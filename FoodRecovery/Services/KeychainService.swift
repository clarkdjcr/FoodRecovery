//
//  KeychainService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation
import Security

enum KeychainService {
    private static let service = Bundle.main.bundleIdentifier ?? "com.foodrecovery.app"

    // Keys are accessible after the device is first unlocked and are never
    // synced to iCloud Keychain — they remain on this device only.
    private static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    static func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        // kSecAttrSynchronizable: false ensures the item is not backed up via iCloud Keychain.
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecAttrSynchronizable: kCFBooleanFalse as Any
        ]
        let updateAttributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: accessibility
        ]
        let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = accessibility
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    static func retrieve(forKey key: String) -> String? {
        // kSecAttrSynchronizableAny finds both legacy items (saved before the
        // synchronizable flag was set) and current non-syncing items.
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(forKey key: String) {
        // Delete regardless of synchronizable flag to catch legacy items.
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ]
        SecItemDelete(query as CFDictionary)
    }
}
