//
//  PanelView.swift
//  Meet
//

import Entities
import SwiftUI

struct PanelView: View {

    // MARK: - Properties

    let peer: Peer
    let action: (Action) -> Void

    enum Action {
        case leaveMeet
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            bar
        } //: HStack
        .frame(height: 60)
        .padding(16)
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Bar

    private var bar: some View {
        Group {
            username
            leave
        } //: Group
        .frame(maxHeight: .infinity)
        .background(Material.bar)
        .clipShape(.capsule)
    }

    // MARK: - Peer

    private var username: some View {
        HStack {
            Text("Peer")
                .foregroundStyle(.secondary)

            Spacer(minLength: .zero)

            Text(peer.username)
        } //: HStack
        .fontWeight(.semibold)
        .padding(.horizontal, 20)
    }

    // MARK: - Leave

    private var leave: some View {
        Button {
            action(.leaveMeet)
        } label: {
            Image(systemName: "phone.down.fill")
                .font(.callout)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.red)
                .clipShape(.circle)
                .padding(.horizontal, 15)
        } //: Button
    }
}

// MARK: - Preview

#Preview {
    PanelView(peer: .Preview.caller) { _ in }
}
