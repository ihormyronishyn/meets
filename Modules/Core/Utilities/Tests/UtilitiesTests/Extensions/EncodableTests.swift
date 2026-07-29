//
//  EncodableTests.swift
//  Utilities
//

import Foundation
import Testing
@testable import Utilities

@Suite
struct EncodableTests {

    // MARK: - Value

    private struct Value: Encodable {
        let name: String
        let count: Int
    }

    // MARK: - Tests

    @Test
    func turnsAValueIntoADictionary() {
        // Arrange.
        let value = Value(name: "Room", count: 2)

        // Act.
        let dictionary = value.dictionary()

        // Assert.
        #expect(dictionary?["name"] as? String == "Room")
        #expect(dictionary?["count"] as? Int == 2)
    }

    @Test
    func answersNothingForAValueThatIsNotAnObject() {
        // Arrange.
        // A list encodes to a JSON array, which is not a dictionary, so the
        // caller learns that rather than receiving something surprising.
        let value = [1, 2, 3]

        // Act.
        let dictionary = value.dictionary()

        // Assert.
        #expect(dictionary == nil)
    }
}
