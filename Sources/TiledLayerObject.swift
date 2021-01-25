//
//  TiledLayerObject.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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
import GameplayKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


// Tuple representing the current render stats for a given frame.
typealias RenderInfo = (idx: UInt32, path: String, zpos: Double,
    sw: Int, sh: Int, tsw: Int, tsh: Int,
    offx: Int, offy: Int, ancx: Int, ancy: Int,
    tc: Int, obj: Int, vis: Int, gn: Int?)



/// Layer render statistics.
typealias LayerRenderStatistics = (tiles: Int, objects: Int)


/// ## Overview
///
/// The `TiledLayerObject` is the generic base class for all layer types.  This class doesn't
/// define any object or child types, but provides base behaviors for layered content, including:
///
/// - coordinate transformations
/// - validating coordinates
/// - positioning and alignment
///
///
/// ### Properties
///
/// | Property    | Description                                                          |
/// |-------------|----------------------------------------------------------------------|
/// | tilemap     | Parent tilemap.                                                      |
/// | index       | Layer index. Matches the index of the layer in the source TMX file.  |
/// | size        | Layer size (in tiles).                                               |
/// | tileSize    | Layer tile size (in pixels).                                         |
/// | anchorPoint | Layer anchor point, used to position layers.                         |
/// | origin      | Layer origin point, used for placing tiles.                          |
///
///
/// ### Instance Methods
///
/// | Method                            | Description                                                          |
/// |-----------------------------------|----------------------------------------------------------------------|
/// | pointForCoordinate(coord:offset:) | Returns a point for a coordinate in the layer, with optional offset. |
/// | coordinateForPoint(_:)            | Returns a tile coordinate for a given point in the layer.            |
/// | touchLocation(_:)                 | Returns a converted touch location in map space. (iOS only)          |
/// | coordinateAtTouchLocation(_:)     | Returns the tile coordinate at a touch location. (iOS only)          |
/// | isValid(coord:)                   | Returns true if the coordinate is valid.                             |
///
///
/// ### Usage
///
/// Coordinate transformation functions return points in the current tilemap projection:
///
/// ```swift
/// node.position = tileLayer.pointForCoordinate(2, 1)
/// ```
/// Coordinate transformation functions translate points to map coordinates:
///
/// ```swift
/// coord = coordinateForPoint(touchPosition)
/// ```
///
/// Return the tile coordinate at a touch event (iOS):
///
/// ```swift
/// coord = imageLayer.coordinateAtTouchLocation(touchPosition)
/// ```
///
/// Return the tile coordinate at a mouse event (macOS):
///
/// ```swift
/// coord = groupLayer.coordinateAtMouse(event: mouseClicked)
/// ```
public class TiledLayerObject: SKEffectNode, CustomReflectable, TiledMappableGeometryType, TiledAttributedType {

    /// Reference to the parent tilemap.
    unowned let tilemap: SKTilemap

    /// Reference to the mappable parent.
    unowned let mapDelegate: TiledMappableGeometryType

    /// Unique layer id.
    public var uuid: String = UUID().uuidString

    /// Layer type.
    public var type: String!

    /// Map orientation.
    public var orientation: TilemapOrientation

    /// Layer has no boundaries.
    @objc public internal(set) var isInfinite: Bool = false

    /// Tile size (in pixels).
    public var tileSize: CGSize

    /// Hexagonal side length.
    public var hexsidelength: Int = 0

    /// Hexagonal stagger axis.
    public var staggeraxis: StaggerAxis = StaggerAxis.y

    /// Hexagonal stagger index.
    public var staggerindex: StaggerIndex = StaggerIndex.odd

    /// Logging verbosity.
    internal var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    // MARK: - Layer Index

    /// Layer index. Matches the **id value** of the layer in the source TMX file.
    public var index: UInt32 = 0

    /// Position in the render tree.
    public var rawIndex: UInt32 = 0

    /// Flattened layer index (internal use only).
    internal var realIndex: UInt32 {
        guard let firstIndex = tilemap.layers.firstIndex(where: { $0 === self }) else {
            return self.index
        }
        return UInt32(firstIndex)
    }

    /// The layer XPath.
    public var xPath: String = #"/"#
    
    /// Translate the parent hierarchy to an layer path string.
    public var path: String {
        let allParents: [SKNode] = parents.filter( { $0 as? SKTilemap == nil } ).reversed()
        if (allParents.count == 1) {
            return layerName
        }
        
        return allParents.reduce("") { result, node in
            let divider = allParents.firstIndex(of: node)! < allParents.count - 1 ? "/" : ""
            return result + "\(node.name ?? "element")" + divider
        }
    }

    // MARK: - Layer Properties

    /// Custom layer properties.
    public var properties: [String: String] = [:]

    /// Ignore custom node properties.
    public var ignoreProperties: Bool = false

    /// ## Overview
    ///
    /// Enum describing layer type.
    ///
    /// ### Constants
    ///
    /// | Property    | Description                               |
    /// |:------------|:------------------------------------------|
    /// | tile        | Layer contains tile sprite data.          |
    /// | object      | Layer contains vector objects, text, etc. |
    /// | image       | Layer contains a static image.            |
    /// | group       | Layer container.                          |
    ///
    enum TiledLayerType: Int {
        case none     = -1
        case tile
        case object
        case image
        case group
    }

