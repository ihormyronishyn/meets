// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Components",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Components",
            targets: ["Components"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/stasel/WebRTC", exact: "150.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Components",
            dependencies: [
                .product(name: "WebRTC", package: "WebRTC"),
            ],
        ),
        .testTarget(
            name: "ComponentsTests",
            dependencies: [
                "Components",
                .product(name: "WebRTC", package: "WebRTC"),
            ],
        ),
    ],
    swiftLanguageModes: [.v6],
)
