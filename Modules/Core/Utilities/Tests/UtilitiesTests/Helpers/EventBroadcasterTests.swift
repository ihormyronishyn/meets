//
//  EventBroadcasterTests.swift
//  Utilities
//

import Foundation
import Testing
@testable import Utilities

@Suite
struct EventBroadcasterTests {

    // MARK: - Tests

    @Test
    func fanOutDeliversToAllSubscribers() async {
        // Arrange.
        let broadcaster = EventBroadcaster<Int>()
        let first = await broadcaster.stream()
        let second = await broadcaster.stream()
        let number = 5

        // Act.
        await broadcaster.yield(number)
        await broadcaster.finish()

        // Assert.
        var firstValues: [Int] = []
        for await value in first {
            firstValues.append(value)
        }

        var secondValues: [Int] = []
        for await value in second {
            secondValues.append(value)
        }

        #expect(firstValues == [number])
        #expect(secondValues == [number])
    }

    @Test(.timeLimit(.minutes(1)))
    func removesSubscriberOnTermination() async {
        // Arrange.
        let broadcaster = EventBroadcaster<Int>()
        let stream = await broadcaster.stream()

        #expect(await broadcaster.subscriberCount == 1)

        // Act.
        let task = Task {
            for await _ in stream {
                // Nothing.
            }
        }

        task.cancel()
        _ = await task.value

        // Assert.
        // Removal hops through a separate task, so poll briefly until it lands.
        for _ in 0 ..< 100 {
            if await broadcaster.subscriberCount == .zero {
                break
            }

            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(await broadcaster.subscriberCount == .zero)
    }

    @Test
    func preservesPerSubscriberOrderingUnderRapidYields() async {
        // Arrange.
        let broadcaster = EventBroadcaster<Int>()
        let first = await broadcaster.stream()
        let second = await broadcaster.stream()
        let values = Array(0 ..< 200)

        // Act.
        for value in values {
            await broadcaster.yield(value)
        }

        await broadcaster.finish()

        // Assert.
        var firstValues: [Int] = []
        for await value in first {
            firstValues.append(value)
        }

        var secondValues: [Int] = []
        for await value in second {
            secondValues.append(value)
        }

        #expect(firstValues == values)
        #expect(secondValues == values)
    }

    @Test
    func finishEndsStreamsAndClearsSubscribers() async {
        // Arrange.
        let broadcaster = EventBroadcaster<Int>()
        let stream = await broadcaster.stream()

        // Act.
        await broadcaster.finish()

        // Assert.
        var values: [Int] = []
        for await value in stream {
            values.append(value)
        }

        #expect(values.isEmpty)
        #expect(await broadcaster.subscriberCount == .zero)
    }

    @Test
    func yieldAfterFinishReachesNobody() async {
        // Arrange.
        let broadcaster = EventBroadcaster<Int>()
        let stream = await broadcaster.stream()

        await broadcaster.finish()

        // Act.
        await broadcaster.yield(5)

        // Assert.
        var values: [Int] = []
        for await value in stream {
            values.append(value)
        }

        #expect(values.isEmpty)
    }

    @Test
    func lateSubscriberMissesEarlierEvents() async {
        // Arrange.
        let broadcaster = EventBroadcaster<Int>()

        await broadcaster.yield(1)

        // Act.
        let stream = await broadcaster.stream()

        await broadcaster.yield(2)
        await broadcaster.finish()

        // Assert.
        var values: [Int] = []
        for await value in stream {
            values.append(value)
        }

        #expect(values == [2])
    }

    @Test
    func oneSubscriberLeavingLeavesTheOtherAlone() async {
        // Arrange.
        let broadcaster = EventBroadcaster<Int>()
        let leaving = await broadcaster.stream()
        let staying = await broadcaster.stream()

        // Act.
        let task = Task {
            for await _ in leaving {
                // Nothing.
            }
        }

        task.cancel()
        _ = await task.value

        await broadcaster.yield(7)
        await broadcaster.finish()

        // Assert.
        var values: [Int] = []
        for await value in staying {
            values.append(value)
        }

        #expect(values == [7])
    }

    @Test(.timeLimit(.minutes(1)))
    func deallocationEndsTheStream() async throws {
        // Arrange.
        var broadcaster: EventBroadcaster<Int>? = EventBroadcaster()
        let stream = try #require(await broadcaster?.stream())

        // Act.
        broadcaster = nil

        // Assert.
        // Without a stream that ends, this loop would never return, so the
        // time limit is what turns a failure into a report.
        var values: [Int] = []
        for await value in stream {
            values.append(value)
        }

        #expect(values.isEmpty)
    }
}
