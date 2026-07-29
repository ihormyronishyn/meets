//
//  ConnectionState.swift
//  Services
//

import Foundation

/// Where a connection to the signaling server stands.
///
/// The two middle cases are what an interface needs in order to show progress
/// and to tell a refusal apart from an idle state.
public enum ConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case failed
}
