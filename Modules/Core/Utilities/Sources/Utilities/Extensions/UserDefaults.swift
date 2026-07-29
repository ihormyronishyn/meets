//
//  UserDefaults.swift
//  Utilities
//

import Foundation

public extension UserDefaults {
    /// Stores the value under the given key, and removes the key entirely when
    /// the value is absent, so an emptied entry leaves nothing behind.
    ///
    /// The name differs from `set(_:forKey:)` on purpose, since a member of the
    /// same shape would compete with the one Foundation already declares.
    func write(_ value: Any?, forKey key: String) {
        guard let value else {
            return removeObject(forKey: key)
        }

        set(value, forKey: key)
    }
}
