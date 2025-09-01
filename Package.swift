// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WKDevKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "WKDevKit",
            targets: ["WKDevKit"]
        ),
    ],
    targets: [
        .target(
            name: "WKDevKit",
            path: "WKDevKit/Sources/WKDevKit"
        ),
        .testTarget(
            name: "WKDevKitTests",
            dependencies: ["WKDevKit"],
            path: "WKDevKit/Tests/WKDevKitTests"
        ),
    ]
)
