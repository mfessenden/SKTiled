# Getting Started

- [Requirements](#requirements)
    - [Swift 2 Note](#swift-2-note)
- [SKTiled Project](#sktiled-project)
- [Installation](#installation)
    - [Framework Installation](#framework-installation)
    - [Source Code Installation](#source-code-installation)
        - [Linking zlib](#linking-zlib)
    - [Carthage Installation](#carthage-installation)
    - [CocoaPods Installation](#cocoapods-installation)
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

When you clone the **SKTiled** project, you'll see that there are four targets included. Two are demo applications, one for iOS and one for macOS. These are included to let you quickly test your own content, or simple play around with the included demo files. 

![Project Targets](images/project_targets.png)

The frameworks are bundles that can be linked in your SpriteKit projects. To use them, build one or both of the targets and add them to your project. Make sure the *Minimum Deployment Target* is set correctly for your project (iOS 9+/macOS 10.11+).


![adding framework](images/framework.png)

### **Framework Installation**


![adding framework](images/framework.png)

After building the framework(s), you'll need to add them to your project. Select your target, and add the framework to the *Embedded Binaries* and *Linked Frameworks and Libraries* sections of the *General* tab. You'll also need to make sure it is linked in the *Build Phases > Embed Frameworks* section.

![framework linking](images/link_binary.png)

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
 
    github "mfessenden/SKTiled" == 1.10
    
    
Close the file and run Carthage from the terminal to build the framework(s) for the platform you want: 

    carthage update --platform iOS

Updating is just as simple. Simply change the version number in the Cartfile to the one you want, and carthage can update the frameworks for you:

    carthage update --platform iOS

Once you've run the build command frameworks are built, you'll find a **Carthage** directory in the root of your project. The frameworks are located in the **Carthage/Build/$PLATFORM_NAME** directories, simply install them as described in the [framework installation](#framework-installation) section above.


![Carthage Directories](images/carthage_directories.png)


See the [Carthage](https://github.com/Carthage/Carthage) home page for help and additional build instructions. 


### CocoaPods Installation

Installation with [CocoaPods](https://cocoapods.org) is similar to Carthage. To use it, browse to your project root directory in the terminal and run the command:

    pod init

This will create a file called **Podfile** in the directory. Open it up and add references to **SKTiled** in each of your targets:


    # Uncomment the next line to define a global platform for your project
    # platform :ios, '9.0'

    target 'iOS' do
      # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
      use_frameworks!
      
      # Pods for iOS
      pod 'SKTiled', '1.10'

    end

    target 'macOS' do
      # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
      use_frameworks!

      # Pods for macOS
      pod 'SKTiled', '1.10'
      
    end



As before, be sure to check the version number. In the terminal, run the following command:

    pod install
    

CocoaPods will create an **.xcworkspace** file with the name of your project. Open that and use this to compile your targets; dependencies will be linked automatically. 


See the [CocoaPods](https://cocoapods.org) home page for help and additional instructions.


## Adding Tiled Assets to Xcode

When adding maps (TMX files), images and tilesets (TSX files) to your Xcode project, you'll need to make sure to add the files as **groups** and not folder references as the assets are stored in the root of the app bundle when compiled. Relative file references in your Tiled files will break when the are added to your app's bundle.



Next: [Setting Up Your Scenes](scenes.html) - [Index](Tutorial.html)
