// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Flows",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
//        .linux
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Flows",
            targets: ["Flows"]),
        .executable(
            name: "flow",
            targets: ["FlowTool"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
//        .package(path: "../../Projects/Tarot"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Flows",
            dependencies: [
                "Graph",
            ]),
        .target(
            name: "Graph",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
            ]),
        .executableTarget(
            name: "FlowTool",
            dependencies: [
                "Flows",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SystemPackage", package: "swift-system"),
            ]),
        .testTarget(
            name: "FlowsTests",
            dependencies: ["Flows"]),
        .testTarget(
            name: "GraphTests",
            dependencies: ["Graph"]),
    ]
)
