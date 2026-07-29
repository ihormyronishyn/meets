//
//  UserDefaultsTests.swift
//  Utilities
//

import Foundation
import Testing
@testable import Utilities

enum UserDefaultsTests {

    // MARK: - Write

    final class Write {

        // MARK: - Properties

        private let name: String
        private let store: UserDefaults

        // MARK: - Setup

        init() throws {
            // Every test owns a suite of its own, so no test observes what
            // another one wrote and the order they run in cannot matter.
            name = UUID().uuidString
            store = try #require(UserDefaults(suiteName: name))
        }

        // MARK: - Teardown

        deinit {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }

        // MARK: - Tests

        @Test
        func `stores A string`() {
            // Act.
            store.write("Text", forKey: "key")

            // Assert.
            #expect(store.string(forKey: "key") == "Text")
        }

        @Test
        func `stores A number`() {
            // Act.
            store.write(42, forKey: "key")

            // Assert.
            #expect(store.object(forKey: "key") as? Int == 42)
        }

        @Test
        func `stores zero as A value`() {
            // Act.
            store.write(0, forKey: "key")

            // Assert.
            // The key has to exist, since a reader tells a stored zero from a
            // missing entry only by asking for the object.
            #expect(store.object(forKey: "key") != nil)
            #expect(store.object(forKey: "key") as? Int == 0)
        }

        @Test
        func `replaces A stored value`() {
            // Arrange.
            store.write("Text", forKey: "key")

            // Act.
            store.write("Other text", forKey: "key")

            // Assert.
            #expect(store.string(forKey: "key") == "Other text")
        }

        @Test
        func `removes the key on nil`() {
            // Arrange.
            store.write("Text", forKey: "key")

            // Act.
            store.write(nil, forKey: "key")

            // Assert.
            #expect(store.object(forKey: "key") == nil)
        }

        @Test
        func `leaves nothing behind on nil`() {
            // Arrange.
            store.write("Text", forKey: "key")

            // Act.
            store.write(nil, forKey: "key")

            // Assert.
            // The entry is gone rather than emptied, so the whole domain holds
            // no trace of the key.
            #expect(store.dictionaryRepresentation()["key"] == nil)
        }

        @Test
        func `nil on an unknown key is harmless`() {
            // Act.
            store.write(nil, forKey: "key")

            // Assert.
            #expect(store.object(forKey: "key") == nil)
        }
    }
}
