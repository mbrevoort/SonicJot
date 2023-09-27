//
//  RecordingQueue.swift
//  SonicJot
//
//  Created by Mike Brevoort on 9/19/23.
//

import AudioToolbox
import AVFAudio

class RecordingQueue {
    let numBuffers = 3
    var audioQueue: AudioQueueRef?
    var buffers: [AudioQueueBufferRef?]
    var accumulatedData: [Float] = []
    var isRunning: Bool = false
    
    public init() {
        buffers = Array(repeating: nil, count: numBuffers)
    }
    
    func newData(data: [Float]) {
        self.accumulatedData.append(contentsOf: data)
    }
    
    
    func startRecording() {
        isRunning = true
        
        // Set up the audio format (e.g., linear PCM)
        var recordingFormat = AudioStreamBasicDescription()
        recordingFormat.mSampleRate = 16000
        recordingFormat.mFormatID = kAudioFormatLinearPCM
        recordingFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        recordingFormat.mFramesPerPacket = 1
        recordingFormat.mChannelsPerFrame = 1
        recordingFormat.mBitsPerChannel = 16
        recordingFormat.mBytesPerPacket = 2
        recordingFormat.mBytesPerFrame = 2
        
        
        // from https://stackoverflow.com/questions/33260808/how-to-use-instance-method-as-callback-for-function-which-takes-only-func-or-lit
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // Create the audio queue
        AudioQueueNewInput(&recordingFormat, {(inUserData: UnsafeMutableRawPointer?,
                                               inQueue: AudioQueueRef,
                                               inBuffer: AudioQueueBufferRef,
                                               inStartTime: UnsafePointer<AudioTimeStamp>,
                                               inNumPackets: UInt32,
                                               inPacketDesc: UnsafePointer<AudioStreamPacketDescription>?) -> Void in
            
            let mySelf = Unmanaged<RecordingQueue>.fromOpaque(inUserData!).takeUnretainedValue()
            let audioData = inBuffer.pointee.mAudioData
            
            let byteSize = Int(inBuffer.pointee.mAudioDataByteSize)
            let samplesPointer = audioData.bindMemory(to: Int16.self, capacity: byteSize)
            let data = Array(UnsafeBufferPointer(start: samplesPointer, count: byteSize / 2))
            
            if data.count == 0 {
                AudioQueueEnqueueBuffer(inQueue, inBuffer, 0, nil)
                return
            }
            
            
            let silence = mySelf.detectSilence(samples: data)
            let pctSilence = mySelf.calculateTruePercentage(boolArray: silence)
//            print("PCT of Silence \(pctSilence) \(data.count)")
            
//            if pctSilence < 100 {
                
                let floats = stride(from: 0, to: data.count, by: 1).map {
                    return data[$0..<$0+1].withUnsafeBytes {
                        let short = Int16(littleEndian: $0.load(as: Int16.self))
                        return max(-1.0, min(Float(short) / 32767.0, 1.0))
                    }
                }
            
                let hasVoices = mySelf.vadSimple(pcmf32: floats, sampleRate: 16000, lastMs: 25, vadThold: 2.0, freqThold: 200.0, verbose: false)
            if hasVoices {
                mySelf.newData(data: floats)
            }
            
                
//            }
            
            // Re-enqueue the buffer for more audio data.
            AudioQueueEnqueueBuffer(inQueue, inBuffer, 0, nil)
        }, selfPointer, nil, nil, 0, &audioQueue)
        
        // Allocate and enqueue buffers
        let bufferSize: UInt32 = 4096
        for i in 0..<numBuffers {
            AudioQueueAllocateBuffer(audioQueue!, bufferSize, &buffers[i])
            AudioQueueEnqueueBuffer(audioQueue!, buffers[i]!, 0, nil)
        }
        
        AudioQueueAddPropertyListener(audioQueue!, kAudioQueueProperty_IsRunning, {(inUserData: UnsafeMutableRawPointer?,
                                                                                    inAQ: AudioQueueRef,
                                                                                    inID: AudioQueuePropertyID) -> Void in
            let mySelf = Unmanaged<RecordingQueue>.fromOpaque(inUserData!).takeUnretainedValue()
            var isRunning: UInt32 = 0
            var size = UInt32(MemoryLayout.size(ofValue: isRunning))
            
            AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &size)
            
            if isRunning == 0 {
                // The AudioQueue has finished processing and has stopped.
                print("AudioQueue has completed processing!")
                mySelf.isRunning = false
            }
        }, selfPointer)
        
