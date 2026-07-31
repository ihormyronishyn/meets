//
//  PeerConnectionObserver.swift
//  Services
//

import Foundation
@preconcurrency import WebRTC

/// The delegate of a peer connection is an objective c protocol, so an actor
/// cannot conform to it. This proxy takes the two callbacks the service acts
/// on, a generated candidate and the arrival of the track of the other side,
/// and yields them into the streams of the service through Sendable
/// continuations, without hopping executors. Everything else only reaches the log.
final class PeerConnectionObserver: NSObject, RTCPeerConnectionDelegate, @unchecked Sendable {

    // MARK: - Properties

    private let iceCandidateContinuation: AsyncStream<IceCandidate>.Continuation
    private let remoteVideoTrackContinuation: AsyncStream<RTCVideoTrack>.Continuation

    // MARK: - Init

    init(
        iceCandidateContinuation: AsyncStream<IceCandidate>.Continuation,
        remoteVideoTrackContinuation: AsyncStream<RTCVideoTrack>.Continuation,
    ) {
        self.iceCandidateContinuation = iceCandidateContinuation
        self.remoteVideoTrackContinuation = remoteVideoTrackContinuation
    }

    // MARK: - Candidates

    func peerConnection(_: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        debugPrint("Peer connection did generate candidate \(candidate).")

        // The candidate is converted here, at the edge, so the type of the
        // framework never leaves this file.
        iceCandidateContinuation.yield(IceCandidate(candidate))
    }

    func peerConnection(_: RTCPeerConnection, didRemove _: [RTCIceCandidate]) {
        debugPrint("Peer connection did remove candidates.")
    }

    // MARK: - Receivers

    /// The track of the other side exists only once the description of that
    /// side has been applied, and it is replaced whenever the two negotiate
    /// again, so it is reported as it arrives rather than read once.
    func peerConnection(_: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams _: [RTCMediaStream]) {
        guard let track = rtpReceiver.track as? RTCVideoTrack else { return }
        debugPrint("Peer connection did add the video track of the other side.")
        remoteVideoTrackContinuation.yield(track)
    }

    func peerConnection(_: RTCPeerConnection, didRemove _: RTCRtpReceiver) {
        debugPrint("Peer connection did remove a receiver.")
    }

    // MARK: - States

    func peerConnection(_: RTCPeerConnection, didChange state: RTCSignalingState) {
        debugPrint("Peer connection changed signaling state to \(state).")
    }

    func peerConnection(_: RTCPeerConnection, didChange state: RTCIceConnectionState) {
        debugPrint("Peer connection changed connection state to \(state).")
    }

    func peerConnection(_: RTCPeerConnection, didChange state: RTCIceGatheringState) {
        debugPrint("Peer connection changed gathering state to \(state).")
    }

    func peerConnectionShouldNegotiate(_: RTCPeerConnection) {
        debugPrint("Peer connection should negotiate.")
    }

    // MARK: - Streams

    func peerConnection(_: RTCPeerConnection, didAdd _: RTCMediaStream) {
        debugPrint("Peer connection did add stream.")
    }

    func peerConnection(_: RTCPeerConnection, didRemove _: RTCMediaStream) {
        debugPrint("Peer connection did remove stream.")
    }

    func peerConnection(_: RTCPeerConnection, didOpen _: RTCDataChannel) {
        debugPrint("Peer connection did open data channel.")
    }
}
