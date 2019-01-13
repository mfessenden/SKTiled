//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
import GameplayKit


/// Object rendering order.
internal enum RenderOrder: String {
    case rightDown  = "right-down"
    case rightUp    = "right-up"
    case leftDown   = "left-down"
    case leftUp     = "left-up"
}


/// Tilemap data encoding.
internal enum TilemapEncoding: String {
    case base64
    case csv
    case xml
}


/**
 Alignment hint used to position the layers within the `SKTilemap` node.

 - `bottomLeft`:   node bottom left rests at parent zeropoint (0)
 - `center`:       node center rests at parent zeropoint (0.5)
 - `topRight`:     node top right rests at parent zeropoint. (1)
 */
internal enum LayerPosition {
    case bottomLeft
    case center
    case topRight
}


/**
 Hexagonal stagger axis.

 - `x`: axis is along the x-coordinate.
 - `y`: axis is along the y-coordinate.
 */
internal enum StaggerAxis: String {
    case x
    case y
}


/**
 Hexagonal stagger index.

 - `even`: stagger evens.
 - `odd`:  stagger odds.
 */
internal enum StaggerIndex: UInt8 {
    case odd
    case even
}


/**
 ## Overview ##

 Describes how the tilemap updates its tiles in your scene. Changing this property will affect your CPU usage, so use it carefully.


 The default mode is `TileUpdateMode.dynamic`, which updates tiles as needed each frame. For best performance, use `TileUpdateMode.actions`, which will
 run SpriteKit actions on animated tiles.

 ### Usage ###

 ```swift
 // passing the tile update mode to the load function
 let tilemap = SKTilemap.load(tmxFile: String, updateMode: TileUpdateMode.dynamic)!

 // updating the attribute on the tilemp node
 tilemap.updateMode = TileUpdateMode.actions
 ```

 ### Properties ###

 | Property              | Description                                                      |
 |:----------------------|:-----------------------------------------------------------------|
 | dynamic               | Dynamically update tiles as needed.                              |
 | full                  | All tiles are updated each frame.                                |
 | actions               | Tiles are not updated, SpriteKit actions are used instead.       |

 */
public enum TileUpdateMode: Int {
    case dynamic                    // dynamically update tiles as needed
    case full                       // all tiles updated
    case actions                    // use SpriteKit actions (no update)
}



//  tile size aliases
public let TileSizeZero  = CGSize(width: 0, height: 0)
public let TileSize8x8   = CGSize(width: 8, height: 8)
public let TileSize16x16 = CGSize(width: 16, height: 16)
public let TileSize32x32 = CGSize(width: 32, height: 32)



/**
 ## Overview ##

 Methods that allow interaction with an `SKTilemap` object as it is being created to customize its properties.

 ### Properties ###

 | Property           | Description                        |
 |:-------------------|:-----------------------------------|
 | zDeltaForLayers    | Default z-distance between layers. |

 ### Instance Methods ###

 Delegate callbacks are called asynchronously as the map is being read from disk and rendered:

 | Method                | Description                                                      |
 |:----------------------|:-----------------------------------------------------------------|
 | didBeginParsing       | Called when the tilemap is instantiated.                         |
 | didAddTileset         | Called when a tileset is added to a map.                         |
 | didAddLayer           | Called when a layer is added to a tilemap.                       |
 | didReadMap            | Called when the tilemap is finished parsing.                     |
 | didRenderMap          | Called when the tilemap layers are finished rendering.           |
 | didAddNavigationGraph | Called when the a navigation graph is built for a layer.         |
 | objectForTileType     | Specify a custom tile object for use in tile layers.             |
 | objectForVectorType   | Specify a custom object for use in object groups.                |
 | objectForGraphType    | Specify a custom graph node object for use in navigation graphs. |

 ### Custom Objects ###

 Custom object methods can be used to substitute your own objects for tiles:

 ```swift
 func objectForTileType(named: String? = nil) -> SKTile.Type {
    if (named == "MyTile") {
        return MyTile.self
    }
    return SKTile.self
 }
 ```
*/
public protocol SKTilemapDelegate: class {
    var zDeltaForLayers: CGFloat { get }
    func didBeginParsing(_ tilemap: SKTilemap)
    func didAddTileset(_ tileset: SKTileset)
    func didAddLayer(_ layer: SKTiledLayerObject)
    func didReadMap(_ tilemap: SKTilemap)
    func didRenderMap(_ tilemap: SKTilemap)
    func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>)
    func objectForTileType(named: String?) -> SKTile.Type
    func objectForVectorType(named: String?) -> SKTileObject.Type
    func objectForGraphType(named: String?) -> GKGridGraphNode.Type
}


/**
 ## Overview ##

 The `SKTilemap` class is a container for managing layers of tiles (sprites),
 vector objects & images. Tile data is stored in `SKTileset` tile sets.

 ### Usage ###

 Maps can be loaded with the class function `SKTilemap.load(tmxFile:)`:

 ```swift
 if let tilemap = SKTilemap.load(tmxFile: "myfile.tmx") {
    scene.addChild(tilemap)
 }
 ```

 ### Properties ###

 | Property    | Description                                   |
 |:------------|:----------------------------------------------|
 | mapSize     | Size of the map (in tiles).                   |
 | tileSize    | Map tile size (in pixels).                    |
 | renderSize  | Size of the map in pixels.                    |
 | orientation | Map orientation (orthogonal, isometric, etc.) |
 | bounds      | Map bounding rect.                            |
 | tilesets    | Array of stored tileset instances.            |
 | allowZoom   | Allow camera zooming.                         |
 | layers      | Array of child layers.                        |

 */
public class SKTilemap: SKEffectNode, SKTiledObject {

    /**
     ## Overview

     Enum describing map orientation type.

     ### Constants ###

     | Property    | Description                                   |
     |:------------|:----------------------------------------------|
     | orthogonal  | Orthogonal(square tiles) tile map.            |
     | isometric   | Isometric tile map.                           |
     | hexagonal   | Hexagonal tile map.                           |
     | staggered   | Staggered isometric tile map.                 |

     */
    public enum TilemapOrientation: String {
        case orthogonal
        case isometric
        case hexagonal
        case staggered
    }


    // MARK: Properties

    /// Source file path.
    public var url: URL!

    /// Unique id.
    public var uuid: String = UUID().uuidString

    /// Tiled application version.
    public var tiledversion: String!                                  // the Tiled version of this tilemap

    /// Custom properties.
    public var properties: [String: String] = [:]

    /// Map type.
    public var type: String!

    /// Ignore custom properties.
    public var ignoreProperties: Bool = false

    /// Returns true if all of the child layers are rendered.
    public internal(set) var isRendered: Bool = false

    /// Returns the render time of this map.
    public internal(set) var mapRenderTime: TimeInterval = 0

    /// Size of map (in tiles).
    public var size: CGSize

    /// Tile size (in pixels).
    public var tileSize: CGSize

    /// Map orientation type.
    public var orientation: TilemapOrientation                        // map orientation
    internal var renderOrder: RenderOrder = RenderOrder.rightDown     // render order

    /// Map display name. Defaults to the current map source file name (minus the tmx extension).
    public var displayName: String?

    /// String representing the map name. Defaults to the current map source file name (minus the tmx extension).
    public var mapName: String {
        if let dname = self.displayName {
            return dname
        }
        return self.name ?? "map"
    }

    // MARK: Updating

    // Update time properties.
    private var lastUpdateTime: TimeInterval = 0
    private let maximumUpdateDelta: TimeInterval = 1.0 / 60.0

    // MARK: Dispatch Queues
    private let renderQueue  = DispatchQueue(label: "com.sktiled.sktilemap.renderqueue", qos: .userInteractive, attributes: .concurrent)
    private let animatedTilesQueue = DispatchQueue(label: "com.sktiled.sktilemap.tiles.animated.renderQueue", qos: .userInteractive, attributes: .concurrent)
    private let staticTilesQueue  = DispatchQueue(label: "com.sktiled.sktilemap.tiles.static.renderQueue", qos: .userInteractive, attributes: .concurrent)

    /// Logging verbosity.
    internal var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    // MARK: Tile Update Mode

    /// Update mode used for tiles & objects.
    public var updateMode: TileUpdateMode = TileUpdateMode.dynamic {
        didSet {
            guard (updateMode != oldValue) else { return }
            // if we are in `none` mode, add/remove spritekit actions
            let doRunActions = (updateMode == TileUpdateMode.actions) ? true : false
            self.runAnimationAsActions(doRunActions)
        }
    }

    // MARK: Render Quality

    /// Maximum render quality
    internal var maxRenderQuality: CGFloat = 16

    /// Scaling factor for text objects, etc.
    public var renderQuality: CGFloat = 2 {
        didSet {
            guard renderQuality != oldValue else { return }
            layers.forEach { $0.renderQuality = renderQuality.clamped(1, maxRenderQuality) }
        }
    }

