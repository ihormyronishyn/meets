//
//  PeerTests.swift
//  Entities
//

import Foundation
import Testing
@testable import Entities

@Suite
struct PeerTests {

    // MARK: - Tests

    @Test
    func decodesThePayloadOfTheRoom() throws {
        // Arrange.
        let payload = Self.data(#"{"roomId": 7, "username": "John", "isCaller": true}"#)

        // Act.
        let peer = try JSONDecoder().decode(Peer.self, from: payload)

        // Assert.
        #expect(peer.roomId == 7)
        #expect(peer.username == "John")
        #expect(peer.isCaller == true)
    }

    @Test
    func decodesWhenTheRoomAndTheRoleAreMissing() throws {
        // Arrange.
        // A peer reaches the application from a socket, so a payload that names
        // only what it knows has to arrive rather than fail.
        let payload = Self.data(#"{"username": "John"}"#)

        // Act.
        let peer = try JSONDecoder().decode(Peer.self, from: payload)

        // Assert.
        #expect(peer.username == "John")
        #expect(peer.roomId == nil)
        #expect(peer.isCaller == nil)
    }

    @Test
    func decodesWhenTheRoomAndTheRoleAreNull() throws {
        // Arrange.
        // An absent key and an explicit null both mean the same thing here, and
        // the two arrive from different senders.
        let payload = Self.data(#"{"roomId": null, "username": "John", "isCaller": null}"#)

        // Act.
        let peer = try JSONDecoder().decode(Peer.self, from: payload)

        // Assert.
        #expect(peer.roomId == nil)
        #expect(peer.isCaller == nil)
    }

    @Test
    func refusesAPayloadWithoutAUsername() {
        // Arrange.
        // The username is the identity, so a payload lacking it describes
        // nobody and is refused rather than decoded into an empty name.
        let payload = Self.data(#"{"roomId": 7, "isCaller": true}"#)

        // Assert.
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Peer.self, from: payload)
        }
    }

    @Test
    func survivesEncodingAndDecoding() throws {
        // Arrange.
        // A peer is sent onwards as often as it is received, so everything it
        // holds has to come back, which stops a property being added without
        // being carried.
        let peer = Peer(roomId: 7, username: "John", isCaller: true)

        // Act.
        let encoded = try JSONEncoder().encode(peer)
        let decoded = try JSONDecoder().decode(Peer.self, from: encoded)

        // Assert.
        #expect(decoded == peer)
    }

    @Test
    func isIdentifiedByTheUsernameAloneButNotEqualByIt() {
        // Arrange.
        // The room lists peers by identity and the protocol keys them by name,
        // so the same name is the same person even when the role differs. That
        // is deliberately weaker than equality, which compares everything.
        let caller = Peer(roomId: 7, username: "John", isCaller: true)
        let callee = Peer(roomId: 7, username: "John", isCaller: false)

        // Assert.
        #expect(caller.id == callee.id)
        #expect(caller != callee)
    }

    // MARK: - Data

    private static func data(_ json: String) -> Data {
        Data(json.utf8)
    }
}
