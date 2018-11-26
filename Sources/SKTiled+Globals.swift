//
//  SKTiled+Globals.swift
//  SKTiled Demo
//
//  Created by Michael Fessenden on 8/4/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import SpriteKit
import Metal


/**

 ## Overview ##

 The `TiledGlobals` object provides information about the framework, as well as allowing
 you to set default **SKTiled** attributes.


 ### Properties ###

 | Property              | Description                   |
 |:----------------------|:------------------------------|
 | renderer              | SpriteKit renderer.           |
 | loggingLevel          | Logging verbosity.            |
 | updateMode            | Default tile update mode.     |
 | enableRenderCallbacks | Send render statistics.       |
 | enableCameraCallbacks | Send camera updates.          |
 | renderQuality         | Global render quality values. |
 | contentScale          | Retina display scale factor.  |
 | version               | Framework version.            |

 ### Usage ###

 **SKTiled** object default values are set in the `TiledGlobals` object.

 ```swift
 // access the default singleton instance
 let tiledGlobals = TiledGlobals.default

 // disable camera callbacks
 tiledGlobals.enableCameraCallbacks = false
 
 // set debugging mouse filters (macOS)
 tiledGlobals.debug.mouseFilters = [.tileCoordinates, .tilesUnderCursor]

 // increase the default text object render quality
 tiledGlobals.renderQuality.text = 12.0
 ```
 */
public class TiledGlobals {
    /// Default singleton instance.
    static public let `default` = TiledGlobals()
    /// Current SpriteKit renderer.
    public private(set) var renderer: Renderer = Renderer.metal
    /// Default logging verbosity.
    public var loggingLevel:  LoggingLevel = LoggingLevel.info
    /// Default tile update mode.
    public var updateMode: TileUpdateMode = TileUpdateMode.dynamic
    /// Enable callbacks for render performance statistics.
    public var enableRenderCallbacks: Bool = false
    /// Enable callbacks from camera to camera delegates.
    public var enableCameraCallbacks: Bool = true
    /// Default tile/object render quality attributes.
    public var renderQuality: RenderQuality = RenderQuality()
    /// Debugging display options.
    public var debug: DebugDisplayOptions = DebugDisplayOptions()
    /// Render statistics display.
    public var timeDisplayMode: TimeDisplayMode = TimeDisplayMode.milliseconds
    /// Returns the current device backing scale.
    public var contentScale: CGFloat {
        return getContentScaleFactor()
    }

    /// Returns current framework version.
    public var version: Version {
        return Version(getSKTiledVersion())
    }

    /// Returns current framework build (if any).
    internal var build: String? {
        return getSKTiledBuildVersion()
    }

    private init() {
        let device = MTLCreateSystemDefaultDevice()
        renderer = (device != nil) ? Renderer.metal : Renderer.opengl
    }

    /**
     ### Overview ###

     Structure representing the framework version (semantic version).

     #### Properties ####

     | Property              | Description                  |
     |:----------------------|:-----------------------------|
     | major                 | Framework major version.     |
     | minor                 | Framework minor version.     |
     | patch                 | Framework patch version      |

     */
    public struct Version {
        var major: Int = 0
        var minor: Int = 0
        var patch: Int = 0

        init(major: Int, minor: Int, patch: Int = 0) {
            self.major = major
            self.minor = minor
            self.patch = patch
        }
    }


    /**
     ### Overview ###

     Represents object's render quality when dealing with higher resolutions.

     #### Properties ####

     | Property              | Description                              |
     |:----------------------|:-----------------------------------------|
     | default               | Global render quality.                   |
     | object                | Object render quality.                   |
     | text                  | Text object render quality               |
     | override              | Override value.                          |

     */
    public struct RenderQuality {
        var `default`: CGFloat = 3
        var object: CGFloat = 8
        var text: CGFloat = 8
        var override: CGFloat = 0
    }

    /**
     ### Overview ###

     Global debug display properties.

     */
    public struct DebugDisplayOptions {