    /// Map animation speed
    override public var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.layers.forEach { layer in
                layer.speed = speed
            }
        }
    }

    // hexagonal
    public var hexsidelength: Int = 0                                 // hexagonal side length
    internal var staggeraxis: StaggerAxis = StaggerAxis.y             // stagger axis
    internal var staggerindex: StaggerIndex = StaggerIndex.odd        // stagger index.

    // MARK: Camera

    /// Render statistics
    public struct CameraZoomConstraints {
        public var min: CGFloat = 0.2
        public var max: CGFloat = 5.0
    }

    public var zoomConstraints: CameraZoomConstraints = CameraZoomConstraints()

    /// Indicates map should auto-resize upon view changes.
    public internal(set) var autoResize: Bool = false

    /// Map bounds.
    public var bounds: CGRect = CGRect.zero

    /// Receive notifications from camera.
    public var receiveCameraUpdates: Bool = true

    /// Display bounds that the tilemap is viewable in.
    public var cameraBounds: CGRect?
    public var nodesInView: [SKNode] = []
    internal var objectsOverlay: TileObjectOverlay = TileObjectOverlay()

    /// Initial world scale
    public var worldScale: CGFloat = 1.0

    /// Map zoom level
    public var currentZoom: CGFloat = 1.0

    /// Allow camera zooming.
    public var allowZoom: Bool = true

    /// Allow camera movement.
    public var allowMovement: Bool = true

    // MARK: Tilesets

    /// Current tilesets.
    public var firstGID: Int = 0
    public var tilesets: Set<SKTileset> = []

    // current layers
    private var _layers: Set<SKTiledLayerObject> = []                 // tile map layers

    /// Layer count.
    public var layerCount: Int { return self.layers.count }

    /// Object count.
    public var objectCount: Int { return self.getObjects(recursive: true).count }

    /// Default z-position range between layers.
    public var zDeltaForLayers: CGFloat = 50


    // MARK: Caching

    /// Storage for tile updates
    internal var dataStorage: TileDataStorage?


    // MARK: Render Statistics/Debugging

    /// Render statistics
    public struct RenderStatistics {
        var updateMode: TileUpdateMode = TileUpdateMode.dynamic
        var objectCount: Int = 0                    // tile objects
        var visibleCount: Int = 0                   // visible tiles
        var cpuPercentage: Int = 0                  // CPU usage
        var effectsEnabled: Bool = false            // tilemap effects enabled
        var updatedThisFrame: Int = 0               // objects updated this frame
        var objectsVisible: Bool = false            // tilemap has objects visible
        var renderTime: TimeInterval = 0            // frame render time
    }

    /// Debugging/Render Statistics
    internal var renderStatistics: RenderStatistics = RenderStatistics()
    internal var renderStatisticsSampleFrequency: Int = 60
    internal var currentFrameIndex: Int = 0

    // MARK: Layers

    /// Returns a flattened array of child layers.
    public var layers: [SKTiledLayerObject] {
        var result: [SKTiledLayerObject] = []
        for layer in _layers.sorted(by: { $0.index > $1.index }) where layer as? BackgroundLayer == nil {
            result += layer.layers
        }
        return result
    }

    /// The tile map default layer, used for displaying the current grid, getting coordinates, etc.
    lazy var defaultLayer: BackgroundLayer = {
        let layer = BackgroundLayer(tilemap: self)
        _ = self.addLayer(layer)
        layer.didFinishRendering()
        return layer
    }()

    /// Pause overlay.
    lazy var overlay: SKSpriteNode = {
        let pauseOverlayColor = SKColor.clear // self.backgroundColor ?? SKColor.clear
        let overlayNode = SKSpriteNode(color: pauseOverlayColor, size: self.sizeInPoints)
        self.addChild(overlayNode)
        overlayNode.zPosition = self.lastZPosition * self.zDeltaForLayers
        return overlayNode
    }()

    // MARK: Background Properties

    /// Ignore Tiled background color.
    public var ignoreBackground: Bool = false {
        didSet {
            backgroundColor = (ignoreBackground == false) ? backgroundColor : nil
        }
    }

    /// Optional background color (read from the Tiled file)
    public var backgroundColor: SKColor? = nil {
        didSet {
            self.defaultLayer.color = (backgroundColor != nil) ? backgroundColor! : SKColor.clear
            self.defaultLayer.colorBlendFactor = (backgroundColor != nil) ? 1.0 : 0
        }
    }

    /// Debug visualization node
    internal var debugNode: SKTiledDebugDrawNode!


    /// Debug visualization options.
    public var debugDrawOptions: DebugDrawOptions = [] {
        didSet {
            debugNode?.draw()


            let proxiesVisible = debugDrawOptions.contains(.drawObjectBounds)
            let proxies = self.getObjectProxies()

            NotificationCenter.default.post(
                name: Notification.Name.DataStorage.ProxyVisibilityChanged,
                object: proxies,
                userInfo: ["visibility": proxiesVisible]
            )
        }
    }

    /// Overlay color.
    public var overlayColor: SKColor = SKColor(hexString: "#40000000")

    // MARK: Object Colors

    public var objectColor: SKColor = SKColor.gray
    public var color: SKColor = SKColor.clear                                             // used for pausing
    public var gridColor: SKColor = TiledGlobals.default.debug.gridColor                  // color used to visualize the tile grid
    public var frameColor: SKColor = TiledGlobals.default.debug.frameColor                // bounding box color
    public var highlightColor: SKColor = TiledGlobals.default.debug.tileHighlightColor    // color used to highlight tiles
    public var navigationColor: SKColor = TiledGlobals.default.debug.navigationColor      // navigation graph color.

    /// dynamics
    public var gravity: CGVector = CGVector.zero

    /// Reference to `SKTilemapDelegate` delegate.
    weak public var delegate: SKTilemapDelegate?

    /// Map frame.
    override public var frame: CGRect {
        //let cy = (heightOffset == 0) ? 0 : (heightOffset / 2)
        return CGRect(center: CGPoint(x: 0, y: 0), size: self.sizeInPoints)
    }

    /// Object vertices.
    public func getVertices() -> [CGPoint] {
        return frame.points
    }

    /// Size of the map in points.
    public var sizeInPoints: CGSize {
        switch orientation {
        case .orthogonal:
            return CGSize(width: size.width * tileSize.width, height: size.height * tileSize.height)

        case .isometric:
            let side = width + height
            return CGSize(width: side * tileWidthHalf,  height: side * tileHeightHalf)

        case .hexagonal, .staggered:
            var result = CGSize.zero
            if staggerX == true {
                result = CGSize(width: width * columnWidth + sideOffsetX,
                                height: height * (tileHeight + sideLengthY))

                if width > 1 { result.height += rowHeight }
            } else {
                result = CGSize(width: width * (tileWidth + sideLengthX),
                                height: height * rowHeight + sideOffsetY)

                if height > 1 { result.width += columnWidth }
            }
            return result
        }
    }


    // used to align the layers within the tile map
    internal var layerAlignment: LayerPosition = .center {
        didSet {
            layers.forEach { self.positionLayer($0) }
        }
    }

    /// Returns the last GID for all of the tilesets.
    public var lastGID: Int {
        return tilesets.isEmpty == false ? tilesets.map {$0.lastGID}.max()! : 0
    }

    /// Returns the last index for all tilesets.
    public var lastIndex: Int {
        return _layers.isEmpty == false ? _layers.map { $0.index }.max()! : 0
    }

    /// Returns the last (highest) z-position in the map.
    public var lastZPosition: CGFloat {
        return layers.isEmpty == false ? layers.map { $0.actualZPosition }.max()! : 0
    }

    /// Tile overlap amount. 1 is typically a good value.
    public var tileOverlap: CGFloat = 1.0 {
        didSet {
            guard oldValue != tileOverlap else { return }
            for tileLayer in tileLayers(recursive: true) {
                tileLayer.setTileOverlap(tileOverlap)
            }
        }
    }

    /// Global property to show/hide all `SKTileObject` objects.
    public var showObjects: Bool {
        get {
            return debugDrawOptions.contains(.drawObjectBounds)
        } set {

            if (newValue == true) {
                debugDrawOptions.insert(.drawObjectBounds)
            } else {
                debugDrawOptions = debugDrawOptions.subtracting(.drawObjectBounds)
            }

            let proxies = self.getObjectProxies()

            NotificationCenter.default.post(
                name: Notification.Name.DataStorage.ProxyVisibilityChanged,
                object: proxies,
                userInfo: ["visibility": newValue]
            )
        }
    }

    /**
     Show objects for the given layers.

     - parameter forLayers: `[SKTiledLayerObject]` array of layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    public func showObjects(forLayers: [SKTiledLayerObject]) {
        forLayers.forEach { layer in
            if let objGroup = layer as? SKObjectGroup {
                objGroup.showObjects = true
            }
        }
    }

    /**
     Return all tile layers. If recursive is false, only returns top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    public func tileLayers(recursive: Bool = true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKTileLayer != nil } as! [SKTileLayer]
    }

    /**
     Return all object groups. If recursive is false, only returns top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKObjectGroup]` array of object groups.
     */
    public func objectGroups(recursive: Bool = true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKObjectGroup != nil } as! [SKObjectGroup]
    }

    /**
     Return all image layers. If recursive is false, only returns top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKImageLayer]` array of image layers.
     */
    public func imageLayers(recursive: Bool = true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKImageLayer != nil } as! [SKImageLayer]
    }

    /**
     Return all group layers. If recursive is false, only returns top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKGroupLayer]` array of image layers.
     */
    public func groupLayers(recursive: Bool = true) -> [SKGroupLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKGroupLayer != nil } as! [SKGroupLayer]
    }


    /// Convenience property to return all group layers.
    public var groupLayers: [SKGroupLayer] {
        return layers.sorted(by: {$0.index < $1.index}).filter { $0 as? SKGroupLayer != nil } as! [SKGroupLayer]
    }

    /// Global antialiasing of lines
    public var antialiasLines: Bool = false {
        didSet {
            layers.forEach { $0.antialiased = antialiasLines }
        }
    }

    /// Global tile count
    public var tileCount: Int {
        return tileLayers(recursive: true).reduce(0) { (result: Int, layer: SKTileLayer) in
            return result + layer.tileCount
        }
    }

    /// Pauses the node, and colors all of its children darker.
    override public var isPaused: Bool {
        willSet (pauseValue) {
            overlay.isHidden = (pauseValue == false)
        }
    }

    // MARK: - Loading

    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:   `String` Tiled file name.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: nil, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode,
                              withTilesets: nil, ignoreProperties: false,
                              loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:     `String` Tiled file name.
     - parameter completion:  `((_ tilemap: SKTilemap) -> Void)?` optional completion block.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String, _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: nil, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode,
                              withTilesets: nil, ignoreProperties: false,
                              loggingLevel: TiledGlobals.default.loggingLevel, completion)
    }

    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:       `String` Tiled file name.
     - parameter loggingLevel:  `LoggingLevel` logging verbosity level.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String, loggingLevel: LoggingLevel) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: nil, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: loggingLevel, nil)
    }

    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:          `String` Tiled file name.
     - parameter delegate:         `SKTilemapDelegate` tilemap [delegate](Protocols/SKTilemapDelegate.html) instance.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String, delegate: SKTilemapDelegate) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:           `String` Tiled file name.
     - parameter delegate:          `SKTilemapDelegate` tilemap [delegate](Protocols/SKTilemapDelegate.html) instance.
     - parameter updateMode:        `TileUpdateMode` tile update mode.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String, delegate: SKTilemapDelegate, updateMode: TileUpdateMode) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: nil,
                              updateMode: updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:            `String` Tiled file name.
     - parameter delegate:           `SKTilemapDelegate` tilemap [delegate](Protocols/SKTilemapDelegate.html) instance.
     - parameter tilesetDataSource:  `SKTilesetDataSource` tilemap [`SKTilesetDataSource`](Protocols/SKTilesetDataSource.html) instance.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String, delegate: SKTilemapDelegate, tilesetDataSource: SKTilesetDataSource) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: tilesetDataSource,
                              updateMode: TiledGlobals.default.updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }


    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:            `String` Tiled file name.
     - parameter delegate:           `SKTilemapDelegate` tilemap [delegate](Protocols/SKTilemapDelegate.html) instance.
     - parameter tilesetDataSource:  `SKTilesetDataSource` tilemap [`SKTilesetDataSource`](Protocols/SKTilesetDataSource.html) instance.
     - parameter updateMode:         `TileUpdateMode` tile update mode.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String, delegate: SKTilemapDelegate, tilesetDataSource: SKTilesetDataSource, updateMode: TileUpdateMode) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: tilesetDataSource,
                              updateMode: updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:            `String` Tiled file name.
     - parameter delegate:           `SKTilemapDelegate` tilemap [delegate](Protocols/SKTilemapDelegate.html) instance.
     - parameter tilesetDataSource:  `SKTilesetDataSource` tilemap [`SKTilesetDataSource`](Protocols/SKTilesetDataSource.html) instance.
     - parameter withTilesets:       `[SKTileset]` pre-loaded tilesets.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String, delegate: SKTilemapDelegate, tilesetDataSource: SKTilesetDataSource, withTilesets: [SKTileset]) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: tilesetDataSource,
                              updateMode: TiledGlobals.default.updateMode, withTilesets: withTilesets,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /**
     Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter tmxFile:            `String` Tiled file name.
     - parameter inDirectory:        `String?` search path for assets.
     - parameter delegate:           `SKTilemapDelegate?` optional [`SKTilemapDelegate`](Protocols/SKTilemapDelegate.html) instance.
     - parameter tilesetDataSource:  `SKTilesetDataSource?` optional [`SKTilesetDataSource`](Protocols/SKTilesetDataSource.html) instance.
     - parameter updateMode:         `TileUpdateMode` tile update mode.
     - parameter withTilesets:       `[SKTileset]?` optional tilesets.
     - parameter ignoreProperties:   `Bool` ignore custom properties from Tiled.
     - parameter loggingLevel:       `LoggingLevel` logging verbosity level.
     - parameter completion:         `((_ tilemap: SKTilemap) -> Void)?` optional completion block.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String,
                           inDirectory: String? = nil,
                           delegate: SKTilemapDelegate? = nil,
                           tilesetDataSource: SKTilesetDataSource? = nil,
                           updateMode: TileUpdateMode = TiledGlobals.default.updateMode,
                           withTilesets: [SKTileset]? = nil,
                           ignoreProperties noparse: Bool = false,
                           loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                           _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) -> SKTilemap? {


        let startTime = Date()
        let queue = DispatchQueue(label: "com.sktiled.loadingQueue", qos: .userInteractive)
        if let tilemap = SKTilemapParser().load(tmxFile: tmxFile,
                                                inDirectory: inDirectory,
                                                delegate: delegate,
                                                tilesetDataSource: tilesetDataSource,
                                                updateMode: updateMode,
                                                withTilesets: withTilesets,
                                                ignoreProperties: noparse,
                                                loggingLevel: loggingLevel,
                                                renderQueue: queue) {


            // set the map render time attribute
            tilemap.mapRenderTime = Date().timeIntervalSince(startTime)
            let timeStamp = String(format: "%.\(String(3))f", tilemap.mapRenderTime)
            Logger.default.log("tilemap \"\(tilemap.mapName)\" rendered in: \(timeStamp)s", level: .success)

            // completion handler
            completion?(tilemap)
            return tilemap
        }
        return nil
    }

    // MARK: - Init

    /**
     Default initializer.
     */
    required public init?(coder aDecoder: NSCoder) {
        size = CGSize.zero
        tileSize = CGSize.zero
        orientation = .orthogonal
        super.init(coder: aDecoder)
        self.setupNotifications()
    }

    /**
     Initialize with dictionary attributes from xml parser.

     - parameter attributes: `Dictionary` attributes dictionary.
     - returns: `SKTilemap?`
     */
    public init?(attributes: [String: String]) {
        guard let width = attributes["width"] else { return nil }
        guard let height = attributes["height"] else { return nil }
        guard let tilewidth = attributes["tilewidth"] else { return nil }
        guard let tileheight = attributes["tileheight"] else { return nil }
        guard let orient = attributes["orientation"] else { return nil }

        // initialize tile size & map size
        tileSize = CGSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        size = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))

        // tile orientation
        guard let tileOrientation: TilemapOrientation = TilemapOrientation(rawValue: orient) else {
            fatalError("orientation \"\(orient)\" not supported.")
        }

        self.orientation = tileOrientation

        // render order
        if let rendorder = attributes["renderorder"] {
            guard let renderorder: RenderOrder = RenderOrder(rawValue: rendorder) else {
                fatalError("orientation \"\(rendorder)\" not supported.")
            }
            self.renderOrder = renderorder
        }

        // hex side
        if let hexside = attributes["hexsidelength"] {
            self.hexsidelength = Int(hexside)!
        }

        // hex stagger axis
        if let hexStagger = attributes["staggeraxis"] {
            guard let staggerAxis: StaggerAxis = StaggerAxis(rawValue: hexStagger) else {
                fatalError("stagger axis \"\(hexStagger)\" not supported.")
            }
            self.staggeraxis = staggerAxis
        }

        // hex stagger index
        if let hexIndex = attributes["staggerindex"] {
            guard let hexindex: StaggerIndex = StaggerIndex(string: hexIndex) else {
                fatalError("stagger index \"\(hexIndex)\" not supported.")
            }
            self.staggerindex = hexindex
        }

        // Tiled application version
        if let tiledVersion = attributes["tiledversion"] {
            self.tiledversion = tiledVersion
        }

        // global antialiasing
        antialiasLines = (currentZoom < 1)
        super.init()

        // turn off effects rendering by default
        shouldEnableEffects = false

        // set the background color
        if let backgroundHexColor = attributes["backgroundcolor"] {
            if (ignoreBackground == false) {
                backgroundColor = SKColor(hexString: backgroundHexColor)

                if let backgroundCGColor = backgroundColor?.withAlphaComponent(0.6) {
                    overlayColor = backgroundCGColor
                }
            }
        }

        // keep renderQuality within texture size limits
        let renderSize = CGSize(width: size.width * tileSize.width, height: size.height * tileSize.height)
        let largestPixelDimension: CGFloat = (renderSize.width > renderSize.height) ? renderSize.width : renderSize.height

        // calculate the ideal max render quality (max size is 16384)
        maxRenderQuality = CGFloat(Int(4000 / (largestPixelDimension * TiledGlobals.default.contentScale)))

        let remainder = maxRenderQuality.truncatingRemainder(dividingBy: 2)
        maxRenderQuality += remainder

        // cap maximum render quality
        maxRenderQuality = (TiledGlobals.default.renderQuality.override == 0) ? (maxRenderQuality > 16) ? 16 : maxRenderQuality : TiledGlobals.default.renderQuality.override

        #if os(iOS)
        renderQuality = maxRenderQuality / 4
        #else
        renderQuality = maxRenderQuality / 2
        #endif

        // cap render quality
        renderQuality = (renderQuality > maxRenderQuality) ? maxRenderQuality : (renderQuality > 8) ? 8 : renderQuality


        // debug node
        self.debugNode = SKTiledDebugDrawNode(tileLayer: self.defaultLayer, isDefault: true)
        self.debugNode.zPosition = zPosition + zDeltaForLayers
        self.objectsOverlay.zPosition = zPosition + (zDeltaForLayers * 2)

        addChild(debugNode)
        addChild(objectsOverlay)

        self.setupNotifications()
    }

    /**
     Initialize with map size/tile size

     - parameter sizeX:     `Int` map width in tiles.
     - parameter sizeY:     `Int` map height in tiles.
     - parameter tileSizeX: `Int` tile width in pixels.
     - parameter tileSizeY: `Int` tile height in pixels.
     - returns: `SKTilemap`
     */
    public init(_ sizeX: Int, _ sizeY: Int,
                _ tileSizeX: Int, _ tileSizeY: Int,
                orientation: TilemapOrientation = .orthogonal) {

        self.size = CGSize(width: CGFloat(sizeX), height: CGFloat(sizeY))
        self.tileSize = CGSize(width: CGFloat(tileSizeX), height: CGFloat(tileSizeY))
        self.orientation = orientation
        self.antialiasLines = (currentZoom < 1)
        super.init()

        // turn off effects rendering by default
        shouldEnableEffects = false
        self.setupNotifications()
    }

    deinit {
        self.dataStorage = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Layer.ObjectAdded, object: nil)
    }

    // MARK: - Tilesets

    /**
     Add a tileset to tilesets set.

     - parameter tileset: `SKTileset` tileset object.
     */
    public func addTileset(_ tileset: SKTileset) {
        tilesets.insert(tileset)
        tileset.tilemap = self
        tileset.ignoreProperties = ignoreProperties
        tileset.loggingLevel = loggingLevel
    }

    /**
     Remove a tileset from the tilesets set.

     - parameter tileset: `SKTileset` removed tileset.
     */
    public func removeTileset(_ tileset: SKTileset) -> SKTileset? {
        return tilesets.remove(tileset)
    }

    /**
     Returns a named tileset from the tilesets set.

     - parameter named: `String` tileset to return.
     - returns: `SKTileset?` tileset object.
     */
    public func getTileset(named: String) -> SKTileset? {
        if let index = tilesets.index(where: { $0.name == named }) {
            let tileset = tilesets[index]
            return tileset
        }
        return nil
    }

    /**
     Returns an external tileset with a given filename.

     - parameter filename: `String` tileset source file.
     - returns: `SKTileset?`
     */
    public func getTileset(fileNamed filename: String) -> SKTileset? {
        if let index = tilesets.index(where: { $0.filename == filename }) {
            let tileset = tilesets[index]
            return tileset
        }
        return nil
    }

    /**
     Returns the tileset associated with a global id.

     - parameter forTile: `Int` tile global id.
     - returns: `SKTileset?` associated tileset.
     */
    public func getTileset(forTile: Int) -> SKTileset? {
        guard let tiledata = getTileData(globalID: forTile) else {
            return nil
        }
        return tiledata.tileset
    }

    // MARK: Coordinates
    /**
     Returns a point for a given coordinate in the layer, with optional offset values for x/y.

     - parameter coord:   `CGPoint` tile coordinate.
     - parameter offsetX: `CGFloat` x-offset value.
     - parameter offsetY: `CGFloat` y-offset value.
     - returns: `CGPoint` point in layer.
     */
    public func pointForCoordinate(coord: CGPoint, offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> CGPoint {
        return defaultLayer.pointForCoordinate(coord: coord, offsetX: offsetX, offsetY: offsetY)
    }

    /**
     Returns a tile coordinate for a given vector_int2 coordinate.

     - parameter vec2: `int2` vector int2 coordinate.
     - returns: `CGPoint` position in layer.
     */
    public func pointForCoordinate(vec2: int2) -> CGPoint {
        return defaultLayer.pointForCoordinate(vec2: vec2)
    }

    /**
     Returns a tile coordinate for a given point in the layer.

     - parameter point: `CGPoint` point in layer.
     - returns: `CGPoint` tile coordinate.
     */
    public func coordinateForPoint(_ point: CGPoint) -> CGPoint {
        return defaultLayer.coordinateForPoint(point)
    }

    /**
     Returns a tile coordinate for a given point in the layer as a vector_int2.

     - parameter point: `CGPoint` point in layer.
     - returns: `int2` tile coordinate.
     */
    public func vectorCoordinateForPoint(_ point: CGPoint) -> int2 {
        return defaultLayer.vectorCoordinateForPoint(point)
    }

    // MARK: - Layers
    /**
     Returns an array of child layers, sorted by index (first is lowest, last is highest).

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTiledLayerObject]` array of layers.
     */
    public func getLayers(recursive: Bool = true) -> [SKTiledLayerObject] {
        return (recursive == true) ? self.layers : Array(self._layers)
    }

    /**
     Returns all content layers (ie. not groups). Sorted by zPosition in scene.

     - returns: `[SKTiledLayerObject]` array of layers.
     */
    public func getContentLayers() -> [SKTiledLayerObject] {
        return self.layers.filter { $0 as? SKGroupLayer == nil }.sorted(by: { $0.actualZPosition > $1.actualZPosition })
    }

    /**
     Returns an array of layer names.

     - returns: `[String]` layer names.
     */
    public func layerNames() -> [String] {
        return layers.compactMap { $0.name }
    }

    /**
     Add a layer to the current layers set. Automatically sets zPosition based on the `SKTilemap.zDeltaForLayers` property. If the `group` argument is not nil, layer will be added to the group instead.

     - parameter layer:    `SKTiledLayerObject` layer object.
     - parameter group:    `SKGroupLayer?` optional group layer.
     - parameter clamped:  `Bool` clamp position to nearest pixel.
     - returns: `(success: Bool, layer: SKTiledLayerObject)` add was successful, layer added.
     */
    @discardableResult
    public func addLayer(_ layer: SKTiledLayerObject, group: SKGroupLayer? = nil, clamped: Bool = true) -> (success: Bool, layer: SKTiledLayerObject) {

        // if a group is indicated, add it to that instead
        if (group != nil) {
            return group!.addLayer(layer, clamped: clamped)
        }

        // get the next z-position from the tilemap.
        let nextZPosition = (_layers.isEmpty == false) ? zDeltaForLayers * CGFloat(_layers.count + 1) : zDeltaForLayers

        // set the layer index
        layer.index = layers.isEmpty == false ? lastIndex + 1 : 0

        // default layer index is -1
        if let bgLayer = layer as? BackgroundLayer {
            bgLayer.index = -1
        }

        let (success, inserted) = _layers.insert(layer)

        if (success == false) {
            Logger.default.log("could not add layer: \"\(inserted.layerName)\"", level: .error)
        }

        // add the layer as a child
        addChild(layer)

        // align the layer with the anchorpoint
        positionLayer(layer, clamped: clamped)

        // set layer zposition
        layer.zPosition = nextZPosition

        // override debugging colors
        layer.gridColor = gridColor
        layer.frameColor = frameColor
        layer.highlightColor = highlightColor
        layer.loggingLevel = loggingLevel
        layer.ignoreProperties = ignoreProperties

        return (success, inserted)
    }

    /**
     Remove a layer from the current layers set.

     - parameter layer: `SKTiledLayerObject` layer object.
     - returns: `SKTiledLayerObject?` removed layer.
     */
    public func removeLayer(_ layer: SKTiledLayerObject) -> SKTiledLayerObject? {
        return _layers.remove(layer)
    }

    /**
     Create and add a new tile layer.

     - parameter named: `String` layer name.
     - parameter group: `SKGroupLayer?` optional group layer.
     - returns: `SKTileLayer` new layer.
     */
    @discardableResult
    public func newTileLayer(named: String, group: SKGroupLayer? = nil) -> SKTileLayer {
        let tileLayer = SKTileLayer(layerName: named, tilemap: self)
        return addLayer(tileLayer, group: group).layer as! SKTileLayer
    }

    /**
     Create and add a new object group.

     - parameter named: `String` layer name.
     - parameter group: `SKGroupLayer?` optional group layer.
     - returns: `SKObjectGroup` new layer.
     */
    @discardableResult
    public func newObjectGroup(named: String, group: SKGroupLayer? = nil) -> SKObjectGroup {
        let groupLayer = SKObjectGroup(layerName: named, tilemap: self)
        return addLayer(groupLayer, group: group).layer as! SKObjectGroup
    }

    /**
     Create and add a new image layer.

     - parameter named: `String` layer name.
     - parameter group: `SKGroupLayer?` optional group layer.
     - returns: `SKImageLayer` new layer.
     */
    @discardableResult
    public func newImageLayer(named: String, group: SKGroupLayer? = nil) -> SKImageLayer {
        let imageLayer = SKImageLayer(layerName: named, tilemap: self)
        return addLayer(imageLayer, group: group).layer as! SKImageLayer
    }

    /**
     Create and add a new group layer.

     - parameter named: `String` layer name.
     - parameter group: `SKGroupLayer?` optional group layer.
     - returns: `SKGroupLayer` new layer.
     */
    @discardableResult
    public func newGroupLayer(named: String, group: SKGroupLayer? = nil) -> SKGroupLayer {
        let groupLayer = SKGroupLayer(layerName: named, tilemap: self)
        return addLayer(groupLayer, group: group).layer as! SKGroupLayer
    }

    /**
     Return layers matching the given name.

     - parameter name:      `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTiledLayerObject]` layer objects.
     */
    public func getLayers(named layerName: String, recursive: Bool = true) -> [SKTiledLayerObject] {
        var result: [SKTiledLayerObject] = []
        let layersToCheck = self.getLayers(recursive: recursive)
        if let index = layersToCheck.index(where: { $0.name == layerName }) {
            result.append(layersToCheck[index])
        }
        return result
    }

    /**
     Return layers with names matching the given prefix.

     - parameter withPrefix: `String` prefix to match.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTiledLayerObject]` layer objects.
     */
    public func getLayers(withPrefix: String, recursive: Bool = true) -> [SKTiledLayerObject] {
        var result: [SKTiledLayerObject] = []
        let layersToCheck = self.getLayers(recursive: recursive)
        if let index = layersToCheck.index(where: { $0.layerName.hasPrefix(withPrefix) }) {
            result.append(layersToCheck[index])
        }
        return result
    }

    /**
     Return layers at the given path.

     - parameter atPath: `String` layer path.
     - returns: `[SKTiledLayerObject]` layer objects.
     */
    public func getLayers(atPath: String) -> [SKTiledLayerObject] {
        var result: [SKTiledLayerObject] = []
        if let index = self.layers.index(where: { $0.path == atPath }) {
            result.append(self.layers[index])
        }
        return result
    }

    /**
     Returns a layer matching the given UUID.

     - parameter uuid: `String` tile layer UUID.
     - returns: `SKTiledLayerObject?` layer object.
     */
    public func getLayer(withID uuid: String) -> SKTiledLayerObject? {
        if let index = layers.index(where: { $0.uuid == uuid }) {
            let layer = layers[index]
            return layer
        }
        return nil
    }

    /**
     Returns a layer given the index (0 being the lowest).

     - parameter index: `Int` layer index.
     - returns: `SKTiledLayerObject?` layer object.
     */
    public func getLayer(atIndex index: Int) -> SKTiledLayerObject? {
        if let index = _layers.index(where: { $0.index == index }) {
            let layer = _layers[index]
            return layer
        }
        return nil
    }

    /**
     Return layers assigned a custom `type` property.

     - parameter ofType:    `String` layer type.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTiledLayerObject]` array of layers.
     */
    public func getLayers(ofType: String, recursive: Bool = true) -> [SKTiledLayerObject] {
        return getLayers(recursive: recursive).filter { $0.type != nil }.filter { $0.type! == ofType }
    }

    /**
     Return tile layers matching the given name. If recursive is false, only returns top-level layers.

     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    public func tileLayers(named layerName: String, recursive: Bool = true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKTileLayer != nil }.filter { $0.name == layerName } as! [SKTileLayer]
    }

    /**
     Return tile layers with names matching the given prefix. If recursive is false, only returns top-level layers.

     - parameter withPrefix: `String` prefix to match.
     - parameter recursive:  `Bool` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    public func tileLayers(withPrefix: String, recursive: Bool = true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKTileLayer != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKTileLayer]
    }

    /**
     Returns a tile layer at the given index, otherwise, nil.

     - parameter atIndex: `Int` layer index.
     - returns: `SKTileLayer?` matching tile layer.
     */
    public func tileLayer(atIndex index: Int) -> SKTileLayer? {
        if let layerIndex = tileLayers(recursive: false).index(where: {$0.index == index} ) {
            let layer = tileLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }

    /**
     Return object groups matching the given name. If recursive is false, only returns top-level layers.

     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKObjectGroup]` array of object groups.
     */
    public func objectGroups(named layerName: String, recursive: Bool = true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).filter { $0 as? SKObjectGroup != nil }.filter { $0.name == layerName } as! [SKObjectGroup]
    }

    /**
     Return object groups with names matching the given prefix. If recursive is false, only returns top-level layers.

     - parameter withPrefix: `String` prefix to match.
     - parameter recursive:  `Bool` include nested layers.
     - returns: `[SKObjectGroup]` array of object groups.
     */
    public func objectGroups(withPrefix: String, recursive: Bool = true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).filter { $0 as? SKObjectGroup != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKObjectGroup]
    }

    /**
     Returns an object group at the given index, otherwise, nil.

     - parameter atIndex: `Int` layer index.
     - returns: `SKObjectGroup?` matching group layer.
     */
    public func objectGroup(atIndex index: Int) -> SKObjectGroup? {
        if let layerIndex = objectGroups(recursive: false).index(where: {$0.index == index} ) {
            let layer = objectGroups(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }

    /**
     Return image layers matching the given name. If recursive is false, only returns top-level layers.

     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKImageLayer]` array of image layers.
     */
    public func imageLayers(named layerName: String, recursive: Bool = true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKImageLayer != nil }.filter { $0.name == layerName } as! [SKImageLayer]
    }

    /**
     Return image layers with names matching the given prefix. If recursive is false, only returns top-level layers.

     - parameter withPrefix: `String` prefix to match.
     - parameter recursive:  `Bool` include nested layers.
     - returns: `[SKImageLayer]` array of image layers.
     */
    public func imageLayers(withPrefix: String, recursive: Bool = true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKImageLayer != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKImageLayer]
    }

    /**
     Returns an image layer at the given index, otherwise, nil.

     - parameter atIndex: `Int` layer index.
     - returns: `SKImageLayer?` matching image layer.
     */
    public func imageLayer(atIndex index: Int) -> SKImageLayer? {
        if let layerIndex = imageLayers(recursive: false).index(where: {$0.index == index} ) {
            let layer = imageLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }

    /**
     Return group layers matching the given name. If recursive is false, only returns top-level layers.

     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKGroupLayer]` array of group layers.
     */
    public func groupLayers(named layerName: String, recursive: Bool = true) -> [SKGroupLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKGroupLayer != nil }.filter { $0.name == layerName } as! [SKGroupLayer]
    }

    /**
     Return group layers with names matching the given prefix. If recursive is false, only returns top-level layers.

     - parameter withPrefix:  `String` prefix to match.
     - parameter recursive:   `Bool` include nested layers.
     - returns: `[SKGroupLayer]` array of group layers.
     */
    public func groupLayers(withPrefix: String, recursive: Bool = true) -> [SKGroupLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKGroupLayer != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKGroupLayer]
    }

    /**
     Returns an group layer at the given index, otherwise, nil.

     - parameter atIndex: `Int` layer index.
     - returns: `SKGroupLayer?` matching group layer.
     */
    public func groupLayer(atIndex index: Int) -> SKGroupLayer? {
        if let layerIndex = groupLayers(recursive: false).index(where: { $0.index == index } ) {
            let layer = groupLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }

    /**
     Position child layers in relation to the map's anchorpoint.

     - parameter layer: `SKTiledLayerObject` layer.
     - parameter clamped: `Bool` layer.
     */
    internal func positionLayer(_ layer: SKTiledLayerObject, clamped: Bool = false) {

        var layerPos = CGPoint.zero

        switch orientation {
        case .orthogonal:
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y

            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y

        case .isometric:
            // layer offset
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y

        case .hexagonal, .staggered:
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y

            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
        }

        // clamp the layer position
        if (clamped == true) {
            let scaleFactor = TiledGlobals.default.contentScale
            layerPos = clampedPosition(point: layerPos, scale: scaleFactor)
        }
        layer.position = layerPos
    }

    /**
     Position a child node in relation to the map's anchorpoint.

     - parameter node:     `SKNode` SpriteKit node.
     - parameter clamped:  `Bool` clamp position to nearest pixel.
     - parameter offset:   `CGPoint` node offset amount.
     */
    internal func positionNode(_ node: SKNode, clamped: Bool = true, offset: CGPoint = CGPoint.zero) {

        var nodePosition = CGPoint.zero

        switch orientation {
        case .orthogonal:
            nodePosition.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            nodePosition.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            nodePosition.x += offset.x
            nodePosition.y -= offset.y

        case .isometric:
            nodePosition.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            nodePosition.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            nodePosition.x += offset.x
            nodePosition.y -= offset.y

        case .hexagonal, .staggered:
            nodePosition.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            nodePosition.y = sizeInPoints.height * layerAlignment.anchorPoint.y

            nodePosition.x += offset.x
            nodePosition.y -= offset.y
        }

        // clamp the node position
        if (clamped == true) {
            let scaleFactor = TiledGlobals.default.contentScale
            nodePosition = clampedPosition(point: nodePosition, scale: scaleFactor)
        }

        node.position = nodePosition
    }

    /**
     Sort the layers in z based on a starting value (defaults to the current zPosition).

     - parameter from: `CGFloat?` optional starting z-positon.
     */
    public func sortLayers(from: CGFloat?=nil) {
        let startingZ: CGFloat = (from != nil) ? from! : zPosition
        getLayers().forEach { $0.zPosition = startingZ + (zDeltaForLayers * CGFloat($0.index)) }
    }

    // MARK: - Tiles

    /**
     Return tiles at the given point (all tile layers).

     - parameter point: `CGPoint` position in tilemap.
     - returns: `[SKTile]` array of tiles.
     */
    public func tilesAt(point: CGPoint) -> [SKTile] {
        return nodes(at: point).filter { node in
            node as? SKTile != nil
        } as! [SKTile]
    }

    /**
     Return tiles at the given coordinate (all tile layers).

     - parameter coord: `CGPoint` coordinate.
     - returns: `[SKTile]` array of tiles.
     */
    public func tilesAt(coord: CGPoint) -> [SKTile] {
        return tileLayers(recursive: true).compactMap { $0.tileAt(coord: coord) }
    }

    /**
     Return tiles at the given coordinate (all tile layers).

     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` - y-coordinate.
     - returns: `[SKTile]` array of tiles.
     */
    public func tilesAt(_ x: Int, _ y: Int) -> [SKTile] {
        return tilesAt(coord: CGPoint(x: CGFloat(x), y: CGFloat(y)))
    }

    /**
     Returns a tile at the given coordinate from a layer.

     - parameter coord:    `CGPoint` tile coordinate.
     - parameter inLayer:  `String?` layer name.
     - returns: `SKTile?` tile, or nil.
     */
    public func tileAt(coord: CGPoint, inLayer named: String?) -> SKTile? {
        if let named = named {
            if let layer = getLayers(named: named).first as? SKTileLayer {
                return layer.tileAt(coord: coord)
            }
        }
        return nil
    }

    /**
     Returns a tile at the given coordinate from a layer.

     - parameter x: `Int` tile x-coordinate.
     - parameter y: `Int` tile y-coordinate.
     - parameter named: `String?` layer name.
     - returns: `SKTile?` tile, or nil.
     */
    public func tileAt(_ x: Int, _ y: Int, inLayer named: String?) -> SKTile? {
        return tileAt(coord: CGPoint(x: CGFloat(x), y: CGFloat(y)), inLayer: named)
    }

    /**
     Returns all tiles in the map. If recursive is false, only returns tiles from top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(recursive: Bool = true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles() }
    }

    /**
     Returns tiles with a property of the given type. If recursive is false, only returns tiles from top-level layers.

     - parameter ofType:    `String` type.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(ofType: String, recursive: Bool = true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles(ofType: ofType) }
    }

    /**
     Returns tiles with the given global id. If recursive is false, only returns tiles from top-level layers.

     - parameter globalID:  `Int` tile globla id.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(globalID: Int, recursive: Bool = true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles(globalID: globalID) }
    }

    /**
     Returns tiles with a property of the given type & value. If recursive is false, only returns tiles from top-level layers.

     - parameter named: `String` property name.
     - parameter value: `Any` property value.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTilesWithProperty(_ named: String, _ value: Any, recursive: Bool = true) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers(recursive: recursive) {
            result += layer.getTilesWithProperty(named, value)
        }
        return result
    }


    /**
     Returns an array of all animated tile objects.

     - returns: `[SKTile]` array of tiles.
     */
    public func animatedTiles(recursive: Bool = true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.animatedTiles() }
    }

    /**
     Return the top-most tile at the given coordinate.

     - parameter coord: `CGPoint` coordinate.
     - returns: `SKTile?` first tile in layers.
     */
    public func firstTileAt(coord: CGPoint) -> SKTile? {
        for layer in tileLayers(recursive: true).reversed().filter({ $0.visible == true }) {
            if let tile = layer.tileAt(coord: coord) {
                return tile
            }
        }
        return nil
    }

    // MARK: - Data
    /**
     Returns data for a global tile id.

     - parameter globalID: `Int` global tile id.
     - returns: `SKTilesetData` tile data, if it exists.
     */
    public func getTileData(globalID gid: Int) -> SKTilesetData? {
        let realID = flippedTileFlags(id: UInt32(gid)).gid
        for tileset in tilesets where tileset.contains(globalID: realID) {
            if let tileData = tileset.getTileData(globalID: Int(realID)) {
                return tileData
            }
        }
        return nil
    }

    /**
     Return tile data with a property of the given type.

     - parameter ofType: `String` tile data type.
     - returns: `[SKTilesetData]` array of tile data.
     */
    public func getTileData(ofType: String) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(withProperty: ofType) }
    }

    /**
     Return tile data with a property of the given type (all tilesets).

     - parameter named: `String` property name.
     - returns: `[SKTilesetData]` array of tile data.
     */
    public func getTileData(withProperty named: String) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(withProperty: named) }
    }

    /**
     Return tile data with a property of the given type (all tile layers).

     - parameter named: `String` property name.
     - parameter value: `Any` property value.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTileData(withProperty named: String, _ value: Any) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(withProperty: named, value) }
    }

    /**
     Returns tile data with the given name & animated state.

     - parameter named:      `String` data name.
     - parameter isAnimated: `Bool` filter data that is animated.
     - returns: `[SKTilesetData]` array of tile data.
     */
    public func getTileData(named name: String, isAnimated: Bool = false) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(named: name, isAnimated: isAnimated) }
    }

    // MARK: - Objects

    /**
     Return obejects at the given point (all object groups).

     - parameter coord: `CGPoint` coordinate.
     - returns: `[SKTileObject]` array of objects.
     */
    public func objectsAt(point: CGPoint) -> [SKTileObject] {
        return nodes(at: point).filter { node in
            node as? SKTileObject != nil
            } as! [SKTileObject]
    }

    /**
     Return all of the current tile objects. If recursive is false, only returns objects from top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects() }
    }

    /**
     Return objects matching a given type. If recursive is false, only returns objects from top-level layers.

     - parameter ofType:    `String` object type to query.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(ofType: String, recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(ofType: ofType) }
    }

    /**
     Return objects matching a given name. If recursive is false, only returns objects from top-level layers.

     - parameter named:     `String` object name to query.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(named: String, recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(named: named) }
    }

    /**
     Return objects with the given text value. If recursive is false, only returns objects from top-level layers.

     - parameter withText:   `String` text value.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(withText text: String, recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(withText: text) }
    }

    /**
     Returns an object with the given id.

     - parameter id: `Int` Object id.
     - returns: `SKTileObject?`
     */
    public func getObject(withID id: Int) -> SKTileObject? {
        return objectGroups(recursive: true).compactMap { $0.getObject(withID: id) }.first
    }

    /**
     Return object proxies.

     - returns: `[TileObjectProxy]` array of object proxies.
     */
    internal func getObjectProxies() -> [TileObjectProxy] {
        return objectGroups().flatMap { $0.getObjectProxies() }
    }

    /**
     Return objects with a tile id. If recursive is false, only returns objects from top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` objects with a tile gid.
     */
    public func tileObjects(recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.tileObjects() }
    }

    /**
     Return objects with a tile id. If recursive is false, only returns objects from top-level layers.

     - parameter globalID:  `Int` global tile id.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` objects with a tile gid.
     */
    public func tileObjects(globalID: Int, recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.tileObjects(globalID: globalID) }
    }

    /**
     Return text objects. If recursive is false, only returns objects from top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` text objects.
     */
    public func textObjects(recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.textObjects() }
    }

    // MARK: - Coordinates

    /**
     Returns true if the coordinate is valid.

     - parameter coord: `CGPoint` tile coordinate.
     - returns: `Bool` coodinate is valid.
     */
    public func isValid(coord: CGPoint) -> Bool {
        return defaultLayer.isValid(Int(coord.x), Int(coord.y))
    }


    /**
     Returns a touch location in negative-y space.

     *Position is in converted space*

     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    #if os(iOS) || os(tvOS)
    public func touchLocation(_ touch: UITouch) -> CGPoint {
        return defaultLayer.touchLocation(touch)
    }

    /**
     Returns the tile coordinate at a touch location.

     - parameter touch: `UITouch` touch location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    public func coordinateAtTouchLocation(_ touch: UITouch) -> CGPoint {
        return defaultLayer.screenToTileCoords(touchLocation(touch))
    }
    #endif

    #if os(macOS)
    /**
     Returns a mouse event location in the default layer. (negative-y space).

     *Position is in converted space*

     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    public func mouseLocation(event: NSEvent) -> CGPoint {
        return defaultLayer.mouseLocation(event: event)
    }

    /**
     Returns the tile coordinate at a mouse event location.

     - parameter event: `NSEvent` mouse event location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    public func coordinateAtMouseEvent(event: NSEvent) -> CGPoint {
        return defaultLayer.screenToTileCoords(mouseLocation(event: event))
    }
    #endif

    // MARK: - Shaders

    /**
     Set a shader for the tile layer.

     - parameter named:    `String` shader file name.
     - parameter uniforms: `[SKUniform]` array of shader uniforms.
     */
    public func setShader(named: String, uniforms: [SKUniform] = []) {
        let fshader = SKShader(fileNamed: named)
        fshader.uniforms = uniforms
        shouldEnableEffects = true
        self.shader = fshader
    }

    // MARK: - Callbacks

    /**
     Called when parser has finished reading the map.

     - parameter timeStarted: `Date` render start time.
     - parameter tasks:       `Int`  number of tasks to complete.
     */
    public func didFinishParsing(timeStarted: Date, tasks: Int = 0) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tilemapFinishedParsing"), object: nil, userInfo: ["parseTime": timeStarted])
    }

    /**
     Called when parser has finished rendering the map.

     - parameter timeStarted: `Date` render start time.
     */
    public func didFinishRendering(timeStarted: Date) {
        // set the `isRendered` property
        isRendered = layers.filter { $0.isRendered == false }.isEmpty

        // set the z-depth of the defaultLayer & background sprite
        defaultLayer.zPosition = -zDeltaForLayers

        // transfer attributes
        scene?.physicsWorld.gravity = gravity

        // delegate callback
        defer {
            self.delegate?.didRenderMap(self)
            NotificationCenter.default.post(
                name: Notification.Name.Map.FinishedRendering,
                object: self,
                userInfo: ["renderTime": timeStarted]
            )
        }

        // run animation actions
        self.runAnimationAsActions(TiledGlobals.default.updateMode == TileUpdateMode.actions)

        // clamp the position of the map & parent nodes
        clampNodePosition(node: self, scale: TiledGlobals.default.contentScale)

        // set the `SKTilemap.bounds` attribute
        //let vertices = getVertices()

        // set the debug zPosition
        let debugStartZPosition = (lastZPosition + zDeltaForLayers)
        debugNode.zPosition = debugStartZPosition
        debugNode.position = defaultLayer.position
        objectsOverlay.zPosition = debugStartZPosition + (zDeltaForLayers + 100)
        updateProxyObjects()
    }

    // MARK: - Notifications

    /**
     Setup notification callbacks.
     */
    internal func setupNotifications() {
        // nuttin here
    }

    internal func updateProxyObjects() {
        guard let dataStorage = dataStorage else {
            log("cannot access tile data storage.", level: .error)
            return
        }

        // clear the layer
        objectsOverlay.removeAllChildren()

        var proxyCount = 0

        renderQueue.sync {
            for object in dataStorage.objectsList {
                // create a proxy
                let proxyObject = TileObjectProxy(object: object, visible: self.showObjects, renderable: object.isRenderableType)
                self.objectsOverlay.addChild(proxyObject)
                proxyObject.container = self.objectsOverlay
                proxyObject.zPosition = self.zDeltaForLayers
                proxyObject.draw()
                proxyCount += 1
            }
        }
        objectsOverlay.initialized = true
    }


    /**
     Post render stats to listeners.

     - parameter renderStart: `Date` render start date.
     - parameter completion: `() -> Void?` optional completion function.
     */
    internal func postRenderStatistics(_ renderStart: Date, _ completion: (() -> Void)? = nil) {
        // copy the render stats and add render time
        var renderStatsToSend = self.renderStatistics.copy()
        renderStatsToSend.renderTime = Date().timeIntervalSince(renderStart)

        renderQueue.sync {

            // update observers
            NotificationCenter.default.post(
                name: Notification.Name.Map.RenderStatsUpdated,
                object: renderStatsToSend
            )

            completion?()
        }
    }


    // MARK: - SpriteKit Actions

    /**
     Run layer animations as SpriteKit actions.

     - parameter value:   `Bool` on/off toggle.
     - parameter restore: `Bool` restore textures.
     */
    public func runAnimationAsActions(_ value: Bool, restore: Bool = true) {
        self.layers.forEach { layer in
            if (value == true) {
                layer.runAnimationAsActions()
            } else {
                layer.removeAnimationActions(restore: restore)
            }
        }
    }

    // MARK: - Updating


    /**
     Update the map as each frame is rendered.

     - parameter currentTime: `TimeInterval` update interval.
     */
    public func update(_ currentTime: TimeInterval) {
        guard (isRendered == true) && (isPaused == false) else {
            return
        }

        defer {
            // sync all queues
            staticTilesQueue.sync {}
            animatedTilesQueue.sync {}
            renderStatistics.updatedThisFrame = 0
        }

        // initialize last update time
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }

        // time since last update
        var dt = currentTime - self.lastUpdateTime
        dt = dt > maximumUpdateDelta ? maximumUpdateDelta : dt

        self.lastUpdateTime = currentTime

        // (re)draw proxy objects
        if (objectsOverlay.initialized == false) {
            self.updateProxyObjects()
        }

        // update tiles
        guard let dataStorage = dataStorage else { return }

        // render start time
        let renderStart = Date()

        switch updateMode {

        case .full:
            // update cached tiles
            self.updateStaticTiles(delta: dt) { fcount in
                self.renderStatistics.updatedThisFrame += fcount
            }

            // update animated tiles
            self.updateAnimatedTiles(delta: dt) { fcount in
                self.renderStatistics.updatedThisFrame += fcount
            }

        case .dynamic:
            // update animated tiles
            self.updateAnimatedTiles(delta: dt) { fcount in
                self.renderStatistics.updatedThisFrame += fcount
            }

        default:
            break
        }

        if (currentFrameIndex >= renderStatisticsSampleFrequency) {
            // update render statistics
            renderStatistics.updateMode = updateMode
            renderStatistics.objectCount = dataStorage.objectsList.count
            renderStatistics.objectsVisible = (showObjects == true)
            renderStatistics.visibleCount = nodesInView.count
            renderStatistics.effectsEnabled = shouldEnableEffects

            if (TiledGlobals.default.enableRenderCallbacks == true) {
                renderStatistics.cpuPercentage = Int(cpuUsage())
                // send render statistics back to the controller
                self.postRenderStatistics(renderStart) {
                    self.currentFrameIndex = 0
                }
            }
        }

        currentFrameIndex += 1
    }

    /**
     Update static tiles.

     - parameter delta: `TimeInterval` current time delta.
     */
    internal func updateStaticTiles(delta: TimeInterval, _ completion: ((Int) -> Void)? = nil) {
        guard let dataStorage = dataStorage else { return }

        var staticTilesUpdated = 0

        staticTilesQueue.async {

            for staticItem in dataStorage.staticTileCache.enumerated() {

                let tileData = staticItem.element.key
                let tileArray = staticItem.element.value
                let tileTexture = tileData.texture

                // loop through tiles
                for tile in tileArray {

                    // ignore tiles not in view
                    if (tile.visibleToCamera) == false {
                        continue
                    }

                    switch tile.renderMode {

                    // tile is ignoring its tile data, move on
                    case .ignore:
                        continue

                    default:

                        // for `default` & `static`, just update the tile texture and continue...
                        guard let tileTexture = tileTexture else {
                            continue
                        }

                        tile.texture = tileTexture
                        tile.size = tileTexture.size()
                    }

                    staticTilesUpdated += 1
                }
            }

            if (TiledGlobals.default.enableRenderCallbacks == true) {
                DispatchQueue.main.async {
                    completion?(staticTilesUpdated)
                }
            }
        }
    }


    /**
     Update cached animated tiles.

     - parameter delta: `TimeInterval` current time delta.
     */
    internal func updateAnimatedTiles(delta: TimeInterval, _ completion: ((Int) -> Void)? = nil) {
        guard let dataStorage = dataStorage else { return }

        var animatedTilesUpdated = 0

        animatedTilesQueue.async {
            for animatedItem in dataStorage.animatedTileCache.enumerated() {

                let tileData = animatedItem.element.key
                let tileArray = animatedItem.element.value
                
                // ignore tile animation if the data is flagged as blocked
                guard (tileData.blockAnimation == false) else {
                    continue
                }

                // figure out which frame of animation we're at...
                let cycleTime = tileData.animationTime
                guard (cycleTime > 0) else { continue }

                // array of frame values
                let frames: [TileAnimationFrame] = (self.speed >= 0) ? tileData.frames : tileData.frames.reversed()

                // increment the current time value
                tileData.currentTime += (delta * abs(Double(self.speed)))

                // current time in ms
                let ct: Int = Int(tileData.currentTime * 1000)

                // current frame
                var cf: UInt8? = nil

                var aggregate = 0

                // get the frame at the current time
                for (idx, frame) in frames.enumerated() {
                    aggregate += frame.duration

                    if ct < aggregate  {
                        if cf == nil {
                            cf = UInt8(idx)
                        }
                    }
                }

                // create a pointer to the texture we're planning to use...
                var currentTexture: SKTexture?

                // set texture for current frame
                if let currentFrame = cf {

                    // stash the frame index
                    tileData.frameIndex = currentFrame
                    let frame = frames[Int(currentFrame)]

                    if let frameTexture = frame.texture {
                        // update frame texture
                        currentTexture = frameTexture
                    }
                }

                // the the current time is greater than the animation cycle, reset current time to 0
                if ct >= cycleTime { tileData.currentTime = 0 }


                // loop through tiles
                for tile in tileArray {
                    // ignore tiles with disabled animation
                    if (tile.enableAnimation == false) {
                        continue
                    }
                    
                    // ignore tiles not in view
                    if (tile.visibleToCamera == false) {
                        continue
                    }

                    switch tile.renderMode {

                    case .ignore, .static:
                        continue

                    default:

                        if let frameTexture = currentTexture {
                            tile.texture = frameTexture
                            tile.size = frameTexture.size()
                        }
                    }
                    animatedTilesUpdated += 1
                }
            }

            if (TiledGlobals.default.enableRenderCallbacks == true) {
                DispatchQueue.main.async {
                    completion?(animatedTilesUpdated)
                }
            }
        }
    }
}


