//
//  WebRTCVideoViewTests.swift
//  ComponentsTests
//

import Foundation
import Testing
@preconcurrency import WebRTC
@testable import Components

/// The tests build real tracks and a real view, and the framework behind them
/// keeps one set of threads for the whole process, so the suite takes them one
/// at a time rather than letting them block each other.
@Suite(.serialized)
@MainActor
struct WebRTCVideoViewTests {

    // MARK: - Properties

    private let factory = RTCPeerConnectionFactory()
    private let coordinator = WebRTCVideoView.Coordinator()
    private let videoView = RTCMTLVideoView()

    // MARK: - Helpers

    private func videoTrack(id: String) -> RTCVideoTrack {
        factory.videoTrack(with: factory.videoSource(), trackId: id)
    }

    // MARK: - Tests

    @Test
    func nothingDrawsBeforeATrackArrives() {
        #expect(!coordinator.isAttached)
    }

    @Test
    func aTrackStartsDrawing() {
        coordinator.attach(track: videoTrack(id: "first"), to: videoView)
        #expect(coordinator.isAttached)
    }

    @Test
    func attachingNothingKeepsNoRenderer() {
        coordinator.attach(track: nil, to: videoView)
        #expect(!coordinator.isAttached)
    }

    @Test
    func aTrackTakenAwayStopsDrawing() {
        coordinator.attach(track: videoTrack(id: "first"), to: videoView)
        coordinator.attach(track: nil, to: videoView)

        #expect(!coordinator.isAttached)
    }

    @Test
    func theSameTrackAgainKeepsDrawing() {
        let track = videoTrack(id: "first")

        coordinator.attach(track: track, to: videoView)
        coordinator.attach(track: track, to: videoView)

        #expect(coordinator.isAttached)
    }

    @Test
    func anotherTrackReplacesTheFirst() {
        coordinator.attach(track: videoTrack(id: "first"), to: videoView)
        coordinator.attach(track: videoTrack(id: "second"), to: videoView)

        #expect(coordinator.isAttached)
    }

    @Test
    func detachStopsDrawing() {
        coordinator.attach(track: videoTrack(id: "first"), to: videoView)
        coordinator.detach()

        #expect(!coordinator.isAttached)
    }

    @Test
    func detachTwiceIsHarmless() {
        coordinator.attach(track: videoTrack(id: "first"), to: videoView)
        coordinator.detach()
        coordinator.detach()

        #expect(!coordinator.isAttached)
    }
}
