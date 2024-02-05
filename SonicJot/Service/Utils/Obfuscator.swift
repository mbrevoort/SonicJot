//
//  Obfuscator.swift
//  SonicJot
//
//  Created by Mike Brevoort on 2/1/24.
//

import Foundation

class Obfuscator {
    
    private var salt: String
    
    init() {
        self.salt = "\(String(describing: AppDelegate.self))\(String(describing: NSObject.self))"
    }
    
    init(with salt: String) {
        self.salt = salt
    }
    
    func bytesByObfuscatingString(string: String) -> [UInt8] {
        let text = [UInt8](string.utf8)
        let cipher = [UInt8](self.salt.utf8)
        let length = cipher.count
        
        var encrypted = [UInt8]()
        
        for t in text.enumerated() {
            encrypted.append(t.element ^ cipher[t.offset % length])
        }
                
        return encrypted
    }
    
    func stringByObfuscatingString(string: String) -> String {
        let array = self.bytesByObfuscatingString(string: string)
        let data = NSData(bytes: array, length: array.count)
        return data.base64EncodedString()
    }
    
    func revealStringByString(string: String) -> String {
        let data = NSData(base64Encoded: string)!
        let array = [UInt8](data)
        return self.reveal(key: array)
    }
    
    func reveal(key: [UInt8]) -> String {
        let cipher = [UInt8](self.salt.utf8)
        let length = cipher.count
        
        var decrypted = [UInt8]()
        
        for k in key.enumerated() {
            decrypted.append(k.element ^ cipher[k.offset % length])
        }
        
        return String(bytes: decrypted, encoding: .utf8)!
    }
}