    /// ## Overview
    ///
    /// Tile offset hint for coordinate conversion.
    ///
    /// ### Constants
    ///
    /// | Property    | Description                               |
    /// |:------------|:------------------------------------------|
    /// | center      | Tile is centered.                         |
    /// | top         | Tile is offset at the top.                |
    /// | topLeft     | Tile is offset at the upper left.         |
    /// | topRight    | Tile is offset at the upper right.        |
    /// | bottom      | Tile is offset at the bottom.             |
    /// | bottomLeft  | Tile is offset at the bottom left.        |
    /// | bottomRight | Tile is offset at the bottom right.       |
    /// | left        | Tile is offset at the left side.          |
    /// | right       | Tile is offset at the right side.         |
    ///
    public enum TileOffset: Int {
        case center
        case top
        case topLeft
        case topRight
        case bottom
        case bottomLeft
        case bottomRight
        case left
        case right
    }


    /// Layer is visible to scene cameras.
    @objc public var visibleToCamera: Bool = true

    /// The type of objects contained in this layer.
    internal var layerType: TiledLayerType = TiledLayerType.none

    // MARK: - Colors

    /// Layer color.
    public var color: SKColor = TiledObjectColors.gun

    /// Grid visualization color.
    public var gridColor: SKColor = TiledGlobals.default.debug.gridColor

    /// Bounding box color.
    public var frameColor: SKColor = TiledGlobals.default.debug.frameColor

    /// Layer highlight color (for highlighting tiles)
    public var highlightColor: SKColor = SKColor.white

    /// Layer proxy object color.
    internal var proxyColor: SKColor?

    /// Layer tint color.
    public var tintColor: SKColor? {
        didSet {
            guard let newColor = tintColor else {

                // reset color blending attributes
                colorBlendFactor = 0
                color = SKColor(hexString: "#ffffff00")
                blendMode = .alpha
                return
            }

            self.color = newColor
            self.blendMode = TiledGlobals.default.layerTintAttributes.blendMode
            self.colorBlendFactor = 1
        }
    }

    /// Sprite to allow for color tinting.
    lazy internal var tintSprite: SKSpriteNode? = {
        let sprite = SKSpriteNode(color: SKColor.clear, size: sizeInPoints)
        sprite.anchorPoint = CGPoint.zero
        addChild(sprite)
        sprite.zPosition = zPosition + 1
        return sprite
    }()

    /// Layer bounding shape.
    public lazy var boundsShape: SKShapeNode? = {
        let scaledverts = getVertices().map { $0 * renderQuality }
        let objpath = polygonPath(scaledverts)
        let shape = SKShapeNode(path: objpath)
        shape.lineWidth = TiledGlobals.default.renderQuality.object * 1.5
        shape.setScale(1 / renderQuality)
        addChild(shape)
        shape.zPosition = zPosition + 1
        return shape
    }()

    /// Layer highlight duration.
    public var highlightDuration: TimeInterval = TiledGlobals.default.debug.highlightDuration

    /// Layer is isolated.
    public private(set) var isolated: Bool = false

    /// Layer is static (not moving).
    public internal(set) var isStatic: Bool = false

    /// Static sprite texture.
    internal var staticTexture: SKTexture?

    /// Static sprite.
    internal var staticSprite: SKSpriteNode?

    // MARK: Sizing & Positioning

    /// Layer offset value (in pixels).
    public var offset: CGPoint = CGPoint.zero

    /// Container size (in tiles).
    public internal(set) var mapSize: CGSize

    /// Layer anchor point, used to position layers.
    public var anchorPoint: CGPoint {
        // TODO: add to new protocol?
        return tilemap.layerAlignment.anchorPoint
    }

    /// Storage for gid errors that occur in parsing.
    internal var gidErrors: [simd_int2: UInt32] = [:]

    /// Pathfinding graph.
    @objc public weak var graph: GKGridGraph<GKGridGraphNode>?

    // Debug visualizations.
    public var gridOpacity: CGFloat = TiledGlobals.default.debug.gridOpactity

    /// Debug visualization node
    internal var debugNode: TiledDebugDrawNode!

    /// Debug visualization options.
    @objc public var debugDrawOptions: DebugDrawOptions = [] {
        didSet {
            guard oldValue != debugDrawOptions else { return }
            debugNode?.draw()
        }
    }

    /// Indicates the layer has been rendered.
    internal private(set) var isRendered: Bool = false

    /// Antialias lines.
    public var antialiased: Bool = false

    /// Blending factor.
    public var colorBlendFactor: CGFloat = 1.0

    /// Render scaling property.
    public var renderQuality: CGFloat = TiledGlobals.default.renderQuality.default

    /// Pixel size of the layer.
    internal var pixelCount: Int {
        return Int(sizeInPoints.width * sizeInPoints.height)
    }

    /// Enable effects rendering of this node.
    public override var shouldEnableEffects: Bool {
        willSet {
            if (newValue == true) && (pixelCount > SKTILED_MAX_TILEMAP_PIXEL_SIZE) {
                // TODO: add os_log here
                self.log("layer size of \(sizeInPoints.shortDescription) exceeds max texture framebuffer size.", level: .warning)
            }
        }
    }

    /// Name used to access navigation graph.
    public var navigationKey: String

    /// Output current zPosition
    public var currentZPosition: CGFloat { return self.zPosition }

    /// Optional background color.
    public var backgroundColor: SKColor? = nil {
        didSet {
            self.background.color = (backgroundColor != nil) ? backgroundColor! : SKColor.clear
            self.background.colorBlendFactor = (backgroundColor != nil) ? 1.0 : 0
        }
    }

