//
//  Encodable.swift
//  Utilities
//

import Foundation

public extension Encodable {
    func dictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let object = try JSONSerialization.jsonObject(with: data)
            return object as? [String: Any]
        } catch {
            return nil
        }
    }
}
