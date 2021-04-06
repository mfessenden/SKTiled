//
//  TiledGlobals.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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


// MARK: - Globals


/// :nodoc: The maximum allowable texture size (in pixels) that SpriteKit will allow.
public let SKTILED_MAX_TILEMAP_PIXEL_SIZE: Int = 4194304

#if DEBUG
/// :nodoc: Global default logging level.
public let SKTILED_DEFAULT_LOGGING_LEVEL: LoggingLevel = LoggingLevel.debug
#else

/// :nodoc: Global default logging level.
public let SKTILED_DEFAULT_LOGGING_LEVEL: LoggingLevel = LoggingLevel.info
#endif


#if SKTILED_DEMO
let SKTILED_DEMO_MODE = true
let DEFAULT_MAP_DEBUG_DRAW_OPTIONS: DebugDrawOptions = DebugDrawOptions.default
#else
let SKTILED_DEMO_MODE = false
let DEFAULT_MAP_DEBUG_DRAW_OPTIONS: DebugDrawOptions = []
#endif


#if SKTILED_BETA
let SKTILED_BETA_MODE = true
#else
let SKTILED_BETA_MODE = false
#endif


#if DEVELOPMENT_MODE
let SKTILED_DEVELOPMENT_MODE = true
#else
let SKTILED_DEVELOPMENT_MODE = false
#endif


/// :nodoc: Allow mouse events (macOS).
public let ENABLE_MOUSE_EVENTS: Bool = false



// MARK: - Aliases

/// :nodoc: Tile size of 0,0.
public let TileSizeZero  = CGSize(value: 0)

/// :nodoc: Tile size of 8,8.
public let TileSize8x8   = CGSize(value: 8)

/// :nodoc: Tile size of 16,16.
public let TileSize16x16 = CGSize(value: 16)

/// :nodoc: Tile size of 32,32.
public let TileSize32x32 = CGSize(value: 32)


/// The `TiledGlobals` object provides information about the framework, as well as allowing
/// you to set default attributes for various objects.
///
/// ### Properties
///
///  - `renderer`:               returns the current SpriteKit renderer (get-only).
///  - `loggingLevel`:           global logging verbosity.
///  - `updateMode`:             default tile update mode.
///  - `enableRenderCallbacks`:  enable callbacks from the tilemap on rendering statistics.
///  - `enableCameraCallbacks`:  enable callbacks from camera to camera delegates.
///  - `renderQuality`:          global render quality values.
///  - `contentScale`:           returns the device retina display scale factor.
///  - `version`:                returns the current framework version.
///
/// ### Usage
///
/// **SKTiled** framework default values are set in the `TiledGlobals` object.
///
/// ```swift
/// // access the default singleton instance
/// let tiledGlobals = TiledGlobals.default
///
/// // disable camera callbacks
/// tiledGlobals.enableCameraCallbacks = false
///
/// // set debugging mouse filters (macOS)
/// tiledGlobals.debugDisplayOptions.mouseFilters = [.tileCoordinates, .tilesUnderCursor]
///
/// // increase the default text object render quality
/// tiledGlobals.renderQuality.text = 12.0
/// ```
public class TiledGlobals {

    /// Default `TiledGlobals` singleton.
    public static var `default`: TiledGlobals {
        return defaultGlobalsInstance
    }

    // MARK: - Framework Globals

    /// Current SpriteKit renderer.
    public let renderer: Renderer

    /// Speed modifier applied to all actions executed by the scene and its descendants.
    public internal(set) var speed: CGFloat = 1.0 {
        willSet {
            guard (newValue != speed) else { return }

        }
    }

    /// Returns the resource URL.
    public var resourceUrl: URL? {
        for fext in ["tmx", "png", "tsx", "json"] {
            if let resurl = Bundle.main.url(forResource: nil, withExtension: fext) {
                return resurl.deletingLastPathComponent()
            }
        }
        return Bundle.main.resourceURL
    }