        /// Debug properties for mouse movements.
        public var mouseFilters: MouseFilters = MouseFilters.tileCoordinates
        /// Debug display properties.
        public var highlightDuration: TimeInterval = 0.3
        public var gridOpactity: CGFloat = 0.4
        public var gridColor: SKColor = TiledObjectColors.grass
        public var frameColor: SKColor = TiledObjectColors.grass
        public var tileHighlightColor: SKColor = TiledObjectColors.lime
        public var objectFillOpacity: CGFloat = 0.25
        public var objectHighlightColor: SKColor = TiledObjectColors.coral
        public var navigationColor: SKColor = TiledObjectColors.azure

        /**
         ### Overview ###

         Global debug display mouse filter options (macOS).

         #### Properties ####

         | Property              | Description                              |
         |:----------------------|:-----------------------------------------|
         | tileCoordinates       | Show tile coordinates.                   |
         | sceneCoordinates      | Show scene coordinates.                  |
         | tileDataUnderCursor   | Show tile data properties.               |
         | tilesUnderCursor      | Highlight tiles under the cursor.        |
         | objectsUnderCursor    | Highlight objects under the cursor.      |

         */
        public struct MouseFilters: OptionSet {
            public let rawValue: Int

            static let tileCoordinates      = MouseFilters(rawValue: 1 << 0)   // 1*
            static let tileLocalID          = MouseFilters(rawValue: 1 << 1)   // 2
            static let sceneCoordinates     = MouseFilters(rawValue: 1 << 2)   // 4
            static let tileDataUnderCursor  = MouseFilters(rawValue: 1 << 3)   // 8*
            static let tilesUnderCursor     = MouseFilters(rawValue: 1 << 4)   // 16
            static let objectsUnderCursor   = MouseFilters(rawValue: 1 << 5)   // 32

            static public let all: MouseFilters = [.tileCoordinates, .tileLocalID, .sceneCoordinates, .tileDataUnderCursor, .tilesUnderCursor, .objectsUnderCursor]

            public init(rawValue: Int = 0) {
                self.rawValue = rawValue
            }
        }
    }

    /**
     ## Overview ##

     Display flag for render statistics.

     ### Properties ##

     | Property              | Description                              |
     |:----------------------|:-----------------------------------------|
     | milliseconds          | Show render time in milliseconds.        |
     | seconds               | Show render time in seconds.             |

     */
    public enum TimeDisplayMode: Int {
        case milliseconds
        case seconds
    }

    /**
     ## Overview ##

     Indicates the current renderer (OpenGL or Metal).

     ### Properties ##

     | Property | Description                                         |
     |:---------|:----------------------------------------------------|
     | opengl   | Indicates the current SpriteKit renderer is OpenGL. |
     | metal    | Indicates the current SpriteKit renderer is Metal.  |

     */
    public enum Renderer {
        case opengl
        case metal
    }
}


internal struct TiledObjectColors {
    static let azure: SKColor       = SKColor(hexString: "#4A90E2")
    static let coral: SKColor       = SKColor(hexString: "#FD4444")
    static let crimson: SKColor     = SKColor(hexString: "#D0021B")
    static let dandelion: SKColor   = SKColor(hexString: "#F8E71C")
    static let english: SKColor     = SKColor(hexString: "#AF3E4D")
    static let grass: SKColor       = SKColor(hexString: "#B8E986")
    static let gun: SKColor         = SKColor(hexString: "#8D99AE")
    static let indigo: SKColor      = SKColor(hexString: "#274060")
    static let lime: SKColor        = SKColor(hexString: "#7ED321")
    static let magenta: SKColor     = SKColor(hexString: "#FF00FF")
    static let metal: SKColor       = SKColor(hexString: "#627C85")
    static let obsidian: SKColor    = SKColor(hexString: "#464B4E")
    static let pear: SKColor        = SKColor(hexString: "#CEE82C")
    static let saffron: SKColor     = SKColor(hexString: "#F28123")
    static let tangerine: SKColor   = SKColor(hexString: "#F5A623")
    static let turquoise: SKColor   = SKColor(hexString: "#44CFCB")
}


// MARK: - Extensions


extension TiledGlobals: CustomDebugReflectable {

