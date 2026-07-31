//
//  I420ConvertingRenderer.swift
//  Components
//

import Foundation
import WebRTC

/// Stands in for the view on the simulator, where the metal texture cache
/// cannot take the buffers the capture produces. Every frame is converted to
/// I420 and passed on, so the view only ever receives one it can draw.
final class I420ConvertingRenderer: NSObject, RTCVideoRenderer {

    // MARK: - Properties

    /// Held as the protocol rather than as the view, because the view carries
    /// main actor isolation while frames arrive on the thread of the capture.
    /// Reaching it through the protocol drops that isolation, which is sound
    /// here only because these two methods are built to be called off the main
    /// thread, and forwarding there keeps the work off it.
    private weak var target: (any RTCVideoRenderer)?

    // MARK: - Init

    init(target: RTCMTLVideoView) {
        self.target = target
    }

    // MARK: - Size

    func setSize(_ size: CGSize) {
        target?.setSize(size)
    }

    // MARK: - Render

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame else {
            target?.renderFrame(nil)
            return
        }

        let converted = RTCVideoFrame(
            buffer: frame.buffer.toI420(),
            rotation: frame.rotation,
            timeStampNs: frame.timeStampNs,
        )

        target?.renderFrame(converted)
    }
}
