// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SKTiled",
    platforms: [
      .iOS(.v12),
      .macOS(.v10_12),
      .tvOS(.v12)
    ],
    products: [
        .library(
            name: "SKTiled",
            targets: ["SKTiled"]),
    ],
  dependencies: [],
    targets: [
        .target(
            name: "SKTiled",
            dependencies: [],
            path: "Sources",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "SKTiledTests",
            dependencies: ["SKTiled"],
            path: "Tests",
            exclude: [
              "Info-tvOS.plist",
              "Info-iOS.plist",
              "Info-macOS.plist"
            ],
            resources: [
              .copy("Assets/test-tilemap.tmx"),
              .copy("Assets/characters-8x8.png"),
              .copy("Assets/characters-8x8.tsx"),
              .copy("Assets/environment-8x8.png"),
              .copy("Assets/environment-8x8.tsx"),
              .copy("Assets/items-8x8.png"),
              .copy("Assets/items-8x8.tsx"),
              .copy("Assets/items-alt-8x8.png"),
              .copy("Assets/monsters-16x16.png"),
              .copy("Assets/monsters-16x16.tsx"),
              .copy("Assets/portraits-8x8.png"),
              .copy("Assets/portraits-8x8.tsx"),
            ]
        )
    ]
)
