// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarklipLauncher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "marklip-launcher",
            targets: ["MarklipLauncher"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MarklipLauncher",
            dependencies: []
        )
    ]
)
