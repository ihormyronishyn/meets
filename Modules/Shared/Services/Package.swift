// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Services",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Services",
            targets: ["Services"],
        ),
    ],
    dependencies: [
        .package(path: "../../Core/Entities"),
        .package(path: "../../Core/Utilities"),
        .package(url: "https://github.com/socketio/socket.io-client-swift", exact: "16.1.1"),
        .package(url: "https://github.com/stasel/WebRTC", exact: "150.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Services",
            dependencies: [
                "Entities",
                "Utilities",
                .product(name: "SocketIO", package: "socket.io-client-swift"),
                .product(name: "WebRTC", package: "WebRTC"),
            ],
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: [
                "Services",
                "Entities",
            ],
        ),
    ],
    swiftLanguageModes: [.v6],
)
