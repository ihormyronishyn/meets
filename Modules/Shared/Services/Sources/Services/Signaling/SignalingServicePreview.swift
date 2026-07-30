//
//  SignalingServicePreview.swift
//  Services
//

#if DEBUG

    import Entities
    import Foundation

    public actor SignalingServicePreview: SignalingServiceProtocol {

        // MARK: - Init

        public init() {
            // Nothing.
        }

        // MARK: - Streams

        /// Both streams end at once, so an observer finishes instead of waiting,
        /// and a canvas keeps whatever state it was handed.
        public func connectionStates() async -> AsyncStream<ConnectionState> {
            AsyncStream { $0.finish() }
        }

        public func peerEvents() async -> AsyncStream<PeerEvent> {
            AsyncStream { $0.finish() }
        }

        // MARK: - Connection

        public func connect(peer _: Peer) {
            // Nothing.
        }

        public func disconnect() {
            // Nothing.
        }

        // MARK: - Emit

        public func emit(eventName _: PeerEvent.Name, payload _: some Encodable & Sendable) {
            // Nothing.
        }
    }

    // MARK: - Preview

    public extension SignalingServiceProtocol where Self == SignalingServicePreview {
        /// A service that speaks to nobody, so a canvas never opens a socket.
        static var preview: SignalingServicePreview {
            SignalingServicePreview()
        }
    }

#endif