extension TileUpdateMode: CustomStringConvertible, CustomDebugStringConvertible {

    public var name: String {
        switch self {
        case .dynamic: return "dynamic"
        case .full: return "full"
        case .actions: return "actions"
        }
    }

    public var description: String {
        return self.name
    }

    public var debugDescription: String {
        return self.name
    }
}



extension TileUpdateMode {

    /**
     
     Returns an array of all tile update modes.
     
      - returns: `[TileUpdateMode]` array of all tile update modes.
     */
    static public func allModes() -> [TileUpdateMode] {
        return [.dynamic, .full, .actions]
    }
    
    /**
     
     Returns the next tile update mode.

     - returns: `TileUpdateMode` next update mode.
     */
    public func next() -> TileUpdateMode {
        switch self {
        case .dynamic: return .full
        case .full: return .actions
        case .actions: return .dynamic
        }
    }
}


// MARK: - Extensions

extension StaggerIndex: Hashable {

    init?(string value: String) {
        switch value {
        case "even": self = .even
        case "odd":  self = .odd
        default: return nil
        }
    }

    var hashValue: Int {
        return (self == .even) ? 1 : 0
    }
}


extension LayerPosition: CustomStringConvertible {

    internal var description: String {
        return "\(name): (\(self.anchorPoint.x), \(self.anchorPoint.y))"
    }

