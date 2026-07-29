//
//  UserDefaultsTests.swift
//  Utilities
//

import Foundation
import Testing
@testable import Utilities

@Suite
enum UserDefaultsTests {

    // MARK: - Write

    @Suite
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
        func storesAString() {
            // Act.
            store.write("Text", forKey: "key")

            // Assert.
            #expect(store.string(forKey: "key") == "Text")
        }

        @Test
        func storesANumber() {
            // Act.
            store.write(42, forKey: "key")

            // Assert.
            #expect(store.object(forKey: "key") as? Int == 42)
        }

        @Test
        func storesZeroAsAValue() {
            // Act.
            store.write(0, forKey: "key")

            // Assert.
            // The key has to exist, since a reader tells a stored zero from a
            // missing entry only by asking for the object.
            #expect(store.object(forKey: "key") != nil)
            #expect(store.object(forKey: "key") as? Int == 0)
        }

        @Test
        func replacesAStoredValue() {
            // Arrange.
            store.write("Text", forKey: "key")

            // Act.
            store.write("Other text", forKey: "key")

            // Assert.
            #expect(store.string(forKey: "key") == "Other text")
        }

        @Test
        func removesTheKeyOnNil() {
            // Arrange.
            store.write("Text", forKey: "key")

            // Act.
            store.write(nil, forKey: "key")

            // Assert.
            #expect(store.object(forKey: "key") == nil)
        }

        @Test
        func leavesNothingBehindOnNil() {
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
        func nilOnAnUnknownKeyIsHarmless() {
            // Act.
            store.write(nil, forKey: "key")

            // Assert.
            #expect(store.object(forKey: "key") == nil)
        }
    }
}
