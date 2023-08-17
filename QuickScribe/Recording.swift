//
//  AudioRecorder.swift
//  QuickScribe
//
//  Created by Mike Brevoort on 8/8/23.
//

import AVFoundation
import QuartzCore

public class Recording : NSObject, AVAudioRecorderDelegate {
    
    @objc public enum State: Int {
        case None, Record, Play
    }
  
    static var directory: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    }
    
    public private(set) var url: NSURL
        
    public var sampleRate = 44100.0
    public var channels = 1
    private var recorder: AVAudioRecorder?
    private var filename = "quickscribe.m4a"
    private var state: State = State.None
  
    public override init() {
        url = NSURL(fileURLWithPath: Recording.directory).appendingPathComponent(filename)! as NSURL
    }
    
    private func prepare() throws {
                
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        recorder = try AVAudioRecorder(url: url as URL, settings: settings)
        recorder?.delegate = self
        recorder?.prepareToRecord()
    }

    public func record() throws {
        if recorder == nil {
            try prepare()
        }
        recorder?.record()
        state = .Record
    }


public func stop() -> NSURL {
        switch state {
        case .Record:
            recorder?.stop()
            recorder = nil
        default:
            break
        }
        state = .None
        return url
    }

    // MARK: - Delegates
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("audioRecorderDidFinishRecording successful: \(flag)")
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("audioRecorderEncodeErrorDidOccur \(String(describing: error?.localizedDescription))")
    }
}
