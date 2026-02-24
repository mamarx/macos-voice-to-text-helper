// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "aihelper",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "aihelper",
            path: "aihelper",
            exclude: ["Info.plist"]
        )
    ]
)
