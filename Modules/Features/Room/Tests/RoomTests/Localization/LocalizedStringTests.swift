//
//  LocalizedStringTests.swift
//  Room
//

import Foundation
import Testing
@testable import Room

@Suite
struct LocalizedStringTests {

    // MARK: - Tests

    @Test
    func aStringWithoutPlaceholdersReadsFromTheCatalogOfTheModule() {
        // Assert.
        // A key the catalog does not carry resolves to the key itself, so this
        // reads back the value rather than something a fallback invented.
        #expect(String(localized: .roomLeaveTitle) == "Leave Room")
    }

    @Test
    func aStringWithAPlaceholderCarriesItsArgument() {
        // Assert.
        // The generated symbol takes the argument and the catalog holds the
        // text around it, and neither half is checked by the compiler.
        #expect(String(localized: .roomPeerLabel("Alex")) == "Peer Alex")
    }
}
