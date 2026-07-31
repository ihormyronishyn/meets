//
//  RoomViewModel.swift
//  Room
//

import Entities
import Observation
import Services
import Utilities

@MainActor
@Observable
public final class RoomViewModel {

    // MARK: - Properties

    var peers: [Peer] = []
    var isCaller: Bool = true

    /// The names of the peers who have offered a meeting to the person signed
    /// in. It is kept here rather than on a peer, because it is what this
    /// screen has heard so far and not something the room reports about a
    /// person, and a peer arriving again would otherwise carry it or lose it
    /// depending on the order the events happened to arrive in.
    private(set) var incomingCalls: Set<String> = []

    var isLeaveRoomConfirmationAlertPresented: Bool = false
    var signalingConnectionState: ConnectionState = .disconnected

    /// Whether the room is live, so the screen asks this rather than comparing
    /// a state it would otherwise have to know about.
    var isConnected: Bool {
        signalingConnectionState == .connected
    }

    /// Whether the room is still being reached, so the screen shows progress
    /// and refuses a second request until this one settles.
    var isConnecting: Bool {
        signalingConnectionState == .connecting
    }

    /// Whether the last attempt to reach the room failed, so the screen says so
    /// instead of looking the same as an untouched one.
    var hasFailedToConnect: Bool {
        signalingConnectionState == .failed
    }

    /// Whether the room turned this person away because it already holds the
    /// two a meeting is between. Trying again leads nowhere, so the screen says
    /// something other than what it says about a connection that went wrong.
    var isRoomFull: Bool {
        signalingConnectionState == .roomIsFull
    }

    private let signalingService: SignalingServiceProtocol
    private let userAuthenticationService: UserAuthenticationServiceProtocol

    @ObservationIgnored public weak var router: RoomRouting?
    @ObservationIgnored private let taskBag = TaskBag()

    var localPeer: Peer? {
        guard
            let roomId = userAuthenticationService.roomId,
            let username = userAuthenticationService.username
        else {
            return nil
        }

        return Peer(roomId: roomId, username: username, isCaller: isCaller)
    }

    // MARK: - Init

    public init(
        signalingService: SignalingServiceProtocol,
        userAuthenticationService: UserAuthenticationServiceProtocol,
    ) {
        self.signalingService = signalingService
        self.userAuthenticationService = userAuthenticationService
    }

    // MARK: - Methods

    /// Checks if a peer is available for initiating a call or answer.
    /// A peer is available if it has a defined role caller or callee,
    /// either we are the caller or it is calling us, and its role differs from the local peer.
    func isPeerAvailable(_ peer: Peer) -> Bool {
        guard let isCaller = peer.isCaller, self.isCaller || incomingCalls.contains(peer.username) else { return false }
        return isCaller != self.isCaller
    }

    // MARK: - Join Room

    /// Adds a peer to the room if he not already present, based on username.
    private func joinRoom(_ peer: Peer) {
        guard !peers.contains(where: { $0.username == peer.username }) else { return }
        peers.append(peer)
    }

    // MARK: - Remove

    /// Forgets a peer along with the call it was making, so a name that comes
    /// back later arrives without the state it left behind.
    private func removePeer(named username: String) {
        peers.removeAll(where: { $0.username == username })
        incomingCalls.remove(username)
    }

    /// Forgets the whole room, so nothing of one connection is read as the
    /// state of the next.
    private func removeAllPeers() {
        peers.removeAll()
        incomingCalls.removeAll()
    }

    // MARK: - Leave Room

    func leaveRoom() async {
        taskBag.cancelAll()
        removeAllPeers()
        await signalingService.disconnect()
        userAuthenticationService.logout()
        router?.didLeaveRoom()
    }

    // MARK: - Connect

    func connect() async {
        guard let localPeer else {
            debugPrint("Refused to connect, there is nobody signed in.")
            return
        }

        // Observation starts before the request, because the service reports
        // the first states at once and nothing replays them to a late reader.
        // Observation tasks survive reconnects, so start them only once,
        // otherwise every connect cycle would add duplicate observers.
        if taskBag.isEmpty {
            await observe()
        }

        await signalingService.connect(peer: localPeer)
    }

    // MARK: - Disconnect

    func disconnect() async {
        removeAllPeers()
        await signalingService.disconnect()
    }

    // MARK: - Meet

    func startMeet(with remotePeer: Peer) {
        guard let localPeer else {
            debugPrint("Dropped a video chat with \(remotePeer.username), there is nobody signed in.")
            return
        }

        router?.didStartMeet(Meet(localPeer: localPeer, remotePeer: remotePeer))
    }

    // MARK: - Observe

    private func observe() async {
        // The streams are asked for here rather than inside the tasks, because
        // a task starts later than the caller returns, and the service would
        // report its first states into nobody. Once a stream exists it buffers,
        // so nothing is lost between this line and the first iteration.
        let connectionStates = await signalingService.connectionStates()
        let peerEvents = await signalingService.peerEvents()

        // Self is promoted from weak per iteration only, so a suspended loop
        // never keeps the view model alive; the task bag cancels on deinit.
        let connectionTask = Task { [weak self] in
            for await state in connectionStates {
                guard let self else { return }
                signalingConnectionState = state

                // A refusal leaves the socket closed just as a leave does, so
                // whatever the previous connection gathered goes with it.
                if state == .disconnected || state == .roomIsFull {
                    removeAllPeers()
                }
            }
        }

        taskBag.insert(connectionTask)

        let peerEventTask = Task { [weak self] in
            for await event in peerEvents {
                guard let self else { return }
                handle(event: event)
            }
        }

        taskBag.insert(peerEventTask)
    }

    // MARK: - Handle

    func handle(event: PeerEvent) {
        switch event {
        case let .roomUserJoined(peer):
            joinRoom(peer)
        case let .roomUserLeft(peer):
            removePeer(named: peer.username)
        case let .offer(communication):
            guard let localPeer, case let .call(call) = communication else {
                debugPrint("Ignored an offer, it carries no call or nobody is signed in.")
                return
            }

            // Only an offer addressed to the person signed in counts. The
            // caller is joined as well, because an offer can reach the callee
            // before the room reports that whoever sent it is there.
            if call.to.username == localPeer.username {
                incomingCalls.insert(call.from.username)
                joinRoom(call.from)
            }
        case let .answer(communication):
            guard let localPeer, case let .call(call) = communication else {
                debugPrint("Ignored an answer, it carries no call or nobody is signed in.")
                return
            }

            // When receiving a call answer not intended for us, it means two other peers
            // have established a connection. Remove both from available peers list
            // since they are now busy with a call and unavailable.
            if call.to.username != localPeer.username {
                removePeer(named: call.to.username)
                removePeer(named: call.from.username)
            }
        case .candidate:
            break
        }
    }
}

// MARK: - Extension

#if DEBUG

    public extension RoomViewModel {

        // MARK: - Preview

        /// A view model wired to doubles, so a canvas draws the screen without
        /// opening a socket and without reading what the application stored.
        ///
        /// The room holds one peer of the opposite role and one of the same, which
        /// is what shows both states of the button that starts a meeting.
        static var preview: RoomViewModel {
            let viewModel = RoomViewModel(
                signalingService: .preview,
                userAuthenticationService: .preview,
            )

            viewModel.signalingConnectionState = .connected
            viewModel.handle(event: .roomUserJoined(.Preview.callee))
            viewModel.handle(event: .roomUserJoined(.Preview.caller))

            return viewModel
        }
    }

#endif
