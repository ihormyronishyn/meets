//
//  RoomViewModelTests.swift
//  Room
//

import Entities
import Foundation
import Services
import Testing
@testable import Room

@Suite
@MainActor
final class RoomViewModelTests {

    // MARK: - Properties

    private let signalingService: SignalingServiceSpy
    private let userAuthenticationService: UserAuthenticationServiceStub
    private let router: RoomRoutingSpy
    private let viewModel: RoomViewModel

    // MARK: - Setup

    init() {
        // The view model keeps the router weakly, so the suite holds it.
        signalingService = SignalingServiceSpy()
        userAuthenticationService = UserAuthenticationServiceStub()
        router = RoomRoutingSpy()
        viewModel = RoomViewModel(
            signalingService: signalingService,
            userAuthenticationService: userAuthenticationService,
        )
        viewModel.router = router
    }

    // MARK: - Tests

    @Test
    func localPeerIsAbsentWithoutCredentials() {
        // Assert.
        #expect(viewModel.localPeer == nil)
    }

    @Test
    func localPeerCarriesTheStoredCredentials() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        // Act.
        let peer = viewModel.localPeer

        // Assert.
        #expect(peer?.username == "John")
        #expect(peer?.roomId == 7)
        #expect(peer?.isCaller == true)
    }

    @Test
    func aPeerOfTheOppositeRoleIsAvailable() {
        // Arrange.
        viewModel.isCaller = true

        // Assert.
        #expect(viewModel.isPeerAvailable(Self.peer(named: "Alex", isCaller: false)))
    }

    @Test
    func aPeerOfTheSameRoleIsNotAvailable() {
        // Arrange.
        viewModel.isCaller = true

        // Assert.
        #expect(viewModel.isPeerAvailable(Self.peer(named: "Alex", isCaller: true)) == false)
    }

    @Test
    func aCalleeSeesOnlyThePeerThatIsCallingIt() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)
        viewModel.isCaller = false

        let silent = Self.peer(named: "Alex", isCaller: true)
        let calling = Self.peer(named: "Mary", isCaller: true)

        // Act.
        viewModel.handle(event: Self.offer(from: calling, to: Self.peer(named: "John", isCaller: false)))

        // Assert.
        #expect(viewModel.isPeerAvailable(silent) == false)
        #expect(viewModel.isPeerAvailable(calling))
    }

    @Test
    func aJoinedPeerIsAddedOnce() {
        // Arrange.
        let peer = Self.peer(named: "Alex", isCaller: false)

        // Act.
        viewModel.handle(event: .roomUserJoined(peer))
        viewModel.handle(event: .roomUserJoined(peer))

        // Assert.
        #expect(viewModel.peers.count == 1)
    }

    @Test
    func aLeavingPeerIsRemoved() {
        // Arrange.
        let peer = Self.peer(named: "Alex", isCaller: false)
        viewModel.handle(event: .roomUserJoined(peer))

        // Act.
        viewModel.handle(event: .roomUserLeft(peer))

        // Assert.
        #expect(viewModel.peers.isEmpty)
    }

    @Test
    func aLeavingPeerForgetsTheCallItWasMaking() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        let caller = Self.peer(named: "Alex", isCaller: true)
        viewModel.handle(event: Self.offer(from: caller, to: Self.peer(named: "John", isCaller: false)))

        // Act.
        viewModel.handle(event: .roomUserLeft(caller))

        // Assert.
        // A name that comes back later is somebody who has not called yet.
        #expect(viewModel.incomingCalls.isEmpty)
    }

    @Test
    func anOfferAddressedToUsMarksTheCallerAsCalling() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        let caller = Self.peer(named: "Alex", isCaller: true)
        viewModel.handle(event: .roomUserJoined(caller))

        // Act.
        viewModel.handle(event: Self.offer(from: caller, to: Self.peer(named: "John", isCaller: false)))

        // Assert.
        // The caller already sat in the room, so joining it a second time adds
        // nobody, and the call is remembered beside the room rather than on it.
        #expect(viewModel.peers.count == 1)
        #expect(viewModel.incomingCalls == ["Alex"])
    }

    @Test
    func anOfferFromSomebodyTheRoomHasNotReportedYetStillJoins() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        let caller = Self.peer(named: "Alex", isCaller: true)

        // Act.
        viewModel.handle(event: Self.offer(from: caller, to: Self.peer(named: "John", isCaller: false)))

        // Assert.
        // An offer can outrun the report that its sender is in the room, and a
        // callee that ignored it would have nobody to answer.
        #expect(viewModel.peers.map(\.username) == ["Alex"])
        #expect(viewModel.incomingCalls == ["Alex"])
    }

    @Test
    func anOfferForSomebodyElseChangesNothing() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        let caller = Self.peer(named: "Alex", isCaller: true)
        viewModel.handle(event: .roomUserJoined(caller))

        // Act.
        viewModel.handle(event: Self.offer(from: caller, to: Self.peer(named: "Mary", isCaller: false)))

        // Assert.
        #expect(viewModel.incomingCalls.isEmpty)
    }

    @Test
    func anAnswerBetweenOthersRemovesBothOfThem() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        let first = Self.peer(named: "Alex", isCaller: true)
        let second = Self.peer(named: "Mary", isCaller: false)

        viewModel.handle(event: .roomUserJoined(first))
        viewModel.handle(event: .roomUserJoined(second))

        // Act.
        viewModel.handle(event: .answer(.call(.init(from: first, to: second))))

        // Assert.
        // Both are busy with each other now, so neither is worth offering.
        #expect(viewModel.peers.isEmpty)
    }

    @Test
    func anAnswerAddressedToUsKeepsTheRoom() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        let caller = Self.peer(named: "Alex", isCaller: true)
        viewModel.handle(event: .roomUserJoined(caller))

        // Act.
        viewModel.handle(event: .answer(.call(.init(from: caller, to: Self.peer(named: "John", isCaller: false)))))

        // Assert.
        #expect(viewModel.peers.count == 1)
    }

    @Test
    func startingAVideoChatRoutesWithBothPeers() {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        let remote = Self.peer(named: "Alex", isCaller: false)

        // Act.
        viewModel.startMeet(with: remote)

        // Assert.
        #expect(router.startedMeet?.localPeer.username == "John")
        #expect(router.startedMeet?.remotePeer.username == "Alex")
    }

    @Test
    func startingAVideoChatWithoutCredentialsRoutesNowhere() {
        // Act.
        viewModel.startMeet(with: Self.peer(named: "Alex", isCaller: false))

        // Assert.
        #expect(router.startedMeet == nil)
    }

    @Test
    func leavingClearsTheRoomAndSignsOut() async {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)
        viewModel.handle(event: .roomUserJoined(Self.peer(named: "Alex", isCaller: false)))

        // Act.
        await viewModel.leaveRoom()

        // Assert.
        #expect(viewModel.peers.isEmpty)
        #expect(await signalingService.disconnectCallCount == 1)
        #expect(userAuthenticationService.isAuthenticated == false)
        #expect(router.didLeaveCallCount == 1)
    }

    @Test
    func disconnectingEmptiesTheRoom() async {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        let caller = Self.peer(named: "Alex", isCaller: true)
        viewModel.handle(event: Self.offer(from: caller, to: Self.peer(named: "John", isCaller: false)))

        // Act.
        await viewModel.disconnect()

        // Assert.
        #expect(viewModel.peers.isEmpty)
        #expect(viewModel.incomingCalls.isEmpty)
        #expect(await signalingService.disconnectCallCount == 1)
    }

    @Test
    func aFullRoomIsNotReportedAsAFailure() {
        // Act.
        viewModel.signalingConnectionState = .roomIsFull

        // Assert.
        // The screen says something different about each, so collapsing a
        // refusal into a failure would blame the connection for a full room.
        #expect(viewModel.isRoomFull)
        #expect(viewModel.hasFailedToConnect == false)
        #expect(viewModel.isConnected == false)
        #expect(viewModel.isConnecting == false)
    }

    @Test
    func connectingWithoutCredentialsAsksNothingOfTheService() async {
        // Act.
        await viewModel.connect()

        // Assert.
        #expect(await signalingService.connectCallCount == .zero)
    }

    @Test(.timeLimit(.minutes(1)))
    func connectingListensBeforeItAsks() async {
        // Arrange.
        userAuthenticationService.login(username: "John", roomId: 7)

        // Act.
        await viewModel.connect()

        // Assert.
        // The service reports the first state during the request itself, and
        // nothing replays it, so a listener that arrives afterwards sees
        // nothing. Observing this state proves the order.
        for _ in 0 ..< 100 where viewModel.signalingConnectionState != .connecting {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(viewModel.signalingConnectionState == .connecting)
    }

    // MARK: - Peer

    private static func peer(named username: String, isCaller: Bool) -> Peer {
        Peer(roomId: 7, username: username, isCaller: isCaller)
    }

    // MARK: - Offer

    private static func offer(from: Peer, to: Peer) -> PeerEvent {
        .offer(.call(.init(from: from, to: to)))
    }
}

