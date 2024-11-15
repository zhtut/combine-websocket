// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var pDependencies = [PackageDescription.Package.Dependency]()
var tDependencies = [PackageDescription.Target.Dependency]()

#if os(macOS) || os(iOS)
// ios 和 macos不需要这个，系统自带了
#else
let latestVersion: Range<Version> = "0.0.1"..<"99.99.99"
pDependencies += [
    .package(url: "https://github.com/zhtut/CombineX.git", latestVersion),
    .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.3.1"),
]
tDependencies += [
    "CombineX",
    .product(name: "WebSocketKit", package: "websocket-kit"),
]
#endif

let package = Package(
    name: "combine-websocket",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CombineWebSocket",
            targets: ["CombineWebSocket"]),
    ],
    dependencies: pDependencies,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CombineWebSocket", dependencies: tDependencies),
        .testTarget(
            name: "CombineWebSocketTests",
            dependencies: ["CombineWebSocket"]
        ),
    ]
)
