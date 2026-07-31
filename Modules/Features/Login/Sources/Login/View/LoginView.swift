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
                field(
                    text: $viewModel.usernameText,
                    title: String(localized: .loginUsernameTitle),
                    contentType: .username,
                )
                field(
                    text: $viewModel.roomIdText,
                    title: String(localized: .loginRoomTitle),
                    keyboardType: .numberPad,
                )
            } //: Group
            .focused($isFieldFocused)
        } header: {
            header
        } //: Section
    }

    // MARK: - Header

    private var header: some View {
        VStack {
            Text(.loginHeading)
                .font(.title)
                .fontWeight(.bold)
                // The rotor of a reader lists headings, and this is the one
                // heading of the screen, so it is marked as such.
                .accessibilityAddTraits(.isHeader)
            Text(.loginSubheading)
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

    /// The title of a field is what a reader hears as its name, so no label is
    /// added on top of it. What the field does need is to say what it holds,
    /// which is what the content type carries, and a keyboard that leaves the
    /// text alone, since a name is typed the way it is meant to be read.
    private func field(
        text: Binding<String>,
        title: String,
        contentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default,
    ) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboardType)
            .textContentType(contentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    // MARK: - Button

    private var button: some View {
        Button {
            viewModel.login()
        } label: {
            Text(.loginJoinTitle)
                .frame(maxWidth: .infinity)
        } //: Button
        .disabled(!viewModel.isLoginAllowed)
        // A hint says what an action leads to, and it can be switched off, so
        // it carries nothing a person needs in order to act. That the button
        // waits for both fields is announced by the dimming itself.
        .accessibilityHint(Text(.loginJoinHint))
        .tint(.accentColor)
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
