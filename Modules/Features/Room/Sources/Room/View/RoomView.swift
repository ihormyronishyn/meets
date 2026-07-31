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
                .navigationSubtitle(Text(.roomSubtitle))
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
        .alert(
            Text(.roomLeaveConfirmationTitle),
            isPresented: $viewModel.isLeaveRoomConfirmationAlertPresented,
        ) {
            Button(role: .destructive) {
                Task {
                    await viewModel.leaveRoom()
                }
            } label: {
                Text(.roomLeaveTitle)
            } //: Button
        } message: {
            Text(.roomLeaveConfirmationMessage)
        }
    }

    // MARK: - Leave

    private var leave: some View {
        Button {
            viewModel.isLeaveRoomConfirmationAlertPresented = true
        } label: {
            Text(.roomLeaveTitle)
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
                Text(.roomUsernameTitle)
            } //: LabeledContent
        }
    }

    // MARK: - Toggle

    private var toggle: some View {
        Toggle(isOn: $viewModel.isCaller) {
            Text(.roomCallerTitle)
        } //: Toggle
        .disabled(viewModel.isConnected || viewModel.isConnecting)
        // The role decides who opens a meeting, and it is fixed for as long as
        // the room is reached, which the dimming alone does not explain.
        .accessibilityHint(Text(.roomCallerHint))
    }

    // MARK: - Peers

    @ViewBuilder
    private var peers: some View {
        if viewModel.isConnected, viewModel.peers.isEmpty {
            Text(.roomPeersEmpty)
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
        let message: Text? = if viewModel.isRoomFull {
            Text(.roomFailureFull)
        } else if viewModel.hasFailedToConnect {
            Text(.roomFailureUnreachable)
        } else {
            nil
        }

        if let message {
            message
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
                Text(.roomConnectionConnecting)
            } else if viewModel.isConnected {
                Text(.roomConnectionDisconnect)
            } else if viewModel.hasFailedToConnect || viewModel.isRoomFull {
                Text(.roomConnectionRetry)
            } else {
                Text(.roomConnectionConnect)
            }

            title
                .frame(maxWidth: .infinity)
        } //: Button
        .disabled(viewModel.isConnecting)
        .tint(viewModel.isConnected ? .red : .accentColor)
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
