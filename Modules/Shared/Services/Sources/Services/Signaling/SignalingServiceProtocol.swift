//
//  SignalingServiceProtocol.swift
//  Services
//

import Entities
import Foundation

public protocol SignalingServiceProtocol: Actor {

    // MARK: - Streams

    func connectionStates() async -> AsyncStream<ConnectionState>
    func peerEvents() async -> AsyncStream<PeerEvent>

    // MARK: - Connection

    func connect(peer: Peer)
    func disconnect()

    // MARK: - Emit

    func emit(eventName: PeerEvent.Name, payload: some Encodable & Sendable)
}
