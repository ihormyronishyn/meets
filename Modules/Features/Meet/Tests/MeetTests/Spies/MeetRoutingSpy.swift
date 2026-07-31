//
//  MeetRoutingSpy.swift
//  Meet
//

import Foundation
@testable import Meet

final class MeetRoutingSpy: MeetRouting {

    // MARK: - Properties

    private(set) var didLeaveCallCount: Int = .zero

    // MARK: - Methods

    func didLeaveMeet() {
        didLeaveCallCount += 1
    }
}
