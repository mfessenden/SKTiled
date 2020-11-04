# Getting Started

- [Requirements](#requirements)
- [Installation](#installation)
    - [Framework Installation](#framework-installation)
    - [Carthage Installation](#carthage-installation)
    - [CocoaPods Installation](#cocoapods-installation)
    - [Building the Documentation](#building-the-documentation)
- [tvOS Support](#tvos-support)
    - [A Note About 4K](#a-note-about-4k)
- [Adding Tiled Assets to Xcode](#adding-tiled-assets-to-xcode)
    - [Referenced Assets](#referenced-assets)



**SKTiled** was designed to be flexible and easy to use. To get started, simply build the framework and add your assets to your Xcode project. If you have any problems or requests, please open an issue at the [**Github page**](https://github.com/mfessenden/SKTiled/issues).


## Requirements

- iOS 11
- tvOS 12
- macOS 10.12
- Xcode 11/Swift 5


## Installation

The **SKTiled** project contains six targets; three are demo applications for iOS/tvOS/macOS. These are included to let you quickly test your own content, or simple play around with the included demo files. The other three are frameworks for use in your own projects.

![Project Schemes](images/project-schemes.png)

To use the frameworks, build the appropriate framework target and add to your project. Make sure the **Minimum Deployment Target** is set correctly for your project (iOS11+/macOS 10.12+/tvOS12+).

### Framework Installation

To use the frameworks, build the appropriate framework target and add to your project. Make sure the **Minimum Deployment Target** is set correctly for your project (iOS11+/macOS 10.12+/tvOS12+).

![adding framework](images/framework.png)

After building the framework(s), you'll need to add them to your project. Select your target, and add the framework to the **Embedded Binaries** and **Linked Frameworks and Libraries** sections of the **General** tab. You'll also need to make sure it is linked in the **Build Phases > Embed Frameworks** section.


![framework embed](images/links.png)


### Carthage Installation

To build with [Carthage](https://github.com/Carthage/Carthage), create a Cartfile in your project root and add a reference to **SKTiled** (be sure to check the current version number):

    github "mfessenden/SKTiled" ~> 1.22


Close the file and run Carthage from the terminal to build the framework(s):

    carthage update

To build for a specific platform, use the `platform` argument in your build command:

    carthage update --platform iOS

Once you've run the build command frameworks are built, you'll find a **Carthage** directory in the root of your project. The frameworks are located in the **Carthage/Build/$PLATFORM_NAME** directories, simply install them as described in the [framework installation](#framework-installation) section above.

![Carthage Directories](images/carthage_directories.png)

See the [Carthage](https://github.com/Carthage/Carthage) home page for help and additional build instructions.

### CocoaPods Installation

Installation with [CocoaPods](https://cocoapods.org) is similar to Carthage. Create a **podfile** in your project root with the command:

    pod init

Add references to **SKTiled** in each of your targets:


    target 'iOS' do
      use_frameworks!

      # Pods for iOS
      pod 'SKTiled', '~> 1.22'

    end

    target 'macOS' do
      use_frameworks!

      # Pods for macOS
      pod 'SKTiled', '~> 1.22'

    end

    target 'tvOS' do
      use_frameworks!

      # Pods for tvOS
      pod 'SKTiled', '~> 1.22'

    end


As before, be sure to check the version number. In the terminal, run the installer:

    pod install


CocoaPods will create an **.xcworkspace** file with the name of your project. Open that and use this to compile your targets; dependencies will be linked automatically.


See the [CocoaPods](https://cocoapods.org) home page for help and additional instructions.


### Building the Documentation

To build the documentation, you'll need to install [**jazzy**][jazzy-url]. To build the html content, simply run the included script in a shell:

	./scripts/build-docs.sh


## tvOS Support

![AppleTV Devices](images/appletv-devices.png)

**SKTiled** can now be built for AppleTV devices, including AppleTV 4K. Currently only tvOS 11+ is supported, although earlier versions might be added in the future.

### A Note About 4K

![AppleTV 4K](images/appletv-4k-launch.png)

If you are displaying content on a 4K AppleTV, check that your Asset LaunchImage has a 2x resolution of **3840 x 2160**. This will ensure that your game runs at a full 4K resolution.



## Adding Tiled Assets to Xcode

![Grouped Assets][xcode-assets-group-img]

When adding assets to your Xcode project, files are automatically bundled in your application. To load a bundled tile map, use the `SKTilemap.load(tmxFile:)` method to read the file:


```swift
if let tilemap = SKTilemap.load(tmxFile: "MyTilemap.tmx") {
    scene.addChild(tilemap)
}
```

On your hard drive, the map's tileset and image should be in the same directory as the map to avoid read errors. Try this instead: [`SKTilemap.load(:)`][sktilemap-load-url]


### Referenced Assets


![Referenced Assets][xcode-assets-ref-img]

If you add assets as folder references, you can supply a directory name with the `inDirectory` argument of `SKTilemap.load(tmxFile:)` method:


```swift
if let tilemap = SKTilemap.load(tmxFile: "MyTilemap.tmx", inDirectory: "Tiled") {
    scene.addChild(tilemap)
}
```

This will allow you more flexibility organizing your project, but be careful that your maps don't reference files above the referenced folder. For more information, see the [**Working with Maps**][working-with-maps-url] section.


Next: [Scene Setup](scene-setup.html) - [Index](Table of Contents.html)


<!--- Images --->

[assets-finder-img]:images/assets-finder.png
[xcode-add-assets-img]:images/xcode-add-assets-group.png
[xcode-assets-group-img]:images/xcode-assets-group.png
[xcode-assets-ref-img]:images/xcode-assets-referenced.png
[xcode-add-assets-ref-img]:images/xcode-add-assets-reference.png
[assets-finder-img]:images/assets-finder.png
[zlib-include-img]:images/zlib-include.png

<!--- URLs --->

[swift4-url]:https://github.com/mfessenden/SKTiled/tree/swift4
[xcode8-url]:https://github.com/mfessenden/SKTiled/tree/xcode8

[sktilemap-load-url]:SKTilemap.load(tmxFile:inDirectory:delegate:withTilesets:ignoreProperties:loggingLevel:)
[working-with-maps-url]:working-with-maps.html#loading-a-tilemap
[jazzy-url]:https://github.com/realm/jazzy
