//
//  IceCandidate.swift
//  Services
//

import Foundation
import WebRTC

public struct IceCandidate: Codable, Sendable {

    // MARK: - Properties

    private let sdp: String
    private let sdpMLineIndex: Int32
    private let sdpMid: String?

    public var rtcIceCandidate: RTCIceCandidate {
        RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }

    // MARK: - Init

    public init(_ iceCandidate: RTCIceCandidate) {
        sdpMLineIndex = iceCandidate.sdpMLineIndex
        sdpMid = iceCandidate.sdpMid
        sdp = iceCandidate.sdp
    }

    // MARK: - Keys

    enum CodingKeys: String, CodingKey {
        case sdp = "candidate"
        case sdpMLineIndex
        case sdpMid
    }
}
