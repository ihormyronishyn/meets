//
//  Peer.swift
//  Entities
//

import Foundation

public struct Peer: Identifiable, Codable, Equatable, Sendable {

    // MARK: - Properties

    /// Peers are keyed by username throughout the signaling protocol,
    /// so username is the stable identity across decodes.
    public var id: String {
        username
    }

    public let roomId: Int?
    public let username: String
    public let isCaller: Bool?
    public var isCalling: Bool?

    // MARK: - Init

    public init(roomId: Int?, username: String, isCaller: Bool?) {
        self.roomId = roomId
        self.username = username
        self.isCaller = isCaller
    }

    // MARK: - Keys

    enum CodingKeys: String, CodingKey {
        case roomId, username, isCaller
    }
}

// MARK: - Preview

#if DEBUG

    public extension Peer {

        /// People a canvas can borrow. The three cover the positions a room holds
        /// at once, the person signed in and the two roles they can meet.
        enum Preview {
            /// The person a canvas is signed in as.
            public static let local = Peer(roomId: 1, username: "Jacob", isCaller: true)

            /// Somebody of the same role, so no meeting between them is possible.
            public static let caller = Peer(roomId: 1, username: "Mary", isCaller: true)

            /// Somebody of the opposite role, so a meeting can start.
            public static let callee = Peer(roomId: 1, username: "Alex", isCaller: false)
        }
    }

#endif