    /// Layer background sprite.
    public lazy var background: SKSpriteNode = { [unowned self] in
        //let spriteSize = self.tilemap.sizeInPoints
        let spriteSize = self.tilemap.calculateAccumulatedFrame().size
        let sprite = SKSpriteNode(color: SKColor.clear, size: spriteSize)
        sprite.anchorPoint = CGPoint.zero
        sprite.name = layerName.uppercased() + "_BACKGROUNDSPRITE"

        #if os(iOS) || os(tvOS)
        sprite.position.y = -self.tilemap.sizeInPoints.height
        #else
        sprite.yScale *= -1
        #endif
        self.addChild(sprite)
        return sprite
        }()

    // MARK: - Geometry

    /// Returns the position of layer origin point (used to place tiles).
    public var origin: CGPoint {

        // TODO: add layerInfiniteOffset?
        switch orientation {

            case .orthogonal:
                return CGPoint.zero

            case .isometric:
                return CGPoint(x: height * tileWidthHalf, y: tileHeightHalf)

            case .hexagonal:
                let startPoint = CGPoint.zero
                //startPoint.x -= tileWidthHalf
                //startPoint.y -= tileHeightHalf
                return startPoint

            case .staggered:
                return CGPoint.zero
        }
    }

    /// Returns the frame rectangle of the layer (used to draw bounds).
    public override var boundingRect: CGRect {
        // TODO: implement this
        let boundsOffset = CGPoint.zero
        return CGRect(x: boundsOffset.x, y: boundsOffset.y, width: sizeInPoints.width, height: -sizeInPoints.height)
    }

    /// Returns a rectangle in this node's parent's coordinate system.
    public override var frame: CGRect {
        let px = parent?.position.x ?? position.x
        let py = parent?.position.y ?? position.y
        return CGRect(center: CGPoint(x: px, y: py), size: sizeInPoints)
    }

    /// Initial layer position for infinite maps. Used to reposition tile layers & chunks in infinite maps. This is used by the tilemap to position the layers as they are added.
    internal var layerInfiniteOffset: CGPoint {
        //if (isInfinite == false) || (layerType != .tile) {
        if (isInfinite == false) {
            return CGPoint.zero
        }
        
        var offsetPos = CGPoint.zero
        switch orientation {
            case .orthogonal:
                offsetPos.x -= tileWidthHalf
                offsetPos.y += tileHeightHalf

            case .isometric:
                offsetPos.x -= sizeInPoints.halfWidth
                offsetPos.y += tileHeightHalf

            case .hexagonal, .staggered:
                offsetPos.x -= tileWidthHalf
                offsetPos.y += tileHeightHalf
        }

        return offsetPos
    }

    /// Shape describing this object.
    @objc public lazy var objectPath: CGPath = {
        let vertices = getVertices(offset: CGPoint.zero)
        return polygonPath(vertices)
    }()

    /// Returns layer render statisics
    internal var renderInfo: RenderInfo {
        return (index, xPath, Double(zPosition), Int(tilemap.mapSize.width),
                Int(tilemap.mapSize.height), Int(tileSize.width),
                Int(tileSize.height),  Int(offset.x), Int(offset.y),
                Int(anchorPoint.x), Int(anchorPoint.y), 0, 0, (isHidden == true) ? 0 : 1, nil)
    }

    internal var layerRenderStatistics: LayerRenderStatistics {
        return (tiles: 0, objects: 0)
    }

    /// Update mode.
    public var updateMode: TileUpdateMode {
        return tilemap.updateMode
    }


    // MARK: - Initialization

    ///  Initialize via the tilemap parser.
    ///
    ///   *This intializer is meant to be called by the `SKTilemapParser`, you should not use it directly.*
    ///
    /// - Parameters:
    ///   - layerName: layer name.
    ///   - tilemap: parent tilemap node.
    ///   - attributes: dictionary of layer attributes.
    public init?(layerName: String, tilemap: SKTilemap, attributes: [String: String]) {

        // tiled renderable attributes
        self.orientation = tilemap.orientation
        self.isInfinite = tilemap.isInfinite
        self.mapSize = tilemap.mapSize
        self.tileSize = tilemap.tileSize
        self.hexsidelength = tilemap.hexsidelength
        self.staggeraxis = tilemap.staggeraxis
        self.staggerindex = tilemap.staggerindex

        self.ignoreProperties = tilemap.ignoreProperties
        self.navigationKey = layerName
        self.tilemap = tilemap
        self.mapDelegate = tilemap as TiledMappableGeometryType

        super.init()
        self.debugNode = TiledDebugDrawNode(tileLayer: self)
        self.name = layerName
        self.shouldEnableEffects = false

        // layer offset
        var offsetx: CGFloat = 0
        var offsety: CGFloat = 0

        // set the size properties
        if let width = attributes["width"] {
            self.mapSize.width = CGFloat(Int(width)!)
        }

        if let height = attributes["height"] {
            self.mapSize.height = CGFloat(Int(height)!)
        }


        if let offsetX = attributes["offsetx"] {
            offsetx = CGFloat(Double(offsetX)!)
        }

        if let offsetY = attributes["offsety"] {
            offsety = CGFloat(Double(offsetY)!)
        }

        self.offset = CGPoint(x: offsetx, y: offsety)

        // set the visibility property
        if let visibility = attributes["visible"] {
            self.visible = (visibility == "1") ? true : false
        }

        // set layer opacity
        if let layerOpacity = attributes["opacity"] {
            self.opacity = CGFloat(Double(layerOpacity)!)
        }

        // layer tint
        if let layerTint = attributes["tintcolor"] {
            self.tintColor = SKColor(hexString: layerTint)
            colorBlendFactor = 1
            print("tint color found:  \(layerTint)")
        }

        // set the layer's antialiasing based on tile size
        self.antialiased = (self.tilemap.currentZoom < 1)
        addChild(debugNode)
        debugNode.position.y -= sizeInPoints.height
    }

