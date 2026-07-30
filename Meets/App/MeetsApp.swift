//
//  MeetsApp.swift
//  Meets
//

import Stinsen
import SwiftUI

@main
struct MeetsApp: App {

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            NavigationViewCoordinator(
                AppCoordinator(server: .current),
            ).view()
        } //: WindowGroup
    }
}
