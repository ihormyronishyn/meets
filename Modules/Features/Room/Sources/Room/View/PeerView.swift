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
            headline
            username
            start
        } //: VStack
    }

    // MARK: - Headline

    private var headline: some View {
        Text("Peer")
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

                Text("Start Meet")
            } //: HStack
            .frame(maxWidth: .infinity)
        } //: Button
        .fontWeight(.medium)
        .controlSize(.extraLarge)
        .buttonStyle(.glass)
        .disabled(!isAvailable)
    }
}

// MARK: - Preview

#Preview {
    PeerView(peer: .Preview.callee, isAvailable: true) { _ in }
}
