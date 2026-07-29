//
//  ContentView.swift
//  Meets
//

import Login
import Services
import SwiftUI

struct ContentView: View {

    // MARK: - Body

    var body: some View {
        LoginView(viewModel: LoginViewModel(userAuthenticationService: UserAuthenticationService()))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
