//
//  ConnectionState.swift
//  Services
//

import Foundation

/// Where a connection to the signaling server stands.
///
/// The middle cases are what an interface needs in order to show progress
/// and to tell a refusal apart from an idle state.
public enum ConnectionState: Sendable {
    /// The room already holds the two people a meeting is between, so this one
    /// was turned away. It is told apart from a plain failure because nothing
    /// about the connection went wrong and trying again changes nothing.
    case roomIsFull
    case disconnected
    case connecting
    case connected
    case failed
}
