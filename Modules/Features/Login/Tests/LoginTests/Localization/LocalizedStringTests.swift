//
//  LocalizedStringTests.swift
//  Login
//

import Foundation
import Testing
@testable import Login

@Suite
struct LocalizedStringTests {

    // MARK: - Tests

    @Test
    func aStringReadsFromTheCatalogOfTheModule() {
        // Assert.
        // A key the catalog does not carry resolves to the key itself, so this
        // reads back the value rather than something a fallback invented. The
        // catalog of each module is reached through its own bundle, so this is
        // pinned once per module and proves nothing about the others.
        #expect(String(localized: .loginJoinTitle) == "Join Room")
    }
}
