# Getting Started

- [Requirements](#requirements)
    - [Swift 2 Note](#swift-2-note)
- [SKTiled Project](#sktiled-project)
- [Installation](#installation)
    - [Framework Installation](#framework-installation)
    - [Source Code Installation](#source-code-installation)
        - [Linking zlib](#linking-zlib)
    - [Carthage Installation](#carthage-installation)
- [Adding Tiled Assets to Xcode](#adding-tiled-assets-to-xcode)


**SKTiled** was designed to be flexible and easy to use. To get started, simply drop the source files into your project and link the **zlib** library (see below). If you have any problems or requests, please open an issue at the [Github page](https://github.com/mfessenden/SKTiled/issues).


## Requirements

- iOS9+ / macOS 10.11+
- Xcode 8
- Swift 3


#### **Swift 2 Note**

Check out the [Swift 2](https://github.com/mfessenden/SKTiled/tree/swift2) branch for Swift 2.3. As Apple is moving forward so quickly to Swift 3, the Swift 2.3 branch is now considered legacy and won't be updated. 

If you're using one of the older toolchains, you'll need to enable the **Use Legacy Swift Language Version** option in the project **Build Settings.**

![Legacy Swift Version](images/swift_legacy.png)


## Installation

When you clone the **SKTiled** project, you'll see that there are four targets included. Two are demo applications, one for iOS and one for macOS. Those are included to let you quickly test your own content, or simple play around with the included demo content. 


![Project Targets](images/project_targets.png)

- SKTiled iOS Framework
- SKTiled macOS Framework
- SKTiled iOS Demo Project
- SKTiled macOS Demo Project

The demo projects are there for you to build and test your own Tiled content. The frameworks are bundles that can be linked in your SpriteKit projects. 

To use the frameworks, build one or both of the targets and install them in a location accessible to your project. Make sure the *Minimum Deployment Target* is set correctly for your project (iOS 9+/macOS 10.11+).

### **Framework Installation**

After building the framework(s), you'll need to add it to your Xcode project and 

![adding framework](images/framework.png)

Select your target, and add the framework to the *Embedded Binaries* and *Linked Frameworks and Libraries* sections of the *General* tab. 

![framework linking](images/link_binary.png)

You'll also add it to the *Build Phases > Embed Frameworks* section. 

![framework embed](images/links.png)

### **Source Code Installation**

It is also possible to integrate the source code directly into your project. To do this, you'll need to copy the `Sources` and `zlib` directories to your project. Make sure the swift files are added to your target(s). 

![Xcode installation](images/installation.png)

#### Linking zlib

Add the `zlib` directory to your project's include paths:
    - *Project > Build Settings > Swift Compiler - Search Paths > Import Paths*

![zlib compression](images/zlib_linking.png)


### Carthage Installation

To install with [Carthage](https://github.com/Carthage/Carthage), browse to the root of the project that you want to build the SKTiled framework with and create an empty Cartfile:


    touch Cartfile


Open the Cartfile with a text editor and add a reference to **SKTiled** (be sure to check the current version number):
 
    github "mfessenden/SKTiled" == 1.07
    
    
Close the file and run Carthage from the terminal to build the framework(s) for the platform you want: 

    carthage update --platform iOS   // specify `iOS` or `macOS` 

Updating is just as simple. Simply change the version number in the Cartfile to the one you want, and carthage can update the frameworks for you:

    carthage update --platform iOS

Once you've run the build command frameworks are built, you'll find a **Carthage** directory in the root of your project. The frameworks are located in the **Carthage/Build/$PLATFORM_NAME** directories, simply install them as described in the [framework installation](#framework-installation) section above.


![Carthage Directories](images/carthage_directories.png)


See the [Carthage](https://github.com/Carthage/Carthage) home page for help and additional build instructions. 

## Adding Tiled Assets to Xcode

When adding maps (TMX files), images and tilesets (TSX files) to your Xcode project, you'll need to make sure to add the files as **groups** and not folder references as the assets are stored in the root of the app bundle when compiled. Relative file references in your Tiled files will break when the are added to your app's bundle.



Next: [Setting Up Your Scenes](scenes.html) - [Index](Tutorial.html)
