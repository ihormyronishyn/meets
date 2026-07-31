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
        // The label and the name are one thought, so they are read as one
        // rather than as two neighbours a reader has to join up.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Meeting with \(peer.username)")
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
        // The button carries no text, so a reader would otherwise hear the
        // name of the symbol, and nothing about what pressing it does.
        .accessibilityLabel("Leave meet")
        .accessibilityHint("Asks to confirm, then ends the meeting.")
    }
}

// MARK: - Preview

#Preview {
    PanelView(peer: .Preview.caller) { _ in }
}