    /// Indicates the current framework is a beta release.
    public var isBeta: Bool {
        return SKTILED_BETA_MODE
    }

    /// Indicates the current environment is a playground.
    public var isPlayground: Bool {
        return ProcessInfo.processInfo.environment["PLAYGROUND_COMMUNICATION_SOCKET"] != nil
    }

    /// Framework domain.
    public var domain: String {
        return "org.sktiled"
    }

    /// Indicates the current application is the demo.
    public var isDemo: Bool {
        return SKTILED_DEMO_MODE
    }

    /// Indicates extra development features should be enabled.
    public var isDevelopment: Bool {
        return SKTILED_DEVELOPMENT_MODE
    }

    /// Default logging verbosity.
    public var loggingLevel:  LoggingLevel = SKTILED_DEFAULT_LOGGING_LEVEL

    /// Default debug draw options for all node types.
    ///
    /// ### Usage
    ///
    /// - `drawGrid`: visualize the nodes's tile grid.
    /// - `drawFrame`: visualize the nodes's bounding rect.
    /// - `drawGraph`: visualize the nodes's pathfinding graph.
    /// - `drawObjectFrames`: draw object's bounding shapes.
    /// - `drawAnchor`: draw the layer's anchor point.
    ///
    public var debugDrawOptions: DebugDrawOptions = DEFAULT_MAP_DEBUG_DRAW_OPTIONS

    /// Default tile update mode.
    public var updateMode: TileUpdateMode = TileUpdateMode.actions

    /// Default layer z-position offset.
    public var zDeltaForLayers: CGFloat = 50

    /// User interface color.
    public var uiColor: SKColor = SKColor(hexString: "#757b8d")
    
    // TODO: this is unused
    
    /// Default debugging objects lower range.
    public var lowerBoundForDebugging: CGFloat = 2500

    /// Enable callbacks for render performance statistics.
    public var enableRenderPerformanceCallbacks: Bool = false

    /// Enable callbacks from the tilemap to subscribers.
    public var enableTilemapNotifications: Bool = false
    
    /// Enable infinite offset use.
    public var enableTilemapInfiniteOffsets: Bool = false {
        didSet {
            #if DEVELOPMENT_MODE
            NotificationCenter.default.post(
                name: Notification.Name.Debug.RepositionLayers,
                object: nil
            )
            #endif
        }
    }
    
    /// Infinite map offset value.
    internal var infiniteOffset: CGPoint = CGPoint.zero {
        didSet {
            #if DEVELOPMENT_MODE
            NotificationCenter.default.post(
                name: Notification.Name.Debug.RepositionLayers,
                object: nil
            )
            #endif
        }
    }
    
    /// Enable callbacks from camera to camera delegates.
    public var enableCameraCallbacks: Bool = false

    /// Allows the camera to update delegate when the contained nodes array changes. Disable this to improve render performance.
    public var enableCameraContainedNodesCallbacks: Bool = false
    
    /// Default tile/object render quality attributes.
    public var renderQuality: RenderQuality = RenderQuality()

    /// Debugging visualzation options.
    ///
    /// The `DebugDisplayOptions` structure has attributes for attributes such as node highlight color, highlight duration as well as what kind of objects respond to mouse actions **(macOS only)**.
    public var debugDisplayOptions: DebugDisplayOptions = DebugDisplayOptions()

    /// Render statistics display.
    public var timeDisplayMode: TimeDisplayMode = TimeDisplayMode.milliseconds
    
    /// Mouse event limiter.
    public var mouseEventDelta: TimeInterval = 0.01

    /// Layer tinting options.
    public var layerTintAttributes: LayerTintOptions = LayerTintOptions()

    /// Returns the current device screen resolution.
    public var screenSize: CGSize {
        return getScreenSize()
    }

    /// Returns a `CGRect` representing the screen (window) size.
    public var screenRect: CGRect {
        let ss = screenSize
        let center = CGPoint(x: ss.halfWidth, y: ss.halfHeight)
        return CGRect(center: center, size: ss)
    }

