//
//  SymbolTests.swift
//  DesignSystem
//

import Foundation
import Testing
import UIKit
@testable import DesignSystem

@Suite
struct SymbolTests {

    // MARK: - Tests

    @Test(arguments: Symbol.allCases)
    func aSymbolExistsInTheSystem(_ symbol: Symbol) {
        // Assert.
        // A name the system does not know draws nothing and says nothing, so
        // the one mistake this type exists to prevent is the one thing the
        // compiler cannot see. Asking the system for it is what can.
        #expect(UIImage(systemName: symbol.rawValue) != nil)
    }

    @Test
    func everySymbolIsNamedOnce() {
        // Assert.
        // Two cases sharing a name would be two ways of saying the same thing,
        // which is what naming them in one place is meant to end.
        #expect(Set(Symbol.allCases.map(\.rawValue)).count == Symbol.allCases.count)
    }
}
