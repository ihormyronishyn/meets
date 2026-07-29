//
//  PeerEventTests.swift
//  Services
//

import Entities
import Foundation
import Testing
@testable import Services

@Suite
struct PeerEventTests {

    // MARK: - Tests

    @Test
    func decodesAJoinedPeer() throws {
        // Arrange.
        let json = Data(#"{"roomId":1,"username":"John","isCaller":true}"#.utf8)

        // Act.
        let event = try PeerEvent.decode(name: .roomUserJoined, from: json)

        // Assert.
        guard case let .roomUserJoined(peer) = event else {
            Issue.record("Expected a joined peer, received \(event).")
            return
        }

        #expect(peer.username == "John")
        #expect(peer.roomId == 1)
        #expect(peer.isCaller == true)
    }

    @Test
    func decodesALeftPeer() throws {
        // Arrange.
        let json = Data(#"{"roomId":1,"username":"John","isCaller":false}"#.utf8)

        // Act.
        let event = try PeerEvent.decode(name: .roomUserLeft, from: json)

        // Assert.
        guard case let .roomUserLeft(peer) = event else {
            Issue.record("Expected a left peer, received \(event).")
            return
        }

        #expect(peer.username == "John")
    }

    @Test
    func decodesAnOfferCarryingACall() throws {
        // Arrange.
        let from = #"{"username":"John","roomId":1,"isCaller":true}"#
        let to = #"{"username":"Alex","roomId":1,"isCaller":false}"#
        let json = Data(#"{"call":{"from":\#(from),"to":\#(to)}}"#.utf8)

        // Act.
        let event = try PeerEvent.decode(name: .offer, from: json)

        // Assert.
        guard case let .offer(communication) = event, case let .call(call) = communication else {
            Issue.record("Expected an offer carrying a call, received \(event).")
            return
        }

        #expect(call.from.username == "John")
        #expect(call.to.username == "Alex")
    }

    @Test
    func decodesAnOfferCarryingASessionDescription() throws {
        // Arrange.
        // The same event name arrives with a bare description and no envelope,
        // which is the branch that tells the two payloads apart.
        let json = Data(#"{"sdp":"v=0","type":"offer"}"#.utf8)

        // Act.
        let event = try PeerEvent.decode(name: .offer, from: json)

        // Assert.
        guard case let .offer(communication) = event, case .sdp = communication else {
            Issue.record("Expected an offer carrying a description, received \(event).")
            return
        }
    }

    @Test
    func decodesAnAnswer() throws {
        // Arrange.
        let json = Data(#"{"sdp":"v=0","type":"answer"}"#.utf8)

        // Act.
        let event = try PeerEvent.decode(name: .answer, from: json)

        // Assert.
        guard case .answer = event else {
            Issue.record("Expected an answer, received \(event).")
            return
        }
    }

    @Test
    func decodesACandidateFromTheWireName() throws {
        // Arrange.
        // The server calls the field `candidate`, while the type stores it as
        // `sdp`, so this pins the mapping between the two names.
        let json = Data(#"{"candidate":"candidate:1 1 udp","sdpMLineIndex":0,"sdpMid":"audio"}"#.utf8)

        // Act.
        let event = try PeerEvent.decode(name: .candidate, from: json)

        // Assert.
        guard case let .candidate(candidate) = event else {
            Issue.record("Expected a candidate, received \(event).")
            return
        }

        #expect(candidate.rtcIceCandidate.sdp == "candidate:1 1 udp")
        #expect(candidate.rtcIceCandidate.sdpMid == "audio")
    }

    @Test
    func refusesAPayloadThatDoesNotFitTheName() {
        // Arrange.
        let json = Data(#"{"unexpected":true}"#.utf8)

        // Act, Assert.
        #expect(throws: DecodingError.self) {
            try PeerEvent.decode(name: .roomUserJoined, from: json)
        }
    }

    @Test
    func reportsTheNameOfEveryCase() {
        // Arrange.
        let peer = Peer(roomId: 1, username: "John", isCaller: true)

        // Assert.
        #expect(PeerEvent.roomUserJoined(peer).name == .roomUserJoined)
        #expect(PeerEvent.roomUserLeft(peer).name == .roomUserLeft)
    }
}