    /// Returns the current device backing scale.
    public var contentScale: CGFloat {
        return getContentScaleFactor()
    }

    /// Returns the current device OS.
    public var os: String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #else
        return "unknown"
        #endif
    }

    /// Returns the name of the host application. ('SKTiled')
    public lazy var executableName: String = {
        var appName = "Unknown"
        if let execName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String {
            appName = execName
        }
        return appName
    }()

    /// Returns current bundle identifier name. ('org.sktiled.SKTiledDemo')
    public lazy var identifier: String = {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let bundleIdentifier = infoDictionary[kCFBundleIdentifierKey as String] as? String  else {
            return "unknown"
        }
        return bundleIdentifier
    }()

    /// Returns current bundle name.  ('SKTiled')
    public lazy var bundleName: String = {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let bundleName = infoDictionary[kCFBundleNameKey as String] as? String  else {
            return "unknown"
        }
        return bundleName
    }()

    /// Returns a string for use with the main window's title.
    public lazy var windowTitle: String = {
        var appName = executableName
        let wintitle = (isDemo == true) ? "DEMO: \(appName)" : appName
        return wintitle
    }()

    /// Returns current framework version.
    public lazy var version: Version = {
        // returns a string from the project, ie: `1300000`
        let verString = getSKTiledBuildVersion() ?? getSKTiledVersion()
        var result = Version(integer: verString)
        result.suffix = getSKTiledVersionSuffix()
        return result
    }()

    /// Returns current framework build (if any).
    public var build: String? {
        return getSKTiledBuildVersion()
    }
    
    // MARK: - Framework Directories
    
    /// Returns a prefernces path directory in the current user's home directory (macOS only).
    ///
    /// - Returns: url of created directory.
    public var exportDirectory: URL? {
        #if os(macOS)
        let userHome = FileManager.default.homeDirectoryForCurrentUser
        let sktiledExportDirectory = userHome.appendingPathComponent(".config/SKTiled")
        Logger.default.log("creating directory at '\(sktiledExportDirectory.path)'", level: .info, symbol: "TiledGlobals")
        if !FileManager.default.fileExists(atPath: sktiledExportDirectory.path) {
            do {
                try FileManager.default.createDirectory(atPath: sktiledExportDirectory.path, withIntermediateDirectories: true, attributes: nil)
                Logger.default.log("creating directory at '\(sktiledExportDirectory.path)'", level: .info, symbol: "TiledGlobals")
                return sktiledExportDirectory
            } catch {
                Logger.default.log(error.localizedDescription, level: .error, symbol: "TiledGlobals")
                return nil
            }
        } else {
            return sktiledExportDirectory
        }
        #else
        return nil
        #endif
    }

    // MARK: - Demo Properties

    /// Enable the demo app to load demo content.
    public var allowDemoMaps: Bool = true

    /// Enable the demo app to load user content.
    public var allowUserMaps: Bool = true

    /// Enable mouse events (macOS).
    public var enableMouseEvents: Bool = true

    /// Image types readable by `Tiled`.
    public var validImageTypes: [String] = ["bmp", "cur", "gif", "heic", "heif", "icns", "ico", "jp2", "jpeg", "jpg", "pbm", "pgm", "png", "ppm", "tga", "tif", "tiff", "wbmp", "webp", "xbm", "xpm"]

    /// File types readable by `Tiled`.
    public var validFileTypes: [String] = ["tmx", "tsx", "tx", "json"]


    /// Default initializer.
    internal init() {
        let device = MTLCreateSystemDefaultDevice()
        self.renderer = (device != nil) ? Renderer.metal : Renderer.opengl

        #if RENDER_STATS
        enableRenderPerformanceCallbacks = true
        #endif

        #if SKTILED_DEMO
        enableCameraContainedNodesCallbacks = true

        NotificationCenter.default.post(
            name: Notification.Name.Globals.Updated,
            object: nil
        )
        #endif
    }

    /// The `Version` structure represents the framework version (semantic version).
    ///
    /// ### Properties
    ///
    /// - `major`: Framework major version.
    /// - `minor`: Framework minor version.
    /// - `patch`: Framework patch version.
    /// - `build`: Framework build versions.
    /// - `suffix`: Version suffix.
    ///
    public struct Version {
        var major: Int = 0
        var minor: Int = 0
        var patch: Int = 0
        var build: Int = 0
        var suffix: String?

        /// Constructor from major, minor, patch & build values.
        ///
        /// - Parameters:
        ///   - major:  major version.
        ///   - minor:  minor version.
        ///   - patch:  patch version.
        ///   - build:  build version.
        ///   - suffix: optional suffix.
        init(major: Int, minor: Int, patch: Int = 0, build: Int = 0, suffix: String? = nil) {
            self.major = major
            self.minor = minor
            self.patch = patch
            self.build = build
            self.suffix = suffix
        }
    }

    /// The `RenderQuality` structure represents the render scaling factor used when dealing with higher resolutions & retina screen scale factors.
    ///
    /// #### Properties
    ///
    /// - `default`: global render quality.
    /// - `object`: object render quality.
    /// - `text`: text object render quality
    /// - `override`: override value.
    ///
    public struct RenderQuality {

        /// Global render quality.
        public var `default`: CGFloat = 3

        /// Vector object render quality.
        public var object: CGFloat = 4

        /// Text object render quality.
        public var text: CGFloat = 4

        /// Value that overrides others.
        public var `override`: CGFloat = 0
    }

    /// The `DebugDisplayOptions` structure represents global debugging visualization attributes.
    ///
    /// ### Properties
    ///
    /// - `mouseFilters`: mouse interaction options.
    /// - `mousePointerSize`: mouse pointer font size.
    /// - `highlightDuration`: global highlight duration for selectable objects.
    ///
    public struct DebugDisplayOptions {

        /// Debug properties for mouse movements.
        public var mouseFilters: MouseFilters = [.tileCoordinates]

        /// Mouse pointer size (demo).
        public var mousePointerSize: CGFloat = 10

        /// Default highlight duration for nodes.
        public var highlightDuration: TimeInterval = 1.5

        /// Debug grid visualization opacity.
        public var gridOpactity: CGFloat = 0.6
        
        /// Tile color blend opacity.
        public var tileHighlighBlendFactor: CGFloat = 0.6

        /// Debug grid visualization color.
        public var gridColor: SKColor = TiledObjectColors.grass

        /// Debug frame visualization color.
        public var frameColor: SKColor = TiledObjectColors.grass

        /// Debug frame line width.
        public var lineWidth: CGFloat = 4

        /// Debug tile highlight color.
        public var tileHighlightColor: SKColor = TiledObjectColors.coral
        
        /// Debug vector object highlight color.
        public var objectHighlightColor: SKColor = TiledObjectColors.lime

        /// Debug highlight color for mappable types.
        public var layerHighlightColor: SKColor = TiledObjectColors.turquoise
        
        /// Debug graph highlight color.
        public var navigationColor: SKColor = TiledObjectColors.azure

        /// Debug camera bounds color.
        public var cameraBoundsColor: SKColor = TiledObjectColors.metal

        /// Debug object fill opacity.
        public var objectFillOpacity: CGFloat = 0.5
        
        /// Default anchor display radius.
        public var anchorRadius: CGFloat = 1

        /// Global debug display mouse filter options (macOS).
        ///
        /// #### Properties
        ///
        /// - `tileCoordinates`: show tile coordinates.
        /// - `sceneCoordinates`: show scene coordinates.
        /// - `tileDataUnderCursor`: show tile data properties.
        ///
        public struct MouseFilters: OptionSet {
            public let rawValue: UInt8

            public static let tileCoordinates      = MouseFilters(rawValue: 1 << 0)
            public static let scenePosition        = MouseFilters(rawValue: 1 << 1)
            public static let tileDataUnderCursor  = MouseFilters(rawValue: 1 << 2)
            public static let mapPosition          = MouseFilters(rawValue: 1 << 3)
            public static let windowPosition       = MouseFilters(rawValue: 1 << 4)

            public static let all: MouseFilters = [.tileCoordinates, .scenePosition, .tileDataUnderCursor, .mapPosition, .windowPosition]

            public init(rawValue: UInt8 = 0) {
                self.rawValue = rawValue
            }
        }
    }

    public struct LayerTintOptions {

        /// Default tint belnding mode mode.
        public var blendMode: SKBlendMode = SKBlendMode.alpha
    }

    /// Display flag for render statistics.
    ///
    /// ### Properties
    ///
    /// - `milliseconds`: show render time in milliseconds.
    /// - `seconds`: show render time in seconds.
    ///
    public enum TimeDisplayMode: Int, CaseIterable {
        case milliseconds
        case seconds
    }

    /// Indicates the current renderer (OpenGL or Metal).
    ///
    /// ### Properties
    ///
    /// - `opengl`: indicates the current SpriteKit renderer is OpenGL.
    /// - `metal`: indicates the current SpriteKit renderer is Metal.
    ///
    public enum Renderer {
        case opengl
        case metal
    }
}


