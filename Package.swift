// swift-tools-version:5.3
import PackageDescription


let package = Package(
    name: "SKTiled",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "SKTiled",
            targets: ["SKTiled"])
    ],
    targets: [
        .target(
            name: "SKTiled",
            dependencies: [],
            path: "Sources",
            exclude: [
                "Info.plist"
            ]
        )
    ]
)
