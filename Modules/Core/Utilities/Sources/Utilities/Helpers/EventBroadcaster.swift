//
//  EventBroadcaster.swift
//  Utilities
//

import Foundation

/// Broadcasts asynchronous events to multiple independent subscribers.
/// Each subscriber receives the same events through its own async stream,
/// ensuring thread safe fan out delivery.
///
/// A subscriber receives only what is sent after it arrives, since nothing is
/// replayed, and it keeps receiving until it stops iterating, until `finish`
/// is called, or until this broadcaster goes away.
public actor EventBroadcaster<Event: Sendable> {

    // MARK: - Properties

    private var continuations: [UUID: AsyncStream<Event>.Continuation] = [:]

    /// Number of subscribers currently attached.
    var subscriberCount: Int {
        continuations.count
    }

    // MARK: - Init

    public init() {
        // Nothing.
    }

    // MARK: - Deinit

    deinit {
        // A subscriber waits on its stream until somebody ends it, and once
        // this broadcaster is gone nobody can, so the streams are closed here
        // rather than left to whatever the runtime does with an abandoned
        // continuation.
        for continuation in continuations.values {
            continuation.finish()
        }
    }

    // MARK: - Stream

    /// Hands out a stream of the events that follow.
    ///
    /// The policy governs one subscriber alone. The default keeps every event,
    /// which suits a subscriber that must miss nothing, such as one reading a
    /// negotiation. A subscriber that only cares about the latest state can ask
    /// for `bufferingNewest` instead and let the rest be dropped, which bounds
    /// the memory it holds.
    public func stream(
        bufferingPolicy: AsyncStream<Event>.Continuation.BufferingPolicy = .unbounded,
    ) -> AsyncStream<Event> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            let id = UUID()
            continuations[id] = continuation

            // Drop the continuation when the subscriber task is cancelled
            // or the stream is discarded, so finished subscribers do not accumulate.
            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.remove(id)
                }
            }
        }
    }

    // MARK: - Remove

    private func remove(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }

    // MARK: - Yield

    public func yield(_ event: Event) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    // MARK: - Finish

    public func finish() {
        for continuation in continuations.values {
            continuation.finish()
        }

        continuations.removeAll()
    }
}
