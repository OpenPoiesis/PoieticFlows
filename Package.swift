// swift-tools-version: 5.10
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
        .executable(
            name: "poietic",
            targets: ["PoieticFlowTool"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.2.2"),
        .package(url: "https://github.com/openpoiesis/PoieticCore", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PoieticFlows",
            dependencies: ["PoieticCore"]
        ),

        .executableTarget(
            name: "PoieticFlowTool",
            dependencies: [
                "PoieticCore",
                "PoieticFlows",
                .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "RealModule", package: "swift-numerics"),
            ],
            path: "Sources/PoieticTool"
        ),
        .testTarget(
            name: "PoieticFlowsTests",
            dependencies: ["PoieticFlows"]),
    ]
)
