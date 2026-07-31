//
//  WebRTCServiceTests.swift
//  ServicesTests
//

import Foundation
import Testing
@preconcurrency import WebRTC
@testable import Services

@Suite
struct WebRTCServiceTests {

    // MARK: - Helpers

    /// A candidate of the shape the wrapper needs, without asking a connection
    /// to gather a real one.
    static func candidate() -> IceCandidate {
        IceCandidate(RTCIceCandidate(sdp: "candidate:0 1 UDP 1 127.0.0.1 5000 typ host", sdpMLineIndex: 0, sdpMid: "0"))
    }

    /// An empty description, enough for a call that is refused before it ever
    /// reaches the connection.
    static func sessionDescription() throws -> SessionDescription {
        try #require(SessionDescription(RTCSessionDescription(type: .offer, sdp: "")))
    }

    // MARK: - Tests

    @Test
    func buildingTheServiceTouchesNeitherTheConnectionNorTheCamera() async {
        let service = WebRTCService(iceServers: [])
        #expect(await service.localVideoTrack == nil)
    }

    @Test
    func anOfferIsRefusedBeforeConnect() async {
        let service = WebRTCService(iceServers: [])

        await #expect(throws: WebRTCServiceError.peerConnectionUnavailable) {
            try await service.offer()
        }
    }

    @Test
    func anAnswerIsRefusedBeforeConnect() async {
        let service = WebRTCService(iceServers: [])

        await #expect(throws: WebRTCServiceError.peerConnectionUnavailable) {
            try await service.answer()
        }
    }

    @Test
    func theDescriptionOfTheOtherSideIsRefusedBeforeConnect() async throws {
        let service = WebRTCService(iceServers: [])
        let sdp = try Self.sessionDescription()

        await #expect(throws: WebRTCServiceError.peerConnectionUnavailable) {
            try await service.set(remoteSdp: sdp)
        }
    }

    @Test
    func aCandidateIsRefusedRatherThanQueuedBeforeConnect() async {
        let service = WebRTCService(iceServers: [])

        await #expect(throws: WebRTCServiceError.peerConnectionUnavailable) {
            try await service.set(remoteCandidate: Self.candidate())
        }

        #expect(await service.queuedRemoteCandidateCount == 0)
    }
}

// MARK: - Connected

/// Every test here raises a real connection, and the framework behind it keeps
/// one signaling thread for the whole process, which it blocks while it works.
/// Running these in parallel starves the pool that carries them and the run
/// stops making progress, so the suite takes them one at a time.
@Suite(.serialized)
struct ConnectedWebRTCServiceTests {

    // MARK: - Properties

    private let iceServers = ["stun:stun.l.google.com:19302"]

    // MARK: - Tests

    @Test
    func connectRaisesTheCameraOfThisSideAndKeepsItOnASecondCall() async throws {
        let service = WebRTCService(iceServers: iceServers)
        try await service.connect()

        let track = try #require(await service.localVideoTrack)
        try await service.connect()

        #expect(await service.localVideoTrack === track)
        await service.disconnect()
    }

    @Test
    func anOfferCarriesTheAudioAndTheVideoOfThisSide() async throws {
        let service = WebRTCService(iceServers: iceServers)
        try await service.connect()

        let sdp = try await service.offer().rtcSessionDescription

        #expect(sdp.type == .offer)
        #expect(sdp.sdp.contains("m=audio"))
        #expect(sdp.sdp.contains("m=video"))

        await service.disconnect()
    }

    @Test
    func aCandidateWaitsForTheDescriptionOfTheOtherSideAndIsAppliedWithIt() async throws {
        let caller = WebRTCService(iceServers: iceServers)
        let callee = WebRTCService(iceServers: iceServers)

        try await caller.connect()
        try await callee.connect()

        try await callee.set(remoteCandidate: WebRTCServiceTests.candidate())
        #expect(await callee.queuedRemoteCandidateCount == 1)

        // A real offer from the other connection is what makes the description
        // acceptable, so the queue has something to drain into.
        let offer = try await caller.offer()
        try await callee.set(remoteSdp: offer)

        #expect(await callee.queuedRemoteCandidateCount == 0)

        await caller.disconnect()
        await callee.disconnect()
    }

    @Test
    func disconnectReleasesTheCameraTheQueueAndEndsBothStreams() async throws {
        let service = WebRTCService(iceServers: iceServers)
        try await service.connect()
        try await service.set(remoteCandidate: WebRTCServiceTests.candidate())

        let iceCandidateStream = await service.iceCandidateStream
        let remoteVideoTrackStream = await service.remoteVideoTrackStream

        await service.disconnect()
        await service.disconnect()

        #expect(await service.localVideoTrack == nil)
        #expect(await service.queuedRemoteCandidateCount == 0)

        // Both loops end at all, which is the point. Nobody is left waiting on
        // a connection that is gone.
        for await _ in iceCandidateStream {}

        var tracks: [RTCVideoTrack] = []

        for await track in remoteVideoTrackStream {
            tracks.append(track)
        }

        #expect(tracks.isEmpty)
    }

    @Test
    func everyStepIsRefusedAfterDisconnect() async throws {
        let service = WebRTCService(iceServers: iceServers)
        try await service.connect()
        await service.disconnect()

        await #expect(throws: WebRTCServiceError.connectionClosed) {
            try await service.connect()
        }

        await #expect(throws: WebRTCServiceError.peerConnectionUnavailable) {
            try await service.offer()
        }

        await #expect(throws: WebRTCServiceError.peerConnectionUnavailable) {
            try await service.set(remoteCandidate: WebRTCServiceTests.candidate())
        }
    }
}
