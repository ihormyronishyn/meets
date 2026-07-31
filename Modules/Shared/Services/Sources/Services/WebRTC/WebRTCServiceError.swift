//
//  WebRTCServiceError.swift
//  Services
//

import Foundation

/// Every case names the step that refused, so a caller can tell a connection
/// that was never built from one that rejected what it was handed. The failure
/// of the framework behind a case goes to the log where it happens, which keeps
/// this type comparable and therefore usable in an expectation.
public enum WebRTCServiceError: Error, Equatable {

    /// A call arrived before connect built the connection, or after disconnect
    /// released it.
    case peerConnectionUnavailable

    /// The factory refused to build a connection for the given configuration.
    case peerConnectionCreationFailed

    /// Connect arrived after disconnect. One instance serves one meeting.
    case connectionClosed

    /// The connection failed to produce a local offer or answer.
    case sessionDescriptionCreationFailed

    /// A session description carries a type this application does not model.
    case sessionDescriptionUnsupported

    /// The offer or answer was produced, but the connection refused it as the
    /// description of this side.
    case localDescriptionFailed

    /// The connection refused the description of the other side.
    case remoteDescriptionFailed

    /// The connection refused a candidate of the other side.
    case remoteCandidateFailed
}