        // Start the audio queue
        AudioQueueStart(audioQueue!, nil)
    }
    
    func stopRecording() {
        AudioQueueStop(audioQueue!, false)
        //        AudioQueueDispose(audioQueue!, true)
    }
    
    func clear() async -> [Float] {
        // brute force hack to prevent cutting off audio but adds stupid 2 second delay
        try? await Task.sleep(nanoseconds: UInt64(2 * Double(NSEC_PER_SEC)))
        let data = self.accumulatedData
        self.accumulatedData = []
        print("💥 SIZE: \(data.count)")
        
        let url = NSURL(fileURLWithPath: RecordingModel.directory).appendingPathComponent("out.wav")!
        print("URL \(url)")
        saveWav(data, fileURL: url)
        //        try? writePCMDataToFile(pcmData: self.accumulatedRaw, toURL: url)
        
        return data
    }
    
    func clearIncremental() -> [Float] {
        // mutext??
        let data = self.accumulatedData
        self.accumulatedData = []
        return data
    }
    
    
    func detectSilence(samples: [Int16], threshold: Double = 0.002, windowSize: Int = 1000) -> [Bool] {
        let normalizedSamples = samples.map { Double($0) / Double(Int16.max) }
        var isSilentWindows: [Bool] = []
        
        for i in stride(from: 0, to: normalizedSamples.count, by: windowSize) {
            let window = Array(normalizedSamples[i..<min(i + windowSize, normalizedSamples.count)])
            let rms = sqrt(window.map { $0 * $0 }.reduce(0, +) / Double(window.count))
            
            isSilentWindows.append(rms < threshold)
        }
        
        return isSilentWindows
    }
    
    
    
    func calculateTruePercentage(boolArray: [Bool]) -> Double {
        let trueCount = boolArray.filter { $0 }.count
        let totalCount = boolArray.count
        let percentage = (Double(trueCount) / Double(totalCount)) * 100
        return percentage
    }
    
    
    func saveWav(_ buf: [Float], fileURL: URL) {
        if let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false) {
            let pcmBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(buf.count))
            memcpy(pcmBuf?.floatChannelData?[0], buf, 4 * buf.count)
            pcmBuf?.frameLength = UInt32(buf.count)
            
            let fileManager = FileManager.default
            do {
                let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                try FileManager.default.createDirectory(atPath: documentDirectory.path, withIntermediateDirectories: true, attributes: nil)
                print(fileURL.path)
                let audioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
                try audioFile.write(from: pcmBuf!)
            } catch {
                print(error)
            }
        }
    }
    
    
    
    
    
    
    func vadSimple(pcmf32: [Float], sampleRate: Int, lastMs: Int, vadThold: Float, freqThold: Float, verbose: Bool) -> Bool {
        var data = pcmf32
        let nSamples = pcmf32.count
        let nSamplesLast = (sampleRate * lastMs) / 1000

        guard nSamplesLast < nSamples else {
            // Not enough samples - assume no speech
            return false
        }

        if freqThold > 0.0 {
            // Assuming you also want to port the high_pass_filter function
            data = highPassFilter(data: data, cutoff:freqThold, sampleRate: Float(sampleRate))
        }

        var energyAll: Float = 0.0
        var energyLast: Float = 0.0

        for i in 0..<nSamples {
            energyAll += abs(data[i])

            if i >= nSamples - nSamplesLast {
                energyLast += abs(data[i])
            }
        }

        energyAll /= Float(nSamples)
        energyLast /= Float(nSamplesLast)

        if verbose {
            print("vadSimple - energyAll: \(energyAll), energyLast: \(energyLast), vadThold: \(vadThold), freqThold: \(freqThold)")
        }

        return energyLast <= vadThold * energyAll
    }
    
    func highPassFilter(data: [Float], cutoff: Float, sampleRate: Float) -> [Float] {
        let rc = 1.0 / (2.0 * Float.pi * cutoff)
        let dt = 1.0 / sampleRate
        let alpha = dt / (rc + dt)
        var out = data

        var y = out[0]

        for i in 1..<data.count {
            y = alpha * (y + out[i] - out[i - 1])
            out[i] = y
        }
        return out
    }
}