    /// Create a new layer within the parent tilemap node.
    ///
    /// - Parameters:
    ///   - layerName: layer name.
    ///   - tilemap: parent tilemap node.
    public init(layerName: String, tilemap: SKTilemap) {

        // tiled renderable attributes
        self.orientation = tilemap.orientation
        self.isInfinite = tilemap.isInfinite
        self.mapSize = tilemap.mapSize
        self.tileSize = tilemap.tileSize
        self.hexsidelength = tilemap.hexsidelength
        self.staggeraxis = tilemap.staggeraxis
        self.staggerindex = tilemap.staggerindex

        self.ignoreProperties = tilemap.ignoreProperties
        self.navigationKey = layerName

        self.tilemap = tilemap
        self.mapDelegate = tilemap as TiledMappableGeometryType

        super.init()
        self.debugNode = TiledDebugDrawNode(tileLayer: self)
        self.name = layerName

        // set the layer's antialiasing based on tile size
        self.antialiased = (self.tilemap.currentZoom < 1)
        addChild(debugNode)
        debugNode.position.y -= sizeInPoints.height
    }

    /// Create a new layer within the parent tilemap node.
    ///
    /// - Parameter tilemap: parent tilemap node.
    /// - Returns: tile layer object.
    public init(tilemap: SKTilemap) {

        // tiled renderable attributes
        self.orientation = tilemap.orientation
        self.isInfinite = tilemap.isInfinite
        self.mapSize = tilemap.mapSize
        self.tileSize = tilemap.tileSize
        self.hexsidelength = tilemap.hexsidelength
        self.staggeraxis = tilemap.staggeraxis
        self.staggerindex = tilemap.staggerindex

        self.ignoreProperties = tilemap.ignoreProperties
        self.navigationKey = "NULL"

        self.tilemap = tilemap
        self.mapDelegate = tilemap as TiledMappableGeometryType

        super.init()
        self.debugNode = TiledDebugDrawNode(tileLayer: self)
        // set the layer's antialiasing based on tile size
        self.antialiased = (self.tilemap.currentZoom < 1)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeAllActions()
        removeAllChildren()
        removeFromParent()
        // clean up graph nodes
        if let graphNodes = graph?.nodes {
            graph?.remove(graphNodes)
        }
        graph = nil
        gidErrors = [:]
    }

    // MARK: - Color

    /// Set the layer color with an `SKColor`.
    ///
    /// - Parameter color: object color.
    public func setColor(color: SKColor) {
        self.color = color
    }

    /// Set the layer color with a hex string.
    ///
    /// - Parameter hexString: color hex string.
    public func setColor(hexString: String) {
        self.color = SKColor(hexString: hexString)
    }

    // MARK: - Children

    /// Returns an array of child layers.
    public var layers: [TiledLayerObject] {
        return [self]
    }

    #if os(iOS) || os(tvOS)

    // MARK: - Touch Events

    /// Returns a converted touch location.
    ///
    /// - Parameter touch: touch location
    /// - Returns: converted point in layer coordinate system.
    public func touchLocation(_ touch: UITouch) -> CGPoint {
        return convertPoint(touch.location(in: self))
    }

    /// Returns the tile coordinate at a touch location.
    ///
    /// - Parameter touch: touch location.
    /// - Returns: coordinate in layer coordinate system.
    public func coordinateAtTouchLocation(touch: UITouch) -> simd_int2 {
        return screenToTileCoords(point: touchLocation(touch))
    }
    #endif

    #if os(macOS)

    // MARK: - Mouse Events

    // TODO: add these to `TiledMappableGeometryType`?

    /// Returns a mouse event location in *the current layer*.
    ///
    /// - Parameter event: mouse event location.
    /// - Returns: converted point in layer coordinate system.
    public func mouseLocation(event: NSEvent) -> CGPoint {
        return convertPoint(event.location(in: self))
    }

    /// Returns the tile coordinate at a mouse event location.
    ///
    /// - Parameter event: mouse event.
    /// - Returns: coordinate in layer coordinate system.
    public func coordinateAtMouse(event: NSEvent) -> simd_int2 {
        return screenToTileCoords(point: mouseLocation(event: event))
    }
    #endif

    // MARK: - Coordinate Conversion

    /// Returns true if the coordinate is *valid* (within map bounds).
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: coordinate is valid.
    public func isValid(_ x: Int32, _ y: Int32) -> Bool {
        return (isInfinite == true) ? true : x >= 0 && x < Int(mapSize.width) && y >= 0 && y < Int(mapSize.height)
    }

    ///  Returns true if the coordinate is *valid* (within map bounds).
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: coordinate is valid
    public func isValid(coord: simd_int2) -> Bool {
        return isValid(coord.x, coord.y)
    }

