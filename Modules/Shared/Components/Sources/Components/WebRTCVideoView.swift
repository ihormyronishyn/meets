//
//  WebRTCVideoView.swift
//  Components
//

import SwiftUI
import WebRTC

/// Draws a video track. The track is only ever read, so it arrives as a value
/// rather than as a binding, and a caller needs no mutable source to show one.
public struct WebRTCVideoView: UIViewRepresentable {

    // MARK: - Properties

    private let track: RTCVideoTrack?
    private let videoContentMode: UIView.ContentMode

    // MARK: - Init

    public init(track: RTCVideoTrack?, videoContentMode: UIView.ContentMode = .scaleAspectFill) {
        self.track = track
        self.videoContentMode = videoContentMode
    }

    // MARK: - Coordinator

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Make

    public func makeUIView(context _: Context) -> RTCMTLVideoView {
        RTCMTLVideoView()
    }

    // MARK: - Update

    /// The content mode is applied here rather than where the view is built,
    /// because this runs right after that and on every change afterwards, so a
    /// caller that switches modes is followed instead of ignored.
    public func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        uiView.videoContentMode = videoContentMode
        context.coordinator.attach(track: track, to: uiView)
    }

    // MARK: - Dismantle

    public static func dismantleUIView(_: RTCMTLVideoView, coordinator: Coordinator) {
        coordinator.detach()
    }
}

// MARK: - Coordinator

public extension WebRTCVideoView {
    final class Coordinator {

        // MARK: - Properties

        private var track: RTCVideoTrack?
        private var renderer: RTCVideoRenderer?

        /// Whether something is drawing right now, which is what a test reads
        /// instead of reaching for the renderer itself.
        var isAttached: Bool {
            renderer != nil
        }

        // MARK: - Attach

        /// Points the track at the view, taking down whatever drew before it.
        /// A track that already draws is left alone, so a redraw of the screen
        /// does not restart the picture.
        func attach(track: RTCVideoTrack?, to videoView: RTCMTLVideoView) {
            guard track !== self.track else { return }
            detach()

            // There is nothing to draw, so no renderer is built and none is
            // kept, otherwise one would sit here attached to nobody.
            guard let track else { return }

            #if targetEnvironment(simulator)
                let renderer = I420ConvertingRenderer(target: videoView)
            #else
                let renderer = videoView
            #endif

            self.track = track
            self.renderer = renderer
            track.add(renderer)
        }

        // MARK: - Detach

        func detach() {
            if let renderer {
                track?.remove(renderer)
            }

            track = nil
            renderer = nil
        }
    }
}

// MARK: - Preview

// A track cannot be built without a connection, so a canvas shows the state a
// caller sees before one arrives, an empty picture waiting to be filled.
#Preview {
    WebRTCVideoView(track: nil)
        .aspectRatio(3 / 4, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 16))
        .padding()
}
