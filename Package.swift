// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "aihelper",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/ggerganov/whisper.spm", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "aihelper",
            dependencies: [
                .product(name: "whisper", package: "whisper.spm")
            ],
            path: "aihelper",
            exclude: ["Info.plist"]
        )
    ]
)
