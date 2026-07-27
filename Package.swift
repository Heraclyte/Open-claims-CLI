// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "openclaims",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift\u{2D}crypto.git", from: "3.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "openclaims",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift\u{2D}crypto"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "openclaimsTests",
            dependencies: ["openclaims"],
            path: "Tests"
        ),
    ]
)
