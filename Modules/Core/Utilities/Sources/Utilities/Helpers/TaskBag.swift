//
//  TaskBag.swift
//  Utilities
//

import Foundation

/// Holds long running tasks so their owner can cancel them together.
///
/// The bag cancels whatever it still holds when it goes away, which gives an
/// owner a single point of teardown instead of one stored task per stream.
/// It carries no lock of its own, so it belongs to one isolation domain, such
/// as a view model on the main actor.
public final class TaskBag {

    // MARK: - Properties

    private var tasks: [Task<Void, Never>] = []

    public var isEmpty: Bool {
        tasks.isEmpty
    }

    // MARK: - Init

    public init() {
        // Nothing.
    }

    // MARK: - Deinit

    deinit {
        cancelAll()
    }

    // MARK: - Insert

    public func insert(_ task: Task<Void, Never>) {
        tasks.append(task)
    }

    // MARK: - Cancel

    public func cancelAll() {
        for task in tasks {
            task.cancel()
        }

        tasks.removeAll()
    }
}
