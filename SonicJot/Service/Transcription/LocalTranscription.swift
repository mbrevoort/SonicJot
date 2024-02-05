//
//  LocalTranscription.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/4/24.
//

import SwiftUI
import SwiftWhisper
import AudioKit
import Zip

final class LocalTranscription: TranscriptionBase, ObservableObject {
    @Published public private(set) var isInitialized: Bool = false
    
    override var translateToEnglish: Bool {
        set {
            self.whisper?.params.translate = newValue
        }
        get {
            self.whisper?.params.translate ?? false
        }
    }
    
    override var language: TranscriptionLanguage {
        set {
            self.whisper?.params.language = WhisperLanguage(rawValue: newValue.rawValue)!
        }
        get {
            if self.whisper?.params.language == nil || self.whisper?.params.language.rawValue == "" {
                return TranscriptionLanguage.English
            }
            return TranscriptionLanguage(rawValue: (self.whisper?.params.language.rawValue)!)!
        }
    }
    
    private var initPromptPtr: UnsafeMutablePointer<CChar>?
    private var whisper: Whisper?

    override var prompt: String {
        set {
            // first deallocate an existing value
            initPromptPtr?.deallocate()
            
            if let cString = newValue.cString(using: .utf8) {
                let length = cString.count
                initPromptPtr = UnsafeMutablePointer<CChar>.allocate(capacity: length)
                initPromptPtr?.initialize(from: cString, count: length)
                self.whisper?.params.initial_prompt = UnsafePointer(initPromptPtr)
            }
        }
        get {
            if self.whisper != nil {
                return String(cString: self.whisper!.params.initial_prompt)
            }
            return ""
        }
    }
        
    public func initModel() async throws {
        if self.whisper == nil {
            let url = try await LocalTranscription.getModelURL()
            print("Model URL: \(url)")
            self.whisper = Whisper(fromFileURL: url)
            print("Loaded model")
            self.whisper?.params.beam_search.beam_size = 5
            self.whisper?.params.entropy_thold = 2.4
            self.whisper?.params.temperature = 0
            // https://github.com/ggerganov/whisper.cpp/issues/588
            self.whisper?.params.temperature_inc = 0
            isInitialized = true
            print("Initiatlized")
        }
    }
    
    public override func transcribe(url: URL) async throws -> String {
        try await self.initModel()
        
        return try await withCheckedThrowingContinuation { continuation in
            self.transcribe(fileURL: url) { result in
                switch result {
                case .success(let text):
                    continuation.resume(returning: text)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func transcribe(fileURL: URL, completionHandler: @escaping (_ result: Result<String, Error>) -> Void) {
        self.convertAudioFileToPCMArray(fileURL: fileURL) { result in
            switch result {
            case .success(let data):
                Task {
                    do {
                        let segments = try await self.whisper!.transcribe(audioFrames: data)
                        let text = segments.map(\.text)
                            .joined()
                            .replacingOccurrences(of: #"\[.*\]"#, with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespaces)
                        completionHandler(.success(text))
                    }
                    catch {
                        
                    }
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    private func convertAudioFileToPCMArray(fileURL: URL, completionHandler: @escaping (_ result: Result<[Float], Error>) -> Void) {
        let timer = Timer()
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)
        converter.start { error in
            if let error {
                completionHandler(.failure(error))
                return
            }
            
            do {
                let data = try Data(contentsOf: tempURL)
                
                let floats = stride(from: 44, to: data.count, by: 2).map {
                    return data[$0..<$0 + 2].withUnsafeBytes {
                        let short = Int16(littleEndian: $0.load(as: Int16.self))
                        return max(-1.0, min(Float(short) / 32767.0, 1.0))
                    }
                }
                
                try FileManager.default.removeItem(at: tempURL)
                print("Conversion to PCM Array took \(timer.stop())")
                completionHandler(.success(floats))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    static private func getModelURL() async throws -> URL {
        let modelNameBase = "medium"
        let name = "ggml-\(modelNameBase)-q5_0.bin"
        let coreMLName = "ggml-\(modelNameBase)-encoder.mlmodelc"
        let hostedModelURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(name)")!
        let hostedCoreMLZipURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(coreMLName).zip")!
        
        let path = try pathForAppSupportDirectory().appendingPathComponent(name)
        let coreMLFilePath = try pathForAppSupportDirectory().appendingPathComponent(coreMLName)
        let coreMLFileZipPath = try pathForAppSupportDirectory().appendingPathComponent("\(coreMLName).zip")
        print("Local model path is \(path)")
        
        
        if !FileManager.default.fileExists(atPath: path.path) {
            // Download model file
            print("Downloading model file")
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) -> Void in
                URLSession.shared.downloadTask(with: URLRequest(url: hostedModelURL)) { url, _, error in
                    if let error {
                        cont.resume(throwing: error)
                    }
                    
                    do {
                        try FileManager.default.copyItem(at: url!, to: path)
                        cont.resume()
                    } catch {
                        cont.resume(throwing: error)
                    }
                    
                }.resume()
            }
        }
        
        if !FileManager.default.fileExists(atPath: coreMLFilePath.path) {
            // Download CoreML zip file
            print("Downloading CoreML file")
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) -> Void in
                URLSession.shared.downloadTask(with: URLRequest(url: hostedCoreMLZipURL)) { url, _, error in
                    if let error {
                        cont.resume(throwing: error)
                    }
                    
                    do {
                        try FileManager.default.copyItem(at: url!, to: coreMLFileZipPath)
                        cont.resume()
                    } catch {
                        cont.resume(throwing: error)
                    }
                }.resume()
            }
                        
            // unzip
            try Zip.unzipFile(coreMLFileZipPath, destination: pathForAppSupportDirectory(), overwrite: true, password: "", progress: { (progress) -> () in
                print(progress)
            })
            
            
            print("Unzipped coreML file \(coreMLFilePath)")
            
            try FileManager.default.removeItem(at: coreMLFileZipPath)
        }

        print("Done downloading files")
        
        return path
    }
    
    static private func pathForAppSupportDirectory() throws -> URL {
        guard let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "", code: 404, userInfo: [ NSLocalizedDescriptionKey: "Application Support directory not found"])
        }
        
        checkAndCreateDirectory(at: appSupportDirectory.absoluteString)
        return appSupportDirectory
    }
    
    static private func checkAndCreateDirectory(at path: String) {
        let fm = FileManager.default
        if !fm.fileExists(atPath: path) {
            do {
                try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print(error)
            }
        }
    }
}