    /// Convert a point into the tile map's coordinate space.
    ///
    /// - Parameter point: input point.
    /// - Returns: point with y-value inverted.
    public func convertPoint(_ point: CGPoint) -> CGPoint {
        return point.invertedY
    }

    // MARK: - Adding & Removing Nodes

    /// Add an `SKNode` child node at the given coordinates. By default, the zPositon will be higher than all of the other nodes in the layer.
    ///
    /// - Parameters:
    ///   - node: SpriteKit node.
    ///   - coord: tile coordinate.
    ///   - offset: offset amount.
    ///   - zpos: optional z-position.
    public func addChild(_ node: SKNode, coord: simd_int2, offset: CGPoint = CGPoint.zero, zpos: CGFloat? = nil) {
        addChild(node)
        node.position = pointForCoordinate(coord: coord, offsetX: offset.y, offsetY: offset.y)
        node.position.x += offset.x
        node.position.y += offset.y
        node.zPosition = (zpos != nil) ? zpos! : zPosition + tilemap.zDeltaForLayers
    }

    /// Add an `SKNode` child node at the given x/y coordinates. By default, the zPositon will be higher than all of the other nodes in the layer.
    ///
    /// - Parameters:
    ///   - node: object.
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    ///   - offset: offset amount.
    ///   - zpos: optional z-position.
    public func addChild(_ node: SKNode, x: Int = 0, y: Int = 0, offset: CGPoint = CGPoint.zero, zpos: CGFloat? = nil) {
        let coord = simd_int2(x: Int32(x), y: Int32(y))
        addChild(node, coord: coord, offset: offset, zpos: zpos)
    }

    /// Prune tiles out of the camera bounds.
    ///
    /// - Parameters:
    ///   - outsideOf: camera bounds.
    ///   - zoom: zoom level?
    ///   - buffer: buffer amount?
    internal func pruneTiles(_ outsideOf: CGRect? = nil, zoom: CGFloat = 1, buffer: CGFloat = 2) {
        // TODO: implement this
        /* override in subclass */
    }

    // MARK: - Callbacks

    /// Called when the layer is finished rendering.
    ///
    /// - Parameter duration: fade-in duration.
    public func didFinishRendering(duration: TimeInterval = 0) {
        self.parseProperties(completion: nil)
        // setup physics for the layer boundary
        if hasKey("isDynamic") && boolForKey("isDynamic") == true || hasKey("isCollider") && boolForKey("isCollider") == true {
            setupLayerPhysicsBoundary()
        }
        isRendered = true
    }

    // MARK: - Dynamics

    /// Set up physics boundary for the entire layer.
    ///
    /// - Parameter isDynamic: layer is dynamic.
    public func setupLayerPhysicsBoundary(isDynamic: Bool = false) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.boundingRect)
        physicsBody?.isDynamic = isDynamic
    }

    /// Set up physics for child objects.
    public func setupPhysics() {
        // override in subclass
    }

    /// Set tile collision shapes.
    public func setupTileCollisions() {
        // override in subclass
    }

    public override var hash: Int {
        return self.uuid.hashValue
    }


    // MARK: - Shaders

    /// Set a shader effect for the layer.
    ///
    /// - Parameters:
    ///   - named: shader file name.
    ///   - uniforms: array of shader uniforms.
    public func setShader(named: String, uniforms: [SKUniform] = []) {
        let layerShader = SKShader(fileNamed: named)
        layerShader.uniforms = uniforms
        shouldEnableEffects = true
        self.shader = layerShader
    }

    // MARK: - Debugging

    public func debugLayer() {
        /* override in subclass */
        let comma = (propertiesString.isEmpty == false) ? ", " : ""
        self.log("Layer: \(name != nil ? "'\(layerName)'" : "null")\(comma)\(propertiesString)", level: .debug)
    }

    /// Toggle layer isolation on/off.
    ///
    /// - Parameter duration: effect duration.
    public func isolateLayer(duration: TimeInterval = 0) {
        let hideLayers = (self.isolated == false)

        let layersToIgnore = self.parents
        let layersToProtect = self.childLayers

        tilemap.layers.filter { (layersToIgnore.contains($0) == false) && (layersToProtect.contains($0) == false)}.forEach { layer in

            if (duration == 0) {
                layer.isHidden = hideLayers
                layer.isolated = (hideLayers == true)
            } else {
                let fadeAction = (hideLayers == true) ? SKAction.fadeOut(withDuration: duration) : SKAction.fadeIn(withDuration: duration)
                layer.run(fadeAction, completion: {
                    layer.isHidden = hideLayers
                    layer.alpha = 1
                    layer.isolated = (hideLayers == true)
                })
            }
        }

        self.isolated = !self.isolated
    }

    /// Render the layer to a texture.
    ///
    /// - Returns: rendered texture.
    internal func render() -> SKTexture? {
        let renderSize = tilemap.sizeInPoints * TiledGlobals.default.contentScale
        let cropRect = CGRect(x: 0, y: -renderSize.height,
                              width: renderSize.width,
                              height: renderSize.height)

        if let rendered = SKView().texture(from: self, crop: cropRect) {
            rendered.filteringMode = .nearest
            return rendered
        }
        return nil
    }
    
    /// Generic highlight method that works for all `SpriteKit` types.
    ///
    /// - Parameters:
    ///   - color: highlight color.
    ///   - duration: duration of highlight effect.
    @objc public override func highlightNode(with color: SKColor, duration: TimeInterval = 0) {
        let removeHighlight: Bool = (color == SKColor.clear)
        let highlightFillColor = (removeHighlight == false) ? color.withAlphaComponent(0.2) : color
        
        boundsShape?.strokeColor = color
        boundsShape?.fillColor = highlightFillColor
        boundsShape?.isHidden = false
        
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
            })
        }
    }

    // MARK: - Updating

    /// Rasterize a static layer into an image.
    public func rasterizeStaticLayer() {
        // override in subclass
    }


    /// Initialize SpriteKit animation actions for the layer.
    public func runAnimationAsActions() {
        // override in subclass
    }

    /// Remove SpriteKit animations in the layer.
    ///
    /// - Parameter restore: restore tile/object texture.
    public func removeAnimationActions(restore: Bool = false) {
        self.log("removing SpriteKit actions for layer '\(self.layerName)'...", level: .debug)
    }

    /// Update the layer before each frame is rendered.
    ///
    /// - Parameter currentTime: update interval.
    public func update(_ currentTime: TimeInterval) {
        guard (isRendered == true) else {
            return
        }
        // clamp the position of the map & parent nodes
        // clampNodePosition(node: self, scale: SKTiledGlobals.default.contentScale)
    }

    // MARK: - Reflection

    /// Returns a custom mirror for this layer.
    public var customMirror: Mirror {
        return Mirror(self, children:
                        ["name": layerName,
                         "uuid": uuid,
                         "xPath": xPath,
                         "path": path,
                         "layerType": layerType,
                         "size": mapSize,
                         "tileSize": tileSize,
                        ],
                      ancestorRepresentation: .suppressed

        )
    }
}




