//
//  WebRTCServiceProtocol.swift
//  Services
//

import Foundation
@preconcurrency import WebRTC

/// Descriptions and candidates cross this boundary in the types of the
/// application, the same ones the socket carries, so a feature never has to
/// know the framework behind the meeting. A video track is the exception, it is
/// handed over as it is because rendering it is what a view does with it.
public protocol WebRTCServiceProtocol: Actor {

    // MARK: - Tracks

    var localVideoTrack: RTCVideoTrack? { get }

    // MARK: - Streams

    var iceCandidateStream: AsyncStream<IceCandidate> { get }
    var remoteVideoTrackStream: AsyncStream<RTCVideoTrack> { get }

    // MARK: - Connection

    func connect() throws
    func disconnect()

    // MARK: - Session

    func offer() async throws -> SessionDescription
    func answer() async throws -> SessionDescription

    // MARK: - Set

    func set(remoteSdp: SessionDescription) async throws
    func set(remoteCandidate: IceCandidate) async throws

    // MARK: - Media

    func startCaptureLocalVideo()
}
