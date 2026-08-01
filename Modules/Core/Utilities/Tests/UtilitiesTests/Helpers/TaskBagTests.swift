//
//  TaskBagTests.swift
//  Utilities
//

import Foundation
import Testing
@testable import Utilities

@Suite
@MainActor
struct TaskBagTests {

    // MARK: - Tests

    @Test
    func startsEmpty() {
        // Arrange.
        let bag = TaskBag()

        // Assert.
        #expect(bag.isEmpty)
    }

    @Test
    func holdsAnInsertedTask() {
        // Arrange.
        let bag = TaskBag()

        // Act.
        bag.insert(Task {})

        // Assert.
        #expect(bag.isEmpty == false)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancelAllStopsTheTasksItHolds() async {
        // Arrange.
        let bag = TaskBag()
        let task = Task {
            // A task that never returns on its own, so only cancellation can
            // end it, which is the whole point of the bag.
            while !Task.isCancelled {
                await Task.yield()
            }
        }

        bag.insert(task)

        // Act.
        bag.cancelAll()
        _ = await task.value

        // Assert.
        #expect(task.isCancelled)
        #expect(bag.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func deallocationStopsTheTasksItHolds() async {
        // Arrange.
        var bag: TaskBag? = TaskBag()
        let task = Task {
            while !Task.isCancelled {
                await Task.yield()
            }
        }

        bag?.insert(task)

        // Act.
        bag = nil

        // Assert.
        _ = await task.value

        #expect(task.isCancelled)
    }
}
