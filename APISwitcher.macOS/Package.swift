// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "APISwitcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "APISwitcher",
            targets: ["APISwitcher"]
        )
    ],
    targets: [
        .executableTarget(
            name: "APISwitcher",
            path: "APISwitcher",
            exclude: [
                "Info.plist",
                "Resources/AppIcon.icns",
                "Resources/AppIcon.iconset"
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/app_profiles.example.json")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
