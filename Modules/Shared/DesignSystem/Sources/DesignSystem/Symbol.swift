//
//  Symbol.swift
//  DesignSystem
//

import SwiftUI

/// The symbols of the system this application draws, named by what they depict
/// rather than by the screen that happens to use them.
///
/// A symbol is asked for by name, and a name that does not exist draws nothing
/// at all, without a warning anywhere. Naming them here is what turns a
/// mistyped one into something the compiler refuses.
public enum Symbol: String, CaseIterable, Sendable {
    case videoFill = "video.fill"
    case phoneDownFill = "phone.down.fill"
}

// MARK: - Image

public extension Image {

    // MARK: - Init

    /// Draws a symbol of the system by role, so a call site names one of the
    /// symbols this application uses rather than any string at all.
    init(_ symbol: Symbol) {
        self.init(systemName: symbol.rawValue)
    }
}
