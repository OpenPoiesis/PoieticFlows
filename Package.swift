// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PoieticFlows",
    platforms: [.macOS("14"), .custom("linux", versionString: "1")],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PoieticFlows",
            targets: ["PoieticFlows"]),
    ],
    dependencies: [
        .package(url: "https://github.com/openpoiesis/PoieticCore", branch: "main"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PoieticFlows",
            dependencies: ["PoieticCore"]
        ),

        .testTarget(
            name: "PoieticFlowsTests",
            dependencies: ["PoieticFlows"]),
    ],
    swiftLanguageVersions: [.v6]

)