    internal var name: String {
        switch self {
        case .bottomLeft: return "Bottom Left"
        case .center: return "Center"
        case .topRight: return "Top Right"
        }
    }

    internal var anchorPoint: CGPoint {
        switch self {
        case .bottomLeft: return CGPoint(x: 0, y: 0)
        case .center: return CGPoint(x: 0.5, y: 0.5)
        case .topRight: return CGPoint(x: 1, y: 1)
        }
    }
}


extension SKTilemap {


    /// Auto-sizing property for map orientation.
    public var isPortrait: Bool {
        return sizeInPoints.height > sizeInPoints.width
    }

    // convenience properties
    public var width: CGFloat { return size.width }
    public var height: CGFloat { return size.height }

    /// Current tile width value.
    public var tileWidth: CGFloat {
        switch orientation {
        case .staggered:
            return CGFloat(Int(tileSize.width) & ~1)
        default:
            return tileSize.width
        }
    }

    /// Current tile height value.
    public var tileHeight: CGFloat {
        switch orientation {
        case .staggered:
            return CGFloat(Int(tileSize.height) & ~1)
        default:
            return tileSize.height
        }
    }

    public var tileWidthHalf: CGFloat { return tileWidth / 2 }
    public var tileHeightHalf: CGFloat { return tileHeight / 2 }
    public var sizeHalved: CGSize { return CGSize(width: size.width / 2, height: size.height / 2)}
    public var tileSizeHalved: CGSize { return CGSize(width: tileWidthHalf, height: tileHeightHalf)}

