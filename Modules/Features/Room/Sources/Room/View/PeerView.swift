//
//  PeerView.swift
//  Room
//

import Entities
import SwiftUI

struct PeerView: View {

    // MARK: - Properties

    let peer: Peer
    let isAvailable: Bool
    let action: (Action) -> Void

    enum Action {
        case startMeet
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading) {
            // The label above the name only exists to introduce it, so the two
            // are read as one element and the button keeps its own.
            VStack(alignment: .leading) {
                headline
                username
            } //: VStack
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(.roomPeerLabel(peer.username)))

            start
        } //: VStack
    }

    // MARK: - Headline

    private var headline: some View {
        Text(.roomPeerHeadline)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Username

    private var username: some View {
        Text(peer.username)
    }

    // MARK: - Start

    private var start: some View {
        Button {
            action(.startMeet)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "video.fill")
                    .font(.callout)
                    .foregroundStyle(.mint)
                    // The text beside it already says what the button does.
                    .accessibilityHidden(true)

                Text(.roomPeerStartTitle)
            } //: HStack
            .frame(maxWidth: .infinity)
        } //: Button
        .fontWeight(.medium)
        .controlSize(.extraLarge)
        .buttonStyle(.glass)
        .disabled(!isAvailable)
        .accessibilityHint(Text(.roomPeerStartHint))
    }
}

// MARK: - Preview

#Preview {
    PeerView(peer: .Preview.callee, isAvailable: true) { _ in }
}
