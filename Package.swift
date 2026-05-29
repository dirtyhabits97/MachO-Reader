// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MachO-Reader",
    products: [
        .executable(name: "macho-reader", targets: ["MachOReaderCLI"]),
        .library(name: "MachOReaderLib", targets: ["MachOReaderLib"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "MachOReaderCLI",
            dependencies: [
                .target(name: "MachOReaderLib"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "MachOReaderLib"
        ),
        .target(
            name: "Env"
        ),
        .testTarget(
            name: "MachOReaderLibTests",
            dependencies: [
                "MachOReaderLib",
                "Env",
            ],
            resources: [
                .process("Fixtures/helloworld"),
                .process("Fixtures/helloworld.swift.txt"),
            ]
        ),
        .testTarget(
            name: "EnvTests",
            dependencies: ["Env"]
        ),
    ]
)
