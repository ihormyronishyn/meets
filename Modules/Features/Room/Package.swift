// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Room",
    // The strings of this screen are carried by the module that draws it, so
    // the catalog beside them is what the package ships and looks up.
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Room",
            targets: ["Room"],
        ),
    ],
    dependencies: [
        .package(path: "../../Core/Entities"),
        .package(path: "../../Core/Utilities"),
        .package(path: "../../Shared/Services"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Room",
            dependencies: [
                "Entities",
                "Services",
                "Utilities",
            ],
            resources: [
                .process("Resources"),
            ],
        ),
        .testTarget(
            name: "RoomTests",
            dependencies: [
                "Room",
                "Entities",
                "Services",
            ],
        ),
    ],
    swiftLanguageModes: [.v6],
)
