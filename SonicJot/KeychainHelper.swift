//
//  KeychainHelper.swift
//  SonicJot
//
//  Created by Mike Brevoort on 8/8/23.
//

import Foundation

final class KeychainHelper {
    static let openAIService: String = "openai-access-token"
    static let openAIAccount: String = "openai"
    static let standard = KeychainHelper()
    private init() {}
    
    static func setOpenAIToken(_ value: String) {
        standard.save(Data(value.utf8), service: openAIService, account: openAIAccount)
    }
    
    static func getOpenAIToken() -> String {
        let data = standard.read(service: openAIService, account: openAIAccount)
        if data == nil {
            return ""
        }
        let value = String(data: data!, encoding: .utf8)!
        return value
    }
    
    static func deleteOpenAIToken() {
        standard.delete(service: openAIService, account: openAIAccount)
    }
    
    // Helper implementation methods
    
    func save(_ data: Data, service: String, account: String) {
        
        // Create query
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as [CFString : Any] as CFDictionary
        
        let attributes: [String: AnyObject] = [
            kSecValueData as String: data as AnyObject
        ]
        
        // Add data in query to keychain
        DispatchQueue.global(qos: .userInitiated).async {
            var status = SecItemUpdate(query, attributes as CFDictionary)
            
            if status == errSecItemNotFound {
                status = SecItemAdd(query, nil)
            }
            
            if status != errSecSuccess {
                // Print out the error
                print("Error: \(SecCopyErrorMessageString(status, nil)!)")
            }
        }
    }
    
    func read(service: String, account: String) -> Data? {
        
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as [CFString : Any] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return (result as? Data)
    }

    func delete(service: String, account: String) {
        
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
        ] as [CFString : Any] as CFDictionary
        
        // Delete item from keychain
        SecItemDelete(query)
    }
}
