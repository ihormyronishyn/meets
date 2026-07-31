//
//  SignalingServiceSpy.swift
//  Meet
//

import Entities
import Foundation
import Services

actor SignalingServiceSpy: SignalingServiceProtocol {

    // MARK: - Properties

    /// Kept as raw values, because the name of an event is not Sendable and a
    /// collection of them cannot leave the actor.
    private(set) var emittedNames: [String] = []

    private(set) var disconnectCallCount: Int = .zero

    private var peerEventContinuation: AsyncStream<PeerEvent>.Continuation?

    // MARK: - Streams

    /// The continuation appears only once somebody asks for the stream, exactly
    /// as the real service behaves, so an event sent before that is lost.
    func peerEvents() async -> AsyncStream<PeerEvent> {
        AsyncStream { continuation in
            peerEventContinuation = continuation
        }
    }

    func connectionStates() async -> AsyncStream<ConnectionState> {
        AsyncStream { $0.finish() }
    }

    // MARK: - Connection

    func connect(peer _: Peer) {
        // Nothing.
    }

    func disconnect() {
        disconnectCallCount += 1
    }

    // MARK: - Emit

    func emit(eventName: PeerEvent.Name, payload _: some Encodable & Sendable) {
        emittedNames.append(eventName.rawValue)
    }

    // MARK: - Send

    func send(event: PeerEvent) {
        peerEventContinuation?.yield(event)
    }
}
