//
//  PeerEvent.swift
//  Services
//

import Entities
import Foundation

/// The server names an event separately from its payload, so decoding goes
/// through `decode(name:from:)` below. A synthesized `Codable` would encode a
/// shape no server understands, which is why the conformance is absent.
public enum PeerEvent: Sendable {

    // MARK: - Cases

    case roomUserJoined(Peer)
    case roomUserLeft(Peer)
    case offer(PeerCommunication)
    case answer(PeerCommunication)
    case candidate(IceCandidate)

    // MARK: - Name

    public enum Name: String, CaseIterable, Sendable {
        case roomUserJoined = "room_user_joined"
        case roomUserLeft = "room_user_left"
        case offer
        case answer
        case candidate
    }

    public var name: Name {
        switch self {
        case .roomUserJoined:
            .roomUserJoined
        case .roomUserLeft:
            .roomUserLeft
        case .offer:
            .offer
        case .answer:
            .answer
        case .candidate:
            .candidate
        }
    }
}

// MARK: - Decode

extension PeerEvent {
    static func decode(name: Name, from data: Data) throws -> PeerEvent {
        let decoder = JSONDecoder()

        switch name {
        case .roomUserJoined:
            return try .roomUserJoined(decoder.decode(Peer.self, from: data))
        case .roomUserLeft:
            return try .roomUserLeft(decoder.decode(Peer.self, from: data))
        case .offer:
            return try .offer(decoder.decode(PeerCommunication.self, from: data))
        case .answer:
            return try .answer(decoder.decode(PeerCommunication.self, from: data))
        case .candidate:
            return try .candidate(decoder.decode(IceCandidate.self, from: data))
        }
    }
}
