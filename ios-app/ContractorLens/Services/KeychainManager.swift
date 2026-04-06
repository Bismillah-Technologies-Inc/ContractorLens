import Foundation
import Security

enum KeychainError: LocalizedError {
    case duplicateItem
    case itemNotFound
    case unknown(OSStatus)
    case invalidData
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "Item already exists in keychain"
        case .itemNotFound:
            return "Item not found in keychain"
        case .unknown(let status):
            return "Keychain error: \(status)"
        case .invalidData:
            return "Invalid data for keychain operation"
        case .encodingFailed:
            return "Failed to encode data for keychain"
        }
    }
}

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    private func createQuery(forKey key: String, shouldReturnData: Bool = true) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.contractorlens.ios"
        ]
        
        if shouldReturnData {
            query[kSecReturnData as String] = kCFBooleanTrue
            query[kSecMatchLimit as String] = kSecMatchLimitOne
        }
        
        return query
    }
    
    func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        var query = createQuery(forKey: key, shouldReturnData: false)
        query[kSecValueData as String] = data
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(value, forKey: key)
            return
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func update(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        let query = createQuery(forKey: key, shouldReturnData: false)
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func get(forKey key: String) throws -> String {
        var query = createQuery(forKey: key)
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    func delete(forKey key: String) throws {
        let query = createQuery(forKey: key, shouldReturnData: false)
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    func exists(forKey key: String) -> Bool {
        do {
            _ = try get(forKey: key)
            return true
        } catch {
            return false
        }
    }
    
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.contractorlens.ios"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}