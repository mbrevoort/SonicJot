//
//  Recording.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/1/24.
//

import QuartzCore
import ComposableArchitecture
import AVFoundation

@DependencyClient
struct RecordingClient {
    var start: () async throws -> Void
    var stop: () async throws -> URL
}

extension DependencyValues {
    
    var recording: RecordingClient {
        get { self[RecordingClient.self] }
        set { self[RecordingClient.self] = newValue }
    }
}

extension RecordingClient: DependencyKey {
    static var liveValue: Self {
        let service = RecordingService()
        
        return Self(
            start: {
                try service.record()
            },
            stop: {
                return service.stop()
            }
        )
    }
}

public class RecordingService : NSObject, AVAudioRecorderDelegate {

    // MARK: - Properties
    
    public enum State: Int {
        case None, Record, Play
    }

    public var sampleRate = 44100.0
    public var channels = 1
    public private(set) var url: NSURL
    private var recorder: AVAudioRecorder?
    private var filename: String
    private var directory: String
    private var state: State = State.None
    
    // MARK: - Initialization
    
    public override init() {
        filename = "\(UUID().uuidString).m4a"
        directory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        url = NSURL(fileURLWithPath: directory).appendingPathComponent(filename)! as NSURL
    }
    
    // MARK: - Public Methods
        
    public func record() throws {
        if recorder == nil {
            try prepare()
        }
        recorder?.record()
        state = .Record
    }
    
    public func stop() -> URL {
        switch state {
        case .Record:
            recorder?.stop()
            recorder = nil
        default:
            break
        }
        state = .None
        return url as URL
    }

    // MARK: - Private Methods
    
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

    
    // MARK: - Delegates
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("audioRecorderDidFinishRecording successful: \(flag)")
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("audioRecorderEncodeErrorDidOccur \(String(describing: error?.localizedDescription))")
    }
}

extension RecordingClient: TestDependencyKey {
    public static var previewValue = Self.noop
    
    public static let testValue = Self(
        start: { },
        stop: { NSURL() as URL }
    )
    
    static let noop = Self(
        start: { },
        stop: { NSURL() as URL }
    )
}
