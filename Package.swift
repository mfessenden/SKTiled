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
              .copy("Assets/Templates/dragon-blue.tx"),
              .copy("Assets/test-infinite.tmx"),
              .copy("Assets/test-large-zlib.tmx"),
              .copy("Info-PerformanceTest.plist"),
              .copy("Assets/Templates/light.tx"),
              .copy("Assets/test-large-infinite-zlib.tmx"),
              .copy("Assets/Templates/hole.tx"),
              .copy("Assets/errortest.tmx"),
              .copy("Assets/test-templates.tmx"),
              .copy("Assets/Templates/dragon-yellow.tx"),
              .copy("Assets/test-small-zlib.tmx"),
              .copy("Assets/Templates/dragon-green.tx"),
              .copy("Assets/Templates/eye-monster.tx"),
              .copy("Assets/test-tilemapdelegate.tmx"),
              .copy("Assets/Templates/stairs.tx")
            ]
        )
    ]
)
