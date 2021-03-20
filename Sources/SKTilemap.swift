//
//  SKTilemap.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
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
import GameplayKit


/// Object rendering order.
internal enum RenderOrder: String {
    case rightDown  = "right-down"
    case rightUp    = "right-up"
    case leftDown   = "left-down"
    case leftUp     = "left-up"
}

/// Alignment hint used to position the layers within the `SKTilemap` node.
///
///  - `bottomLeft`:   node bottom left rests at map zero point (0).
///  - `center`:       node center rests at parent zero point (0.5).
///  - `topRight`:     node top right rests at parent zero point. (1).
internal enum LayerPosition {
    case bottomLeft
    case center
    case topRight
}


/// The `TileUpdateMode` enumeration dictates how the tilemap updates its tiles in your scene. Changing this property can drastically affect your CPU usage, so use it carefully.
///
/// The default mode is `TileUpdateMode.actions`, which should be used for the best performance. In this mode, animated tiles are animated with [**SpriteKit actions**][skaction-url].
///
/// If `full` mode is used, each tile (animated or otherwise) is updated **every frame**. This ensures accuracy in syncronizing frames.
///
/// - Important:
///  If `dynamic` or `full` mode is selected, the `SKTilemap` node **must** be included in your scene's main update loop to render properly.
///
/// ### Usage
///
/// ```swift
/// // passing the tile update mode to the load function
/// if let tilemap = SKTilemap.load(tmxFile: "MyFile.tmx", updateMode: TileUpdateMode.dynamic) {
///     scene.addChild(tilemap)
/// }
///
/// // updating the attribute on the tilemp node
/// tilemap.updateMode = TileUpdateMode.actions
/// ```
///
/// ### Properties
///
/// - `dynamic`: dynamically update tiles as needed.
/// - `full`: **all** tiles are updated each frame.
/// - `actions`: tiles are not updated, SpriteKit actions are used instead.
///
/// [skaction-url]:https://developer.apple.com/documentation/spritekit/getting_started_with_actions
public enum TileUpdateMode: UInt8 {
    case dynamic                    // dynamically update tiles as needed
    case full                       // all tiles updated
    case actions                    // use SpriteKit actions (no update)
}


/// The `TiledGeometryIsolationMode` optionset controls what renderable content will be shown at any given time.
///
/// ### Properties
///
/// - `none`: all object/tile types are shown.
/// - `tiles`: oOnly tiles are shown.
/// - `objects`: only objects are shown.
/// - `layers`: only layers are shown.
/// - `tileObjects`: only [tile objects][tile-objects-url] are shown.
/// - `textObjects`: only text objects are shown.
/// - `pointObjects`: only point objects are shown.
///
/// [tile-objects-url]:../working-with-objects.html#tile-objects
public struct TiledGeometryIsolationMode: OptionSet {

    public let rawValue: UInt8

    public static let none          = TiledGeometryIsolationMode(rawValue: 1 << 0)
    public static let tiles         = TiledGeometryIsolationMode(rawValue: 1 << 1)
    public static let objects       = TiledGeometryIsolationMode(rawValue: 1 << 2)
    public static let layers        = TiledGeometryIsolationMode(rawValue: 1 << 3)
    public static let tileObjects   = TiledGeometryIsolationMode(rawValue: 1 << 4)
    public static let textObjects   = TiledGeometryIsolationMode(rawValue: 1 << 5)
    public static let pointObjects  = TiledGeometryIsolationMode(rawValue: 1 << 6)

    public static let all: TiledGeometryIsolationMode = [.none, .tiles, .objects, .layers, .tileObjects, .textObjects, pointObjects]
    public static let allTiles: TiledGeometryIsolationMode = [.tiles, .tileObjects]
    public static let allObjects: TiledGeometryIsolationMode = [.objects, .tileObjects, .textObjects, pointObjects]

    /// Initialize with a raw integer value.
    ///
    /// - Parameter rawValue: unsigned integer value.
    public init(rawValue: UInt8 = 0) {
        self.rawValue = rawValue
    }
}


/// The `SKTilemap` class is a mappable container for managing layers of tiles (sprites),
/// vector objects & images. Tile data is stored in [`SKTileset`][tileset-url] tile sets.
///
/// ### Usage
///
/// Maps can be loaded with the class function `SKTilemap.load(tmxFile:)`:
///
/// ```swift
/// if let tilemap = SKTilemap.load(tmxFile: "MyFile.tmx") {
///     scene.addChild(tilemap)
/// }
/// ```
///
/// ### Properties
///
/// - `mapSize`: Size of the map (in tiles).
/// - `tileSize`: Map tile size (in pixels).
/// - `sizeInPoints`: Size of the map in pixels.
/// - `orientation`: Map orientation (orthogonal, isometric, etc).
/// - `boundingRect`: Map bounding rect.
/// - `tilesets`: Array of stored tileset instances.
/// - `allowZoom`: Allow camera zooming.
/// - `layers`: Array of child layers.
///
///
/// For more information, see the [**Working with Maps**][tilemap-doc-url] page in the [**official documentation**][sktiled-docroot-url].
///
/// [tilemap-doc-url]:https://mfessenden.github.io/SKTiled/1.3/working-with-maps.html
/// [sktiled-docroot-url]:https://mfessenden.github.io/SKTiled/1.3/index.html
/// [tileset-url]:SKTileset.html
public class SKTilemap: SKNode, CustomReflectable, TiledMappableGeometryType, TiledObjectType {

    // MARK: - File Properties

    /// Tilemap source file path.
    public internal(set) var url: URL!

    /// Tilemap source file path, relative to the bundle.
    public internal(set) var relativeUrl: URL!

    /// Map container display name. Defaults to the current map source file name (minus the tmx extension).
    public var displayName: String?
    
    // MARK: - Tilesets

    /// Array of tilesets associated with this map.
    public var tilesets: Set<SKTileset> = []

    // MARK: - Basic Properties

    /// Unique SpriteKit node id.
    public internal(set) var uuid: String = UUID().uuidString

    /// Indicates the Tiled application version this map was created with.
    public internal(set) var tiledversion: String!

    /// Indicates the Tiled map version.
    public internal(set) var mapversion: String!

    /// Map data encoding type.
    internal var encoding: TilemapEncoding = TilemapEncoding.unknown

    /// Map data compression type.
    internal var compression: TilemapCompression = TilemapCompression.unknown

    /// Reference to `TilemapDelegate` delegate.
    public weak var delegate: TilemapDelegate?

    /// Custom **Tiled** properties.
    public var properties: [String: String] = [:]

    /// :nodoc: Private **Tiled** properties.
    public var _tiled_properties: [String: String] = [:]

    /// If enabled, custom **Tiled** properties are ignored.
    public var ignoreProperties: Bool = false
    
    /// Default z-position range between layers.
    public var zDeltaForLayers: CGFloat = TiledGlobals.default.zDeltaForLayers

    /// Indicates the map type is infinite.
    @objc public internal(set) var isInfinite: Bool = false

    /// Tilemap mode type.
    public var type: String!

    /// Returns true if all of the child layers are rendered.
    public internal(set) var isRendered: Bool = false

    /// Returns the time taken to parse the map and dependencies.
    public internal(set) var parseTime: TimeInterval = 0

    /// Returns the render time of this map.
    public internal(set) var renderTime: TimeInterval = 0

    /// Size of map (in tiles).
    public internal(set) var mapSize: CGSize

    /// Tile size (in pixels).
    public internal(set) var tileSize: CGSize

    /// Chunk size (infinite maps).
    public internal(set) var chunkSize: CGSize?

    /// Storage for tile data.
    internal var dataStorage: TileDataStorage?
    
    /// Current focus coordinate.
    public var currentCoordinate = simd_int2(0, 0) {
        didSet {
            guard (oldValue != currentCoordinate) else {
                return
            }
            
            if (TiledGlobals.default.enableTilemapNotifications == true) {
                
                let isValidCoord = isValid(coord: currentCoordinate)
                onCoordinateChange?(oldValue, currentCoordinate, isValidCoord)
            }
        }
    }
    
    // MARK: - Layers

    
    /// Array of layers contained in this map. This includes private layers (such as `SKTilemap.defaultLayer`)
    private var _layers: Set<TiledLayerObject> = []
    
    /// Returns a flattened array of contained child layers.
    public var layers: [TiledLayerObject] {
        var result: [TiledLayerObject] = []
        for layer in _layers.sorted(by: { $0.index > $1.index }) where layer as? TiledBackgroundLayer == nil {
            result += layer.layers
        }
        return result
    }
        
    /// Returns the number of layers contained in this map.
    public var layerCount: Int {
        return self.layers.count
    }
    
    /// The tile map default layer, used for displaying the current grid, getting coordinates, etc.
    internal lazy var defaultLayer: TiledBackgroundLayer = { [unowned self] in
        let layer = TiledBackgroundLayer(tilemap: self)
        _ = self.addLayer(layer)
        layer.didFinishRendering()
        return layer
    }()
    
    /// Pause overlay.
    public lazy var overlay: SKSpriteNode = { [unowned self] in
        let pauseOverlayColor = SKColor.clear
        let overlayNode = SKSpriteNode(color: pauseOverlayColor, size: self.sizeInPoints)
        overlayNode.name = "MAP_OVERLAY"
        
        #if SKTILED_DEMO
        overlayNode.setAttr(key: "tiled-node-name", value: "overlay")
        #endif
        
        self.addChild(overlayNode)
        overlayNode.zPosition = self.lastZPosition * self.zDeltaForLayers
        overlayNode.isHidden = (self.isPaused == false)
        return overlayNode
    }()
    
    
    /// Overlay color.
    public var overlayColor: SKColor = SKColor(hexString: "#40000000") {
        didSet {
            drawOverlay()
        }
    }
    
    /// Overlay transparency amount.
    public var overlayOpacity: CGFloat = 0.4 {
        didSet {
            drawOverlay()
        }
    }
    
