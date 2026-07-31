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
            .accessibilityLabel("Video of \(viewModel.meet.remotePeer.username)")
            .accessibilityValue(viewModel.remoteVideoTrack == nil ? "Waiting" : "Live")
            .navigationBarBackButtonHidden()
            .ignoresSafeArea(.container, edges: .all)
            .safeAreaInset(edge: .top) {
                panel
            }
            .overlay(alignment: .bottomTrailing) {
                local
            }
            .alert("Are you sure?", isPresented: $viewModel.isLeaveMeetConfirmationAlertPresented) {
                Button("Leave Meet", role: .destructive) {
                    Task {
                        await viewModel.leaveMeet()
                    }
                } //: Button
            } message: {
                Text("Are you sure you want to leave the meet?")
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
            .accessibilityLabel("Your own video")
            .accessibilityValue(viewModel.localVideoTrack == nil ? "Waiting" : "Live")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetView(viewModel: .preview)
    } //: NavigationStack
}
