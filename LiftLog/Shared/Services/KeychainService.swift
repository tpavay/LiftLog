//
//  KeychainService.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import Foundation
import Security

/// Secure storage for sensitive data using iOS Keychain
enum KeychainService {
    
    enum KeychainError: LocalizedError {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .duplicateItem:
                return "Item already exists in keychain"
            case .itemNotFound:
                return "Item not found in keychain"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            case .invalidData:
                return "Invalid data format"
            }
        }
    }
    
    /// Keys for stored credentials
    enum Key: String {
        case hevyApiKey = "com.liftlog.hevy-api-key"
        case anthropicApiKey = "com.liftlog.anthropic-api-key"
    }
    
    // MARK: - Public API
    
    /// Save a string value to the keychain
    static func save(key: Key, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // First try to delete any existing item
        try? delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: "LiftLog",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Retrieve a string value from the keychain
    static func get(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: "LiftLog",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// Delete a value from the keychain
    static func delete(key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: "LiftLog"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Check if a key exists in the keychain
    static func exists(key: Key) -> Bool {
        return get(key: key) != nil
    }
    
    /// Update an existing value in the keychain
    static func update(key: Key, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: "LiftLog"
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecItemNotFound {
            // Item doesn't exist, create it
            try save(key: key, value: value)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// MARK: - Validation

extension KeychainService {
    
    /// Validate Hevy API key format (UUID)
    static func isValidHevyKey(_ key: String) -> Bool {
        let uuidRegex = #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#
        return key.range(of: uuidRegex, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    /// Validate Anthropic API key format
    static func isValidAnthropicKey(_ key: String) -> Bool {
        return key.hasPrefix("sk-ant-") && key.count > 20
    }
}
