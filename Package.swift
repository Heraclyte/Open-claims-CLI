import PackageDescription

let package = Package(
    name: "openclaims",
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0"..<"5.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "openclaims",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift-crypto"),
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
