//
//  Call.swift
//  Entities
//

import Foundation

public struct Call: Equatable {

    // MARK: - Properties

    public let localPeer: Peer
    public let remotePeer: Peer

    // MARK: - Init

    public init(localPeer: Peer, remotePeer: Peer) {
        self.localPeer = localPeer
        self.remotePeer = remotePeer
    }
}
