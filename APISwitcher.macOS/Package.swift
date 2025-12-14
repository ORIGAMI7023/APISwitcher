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
                "Resources/app_profiles.example.json"
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/app_profiles.example.json")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
