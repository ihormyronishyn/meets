//
//  MeetViewModelTests.swift
//  Meet
//

import Entities
import Foundation
import Services
import Testing
@preconcurrency import WebRTC
@testable import Meet

@Suite
@MainActor
final class MeetViewModelTests {

    // MARK: - Properties

    private let signalingService: SignalingServiceSpy
    private let webRTCService: WebRTCServiceSpy
    private let router: MeetRoutingSpy
    private let viewModel: MeetViewModel

    // MARK: - Setup

    init() {
        // The view model keeps the router weakly, so the suite holds it.
        signalingService = SignalingServiceSpy()
        webRTCService = WebRTCServiceSpy()
        router = MeetRoutingSpy()
        viewModel = MeetViewModel(
            meet: Meet(localPeer: .Preview.local, remotePeer: .Preview.callee),
            signalingService: signalingService,
            webRTCService: webRTCService,
        )
        viewModel.router = router
    }

    // MARK: - Start

    @Test(.timeLimit(.minutes(1)))
    func startingRaisesTheConnection() async {
        await viewModel.start()
        #expect(await webRTCService.connectCallCount == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func startingPublishesTheCameraOfThisSide() async {
        await viewModel.start()
        #expect(viewModel.localVideoTrack != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func startingBeginsTheCapture() async {
        await viewModel.start()
        #expect(await webRTCService.startCaptureCallCount == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func startingTwiceDoesTheWorkOnce() async {
        await viewModel.start()
        await viewModel.start()

        #expect(await webRTCService.connectCallCount == 1)
        #expect(await webRTCService.startCaptureCallCount == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func aConnectionThatFailsToRiseStopsTheStart() async {
        await webRTCService.failTheConnection()

        await viewModel.start()

        #expect(viewModel.localVideoTrack == nil)
        #expect(await webRTCService.startCaptureCallCount == .zero)
    }

    // MARK: - Announce

    @Test(.timeLimit(.minutes(1)))
    func theCallerAnnouncesTheMeetingWithAnOffer() async {
        await viewModel.start()
        #expect(await signalingService.emittedNames == [.offer])
    }

    @Test(.timeLimit(.minutes(1)))
    func theCalleeAnnouncesTheMeetingWithAnAnswer() async {
        let viewModel = MeetViewModel(
            meet: Meet(localPeer: .Preview.callee, remotePeer: .Preview.caller),
            signalingService: signalingService,
            webRTCService: webRTCService,
        )

        await viewModel.start()

        #expect(await signalingService.emittedNames == [.answer])
    }

    // MARK: - Observe

    @Test(.timeLimit(.minutes(1)))
    func aCandidateOfThisSideGoesOutOverTheSocket() async {
        await viewModel.start()

        await webRTCService.send(candidate: Self.candidate())
        await waitUntil { await self.signalingService.emittedNames.contains(PeerEvent.Name.candidate) }

        #expect(await signalingService.emittedNames.contains(PeerEvent.Name.candidate))
    }

    @Test(.timeLimit(.minutes(1)))
    func theTrackOfTheOtherSideReachesTheScreen() async {
        await viewModel.start()

        await webRTCService.sendRemoteVideoTrack()
        await waitUntil { self.viewModel.remoteVideoTrack != nil }

        #expect(viewModel.remoteVideoTrack != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func anEventFromTheSocketIsHandled() async {
        await viewModel.start()

        await signalingService.send(event: .candidate(Self.candidate()))
        await waitUntil { await self.webRTCService.remoteCandidateCount == 1 }

        #expect(await webRTCService.remoteCandidateCount == 1)
    }

    // MARK: - Offer

    @Test
    func anOfferCarryingADescriptionIsAppliedAndAnswered() async throws {
        try await viewModel.handle(event: .offer(.sdp(Self.sessionDescription())))

        #expect(await webRTCService.remoteSdpCount == 1)
        #expect(await webRTCService.answerCallCount == 1)
        #expect(await signalingService.emittedNames == [.answer])
    }

    @Test
    func anOfferCarryingACallIsIgnored() async throws {
        try await viewModel.handle(event: .offer(.call(.init(from: .Preview.caller, to: .Preview.callee))))

        #expect(await webRTCService.remoteSdpCount == .zero)
        #expect(await signalingService.emittedNames.isEmpty)
    }

    // MARK: - Answer

    @Test
    func anAnswerCarryingACallSendsTheRealOffer() async throws {
        try await viewModel.handle(event: .answer(.call(.init(from: .Preview.local, to: .Preview.callee))))

        #expect(await webRTCService.offerCallCount == 1)
        #expect(await signalingService.emittedNames == [.offer])
    }

    @Test
    func anAnswerCarryingADescriptionIsApplied() async throws {
        try await viewModel.handle(event: .answer(.sdp(Self.sessionDescription())))

        #expect(await webRTCService.remoteSdpCount == 1)
        #expect(await signalingService.emittedNames.isEmpty)
    }

    // MARK: - Candidate

    @Test
    func aCandidateOfTheOtherSideIsApplied() async throws {
        try await viewModel.handle(event: .candidate(Self.candidate()))
        #expect(await webRTCService.remoteCandidateCount == 1)
    }

    // MARK: - Room

    @Test
    func aPeerJoiningTheRoomChangesNothing() async throws {
        try await viewModel.handle(event: .roomUserJoined(.Preview.caller))

        #expect(await webRTCService.disconnectCallCount == .zero)
        #expect(router.didLeaveCallCount == .zero)
    }

    @Test
    func aPeerLeavingEndsTheMeeting() async throws {
        try await viewModel.handle(event: .roomUserLeft(.Preview.callee))

        #expect(await webRTCService.disconnectCallCount == 1)
        #expect(router.didLeaveCallCount == 1)
    }

    // MARK: - Leave

    @Test
    func leavingTearsDownBothServicesAndRoutes() async {
        await viewModel.leaveMeet()

        #expect(await signalingService.disconnectCallCount == 1)
        #expect(await webRTCService.disconnectCallCount == 1)
        #expect(router.didLeaveCallCount == 1)
    }

    // MARK: - Helpers

    private static func candidate() -> IceCandidate {
        IceCandidate(RTCIceCandidate(sdp: "candidate", sdpMLineIndex: 0, sdpMid: "0"))
    }

    private static func sessionDescription() throws -> SessionDescription {
        try #require(SessionDescription(RTCSessionDescription(type: .offer, sdp: "")))
    }

    /// Waits for work carried by a task rather than by the call under test, so
    /// an expectation reads a settled state instead of a racing one.
    private func waitUntil(_ condition: () async -> Bool) async {
        for _ in 0 ..< 100 where await !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
