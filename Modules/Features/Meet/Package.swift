// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Meet",
    // The strings of this screen are carried by the module that draws it, so
    // the catalog beside them is what the package ships and looks up.
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Meet",
            targets: ["Meet"],
        ),
    ],
    dependencies: [
        .package(path: "../../Core/Entities"),
        .package(path: "../../Core/Utilities"),
        .package(path: "../../Shared/Components"),
        .package(path: "../../Shared/Services"),
        .package(url: "https://github.com/stasel/WebRTC", exact: "150.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Meet",
            dependencies: [
                "Components",
                "Entities",
                "Services",
                "Utilities",
                .product(name: "WebRTC", package: "WebRTC"),
            ],
            resources: [
                .process("Resources"),
            ],
        ),
        .testTarget(
            name: "MeetTests",
            dependencies: [
                "Meet",
                "Entities",
                "Services",
                .product(name: "WebRTC", package: "WebRTC"),
            ],
        ),
    ],
    swiftLanguageModes: [.v6],
)
