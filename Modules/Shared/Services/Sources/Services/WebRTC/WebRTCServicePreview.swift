//
//  WebRTCServicePreview.swift
//  Services
//

#if DEBUG

    import Foundation
    @preconcurrency import WebRTC

    public actor WebRTCServicePreview: WebRTCServiceProtocol {

        // MARK: - Init

        public init() {
            // Nothing.
        }

        // MARK: - Tracks

        /// A canvas draws a placeholder where the camera would be, so nothing
        /// here asks the device for one.
        public let localVideoTrack: RTCVideoTrack? = nil

        // MARK: - Streams

        /// Both streams end at once, so a reader finishes instead of waiting,
        /// and a canvas keeps whatever state it was handed.
        public let iceCandidateStream: AsyncStream<IceCandidate> = AsyncStream { $0.finish() }
        public let remoteVideoTrackStream: AsyncStream<RTCVideoTrack> = AsyncStream { $0.finish() }

        // MARK: - Connection

        public func connect() throws {
            // Nothing.
        }

        public func disconnect() {
            // Nothing.
        }

        // MARK: - Session

        public func offer() async throws -> SessionDescription {
            try Self.sessionDescription(of: .offer)
        }

        public func answer() async throws -> SessionDescription {
            try Self.sessionDescription(of: .answer)
        }

        /// An empty description of the asked type, enough to satisfy a caller
        /// that only passes it along.
        private static func sessionDescription(of type: RTCSdpType) throws -> SessionDescription {
            guard let sessionDescription = SessionDescription(RTCSessionDescription(type: type, sdp: "")) else {
                throw WebRTCServiceError.sessionDescriptionUnsupported
            }

            return sessionDescription
        }

        // MARK: - Set

        public func set(remoteSdp _: SessionDescription) async throws {
            // Nothing.
        }

        public func set(remoteCandidate _: IceCandidate) async throws {
            // Nothing.
        }

        // MARK: - Media

        public func startCaptureLocalVideo() {
            // Nothing.
        }
    }

    // MARK: - Preview

    public extension WebRTCServiceProtocol where Self == WebRTCServicePreview {
        /// A service that meets nobody, so a canvas never raises a connection
        /// and never turns on the camera.
        static var preview: WebRTCServicePreview {
            WebRTCServicePreview()
        }
    }

#endif