/// Singleton instance.
let defaultGlobalsInstance = TiledGlobals()


/// :nodoc:
public struct TiledObjectColors {
    public static let azure: SKColor       = SKColor(hexString: "#4A90E2")
    public static let coral: SKColor       = SKColor(hexString: "#FD4444")
    public static let crimson: SKColor     = SKColor(hexString: "#D0021B")
    public static let dandelion: SKColor   = SKColor(hexString: "#F8E71C")
    public static let english: SKColor     = SKColor(hexString: "#AF3E4D")
    public static let grass: SKColor       = SKColor(hexString: "#B8E986")
    public static let gun: SKColor         = SKColor(hexString: "#8D99AE")
    public static let indigo: SKColor      = SKColor(hexString: "#274060")
    public static let lime: SKColor        = SKColor(hexString: "#7ED321")
    public static let magenta: SKColor     = SKColor(hexString: "#FF00FF")
    public static let metal: SKColor       = SKColor(hexString: "#627C85")
    public static let obsidian: SKColor    = SKColor(hexString: "#464B4E")
    public static let pear: SKColor        = SKColor(hexString: "#CEE82C")
    public static let saffron: SKColor     = SKColor(hexString: "#F28123")
    public static let tangerine: SKColor   = SKColor(hexString: "#F5A623")
    public static let turquoise: SKColor   = SKColor(hexString: "#44CFCB")
}


