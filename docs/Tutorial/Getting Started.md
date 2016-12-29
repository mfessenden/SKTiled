# Getting Started

- [Requirements](#requirements)
    - [Swift 2 Note](#swift-2-note)
- [Installation](#installation)
- [Adding Tiled Assets to Xcode](#adding-tiled-assets-to-xcode)

**SKTiled** was designed to be flexible and easy to use. To get started, simply drop the source files into your project and link the **zlib** library (see below). If you have any problems or requests, please open an issue at the [Github page](https://github.com/mfessenden/SKTiled/issues).


## Requirements

- iOS9+ / macOS 10.11+
- Xcode 8
- Swift 3


### **Swift 2 Note**

Check out the [Swift 2](https://github.com/mfessenden/SKTiled/tree/swift2) branch for Swift 2.3. As Apple is moving forward so quickly to Swift 3, the Swift 2.3 branch is now considered legacy and won't be updated. 

If you're using one of the older toolchains, you'll need to enable the **Use Legacy Swift Language Version** option in the project **Build Settings.**

![Legacy Swift Version](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/swift_legacy.png)


## Installation

![Xcode installation](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/installation.png)

1. Copy the `Sources` and `zlib` directories to your project. Make sure the swift files are added to your target(s).
2. Add the `zlib` directory to your project's include paths:
    - *Project > Build Settings > Swift Compiler - Search Paths > Import Paths*

![zlib compression](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/zlib_linking.png)


## Adding Tiled Assets to Xcode

When adding maps (TMX files), images and tilesets (TSX files) to your Xcode project, you'll need to make sure to add the files as **groups** and not folder references as the assets are stored in the root of the app bundle when compiled. Relative file references in your Tiled files will break when the are added to your app's bundle.



Next: [Setting Up Your Scenes](scenes.html) - [Index](Tutorial.html)
