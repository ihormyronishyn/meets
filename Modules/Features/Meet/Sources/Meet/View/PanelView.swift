//
//  PanelView.swift
//  Meet
//

import Entities
import SwiftUI

struct PanelView: View {

    // MARK: - Properties

    /// The panel is one row tall, and the button that ends a meeting is as wide
    /// as it is tall, so the two are read from here.
    private static let height: CGFloat = 60

    let peer: Peer
    let action: (Action) -> Void

    enum Action {
        case leaveMeet
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            username
            leave
        } //: HStack
        .frame(height: Self.height)
        .padding(16)
        .environment(\.colorScheme, .dark)
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
        .frame(maxHeight: .infinity)
        .background(Material.bar)
        .clipShape(.capsule)
    }

    // MARK: - Leave

    /// The width matches the height of the panel, so the shape is a circle
    /// rather than a capsule, and the red reaches its edge because this one
    /// carries no material behind it.
    private var leave: some View {
        Button {
            action(.leaveMeet)
        } label: {
            Image(systemName: "phone.down.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: Self.height, height: Self.height)
                .background(.red)
                .clipShape(.circle)
        } //: Button
    }
}

// MARK: - Preview

#Preview {
    PanelView(peer: .Preview.caller) { _ in }
}