// MARK: - Extensions



/// :nodoc:
extension TiledGlobals: CustomReflectable, CustomStringConvertible, CustomDebugStringConvertible {

    /// Returns a custom mirror for this object.
    public var customMirror: Mirror {

        let buildConfig = (getBuildConfiguration() == true) ? "release" : "debug"

        var attributes: [(label: String?, value: Any)] = [
            (label: "framework version", value: self.version.description),
            (label: "build configuration", buildConfig),
            (label: "operating system", value: self.os),
            (label: "Swift version", value: getSwiftVersion())
        ]


        if (isDemo == true) {
            attributes.insert(("bundle name", self.bundleName), at: 0)
            attributes.insert(("bundle indentifier", self.identifier), at: 0)
            attributes.insert(("product name", self.executableName), at: 0)
        }

        return Mirror(self, children: attributes, displayStyle: .class)
    }

    /// A textual representation of the object.
    public var description: String {
        return #"SKTiled Globals v\#(self.version.description)"#
    }

    /// A textual representation of the object, used for debugging.
    public var debugDescription: String {
        return #"<\#(description)>"#
    }
}



/// :nodoc:
extension TiledGlobals: TiledCustomReflectableType {

    /// Outputs global values to the console.
    public func dumpStatistics() {
        let headerString = " SKTiled Globals ".padEven(toLength: 40, withPad: "-")
        print("\n\(headerString)\n")

        #if SKTILED_DEMO
        print("  ▸ product name:            '\(self.executableName)'")
        print("  ▸ bundle indentifier:      '\(self.identifier)'")
        print("  ▸ bundle name:             '\(self.bundleName)'")
        #endif

        print("  ▸ framework version:       \(self.version.description)")

        let buildConfig = (getBuildConfiguration() == true) ? "release" : "debug"
        print("  ▸ build configuration:     \(buildConfig)")

        if let buildVersion = self.build {
            print("  ▸ build version:           \(buildVersion)")
        }
        print("  ▸ OS:                      \(self.os)")
        print("  ▸ Swift version:           \(getSwiftVersion())")
        print("  ▸ demo:                    \(isDemo)")
        print("  ▸ development mode:        \(isDevelopment)")
        print("  ▸ beta:                    \(isBeta)")
        print("  ▸ playground:              \(isPlayground)")
        print("  ▸ speed:                   \(self.speed.stringRoundedTo(1))")
        print("  ▸ renderer:                \(self.renderer.name)\n")
        
        
        print("  ▾ Screen:")
        print("     ▸ screen size:             \(self.screenSize.shortDescription)")
        print("     ▸ retina scale factor:     \(self.contentScale)")
        print("     ▸ screen rect:             \(self.screenRect.shortDescription)\n")


        print("  ▸ logging level:           \(self.loggingLevel)")
        print("  ▸ update mode:             \(self.updateMode.name)")
        print("  ▸ layer z-delta:           \(self.zDeltaForLayers.stringRoundedTo())")
        print("  ▸ ui color:                \(self.uiColor.hexString())")
        print("  ▸ debug draw options:      \(self.debugDrawOptions.debugDescription)")
        print("  ▸ render callbacks:        \(self.enableRenderPerformanceCallbacks)")
        print("  ▸ mouse event frequency:   \(self.mouseEventDelta.stringRoundedTo(4))")
        print("  ▸ tilemap notifications:   \(self.enableTilemapNotifications)")
        print("  ▸ infinite offsets:        \(self.enableTilemapInfiniteOffsets)")
        print("  ▸ camera callbacks:        \(self.enableCameraCallbacks)")
        print("  ▸ visble nodes callbacks:  \(self.enableCameraContainedNodesCallbacks)")
        #if os(macOS)
        print("  ▸ enable mouse events:     \(self.enableMouseEvents)\n")
        #endif
        print("  ▾ Demo Assets:")
        print("     ▸ allow demo assets:    \(self.allowDemoMaps)")
        print("     ▸ allow user assets:    \(self.allowUserMaps)\n")
        
        print("  ▾ Debug Display: ")
        print("     ▸ highlight duration:   \(self.debugDisplayOptions.highlightDuration)")
        print("     ▸ grid opacity:         \(self.debugDisplayOptions.gridOpactity)")
        print("     ▸ tile color blend:     \(self.debugDisplayOptions.tileHighlighBlendFactor.stringRoundedTo())")
        print("     ▸ object fill opacity:  \(self.debugDisplayOptions.objectFillOpacity)")
        print("     ▸ object line width:    \(self.debugDisplayOptions.lineWidth)")
        print("     ▸ grid color:           \(self.debugDisplayOptions.gridColor.hexString())")
        print("     ▸ anchor radius:        \(self.debugDisplayOptions.anchorRadius)\n")
        
        print("  ▾ Render Quality: ")
        print("     ▸ default:              \(self.renderQuality.default)")
        print("     ▸ object:               \(self.renderQuality.object)")
        print("     ▸ text:                 \(self.renderQuality.text)")
        print(self.renderQuality.override > 0 ? "     ⁃ override:             \(self.renderQuality.override)\n" : "")
        
        #if os(macOS)
        print("  ▾ Debug Mouse Filters:")
        print("     ▸ tile coordinates:     \(self.debugDisplayOptions.mouseFilters.contains(.tileCoordinates))")
        print("     ▸ scene coordinates:    \(self.debugDisplayOptions.mouseFilters.contains(.scenePosition))")
        print("     ▸ map coordinates:      \(self.debugDisplayOptions.mouseFilters.contains(.mapPosition))")
        print("     ▸ tile data:            \(self.debugDisplayOptions.mouseFilters.contains(.tileDataUnderCursor))")
        print("     ▸ mouse pointer:        \(self.debugDisplayOptions.mouseFilters.enableMousePointer)\n")
        #endif
        print("\n---------------------------------------\n")
    }
}



