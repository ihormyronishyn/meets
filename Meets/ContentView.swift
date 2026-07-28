//
//  ContentView.swift
//  Meets
//

import SwiftUI

struct ContentView: View {

    // MARK: - Body

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        } //: VStack
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
