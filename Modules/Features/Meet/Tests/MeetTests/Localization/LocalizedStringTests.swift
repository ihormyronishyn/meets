//
//  LocalizedStringTests.swift
//  Meet
//

import Foundation
import Testing
@testable import Meet

@Suite
struct LocalizedStringTests {

    // MARK: - Tests

    @Test
    func aStringWithoutPlaceholdersReadsFromTheCatalogOfTheModule() {
        // Assert.
        // A key the catalog does not carry resolves to the key itself, so this
        // reads back the value rather than something a fallback invented. The
        // catalog of each module is reached through its own bundle, so this is
        // pinned once per module and proves nothing about the others.
        #expect(String(localized: .meetLeaveLabel) == "Leave meet")
    }

    @Test
    func aStringWithAPlaceholderCarriesItsArgument() {
        // Assert.
        // The generated symbol takes the argument and the catalog holds the
        // text around it, and neither half is checked by the compiler.
        #expect(String(localized: .meetPeerLabel("Alex")) == "Meeting with Alex")
    }
}
