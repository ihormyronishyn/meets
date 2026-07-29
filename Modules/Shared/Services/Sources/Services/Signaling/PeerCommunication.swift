//
//  PeerCommunication.swift
//  Services
//

import Entities
import Foundation

public enum PeerCommunication: Codable, Sendable {

    // MARK: - Cases

    case call(SignalingCall)
    case sdp(SessionDescription)

    // MARK: - Keys

    enum CodingKeys: String, CodingKey {
        case call
    }

    // MARK: - Decoder

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let call = try container.decodeIfPresent(SignalingCall.self, forKey: .call) {
            self = .call(call)
        } else {
            self = try .sdp(SessionDescription(from: decoder))
        }
    }

    // MARK: - Encoder

    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .call(call):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(call, forKey: .call)
        case let .sdp(sdp):
            try sdp.encode(to: encoder)
        }
    }
}

// MARK: - Call

public extension PeerCommunication {
    struct SignalingCall: Codable, Sendable {

        // MARK: - Properties

        public let from: Peer
        public let to: Peer

        // MARK: - Init

        public init(from: Peer, to: Peer) {
            self.from = from
            self.to = to
        }
    }
}
