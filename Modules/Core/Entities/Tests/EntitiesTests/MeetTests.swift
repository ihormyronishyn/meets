//
//  MeetTests.swift
//  Entities
//

import Foundation
import Testing
@testable import Entities

@Suite
struct MeetTests {

    // MARK: - Tests

    @Test
    func keepsTheTwoSidesApart() {
        // Arrange.
        // One side is the person signed in and the other is who they are
        // meeting, so the pair is ordered. A meeting built the other way round
        // would show each of them the video of themselves.
        let local = Peer(roomId: 7, username: "John", isCaller: true)
        let remote = Peer(roomId: 7, username: "Alex", isCaller: false)

        // Act.
        let meet = Meet(localPeer: local, remotePeer: remote)

        // Assert.
        #expect(meet.localPeer == local)
        #expect(meet.remotePeer == remote)
        #expect(meet != Meet(localPeer: remote, remotePeer: local))
    }
}