// MARK: - Extensions


/// Convenience properties.
extension TiledLayerObject {

    /// Layer width (in tiles).
    public var width: CGFloat { return tilemap.width }

    /// Layer height (in tiles).
    public var height: CGFloat { return tilemap.height }

    /// Layer tile size width.
    public var tileWidth: CGFloat { return tilemap.tileWidth }

    /// Layer tile size height.
    public var tileHeight: CGFloat { return tilemap.tileHeight }

    /// Layer size, halved.
    public var sizeHalved: CGSize { return tilemap.sizeHalved }

    /// Layer tile size width, halved.
    public var tileWidthHalf: CGFloat { return tilemap.tileWidthHalf }

    /// Layer tile size height, halved.
    public var tileHeightHalf: CGFloat { return tilemap.tileHeightHalf }

    /// Layer transparency.
    public var opacity: CGFloat {
        get {
            return self.alpha
        }
        set {
            self.alpha = newValue
        }
    }

    /// Layer visibility.
    public var visible: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }

    /// Add a node at the given coordinates. By default, the zPositon will be higher than all of the other nodes in the layer.
    ///
    /// - Parameters:
    ///   - node: SpriteKit node.
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    ///   - dx: offset x-amount.
    ///   - dy: offset y-amount.
    ///   - zpos: z-position (optional).
    public func addChild(_ node: SKNode, _ x: Int, _ y: Int, dx: CGFloat = 0, dy: CGFloat = 0, zpos: CGFloat? = nil) {
        let coord = simd_int2(x: Int32(x), y: Int32(y))
        let offset = CGPoint(x: dx, y: dy)
        addChild(node, coord: coord, offset: offset, zpos: zpos)
    }

    /// Returns a point for a given coordinate in the layer, with optional offset values for x/y.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    ///   - offsetX: x-offset value.
    ///   - offsetY: y-offset value.
    /// - Returns: position in layer.
    public func pointForCoordinate(_ x: Int, _ y: Int, offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> CGPoint {
        let coord = simd_int2(x: Int32(x), y: Int32(y))
        return self.pointForCoordinate(coord: coord, offsetX: offsetX, offsetY: offsetY)
    }

    /// Returns a point for a given coordinate in the layer, with optional offset.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    ///   - offset: tile offset.
    /// - Returns: point in layer.
    public func pointForCoordinate(coord: simd_int2, offset: CGPoint) -> CGPoint {
        return self.pointForCoordinate(coord: coord, offsetX: offset.x, offsetY: offset.y)
    }

    /// Returns a point for a given coordinate in the layer, with optional offset.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    ///   - tileOffset: tile offset hint
    /// - Returns: point in layer.
    public func pointForCoordinate(coord: simd_int2, tileOffset: TiledLayerObject.TileOffset = .center) -> CGPoint {
        var offset = CGPoint(x: 0, y: 0)
        switch tileOffset {
            case .top:
                offset = CGPoint(x: 0, y: -tileHeightHalf)
            case .topLeft:
                offset = CGPoint(x: -tileWidthHalf, y: -tileHeightHalf)
            case .topRight:
                offset = CGPoint(x: tileWidthHalf, y: -tileHeightHalf)
            case .bottom:
                offset = CGPoint(x: 0, y: tileHeightHalf)
            case .bottomLeft:
                offset = CGPoint(x: -tileWidthHalf, y: tileHeightHalf)
            case .bottomRight:
                offset = CGPoint(x: tileWidthHalf, y: tileHeightHalf)
            case .left:
                offset = CGPoint(x: -tileWidthHalf, y: 0)
            case .right:
                offset = CGPoint(x: tileWidthHalf, y: 0)
            default:
                break
        }
        return self.pointForCoordinate(coord: coord, offsetX: offset.x, offsetY: offset.y)
    }

    /// Returns a tile coordinate for a given point in the layer.
    ///
    /// - Parameters:
    ///   - x: x-position.
    ///   - y: y-position.
    /// - Returns: position in layer.
    public func coordinateForPoint(_ x: Int, _ y: Int) -> simd_int2 {
        return self.coordinateForPoint(point: CGPoint(x: x, y: y))
    }

    /// Returns the center point of a layer.
    public var center: CGPoint {
        return CGPoint(x: (mapSize.width / 2) - (mapSize.width * anchorPoint.x), y: (mapSize.height / 2) - (mapSize.height * anchorPoint.y))
    }

    /// Calculate the distance from the layer's origin.
    ///
    /// - Parameter pos: point to measure.
    /// - Returns: distance vector.
    public func distanceFromOrigin(_ pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVector(dx: dx, dy: dy)
    }

    public override var description: String {
        let isTopLevel = self.parents.count == 1
        let indexString = (isTopLevel == true) ? ", index: \(index)" : ""
        return "\(tiledNodeNiceName) '\(path)'\(indexString) zpos: \(Int(zPosition))"
    }

    public override var debugDescription: String {
        return description
    }

    /// Returns a string representation for use with a dropdown menu.
    public var menuDescription: String {
        let parentCount = parents.count
        let isGrouped: Bool = (parentCount > 1)
        var layerSymbol: String = layerType.symbol
        let isGroupNode = (layerType == TiledLayerType.group)
        let hasChildren: Bool = (childLayers.isEmpty == false)
        if (isGroupNode == true) {
            layerSymbol = (hasChildren == true) ? "▿" : "▹"
        }

        let filler = (isGrouped == true) ? String(repeating: "   ", count: parentCount - 1) : ""
        return "\(filler)\(layerSymbol) \(layerName)"
    }
}

