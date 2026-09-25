// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MachO-Reader",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "macho-reader", targets: ["MachOReaderCLI"]),
        .library(name: "MachOReaderLib", targets: ["MachOReaderLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "MachOReaderCLI",
            dependencies: [
                .target(name: "MachOReaderLib"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),
        .target(
            name: "MachOReaderLib",
        ),
        .testTarget(
            name: "MachOReaderLibTests",
            dependencies: [
                "MachOReaderLib",
            ],
            resources: [
                .process("Fixtures/helloworld"),
                .process("Fixtures/helloworld.swift.txt"),
                .process("Fixtures/ls"),
            ],
        ),
    ],
)