    /// Redraw the map overlay.
    internal func drawOverlay() {
        overlay.color = overlayColor.withAlphaComponent(overlayOpacity)
    }
    
    
    /// Isolated layers.
    public var isolatedLayers: [TiledLayerObject]?  {
        didSet {
            guard let isolated = isolatedLayers else {
                layers.forEach({ layer in
                    layer.isIsolated = false
                    // TODO: need to stash previous `isHidden` value
                    layer.isHidden = false
                })
                
                NotificationCenter.default.post(
                    name: Notification.Name.Map.Updated,
                    object: self
                )
                
                return
            }

            var alreadyIsolated: [TiledLayerObject] = []
            
            
            for layer in layers {
                
                if let chunk = layer as? SKTileLayerChunk {
                    print("chunk: '\(chunk.xPath)'")
                }
                
                
                // if this layer is part of the isolated array...
                let isolateThisLayer = isolated.contains(layer)
                
                if (isolateThisLayer == false) {
                    if (alreadyIsolated.contains(layer) == true) {
                        continue
                    }
                }
                
                alreadyIsolated.append(layer)
                
                
                // if this is a group layer, we need to show child layers
                let isGroupLayer = (layer as? SKGroupLayer != nil)
                let hideThisLayer = isolateThisLayer == false
                
                // we need to set these visible so the current layer can be seen...
                var layersToProtect = Set(layer.parentLayers)
                
                // if this is a group layer, we need to also see all of the current child layers
                if (isGroupLayer == true) {
                    
                    for child in layer.childLayers {
                        layersToProtect.insert(child)
                    }
                }
                
                // isolate the layer...
                layer.isIsolated = isolateThisLayer
                layer.isHidden = hideThisLayer
                
                for relative in layersToProtect.filter({ $0 != layer && $0 as? SKTileLayerChunk == nil }) {
                    relative.isHidden = hideThisLayer
                    alreadyIsolated.append(relative)
                }
            }
            
            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: self
            )
        }
    }
    
    
    // MARK: - Background Properties
    
    /// Optional background color (parsed from the source tmx file).
    public var backgroundColor: SKColor? = nil {
        didSet {
            self.defaultLayer.color = (backgroundColor != nil) ? backgroundColor! : SKColor.clear
            self.defaultLayer.colorBlendFactor = (backgroundColor != nil) ? 1.0 : 0
        }
    }
    
    /// Background opactiy.
    public var backgroundOpacity: CGFloat = 1 {
        didSet {
            self.defaultLayer.opacity = backgroundOpacity
        }
    }
    
    /// Ignore Tiled background color.
    public var ignoreBackground: Bool = false {
        didSet {
            defaultLayer.colorBlendFactor = (ignoreBackground == false) ? 1.0 : 0
        }
    }
    
    /// Background offset.
    public var backgroundOffset: CGSize = CGSize.zero {
        didSet {
            self.defaultLayer.frameOffset = backgroundOffset
        }
    }
    
    
    // MARK: - Timing
    
    // Update time properties.
    private var lastUpdateTime: TimeInterval = 0
    
    private let maximumUpdateDelta: TimeInterval = 1.0 / 60.0
    
    
    // MARK: - Dispatch Queues
    
    private let renderQueue  = DispatchQueue(label: "org.sktiled.sktilemap.renderqueue", qos: .userInteractive, attributes: .concurrent)
    private let animatedTilesQueue = DispatchQueue(label: "org.sktiled.sktilemap.tiles.animated.renderQueue", qos: .userInteractive, attributes: .concurrent)
    private let staticTilesQueue  = DispatchQueue(label: "org.sktiled.sktilemap.tiles.static.renderQueue", qos: .userInteractive, attributes: .concurrent)
    
    /// Logging verbosity.
    internal var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    
    // MARK: - Positioning
    
    /// Mappable child node offset. By default, the `SKTilemap` node aligns child layers to its' center point.
    ///
    /// Used when a map container aligns all of the layers.
    public var childOffset: CGPoint {
        var offsetOutput = CGPoint.zero
        
        // default alignment is `center` (0.5,0.5)
        let layerAnchorPoint = layerAlignment.anchorPoint
        
        switch orientation {
            case .orthogonal:
                offsetOutput.x = -sizeInPoints.width * layerAnchorPoint.x
                offsetOutput.y = sizeInPoints.height * layerAnchorPoint.y
                
            case .isometric:
                offsetOutput.x = -sizeInPoints.width * layerAnchorPoint.x
                offsetOutput.y = sizeInPoints.height * layerAnchorPoint.y
                
            case .hexagonal, .staggered:
                offsetOutput.x = -sizeInPoints.width * layerAnchorPoint.x
                offsetOutput.y = sizeInPoints.height * layerAnchorPoint.y
        }
        return offsetOutput
    }
    
    /// Defines this map's position within a [Tiled world][tiled-world-url]. This value cannot be changed directly, but matches the value set in the world JSON description.
    ///
    /// [tiled-world-url]:https://doc.mapeditor.org/en/stable/manual/worlds/
    public internal(set) var worldOffset: CGPoint = CGPoint.zero
    
    /// The map projection type.
    ///
    /// [tilemap-orientation-image]:../images/tilemap-orientations.svg
    public internal(set) var orientation: TilemapOrientation
    
    /// Tile render order.
    internal var renderOrder: RenderOrder = RenderOrder.rightDown
    
    
    // MARK: - Camera
    
    /// Reference to the Tiled scene camera.
    public var cameraNode: SKTiledSceneCamera? {
        guard let tiledScene = scene as? SKTiledScene,
              let tiledCamera = tiledScene.cameraNode else {
            return nil
        }
        return tiledCamera
    }
    
    /// Indicates the current node has received focus or selected.
    public var isFocused: Bool = false {
        didSet {
            guard isFocused != oldValue else {
                return
            }
        }
    }
    
    /// Node is visible to the camera.
    public var visibleToCamera: Bool = true
    
    /// Constraints on camera min/max zoom levels.
    ///
    /// ### Constants
    ///
    /// - `min`: minimum camera zoom level.
    /// - `max`: maximum camera zoom level.
    ///
    public struct CameraZoomConstraints {
        public var min: CGFloat = 0.2
        public var max: CGFloat = 5.0
    }
    
    /// Camera zoom constraints.
    public var zoomConstraints: CameraZoomConstraints = CameraZoomConstraints()
    
    /// This flag indicates that the map should auto-resize upon view changes.
    public internal(set) var autoResize: Bool = false
    
    /// Enables the map node to receive notifications from camera.
    @objc public var receiveCameraUpdates: Bool = true
    
    /// The camera's current position.
    public internal(set) var cameraPosition: CGPoint = CGPoint.zero
    
    /// Display bounds that the tilemap is viewable in.
    public internal(set) var cameraBounds: CGRect?
    
    /// Current map zoom level.
    public internal(set) var currentZoom: CGFloat = 1.0
    
    /// Allow camera zooming.
    public var allowZoom: Bool = true
    
    /// Allow camera movement.
    public var allowMovement: Bool = true
    
    /// Allow camera rotation.
    public var allowRotation: Bool = false
    
    /// Initial world scale.
    public var worldScale: CGFloat = 1.0
    
    
    // MARK: - Hexagonal/Staggered Properties

    /// Hexagonal side length.
    public var hexsidelength: Int = 0

    /// Hexagonal stagger axis.
    public var staggeraxis: StaggerAxis = StaggerAxis.y

    /// Hexagonal stagger index.
    public var staggerindex: StaggerIndex = StaggerIndex.odd


    // MARK: - Content Root Nodes

    /// Root for all Tiled renderable content.
    internal let contentRoot = SKEffectNode()

    /// Root node for all debugging content.
    internal let debugRoot = SKNode()

    /// Crop node to crop the map at boundaries.
    internal let cropNode = SKCropNode()

    /// Setting this property masks the map at its boundaries.
    public var isCropped: Bool {
        
        // FIXME: this will not work with infinite maps
        
        get {
            return cropNode.maskNode != nil
        } set {
            cropNode.maskNode = nil
            if (newValue == true) {
                let mask = SKSpriteNode(color: SKColor.black, size: self.sizeInPoints)
                cropNode.maskNode = mask
            }
        }
    }

    /// This object's `CGPath` defining the shape of geometry. Used to draw the bounding shape.
    @objc public lazy var objectPath: CGPath = {
        let vertices = getVertices(offset: CGPoint.zero)
        return polygonPath(vertices)
    }()

    // MARK: - Misc Properties

    /// Map isolation mode for geometry..
    ///
    /// # Properties
    ///
    /// - none: all object/tile types are shown.
    /// - tiles: oOnly tiles are shown.
    /// - objects: only objects are shown.
    /// - layers: only layers are shown.
    /// - tileObjects: only tile objects are shown.
    /// - textObjects: only text objects are shown.
    /// - pointObjects: only point objects are shown.
    internal var isolationMode: TiledGeometryIsolationMode = TiledGeometryIsolationMode.none {
        didSet {
            guard (isolationMode != oldValue) else {
                return
            }

            updateGeometryIsolationMode()

            // TODO: document this notification

            /// calls back to the tile data storage container.
            NotificationCenter.default.post(
                name: Notification.Name.Map.TileIsolationModeChanged,
                object: self
            )
        }
    }

    /// Signifies that the tilemap is fully initialized.
    public private(set) var isInitialized: Bool = false

    // MARK: Tile Update Mode

    /// Force render queues to sync each frame.
    internal var syncEveryFrame: Bool = false

    /// Update mode used for tiles & objects.
    ///
    /// ### Constants
    ///
    /// - `dynamic`: dynamically update tiles as needed.
    /// - `full`: all tiles are updated each frame.
    /// - `actions`: tiles are not updated, SpriteKit actions are used instead.
    ///
    public var updateMode: TileUpdateMode = TiledGlobals.default.updateMode {
        didSet {
            guard (updateMode != oldValue) && (isRendered == true) && (isInitialized == true) else { return }
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

    // MARK: - Content Root

    /// Tilemap custom shader.
    public var shader: SKShader? {
        get {
            return contentRoot.shader
        } set {
            contentRoot.shader = newValue
        }
    }

    /// Enable effects rendering of this node.
    public var shouldEnableEffects: Bool {
        get {
            return contentRoot.shouldEnableEffects
        } set {
            if (newValue == true) && (pixelCount > SKTILED_MAX_TILEMAP_PIXEL_SIZE) {

                // TODO: this should be a system log event
                self.log("map size of \(sizeInPoints.shortDescription) exceeds max texture framebuffer size.", level: .warning)
            }
            contentRoot.shouldEnableEffects = newValue
        }
    }

    /// Indicates whether the results of rendering the child nodes should be cached.
    public var shouldRasterize: Bool {
        get {
            return contentRoot.shouldRasterize
        } set {
            contentRoot.shouldRasterize = newValue
        }
    }

    /// Image processing filter.
    public var filter: CIFilter? {
        get {
            return contentRoot.filter
        } set {
            contentRoot.filter = newValue
        }
    }

    /// Speed modifier applied to all actions executed by the tilemap and its descendants.
    public override var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.layers.forEach { layer in
                layer.speed = speed
                layer.runAnimationAsActions()
            }
        }
    }

    // MARK: - Debug Overlay

    /// Overlay layer used to display object bounds (debug).
    internal var objectsOverlay: TileObjectOverlay = TileObjectOverlay()

    /// Object count.
    public var objectCount: Int {
        return self.getObjects(recursive: true).count
    }


    // MARK: Debugging

    /// Render statistics
    public struct RenderStatistics {

        /// Tile update mode.
        public var updateMode: TileUpdateMode = TileUpdateMode.dynamic

        /// Tile object count.
        public var objectCount: Int = 0

        /// Visible tile count.
        public var visibleCount: Int = 0

        /// CPU Usage.
        public var cpuPercentage: Int = 0

        /// Tilemap effects enabled.
        public var effectsEnabled: Bool = false

        /// Objects updated this frame.
        public var updatedThisFrame: Int = 0

        /// Tilemap has visible objects.
        public var objectsVisible: Bool = false

        /// Number of animated tile actions.
        public var actionsCount: UInt32 = 0

        /// Tile data cache size.
        public var cacheSize: String = "-"

        /// Frame render time.
        public var renderTime: TimeInterval = 0

        /// View tracking view count.
        public var trackingViews: UInt32 = 0
    }

    /// Debugging/Render Statistics.
    internal var renderStatistics: RenderStatistics = RenderStatistics()

    /// Frequency of samples.
    internal var renderStatisticsSampleFrequency: Int = 60

    /// The current frame index.
    internal var currentFrameIndex: Int = 0

    /// Coordinate change handler.
    internal var onCoordinateChange: ((simd_int2, simd_int2, Bool) -> ())?



    /// Map bounding shape.
    @objc public lazy var boundsShape: SKShapeNode? = {
        let scaledverts = getVertices(offset: CGPoint.zero).map { $0 * renderQuality }
        let objpath = polygonPath(scaledverts)
        let shape = SKShapeNode(path: objpath)

        let boundsLineWidth = TiledGlobals.default.renderQuality.object / 1.5
        shape.lineWidth = boundsLineWidth
        shape.lineJoin = .miter
        shape.miterLimit = 6
        shape.setScale(1 / renderQuality)
        addChild(shape)
        shape.zPosition = zPosition + 5000
        shape.name = boundsKey
        return shape
    }()

    /// Object anchor node visualization node.
    @objc public lazy var anchorShape: SKShapeNode = {
        let anchorRadius: CGFloat = (tileSize.height / 8)
        let shape = SKShapeNode(circleOfRadius: anchorRadius)
        shape.strokeColor = SKColor.clear
        shape.fillColor = frameColor
        addChild(shape)
        shape.zPosition = zPosition + 5000
        shape.name = anchorKey
        return shape
    }()

    // MARK: - Debugging


    /// Debug visualization node.
    internal var debugNode: TiledDebugDrawNode!

    /// Debug visualization options.
    @objc public var debugDrawOptions: DebugDrawOptions = TiledGlobals.default.debugDrawOptions {
        didSet {
            debugNode?.draw()

            // TODO: do we need this anymore?

            let proxiesVisible = self.isShowingObjectBounds
            let proxies = self.getObjectProxies()

            for proxy in proxies {
                proxy.displayReference = proxiesVisible
                proxy.draw()
            }
        }
    }

    // MARK: - Color Attributes

    /// Color used to display object frames.
    public var objectColor: SKColor = SKColor.gray

    /// Default color (used for pause).
    public var color: SKColor = SKColor.clear

    /// Color used to visualize the tile grid.
    public var gridColor: SKColor = TiledGlobals.default.debugDisplayOptions.gridColor

    /// Bounding frame color.
    public var frameColor: SKColor = TiledGlobals.default.debugDisplayOptions.frameColor

    /// Color used to highlight tiles.
    public var highlightColor: SKColor = TiledGlobals.default.debugDisplayOptions.tileHighlightColor

    /// Navigation graph color.
    public var navigationColor: SKColor = TiledGlobals.default.debugDisplayOptions.navigationColor

    /// Gravity vector.
    public var gravity: CGVector = CGVector.zero


    /// Map frame in parent coordinate space.
    public override var frame: CGRect {
        print("⭑ [SKTilemap]: calculating map frame...")
        let px = parent?.position.x ?? position.x
        let py = parent?.position.y ?? position.y

        // CHECKME: this might be mucking up the sizing (iso bounds bug)
        let frameSize = (isInfinite == true) ? absoluteSize : sizeInPoints
        return CGRect(center: CGPoint(x: px, y: py), size: frameSize)
    }

    /// Returns a bounding rect for the entire map. Adapted from Tiled `Renderer.mapBoundingRect`.
    public override var boundingRect: CGRect {

        switch orientation {

            case .orthogonal:
                
                /// infinite map
                if (isInfinite == true) {
                    var mapBounds = CGRect.zero
                    for tileLayer in tileLayers() {
                        mapBounds = tileLayer.boundingRect.union(mapBounds)
                    }

                    if (mapBounds == CGRect.zero) {
                        mapBounds.origin.x = 1
                        mapBounds.origin.y = 1
                    }

                    return CGRect(x: mapBounds.origin.x * tileWidth, y: mapBounds.origin.y * tileHeight, width: mapSize.width * tileWidth, height: -(mapSize.height * tileHeight))

                /// standard map
                } else {
                    
                    
                    /// `childOffset` represents the map center point
                    return CGRect(origin: childOffset, size: CGSize(width: width * tileWidth, height: -(height * tileHeight)))
                }

            case .isometric:
                
                /// infinite map
                if (isInfinite == true) {

                    var mapBounds = CGRect.zero
                    for tileLayer in tileLayers() {
                        mapBounds = tileLayer.boundingRect.union(mapBounds)
                    }

                    if (mapBounds == CGRect.zero) {
                        mapBounds.origin.x = 1
                        mapBounds.origin.y = 1
                    }

                    let origin = mapBounds.origin.x * mapBounds.origin.y
                    let side = height * width

                    return CGRect(x: origin * tileWidth / 2, y: origin * tileHeight / 2, width: side * tileWidth / 2, height: side * tileHeight / 2)
                
                /// standard map
                } else {
                    return CGRect(origin: childOffset, size: CGSize(width: width * tileWidth, height: -(height * tileHeight)))
                }

            // FIXME: this is incorrect
            case .hexagonal, .staggered:

                var mapBounds = CGRect.zero

                if (isInfinite == true) {
                    for tileLayer in tileLayers() {
                        mapBounds = tileLayer.boundingRect.union(mapBounds)
                    }
                } else {
                    mapBounds = CGRect(x: 0, y: 0, width: width, height: height)
                }


                if (staggerX == true) {
                    let morigin = CGPoint(x: mapBounds.origin.x * columnWidth, y: mapBounds.origin.y * (tileHeight + sideLengthY))
                    let msize = CGSize(width: width * columnWidth + sideOffsetX, height: -(height * (tileHeight + sideLengthY)))
                    return CGRect(origin: morigin, size: msize)


                } else {
                    let morigin = CGPoint(x: mapBounds.origin.x * (tileWidth + sideLengthX), y: mapBounds.origin.y * rowHeight)
                    var msize = CGSize(width: width * (tileWidth + sideOffsetX), height: -(height * rowHeight + sideLengthY))

                    if (mapBounds.height > 1) {
                        msize.width -= columnWidth
                    }
                    return CGRect(origin: morigin, size: msize)
                }
        }
    }

    /// The accumulated map size.
    public var absoluteSize: CGSize {

        // TODO: finish implementing this
        if (isInfinite == true) {
            var result = boundingRect

            for layer in layers {
                let layerFrame = layer.frame

                if layerFrame.minX <= result.minX {
                    result.origin.x -= layerFrame.minX
                }

                if layerFrame.maxX >= result.maxX {
                    result.origin.x += layerFrame.maxX
                }

                if layerFrame.minY <= result.minY {
                    result.origin.y -= layerFrame.minY
                }

                if layerFrame.maxY >= result.maxY {
                    result.origin.y += layerFrame.maxY
                }

            }
            return result.size
        }

        return sizeInPoints
    }

    /// Pixel size of the map.
    internal var pixelCount: Int {
        return Int(sizeInPoints.width * sizeInPoints.height)
    }

    /// The property used to align child layers within the tilemap.
    internal var layerAlignment: LayerPosition = LayerPosition.center {
        didSet {
            layers.forEach {
                self.positionLayer($0)
            }
        }
    }

    /// Returns the last GID for all of the tilesets.
    public var lastGID: UInt32 {
        return tilesets.isEmpty == false ? tilesets.map { $0.lastGID }.max()! : 0
    }

    /// Returns the last index for all tilesets.
    public var lastIndex: UInt32 {
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

    /// Return all tile layers. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: array of tile layers.
    public func tileLayers(recursive: Bool = true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKTileLayer != nil } as! [SKTileLayer]
    }

    /// Return all object groups. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: array of object groups.
    public func objectGroups(recursive: Bool = true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKObjectGroup != nil } as! [SKObjectGroup]
    }

    /// Return all image layers. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: array of image layers.
    public func imageLayers(recursive: Bool = true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter { $0 as? SKImageLayer != nil } as! [SKImageLayer]
    }

    /// Return all group layers. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: array of image layers.
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
    public override var isPaused: Bool {
        willSet (pauseValue) {
            overlay.isHidden = (pauseValue == false)
        }
    }

    // MARK: - Loading

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
    ///
    /// - Parameter tmxFile: Tiled file name.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: nil, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode,
                              withTilesets: nil, ignoreProperties: false,
                              loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name.
    ///   - completion: optional completion block.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String,
                           _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) -> SKTilemap? {

        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: nil, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode,
                              withTilesets: nil, ignoreProperties: false,
                              loggingLevel: TiledGlobals.default.loggingLevel, completion)
    }

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name.
    ///   - loggingLevel: logging verbosity level.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String,
                           loggingLevel: LoggingLevel) -> SKTilemap? {

        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: nil, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: loggingLevel, nil)
    }

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name.
    ///   - delegate: tilemap [delegate](Protocols/TilemapDelegate.html) instance.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String,
                           delegate: TilemapDelegate) -> SKTilemap? {

        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name.
    ///   - delegate: tilemap [delegate](Protocols/TilemapDelegate.html) instance.
    ///   - updateMode: tile update mode.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String,
                           delegate: TilemapDelegate,
                           updateMode: TileUpdateMode) -> SKTilemap? {

        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: nil,
                              updateMode: updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name.
    ///   - delegate: tilemap [delegate](Protocols/TilemapDelegate.html) instance.
    ///   - tilesetDataSource: tilemap [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String,
                           delegate: TilemapDelegate,
                           tilesetDataSource: TilesetDataSource) -> SKTilemap? {

        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: tilesetDataSource,
                              updateMode: TiledGlobals.default.updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name.
    ///   - delegate: tilemap [delegate](Protocols/TilemapDelegate.html) instance.
    ///   - tilesetDataSource: tilemap [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - updateMode: tile update mode.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String,
                           delegate: TilemapDelegate,
                           tilesetDataSource: TilesetDataSource,
                           updateMode: TileUpdateMode) -> SKTilemap? {

        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: tilesetDataSource,
                              updateMode: updateMode, withTilesets: nil,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name.
    ///   - delegate: tilemap [delegate](Protocols/TilemapDelegate.html) instance.
    ///   - tilesetDataSource: tilemap [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - withTilesets: pre-loaded tilesets.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String,
                           delegate: TilemapDelegate,
                           tilesetDataSource: TilesetDataSource,
                           withTilesets: [SKTileset]) -> SKTilemap? {

        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: tilesetDataSource,
                              updateMode: TiledGlobals.default.updateMode, withTilesets: withTilesets,
                              ignoreProperties: false, loggingLevel: TiledGlobals.default.loggingLevel, nil)
    }

    /// Load a **Tiled** tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error. This is the primary loading method for tilemaps. Currently used by the demo app.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name.
    ///   - inDirectory: asset search path.
    ///   - delegate: optional [`TilemapDelegate`](Protocols/TilemapDelegate.html) instance.
    ///   - tilesetDataSource: optional [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - updateMode: tile update mode.
    ///   - withTilesets: pre-loaded tilesets.
    ///   - noparse: ignore custom properties from Tiled.
    ///   - loggingLevel: logging verbosity level.
    ///   - completion: optional completion block.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(tmxFile: String,
                           inDirectory: String? = nil,
                           delegate: TilemapDelegate? = nil,
                           tilesetDataSource: TilesetDataSource? = nil,
                           updateMode: TileUpdateMode = TiledGlobals.default.updateMode,
                           withTilesets: [SKTileset]? = nil,
                           ignoreProperties noparse: Bool = false,
                           loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                           _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) -> SKTilemap? {


        let startTime = Date()
        let queue = DispatchQueue(label: "org.sktiled.renderqueue", qos: .userInitiated)
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
            tilemap.renderTime = Date().timeIntervalSince(startTime)
            let renderTimeStamp = String(format: "%.\(String(3))f", tilemap.renderTime)
            let parseTimeStamp  = String(format: "%.\(String(3))f", tilemap.parseTime)

            // FIXME: check for errors here
            Logger.default.log("tilemap '\(tilemap.mapName)' rendered in: \(renderTimeStamp)s ( parse: \(parseTimeStamp)s )", level: .success)

            // completion handler
            completion?(tilemap)
            return tilemap
        }
        return nil
    }

    // MARK: - String Loading


    /// Load tilemap from xml string data.
    ///
    /// - Parameters:
    ///   - string: xml string data.
    ///   - documentRoot: document root.
    ///   - delegate: optional [`TilemapDelegate`](Protocols/TilemapDelegate.html) instance.
    ///   - tilesetDataSource: optional [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - updateMode: tile update mode.
    ///   - withTilesets: pre-loaded tilesets.
    ///   - noparse: ignore custom properties from Tiled.
    ///   - loggingLevel: logging verbosity level.
    ///   - completion: optional completion block.
    /// - Returns: tilemap object (if file read succeeds).
    public class func load(string: String,
                           documentRoot: String? = nil,
                           delegate: TilemapDelegate? = nil,
                           tilesetDataSource: TilesetDataSource? = nil,
                           updateMode: TileUpdateMode = TiledGlobals.default.updateMode,
                           withTilesets: [SKTileset]? = nil,
                           ignoreProperties noparse: Bool = false,
                           loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                           _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) -> SKTilemap? {


        let startTime = Date()
        let queue = DispatchQueue(label: "org.sktiled.renderqueue", qos: .userInitiated)
        if let tilemap = SKTilemapParser().load(string: string,
                                                documentRoot: documentRoot,
                                                delegate: delegate,
                                                tilesetDataSource: tilesetDataSource,
                                                updateMode: updateMode,
                                                withTilesets: withTilesets,
                                                ignoreProperties: noparse,
                                                loggingLevel: loggingLevel,
                                                renderQueue: queue) {


            // set the map render time attribute
            tilemap.renderTime = Date().timeIntervalSince(startTime)
            let renderTimeStamp = String(format: "%.\(String(3))f", tilemap.renderTime)
            let parseTimeStamp  = String(format: "%.\(String(3))f", tilemap.parseTime)

            // FIXME: check for errors here
            Logger.default.log("tilemap '\(tilemap.mapName)' rendered in: \(renderTimeStamp)s ( parse: \(parseTimeStamp)s )", level: .success)

            // completion handler5
            completion?(tilemap)
            return tilemap
        }
        return nil
    }

    /// Load tilemap from xml string data.
    ///
    /// - Parameters:
    ///   - data: xml string data.
    ///   - documentRoot: document root.
    ///   - delegate: optional [`TilemapDelegate`](Protocols/TilemapDelegate.html) instance.
    ///   - tilesetDataSource: optional [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - updateMode: tile update mode.
    ///   - withTilesets: pre-loaded tilesets.
    ///   - noparse: ignore custom properties from Tiled.
    ///   - loggingLevel: logging verbosity level.
    ///   - completion: optional completion block.
    /// - Returns: tilemap object (if file read succeeds).
    @available(*, deprecated, message: "This method has not yet been implemented.")
    public class func load(data: Data,
                           documentRoot: String? = nil,
                           delegate: TilemapDelegate? = nil,
                           tilesetDataSource: TilesetDataSource? = nil,
                           updateMode: TileUpdateMode = TiledGlobals.default.updateMode,
                           withTilesets: [SKTileset]? = nil,
                           ignoreProperties noparse: Bool = false,
                           loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                           _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) -> SKTilemap? {


        let startTime = Date()
        let queue = DispatchQueue(label: "org.sktiled.renderqueue", qos: .userInitiated)
        if let tilemap = SKTilemapParser().load(data: data,
                                                documentRoot: documentRoot,
                                                delegate: delegate,
                                                tilesetDataSource: tilesetDataSource,
                                                updateMode: updateMode,
                                                withTilesets: withTilesets,
                                                ignoreProperties: noparse,
                                                loggingLevel: loggingLevel,
                                                renderQueue: queue) {


            // set the map render time attribute
            tilemap.renderTime = Date().timeIntervalSince(startTime)
            let renderTimeStamp = String(format: "%.\(String(3))f", tilemap.renderTime)
            let parseTimeStamp  = String(format: "%.\(String(3))f", tilemap.parseTime)


            // FIXME: check for errors here
            Logger.default.log("tilemap '\(tilemap.mapName)' rendered in: \(renderTimeStamp)s ( parse: \(parseTimeStamp)s )", level: .success)

            // completion handler
            completion?(tilemap)
            return tilemap
        }
        return nil
    }


    // MARK: - Initialization

    /// Instantiate the map with a decoder instance.
    ///
    /// - Parameter aDecoder: decoder.
    required public init?(coder aDecoder: NSCoder) {
        mapSize = CGSize.zero
        tileSize = CGSize.zero
        orientation = .orthogonal
        super.init(coder: aDecoder)
        self.setupNotifications()
    }

    /// Initialize with dictionary attributes from xml parser.
    ///
    /// - Parameter attributes: **Tiled** attributes dictionary.
    public init?(attributes: [String: String]) {
        guard let width = attributes["width"] else { return nil }
        guard let height = attributes["height"] else { return nil }
        guard let tilewidth = attributes["tilewidth"] else { return nil }
        guard let tileheight = attributes["tileheight"] else { return nil }
        guard let orient = attributes["orientation"] else { return nil }

        // initialize tile size & map size
        tileSize = CGSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        mapSize = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))

        // tile orientation
        guard let tileOrientation: TilemapOrientation = TilemapOrientation(string: orient) else {
            fatalError("invalid tilemap orientation '\(orient)'.")
        }

        self.orientation = tileOrientation

        // Infinite map flag
        self.isInfinite = false
        if let infinite = attributes["infinite"] {
            if let intValue = Int(infinite)  {
                self.isInfinite = Bool(intValue)
            }
        }

        // render order
        if let rendorder = attributes["renderorder"] {
            guard let renderorder: RenderOrder = RenderOrder(rawValue: rendorder) else {
                fatalError("invalid render order '\(rendorder)'.")
            }
            self.renderOrder = renderorder
        }

        // hex side
        if let hexside = attributes["hexsidelength"] {
            self.hexsidelength = Int(hexside)!
        }

        // hex stagger axis
        if let hexStagger = attributes["staggeraxis"] {
            guard let staggerAxis: StaggerAxis = StaggerAxis(string: hexStagger) else {
                fatalError("invalid stagger axis '\(hexStagger)'.")
            }
            self.staggeraxis = staggerAxis
        }

        // hex stagger index
        if let hexIndex = attributes["staggerindex"] {
            guard let hexindex: StaggerIndex = StaggerIndex(string: hexIndex) else {
                fatalError("invalid stagger index '\(hexIndex)'.")
            }
            self.staggerindex = hexindex
        }

        // Tiled application version
        if let tiledVersion = attributes["tiledversion"] {
            self.tiledversion = tiledVersion
        }

        // Tiled map version
        if let tiledMapVersion = attributes["mapversion"] {
            self.mapversion = tiledMapVersion
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
        let renderSize = CGSize(width: mapSize.width * tileSize.width, height: mapSize.height * tileSize.height)
        let largestPixelDimension: CGFloat = (renderSize.width > renderSize.height) ? renderSize.width : renderSize.height

        // calculate the ideal max render quality (max size is 16384)
        maxRenderQuality = CGFloat(Int(ceil(4000 / (largestPixelDimension * TiledGlobals.default.contentScale))))

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

        setupChildNodes()
        setupNotifications()
    }

    /// Initialize with map size/tile size.
    ///
    /// - Parameters:
    ///   - sizeX: map width in tiles.
    ///   - sizeY: map height in tiles.
    ///   - tileSizeX: tile width in pixels.
    ///   - tileSizeY: tile height in pixels.
    ///   - orientation: map orientation.
    public init(_ sizeX: Int, _ sizeY: Int,
                _ tileSizeX: Int, _ tileSizeY: Int,
                orientation: TilemapOrientation = .orthogonal) {

        self.mapSize = CGSize(width: CGFloat(sizeX), height: CGFloat(sizeY))
        self.tileSize = CGSize(width: CGFloat(tileSizeX), height: CGFloat(tileSizeY))
        self.orientation = orientation
        self.antialiasLines = (currentZoom < 1)
        super.init()

        // turn off effects rendering by default
        shouldEnableEffects = false
        self.setupNotifications()
    }

    deinit {
        isolatedLayers = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.LayerIsolationChanged, object: nil)
        objectsOverlay.removeAllChildren()
        objectsOverlay.removeFromParent()
        _layers = []
        // dataStorage?.objectsList = nil
        dataStorage = nil
    }

    /// Set up the debug & content root nodes.
    internal func setupChildNodes() {
        // debug node
        self.debugNode = TiledDebugDrawNode(tileLayer: self.defaultLayer, isDefault: true)
        self.debugNode.zPosition = zPosition + zDeltaForLayers

        #if SKTILED_DEMO
        objectsOverlay.receiveCameraUpdates = true
        #endif

        objectsOverlay.zPosition = zPosition + (zDeltaForLayers * 2)
        cropNode.name = "MAP_CROP_ROOT"

        debugNode.name = "MAP_DEBUG_CONTENT"
        addChild(debugNode)
        debugNode.position.y -= sizeInPoints.height
        addChild(objectsOverlay)

        contentRoot.name = "MAP_RENDERABLE_CONTENT"

        #if SKTILED_DEMO
        contentRoot.setAttrs(values: ["tiled-node-desc": "Root node for all Tiled image & vector types."])
        #endif

        contentRoot.addChild(cropNode)
        addChild(contentRoot)

        debugRoot.name = "MAP_DEBUG_ROOT"

        #if SKTILED_DEMO
        debugRoot.setAttrs(values: ["tiled-node-name": "debugroot", "tiled-node-icon": "debug-icon"])
        #endif

        addChild(debugRoot)
    }

    // MARK: - Tileset Mangement

    /// Add a tileset to tilesets set.
    ///
    /// - Parameter tileset: tileset object.
    public func addTileset(_ tileset: SKTileset) {
        tilesets.insert(tileset)
        tileset.tilemap = self
        tileset.ignoreProperties = ignoreProperties
        tileset.loggingLevel = loggingLevel
    }

    /// Remove a tileset from the tilesets set.
    ///
    /// - Parameter tileset: tileset object.
    /// - Returns: removed tileset.
    public func removeTileset(_ tileset: SKTileset) -> SKTileset? {
        return tilesets.remove(tileset)
    }

    /// Returns a named tileset from the tilesets set.
    ///
    /// - Parameter named: tileset to return.
    /// - Returns: tileset object.
    public func getTileset(named: String) -> SKTileset? {
        if let index = tilesets.firstIndex(where: { $0.name == named }) {
            let tileset = tilesets[index]
            return tileset
        }
        return nil
    }

    /// Returns an *externally referenced* tileset with a given filename.
    ///
    /// - Parameter filename: tileset source file.
    /// - Returns: tileset with the given file name.
    public func getTileset(fileNamed filename: String) -> SKTileset? {
        if let index = tilesets.firstIndex(where: { $0.filename == filename }) {
            let tileset = tilesets[index]
            return tileset
        }
        return nil
    }

    /// Returns the tileset associated with a global id.
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: associated tileset.
    public func getTilesetFor(globalID: UInt32) -> SKTileset? {
        guard let tiledata = getTileData(globalID: globalID) else {
            return nil
        }
        return tiledata.tileset
    }

    /// Returns the tileset containing the given global id.
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: tuple of result & matching tileset.
    public func contains(globalID: UInt32) -> (Bool, SKTileset?) {
        for tileset in tilesets {
            if tileset.contains(globalID: globalID) == true {
                return (true, tileset)
            }
        }
        return (false, nil)
    }

    // MARK: - Layer Management

    /// Returns an array of child layers, sorted by index (first is lowest, last is highest).
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: array of layers.
    public func getLayers(recursive: Bool = true) -> [TiledLayerObject] {
        return (recursive == true) ? self.layers : Array(self._layers)
    }

    /// Return child layers matching the given name.
    ///
    /// - Parameters:
    ///   - layerName: tile layer name.
    ///   - recursive: include nested layers.
    /// - Returns: layer objects.
    public func getLayers(named layerName: String, recursive: Bool = true) -> [TiledLayerObject] {
        return getLayers(recursive: recursive).filter { $0.name == layerName }
    }
    
    /// Return child layers with names matching the given prefix.
    ///
    /// - Parameters:
    ///   - withPrefix: prefix to match.
    ///   - recursive: include nested layers.
    /// - Returns: layer objects.
    public func getLayers(withPrefix: String, recursive: Bool = true) -> [TiledLayerObject] {
        return getLayers(recursive: recursive).filter { $0.layerName.hasPrefix(withPrefix) }
    }

    /// Return child layers with matching the given path. Tiled allows for duplicate layer names, so we're returning an array.
    ///
    /// - Parameters:
    ///   - withPrefix: layer path to search for.
    /// - Returns: layer objects.
    public func getLayers(atPath: String) -> [TiledLayerObject] {
        return getLayers(recursive: true).filter( { $0.path == atPath })
    }

    /// Returns a child layer given an `xPath` value.
    ///
    /// - Parameter xPath: layer xPath.
    /// - Returns: layer objects.
    public func getLayer(xPath: String) -> TiledLayerObject? {
        if let xindex = layers.firstIndex(where: { $0.xPath == xPath }) {
            return layers[xindex]
        }
        return nil
    }

    /// Returns a child layer matching the given UUID.
    ///
    /// - Parameter uuid: tile layer UUID.
    /// - Returns: layer object.
    public func getLayer(withID uuid: String) -> TiledLayerObject? {
        if let index = layers.firstIndex(where: { $0.uuid == uuid }) {
            let layer = layers[index]
            return layer
        }
        return nil
    }

    /// Returns a child layer given the index (0 being the lowest).
    ///
    /// - Parameter index: layer index.
    /// - Returns: layer object.
    public func getLayer(atIndex index: UInt32) -> TiledLayerObject? {
        if let index = _layers.firstIndex(where: { $0.index == index }) {
            let layer = _layers[index]
            return layer
        }
        return nil
    }

    /// Returns child layers assigned a custom `type` property.
    ///
    /// - Parameters:
    ///   - ofType: layer type.
    ///   - recursive: include nested layers.
    /// - Returns: array of layers.
    public func getLayers(ofType: String, recursive: Bool = true) -> [TiledLayerObject] {
        return getLayers(recursive: recursive).filter { $0.type != nil }.filter { $0.type! == ofType }
    }

    /// Returns all content layers (ie. not groups). Sorted by zPosition in scene.
    ///
    /// - Returns: array of layers.
    public func getContentLayers() -> [TiledLayerObject] {
        return self.layers.filter { $0 as? SKGroupLayer == nil && $0 as? TiledBackgroundLayer == nil }.sorted(by: { $0.actualZPosition > $1.actualZPosition })
    }

    /// Returns an array of layer names.
    ///
    /// - Returns: layer names.
    public func layerNames() -> [String] {
        return layers.compactMap { $0.name }
    }

    /// Add a layer to the current layers set. Automatically sets zPosition based on the `SKTilemap.zDeltaForLayers` property. If the `group` argument is not nil, layer will be added to the group instead.
    ///
    /// - Parameters:
    ///   - layer: layer object.
    ///   - group: optional group layer.
    ///   - clamped: clamp position to nearest pixel.
    /// - Returns: add was successful, added layer.
    @discardableResult
    public func addLayer(_ layer: TiledLayerObject,
                         group: SKGroupLayer? = nil,
                         clamped: Bool = true) -> (success: Bool, layer: TiledLayerObject) {

        // if a group is indicated, add it to that instead
        if (group != nil) {
            return group!.addLayer(layer, clamped: clamped)
        }

        // get the next z-position from the tilemap.
        let nextZPosition = (_layers.isEmpty == false) ? zDeltaForLayers * CGFloat(_layers.count + 1) : zDeltaForLayers

        // set the layer index
        layer.index = layers.isEmpty == false ? lastIndex + 1 : 1     // was `lastIndex + 1 : 0`

        // default layer index is -1
        if let bgLayer = layer as? TiledBackgroundLayer {
            bgLayer.index = 0
        }

        let (success, inserted) = _layers.insert(layer)

        if (success == false) {
            Logger.default.log("could not add layer: '\(inserted.layerName)'", level: .error)
        }

        // add the layer as a child
        cropNode.addChild(layer)

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

    /// Remove a layer from the current layers set.
    ///
    /// - Parameter layer: layer object.
    /// - Returns: removed layer.
    public func removeLayer(_ layer: TiledLayerObject) -> TiledLayerObject? {
        return _layers.remove(layer)
    }

    /// Create and add a new tile layer.
    ///
    /// - Parameters:
    ///   - named: layer name.
    ///   - group: optional group layer.
    /// - Returns: new layer.
    @discardableResult
    public func newTileLayer(named: String, group: SKGroupLayer? = nil) -> SKTileLayer {
        let tileLayer = SKTileLayer(layerName: named, tilemap: self)
        return addLayer(tileLayer, group: group).layer as! SKTileLayer
    }

    /// Create and add a new object group.
    ///
    /// - Parameters:
    ///   - named: layer name.
    ///   - group: optional group layer.
    /// - Returns: new layer.
    @discardableResult
    public func newObjectGroup(named: String, group: SKGroupLayer? = nil) -> SKObjectGroup {
        let groupLayer = SKObjectGroup(layerName: named, tilemap: self)
        return addLayer(groupLayer, group: group).layer as! SKObjectGroup
    }

    /// Create and add a new image layer.
    ///
    /// - Parameters:
    ///   - named: layer name.
    ///   - group: optional group layer.
    /// - Returns: new layer.
    @discardableResult
    public func newImageLayer(named: String, group: SKGroupLayer? = nil) -> SKImageLayer {
        let imageLayer = SKImageLayer(layerName: named, tilemap: self)
        return addLayer(imageLayer, group: group).layer as! SKImageLayer
    }

    /// Create and add a new group layer.
    ///
    /// - Parameters:
    ///   - named: layer name.
    ///   - group: optional group layer.
    /// - Returns: new layer.
    @discardableResult
    public func newGroupLayer(named: String, group: SKGroupLayer? = nil) -> SKGroupLayer {
        let groupLayer = SKGroupLayer(layerName: named, tilemap: self)
        return addLayer(groupLayer, group: group).layer as! SKGroupLayer
    }

    /// Return tile layers matching the given name. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameters:
    ///   - layerName: tile layer name.
    ///   - recursive: include nested layers.
    /// - Returns: array of tile layers.
    public func tileLayers(named layerName: String, recursive: Bool = true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKTileLayer != nil }.filter { $0.name == layerName } as! [SKTileLayer]
    }

    /// Return tile layers with names matching the given prefix. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameters:
    ///   - withPrefix: prefix to match.
    ///   - recursive: include nested layers.
    /// - Returns: array of tile layers.
    public func tileLayers(withPrefix: String, recursive: Bool = true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKTileLayer != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKTileLayer]
    }

    /// Returns a tile layer at the given index, otherwise, nil.
    ///
    /// - Parameter index: layer index.
    /// - Returns: matching tile layer.
    public func tileLayer(atIndex index: Int) -> SKTileLayer? {
        if let layerIndex = tileLayers(recursive: false).firstIndex(where: { $0.index == index } ) {
            let layer = tileLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }

    /// Return object groups matching the given name. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameters:
    ///   - layerName: tile layer name.
    ///   - recursive: include nested layers.
    /// - Returns:  array of object groups.
    public func objectGroups(named layerName: String, recursive: Bool = true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).filter { $0 as? SKObjectGroup != nil }.filter { $0.name == layerName } as! [SKObjectGroup]
    }

    /// Return object groups with names matching the given prefix. If `recursive` is false, only returns top-level layers.
    /// - Parameters:
    ///   - withPrefix: prefix to match.
    ///   - recursive: include nested layers.
    /// - Returns: array of object groups.
    public func objectGroups(withPrefix: String, recursive: Bool = true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).filter { $0 as? SKObjectGroup != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKObjectGroup]
    }

    /// Returns an object group at the given index, otherwise, nil.
    ///
    /// - Parameter index: layer index.
    /// - Returns: matching group layer.
    public func objectGroup(atIndex index: Int) -> SKObjectGroup? {
        if let layerIndex = objectGroups(recursive: false).firstIndex(where: { $0.index == index } ) {
            let layer = objectGroups(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }

    /// Return image layers matching the given name. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameters:
    ///   - layerName: tile layer name.
    ///   - recursive: include nested layers.
    /// - Returns: array of image layers.
    public func imageLayers(named layerName: String, recursive: Bool = true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKImageLayer != nil }.filter { $0.name == layerName } as! [SKImageLayer]
    }

    /// Return image layers with names matching the given prefix. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameters:
    ///   - withPrefix: prefix to match.
    ///   - recursive: include nested layers.
    /// - Returns: array of image layers.
    public func imageLayers(withPrefix: String, recursive: Bool = true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKImageLayer != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKImageLayer]
    }

    /// Returns an image layer at the given index, otherwise, nil.
    ///
    /// - Parameter index: layer index.
    /// - Returns: matching image layer.
    public func imageLayer(atIndex index: Int) -> SKImageLayer? {
        if let layerIndex = imageLayers(recursive: false).firstIndex(where: { $0.index == index } ) {
            let layer = imageLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }

    /// Return group layers matching the given name. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameters:
    ///   - layerName: tile layer name.
    ///   - recursive: include nested layers.
    /// - Returns: array of group layers.
    public func groupLayers(named layerName: String, recursive: Bool = true) -> [SKGroupLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKGroupLayer != nil }.filter { $0.name == layerName } as! [SKGroupLayer]
    }

    /// Return group layers with names matching the given prefix. If `recursive` is false, only returns top-level layers.
    ///
    /// - Parameters:
    ///   - withPrefix: prefix to match.
    ///   - recursive: include nested layers.
    /// - Returns: array of group layers.
    public func groupLayers(withPrefix: String, recursive: Bool = true) -> [SKGroupLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKGroupLayer != nil }.filter { $0.layerName.hasPrefix(withPrefix) } as! [SKGroupLayer]
    }

    /// Returns an group layer at the given index, otherwise, nil.
    ///
    /// - Parameter index: layer index.
    /// - Returns: matching group layer.
    public func groupLayer(atIndex index: Int) -> SKGroupLayer? {
        if let layerIndex = groupLayers(recursive: false).firstIndex(where: { $0.index == index } ) {
            let layer = groupLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }
    
    
    
    
    internal func replaceLayer(old oldLayer: TiledLayerObject, new newLayer: TiledLayerObject) {
        guard let oldLayerIndex = _layers.firstIndex(of: oldLayer) else {
            return
        }
        
        _layers.remove(at: oldLayerIndex)
    }

    /// Position child layers in relation to the map's anchorpoint. Called when a layer is initially added, or the tilemap node's `layerAlignment` is modified.
    ///
    /// - Parameters:
    ///   - layer: layer instance.
    ///   - clamped: clamp the result.
    internal func positionLayer(_ layer: TiledLayerObject, clamped: Bool = false) {

        // start with the child offset
        var result = self.childOffset

        // layer offset
        result.x += layer.offset.x
        result.y -= layer.offset.y

        // clamp the layer position
        if (clamped == true) {
            let scaleFactor = TiledGlobals.default.contentScale
            result = clampedPosition(point: result, scale: scaleFactor)
        }


        if (TiledGlobals.default.enableTilemapInfiniteOffsets == true) {
            // apply offset for infinite maps (tile layers only)
            result += layer.layerInfiniteOffset
        }
        
        //result += layer.debugOffset
        
        // set the layer final position
        layer.position = result
    }

    /// Position a child node in relation to the map's anchorpoint.
    ///
    /// - Parameters:
    ///   - node: any `SKNode` type.
    ///   - clamped: clamp position to nearest pixel.
    ///   - offset: node offset amount.
    internal func positionNode(_ node: SKNode,
                               clamped: Bool = true,
                               offset: CGPoint = CGPoint.zero) {

        var result = self.childOffset

        result.x += offset.x
        result.y -= offset.y

        // clamp the node position
        if (clamped == true) {
            let scaleFactor = TiledGlobals.default.contentScale
            result = clampedPosition(point: result, scale: scaleFactor)
        }

        node.position = result
    }

    /// Sort the layers in z based on a starting value (defaults to the current zPosition).
    ///
    /// - Parameter from: optional starting z-position.
    public func sortLayers(from: CGFloat? = nil) {
        let startingZ: CGFloat = (from != nil) ? from! : zPosition
        getLayers().forEach { $0.zPosition = startingZ + (zDeltaForLayers * CGFloat($0.index)) }
    }

    // MARK: - Tiles

    /// Return tiles at the given coordinate (all tile layers).
    ///
    /// - Parameter coord: coordinate.
    /// - Returns: array of tiles.
    public func tilesAt(coord: simd_int2) -> [SKTile] {
        return tileLayers(recursive: true).compactMap { $0.tileAt(coord: coord) }.reversed()
    }

    /// Return tiles at the given coordinate (all tile layers).
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: array of tiles.
    public func tilesAt(_ x: Int, _ y: Int) -> [SKTile] {
        return tilesAt(coord: simd_int2(Int32(x), Int32(y)))
    }

    /// Returns the *first* tile at the given coordinate from a layer.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    ///   - named: layer name.
    /// - Returns: matching tile, if one exists.
    public func tileAt(coord: simd_int2, inLayer named: String?) -> SKTile? {
        // TODO: need to test this
        if let named = named {
            if let layer = getLayers(named: named).first as? SKTileLayer {
                return layer.tileAt(coord: coord)
            }
        }
        return nil
    }

    /// Returns a tile at the given coordinate from a layer.
    ///
    /// - Parameters:
    ///   - x: tile x-coordinate.
    ///   - y: tile y-coordinate
    ///   - named: layer name.
    /// - Returns: matching tile, if one exists.
    public func tileAt(_ x: Int, _ y: Int, inLayer named: String?) -> SKTile? {
        return tileAt(coord: simd_int2(Int32(x), Int32(y)), inLayer: named)
    }

    /// Return the top-most tile at the given coordinate.
    ///
    /// - Parameter coord: coordinate.
    /// - Returns: first tile in layers.
    public func firstTileAt(coord: simd_int2) -> SKTile? {
        for layer in tileLayers(recursive: true).reversed().filter({ $0.visible == true }) {
            if let tile = layer.tileAt(coord: coord) {
                return tile
            }
        }
        return nil
    }

    /// Returns all tiles in the map. If `recursive` is false, only returns tiles from top-level layers.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: array of tiles.
    public func getTiles(recursive: Bool = true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles() }
    }

    /// Returns an array of tiles with a property of the given type. If `recursive` is false, only returns tiles from top-level layers.
    ///
    /// - Parameters:
    ///   - ofType: tile type.
    ///   - recursive: include nested layers.
    /// - Returns: array of tiles.
    public func getTiles(ofType: String, recursive: Bool = true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles(ofType: ofType) }
    }

    /// Returns an array of tiles matching the given global id. If `recursive` is false, only returns tiles from top-level layers.
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - recursive: include nested layers.
    /// - Returns: array of tiles.
    public func getTiles(globalID: UInt32, recursive: Bool = true) -> [SKTile] {
        // TODO: deprecate this - use `SKTilemap.allTiles(globalID:)`
        return tileLayers(recursive: recursive).flatMap { $0.getTiles(globalID: globalID) }
    }

    /// Returns tiles with a property matching the given name.
    ///
    /// - Parameters:
    ///   - named: property name.
    ///   - recursive: include nested layers.
    /// - Returns: array of tiles.
    public func getTilesWithProperty(_ named: String, recursive: Bool = true) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers(recursive: recursive) {
            result += layer.getTilesWithProperty(named)
        }
        return result
    }

    /// Returns tiles with a property of the given type & value. If `recursive` is false, only returns tiles from top-level layers.
    ///
    /// - Parameters:
    ///   - named: property name.
    ///   - value: property value.
    ///   - recursive: include nested layers
    /// - Returns: array of tiles.
    public func getTilesWithProperty(_ named: String, _ value: Any, recursive: Bool = true) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers(recursive: recursive) {
            result += layer.getTilesWithProperty(named, value)
        }
        return result
    }

    /// Returns an array of all animated tile objects.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: array of tiles
    public func animatedTiles(recursive: Bool = true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.animatedTiles() }
    }

    /// Creates and returns a new tile instance with the given global id.
    ///
    /// - Parameters:
    ///   - localID: tile gobal id.
    ///   - tileType: tile object type.
    /// - Returns: tile instance, if tile data exists.
    public func newTile(globalID: UInt32, type tileType: SKTile.Type = SKTile.self) -> SKTile? {
        guard let tiledata = getTileData(globalID: globalID),
              let tile = tileType.init(data: tiledata) else {
            return nil
        }

        // add to tile cache
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: tile
        )

        return tile
    }

    // MARK: - Tile Data

    /// Returns tile data for a global tile id.
    ///
    /// - Parameters:
    ///   - globalID: global tile id.
    /// - Returns: tile data, if it exists.
    public func getTileData(globalID: UInt32) -> SKTilesetData? {
        let unmaskedGid = flippedTileFlags(id: globalID).globalID
        for tileset in tilesets where tileset.contains(globalID: unmaskedGid) {
            if let tileData = tileset.getTileData(globalID: unmaskedGid) {
                return tileData
            }
        }
        return nil
    }

    /// Return tile data with a property of the given type.
    ///
    /// - Parameter ofType: tile data type.
    /// - Returns: array of tile data.
    public func getTileData(ofType: String) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(ofType: ofType) }
    }

    /// Return tile data with a property of the given type (all tilesets).
    ///
    /// - Parameter named: property name.
    /// - Returns: array of tile data.
    public func getTileData(withProperty named: String) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(withProperty: named) }
    }

    /// Return tile data with a property of the given type (all tile layers).
    ///
    /// - Parameters:
    ///   - named: property name.
    ///   - value: property value.
    /// - Returns: array of tiles.
    public func getTileData(withProperty named: String, _ value: Any) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(withProperty: named, value) }
    }

    /// Returns tile data with the given name & animated state.
    ///
    /// - Parameters:
    ///   - name: data name.
    ///   - isAnimated: filter data that is animated.
    /// - Returns: array of tile data.
    public func getTileData(named name: String, isAnimated: Bool = false) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(named: name, isAnimated: isAnimated) }
    }

    // MARK: - Objects

    /// Return objects at the given point (all object groups).
    ///
    /// - Parameter point: coordinate.
    /// - Returns: array of objects.
    public func objectsAt(point: CGPoint) -> [SKTileObject] {
        return nodes(at: point).filter { node in
            node as? SKTileObject != nil
            } as! [SKTileObject]
    }

    /// Return objects at the given coordinate (all object groups). Queries the `TileObjectOverlay` node, which is not exposed to the public API.
    ///
    /// - Parameter coord: coordinate.
    /// - Returns: array of objects.
    public func objectsAt(coord: CGPoint) -> [SKTileObject] {
        // TODO: need to test this
        let pointInMap = pointForCoordinate(coord: coord.toVec2)
        let pointInOverlay = convert(pointInMap, to: objectsOverlay)
        return objectsOverlay.objectsAt(point: pointInOverlay)
    }

    /// Return all of the current tile objects. If `recursive` is false, only returns objects from top-level layers.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: array of objects.
    public func getObjects(recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects() }
    }

    /// Return objects matching a given type. If `recursive` is false, only returns objects from top-level layers.
    ///
    /// - Parameters:
    ///   - ofType: object type to query.
    ///   - recursive: include nested layers.
    /// - Returns: array of objects.
    public func getObjects(ofType: String, recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(ofType: ofType) }
    }

    /// Return objects matching a given name. If `recursive` is false, only returns objects from top-level layers.
    /// - Parameters:
    ///   - named: object name to query.
    ///   - recursive: include nested layers.
    /// - Returns: array of objects.
    public func getObjects(named: String, recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(named: named) }
    }

    /// Return objects with the given text value. If `recursive` is false, only returns objects from top-level layers.
    ///
    /// - Parameters:
    ///   - text: text value.
    ///   - recursive: include nested layers.
    /// - Returns: array of matching objects.
    public func getObjects(withText text: String, recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(withText: text) }
    }

    /// Returns an object with the given **Tiled** id.
    ///
    /// - Parameter id: Object id.
    /// - Returns: object matching the given id.
    public func getObject(withID id: UInt32) -> SKTileObject? {
        return objectGroups(recursive: true).compactMap { $0.getObject(withID: id) }.first
    }

    /// Return object proxies.
    ///
    /// - Returns: array of object proxies.
    internal func getObjectProxies() -> [TileObjectProxy] {
        return objectGroups().flatMap { $0.getObjectProxies() }
    }

    /// Return objects with a tile id. If `recursive` is false, only returns objects from top-level layers.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: objects with a tile gid.
    public func tileObjects(recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.tileObjects() }
    }

    /// Return objects with a tile id. If `recursive` is false, only returns objects from top-level layers.
    ///
    /// - Parameters:
    ///   - globalID: global tile id.
    ///   - recursive: include nested layers.
    /// - Returns: array of objects matching the given tile global id.
    public func tileObjects(globalID: UInt32, recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.tileObjects(globalID: globalID) }
    }

    /// Return text objects. If `recursive` is false, only returns objects from top-level layers.
    ///
    /// - Parameter recursive: include nested layers.
    /// - Returns: text objects.
    public func textObjects(recursive: Bool = true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.textObjects() }
    }

    // MARK: - Physics

    /// Setup tile collision shapes in every layer.
    public func setupTileCollisions() {
        layers.forEach { layer in
            layer.setupTileCollisions()
        }
    }

    // MARK: - Coordinates

    /// Returns true if the coordinate is *valid* (within map bounds).
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: coordinate is valid.
    public func isValid(_ x: Int32, _ y: Int32) -> Bool {
        return defaultLayer.isValid(x, y)
    }

    ///  Returns true if the coordinate is *valid* (within map bounds).
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: coordinate is valid
    public func isValid(coord: simd_int2) -> Bool {
        return isValid(coord.x, coord.y)
    }


    #if os(iOS) || os(tvOS)
    /// Returns a touch location in negative-y space.
    ///   *Position is in converted space*
    ///
    /// - Parameter touch: touch event.
    /// - Returns: converted point in map coordinate system
    public func touchLocation(_ touch: UITouch) -> CGPoint {
        return defaultLayer.touchLocation(touch)
    }

    /// Returns the tile coordinate at a touch location.
    ///
    /// - Parameter touch: touch event.
    /// - Returns: converted point in layer coordinate system.
    public func coordinateAtTouchLocation(_ touch: UITouch) -> CGPoint {
        return defaultLayer.screenToTileCoords(point: touch.location(in: self)).cgPoint
    }
    #endif

    #if os(macOS)

    /// Returns a mouse event location in the default layer. (negative-y space).
    ///   *Position is in converted space*
    ///
    /// - Parameter event: mouse event.
    /// - Returns: converted point in map coordinate system.
    public func mouseLocation(event: NSEvent) -> CGPoint {
        return defaultLayer.mouseLocation(event: event)
    }

    /// Returns the tile coordinate at a mouse event location.
    ///
    /// - Parameter event: mouse event.
    /// - Returns: converted point in layer coordinate system.
    public func coordinateAtMouse(event: NSEvent) -> simd_int2 {
        return defaultLayer.screenToTileCoords(point: mouseLocation(event: event))
    }
    #endif

    // MARK: - Shaders


    /// Set a shader for the map.
    ///
    /// - Parameters:
    ///   - named: shader file name.
    ///   - uniforms: array of shader uniforms.
    ///   - attributes: array of shader attributes.
    public func setShader(named: String, uniforms: [SKUniform] = [], attributes: [SKAttribute] = []) {
        let fshader = SKShader(fileNamed: named)
        fshader.uniforms = uniforms
        fshader.attributes = attributes
        shouldEnableEffects = true
        self.contentRoot.shader = fshader
    }


    // MARK: - Callbacks

    /// Called when parser has finished reading the map.
    ///
    /// - Parameters:
    ///   - timeStarted: render start time.
    ///   - tasks: number of tasks to complete.
    public func didFinishParsing(timeStarted: Date, tasks: Int = 0) {

        #if SKTILED_DEMO

        // call back to the Demo App Delegate
        NotificationCenter.default.post(
            name: Notification.Name.Map.FinishedParsing,
            object: self,
            userInfo: ["parseTime": timeStarted]
        )
        #endif
    }

    /// Called when parser has finished rendering the map.
    ///
    /// - Parameter timeStarted: render start time.
    public func didFinishRendering(timeStarted: Date) {

        // set the `isRendered` property
        isRendered = layers.filter { $0.isRendered == false }.isEmpty

        isInitialized = true

        // set the z-depth of the defaultLayer & background sprite
        defaultLayer.zPosition = -zDeltaForLayers

        // transfer attributes
        scene?.physicsWorld.gravity = gravity

        // delegate callback
        defer {
            self.delegate?.didRenderMap?(self)

            #if SKTILED_DEMO

            // call back to the Demo App Delegate to build the tilemap UI
            NotificationCenter.default.post(
                name: Notification.Name.Map.FinishedRendering,
                object: self,
                userInfo: ["renderTime": timeStarted]
            )
            #endif
        }

        // clamp the position of the map & parent nodes
        clampNodePosition(node: self, scale: TiledGlobals.default.contentScale)

        // set the `SKTilemap.bounds` attribute
        //let vertices = getVertices(offset: CGPoint.zero)

        // set the debug zPosition
        let debugStartZPosition = (lastZPosition + zDeltaForLayers)
        debugNode.zPosition = debugStartZPosition
        debugNode.position = defaultLayer.position
        objectsOverlay.zPosition = debugStartZPosition + (zDeltaForLayers + 100)
        updateProxyObjects()
        calculateXPaths()
    }

    // MARK: - Notifications

    /// Setup notification callbacks.
    internal func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(layerIsolationChanged), name: Notification.Name.Map.LayerIsolationChanged, object: nil)
    }

    /// Regenerate the proxy objects.
    internal func updateProxyObjects() {
        guard let dataStorage = dataStorage,
            let objectsList = dataStorage.objectsList else {
                log("cannot access proxy objects.", level: .error)
                return
        }

        // clear the layer
        objectsOverlay.removeAllChildren()

        var proxyCount = 0

        renderQueue.sync {
            for object in objectsList {
                // create a proxy
                let proxy = TileObjectProxy(object: object, visible: isShowingObjectBounds, renderable: object.isRenderableType)
                self.objectsOverlay.addChild(proxy)
                proxy.container = self.objectsOverlay
                proxy.zPosition = self.zDeltaForLayers
                proxy.draw()
                proxyCount += 1
            }
        }
        objectsOverlay.initialized = true
    }

    /// This method posts tilemap render performance statistics to listeners.
    ///
    /// - Parameters:
    ///   - renderStart: render start date.
    ///   - completion: optional completion function.
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

    /// Toggle tilemap animation rendering as SpriteKit actions.
    ///
    /// - Parameters:
    ///   - value: on/off toggle.
    ///   - restore: restore textures.
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

    /// Called when the map isolation mode changes.
    internal func updateGeometryIsolationMode() {

        print("⭑ geometry isolation mode updated '\(isolationMode)'")


        var doShowTiles = isolationMode.contains(.tiles) || isolationMode.contains(.none)
        var doShowObjects = isolationMode.contains(.objects) || isolationMode.contains(.none)

        let doShowTextObjects = isolationMode.contains(.textObjects)
        let doShowTileObjects = isolationMode.contains(.tileObjects)
        let doShowPointObjects = isolationMode.contains(.pointObjects)


        getTiles().forEach { tile in
            tile.isHidden = !doShowTiles
        }

        getObjects().forEach { obj in

            let objIsText = obj.text != nil
            let objIsTile = obj.tile != nil
            let objIsPoint = obj.objectType == .point


            var hideThisObject = !doShowObjects

            if (objIsText == true && doShowTextObjects == true) {
                hideThisObject = false
            }

            if (objIsTile == true && doShowTileObjects == true) {
                hideThisObject = false
            }

            if (objIsPoint == true && doShowPointObjects == true) {
                hideThisObject = false
            }

            obj.isHidden = hideThisObject
            obj.proxy?.isHidden = hideThisObject
        }
    }

    /// Updates the tilemap as each frame is rendered.
    ///
    /// - Parameter currentTime: update interval.
    public func update(_ currentTime: TimeInterval) {
        guard (isRendered == true) && (isPaused == false) else {
            return
        }


        defer {
            if (syncEveryFrame == true) {
                // sync all queues
                staticTilesQueue.sync {}
                animatedTilesQueue.sync {}
                renderStatistics.updatedThisFrame = 0
            }
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
        guard let dataStorage = dataStorage else {
            log("cannot access tile data storage.", level: .fatal)
            return
        }

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

        if (TiledGlobals.default.enableRenderPerformanceCallbacks == true) {

            // track CPU usage
            if (currentFrameIndex >= renderStatisticsSampleFrequency) {

                // update render statistics
                renderStatistics.updateMode = updateMode
                renderStatistics.objectCount = dataStorage.objectsList?.count ?? 0
                renderStatistics.objectsVisible = (isShowingObjectBounds == true)

                #if SKTILED_DEMO
                renderStatistics.visibleCount = cameraNode?.containedNodeSet().count ?? -1

                #if os(macOS)
                if let scene = self.scene {
                    if let view = scene.view {
                        renderStatistics.trackingViews = UInt32(view.trackingAreas.count)
                    }
                }
                #endif

                // get the cpu usage of the app currently
                renderStatistics.cpuPercentage = Int(cpuUsage())
                #endif

                renderStatistics.effectsEnabled = shouldEnableEffects
                renderStatistics.actionsCount = UInt32(dataStorage.actionsCache.count)

                // cache size
                renderStatistics.cacheSize = dataStorage.sizeString

                // send render statistics back to the controller
                self.postRenderStatistics(renderStart) {
                    self.currentFrameIndex = 0
                }
            }
        }

        currentFrameIndex += 1
    }

    /// Update static tiles.
    ///
    /// - Parameters:
    ///   - delta: current time delta.
    ///   - completion: optional completion closure.
    internal func updateStaticTiles(delta: TimeInterval, _ completion: ((Int) -> Void)? = nil) {
        guard let dataStorage = dataStorage else { return }

        var staticTilesUpdated = 0

        staticTilesQueue.async {

            for staticItem in dataStorage.staticTileCache.enumerated() {

                let tileData = staticItem.element.key
                let tileArray = staticItem.element.value
                let frameTexture = tileData.texture

                // loop through tiles
                for tile in tileArray {

                    // ignore tiles not in view
                    if (tile.visibleToCamera == false) {
                        continue
                    }

                    switch tile.renderMode {

                        // tile is ignoring its tile data, move on
                        case .ignore:
                            continue

                        default:

                            // for `default` & `static`, just update the tile texture and continue...
                            guard let frameTexture = frameTexture else {
                                continue
                            }

                            tile.texture = frameTexture
                            //tile.size = tile.objectSize ?? frameTexture.size()
                            tile.size = frameTexture.size()
                    }

                    staticTilesUpdated += 1
                }
            }

            if (TiledGlobals.default.enableRenderPerformanceCallbacks == true) {
                DispatchQueue.main.async {
                    completion?(staticTilesUpdated)
                }
            }
        }
    }

    /// Update cached aninated tiles.
    ///
    /// - Parameters:
    ///   - delta: current time delta.
    ///   - completion: optional completiom handler.
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
                                //tile.size = tile.objectSize ?? frameTexture.size()
                                tile.size = frameTexture.size()

                        }
                    }
                    animatedTilesUpdated += 1
                }
            }

            if (TiledGlobals.default.enableRenderPerformanceCallbacks == true) {
                DispatchQueue.main.async {
                    completion?(animatedTilesUpdated)
                }
            }
        }
    }

    // MARK: - Chunks

    /// Returns a chunk at the given coordinate.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: array of layer chunks..
    internal func chunksAt(_ x: Int32, _ y: Int32) -> [SKTileLayerChunk] {
        var result: [SKTileLayerChunk] = []
        for tileLayer in tileLayers().reversed() {
            if let chunkAtCoord = tileLayer.chunkAt(coord: simd_int2(x, y)) {
                result.append(chunkAtCoord)
            }
        }
        return result
    }

    /// Returns a chunk at the given coordinate.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    /// - Returns: array of layer chunks..
    internal func chunksAt(coord: simd_int2) -> [SKTileLayerChunk] {
        return chunksAt(coord.x, coord.y)
    }

    // MARK: - Reflection

    /// Returns a custom mirror for this object.
    public var customMirror: Mirror {

        var attributes: [(label: String?, value: Any)] = [
            (label: "name", value: mapName),
            (label: "uuid", uuid),
            (label: "url", value: url.relativePath),
            (label: "isInfinite", value: isInfinite),
            (label: "map size", value: mapSize),
            (label: "tile size", value: tileSize),
            (label: "layer alignment", value: layerAlignment),
            (label: "layers", value: layers),
            (label: "parse time", value: "\(parseTime.milleseconds.stringRoundedTo(2))ms"),
            (label: "render time", value: "\(renderTime.milleseconds.stringRoundedTo(2))ms"),
            (label: "properties", value: mirrorChildren())
        ]


        /// internal debugging attrs
        attributes.append(("tiled element name", tiledElementName))
        attributes.append(("tiled node nice name", tiledNodeNiceName))
        attributes.append(("tiled list description", #"\#(tiledListDescription)"#))
        attributes.append(("tiled menu item description", #"\#(tiledMenuItemDescription)"#))
        attributes.append(("tiled display description", #"\#(tiledDisplayItemDescription)"#))
        attributes.append(("tiled help description", tiledHelpDescription))

        attributes.append(("tiled description", description))
        attributes.append(("tiled debug description", debugDescription))

        return Mirror(self, children: attributes)
    }


    // MARK: - Notification Handlers


    /// Called when a layer is selected to be isolated. Called when the `Notification.Name.Map.LayerIsolationChanged` notification fires.
    ///
    /// - Parameter notification: event notification
    @objc func layerIsolationChanged(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let focusedLayer = notification.object as? TiledLayerObject else {
            getLayers().forEach { $0.isHidden = false }
            return
        }


        let focusedLayerIsIsolated = !focusedLayer.isHidden
        let actionString = (focusedLayerIsIsolated == true) ? "de-isolating" : "isolating"


        print("⭑ \(actionString) layer '\(focusedLayer.layerName)'...")
        let focusedParentLayers = focusedLayer.parentLayers




        for layer in getLayers() {
            if (focusedParentLayers.contains(layer) == true) {
                layer.isHidden = focusedLayerIsIsolated
                if (layer.isHidden == true) {
                    print("  - layer '\(layer.layerName)' is hidden: \(layer.isHidden)")
                }

            } else {
                layer.isHidden = !focusedLayerIsIsolated
                if (layer.isHidden == true) {
                    print("  - layer '\(layer.layerName)' is hidden: \(layer.isHidden)")
                }
            }
        }
    }
}


// MARK: - Extensions

/// :nodoc:
extension TiledGeometryIsolationMode {

    /// Returns an array of string describing the option set.
    public var strings: [String] {
        var result: [String] = []
        if self.contains(.none) {
            result.append("none")
        }
        if self.contains(.tiles ) {
            result.append("Tiles")
        }
        if self.contains(.objects) {
            result.append("Objects")
        }
        if self.contains(.tileObjects) {
            result.append("Tile Objects")
        }
        if self.contains(.textObjects) {
            result.append("Text Objects")
        }
        if self.contains(.pointObjects) {
            result.append("Point Objects")
        }

        return result
    }
}



/// :nodoc:
extension TileUpdateMode: CustomStringConvertible, CustomDebugStringConvertible {

    /// Returns the name of the given mode.
    public var name: String {
        switch self {
            case .dynamic:
                return "dynamic"

            case .full:
                return "full"

            case .actions:
                return "actions"
        }
    }

    /// String representation of the mode.
    public var description: String {
        return self.name
    }

    /// Debug string representation of the mode.
    public var debugDescription: String {
        return self.name
    }
}



extension TileUpdateMode {


    /// Returns an array of all tile update modes.
    ///
    /// - Returns: array of all tile update modes.
    public static func allModes() -> [TileUpdateMode] {
        return [.dynamic, .full, .actions]
    }

    /// Returns the next tile update mode.
    ///
    /// - Returns: next update mode.
    public func next() -> TileUpdateMode {
        switch self {
            case .dynamic: return .full
            case .full: return .actions
            case .actions: return .dynamic
        }
    }

    /// Control string to be used with the render stats menu.
    public var uiControlString: String {
        switch self {
            case .dynamic: return "Dynamic"
            case .full: return "Full"
            case .actions: return "SpriteKit Actions"
        }
    }
}


/// :nodoc:
extension StaggerIndex: Hashable {

    /// Initialize with a string value.
    ///
    /// - Parameter value: string description.
    init?(string value: String) {
        switch value {
            case "even": self = .even
            case "odd":  self = .odd
            default: return nil
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}



/// :nodoc:
extension StaggerAxis: Hashable {

    /// Initialize with a string value.
    ///
    /// - Parameter value: string description.
    init?(string value: String) {
        switch value {
            case "x": self = .x
            case "y":  self = .y
            default: return nil
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}



/// :nodoc:
extension LayerPosition: CustomStringConvertible {
    
    /// Initialize with a string value.
    ///
    /// - Parameter value: string description.
    init?(string value: String) {
        switch value.lowercased() {
            case "bottomleft", "bottom-left":
                self = .bottomLeft
                
            case "center":
                self = .center

            case "topright", "top-right":
                self = .topRight
                
            default: return nil
        }
    }
    
    /// Returns the layer position name.
    internal var name: String {
        switch self {
            case .bottomLeft: return "Bottom Left"
            case .center: return "Center"
            case .topRight: return "Top Right"
        }
    }

    /// Returns the anchor point for aligning the map's child layers.
    internal var anchorPoint: CGPoint {
        switch self {
            case .bottomLeft: return CGPoint(x: 0, y: 0)
            case .center: return CGPoint(x: 0.5, y: 0.5)
            case .topRight: return CGPoint(x: 1, y: 1)
        }
    }

    internal var description: String {
        return "\(name): (\(self.anchorPoint.x), \(self.anchorPoint.y))"
    }
}



/// Convenience properties & methods.
extension SKTilemap {

    /// String representing the map name (ie: `dungeon-16x16`).
    ///
    /// Defaults to the current map source file name (minus the tmx extension).
    public var mapName: String {
        if let dname = self.displayName {
            return dname
        }
        return self.name ?? "map"
    }

    /// Auto-sizing property for map orientation.
    public var isPortrait: Bool {
        return sizeInPoints.height > sizeInPoints.width
    }

    /// Returns the width (in tiles) of the map.
    public var width: CGFloat {
        return mapSize.width
    }

    /// Returns the height (in tiles) of the map.
    public var height: CGFloat {
        return mapSize.height
    }

    /// Returns the tile width (in pixels) value.
    public var tileWidth: CGFloat {
        switch orientation {
            case .staggered:
                return CGFloat(Int(tileSize.width) & ~1)
            default:
                return tileSize.width
        }
    }

    /// Returns the tile size height (in pixels).
    ///
    /// - Returns: tile size height.
    public var tileHeight: CGFloat {
        switch orientation {
            case .staggered:
                return CGFloat(Int(tileSize.height) & ~1)
            default:
                return tileSize.height
        }
    }
    
    /// Returns the tile size width (in pixels), halved.
    ///
    /// - Returns: tile size half-width.
    public var tileWidthHalf: CGFloat {
        return tileWidth / 2
    }
    
    /// Returns the tile size height (in pixels), halved.
    ///
    /// - Returns: tile size half-height.
    public var tileHeightHalf: CGFloat {
        return tileHeight / 2
    }
    
    /// Returns the container size (in tiles), halved.
    ///
    /// - Returns: container size in tiles, halved.
    public var sizeHalved: CGSize {
        return CGSize(width: mapSize.width / 2, height: mapSize.height / 2)
    }
    
    /// Returns the container tile size (in pixels), halved.
    ///
    /// - Returns: container tile size in tiles, halved.
    public var tileSizeHalved: CGSize {
        return CGSize(width: tileWidthHalf, height: tileHeightHalf)
    }

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

    /// Returns true if the given x-coordinate represents a staggered (offset) column.
    ///
    /// - Parameter x: map x-coordinate.
    /// - Returns: column should be staggered.
    internal func doStaggerX(_ x: Int) -> Bool {
        let hash: Int = (staggerEven == true) ? 1 : 0
        return staggerX && Bool((x & 1) ^ hash)
    }

    /// Returns true if the given y-coordinate represents a staggered (offset) row.
    ///
    /// - Parameter y: map y-coordinate.
    /// - Returns: row should be staggered.
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

    /// Returns all pathfinding graphs in the map.
    public var graphs: [GKGridGraph<GKGridGraphNode>] {
        return tileLayers().compactMap { $0.graph }
    }

    /// Returns an array of renderable tiles/objects.
    ///
    /// - Returns: array of child objects.
    public func renderableObjects() -> [SKNode] {
        var result: [SKNode] = []
        enumerateChildNodes(withName: ".//*") { node, stop in
            if (node as? TiledGeometryType != nil) {
                result.append(node)
            }
        }
        return result
    }

    /// Returns an array of animated tiles/objects.
    ///
    /// - Returns: array of child objects.
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
    /// Highlight the map with a given color & duration.
    ///
    /// - Parameters:
    ///   - color: highlight color.
    ///   - duration: duration of highlight effect.
    @objc public override func highlightNode(with color: SKColor, duration: TimeInterval = 0) {

        let highlightFillColor = color.withAlphaComponent(0.2)

        boundsShape?.strokeColor = color
        boundsShape?.fillColor = highlightFillColor
        boundsShape?.isHidden = false

        anchorShape.fillColor = color
        anchorShape.isHidden = false

        if (duration > 0) {
            let fadeInAction = SKAction.colorize(withColorBlendFactor: 1, duration: duration)

            let groupAction = SKAction.group(
                [
                    fadeInAction,
                    SKAction.wait(forDuration: duration),
                    fadeInAction.reversed()
                ]
            )

            boundsShape?.run(groupAction, completion: {
                self.boundsShape?.isHidden = true
                self.anchorShape.isHidden = true
                self.isFocused = false
            })
        }
    }

    /// Remove the current object's highlight color.
    @objc public override func removeHighlight() {
        boundsShape?.isHidden = true
        anchorShape.isHidden = true
    }
}


/// :nodoc:
extension SKTilemap: TiledCustomReflectableType {

    /// Dump a summary of the current tilemap's layer statistics to the console.
    public func dumpStatistics() {
        guard (layerCount > 0) else {
            print("# Tilemap '\(mapName)': 0 Layers")
            return
        }

        // collect graphs for each tile layer
        let graphs = tileLayers().compactMap { $0.graph }

        // format the header
        let graphsString = (graphs.isEmpty == false) ? (graphs.count > 1) ? " : \(graphs.count) Graphs" : " : \(graphs.count) Graph" : ""
        let headerString = "# Tilemap '\(mapName)': \(tileCount) Tiles: \(layerCount) Layers\(graphsString)"
        let titleUnderline = String(repeating: "-", count: headerString.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        //let columnTitles = ["Index", "Type", "Visible", "Name", "Position", "Size", "Offset", "Anchor", "Z-Position", "Opacity", "Update", "Static", "Graph"]
        let allLayers = self.layers.filter { $0 as? TiledBackgroundLayer == nil }

        // get the stats from each layer
        let allLayerStats = allLayers.map { $0.layerOneLineDescrption }

        // prefix for each column
        let prefixes: [String] = ["", "", "", "", "pos", "size", "offset", "anc", "zpos", "opac", "nav"]

        // buffer for each column
        let buffers: [Int] = [1, 2, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        var columnSizes: [Int] = Array(repeating: 0, count: prefixes.count)

        // get the max column size for each column
        for (_, stats) in allLayerStats.enumerated() {
            for stat in stats {
                let cindex = Int(stats.firstIndex(of: stat)!)

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
                layerOutputString += currentColumnValue.padRight(toLength: fillSize, withPad: " ")
            }
            outputString += "\n\(layerOutputString)"
        }
        
        
        
        
        
        

        print("\n\n" + outputString + "\n\n")
    }

    /// Dump the contents of all tile layers' tile data to the console.
    ///
    /// - Parameters:
    ///   - spacing: spacing length.
    ///   - recursive: include nested layers.
    public func dumpTileLayerData(spacing: Int = 3, recursive: Bool = true) {
        for tileLayer in tileLayers(recursive: recursive) {
            tileLayer.dumpTileLayerData(spacing: spacing)
        }
    }
}


/// :nodoc:
extension TilemapOrientation {

    /// Initialize with a string value.
    ///
    /// - Parameter stringValue: string description.
    public init?(string value: String) {
        switch value {
            case "orthogonal":
                self = TilemapOrientation.orthogonal
            case "isometric":
                self = TilemapOrientation.isometric
            case "hexagonal":
                self = TilemapOrientation.hexagonal
            case "staggered":
                self = TilemapOrientation.staggered
            default:
                return nil
        }
    }


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
            default:
                return CGPoint(x: 0.5, y: 0.5)
        }
    }
}

/// :nodoc:
extension TilemapOrientation: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
            case .orthogonal: return "orthogonal"
            case .isometric: return "isometric"
            case .hexagonal: return "hexagonal"
            case .staggered: return "staggered"
            default: return "unknown"
        }
    }

    public var debugDescription: String {
        return description
    }
}


extension SKTilemap.RenderStatistics {

    /// Create a copy of the current render statistics.
    ///
    /// - Returns: render statistics for the current frame.
    public func copy() -> SKTilemap.RenderStatistics {
        return SKTilemap.RenderStatistics(updateMode: self.updateMode, objectCount: self.objectCount,
                                          visibleCount: self.visibleCount, cpuPercentage: self.cpuPercentage,
                                          effectsEnabled: self.effectsEnabled, updatedThisFrame: self.updatedThisFrame,
                                          objectsVisible: self.objectsVisible, actionsCount: self.actionsCount,
                                          cacheSize: self.cacheSize, renderTime: 0, trackingViews: self.trackingViews)
    }
}


// MARK: - Camera Delegate Methods


/// :nodoc: Clamp position of the map & parents when camera changes happen.
extension SKTilemap: TiledSceneCameraDelegate {

    /// Called when the camera bounds updated.
    ///
    /// - Parameters:
    ///   - bounds: camera view bounds.
    ///   - position: camera position.
    ///   - zoom: camera zoom amount.
    public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {
        cameraBounds = bounds
    }

    /// Called when the camera position changes.
    ///
    /// - Parameter newPosition: updated camera position.
    public func cameraPositionChanged(newPosition: CGPoint) {
        defer {
            cameraPosition = newPosition
        }
        
        let dampen: CGFloat = 0.5
        let delta = cameraPosition.delta(to: newPosition)
        
        // Move layers according to their parallax values
        getLayers().forEach { layer in
            let layerParallax = layer.parallax
            
            if (layerParallax.x != 1) {
                layer.position.x -= (delta.x * layer.parallax.x) * dampen
            }
            
            if (layerParallax.y != 1) {
                layer.position.y += (delta.y * layer.parallax.y) * dampen
            }
        }
    }

    /// Called when the camera zoom changes.
    ///
    /// - Parameter newZoom: camera zoom amount.
    public func cameraZoomChanged(newZoom: CGFloat) {
        //let oldZoom = currentZoom
        currentZoom = newZoom
        antialiasLines = (newZoom < 1)
    }

    #if os(iOS) || os(tvOS)

    /// Called when the scene receives a double-tap event **(iOS only)**.
    ///
    /// - Parameter location: touch event location.
    public func sceneDoubleTapped(location: CGPoint) {
        // TODO: implement this
    }

    #else



    /// Handler for when the scene is clicked **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc public func sceneClicked(event: NSEvent) {
        let nodesAtClickLocation = handleMouseEvent(event: event)
        
        guard let firstNode = nodesAtClickLocation.first else {
            print("no nodes clicked.")
            return
        }
        print("⭑ [SKTilemap]: node clicked: \(firstNode.description)")
        firstNode.mouseDown(with: event)
    }

    /// Called when the scene is double-clicked **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc public func sceneDoubleClicked(event: NSEvent) {
        // TODO: implement this
    }

    /// Called when the mouse moves in the scene **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc public func mousePositionChanged(event: NSEvent) {
        //currentCoordinate = coordinateAtMouse(event: event)
        #if SKTILED_DEMO
        let lastCoordinate = currentCoordinate

        // TODO: add filtering options here
        let nodesAtClickLocation = handleMouseEvent(event: event)
        let coordDelta = currentCoordinate.delta(to: lastCoordinate)

        // TODO: if something is currently selected, don't send this notification
        if coordDelta.magnitude() >= 1 {
            /// calls back to `MousePointer` & `GameViewController`
            NotificationCenter.default.post(
                name: Notification.Name.Demo.NothingUnderCursor,
                object: nil
            )
        }

        for node in nodesAtClickLocation {

            if let object = node as? SKTileObject {

                /// calls back to `MousePointer` & `GameViewController`
                NotificationCenter.default.post(
                    name: Notification.Name.Demo.ObjectUnderCursor,
                    object: object
                )

                return
            }

            if let tile = node as? SKTile {

                /// calls back to `MousePointer` & `GameViewController`
                NotificationCenter.default.post(
                    name: Notification.Name.Demo.TileUnderCursor,
                    object: tile
                )

                return

            }
        }
        #endif
    }

    /// Filters objects at the given mouse event.
    ///
    /// - Parameter event: mouse event.
    /// - Returns: array of nodes at the event.
    internal func handleMouseEvent(event: NSEvent) -> [SKNode] {
        currentCoordinate = coordinateAtMouse(event: event)

        // TODO: test this method
        //let tilesAtMapCoordinate = tilesAt(coord: currentCoordinate).filter { $0.isHidden == false }

        // TODO: check tiles for coordinate match? this is very inaccurate in isometric & staggered maps
        
        // can't filter by `isFocused` until highlight functions are finished
        // var result = tiledNodes(at: event.location(in: self)).filter { $0.isFocused == false } as! [SKNode]
        var result = tiledNodes(at: event.location(in: self)) as! [SKNode]
        
        let clickedProxies = objectsOverlay.nodes(at: event.location(in: objectsOverlay)).filter { $0 as? TileObjectProxy != nil} as! [TileObjectProxy]

        if let firstProxy = clickedProxies.first {
            if let object = firstProxy.reference {
                result.insert(object, at: 0)
            }
        }
        return result
    }

    #endif
    

    /// Calculate the xPath values of the layers.
    internal func calculateXPaths() {
        let rootPath = #"/\#(tiledElementName)"#

        for (i, layer) in layers.enumerated() {

            let tiledlayer = layer as TiledCustomReflectableType

            if let nodeType = tiledlayer.tiledElementName {
                let layerPathName = "\(nodeType)[\(i)]"
                let thisLayerPath = rootPath + #"/\#(layerPathName)"#
                layer.xPath = thisLayerPath

                if let tilelayer = layer as? SKTileLayer {
                    /// currentPath: ''
                    for (x, chunk) in tilelayer.chunks.enumerated() {
                        let chunkPathName = "\(chunk.tiledElementName)[\(x)]"
                        let thisNodePath = thisLayerPath + #"/\#(chunkPathName)"#
                        chunk.xPath = thisNodePath
                        chunk.name = chunkPathName
                    }
                }
            }
        }
    }
}



// MARK: Tile Data Cache Optimizations

/// :nodoc: These are similar to existing methods, but added to test whether it is faster to access the tile data storage.
extension SKTilemap {

    /// Returns a SpriteKit action for the given global id (if one exists).
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: SpriteKit action for the given id.
    public func actionFor(globalID: UInt32) -> SKAction? {
        return dataStorage?.tileAnimationAction(globalID: globalID)
    }

    /// Returns an array of tiles matching the given global id.
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: array of tiles with the given global id.
    public func allTiles(globalID: UInt32) -> [SKTile]? {
        return dataStorage?.allTiles(globalID: globalID)
    }

    /// Returns an array of tiles matching the given type.
    ///
    /// - Parameter ofType: tile type.
    /// - Returns: array of tiles with the given type.
    public func allTiles(ofType: String) -> [SKTile]? {
        return dataStorage?.allTiles(ofType: ofType)
    }
}


// MARK: - Debug Descriptions

/// :nodoc:
extension SKTilemap {

    /// String representation of the map.
    public override var description: String {
        var result = tiledNodeNiceName.titleCased()

        result += " '\(mapName)' "
        result += " orientation: '\(orientation.description)' "

        let mapsizeString = (isInfinite == false) ? "map size: \(sizeInPoints)" : "map size: 'infinite'"
        result += "\(mapsizeString) size: \(mapSize) tile size: \(tileSize) "

        if (orientation == .staggered) {
            result += "axis: '\(staggeraxis)' index: '\(staggerindex)'"
        }

        return result
    }

    /// Debug string representation of the map.
    public override var debugDescription: String {
        var result = className

        result += " '\(mapName)' "
        result += " orientation: '\(orientation.description)' "


        let mapsizeString = (isInfinite == false) ? "map size: \(sizeInPoints)" : "map size: 'infinite'"
        result += "\(mapsizeString) size: \(mapSize) tile size: \(tileSize) "

        if (orientation == .staggered) {
            result += "axis: '\(staggeraxis)' index: '\(staggerindex)'"
        }

        if (url != nil) {
            result += " url: '\(url.relativePath)'"
        }

        return #"<\#(result)>"#
    }
}


/// :nodoc:
extension SKTilemap {


    /// Returns the internal **Tiled** node type.
    @objc public var tiledElementName: String {
        return "map"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return (isInfinite == true) ? "infinite map" : "tilemap"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "map-icon"
    }

    /// A description of the node.
    @objc public var tiledListDescription: String {
        return "\(tiledNodeNiceName.titleCased()): '\(mapName)'"
    }

    /// A description of the node used in dropdown & popu menus.
    @objc public var tiledMenuItemDescription: String {
        return "\(tiledNodeNiceName.titleCased()): '\(mapName)'"
    }

    /// A description of the node used for debug output text.
    @objc public var tiledDisplayItemDescription: String {
        let mapNameString = "'\(mapName)'"
        return #"<\#(className)\#(mapNameString)>"#
    }

    /// Description of the node type.
    @objc public var tiledHelpDescription: String {
        return "Map container node."
    }

    /// Returns a string suitable for a UI widget to display as a tooltip.
    @objc public var tiledTooltipDescription: String {
        return "/map"
    }
}



// MARK: - Deprecations


extension SKTilemap {

    /// Container size (in tiles).
    @available(*, deprecated, renamed: "mapSize")
    public internal(set) var size: CGSize {
        get {
            return mapSize
        } set {
            mapSize = newValue
        }
    }

    /// Load a Tiled tmx file and return a new `SKTilemap` object. Returns nil if there is a problem reading the file.
    ///
    /// - Parameters:
    ///   - filename: Tiled file name.
    ///   - delegate: optional [`TilemapDelegate`](Protocols/TilemapDelegate.html) instance.
    ///   - withTilesets: optional tilesets.
    /// - Returns: tilemap object.
    @available(*, deprecated, renamed: "SKTilemap.load(tmxFile:)")
    public class func load(fromFile filename: String,
                           delegate: TilemapDelegate? = nil,
                           withTilesets: [SKTileset]? = nil) -> SKTilemap? {

        return SKTilemap.load(tmxFile: filename, inDirectory: nil, delegate: delegate, withTilesets: withTilesets)
    }

    /// Returns an array of all child layers, sorted by index (first is lowest, last is highest).
    ///
    /// - Returns: array of layers.
    @available(*, deprecated, message: "use `getLayers()` instead")
    public func allLayers() -> [TiledLayerObject] {
        return layers.sorted(by: { $0.index < $1.index })
    }

    /// Returns a named tile layer from the layers set.
    ///
    /// - Parameter layerName: tile layer name.
    /// - Returns: layer object.
    @available(*, deprecated, message: "use `getLayers(named:)` instead")
    public func getLayer(named layerName: String) -> TiledLayerObject? {
        if let index = layers.index(where: { $0.name == layerName }) {
            let layer = layers[index]
            return layer
        }
        return nil
    }

    /// Returns a named tile layer if it exists, otherwise, nil.
    ///
    /// - Parameter name: tile layer name.
    /// - Returns: matching tile layer.
    @available(*, deprecated, message: "use `tileLayers(named:)` instead")
    public func tileLayer(named name: String) -> SKTileLayer? {
        if let layerIndex = tileLayers().index(where: { $0.name == name }) {
            let layer = tileLayers()[layerIndex]
            return layer
        }
        return nil
    }

    /// Returns a named object group if it exists, otherwise, nil.
    ///
    /// - Parameter name: tile layer name.
    /// - Returns: object layer matching the given name, if one exists.
    @available(*, deprecated, message: "use `objectGroups(named:)` instead")
    public func objectGroup(named name: String) -> SKObjectGroup? {
        if let layerIndex = objectGroups().index(where: { $0.name == name }) {
            let layer = objectGroups()[layerIndex]
            return layer
        }
        return nil
    }

    /// Output a summary of the current scenes layer data.
    ///
    /// - Parameter reverse: reverse layer order.
    @available(*, deprecated, message: "use `dumpStatistics` instead")
    public func debugLayers(reverse: Bool = false) {
        dumpStatistics()
    }

    /// Minimum zoom level for the map.
    @available(*, deprecated, renamed: "zoomConstraints.min")
    public var minZoom: CGFloat {
        get {
            return zoomConstraints.min
        } set {
            zoomConstraints.min = newValue
        }
    }

    /// Maximum zoom level for the map.
    @available(*, deprecated, renamed: "zoomConstraints.max")
    public var maxZoom: CGFloat {
        get {
            return zoomConstraints.max
        } set {
            zoomConstraints.max = newValue
        }
    }

    /// Returns the render time of this map.
    @available(*, deprecated, renamed: "renderTime")
    public var mapRenderTime: TimeInterval {
        return renderTime
    }

    /// Returnas true if any of the child layers is showing a graph visual.
    @available(*, deprecated, renamed: "isShowingGridGraph")
    public var isShowingGraphs: Bool {
        let visibleGraphLayers = tileLayers().filter{ tileLayer in
            tileLayer.debugDrawOptions.contains(.drawGraph) == true
        }
        return (visibleGraphLayers.isEmpty == false)
    }

    /// Show objects for the given layers.
    ///
    /// - Parameter forLayers: array of layers.
    @available(*, deprecated, message: "use `debugDrawOptions` instead")
    public func showObjects(forLayers: [TiledLayerObject]) {
        forLayers.forEach { layer in
            if let objGroup = layer as? SKObjectGroup {
                objGroup.isShowingObjectBounds = true
            }
        }
    }

    /// Returns the tileset associated with a global id.
    ///
    /// - Parameter forTile: tile global id.
    /// - Returns: associated tileset.
    @available(*, deprecated, renamed: "getTilesetFor(globalID:)")
    public func getTileset(forTile: Int) -> SKTileset? {
        return getTilesetFor(globalID: UInt32(forTile))
    }

    /// Returns an object with the given **Tiled** id.
    ///
    /// - Parameter id: Object id.
    /// - Returns: object matching the given id.
    @available(*, deprecated, renamed: "getObject(withID:)")
    public func getObject(withID id: Int) -> SKTileObject? {
        return objectGroups(recursive: true).compactMap { $0.getObject(withID: id) }.first
    }

    /// Return objects with a tile id. If `recursive` is false, only returns objects from top-level layers.
    ///
    /// - Parameters:
    ///   - globalID: global tile id.
    ///   - recursive: include nested layers.
    /// - Returns: array of objects matching the given tile global id.
    @available(*, deprecated, renamed: "tileObjects(globalID:recursive:)")
    public func tileObjects(globalID: Int, recursive: Bool = true) -> [SKTileObject] {
        return tileObjects(globalID: UInt32(globalID), recursive: recursive)
    }

    /// Returns tiles with the given global id. If `recursive` is false, only returns tiles from top-level layers.
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - recursive: include nested layers.
    /// - Returns: array of tiles.
    @available(*, deprecated, renamed: "getTiles(globalID:recursive:)")
    public func getTiles(globalID: Int, recursive: Bool = true) -> [SKTile] {
        return getTiles(globalID: UInt32(globalID), recursive: recursive)
    }

    /// Returns true if the coordinate is valid.
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: coordinate is valid.
    @available(*, deprecated, renamed: "isValid(coord:)")
    public func isValid(coord: CGPoint) -> Bool {
        return defaultLayer.isValid(Int32(coord.x), Int32(coord.y))
    }

    /// Return tiles at the given point (all tile layers).
    ///
    /// - Parameter point: position in tilemap.
    /// - Returns: array of tiles.
    @available(*, deprecated, message: "???")
    public func tilesAt(point: CGPoint) -> [SKTile] {
        return nodes(at: point).filter { node in
            node as? SKTile != nil
        } as! [SKTile]
    }

    /// Return tiles at the given coordinate (all tile layers).
    ///
    /// - Parameter coord: coordinate.
    /// - Returns: array of tiles.
    @available(*, deprecated, renamed: "tilesAt(coord:)")
    public func tilesAt(coord: CGPoint) -> [SKTile] {
        return tileLayers(recursive: true).compactMap { $0.tileAt(coord: coord) }.reversed()
    }

    /// Returns the *first* tile at the given coordinate from a layer.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    ///   - named: layer name.
    /// - Returns: matching tile, if one exists.
    @available(*, deprecated, renamed: "tileAt(coord:simd_int2:inLayer:)")
    public func tileAt(coord: CGPoint, inLayer named: String?) -> SKTile? {
        return tileAt(coord: simd_int2(Int32(coord.x), Int32(coord.y)), inLayer: named)
    }

    /// Return the top-most tile at the given coordinate.
    ///
    /// - Parameter coord: coordinate.
    /// - Returns: first tile in layers.
    @available(*, deprecated, renamed: "firstTileAt(coord:)")
    public func firstTileAt(coord: CGPoint) -> SKTile? {
        for layer in tileLayers(recursive: true).reversed().filter({ $0.visible == true }) {
            if let tile = layer.tileAt(coord: coord) {
                return tile
            }
        }
        return nil
    }

    /// Returns a tile coordinate for a given `simd_int2` coordinate.
    ///
    /// - Parameter vec2: `simd_int2` coordinate
    /// - Returns: position in map.
    @available(*, deprecated, renamed: "pointForCoordinate(coord:)")
    public func pointForCoordinate(vec2: simd_int2) -> CGPoint {
        return pointForCoordinate(coord: vec2)
    }

    /// Returns a tile coordinate for a given point in the layer.
    ///
    /// - Parameter point: point in layer.
    /// - Returns: tile coordinate.
    @available(*, deprecated, renamed: "coordinateForPoint(point:)")
    public func coordinateForPoint(_ point: CGPoint) -> CGPoint {
        return coordinateForPoint(point: point).cgPoint
    }


    /// Returns a tile coordinate for a given point in the layer as a simd_int2.
    ///
    /// - Parameter point: point in layer.
    /// - Returns: tile coordinate
    @available(*, deprecated, message: "use coordinateForPoint(point:)")
    public func vectorCoordinateForPoint(_ point: CGPoint) -> simd_int2 {
        return coordinateForPoint(point: point)
    }

    #if os(macOS)
    /// Returns the tile coordinate at a mouse event location.
    ///
    /// - Parameter event: mouse event.
    /// - Returns: converted point in layer coordinate system.
    @available(*, deprecated, renamed: "coordinateAtMouse(event:)")
    public func coordinateAtMouseEvent(event: NSEvent) -> CGPoint {
        // FIXME: rename this back to what it was!
        return coordinateAtMouse(event: event).cgPoint
    }
    #endif

    /// Returns a layer given the index (0 being the lowest).
    ///
    /// - Parameter index: layer index.
    /// - Returns: layer object.
    @available(*, deprecated, renamed: "getLayer(atIndex:)")
    public func getLayer(atIndex index: Int) -> TiledLayerObject? {
        return getLayer(atIndex: UInt32(index))
    }

    /// Global property to show/hide all `SKTileObject` objects.
    @available(*, deprecated, renamed: "isShowingObjectBounds")
    public var showObjects: Bool {
        get {
            return isShowingObjectBounds
        } set {
            guard newValue != isShowingObjectBounds else {
                return
            }
            isShowingObjectBounds = newValue
        }
    }
}
