//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
import GameplayKit


/// String representing Tiled application version.
public var SKTiledTiledApplicationVersion: String = "0"

/// Global logging level.
public var SKTiledLoggingLevel: LoggingLevel = .info

/// Global device scaling factor for retina displays.
public var SKTiledContentScaleFactor: CGFloat = getContentScaleFactor()


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
internal enum StaggerIndex: String {
    case odd
    case even
}


//  Common tile size aliases
internal let TileSizeZero  = CGSize(width: 0, height: 0)
internal let TileSize8x8   = CGSize(width: 8, height: 8)
internal let TileSize16x16 = CGSize(width: 16, height: 16)
internal let TileSize32x32 = CGSize(width: 32, height: 32)


/**
 ## Overview ##

 The `SKTilemapDelegate` protocol defines a delegate that allows the user to interact with a tile map as it is being created and customize its properties.


 ## Callbacks ##

 Delegate callbacks are called asynchronously as the map is being read from disk and rendered.

 ```swift
 SKTilemapDelegate.didBeginParsing(_ tilemap: SKTilemap)
 SKTilemapDelegate.didAddTileset(_ tileset: SKTileset)
 SKTilemapDelegate.didAddLayer(_ layer: SKTiledLayerObject)
 SKTilemapDelegate.didReadMap(_ tilemap: SKTilemap)
 SKTilemapDelegate.didRenderMap(_ tilemap: SKTilemap)
 ```

 ## Custom Objects ##

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
 ## Overview

 The `SKTilemap` class defines a container for managing layers, tiles (sprites),
 vector objects & images. Tile data is stored in `SKTileset` tile sets.

 ### Usage

 Maps can be loaded with the class function `SKTilemap.load(tmxFile:)`:

 ```swift
 if let tilemap = SKTilemap.load(tmxFile: "myfile.tmx") {
    scene.addChild(tilemap)
 }
 ```

 ### Properties



 ```swift
 let mapSize    = tilemap.size          // returns the size of the map (tiles).
 let renderSize = tilemap.sizeInPoints  // returns the size of the map (pixels).
 let tileSize   = tilemap.tileSize      // returns the map tile size (pixels).
 ```
 */
public class SKTilemap: SKNode, SKTiledObject {
    /**
     ## Overview

     Enum describing map orientation type.
     */
    public enum TilemapOrientation: String {
        case orthogonal
        case isometric
        case hexagonal
        case staggered
    }

    /// File path.
    public var url: URL!
    /// Unique id.
    public var uuid: String = UUID().uuidString
    /// Tiled application version.
    public var tiledversion: String!
    public var properties: [String: String] = [:]                   // custom properties
    public var type: String!                                        // map type
    public var displayName: String!                                 // map display name
    /// Size of map (in tiles).
    public var size: CGSize
    /// Tile size (in pixels).
    public var tileSize: CGSize
    /// Map orientation type.
    public var orientation: TilemapOrientation                      // map orientation
    internal var renderOrder: RenderOrder = .rightDown              // render order

    // Update time properties.
    private var lastUpdateTime : TimeInterval = 0
    private let maximumUpdateDelta: TimeInterval = 1.0 / 60.0

    /// Logging verbosity.
    internal var loggingLevel: LoggingLevel = SKTiledLoggingLevel

    internal var maxRenderQuality: CGFloat = 16                     // max render quality
    /// Scaling value for text objects, etc.
    public var renderQuality: CGFloat = 8 {                         // object render quality.
        didSet {
            guard renderQuality != oldValue else { return }
            layers.forEach { $0.renderQuality = renderQuality.clamped(1, maxRenderQuality) }
        }
    }