    // hexagonal/staggered
    public var staggerX: Bool { return (staggeraxis == .x) }
    public var staggerEven: Bool { return staggerindex == .even }

    public var sideLengthX: CGFloat { return (staggeraxis == .x) ? CGFloat(hexsidelength) : 0 }
    public var sideLengthY: CGFloat { return (staggeraxis == .y) ? CGFloat(hexsidelength) : 0 }

    public var sideOffsetX: CGFloat { return (tileWidth - sideLengthX) / 2 }
    public var sideOffsetY: CGFloat { return (tileHeight - sideLengthY) / 2 }

    // coordinate grid values for hex/staggered
    public var columnWidth: CGFloat { return sideOffsetX + sideLengthX }
    public var rowHeight: CGFloat { return sideOffsetY + sideLengthY }

    /**
     Returns true if the given x-coordinate represents a staggered (offset) column.

     - parameter x:  `Int` map x-coordinate.
     - returns: `Bool` column should be staggered.
     */
    internal func doStaggerX(_ x: Int) -> Bool {
        let hash: Int = (staggerEven == true) ? 1 : 0
        return staggerX && Bool((x & 1) ^ hash)

    }

    /**
     Returns true if the given y-coordinate represents a staggered (offset) row.

     - parameter x:  `Int` map y-coordinate.
     - returns: `Bool` row should be staggered.
     */
    internal func doStaggerY(_ y: Int) -> Bool {
        let hash: Int = (staggerEven == true) ? 1 : 0
        return !staggerX && Bool((y & 1) ^ hash)
    }