extension TiledGlobals.Version {

    /// Initialize with a version string (ie "2.1.4").
    ///
    /// - Parameter value: version string value.
    public init(string: String) {
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

    /// Initialize with a integer version string (ie: "2010401")
    ///
    /// - Parameter build: build string.
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
}


/// :nodoc:
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

    /// Returns the name of the current SpriteKit renderer.
    public var name: String {
        switch self {
            case .opengl: return "OpenGL"
            case .metal: return "Metal"
        }
    }
}


/// :nodoc:
extension TiledGlobals.DebugDisplayOptions.MouseFilters {

    /// Indicates tile coordinate data should be displayed.
    public var isShowingTileCoordinates: Bool {
        return contains(.tileCoordinates)
    }

    /// Indicates scene coordinate data should be displayed.
    public var isShowingScenePosition: Bool {
        return contains(.scenePosition)
    }

    /// Indicates tile data attributes should be displayed.
    public var isShowingTileData: Bool {
        return contains(.tileDataUnderCursor)
    }

    /// Indicates map position data should be displayed.
    public var isShowingMapPosition: Bool {
        return contains(.mapPosition)
    }

    /// Indicates window position data should be displayed.
    public var isShowingWindowPosition: Bool {
        return contains(.windowPosition)
    }

    public var strings: [String] {
        var result: [String] = []
        if self.contains(.tileCoordinates) {
            result.append("Tile Coordinates")
        }

        if self.contains(.scenePosition) {
            result.append("Scene Position")
        }

        if self.contains(.tileDataUnderCursor) {
            result.append("Tile Data")
        }

        if self.contains(.mapPosition) {
            result.append("Map Position")
        }

        if self.contains(.windowPosition) {
            result.append("Window Position")
        }

        return result
    }