/// :nodoc:
extension TiledLayerObject {

    /// String representing the layer name (null if not set).
    public var layerName: String {
        return self.name ?? "null"
    }



    /// Recursively enumerate child layers.
    ///
    /// - Returns: child layer elements.
    internal func enumerate() -> [SKNode] {
        var result: [SKNode] = [self]
        for child in children {
            if let node = child as? TiledLayerObject {
                result += node.enumerate()
            }
        }
        return result
    }

    /// Returns an array of child layers.
    public var childLayers: [SKNode] {
        return self.enumerate()
    }

    /// Returns an array of tiles/objects that conform to the `SKTiledGeometry` protocol.
    ///
    /// - Returns: array of child objects.
    public func renderableObjects() -> [SKNode] {
        var result: [SKNode] = []
        enumerateChildNodes(withName: ".//*") { node, _ in
            if (node as? TiledGeometryType != nil) {
                result.append(node)
            }
        }
        return result
    }

    /// Indicates the layer is a top-level layer.
    public var isTopLevel: Bool {
        return self.parents.count <= 1
    }

    /// Returns the actual zPosition as rendered by the scene.
    internal var actualZPosition: CGFloat {
        return (isTopLevel == true) ? zPosition : parents.reduce(zPosition, { result, parent in
            return result + parent.zPosition
        })
    }

    /// Returns a string array representing the current layer name & index.
    public var layerStatsDescription: [String] {
        let digitCount: Int = self.tilemap.lastIndex.digitCount + 1

        let parentNodes = self.parents
        let isGrouped: Bool = (parentNodes.count > 1)
        let isGroupNode: Bool = (self as? SKGroupLayer != nil)

        let indexString = (isGrouped == true) ? String(repeating: " ", count: digitCount) : "\(index).".padLeft(toLength: digitCount, withPad: " ")
        let typeString = self.layerType.stringValue.capitalized.padRight(toLength: 6, withPad: " ")
        let hasChildren: Bool = (childLayers.isEmpty == false)

        var layerSymbol: String = " "
        if (isGroupNode == true) {
            layerSymbol = (hasChildren == true) ? "▿" : "▹"
        }

        let filler = (isGrouped == true) ? String(repeating: "  ", count: parentNodes.count - 1) : ""

        let layerPathString = "\(filler)\(layerSymbol) '\(layerName)'"
        let layerVisibilityString: String = (self.isolated == true) ? "(i)" : self.visible.valueAsCheckbox

        // layer position string, filters out child layers with no offset
        var positionString = self.position.shortDescription
        if (self.position.x == 0) && (self.position.y == 0) {
            positionString = ""
        }

        let graphStat = (renderInfo.gn != nil) ? "\(renderInfo.gn!)" : ""

        return [indexString, typeString, layerVisibilityString, layerPathString, positionString,
                self.sizeInPoints.shortDescription, self.offset.shortDescription,
                self.anchorPoint.shortDescription, "\(Int(self.zPosition))", self.opacity.stringRoundedTo(2), graphStat]
    }
}



extension TiledLayerObject.TiledLayerType {

    /// Returns a string representation of the layer type.
    internal var stringValue: String { return "\(self)".lowercased() }

    /// Returns a symbol for use in menus and debug output.
    internal var symbol: String {
        switch self {
            case .tile:   return "⊞"
            case .object: return "⧉"
            case .image:  return "⧈"
            default:      return ""
        }
    }
}

/// :nodoc:
extension TiledLayerObject.TiledLayerType: CustomStringConvertible, CustomDebugStringConvertible {

    var description: String {
        switch self {
            case .none: return "none"
            case .tile: return "tile"
            case .object: return "object"
            case .image: return "image"
            case .group: return "group"
        }
    }

