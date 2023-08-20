//
//  LocalTranscription.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/16/23.
//

import Foundation
import SwiftWhisper
import AudioKit

final class LocalTranscription: ObservableObject {
    @Published var isInitialized: Bool = false
    var whisper: Whisper?
    var translateToEnglish: Bool {
        set {
            self.whisper?.params.translate = newValue
        }
        get {
            self.whisper?.params.translate ?? false
        }
    }
    var language: String {
        set {
            self.whisper?.params.language = WhisperLanguage(rawValue: newValue)!
        }
        get {
            self.whisper?.params.language.rawValue ?? ""
        }
    }
    var prompt: String {
        set {
            let cStringArray = Array(newValue.utf8CString) // Array<CChar> with null terminator
            cStringArray.withUnsafeBufferPointer { buffer in
                let pointer: UnsafePointer<CChar> = buffer.baseAddress!
                self.whisper?.params.initial_prompt = pointer
            }
        }
        get {
            if self.whisper != nil {
                return String(cString: self.whisper!.params.initial_prompt)
            }
            return ""
        }
    }
    
    init() {
    }
    
    public func initModel() async {
        if self.whisper == nil {
            let url = await LocalTranscription.getModelURL()!
            print("Model URL: \(url)")
            self.whisper = Whisper(fromFileURL: url)
            self.whisper?.params.beam_search.beam_size = 5
            self.whisper?.params.entropy_thold = 2.4
            self.whisper?.params.temperature = 0
            isInitialized = true
        }
    }
    
    
    func transcribe(fileURL: URL, completionHandler: @escaping (_ result: Result<String, Error>) -> Void) {
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
            
            let data = try! Data(contentsOf: tempURL) // Handle error here
            
            let floats = stride(from: 44, to: data.count, by: 2).map {
                return data[$0..<$0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }
            
            try? FileManager.default.removeItem(at: tempURL)
            
            completionHandler(.success(floats))
        }
    }
    
    static private func getModelURL() async -> URL? {
        let hostedModelURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin")!
        NSHomeDirectory()
        
        
        guard let path = pathForAppSupportDirecotry()?.appendingPathComponent("ggml-small.bin") else { return nil }
        print("Local model path is \(path)")
        
        if FileManager.default.fileExists(atPath: path.path) {
            return path
        }
        
        do {
            let url = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) -> Void in
                let urlRequest = URLRequest(url: hostedModelURL)
                
                URLSession.shared.downloadTask(with: urlRequest) { url, _, error in
                    if let error {
                        cont.resume(throwing: error)
                    }
                    
                    cont.resume(returning: url!)
                }.resume()
            }
            
            try FileManager.default.copyItem(at: url, to: path)
        } catch {
            return nil
        }
        
        return path
    }
    
    static private func pathForAppSupportDirecotry() -> URL? {
        guard let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
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



