// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

/// The composition root is drawn and driven on the main actor, and it conforms
/// to routing protocols declared in the modules below it. The target of the
/// application carries the same two settings, so moving the code here rather
/// than leaving it there changes nothing about how it is checked.
let swiftSettings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "App",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "App",
            targets: ["App"],
        ),
    ],
    dependencies: [
        .package(path: "../../Core/Entities"),
        .package(path: "../../Features/Login"),
        .package(path: "../../Features/Meet"),
        .package(path: "../../Features/Room"),
        .package(path: "../../Shared/Services"),
        .package(url: "https://github.com/rundfunk47/stinsen", exact: "2.0.15"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "App",
            dependencies: [
                "Entities",
                "Login",
                "Meet",
                "Room",
                "Services",
                .product(name: "Stinsen", package: "stinsen"),
            ],
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "App",
                "Entities",
                "Services",
            ],
            swiftSettings: swiftSettings,
        ),
    ],
    swiftLanguageModes: [.v6],
)
