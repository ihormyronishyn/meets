//
//  RootView.swift
//  App
//

import Stinsen
import SwiftUI

/// What the application shows, and the whole of what it knows about navigation.
///
/// The library that drives the stack stays behind this view, so the target of
/// the application declares neither it nor a route, and the map of the
/// application remains readable in one file beside this one.
public struct RootView: View {

    // MARK: - Properties

    private let server: Server

    // MARK: - Init

    public init(server: Server = .current) {
        self.server = server
    }

    // MARK: - Body

    public var body: some View {
        NavigationViewCoordinator(
            AppCoordinator(server: server),
        ).view()
    }
}
