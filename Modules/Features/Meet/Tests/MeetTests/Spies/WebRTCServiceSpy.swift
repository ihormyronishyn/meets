//
//  WebRTCServiceSpy.swift
//  Meet
//

import Foundation
import Services
@preconcurrency import WebRTC

actor WebRTCServiceSpy: WebRTCServiceProtocol {

    // MARK: - Properties

    private(set) var connectCallCount: Int = .zero
    private(set) var disconnectCallCount: Int = .zero
    private(set) var startCaptureCallCount: Int = .zero
    private(set) var offerCallCount: Int = .zero
    private(set) var answerCallCount: Int = .zero
    private(set) var remoteSdpCount: Int = .zero
    private(set) var remoteCandidateCount: Int = .zero

    private(set) var localVideoTrack: RTCVideoTrack?

    private var shouldFailTheConnection: Bool = false
    private let factory = RTCPeerConnectionFactory()

    // MARK: - Streams

    let iceCandidateStream: AsyncStream<IceCandidate>
    let remoteVideoTrackStream: AsyncStream<RTCVideoTrack>

    private let iceCandidateContinuation: AsyncStream<IceCandidate>.Continuation
    private let remoteVideoTrackContinuation: AsyncStream<RTCVideoTrack>.Continuation

    // MARK: - Init

    init() {
        (iceCandidateStream, iceCandidateContinuation) = AsyncStream.makeStream(
            of: IceCandidate.self,
            bufferingPolicy: .unbounded,
        )

        (remoteVideoTrackStream, remoteVideoTrackContinuation) = AsyncStream.makeStream(
            of: RTCVideoTrack.self,
            bufferingPolicy: .unbounded,
        )
    }

    // MARK: - Connection

    func connect() throws {
        connectCallCount += 1

        guard !shouldFailTheConnection else {
            throw WebRTCServiceError.peerConnectionCreationFailed
        }

        localVideoTrack = videoTrack(id: "local")
    }

    func disconnect() {
        disconnectCallCount += 1
    }

    // MARK: - Session

    func offer() async throws -> SessionDescription {
        offerCallCount += 1
        return try sessionDescription(of: .offer)
    }

    func answer() async throws -> SessionDescription {
        answerCallCount += 1
        return try sessionDescription(of: .answer)
    }

    // MARK: - Set

    func set(remoteSdp _: SessionDescription) async throws {
        remoteSdpCount += 1
    }

    func set(remoteCandidate _: IceCandidate) async throws {
        remoteCandidateCount += 1
    }

    // MARK: - Media

    func startCaptureLocalVideo() {
        startCaptureCallCount += 1
    }

    // MARK: - Send

    func send(candidate: IceCandidate) {
        iceCandidateContinuation.yield(candidate)
    }

    func sendRemoteVideoTrack() {
        remoteVideoTrackContinuation.yield(videoTrack(id: "remote"))
    }

    func failTheConnection() {
        shouldFailTheConnection = true
    }

    // MARK: - Helpers

    private func videoTrack(id: String) -> RTCVideoTrack {
        factory.videoTrack(with: factory.videoSource(), trackId: id)
    }

    private func sessionDescription(of type: RTCSdpType) throws -> SessionDescription {
        guard let sessionDescription = SessionDescription(RTCSessionDescription(type: type, sdp: "")) else {
            throw WebRTCServiceError.sessionDescriptionUnsupported
        }

        return sessionDescription
    }
}