    /// Indicates the current scene should enable a `MousePointer` inspection node.
    public var enableMousePointer: Bool {
        #if os(macOS)
        return self.contains(.tileCoordinates) || self.contains(.scenePosition) || self.contains(.tileDataUnderCursor)
        #else
        return false
        #endif
    }
}


/// :nodoc:
extension TiledObjectColors {

    /// Returns an array of all colors.
    public static let all: [SKColor] = [azure, coral, crimson, dandelion,
                                 english, grass, gun, indigo, lime,
                                 magenta, metal, obsidian, pear,
                                 saffron, tangerine, turquoise]

    /// Returns an array of all color names.
    public static let names: [String] = ["azure", "coral", "crimson","dandelion",
                                  "english","grass","gun","indigo","lime",
                                  "magenta","metal","obsidian","pear",
                                  "saffron","tangerine","turquoise"]
    /// Returns a random color.
    public static var random: SKColor {
        let randIndex = Int(arc4random_uniform(UInt32(TiledObjectColors.all.count)))
        return TiledObjectColors.all[randIndex]
    }
}



// MARK: - Deprecations

extension TiledGlobals {

    /// Debugging display options.
    @available(*, deprecated, renamed: "debugDisplayOptions")
    public var debug: DebugDisplayOptions {
        get {
            return debugDisplayOptions
        } set {
            debugDisplayOptions = newValue
        }
    }

    /// Enable callbacks for render performance statistics.
    @available(*, deprecated, renamed: "enableRenderPerformanceCallbacks")
    public var enableRenderCallbacks: Bool {
        get {
            return enableRenderPerformanceCallbacks
        } set {
            enableRenderPerformanceCallbacks = newValue
        }
    }
}
