# Getting Started

- [Requirements](#requirements)
    - [Swift 2 Note](#swift-2-note)
- [SKTiled Project](#sktiled-project)
- [Installation](#installation)
    - [Framework Installation](#framework-framework)
    - [Source Code Installation](#source-code-installation)
        - [Linking zlib](#linking-zlib)
- [Adding Tiled Assets to Xcode](#adding-tiled-assets-to-xcode)

**SKTiled** was designed to be flexible and easy to use. To get started, simply drop the source files into your project and link the **zlib** library (see below). If you have any problems or requests, please open an issue at the [Github page](https://github.com/mfessenden/SKTiled/issues).


## Requirements

- iOS9+ / macOS 10.11+
- Xcode 8
- Swift 3


#### **Swift 2 Note**

Check out the [Swift 2](https://github.com/mfessenden/SKTiled/tree/swift2) branch for Swift 2.3. As Apple is moving forward so quickly to Swift 3, the Swift 2.3 branch is now considered legacy and won't be updated. 

If you're using one of the older toolchains, you'll need to enable the **Use Legacy Swift Language Version** option in the project **Build Settings.**

![Legacy Swift Version](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/swift_legacy.png)


## Installation

When you clone the **SKTiled** project, you'll see that there are four targets included:

![Project Targets](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/project_targets.png)

- SKTiled iOS Framework
- SKTiled macOS Framework
- SKTiled iOS Demo Project
- SKTiled macOS Demo Project

The demo projects are there for you to build and test your own Tiled content. The frameworks are bundles that can be linked in your SpriteKit projects. 

To use the frameworks, build one or both of the targets and install them in a location accessible to your project.

### Framework Installation

After building the framework(s), you'll need to add it to your Xcode project and 

![adding framework](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/framework.png)

Select your target, and add the framework to the *Embedded Binaries* and *Linked Frameworks and Libraries* sections of the *General* tab. 

![framework linking](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/link_binary.png)

You'll also add it to the *Build Phases > Embed Frameworks* section. 

![framework embed](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/links.png)

### Source Code Installation

It is also possible to integrate the source code directly into your project. To do this, you'll need to copy the `Sources` and `zlib` directories to your project. Make sure the swift files are added to your target(s). 

![Xcode installation](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/installation.png)

#### Linking zlib

Add the `zlib` directory to your project's include paths:
    - *Project > Build Settings > Swift Compiler - Search Paths > Import Paths*

![zlib compression](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/zlib_linking.png)

## Deployment Target

Make sure the *Minimum Deployment Target* is set correctly for your project:

- iOS 9 
- macOS 10.11


## Adding Tiled Assets to Xcode

When adding maps (TMX files), images and tilesets (TSX files) to your Xcode project, you'll need to make sure to add the files as **groups** and not folder references as the assets are stored in the root of the app bundle when compiled. Relative file references in your Tiled files will break when the are added to your app's bundle.



Next: [Setting Up Your Scenes](scenes.html) - [Index](Tutorial.html)
