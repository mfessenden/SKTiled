//
//  TiledGlobals.swift
//  SKTiled
//
//  Created by Michael Fessenden.
//
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SpriteKit
import Metal


// MARK: - Aliases

/// :nodoc: Tile size of 0,0.
public let TileSizeZero  = CGSize(value: 0)

/// :nodoc: Tile size of 8,8.
public let TileSize8x8   = CGSize(value: 8)

/// :nodoc: Tile size of 16,16.
public let TileSize16x16 = CGSize(value: 16)

/// :nodoc: Tile size of 32,32.
public let TileSize32x32 = CGSize(value: 32)


/**
 
 ## Overview
 
 The `TiledGlobals` object provides information about the framework, as well as allowing
 you to set default **SKTiled** attributes.
 
 
 ### Properties
 
 | Property              | Description                                                |
 |:--------------------- |:---------------------------------------------------------- |
 | renderer              | Returns the current SpriteKit renderer (get-only).         |
 | loggingLevel          | Logging verbosity.                                         |
 | updateMode            | Default tile update mode.                                  |
 | enableRenderCallbacks | Enable callbacks from the tilemap on rendering statistics. |
 | enableCameraCallbacks | Enable callbacks from camera to camera delegates.          |
 | renderQuality         | Global render quality values.                              |
 | contentScale          | Returns the device retina display scale factor.            |
 | version               | Returns the current framework version.                     |
 
 ### Usage
 
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
    public var updateMode: TileUpdateMode = TileUpdateMode.actions
    
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
    public lazy var version: Version = {
        // returns a string from the project: 1300000
        let verString = getSKTiledBuildVersion() ?? getSKTiledVersion()
        var result = Version(integer: verString)
        result.suffix = getSKTiledVersionSuffix()
        return result
    }()
    
    /// Returns current bundle identifier name.
    public lazy var identifier: String = {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let bundleIdentifier = infoDictionary[kCFBundleIdentifierKey as String] as? String  else {
            return "unknown"
        }
        return bundleIdentifier
    }()
    
    /// Returns current framework build (if any).
    internal var build: String? {
        return getSKTiledBuildVersion()
    }
    
    /// Private init.
    private init() {
        let device = MTLCreateSystemDefaultDevice()
        renderer = (device != nil) ? Renderer.metal : Renderer.opengl
    }
    
    /**
     ## Overview
     
     Structure representing the framework version (semantic version).
     
     ### Properties
     
     | Property              | Description                  |
     |:----------------------|:-----------------------------|
     | major                 | Framework major version.     |
     | minor                 | Framework minor version.     |
     | patch                 | Framework patch version      |
     | build                 | Framework build versions.    |
     | suffix                | Version suffix.              |
     
     */
    public struct Version {
        var major: Int = 0
        var minor: Int = 0
        var patch: Int = 0
        var build: Int = 0
        var suffix: String?
        
        /**
         Constructor from major, minor, patch & build values.
         
         - parameter major: major version.
         - parameter minor: minor version.
         - parameter patch: patch version.
         - parameter build: build version.
         - parameter suffix: optional suffix.
         */
        init(major: Int, minor: Int, patch: Int = 0, build: Int = 0, suffix: String? = nil) {
            self.major = major
            self.minor = minor
            self.patch = patch
            self.build = build
            self.suffix = suffix
        }
    }
    
    
    /**
     ## Overview
     
     Represents object's render quality when dealing with higher resolutions.
     
     ### Properties
     
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
     ## Overview
     
     Global debug display properties.
     
     */
    public struct DebugDisplayOptions {
        
        /// Debug properties for mouse movements.
        public var mouseFilters: MouseFilters = MouseFilters.tileCoordinates
        
        /// Debug display properties.
        public var highlightDuration: TimeInterval = 0.3
        
        /// Debug grid drawing opacity.
        public var gridOpactity: CGFloat = 0.4
        
        /// Debug grid drawing color.
        public var gridColor: SKColor = TiledObjectColors.grass
        
        /// Debug frame drawing color.
        public var frameColor: SKColor = TiledObjectColors.grass
        
        /// Debug tile highlight color.
        public var tileHighlightColor: SKColor = TiledObjectColors.lime
        
        /// Debug object fill opacity.
        public var objectFillOpacity: CGFloat = 0.25
        
        /// Debug object highlight color.
        public var objectHighlightColor: SKColor = TiledObjectColors.coral
        
        /// Debug graph highlight color.
        public var navigationColor: SKColor = TiledObjectColors.azure
        
        /**
         ## Overview
         
         Global debug display mouse filter options (macOS).
         
         ### Properties
         
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
     ## Overview
     
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
     ## Overview
     
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

/// :nodoc:
extension TiledGlobals: CustomDebugReflectable {
    
    func dumpStatistics() {
        print("\n----------- SKTiled Globals -----------")
        #if SKTILED_DEMO
        print("  - indentifier:          \(self.identifier)")
        #endif
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
     Initialize with a version string (ie "2.1.4").
     
     - parameter string: `String` version string.
     */
    init(string: String) {
        let digitSet = CharacterSet(charactersIn: "0123456789.")
        let alphaString = String(string.unicodeScalars.filter { digitSet.contains($0) })
        let parts = alphaString.split(separator: ".").compactMap { Int($0) }
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
            case 4:
                self.major = parts.first!
                self.minor = parts[1]
                self.patch = parts[2]
                self.build = parts[3]
            default:
                self.major = 1
                self.minor = 0
                self.patch = 0
                self.build = 0
        }
    }
    
    /**
     Initialize with a integer version string (ie: "2010401").
     
     - parameter integer: `String` build string.
     */
    public init(integer value: String) {
        guard (value.count >= 7),
              let intValue = Int(value) else {
            print("Error: invalid string '\(value)'")
            return
        }
        
        major = intValue / 1000000
        let r1 = intValue - (1000000 * major)
        minor = r1 / 10000
        let r2 = r1 - (10000 * minor)
        patch = r2 / 100
        build = r2 - (100 * patch)
    }
    
    /// Return the version expressed as an integer.
    public var integerValue: Int32  {
        var result = major * 1000000
        result += minor * 10000
        result += patch * 100
        result += build
        return Int32(result)
    }
    
    public var versionString: String {
        return "SKTiled version \(description) (\(integerValue))"
    }
}


extension TiledGlobals.Version: CustomStringConvertible, CustomDebugStringConvertible {
    
    /// String description of the framework version.
    public var description: String {
        let suffixString = suffix ?? ""
        return "\(major).\(minor)\(patch > 0 ? ".\(patch)" : "")\(build > 0 ? ".\(build)" : "")\(suffixString)"
    }
    /// String description of the framework version.
    public var debugDescription: String {
        return self.description
    }
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
