import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    private let service = "com.yourcompany.ralph"
    
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }
    
    // MARK: - OpenAI API Key Management
    
    func saveOpenAIAPIKey(_ apiKey: String) throws {
        try save(key: "openai_api_key", data: apiKey.data(using: .utf8) ?? Data())
    }
    
    func getOpenAIAPIKey() throws -> String {
        let data = try get(key: "openai_api_key")
        guard let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return apiKey
    }
    
    func deleteOpenAIAPIKey() throws {
        try delete(key: "openai_api_key")
    }
    
    var hasOpenAIAPIKey: Bool {
        do {
            _ = try getOpenAIAPIKey()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - User Credentials Management
    
    func saveUserCredentials(email: String, password: String) throws {
        let credentials = UserCredentials(email: email, password: password)
        let data = try JSONEncoder().encode(credentials)
        try save(key: "user_credentials", data: data)
    }
    
    func getUserCredentials() throws -> UserCredentials {
        let data = try get(key: "user_credentials")
        return try JSONDecoder().decode(UserCredentials.self, from: data)
    }
    
    func deleteUserCredentials() throws {
        try delete(key: "user_credentials")
    }
    
    var hasUserCredentials: Bool {
        do {
            _ = try getUserCredentials()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Generic Keychain Operations
    
    private func save(key: String, data: Data) throws {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecValueData as String: data as AnyObject
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(key: key, data: data)
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }
    
    private func get(key: String) throws -> Data {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    private func update(key: String, data: Data) throws {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: key as AnyObject
        ]
        
        let attributes: [String: AnyObject] = [
            kSecValueData as String: data as AnyObject
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    private func delete(key: String) throws {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: key as AnyObject
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() throws {
        try? deleteOpenAIAPIKey()
        try? deleteUserCredentials()
    }
}

// MARK: - Supporting Types

struct UserCredentials: Codable {
    let email: String
    let password: String
}

// MARK: - Convenience Extensions

extension KeychainManager {
    func promptForOpenAIAPIKey() async -> String? {
        // This would typically be called from a view that presents an alert
        // For now, we'll return nil and handle this in the UI layer
        return nil
    }
}

// MARK: - OpenAI API Key Validation

extension KeychainManager {
    func validateOpenAIAPIKey(_ apiKey: String) -> Bool {
        // Basic validation - OpenAI API keys start with "sk-" and are typically 51 characters
        return apiKey.hasPrefix("sk-") && apiKey.count >= 20
    }
    
    func formatOpenAIAPIKey(_ apiKey: String) -> String {
        return apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}