    func dumpStatistics() {
        print("\n----------- SKTiled Globals -----------")
        print("  - framework version:    \(self.version.description)")
        print("  - swift version:        \(getSwiftVersion())")

        if let buildVersion = self.build {
            print("  - build version:        \(buildVersion)")
        }

        print("  - renderer:             \(self.renderer.name)")
        print("  - ui scale:             \(self.contentScale)")
        print("  - logging level:        \(self.loggingLevel)")
        print("  - update mode:          \(self.updateMode.name)")
        print("  - render callbacks:     \(self.enableRenderCallbacks)")
        print("  - camera callbacks:     \(self.enableCameraCallbacks)\n")
        print("  - Debug Display: ")
        print("     - highlight duration:   \(self.debug.highlightDuration)")
        print("     - grid opacity:         \(self.debug.gridOpactity)")
        print("     - object fill opacity:  \(self.debug.objectFillOpacity)")
        print("     - grid color:           \(self.debug.gridColor.hexString())\n")
        print("  - Render Quality: ")
        print("     - default:   \(self.renderQuality.default)")
        print("     - object:    \(self.renderQuality.object)")
        print("     - text:      \(self.renderQuality.text)")
        print(self.renderQuality.override > 0 ? "     - override:  \(self.renderQuality.override)\n" : "")
        print("  - Debug Mouse Filters:")
        print("     - tile coordinates:  \(self.debug.mouseFilters.contains(.tileCoordinates))")
        print("     - scene coordinates: \(self.debug.mouseFilters.contains(.sceneCoordinates))")
        print("     - tile data:         \(self.debug.mouseFilters.contains(.tileDataUnderCursor))")
        print("     - highlight tiles:   \(self.debug.mouseFilters.contains(.tilesUnderCursor))")
        print("     - highlight objects: \(self.debug.mouseFilters.contains(.objectsUnderCursor))")
        print("\n---------------------------------------\n")
    }
}



extension TiledGlobals.Version {
    /**
     Initialize with a string (ie "2.1.4").
     */
    init(_ value: String) {
        let parts = value.split(separator: ".").compactMap { Int($0) }
        switch parts.count {
        case 1:
            self.major = parts.first!
        case 2:
            self.major = parts.first!
            self.minor = parts[1]
        case 3:
            self.major = parts.first!
            self.minor = parts[1]
            self.patch = parts[2]
        default:
            self.major = 1
            self.minor = 0
            self.patch = 0
        }
    }
}


extension TiledGlobals.Version: CustomStringConvertible, CustomDebugStringConvertible {
    /// String description of the framework version.
    public var description: String { return "\(major).\(minor)\(patch > 0 ? ".\(patch)" : "")" }
    /// String description of the framework version.
    public var debugDescription: String { return self.description }
}


extension TiledGlobals.TimeDisplayMode {

    var allModes: [TiledGlobals.TimeDisplayMode] {
        return [.seconds, .milliseconds]
    }

    var uiControlString: String {
        switch self {
        case .seconds: return "Seconds"
        case .milliseconds: return "Milliseconds"
        }
    }
}



extension TiledGlobals.Renderer {

    var name: String {
        switch self {
        case .opengl: return "OpenGL"
        case .metal: return "Metal"
        }
    }
}


extension TiledGlobals.DebugDisplayOptions.MouseFilters {

    public var strings: [String] {
        var result: [String] = []
        if self.contains(.tileCoordinates) {
            result.append("Tile Coordinates")
        }

        if self.contains(.tileLocalID) {
            result.append("Tile Local ID")
        }

        if self.contains(.sceneCoordinates) {
            result.append("Scene Coordinates")
        }

        if self.contains(.tileDataUnderCursor) {
            result.append("Tile Data")
        }

        if self.contains(.tilesUnderCursor) {
            result.append("Tiles Under Cursor")
        }

        if self.contains(.objectsUnderCursor) {
            result.append("Objects Under Cursor")
        }

        return result
    }

}


extension TiledObjectColors {
    /// Returns an array of all colors.
    static let all: [SKColor] = [azure, coral, crimson, dandelion,
                                 english, grass, gun, indigo, lime,
                                 magenta, metal, obsidian, pear,
                                 saffron, tangerine, turquoise]

    /// Returns an array of all color names.
    static let names: [String] = ["azure", "coral", "crimson","dandelion",
                                  "english","grass","gun","indigo","lime",
                                  "magenta","metal","obsidian","pear",
                                  "saffron","tangerine","turquoise"]
    /// Returns a random color.
    static var random: SKColor {
        let randIndex = Int(arc4random_uniform(UInt32(TiledObjectColors.all.count)))
        return TiledObjectColors.all[randIndex]
    }
}