    internal func topLeft(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        // if the value of y is odd & stagger index is odd
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y - 1)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        } else {
            // if the value of x is odd & stagger index is odd
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        }
    }

    internal func topRight(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y - 1)
            } else {
                return CGPoint(x: x, y: y - 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y)
            } else {
                return CGPoint(x: x + 1, y: y - 1)
            }
        }
    }

    internal func bottomLeft(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y + 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y)
            }
        }
    }

    internal func bottomRight(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x, y: y + 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x + 1, y: y)
            }
        }
    }

    /// Returns all pathfinding graphs in the map
    public var graphs: [GKGridGraph<GKGridGraphNode>] {
        return tileLayers().compactMap { $0.graph }
    }

    public var isShowingGraphs: Bool {
        let visibleGraphLayers = tileLayers().filter{ tileLayer in
            tileLayer.debugDrawOptions.contains(.drawGraph) == true
        }
        return (visibleGraphLayers.isEmpty == false)
    }


    /// String representation of the map.
    override public var description: String {
        let sizedesc = "\(sizeInPoints.shortDescription): (\(size.shortDescription) @ \(tileSize.shortDescription))"
        guard isRendered == true else {
            return "Map: \(mapName), \(sizedesc)"
        }
        return "Map: \(mapName), \(sizedesc), \(tileCount) tiles"
    }

    /// Debug string representation of the map.
    override public var debugDescription: String {
        return "Tile Map: \"\(mapName)\", \(tileCount) tiles"
    }

    /**
     Returns an array of tiles/objects.

     - returns: `[SKNode]` array of child objects.
     */
    public func renderableObjects() -> [SKNode] {
        var result: [SKNode] = []
        enumerateChildNodes(withName: "*") { node, stop in
            if (node as? SKTiledGeometry != nil) {
                result.append(node)
            }
        }
        return result
    }

    /**
     Return tiles & objects at the given point in the map.

     - parameter point: `CGPoint` position in tilemap.
     - returns: `[SKNode]` array of tiles.
     */
    public func renderableObjectsAt(point: CGPoint) -> [SKNode] {
        let pixelPosition = defaultLayer.screenToPixelCoords(point)
        return nodes(at: pixelPosition).filter { node in
            (node as? SKTiledGeometry != nil)
        }
    }

    /**
     Returns an array of animated tiles/objects.

     - returns: `[SKNode]` array of child objects.
     */
    public func animatedObjects() -> [SKNode] {
        let renderable = renderableObjects()
        return renderable.filter {
            if let tile = $0 as? SKTile {
                return tile.action(forKey: tile.animationKey) != nil
            }

            if let tileObj = $0 as? SKTileObject {
                if let tile = tileObj.tile {
                    return tile.action(forKey: tile.animationKey) != nil
                }
            }
            return false
        }
    }
}


