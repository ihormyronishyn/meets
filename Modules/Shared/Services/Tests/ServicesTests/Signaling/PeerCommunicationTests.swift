//
//  PeerCommunicationTests.swift
//  Services
//

import Entities
import Foundation
import Testing
@testable import Services

@Suite
struct PeerCommunicationTests {

    // MARK: - Tests

    @Test
    func encodesACallUnderItsOwnKey() throws {
        // Arrange.
        let from = Peer(roomId: 1, username: "John", isCaller: true)
        let to = Peer(roomId: 1, username: "Alex", isCaller: false)
        let communication = PeerCommunication.call(.init(from: from, to: to))

        // Act.
        let data = try JSONEncoder().encode(communication)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Assert.
        let call = try #require(object?["call"] as? [String: Any])
        let sender = try #require(call["from"] as? [String: Any])

        #expect(sender["username"] as? String == "John")
    }

    @Test
    func encodesADescriptionWithoutAnEnvelope() throws {
        // Arrange.
        let json = Data(#"{"sdp":"v=0","type":"offer"}"#.utf8)
        let communication = try JSONDecoder().decode(PeerCommunication.self, from: json)

        // Act.
        let data = try JSONEncoder().encode(communication)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Assert.
        // The description sits at the top level, since the server reads the
        // very shape it sent, and no key names it.
        #expect(object?["call"] == nil)
        #expect(object?["sdp"] as? String == "v=0")
        #expect(object?["type"] as? String == "offer")
    }

    @Test
    func readsACallWhenTheKeyIsPresent() throws {
        // Arrange.
        let from = #"{"username":"John","roomId":1,"isCaller":true}"#
        let to = #"{"username":"Alex","roomId":1,"isCaller":false}"#
        let json = Data(#"{"call":{"from":\#(from),"to":\#(to)}}"#.utf8)

        // Act.
        let communication = try JSONDecoder().decode(PeerCommunication.self, from: json)

        // Assert.
        guard case let .call(call) = communication else {
            Issue.record("Expected a call, received \(communication).")
            return
        }

        #expect(call.to.username == "Alex")
    }

    @Test
    func readsADescriptionWhenTheKeyIsAbsent() throws {
        // Arrange.
        let json = Data(#"{"sdp":"v=0","type":"answer"}"#.utf8)

        // Act.
        let communication = try JSONDecoder().decode(PeerCommunication.self, from: json)

        // Assert.
        guard case let .sdp(description) = communication else {
            Issue.record("Expected a description, received \(communication).")
            return
        }

        #expect(description.rtcSessionDescription.sdp == "v=0")
    }

    @Test
    func survivesARoundTrip() throws {
        // Arrange.
        let json = Data(#"{"sdp":"v=0","type":"answer"}"#.utf8)
        let communication = try JSONDecoder().decode(PeerCommunication.self, from: json)

        // Act.
        let encoded = try JSONEncoder().encode(communication)
        let decoded = try JSONDecoder().decode(PeerCommunication.self, from: encoded)

        // Assert.
        guard case let .sdp(description) = decoded else {
            Issue.record("Expected a description, received \(decoded).")
            return
        }

        #expect(description.rtcSessionDescription.sdp == "v=0")
    }
}
