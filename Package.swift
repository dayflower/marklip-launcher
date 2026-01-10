// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarklipLauncher",
    platforms: [
        .macOS(.v12)
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
            dependencies: [],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/Resources/Info.plist"
                ])
            ]
        )
    ]
)
