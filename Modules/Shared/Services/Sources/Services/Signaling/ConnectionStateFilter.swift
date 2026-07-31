//
//  ConnectionStateFilter.swift
//  Services
//

import Foundation

/// Decides which connection states are worth passing on to a reader.
///
/// A refusal is announced and the socket is closed in the same breath, so the
/// disconnection that follows would arrive last and leave a reader holding a
/// state indistinguishable from an ordinary leave, with the reason gone. That
/// one disconnection is swallowed, and only that one.
struct ConnectionStateFilter {

    // MARK: - Properties

    private var wasRefused: Bool = false

    // MARK: - Methods

    mutating func allows(_ state: ConnectionState) -> Bool {
        guard !wasRefused || state != .disconnected else {
            wasRefused = false
            return false
        }

        wasRefused = state == .roomIsFull
        return true
    }
}
