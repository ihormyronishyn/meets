//
//  MeetView.swift
//  Meet
//

import Components
import SwiftUI

public struct MeetView: View {

    // MARK: - Properties

    @Bindable private var viewModel: MeetViewModel

    // MARK: - Init

    public init(viewModel: MeetViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        WebRTCVideoView(track: viewModel.remoteVideoTrack)
            // A rendered picture says nothing to a reader on its own, so both
            // videos are named, and each says whether it carries anything yet.
            .accessibilityElement()
            .accessibilityLabel(Text(.meetRemoteVideoLabel(viewModel.meet.remotePeer.username)))
            .accessibilityValue(Self.presence(isLive: viewModel.remoteVideoTrack != nil))
            .navigationBarBackButtonHidden()
            .ignoresSafeArea(.container, edges: .all)
            .safeAreaInset(edge: .top) {
                panel
            }
            .overlay(alignment: .bottomTrailing) {
                local
            }
            .alert(
                Text(.meetLeaveConfirmationTitle),
                isPresented: $viewModel.isLeaveMeetConfirmationAlertPresented,
            ) {
                Button(role: .destructive) {
                    Task {
                        await viewModel.leaveMeet()
                    }
                } label: {
                    Text(.meetLeaveConfirmationAction)
                } //: Button
            } message: {
                Text(.meetLeaveConfirmationMessage)
            }
            .task {
                await viewModel.start()
            }
    }

    // MARK: - Panel

    private var panel: some View {
        PanelView(peer: viewModel.meet.remotePeer) { action in
            switch action {
            case .leaveMeet:
                viewModel.isLeaveMeetConfirmationAlertPresented = true
            }
        } //: PanelView
    }

    // MARK: - Local

    private var local: some View {
        WebRTCVideoView(track: viewModel.localVideoTrack)
            .aspectRatio(3 / 4, contentMode: .fit)
            .containerRelativeFrame(.horizontal) { width, _ in width / 3 }
            .background(Material.bar)
            .clipShape(.rect(cornerRadius: 16))
            .padding()
            .accessibilityElement()
            .accessibilityLabel(Text(.meetLocalVideoLabel))
            .accessibilityValue(Self.presence(isLive: viewModel.localVideoTrack != nil))
    }

    // MARK: - Presence

    /// What a picture is worth saying about itself, since a reader cannot tell
    /// an empty frame from one carrying a video.
    private static func presence(isLive: Bool) -> Text {
        isLive ? Text(.meetVideoLive) : Text(.meetVideoWaiting)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetView(viewModel: .preview)
    } //: NavigationStack
}
