//
//  WebRTCService.swift
//  Services
//

import AVFoundation
import Foundation
@preconcurrency import WebRTC

/// One instance serves one meeting. The initializer only remembers what it was
/// given, connect builds the connection and the media, and disconnect takes it
/// all down for good, which is why the coordinator builds a service when it
/// opens the screen of a meeting rather than keeping one around.
public actor WebRTCService: WebRTCServiceProtocol {

    // MARK: - Factory

    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()

        return RTCPeerConnectionFactory(
            encoderFactory: RTCDefaultVideoEncoderFactory(),
            decoderFactory: RTCDefaultVideoDecoderFactory(),
        )
    }()

    // MARK: - Constraints

    private static let mediaConstraints = [
        kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue,
    ]

    // MARK: - Identifiers

    private static let audioTrackId = "local_audio_track"
    private static let videoTrackId = "local_video_track"

    // MARK: - Resources

    /// A recording that stands in for the front camera where there is none,
    /// played into the same source a real camera would feed.
    private static let simulatorFrontCameraFileName = "SimulatorFrontCamera.mp4"

    // MARK: - Properties

    private let iceServers: [String]

    private var peerConnection: RTCPeerConnection?
    private var videoCapturer: RTCVideoCapturer?

    /// The connection holds its delegate weakly, so the actor keeps the
    /// observer alive for as long as the connection is in use.
    private var peerConnectionObserver: PeerConnectionObserver?

    /// Disconnect ends both streams, so a second connect would build a
    /// connection nobody could ever hear from. This says the service is spent.
    private var isClosed: Bool = false

    /// Candidates of the other side that arrived before its description,
    /// applied once that description lands.
    private var queuedRemoteCandidates: [RTCIceCandidate] = []

    /// How many candidates wait for the description of the other side, which is
    /// what a test reads to see that queueing happened at all.
    var queuedRemoteCandidateCount: Int {
        queuedRemoteCandidates.count
    }

    // MARK: - Tracks

    /// The camera of this side, ready as soon as connect returns.
    public private(set) var localVideoTrack: RTCVideoTrack?

    // MARK: - Streams

    // Both streams carry what arrives later rather than what is ready now, and
    // both are meant for a single reader, because a second one would take
    // elements away from the first. They buffer without bound, so whatever the
    // connection produced before anyone started reading is still delivered.

    public let iceCandidateStream: AsyncStream<IceCandidate>
    public let remoteVideoTrackStream: AsyncStream<RTCVideoTrack>

    private let iceCandidateContinuation: AsyncStream<IceCandidate>.Continuation
    private let remoteVideoTrackContinuation: AsyncStream<RTCVideoTrack>.Continuation

    // MARK: - Init

    /// Holds the addresses and opens the streams, nothing more, so building a
    /// service costs nothing and never touches the camera. Raising a connection
    /// waits for connect, which runs on the executor of the actor rather than
    /// on the thread that pushed a screen.
    public init(iceServers: [String]) {
        self.iceServers = iceServers

        (iceCandidateStream, iceCandidateContinuation) = AsyncStream.makeStream(
            of: IceCandidate.self,
            bufferingPolicy: .unbounded,
        )

        (remoteVideoTrackStream, remoteVideoTrackContinuation) = AsyncStream.makeStream(
            of: RTCVideoTrack.self,
            bufferingPolicy: .unbounded,
        )
    }

    // MARK: - Connect

    /// Raises the connection, adds the microphone and the camera of this side,
    /// and starts listening to the connection. Connecting twice does nothing,
    /// connecting after disconnect throws, because the instance is spent.
    public func connect() throws {
        guard !isClosed else { throw WebRTCServiceError.connectionClosed }
        guard peerConnection == nil else { return }

        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: iceServers)]
        configuration.sdpSemantics = .unifiedPlan
        configuration.continualGatheringPolicy = .gatherContinually

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue],
        )

        guard let peerConnection = Self.factory.peerConnection(
            with: configuration,
            constraints: constraints,
            delegate: nil,
        ) else {
            debugPrint("The factory refused to build a peer connection.")
            throw WebRTCServiceError.peerConnectionCreationFailed
        }

        configureAudioSession()

        // Audio.
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = Self.factory.audioSource(with: audioConstraints)
        let audioTrack = Self.factory.audioTrack(with: audioSource, trackId: Self.audioTrackId)
        peerConnection.add(audioTrack, streamIds: [Self.audioTrackId])

        // Video.
        let videoSource = Self.factory.videoSource()
        let videoCapturer: RTCVideoCapturer

        #if targetEnvironment(simulator)
            videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
        #else
            videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        #endif

        let videoTrack = Self.factory.videoTrack(with: videoSource, trackId: Self.videoTrackId)
        peerConnection.add(videoTrack, streamIds: [Self.videoTrackId])

        let observer = PeerConnectionObserver(
            iceCandidateContinuation: iceCandidateContinuation,
            remoteVideoTrackContinuation: remoteVideoTrackContinuation,
        )

        peerConnection.delegate = observer

        self.peerConnection = peerConnection
        self.videoCapturer = videoCapturer
        peerConnectionObserver = observer
        localVideoTrack = videoTrack
    }

    // MARK: - Audio

    /// Routes the meeting to the speaker rather than to the earpiece, which is
    /// what a video call is expected to sound like. A failure here still leaves
    /// the meeting audible on the default route, so it is logged, not thrown.
    private func configureAudioSession() {
        let session = RTCAudioSession.sharedInstance()
        session.lockForConfiguration()

        defer {
            session.unlockForConfiguration()
        }

        do {
            try session.setCategory(.playAndRecord, mode: .videoChat, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            debugPrint("The audio session was not configured, \(error).")
        }
    }

    // MARK: - Disconnect

    /// Takes the meeting down and ends both streams, so their readers finish
    /// instead of waiting on a connection that is gone. Calling it twice is
    /// harmless, calling connect afterwards is not allowed.
    public func disconnect() {
        isClosed = true

        peerConnection?.delegate = nil
        stopCaptureLocalVideo()

        localVideoTrack?.isEnabled = false
        localVideoTrack = nil

        queuedRemoteCandidates.removeAll()

        peerConnection?.close()
        peerConnection = nil
        videoCapturer = nil
        peerConnectionObserver = nil

        iceCandidateContinuation.finish()
        remoteVideoTrackContinuation.finish()
    }

    // MARK: - Offer

    public func offer() async throws -> SessionDescription {
        debugPrint("Creating offer.")

        guard let peerConnection else { throw WebRTCServiceError.peerConnectionUnavailable }
        let constraints = RTCMediaConstraints(mandatoryConstraints: Self.mediaConstraints, optionalConstraints: nil)

        let sdp = try await localDescription(of: peerConnection, kind: "offer") { handler in
            peerConnection.offer(for: constraints, completionHandler: handler)
        }

        return try Self.sessionDescription(from: sdp)
    }

    // MARK: - Answer

    public func answer() async throws -> SessionDescription {
        debugPrint("Creating answer.")

        guard let peerConnection else { throw WebRTCServiceError.peerConnectionUnavailable }
        let constraints = RTCMediaConstraints(mandatoryConstraints: Self.mediaConstraints, optionalConstraints: nil)

        let sdp = try await localDescription(of: peerConnection, kind: "answer") { handler in
            peerConnection.answer(for: constraints, completionHandler: handler)
        }

        return try Self.sessionDescription(from: sdp)
    }

    // MARK: - Local

    /// Offer and answer differ in one call, so the pair of steps they share,
    /// producing a description and adopting it as the one of this side, lives
    /// here once. The connection stays captured, so the handler always fires
    /// and resumes exactly once, even when disconnect runs in the meantime.
    private func localDescription(
        of peerConnection: RTCPeerConnection,
        kind: String,
        create: (@escaping @Sendable (RTCSessionDescription?, Error?) -> Void) -> Void,
    ) async throws -> RTCSessionDescription {
        try await withCheckedThrowingContinuation { continuation in
            create { sdp, error in
                guard let sdp else {
                    debugPrint("The \(kind) was not created, \(String(describing: error)).")
                    continuation.resume(throwing: WebRTCServiceError.sessionDescriptionCreationFailed)
                    return
                }

                peerConnection.setLocalDescription(sdp) { error in
                    if let error {
                        debugPrint("The \(kind) was not adopted as the description of this side, \(error).")
                        continuation.resume(throwing: WebRTCServiceError.localDescriptionFailed)
                    } else {
                        debugPrint("The \(kind) was adopted as the description of this side.")
                        continuation.resume(returning: sdp)
                    }
                }
            }
        }
    }

    /// The wrapper refuses a type this application does not model, and a
    /// description nobody can carry over the socket is a failure rather than a
    /// silent nothing.
    private static func sessionDescription(from sdp: RTCSessionDescription) throws -> SessionDescription {
        guard let sessionDescription = SessionDescription(sdp) else {
            debugPrint("A session description of an unsupported type was produced.")
            throw WebRTCServiceError.sessionDescriptionUnsupported
        }

        return sessionDescription
    }

    // MARK: - Set

    public func set(remoteSdp: SessionDescription) async throws {
        guard let peerConnection else { throw WebRTCServiceError.peerConnectionUnavailable }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            peerConnection.setRemoteDescription(remoteSdp.rtcSessionDescription) { error in
                if let error {
                    debugPrint("The description of the other side was refused, \(error).")
                    continuation.resume(throwing: WebRTCServiceError.remoteDescriptionFailed)
                } else {
                    continuation.resume()
                }
            }
        }

        // The queue is emptied before the candidates are applied, so a failure
        // partway does not leave applied candidates behind to be applied a
        // second time when the next description arrives.
        let queued = queuedRemoteCandidates
        queuedRemoteCandidates.removeAll()

        for candidate in queued {
            try await add(remoteCandidate: candidate)
        }
    }

    public func set(remoteCandidate: IceCandidate) async throws {
        guard let peerConnection else { throw WebRTCServiceError.peerConnectionUnavailable }

        // Candidates may arrive over the socket before the description of the
        // other side is set, adding them at that point fails and the candidate
        // is lost, so they wait until setting that description drains them.
        guard peerConnection.remoteDescription != nil else {
            queuedRemoteCandidates.append(remoteCandidate.rtcIceCandidate)
            return
        }

        try await add(remoteCandidate: remoteCandidate.rtcIceCandidate)
    }

    private func add(remoteCandidate: RTCIceCandidate) async throws {
        guard let peerConnection else { throw WebRTCServiceError.peerConnectionUnavailable }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            peerConnection.add(remoteCandidate) { error in
                if let error {
                    debugPrint("A candidate of the other side was refused, \(error).")
                    continuation.resume(throwing: WebRTCServiceError.remoteCandidateFailed)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Capture

    public func startCaptureLocalVideo() {
        #if targetEnvironment(simulator)
            startFileCapture(named: Self.simulatorFrontCameraFileName)
        #else
            startCameraCapture()
        #endif
    }

    private func stopCaptureLocalVideo() {
        switch videoCapturer {
        case let capturer as RTCCameraVideoCapturer:
            capturer.stopCapture()
        case let capturer as RTCFileVideoCapturer:
            capturer.stopCapture()
        default:
            break
        }
    }

    // MARK: - File

    private func startFileCapture(named fileName: String) {
        guard let capturer = videoCapturer as? RTCFileVideoCapturer else { return }

        guard Bundle.main.path(forResource: fileName, ofType: nil) != nil else {
            debugPrint("File \(fileName) is missing from the main bundle.")
            return
        }

        capturer.startCapturing(fromFileNamed: fileName) { error in
            debugPrint("Failed to start file capture \(error).")
        }
    }

    // MARK: - Camera

    private func startCameraCapture() {
        guard
            let capturer = videoCapturer as? RTCCameraVideoCapturer,
            let camera = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == .front }),
            let format = RTCCameraVideoCapturer.supportedFormats(for: camera)
            .max(by: {
                CMVideoFormatDescriptionGetDimensions($0.formatDescription).width <
                    CMVideoFormatDescriptionGetDimensions($1.formatDescription).width
            }),
            let fps = format.videoSupportedFrameRateRanges
            .max(by: { $0.maxFrameRate < $1.maxFrameRate })
        else { return }

        capturer.startCapture(
            with: camera,
            format: format,
            fps: Int(fps.maxFrameRate),
        )
    }
}