extension SKTilemap: CustomDebugReflectable {

    /**
     Dump a summary of the current tilemap's layer statistics.
     */
    public func dumpStatistics() {
        guard (layerCount > 0) else {
            print("# Tilemap \"\(mapName)\": 0 Layers")
            return
        }

        // collect graphs for each tile layer
        let graphs = tileLayers().compactMap { $0.graph }

        // format the header
        let graphsString = (graphs.isEmpty == false) ? (graphs.count > 1) ? " : \(graphs.count) Graphs" : " : \(graphs.count) Graph" : ""
        let headerString = "# Tilemap \"\(mapName)\": \(tileCount) Tiles: \(layerCount) Layers\(graphsString)"
        let titleUnderline = String(repeating: "-", count: headerString.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        //let columnTitles = ["Index", "Type", "Visible", "Name", "Position", "Size", "Offset", "Anchor", "Z-Position", "Opacity", "Update", "Static", "Graph"]
        let allLayers = self.layers.filter { $0 as? BackgroundLayer == nil }

        // get the stats from each layer
        let allLayerStats = allLayers.map { $0.layerStatsDescription }

        // prefix for each column
        var prefixes: [String] = ["", "", "", "", "pos", "size", "offset", "anc", "zpos", "opac", "nav"]

        // buffer for each column
        var buffers: [Int] = [1, 2, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        var columnSizes: [Int] = Array(repeating: 0, count: prefixes.count)

        // get the max column size for each column
        for (_, stats) in allLayerStats.enumerated() {
            for stat in stats {
                let cindex = Int(stats.index(of: stat)!)

                let colCharacters = stat.count
                let prefix = prefixes[cindex]
                let buffer = buffers[cindex]

                // if the current stat has characters
                if colCharacters > 0 {

                    // get the prefix size + buffer
                    let layerBufferSize = (prefix.isEmpty == false) ? prefix.count + buffer : 2

                    // this is the size of the column + prefix
                    let columnSize = colCharacters + layerBufferSize

                    // if this is more than the max, update the column sizes
                    if columnSize > columnSizes[cindex] {
                        columnSizes[cindex] = columnSize
                    }
                }
            }
        }


        for (_, stats) in allLayerStats.enumerated() {
            var layerOutputString = ""
            for (sidx, stat) in stats.enumerated() {

                // this is the column size to fill
                let columnSize = columnSizes[sidx]
                let buffer = buffers[sidx]

                let isLastColumn = (sidx == stats.count - 1)
                var nextValue: String? = nil
                let nextIndex = sidx + 1

                if (isLastColumn == false) {
                    nextValue = stats[nextIndex]
                }

                // format the prefix for each column
                var prefix  = ""
                var divider = ""
                var comma   = ""

                var currentColumnValue = " "

                // for empty values, add an extra buffer
                var emptyBuffer = 2
                if (stat.isEmpty == false) {
                    emptyBuffer = 0
                    prefix = prefixes[sidx]
                    if (prefix.isEmpty == false) {
                        divider = ": "
                        // for all columns but the last, add a comma
                        if (isLastColumn == false) {
                            comma = (nextValue == "") ? "" : ", "
                        }
                        prefix = "\(prefix)\(divider)"
                    }

                    currentColumnValue = "\(prefix)\(stat)\(comma)"
                }

                let fillSize = columnSize + comma.count + buffer + emptyBuffer
                // pad each string to the right
                layerOutputString += currentColumnValue.zfill(length: fillSize, pattern: " ", padLeft: false)
            }
            outputString += "\n\(layerOutputString)"
        }

        print("\n\n" + outputString + "\n\n")
    }
}



extension SKTilemap.TilemapOrientation {

    /// Hint for aligning tiles within each layer.
    public var alignmentHint: CGPoint {
        switch self {
        case .orthogonal:
            return CGPoint(x: 0.5, y: 0.5)
        case .isometric:
            return CGPoint(x: 0.5, y: 0.5)
        case .hexagonal:
            return CGPoint(x: 0.5, y: 0.5)
        case .staggered:
            return CGPoint(x: 0.5, y: 0.5)
        }
    }
}

extension SKTilemap.TilemapOrientation: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .orthogonal: return "orthogonal"
        case .isometric: return "isometric"
        case .hexagonal: return "hexagonal"
        case .staggered: return "staggered"
        }
    }
    public var debugDescription: String {
        return description
    }
}