    var debugDescription: String {
        return description
    }
}


extension TiledLayerObject.TileOffset {

    /// Returns the anchor point described by the offset.
    public var anchorPoint: CGPoint {
        switch self {
            case .center:
                return CGPoint(x: 0.5, y: 0.5)
            case .top:
                return CGPoint(x: 0.5, y: 1)
            case .topLeft:
                return CGPoint(x: 0, y: 1)
            case .topRight:
                return CGPoint(x: 1, y: 1)
            case .bottom:
                return CGPoint(x: 0.5, y: 0)
            case .bottomLeft:
                return CGPoint(x: 0, y: 0)
            case .bottomRight:
                return CGPoint(x: 1, y: 0)
            case .left:
                return CGPoint(x: 0, y: 0.5)
            case .right:
                return CGPoint(x: 1, y: 0.5)
        }
    }
}


extension TiledLayerObject {


    @objc func dumpStatistics() {
        print("\nLayer: '\(layerName)'")
        print("------------------------------------------")
        print("   size:       \(mapSize.shortDescription)")
        print("   tile size:  \(tileSize.shortDescription)")
        print("   offset:     \(offset.shortDescription)")
        print("\n")
    }

}



// MARK: - Deprecations

extension TiledLayerObject {


    /// Returns a tile coordinate for a given point in the layer.
    ///
    /// - Parameter point: point in layer (spritekit space).
    /// - Returns: tile coordinate.
    @available(*, deprecated, renamed: "coordinateForPoint(point:)")
    public func coordinateForPoint(_ point: CGPoint) -> CGPoint {
        return screenToTileCoords(point: point).cgPoint
    }

    /// Returns a tile coordinate for a given point in the layer.
    ///
    /// - Parameters:
    ///   - x: x-position.
    ///   - y: y-position.
    /// - Returns: position in layer.
    @available(*, deprecated, message: "use coordinateForPoint(point:")
    public func coordinateForPoint(_ x: Int, _ y: Int) -> CGPoint {
        return coordinateForPoint(point: CGPoint(x: x, y: y)).cgPoint
    }

    /// Returns a tile coordinate for a given `simd_int2` coordinate.
    ///
    /// - Parameters:
    ///   - vec2: vector simd_int2 coordinate.
    ///   - offsetX: x-offset value.
    ///   - offsetY: y-offset value.
    /// - Returns: position in layer.
    @available(*, deprecated, renamed: "pointForCoordinate(coord:)")
    public func pointForCoordinate(vec2: simd_int2, offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> CGPoint {
        return self.pointForCoordinate(coord: vec2, offsetX: offsetX, offsetY: offsetY)
    }

    /// Returns a tile coordinate for a given point in the layer as a `simd_int2`.
    ///
    /// - Parameter point: point in layer.
    /// - Returns: tile coordinate.
    @available(*, deprecated, message: "use coordinateForPoint(point:")
    public func vectorCoordinateForPoint(_ point: CGPoint) -> simd_int2 {
        return screenToTileCoords(point: point)
    }

    /// Returns true if the coordinate is *valid* (within map bounds).
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: coordinate is valid.
    @available(*, deprecated, renamed: "isValid(_:_:)")
    public func isValid(_ x: Int, _ y: Int) -> Bool {
        return isValid(Int32(x), Int32(y))
    }

    /// Returns true if the coordinate is *valid* (within map bounds).
    ///
    /// - Parameter coord: `CGPoint` coordinate.
    /// - Returns: coordinate is valid.
    @available(*, deprecated, renamed: "isValid(coord:)")
    public func isValid(coord: CGPoint) -> Bool {
        return isValid(Int(coord.x), Int(coord.y))
    }

    /// Add an `SKNode` child node at the given coordinates. By default, the zPositon will be higher than all of the other nodes in the layer.
    ///
    /// - Parameters:
    ///   - node: SpriteKit node.
    ///   - coord: tile coordinate.
    ///   - offset: offset amount.
    ///   - zpos: optional z-position.
    @available(*, deprecated, renamed: "addChild(_:coord:offset:zpos:)")
    public func addChild(_ node: SKNode, coord: CGPoint, offset: CGPoint = CGPoint.zero, zpos: CGFloat? = nil) {
        addChild(node, coord: coord.toVec2, offset: offset, zpos: zpos)
    }
}




extension TiledLayerObject {

    #if os(macOS)
    /// Returns the tile coordinate at a mouse event location.
    ///
    /// - Parameter event: mouse event.
    /// - Returns: converted point in layer coordinate system.
    @available(*, deprecated, renamed: "coordinateAtMouse(event:)")
    public func coordinateAtMouseEvent(event: NSEvent) -> CGPoint {
        return screenToTileCoords(point: event.location(in: self)).cgPoint
    }

    #else

    /// Returns the tile coordinate at a touch location.
    ///
    /// - Parameter touch: touch location.
    /// - Returns: converted point in layer coordinate system.
    @available(*, deprecated, renamed: "coordinateAtTouchLocation(touch:)")
    public func coordinateAtTouchLocation(_ touch: UITouch) -> CGPoint {
        return screenToTileCoords(point: touchLocation(touch)).cgPoint
    }
    #endif
}



extension TiledLayerObject {

    /// Container size (in tiles).
    @available(*, deprecated, renamed: "mapSize")
    public internal(set) var size: CGSize {
        get {
            return mapSize
        } set {
            mapSize = newValue
        }
    }
}