    // Set the speed of child layers
    override public var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.layers.forEach {$0.speed = speed}
        }
    }

    // hexagonal
    public var hexsidelength: Int = 0                               // hexagonal side length
    internal var staggeraxis: StaggerAxis = .y                      // stagger axis
    internal var staggerindex: StaggerIndex = .odd                  // stagger index.

    // camera/scene
    public var bounds: CGRect = .zero                               // current bounds
    public var worldScale: CGFloat = 1.0                            // initial world scale
    public var currentZoom: CGFloat = 1.0                           // zoom level

    /// Allow camera zoom.
    public var allowZoom: Bool = true
    /// Allow camera movement.
    public var allowMovement: Bool = true
    /// Minimum zoom level for the map.
    public var minZoom: CGFloat = 0.2
    /// Mximum zoom level for the map.
    public var maxZoom: CGFloat = 5.0

    /// Ignore custom properties.
    public var ignoreProperties: Bool = false

    /// Current tilesets.
    public var tilesets: Set<SKTileset> = []

    // current layers
    private var _layers: Set<SKTiledLayerObject> = []               // tile map layers
    /// Layer count.
    public var layerCount: Int { return self.layers.count }

    /// Default z-position range between layers.
    public var zDeltaForLayers: CGFloat = 50
    public var bufferSize: CGFloat = 4.0

    /// Returns true if all of the child layers are rendered.
    internal var isRendered: Bool {
        return layers.filter { $0.isRendered == false }.isEmpty
    }

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

    /// Debug visualization options.
    public var debugDrawOptions: DebugDrawOptions {
        get {
            return defaultLayer.debugDrawOptions
        } set {
            defaultLayer.debugDrawOptions = newValue
        }
    }

    /// Overlay color.
    public var overlayColor: SKColor = SKColor(hexString: "#40000000")

    // MARK: - Object Colors
    public var objectColor: SKColor = SKColor.gray
    public var color: SKColor = SKColor.clear                           // used for pausing
    public var gridColor: SKColor = TiledObjectColors.obsidian          // color used to visualize the tile grid
    public var frameColor: SKColor = TiledObjectColors.obsidian         // bounding box color
    public var highlightColor: SKColor = TiledObjectColors.lime         // color used to highlight tiles
    public var navigationColor: SKColor = TiledObjectColors.lime        // navigation graph color.
    internal var autoResize: Bool = false                               // indicates map should auto-resize when view changes

    /// dynamics
    public var gravity: CGVector = CGVector.zero

    /// Weak reference to `SKTilemapDelegate` delegate
    weak public var delegate: SKTilemapDelegate?
    /// Objects under the mouse cursor.
    public var focusObjects: [SKNode] = []
    
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
    public var tileOverlap: CGFloat = 0.5 {
        didSet {
            guard oldValue != tileOverlap else { return }
            for tileLayer in tileLayers(recursive: true) {
                tileLayer.setTileOverlap(tileOverlap)
            }
        }
    }

    /// Global property to show/hide all `SKTileObject` objects.
    public var showObjects: Bool = false {
        didSet {
            guard oldValue != showObjects else { return }
            for objectGroup in objectGroups(recursive: true) {
                objectGroup.showObjects = showObjects
            }
        }
    }

    /**
     Show objects for the given layers.

     - parameter forLayers: `[SKTiledLayerObject]` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    public func showObjects(forLayers: [SKTiledLayerObject]) {

    }

    /**
     Return all tile layers. If recursive is false, only returns top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    public func tileLayers(recursive: Bool=true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKTileLayer != nil } as! [SKTileLayer]
    }

    /**
     Return all object groups. If recursive is false, only returns top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKObjectGroup]` array of object groups.
     */
    public func objectGroups(recursive: Bool=true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKObjectGroup != nil } as! [SKObjectGroup]
    }

    /**
     Return all image layers. If recursive is false, only returns top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKImageLayer]` array of image layers.
     */
    public func imageLayers(recursive: Bool=true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKImageLayer != nil } as! [SKImageLayer]
    }

    /**
     Return all group layers. If recursive is false, only returns top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKGroupLayer]` array of image layers.
     */
    public func groupLayers(recursive: Bool=true) -> [SKGroupLayer] {
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
     Load a Tiled tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.

     - parameter filename:           `String` Tiled file name.
     - parameter inDirectory:        `String?` search path for assets.
     - parameter delegate:           `SKTilemapDelegate?` optional [`SKTilemapDelegate`](Protocols/SKTilemapDelegate.html) instance.
     - parameter withTilesets:       `[SKTileset]?` optional tilesets.
     - parameter ignoreProperties:   `Bool` ignore custom properties from Tiled.
     - parameter loggingLevel:       `LoggingLevel` logging verbosity level.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(tmxFile: String,
                           inDirectory: String? = nil,
                           delegate: SKTilemapDelegate? = nil,
                           withTilesets: [SKTileset]? = nil,
                           ignoreProperties noparse: Bool = false,
                           loggingLevel: LoggingLevel = .info) -> SKTilemap? {


        let startTime = Date()
        let queue = DispatchQueue(label: "com.sktiled.renderqueue", qos: .userInteractive)
        if let tilemap = SKTilemapParser().load(tmxFile: tmxFile,
                                                inDirectory: inDirectory,
                                                delegate: delegate,
                                                withTilesets: withTilesets,
                                                ignoreProperties: noparse,
                                                loggingLevel: loggingLevel,
                                                renderQueue: queue) {



            let renderTime = Date().timeIntervalSince(startTime)
            let timeStamp = String(format: "%.\(String(3))f", renderTime)
            Logger.default.log("tilemap \"\(tilemap.mapName)\" rendered in: \(timeStamp)s", level: .success)
            return tilemap
        }
        return nil
    }

    // MARK: - Init
    /**
     Initialize with dictionary attributes from xml parser.

     - parameter attributes: `Dictionary` attributes dictionary.
     - returns: `SKTileMapNode?`
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
            guard let hexindex: StaggerIndex = StaggerIndex(rawValue: hexIndex) else {
                fatalError("stagger index \"\(hexIndex)\" not supported.")
            }
            self.staggerindex = hexindex
        }

        // Tiled application version
        if let tiledVersion = attributes["tiledversion"] {
            self.tiledversion = tiledVersion
            SKTiledTiledApplicationVersion = tiledVersion
        }

        // global antialiasing
        antialiasLines = (currentZoom < 1)
        super.init()

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
        let largestDimension = (renderSize.width > renderSize.height) ? renderSize.width : renderSize.height
        maxRenderQuality = CGFloat(Int(16000 / (largestDimension * SKTiledContentScaleFactor)))

        // clamp max render quality
        maxRenderQuality = (maxRenderQuality > 16) ? 16 : maxRenderQuality

        #if os(iOS)
        renderQuality = maxRenderQuality / 4
        #else
        renderQuality = maxRenderQuality / 2
        #endif
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
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    // MARK: Coordinates
    /**
     Returns a point for a given coordinate in the layer, with optional offset values for x/y.

     - parameter coord:   `CGPoint` tile coordinate.
     - parameter offsetX: `CGFloat` x-offset value.
     - parameter offsetY: `CGFloat` y-offset value.
     - returns: `CGPoint` point in layer.
     */
    public func pointForCoordinate(coord: CGPoint, offsetX: CGFloat=0, offsetY: CGFloat=0) -> CGPoint {
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

    // MARK: - Layers
    /**
     Returns an array of child layers, sorted by index (first is lowest, last is highest).

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTiledLayerObject]` array of layers.
     */
    public func getLayers(recursive: Bool=true) -> [SKTiledLayerObject] {
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
        return layers.flatMap { $0.name }
    }

    /**
     Add a layer to the current layers set. Automatically sets zPosition based on the `SKTilemap.zDeltaForLayers` property. If the `group` argument is not nil, layer will be added to the group instead.

     - parameter layer:    `SKTiledLayerObject` layer object.
     - parameter group:    `SKGroupLayer?` optional group layer.
     - parameter clamped:  `Bool` clamp position to nearest pixel.
     - returns: `(success: Bool, layer: SKTiledLayerObject)` add was successful, layer added.
     */
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
    public func getLayers(named layerName: String, recursive: Bool=true) -> [SKTiledLayerObject] {
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
    public func getLayers(withPrefix: String, recursive: Bool=true) -> [SKTiledLayerObject] {
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
    public func getLayers(ofType: String, recursive: Bool=true) -> [SKTiledLayerObject] {
        return getLayers(recursive: recursive).filter { $0.type != nil }.filter { $0.type! == ofType }
    }

    /**
     Return tile layers matching the given name. If recursive is false, only returns top-level layers.

     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    public func tileLayers(named layerName: String, recursive: Bool=true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKTileLayer != nil }.filter { $0.name == layerName } as! [SKTileLayer]
    }

    /**
     Return tile layers with names matching the given prefix. If recursive is false, only returns top-level layers.

     - parameter withPrefix: `String` prefix to match.
     - parameter recursive:  `Bool` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    public func tileLayers(withPrefix: String, recursive: Bool=true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKTileLayer != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKTileLayer]
    }

    /**
     Returns a tile layer at the given index, otherwise, nil.

     - parameter atIndex: `Int` layer index.
     - returns: `SKTileLayer?` matching tile layer.
     */
    public func tileLayer(atIndex index: Int) -> SKTileLayer? {
        if let layerIndex = tileLayers(recursive: false).index(where: { $0.index == index } ) {
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
    public func objectGroups(named layerName: String, recursive: Bool=true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).filter { $0 as? SKObjectGroup != nil }.filter { $0.name == layerName } as! [SKObjectGroup]
    }

    /**
     Return object groups with names matching the given prefix. If recursive is false, only returns top-level layers.

     - parameter withPrefix: `String` prefix to match.
     - parameter recursive:  `Bool` include nested layers.
     - returns: `[SKObjectGroup]` array of object groups.
     */
    public func objectGroups(withPrefix: String, recursive: Bool=true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).filter { $0 as? SKObjectGroup != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKObjectGroup]
    }

    /**
     Returns an object group at the given index, otherwise, nil.

     - parameter atIndex: `Int` layer index.
     - returns: `SKObjectGroup?` matching group layer.
     */
    public func objectGroup(atIndex index: Int) -> SKObjectGroup? {
        if let layerIndex = objectGroups(recursive: false).index(where: { $0.index == index } ) {
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
    public func imageLayers(named layerName: String, recursive: Bool=true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKImageLayer != nil }.filter { $0.name == layerName } as! [SKImageLayer]
    }

    /**
     Return image layers with names matching the given prefix. If recursive is false, only returns top-level layers.

     - parameter withPrefix: `String` prefix to match.
     - parameter recursive:  `Bool` include nested layers.
     - returns: `[SKImageLayer]` array of image layers.
     */
    public func imageLayers(withPrefix: String, recursive: Bool=true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKImageLayer != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKImageLayer]
    }

    /**
     Returns an image layer at the given index, otherwise, nil.

     - parameter atIndex: `Int` layer index.
     - returns: `SKImageLayer?` matching image layer.
     */
    public func imageLayer(atIndex index: Int) -> SKImageLayer? {
        if let layerIndex = imageLayers(recursive: false).index(where: { $0.index == index } ) {
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
    public func groupLayers(named layerName: String, recursive: Bool=true) -> [SKGroupLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKGroupLayer != nil }.filter { $0.name == layerName } as! [SKGroupLayer]
    }

    /**
     Return group layers with names matching the given prefix. If recursive is false, only returns top-level layers.

     - parameter withPrefix:  `String` prefix to match.
     - parameter recursive:   `Bool` include nested layers.
     - returns: `[SKGroupLayer]` array of group layers.
     */
    public func groupLayers(withPrefix: String, recursive: Bool=true) -> [SKGroupLayer] {
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
            let scaleFactor = SKTiledContentScaleFactor
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
    internal func positionNode(_ node: SKNode, clamped: Bool = true, offset: CGPoint = .zero) {

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
            let scaleFactor = SKTiledContentScaleFactor
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
        return tileLayers(recursive: true).flatMap { $0.tileAt(coord: coord) }
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
    public func getTiles(recursive: Bool=true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles() }
    }

    /**
     Returns tiles with a property of the given type. If recursive is false, only returns tiles from top-level layers.

     - parameter ofType:    `String` type.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(ofType: String, recursive: Bool=true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles(ofType: ofType) }
    }

    /**
     Returns tiles with the given global id. If recursive is false, only returns tiles from top-level layers.

     - parameter globalID:  `Int` tile globla id.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(globalID: Int, recursive: Bool=true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles(globalID: globalID) }
    }

    /**
     Returns tiles with a property of the given type & value. If recursive is false, only returns tiles from top-level layers.

     - parameter named: `String` property name.
     - parameter value: `Any` property value.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTilesWithProperty(_ named: String, _ value: Any, recursive: Bool=true) -> [SKTile] {
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
    public func animatedTiles(recursive: Bool=true) -> [SKTile] {
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
    public func getObjects(recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects() }
    }

    /**
     Return objects matching a given type. If recursive is false, only returns objects from top-level layers.

     - parameter ofType:    `String` object type to query.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(ofType: String, recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(ofType: ofType) }
    }

    /**
     Return objects matching a given name. If recursive is false, only returns objects from top-level layers.

     - parameter named:     `String` object name to query.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(named: String, recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(named: named) }
    }

    /**
     Return objects with the given text value. If recursive is false, only returns objects from top-level layers.

     - parameter withText:   `String` text value.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(withText text: String, recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(withText: text) }
    }

    /**
     Returns an object with the given id.

     - parameter id: `Int` Object id.
     - returns: `SKTileObject?`
     */
    public func getObject(withID id: Int) -> SKTileObject? {
        return objectGroups(recursive: true).flatMap { $0.getObject(withID: id) }.first
    }

    /**
     Return objects with a tile id. If recursive is false, only returns objects from top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` objects with a tile gid.
     */
    public func tileObjects(recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.tileObjects() }
    }

    /**
     Return text objects. If recursive is false, only returns objects from top-level layers.

     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` text objects.
     */
    public func textObjects(recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.textObjects() }
    }

    // MARK: - Coordinates
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

    // MARK: - Callbacks
    /**
     Called when parser has finished reading the map.

     - parameter timeStarted: `Date` render start time.
     - parameter tasks:       `Int`  number of tasks to complete.
     */
    public func didFinishParsing(timeStarted: Date, tasks: Int=0) {}

    /**
     Called when parser has finished rendering the map.

     - parameter timeStarted: `Date` render start time.
     */
    public func didFinishRendering(timeStarted: Date) {
        log("rendering finished!", level: .debug)

        // set the z-depth of the defaultLayer & background sprite
        defaultLayer.zPosition = -zDeltaForLayers

        // transfer attributes
        scene?.physicsWorld.gravity = gravity

        // delegate callback
        defer {
            self.delegate?.didRenderMap(self)
        }

        // clamp the position of the map & parent nodes
        clampPositionWithNode(node: self, scale: getContentScaleFactor())
    }

    // MARK: - Updating

    /**
     Update the map as each frame is rendered.

     - parameter currentTime: `TimeInterval` update interval.
     */
    public func update(_ currentTime: TimeInterval) {
        // Initialize lastUpdateTime
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }

        // Calculate time since last update
        var dt = currentTime - self.lastUpdateTime
        dt = dt > maximumUpdateDelta ? maximumUpdateDelta : dt

        self.lastUpdateTime = currentTime

        // Update layers
        self.layers.forEach { layer in
            layer.update(dt)
        }
    }
}


// MARK: - Extensions

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

    /// String representing the map name.
    public var mapName: String {
        if let displayName = self.displayName {
            return displayName
        }
        return self.name ?? "null"
    }

    /// Auto-sizing property for map orientation.
    internal var isPortrait: Bool {
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
        return staggerX && Bool((x & 1) ^ staggerEven.hashValue)
    }

    /**
     Returns true if the given y-coordinate represents a staggered (offset) row.

     - parameter x:  `Int` map y-coordinate.
     - returns: `Bool` row should be staggered.
     */
    internal func doStaggerY(_ y: Int) -> Bool {
        return !staggerX && Bool((y & 1) ^ staggerEven.hashValue)
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

    /// String representation of the map.
    override public var description: String {
        let sizedesc = "\(sizeInPoints.shortDescription): (\(size.shortDescription) @ \(tileSize.shortDescription))"
        guard isRendered == true else {
            return "Map: \(mapName), \(sizedesc)"
        }
        return "Map: \(mapName), \(sizedesc), \(tileCount) tiles"
    }

    /// Debug string representation of the map.
    override public var debugDescription: String { return description }

    /**
     Returns an array of tiles/objects.

     - returns: `[SKNode]` array of child objects.
     */
    public func renderableObjects() -> [SKNode] {
        var result: [SKNode] = []
        enumerateChildNodes(withName: "*") { node, stop in
            if (node as? SKTile != nil) || (node as? SKTileObject != nil) {
                result.append(node)
            }
        }
        return result
    }

    /**
     Dump a summary of the current tilemap's layer statistics.

     - parameter defaul: `Bool` include the map's default layer.
     */
    public func mapStatistics(default: Bool = false) {
        guard (layerCount > 0) else {
            print("# Tilemap \"\(mapName)\": 0 Layers")
            return
        }

        // collect graphs for each tile layer
        let graphs = tileLayers().flatMap { $0.graph }

        // format the header
        let graphsString = (graphs.isEmpty == false) ? (graphs.count > 1) ? " : \(graphs.count) Graphs" : " : \(graphs.count) Graph" : ""
        let headerString = "# Tilemap \"\(mapName)\": \(tileCount) Tiles: \(layerCount) Layers\(graphsString)"
        let titleUnderline = String(repeating: "-", count: headerString.characters.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        var allLayers = self.layers.filter { $0 as? BackgroundLayer == nil }

        if (`default` == true) {
            allLayers.insert(self.defaultLayer, at: 0)
        }

        // grab the stats from each layer
        let allLayerStats = allLayers.map { $0.layerStatsDescription }

        // prefix for each column
        var prefixes: [String] = ["", "", "", "", "pos", "size", "offset", "anc", "zpos", "opac", "nav"]

        // buffer for each column
        var buffers: [Int] = [1, 2, 0, 0, 1, 1, 1, 1, 1, 1, 1]
        var columnSizes: [Int] = Array(repeating: 0, count: prefixes.count)

        // get the max column size for each column
        for (_, stats) in allLayerStats.enumerated() {
            for stat in stats {
                let cindex = Int(stats.index(of: stat)!)

                let colCharacters = stat.characters.count
                let prefix = prefixes[cindex]
                let buffer = buffers[cindex]

                // if the current stat has characters
                if colCharacters > 0 {

                    // get the prefix size + buffer
                    let bufferSize = (prefix.characters.count > 0) ? prefix.characters.count + buffer : 2

                    // this is the size of the column + prefix
                    let columnSize = colCharacters + bufferSize

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
                if (stat.characters.count > 0) {
                    emptyBuffer = 0
                    prefix = prefixes[sidx]
                    if (prefix.characters.count > 0) {
                        divider = ": "
                        // for all columns but the last, add a comma
                        if (isLastColumn == false) {
                            comma = (nextValue == "") ? "" : ", "
                        }
                        prefix = "\(prefix)\(divider)"
                    }

                    currentColumnValue = "\(prefix)\(stat)\(comma)"
                }

                let fillSize = columnSize + comma.characters.count + buffer + emptyBuffer
                // pad each string to the right
                layerOutputString += currentColumnValue.zfill(length: fillSize, pattern: " ", padLeft: false)
            }
            outputString += "\n\(layerOutputString)"
        }

        print("\n\n" + outputString + "\n\n")
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

    public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {}

    public func cameraPositionChanged(newPosition: CGPoint) {
        // clamp the position of the map & parent nodes
        clampPositionWithNode(node: self, scale: getContentScaleFactor())
    }

    public func cameraZoomChanged(newZoom: CGFloat) {
        //let oldZoom = currentZoom
        currentZoom = newZoom
        antialiasLines = (newZoom < 1)

        // clamp the position of the map & parent nodes
        clampPositionWithNode(node: self, scale: getContentScaleFactor())
    }

    #if os(iOS) || os(tvOS)
    public func sceneDoubleTapped(location: CGPoint) {}
    #else

    public func sceneDoubleClicked(event: NSEvent) {
        let coord = coordinateAtMouseEvent(event: event)
        let tiles = tilesAt(coord: coord)
        log("\(tiles.count) tiles found at \(coord.shortDescription)", level: .debug)
    }

    public func mousePositionChanged(event: NSEvent) {
        let coord = coordinateAtMouseEvent(event: event)
        let locationInMap = event.location(in: self)
        //let locationInLayer = mouseLocation(event: event)

        let nodesUnderCursor = nodes(at: locationInMap)

        focusObjects = []
        for node in nodesUnderCursor {
            if node is SKTileObject {
                focusObjects.append(node)
            }

            if let tile = node as? SKTile, (tile.texture != nil) {
                if tilesAt(coord: coord).contains(tile) {
                    focusObjects.append(node)
                }
            }
        }
    }
    #endif
}


extension TiledObjectColors {

    static let all: [SKColor] = [coral, crimson, english, saffron,
                                 tangerine, dandelion, azure, turquoise,
                                 lime, pear, grass, indigo, metal, gun]
    /// Returns a random color.
    static var random: SKColor {
        let randIndex = Int(arc4random_uniform(UInt32(TiledObjectColors.all.count)))
        return TiledObjectColors.all[randIndex]
    }
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
     */
    @available(*, deprecated, message: "use `mapStatistics(default:)` instead")
    public func debugLayers(reverse: Bool=false) {
        mapStatistics()
    }
}
