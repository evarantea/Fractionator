// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FractionCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FractionCore", targets: ["FractionCore"]),
    ],
    targets: [
        .target(name: "FractionCore"),
        .testTarget(name: "FractionCoreTests", dependencies: ["FractionCore"]),
    ]
)
