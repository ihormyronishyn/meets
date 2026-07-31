//
//  RoomView.swift
//  Room
//

import Services
import SwiftUI

public struct RoomView: View {

    // MARK: - Properties

    @Bindable private var viewModel: RoomViewModel

    // MARK: - Init

    public init(viewModel: RoomViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        if let localPeer = viewModel.localPeer, let roomId = localPeer.roomId {
            form
                .navigationTitle(String(roomId))
                .navigationSubtitle(Text("Room ID"))
                .toolbarTitleDisplayMode(.large)
        } else {
            form
        }
    }

    // MARK: - Form

    private var form: some View {
        Form {
            section
        } //: Form
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                leave
            } //: ToolbarItem
        }
        .safeAreaBar(edge: .bottom) {
            connection
        }
        .alert("Are you sure?", isPresented: $viewModel.isLeaveRoomConfirmationAlertPresented) {
            Button("Leave Room", role: .destructive) {
                Task {
                    await viewModel.leaveRoom()
                }
            } //: Button
        } message: {
            Text("Are you sure you want to leave the room?")
        }
    }

    // MARK: - Leave

    private var leave: some View {
        Button("Leave Room") {
            viewModel.isLeaveRoomConfirmationAlertPresented = true
        } //: Button
    }

    // MARK: - Section

    private var section: some View {
        Section {
            username
            toggle
            peers
        } footer: {
            failure
        } //: Section
    }

    // MARK: - Username

    @ViewBuilder
    private var username: some View {
        if let localPeer = viewModel.localPeer {
            LabeledContent {
                Text(localPeer.username)
            } label: {
                Text("Username")
            } //: LabeledContent
        }
    }

    // MARK: - Toggle

    private var toggle: some View {
        Toggle("Caller", isOn: $viewModel.isCaller)
            .disabled(viewModel.isConnected || viewModel.isConnecting)
            // The role decides who opens a meeting, and it is fixed for as
            // long as the room is reached, which the dimming alone does not
            // explain.
            .accessibilityHint("Decides which side starts a meeting. Fixed while the room is connected.")
    }

    // MARK: - Peers

    @ViewBuilder
    private var peers: some View {
        if viewModel.isConnected, viewModel.peers.isEmpty {
            Text("No peers in the room yet.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.peers) { peer in
                PeerView(peer: peer, isAvailable: viewModel.isPeerAvailable(peer)) { action in
                    switch action {
                    case .startMeet:
                        viewModel.startMeet(with: peer)
                    }
                } //: PeerView
            } //: ForEach
        }
    }

    // MARK: - Failure

    @ViewBuilder
    private var failure: some View {
        // A room that is full and a room that could not be reached both leave the
        // screen looking untouched, so each says what happened in its own words.
        let message: String? = if viewModel.isRoomFull {
            "This room already holds two people. Leave and try another one."
        } else if viewModel.hasFailedToConnect {
            "Could not reach the room. Check the connection and try again."
        } else {
            nil
        }

        if let message {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    // MARK: - Connection

    private var connection: some View {
        Button {
            Task {
                viewModel.isConnected ? await viewModel.disconnect() : await viewModel.connect()
            }
        } label: {
            let title = if viewModel.isConnecting {
                "Connecting"
            } else if viewModel.isConnected {
                "Disconnect"
            } else if viewModel.hasFailedToConnect || viewModel.isRoomFull {
                "Try Again"
            } else {
                "Connect"
            }

            Text(title)
                .frame(maxWidth: .infinity)
        } //: Button
        .disabled(viewModel.isConnecting)
        .tint(viewModel.isConnected ? .red : .orange)
        .fontWeight(.medium)
        .buttonStyle(.glassProminent)
        .controlSize(.extraLarge)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoomView(viewModel: .preview)
    } //: NavigationStack
}
