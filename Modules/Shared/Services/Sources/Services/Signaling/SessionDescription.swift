//
//  SessionDescription.swift
//  Services
//

import Foundation
import WebRTC

public struct SessionDescription: Codable, Sendable {

    // MARK: - Properties

    private let sdp: String
    private let type: SdpType

    public var rtcSessionDescription: RTCSessionDescription {
        RTCSessionDescription(type: type.rtcSdpType, sdp: sdp)
    }

    public enum SdpType: String, Codable, Sendable {
        case offer, prAnswer, answer, rollback

        public var rtcSdpType: RTCSdpType {
            switch self {
            case .offer:
                .offer
            case .answer:
                .answer
            case .prAnswer:
                .prAnswer
            case .rollback:
                .rollback
            }
        }
    }

    // MARK: - Init

    public init?(_ rtcSessionDescription: RTCSessionDescription) {
        sdp = rtcSessionDescription.sdp

        switch rtcSessionDescription.type {
        case .offer:
            type = .offer
        case .prAnswer:
            type = .prAnswer
        case .answer:
            type = .answer
        case .rollback:
            type = .rollback
        @unknown default:
            return nil
        }
    }
}
