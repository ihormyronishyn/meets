//
//  SignalingService.swift
//  Services
//

import Entities
import Foundation
import SocketIO
import Utilities

public actor SignalingService: SignalingServiceProtocol {

    // MARK: - Signal

    /// Wraps every socket callback so connection state changes and peer
    /// events flow through a single ordered pipeline into the broadcasters.
    private enum Signal {
        case connectionState(ConnectionState)
        case peerEvent(PeerEvent)
    }

    // MARK: - Events

    /// The server names this when it turns a connection away, and it is not a
    /// peer event, so it is listened for on its own.
    private static let roomFullEventName = "room_full"

    // MARK: - Properties

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var forwardTask: Task<Void, Never>?

    // MARK: - Broadcasters

    // The broadcasters stay private, so nobody outside can yield an event that
    // never came from the server, or finish a stream that others are reading.
    private let connectionStateBroadcaster = EventBroadcaster<ConnectionState>()
    private let peerEventBroadcaster = EventBroadcaster<PeerEvent>()

    private let url: URL
    private let signalStream: AsyncStream<Signal>
    private let signalContinuation: AsyncStream<Signal>.Continuation

    // MARK: - Init

    public init(url: URL) {
        self.url = url
        (signalStream, signalContinuation) = AsyncStream.makeStream(of: Signal.self, bufferingPolicy: .unbounded)
    }

    // MARK: - Connect

    public func connect(peer: Peer) {
        guard socket == nil || socket?.status == .disconnected || socket?.status == .notConnected else {
            debugPrint("Ignored a connect while the socket was \(socket?.status.description ?? "absent").")
            return
        }

        guard let roomId = peer.roomId, let isCaller = peer.isCaller else {
            debugPrint("Refused to connect, the peer carries no room or no caller flag.")
            signalContinuation.yield(.connectionState(.failed))
            return
        }

        signalContinuation.yield(.connectionState(.connecting))

        manager = SocketManager(socketURL: url)
        manager?.config = [
            .log(true),
            .compress,
            .connectParams([
                "roomId": roomId,
                "username": peer.username,
                "isCaller": isCaller,
            ]),
        ]

        socket = manager?.defaultSocket
        startForwardingIfNeeded()
        listen()
        socket?.connect()
    }

    // MARK: - Forward

    /// Forwards signals to the broadcasters one at a time, preserving the
    /// order in which the socket delivered them. The service lives for the
    /// whole app session, so the task never needs teardown.
    private func startForwardingIfNeeded() {
        guard forwardTask == nil else { return }

        forwardTask = Task { [connectionStateBroadcaster, peerEventBroadcaster, signalStream] in
            // The filter remembers one state at a time and lives inside the
            // single reader of the stream, so it is reached in arrival order
            // and by nobody else.
            var filter = ConnectionStateFilter()

            for await signal in signalStream {
                switch signal {
                case let .connectionState(state):
                    guard filter.allows(state) else { continue }
                    await connectionStateBroadcaster.yield(state)
                case let .peerEvent(event):
                    await peerEventBroadcaster.yield(event)
                }
            }
        }
    }

    // MARK: - Disconnect

    public func disconnect() {
        socket?.disconnect()
    }

    // MARK: - Listen

    private func listen() {
        // Handlers yield synchronously into the signal stream; SocketIO invokes
        // them on its serial handle queue, so yield order matches arrival order.
        socket?.on(clientEvent: .connect) { [signalContinuation] _, _ in
            signalContinuation.yield(.connectionState(.connected))
        }

        socket?.on(clientEvent: .disconnect) { [signalContinuation] _, _ in
            signalContinuation.yield(.connectionState(.disconnected))
        }

        socket?.on(clientEvent: .error) { [signalContinuation] data, _ in
            debugPrint("Signaling socket reported an error: \(data).")
            signalContinuation.yield(.connectionState(.failed))
        }

        socket?.on(Self.roomFullEventName) { [signalContinuation] _, _ in
            signalContinuation.yield(.connectionState(.roomIsFull))
        }

        for name in PeerEvent.Name.allCases {
            socket?.on(name.rawValue) { [signalContinuation] data, _ in
                guard let event = Self.decodeEvent(name: name, data: data) else { return }
                signalContinuation.yield(.peerEvent(event))
            }
        }
    }

    // MARK: - Streams

    /// Hands out the connection states as they arrive, read only.
    public func connectionStates() async -> AsyncStream<ConnectionState> {
        await connectionStateBroadcaster.stream()
    }

    /// Hands out the peer events as they arrive, read only.
    public func peerEvents() async -> AsyncStream<PeerEvent> {
        await peerEventBroadcaster.stream()
    }

    // MARK: - Emit

    public func emit(eventName: PeerEvent.Name, payload: some Encodable & Sendable) {
        guard let dictionary = payload.dictionary() else {
            debugPrint("Dropped \(eventName.rawValue) emit because its payload failed to encode.")
            return
        }

        socket?.emit(eventName.rawValue, dictionary)
    }
}

// MARK: - Decode

extension SignalingService {
    static func decodeEvent(
        name: PeerEvent.Name,
        data: [Any],
    ) -> PeerEvent? {
        guard let object = data.first, JSONSerialization.isValidJSONObject(object) else {
            debugPrint("Payload for \(name.rawValue) event is missing or is not a JSON object.")
            return nil
        }

        do {
            let json = try JSONSerialization.data(withJSONObject: object)
            return try PeerEvent.decode(name: name, from: json)
        } catch {
            debugPrint("Failed to decode \(name.rawValue) event: \(error)")
            return nil
        }
    }
}