extension SKTilemap.RenderStatistics {

    /**
     Create a copy of the current render statistics.

     - returns: `SKTilemap.RenderStatistics` render statistics for the current frame.
     */
    public func copy() -> SKTilemap.RenderStatistics {
        return SKTilemap.RenderStatistics(updateMode: self.updateMode, objectCount: self.objectCount,
                                          visibleCount: self.visibleCount, cpuPercentage: self.cpuPercentage,
                                          effectsEnabled: self.effectsEnabled, updatedThisFrame: self.updatedThisFrame,
                                          objectsVisible: self.objectsVisible, renderTime: 0)
    }
}



/**
 Default callback methods.
 */
extension SKTilemapDelegate {

    /// Determines the z-zposition difference between layers.
    public var zDeltaForLayers: CGFloat {
        return 50
    }

    /**
     Called when the tilemap is instantiated.

     - parameter tilemap:  `SKTilemap` tilemap instance.
     */
    public func didBeginParsing(_ tilemap: SKTilemap) {}

    /**
     Called when a tileset is added to a map.

     - parameter tileset:  `SKTileset` tileset instance.
     */
    public func didAddTileset(_ tileset: SKTileset) {}

    /**
     Called when a layer is added to a tilemap.

     - parameter layer:  `SKTiledLayerObject` tilemap instance.
     */
    public func didAddLayer(_ layer: SKTiledLayerObject) {}

    /**
     Called when the tilemap is finished parsing.

     - parameter tilemap:  `SKTilemap` tilemap instance.
     */
    public func didReadMap(_ tilemap: SKTilemap) {}

    /**
     Called when the tilemap layers are finished rendering.

     - parameter tilemap:  `SKTilemap` tilemap instance.
     */
    public func didRenderMap(_ tilemap: SKTilemap) {}

    /**
     Called when the a navigation graph is built for a layer.

     - parameter graph: `GKGridGraph<GKGridGraphNode>` graph instance.
     */
    public func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>) {}

    /**
     Specify a custom tile object for use in tile layers.

     - parameter className:    `String` optional class name.
     - returns `SKTile.self`:  `SKTile` subclass.
     */
    public func objectForTileType(named: String? = nil) -> SKTile.Type { return SKTile.self }

    /**
     Specify a custom object for use in object groups.

     - parameter named:             `String` optional class name.
     - returns `SKTileObject.self`: `SKTileObject` subclass.
     */
    public func objectForVectorType(named: String? = nil) -> SKTileObject.Type { return SKTileObject.self }

    /**
     Specify a custom graph node object for use in navigation graphs.

     - parameter named:                 `String` optional class name.
     - returns `GKGridGraphNode.Type`:  `GKGridGraphNode` node type.
     */
    public func objectForGraphType(named: String?) -> GKGridGraphNode.Type { return SKTiledGraphNode.self }
}



/* Clamp position of the map & parents when camera changes happen. */
extension SKTilemap: SKTiledSceneCameraDelegate {


    /**
     Called when the nodes in the camera view changes.

     - parameter nodes: `Set<SKNode>` nodes in camera view.
     */
    public func containedNodesChanged(_ nodes: Set<SKNode>) {
        guard (receiveCameraUpdates == true) else { return }

        DispatchQueue.main.async {
            self.nodesInView = nodes.filter {
                $0.isHidden == false
            }
        }
    }

    /**
     Called when the camera bounds updated.

     - parameter bounds:  `CGRect` camera view bounds.
     - parameter positon: `CGPoint` camera position.
     - parameter zoom:    `CGFloat` camera zoom amount.
     */
    public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {
        cameraBounds = bounds
    }

    /**
     Called when the camera positon changes.

     - parameter newPositon: `CGPoint` updated camera position.
     */
    public func cameraPositionChanged(newPosition: CGPoint) {
        // nodesInView
    }

    /**
     Called when the camera zoom changes.

     - parameter newZoom: `CGFloat` camera zoom amount.
     */
    public func cameraZoomChanged(newZoom: CGFloat) {
        //let oldZoom = currentZoom
        currentZoom = newZoom
        antialiasLines = (newZoom < 1)
    }

    #if os(iOS) || os(tvOS)

    /**
     Called when the scene receives a double-tap event (iOS only).

     - parameter location: `CGPoint` touch event location.
     */
    public func sceneDoubleTapped(location: CGPoint) {}
    #else

    /**
     Called when the scene is double-clicked (macOS only).

     - parameter event: `NSEvent` mouse click event.
     */
    public func sceneDoubleClicked(event: NSEvent) {}

    /**
     Called when the mouse moves in the scene (macOS only).

     - parameter event: `NSEvent` mouse click event.
     */
    public func mousePositionChanged(event: NSEvent) {}
    #endif
}


// MARK: - Deprecated

@available(*, deprecated, renamed: "SKTiledLayerObject")
typealias TiledLayerObject = SKTiledLayerObject


extension SKTilemap {

    /**
     Load a Tiled tmx file and return a new `SKTilemap` object. Returns nil if there is a problem reading the file

     - parameter filename:    `String` Tiled file name.
     - parameter delegate:    `SKTilemapDelegate?` optional [`SKTilemapDelegate`](Protocols/SKTilemapDelegate.html) instance.
     - parameter withTilesets `[SKTileset]?` optional tilesets.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    @available(*, deprecated, renamed: "SKTilemap.load(tmxFile:)")
    public class func load(fromFile filename: String,
                           delegate: SKTilemapDelegate? = nil,
                           withTilesets: [SKTileset]? = nil) -> SKTilemap? {

        return SKTilemap.load(tmxFile: filename, inDirectory: nil, delegate: delegate, withTilesets: withTilesets)
    }

    /**
     Returns an array of all child layers, sorted by index (first is lowest, last is highest).

     - returns: `[SKTiledLayerObject]` array of layers.
     */
    @available(*, deprecated, message: "use `getLayers()` instead")
    public func allLayers() -> [SKTiledLayerObject] {
        return layers.sorted(by: { $0.index < $1.index })
    }

    /**
     Returns a named tile layer from the layers set.

     - parameter name: `String` tile layer name.
     - returns: `SKTiledLayerObject?` layer object.
     */
    @available(*, deprecated, message: "use `getLayers(named:)` instead")
    public func getLayer(named layerName: String) -> SKTiledLayerObject? {
        if let index = layers.index(where: { $0.name == layerName }) {
            let layer = layers[index]
            return layer
        }
        return nil
    }

    /**
     Returns a named tile layer if it exists, otherwise, nil.

     - parameter named: `String` tile layer name.
     - returns: `SKTileLayer?`
     */
    @available(*, deprecated, message: "use `tileLayers(named:)` instead")
    public func tileLayer(named name: String) -> SKTileLayer? {
        if let layerIndex = tileLayers().index(where: { $0.name == name }) {
            let layer = tileLayers()[layerIndex]
            return layer
        }
        return nil
    }

    /**
     Returns a named object group if it exists, otherwise, nil.

     - parameter named: `String` tile layer name.
     - returns: `SKObjectGroup?`
     */
    @available(*, deprecated, message: "use `objectGroups(named:)` instead")
    public func objectGroup(named name: String) -> SKObjectGroup? {
        if let layerIndex = objectGroups().index(where: { $0.name == name }) {
            let layer = objectGroups()[layerIndex]
            return layer
            }
        return nil
    }

    /**
     Output a summary of the current scenes layer data.

     - parameter reverse: `Bool` reverse layer order.
     */
    @available(*, deprecated, message: "use `dumpStatistics` instead")
    public func debugLayers(reverse: Bool = false) {
        dumpStatistics()
    }

    /// Minimum zoom level for the map.
    @available(*, deprecated, renamed: "SKTilemap.zoomConstraints.min")
    public var minZoom: CGFloat {
        get {
            return zoomConstraints.min
        } set {
            zoomConstraints.min = newValue
        }
    }

    /// Maximum zoom level for the map.
    @available(*, deprecated, renamed: "SKTilemap.zoomConstraints.max")
    public var maxZoom: CGFloat {
        get {
            return zoomConstraints.max
        } set {
            zoomConstraints.max = newValue
        }
    }
}
