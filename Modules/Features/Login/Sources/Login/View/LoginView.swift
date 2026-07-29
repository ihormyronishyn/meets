//
//  LoginView.swift
//  Login
//

import Services
import SwiftUI

public struct LoginView: View {

    // MARK: - Properties

    @Bindable private var viewModel: LoginViewModel

    @FocusState private var isFieldFocused: Bool

    // MARK: - Init

    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        form
            .safeAreaBar(edge: .bottom) {
                button
            }
    }

    // MARK: - Form

    private var form: some View {
        Form {
            section
        } //: Form
        .scrollDisabled(true)
        // The whole frame answers to a tap, so the empty space around the
        // fields counts as background. A tap that a field claims never
        // reaches here, which leaves entering a field working as before.
        .contentShape(.rect)
        .onTapGesture {
            isFieldFocused = false
        }
    }

    // MARK: - Section

    private var section: some View {
        Section {
            Group {
                field(text: $viewModel.usernameText, title: "Username")
                field(text: $viewModel.roomIdText, title: "Room ID", keyboardType: .numberPad)
            } //: Group
            .focused($isFieldFocused)
        } header: {
            header
        } //: Section
    }

    // MARK: - Header

    private var header: some View {
        VStack {
            Text("Join a Room")
                .font(.title)
                .fontWeight(.bold)
            Text("Enter your username and room identifier to join.")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        } //: VStack
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.bottom)
    }

    // MARK: - Field

    private func field(text: Binding<String>, title: String, keyboardType: UIKeyboardType = .default) -> some View {
        TextField(title, text: text).keyboardType(keyboardType)
    }

    // MARK: - Button

    private var button: some View {
        Button {
            viewModel.login()
        } label: {
            Text("Join Room")
                .frame(maxWidth: .infinity)
        } //: Button
        .disabled(!viewModel.isLoginAllowed)
        .tint(.orange)
        .fontWeight(.medium)
        .buttonStyle(.glassProminent)
        .controlSize(.extraLarge)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    LoginView(
        viewModel: LoginViewModel(userAuthenticationService: UserAuthenticationService()),
    )
}
