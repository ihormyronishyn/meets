//
//  Server.swift
//  App
//

import Foundation

/// The addresses this build talks to, gathered in one value so the composition
/// root hands them over together rather than one parameter at a time.
public struct Server: Sendable {

    // MARK: - Properties

    /// Where the signaling server listens.
    public let signalingURL: URL

    /// The discovery servers a peer connection may use, in the order they are
    /// written. An empty list is allowed, since a connection over a local
    /// network needs none.
    public let iceURLs: [String]

    // MARK: - Init

    public init(signalingURL: URL, iceURLs: [String]) {
        self.signalingURL = signalingURL
        self.iceURLs = iceURLs
    }
}

// MARK: - Current

public extension Server {

    // MARK: - Keys

    private enum Key: String {
        case signalingServerURL = "SignalingServerURL"
        case iceServerURLs = "IceServerURLs"
    }

    // MARK: - Properties

    /// What this build was configured with, taken from the information property
    /// list that the build settings fill in.
    ///
    /// A missing or malformed entry is a fault of the build rather than a state
    /// the application can meet, so reading one stops the launch instead of
    /// quietly substituting something that would fail much later.
    static let current: Server = {
        let address = string(for: .signalingServerURL)

        guard let signalingURL = URL(string: address) else {
            preconditionFailure("\(Key.signalingServerURL.rawValue) is not a URL, it reads \(address).")
        }

        let iceURLs = string(for: .iceServerURLs)
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return Server(signalingURL: signalingURL, iceURLs: iceURLs)
    }()

    // MARK: - String

    /// The list is read from the bundle of the application rather than the one
    /// of this module, because the build settings fill in the former.
    private static func string(for key: Key) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String else {
            preconditionFailure("\(key.rawValue) is missing from the information property list.")
        }

        return value
    }
}
