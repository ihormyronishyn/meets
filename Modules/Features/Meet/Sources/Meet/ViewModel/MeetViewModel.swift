//
//  MeetViewModel.swift
//  Meet
//

import Entities
import Foundation
import Observation
import Services
import Utilities
@preconcurrency import WebRTC

@MainActor
@Observable
public final class MeetViewModel {

    // MARK: - Properties

    var localVideoTrack: RTCVideoTrack?
    var remoteVideoTrack: RTCVideoTrack?
    var isLeaveMeetConfirmationAlertPresented: Bool = false

    let meet: Meet

    @ObservationIgnored public weak var router: MeetRouting?
    @ObservationIgnored private let taskBag = TaskBag()

    /// The screen asks to start on every appearance, so the work behind it runs
    /// once and later calls are ignored.
    @ObservationIgnored private var hasStarted: Bool = false

    private let signalingService: SignalingServiceProtocol
    private let webRTCService: WebRTCServiceProtocol

    // MARK: - Init

    public init(meet: Meet, signalingService: SignalingServiceProtocol, webRTCService: WebRTCServiceProtocol) {
        self.meet = meet
        self.signalingService = signalingService
        self.webRTCService = webRTCService
    }

    // MARK: - Start

    /// Listens first, then raises the connection, publishes the camera of this
    /// side, and tells the other peer the meeting is on.
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        await observe()

        do {
            try await webRTCService.connect()
        } catch {
            debugPrint("The meeting was not raised, \(error).")
            return
        }

        // The track arrives in a local first, because the checker cannot follow
        // a non Sendable reference assigned straight across the boundary.
        let track = await webRTCService.localVideoTrack
        localVideoTrack = track

        await communicate()
        await webRTCService.startCaptureLocalVideo()
    }

    // MARK: - Observe

    private func observe() async {
        // The streams are asked for here rather than inside the tasks, because
        // a task starts later than the caller returns, and the first events
        // would reach nobody. Once a stream exists it buffers, so nothing is
        // lost between this line and the first iteration.
        let peerEvents = await signalingService.peerEvents()
        let iceCandidates = await webRTCService.iceCandidateStream

        // A video track is a reference the framework treats as safe to touch
        // from any thread, which the language cannot see, so a stream of them
        // is not Sendable and cannot be handed to a task. The promise is made
        // here, in the one place that carries it across.
        nonisolated(unsafe) let remoteVideoTracks = await webRTCService.remoteVideoTrackStream

        // Self is promoted from weak per iteration only, so a suspended loop
        // never keeps the view model alive, and the task bag cancels on deinit.
        let peerEventTask = Task { [weak self] in
            for await event in peerEvents {
                guard let self else { return }

                do {
                    try await handle(event: event)
                } catch {
                    debugPrint("Failed to handle a peer event, \(error).")
                }
            }
        }

        taskBag.insert(peerEventTask)

        // The candidates of this side go out over the socket as they are
        // gathered, which is what lets the other peer reach us.
        let iceCandidateTask = Task { [signalingService] in
            for await candidate in iceCandidates {
                await signalingService.emit(eventName: .candidate, payload: candidate)
            }
        }

        taskBag.insert(iceCandidateTask)

        // The track of the other side exists only once its description has been
        // applied, so it arrives here rather than being read at the start.
        let remoteVideoTrackTask = Task { [weak self] in
            for await track in remoteVideoTracks {
                guard let self else { return }
                remoteVideoTrack = track
            }
        }

        taskBag.insert(remoteVideoTrackTask)
    }

    // MARK: - Communicate

    private func communicate() async {
        guard let isCaller = meet.localPeer.isCaller else {
            debugPrint("Refused to announce the meeting, the peer carries no caller flag.")
            return
        }

        let communication: PeerCommunication = isCaller
            ? .call(.init(from: meet.localPeer, to: meet.remotePeer))
            : .call(.init(from: meet.remotePeer, to: meet.localPeer))

        await signalingService.emit(eventName: isCaller ? .offer : .answer, payload: communication)
    }

    // MARK: - Offer

    private func createOffer() async throws {
        let sessionDescription = try await webRTCService.offer()
        await signalingService.emit(eventName: .offer, payload: PeerCommunication.sdp(sessionDescription))
    }

    // MARK: - Answer

    private func createAnswer() async throws {
        let sessionDescription = try await webRTCService.answer()
        await signalingService.emit(eventName: .answer, payload: PeerCommunication.sdp(sessionDescription))
    }

    // MARK: - Leave Meet

    /// Tears the meeting down. Note this disconnects the shared signaling
    /// socket, so the room loses its connection as well and the person
    /// reconnects by hand on return. Accepted behavior by design.
    func leaveMeet() async {
        taskBag.cancelAll()
        await signalingService.disconnect()
        await webRTCService.disconnect()
        router?.didLeaveMeet()
    }

    // MARK: - Handle

    func handle(event: PeerEvent) async throws {
        switch event {
        case .roomUserJoined:
            // Somebody entered the room behind us, which changes nothing here.
            break
        case .roomUserLeft:
            await leaveMeet()
        case let .offer(communication):
            guard case let .sdp(sessionDescription) = communication else {
                debugPrint("Ignored an offer, it carries no session description.")
                return
            }

            try await webRTCService.set(remoteSdp: sessionDescription)
            try await createAnswer()
        case let .answer(communication):
            switch communication {
            case .call:
                // The callee took the invite, so the real offer goes out now.
                try await createOffer()
            case let .sdp(sessionDescription):
                try await webRTCService.set(remoteSdp: sessionDescription)
            }
        case let .candidate(iceCandidate):
            try await webRTCService.set(remoteCandidate: iceCandidate)
        }
    }
}

// MARK: - Extension

#if DEBUG

    public extension MeetViewModel {

        // MARK: - Preview

        /// A view model wired to doubles, so a canvas draws the screen without
        /// opening a socket and without turning on the camera.
        ///
        /// Neither side carries a track, so both pictures stay empty and what
        /// the canvas shows is the panel and the frame around them.
        static var preview: MeetViewModel {
            MeetViewModel(
                meet: Meet(localPeer: .Preview.local, remotePeer: .Preview.callee),
                signalingService: .preview,
                webRTCService: .preview,
            )
        }
    }

#endif