// MARK: - SignalingServiceSpy

private actor SignalingServiceSpy: SignalingServiceProtocol {

    // MARK: - Properties

    private(set) var connectCallCount: Int = .zero
    private(set) var disconnectCallCount: Int = .zero

    private var connectionStateContinuation: AsyncStream<ConnectionState>.Continuation?
    private var peerEventContinuation: AsyncStream<PeerEvent>.Continuation?

    // MARK: - Streams

    /// The continuation appears only once somebody asks for the stream, exactly
    /// as the real service behaves, so an event sent before that is lost.
    func connectionStates() async -> AsyncStream<ConnectionState> {
        AsyncStream { continuation in
            connectionStateContinuation = continuation
        }
    }

    func peerEvents() async -> AsyncStream<PeerEvent> {
        AsyncStream { continuation in
            peerEventContinuation = continuation
        }
    }

    // MARK: - Connection

    func connect(peer _: Peer) {
        connectCallCount += 1
        connectionStateContinuation?.yield(.connecting)
    }

    func disconnect() {
        disconnectCallCount += 1
        connectionStateContinuation?.yield(.disconnected)
    }

    // MARK: - Emit

    func emit(eventName _: PeerEvent.Name, payload _: some Encodable & Sendable) {
        // Nothing.
    }
}

// MARK: - UserAuthenticationServiceStub

@MainActor
private final class UserAuthenticationServiceStub: UserAuthenticationServiceProtocol {

    // MARK: - Properties

    private(set) var username: String?
    private(set) var roomId: Int?

    var isAuthenticated: Bool {
        username != nil && roomId != nil
    }

    // MARK: - Methods

    func login(username: String, roomId: Int) {
        self.username = username
        self.roomId = roomId
    }

    func logout() {
        username = nil
        roomId = nil
    }
}

// MARK: - RoomRoutingSpy

private final class RoomRoutingSpy: RoomRouting {

    // MARK: - Properties

    private(set) var didLeaveCallCount: Int = .zero
    private(set) var startedMeet: Meet?

    // MARK: - Methods

    func didLeaveRoom() {
        didLeaveCallCount += 1
    }

    func didStartMeet(_ meet: Meet) {
        startedMeet = meet
    }
}
