//
//  SKTile.swift
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


/// The `TileRenderMode` flag determines how a particular tile instance is rendered. If the default is
/// specified, the tile renders however the parent tilemap tells it to. Only set this flag to override a
/// particular tile instance's render behavior.
///
/// ### Properties
///
/// - `default`: Tile renders at default settings.
/// - `static`: Tile ignores any animation data.
/// - `ignore`: Tile does not take into account its tile data.
/// - `animated`: Animate with a global id value.
///
public enum TileRenderMode {
    case `default`
    case `static`
    case ignore
    case animated(gid: Int?)
}


/// The `SKTile` class is a custom **[SpriteKit sprite][skspritenode-url]** node that references its image and animation data from a tileset container. The tile represents a single piece of a larger image stored in a **[tile layer](SKTileLayer.html)** container.
///
/// ![Tile Data Setup][tiledata-diagram-url]
///
/// ### Properties
///
///  - `globalId`: tile global id.
///  - `tileData`: tileset **[tile data][tiledata-url]** reference.
///  - `tileSize`: tile size (in pixels).
///  - `layer`: parent tile layer.
///
/// ### Instance Methods
///
///  - `setupPhysics(shapeOf:isDynamic:)`:  setup physics for the tile.
///  - `setupPhysics(rectSize:isDynamic:)`: setup physics for the tile.
///  - `setupPhysics(withSize:isDynamic:)`: setup physics for the tile.
///  - `runAnimation()`:                    play tile animation (if animated).
///  - `removeAnimation(restore:)`:         remove animation.
///  - `runAnimationAsActions()`:           runs a SpriteKit action to animate the tile.
///  - `removeAnimationActions(restore:)`:  remove the animation for the current tile.
///
/// [tiledata-diagram-url]:../images/tiledata-setup.svg
/// [tiledata-url]:SKTilesetData.html
/// [skspritenode-url]:https://developer.apple.com/documentation/spritekit/skspritenode
open class SKTile: SKSpriteNode, CustomReflectable {

    /// Tile size (in pixels).
    open var tileSize: CGSize

    /// Node unique indentifier.
    @objc public var uuid: String = UUID().uuidString

    /// Node type. With a tile, this will never be set.
    @objc public var type: String!

    /// Animation frame index
    private var frameIndex: UInt8 = 0

    /// ## Overview
    ///
    /// The `SKTile.tileData` property holds a reference to the tile data contained in the referencing tileset. This struct
    /// contains attributes like texture, animation frame data and
    open var tileData: SKTilesetData {
        didSet {
            guard (oldValue != tileData) else {
                return
            }

            NotificationCenter.default.post(
                name: Notification.Name.Tile.TileDataChanged,
                object: self,
                userInfo: ["old": oldValue]
            )
        }
    }

    /// ## Overview
    ///
    /// Tile global id attribute. This attribute determines the tile data assigned to the tile. Changing this value will update this tiles' tile data.
    ///
    /// This is a wrapper for the `TileID` data structure and represents both global ID & tile orientation flags.
    @TileID open var globalId: UInt32 = 0 {
        didSet {
            guard (oldValue != globalId) && (oldValue != 0) else {
                return
            }

            NotificationCenter.default.post(
                name: Notification.Name.Tile.TileIDChanged,
                object: self,
                userInfo: ["old": oldValue]
            )
        }
    }

    /// Returns the tile data "real value" (global id with flags mask). If tile flip flags have been set in **Tiled**, this value will match the value set in the parent layer's tile data array.
    ///
    ///  For example, a value of **2684354571** translates to a global id of **11**, flipped horizontally & diagonally.
    ///
    /// ```swift
    /// tile.globalId = 11
    /// tile.flipFlags = [.flipHorizontal, .flipDiagonal]
    /// print(tile.maskedTileId)
    /// // 2684354571
    /// ```
    public var maskedTileId: UInt32 {
        return _globalId.realValue
    }

    /// The tile's current coordinate.
    open var currentCoordinate: simd_int2 = simd_int2(0, 0)

    /// Reference to the parent layer.
    open weak var layer: TiledLayerObject!

    /// Parent tile onbject.
    open weak var object: SKTileObject?

    /// Object is visible in camera.
    open var visibleToCamera: Bool = true

    /// Don't send update notifications.
    internal var blockNotifications: Bool = false

    /// ## Overview
    ///
    /// The tile render mode for this instance.
    ///
    /// - Render Modes
    ///   - default: tile renders at default settings.
    ///   - static: tile ignores any animation data.
    ///   - ignore: tile does not take into account its tile data.
    ///   - animate: animate with a global id value.
    ///
    open var renderMode: TileRenderMode = TileRenderMode.default {
        didSet {
            guard (oldValue != renderMode) else { return }

            NotificationCenter.default.post(
                name: Notification.Name.Tile.RenderModeChanged,
                object: self,
                userInfo: ["old": oldValue]
            )
        }
    }

    /// Returns true if the tile is part of a tile object.
    public internal(set) var isTileObject: Bool = false

    /// Debug visualization options.
    @objc public var debugDrawOptions: DebugDrawOptions = []
    
    // MARK: - Properties
    
    /// Ignore custom node properties.
    @objc public var ignoreProperties: Bool = false
    
    /// Private **Tiled** properties.
    @objc public var _tiled_properties: [String: String] = [:]
    
    @objc public var properties: [String: String] {
        get {
            return tileData.properties
        } set {
            _tiled_properties = newValue
        }
    }
    
    /// Return a string value for the given key, if it exists.
    ///
    /// ### Usage
    ///
    ///  ```swift
    ///  if let characterName = tile["characterName"] {
    ///     print("character name is '\(characterName)'.")
    ///  }
    ///  ```
    ///
    /// - parameter key: `String` key to query.
    public subscript(key: String) -> String? {
        get {
            return (ignoreProperties == false) ? properties[key] : nil
        } set(newValue) {
            properties[key] = newValue
        }
    }
    
    // MARK: - Tile Handlers

    /// Indicates the current node has received focus or selected.
    public var isFocused: Bool = false {
        didSet {
            guard isFocused != oldValue else {
                return
            }

            if (isFocused == true) {

            } else {

            }
        }
    }
    
    /// Handler for when the tile is created.
    internal var onCreate: ((SKTile) -> ())?
    
    /// Handler for when the tile is destroyed.
    internal var onDestroy: ((SKTile) -> ())?

    #if os(macOS)

    /// Mouse over handler.
    internal var onMouseOver: ((SKTile) -> ())?

    /// Mouse click handler.
    internal var onMouseClick: ((SKTile) -> ())?

    #else

    /// Touch event handler.
    internal var onTouch: ((SKTile) -> ())?

    #endif

    /// Alignment hint used to define how to handle tile positioning within layers &
    /// objects (in the event the tile size is different than the parent).
    ///
    /// ### Properties
    ///
    /// - `topLeft`: Tile is positioned at the upper left.
    /// - `top`: Tile is positioned at top.
    /// - `topRight`: Tile is positioned at the upper right.
    /// - `left`: Tile is positioned at the left.
    /// - `center`: Tile is positioned in the center.
    /// - `right`: Tile is positioned to the right.
    /// - `bottomLeft`: Tile is positioned at the bottom left.
    /// - `bottom`: Tile is positioned at the bottom.
    /// - `bottomRight`: Tile is positioned at the bottom right.
    ///
    public enum TileAlignmentHint: UInt8 {
        case topLeft
        case top
        case topRight
        case left
        case center
        case right
        case bottomLeft
        case bottom
        case bottomRight
    }

    /// Render scaling property.
    @objc public var renderQuality: CGFloat {
        get {
            return tileData.renderQuality
        } set {
            tileData.renderQuality = newValue
        }
    }

    /// Tile overlap amount.
    fileprivate var tileOverlap: CGFloat = 1.0

    /// Maximum tile overlap.
    fileprivate var maxOverlap: CGFloat = 3.0

    /// Update values.
    private var currentTime : TimeInterval = 0

    // MARK: - Color Attributes

    /// User-defined tile highlight color.
    private var userHighlightColor: SKColor? {
        if let highlightColorString = tileData.stringForKey("highlightColor") {
            return SKColor(hexString: highlightColorString)
        }
        return nil
    }

    /// User-defined tile frame color.
    private var userFrameColor: SKColor? {
        if let frameColorString = tileData.stringForKey("frameColor") {
            return SKColor(hexString: frameColorString)
        }
        return nil
    }

    /// Tile highlight color.
    open var highlightColor: SKColor {
        get {
            return userHighlightColor ?? TiledGlobals.default.debugDisplayOptions.tileHighlightColor
        } set {
            tileData.setValue(for: "highlightColor", newValue.hexString())
        }
    }

    /// Tile bounds color.
    open var frameColor: SKColor {
        get {
            return userFrameColor ?? TiledGlobals.default.debugDisplayOptions.frameColor
        } set {
            tileData.setValue(for: "frameColor", newValue.hexString())
        }
    }

    /// Tile tint color.
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

    // MARK: - Geometry

    /// Tile object offset.
    internal var boundsOffset: CGPoint = CGPoint.zero

    /// Layer bounding shape.
    @objc public lazy var boundsShape: SKShapeNode? = {
        let scaledverts = getVertices().map { $0 * renderQuality }
        let objpath = polygonPath(scaledverts)
        let shape = SKShapeNode(path: objpath)
        
        
        let boundsLineWidth = TiledGlobals.default.renderQuality.object
        shape.lineWidth = boundsLineWidth
        shape.lineJoin = .miter
        shape.miterLimit = 0.25
        shape.setScale(1 / renderQuality)
        addChild(shape)
        shape.zPosition = zPosition + 1

        // offset for tile objects
        shape.position.x -= boundsOffset.x
        shape.position.y -= boundsOffset.y
        shape.name = boundsKey
        return shape
    }()
    
    /// Object anchor node visualization node.
    @objc public lazy var anchorShape: SKShapeNode = {
        let tileheight = tilemap?.tileSize.height ?? tileSize.height
    
        // tile height = 16 -> 1.5
        let anchorRadius: CGFloat = (tileheight / 8) * 0.75
        let shape = SKShapeNode(circleOfRadius: anchorRadius)
        shape.strokeColor = SKColor.clear
        shape.fillColor = frameColor
        addChild(shape)
        shape.zPosition = zPosition + 1
        shape.name = anchorKey
        return shape
    }()

    /// Tile highlight duration.
    open var highlightDuration: TimeInterval = TiledGlobals.default.debugDisplayOptions.highlightDuration

    /// Enable tile animation.
    open var enableAnimation: Bool = true {
        didSet {
            if (enableAnimation == false) {
                removeAction(forKey: animationKey)
            } else {
                runAnimationAsActions()
            }
        }
    }
    
    /// Returns the size of parent object container (if one exists). If this tile is used as a [**tile object**][tile-objects-url], the vector object container might have a completely different size.
    ///
    /// [tile-objects-url]:working-with-objects.html#tile-objects
    internal var objectSize: CGSize?

    /// Shape describing this object.
    @objc public lazy var objectPath: CGPath = {
        let vertices = getVertices(offset: CGPoint.zero)
        return polygonPath(vertices)
    }()

    /// Internal points storage
    @objc var points: [CGPoint] = []

    /// Returns an array of points representing the tile's bounding shape.
    ///
    /// - Parameter offset: point offset value.
    /// - Returns: array of bounding shape points.
    @objc open override func getVertices(offset: CGPoint = CGPoint.zero) -> [CGPoint] {
        
        // FIXME: this is incorrect for tiles added to a layer after a map is rendered
        guard let tileLayer = layer,
              let parent = parent else {
            return boundingRect.points
        }

        //return boundingRect.points.map( { parent?.convert($0, from: parent)} )

        var vertices: [CGPoint] = []
        let tileSizeHalved = CGSize(width: tileLayer.tileSize.halfWidth, height: tileLayer.tileSize.halfHeight)

        /// if this is a tile object, the object anchor lies at the first point (typically bottom-left)
        if let parentObj = object {
            return parentObj.getVertices().map { point in
                var offsetpoint = point
                offsetpoint.x += self.layer.tileWidthHalf
                offsetpoint.y += self.layer.tileHeightHalf
                return self.convert(offsetpoint, from: parentObj)
            }
        }


        switch tileLayer.orientation {

            case .orthogonal:
                var origin = CGPoint(x: -tileSizeHalved.width, y: tileSizeHalved.height)

                // adjust for tileset.tileOffset here
                origin.x += tileData.tileOffset.x
                vertices = rectPointArray(tileSize, origin: origin)

            case .isometric, .staggered:
                vertices = [
                    CGPoint(x: -tileSizeHalved.width, y: 0),    // left-side
                    CGPoint(x: 0, y: tileSizeHalved.height),
                    CGPoint(x: tileSizeHalved.width, y: 0),
                    CGPoint(x: 0, y: -tileSizeHalved.height)    // bottom
                ]

            case .hexagonal:
                var hexPoints = Array(repeating: CGPoint.zero, count: 6)
                let staggerX = tileLayer.tilemap.staggerX
                let tileWidth = tileLayer.tilemap.tileWidth
                let tileHeight = tileLayer.tilemap.tileHeight

                let sideLengthX = tileLayer.tilemap.sideLengthX
                let sideLengthY = tileLayer.tilemap.sideLengthY
                var variableSize: CGFloat = 0

                // flat
                if (staggerX == true) {
                    let r = (tileWidth - sideLengthX) / 2
                    let h = tileHeight / 2
                    variableSize = tileWidth - (r * 2)
                    hexPoints[0] = CGPoint(x: -(variableSize / 2), y: h)
                    hexPoints[1] = CGPoint(x: (variableSize / 2), y: h)
                    hexPoints[2] = CGPoint(x: (tileWidth / 2), y: 0)
                    hexPoints[3] = CGPoint(x: (variableSize / 2), y: -h)
                    hexPoints[4] = CGPoint(x: -(variableSize / 2), y: -h)
                    hexPoints[5] = CGPoint(x: -(tileWidth / 2), y: 0)

                // pointy
                } else {
                    let r = (tileWidth / 2)
                    let h = (tileHeight - sideLengthY) / 2
                    variableSize = tileHeight - (h * 2)
                    hexPoints[0] = CGPoint(x: 0, y: (tileHeight / 2))
                    hexPoints[1] = CGPoint(x: r, y: (variableSize / 2))
                    hexPoints[2] = CGPoint(x: r, y: -(variableSize / 2))
                    hexPoints[3] = CGPoint(x: 0, y: -(tileHeight / 2))
                    hexPoints[4] = CGPoint(x: -r, y: -(variableSize / 2))
                    hexPoints[5] = CGPoint(x: -r, y: (variableSize / 2))
                }

                vertices = hexPoints.map { $0.invertedY }
        }

        // apply the offset value
        let offsetVertices = vertices.map { $0 + offset }
        return offsetVertices
    }

    /// Tile positioning hint.
    internal var alignment: TileAlignmentHint = TileAlignmentHint.bottomLeft

    /// Returns the bounding box of the shape.
    open override var boundingRect: CGRect {
        //return CGRect(x: -tileSize.halfWidth, y: tileSize.halfHeight, width: tileSize.width, height: -tileSize.height)
        return CGRect(x: 0, y: 0, width: tileSize.width, height: -tileSize.height)
    }



    // MARK: - Initialization

    /// Instantiate the tile with `SKTilesetData` data instance.
    ///
    /// - Parameter data: tile data structure.
    required public init?(data: SKTilesetData) {
        guard let tileset = data.tileset else { return nil }
        self.tileData = data
        //self.animationKey += "-\(data.globalID)"
        self.tileSize = tileset.tileSize
        super.init(texture: data.texture, color: SKColor.clear, size: fabs(tileset.tileSize))
        isUserInteractionEnabled = true

        // get render mode from tile data properties
        if let rawRenderMode = data.intForKey("renderMode") {
            if let newRenderMode = TileRenderMode.init(rawValue: rawRenderMode) {
                self.renderMode = newRenderMode
            }
        }
    }

    /// Instantiate the tile with a decoder instance.
    ///
    /// - Parameter aDecoder: decoder.
    required public init?(coder aDecoder: NSCoder) {
        tileData = SKTilesetData()
        tileSize = CGSize.zero
        super.init(coder: aDecoder)
        isUserInteractionEnabled = true

        // TODO: check for crash here
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: self
        )
    }

    /// Instantiate an empty tile.
    required public init() {
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = CGSize.zero
        super.init(texture: SKTexture(), color: SKColor.clear, size: tileSize)
        colorBlendFactor = 0
        isUserInteractionEnabled = true

        // TODO: check for crash here
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: self
        )
    }

    /// Initialize the tile with a tile size.
    ///
    /// - Parameter size: tile size in pixels.
    public init(tileSize size: CGSize) {
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = size
        super.init(texture: SKTexture(), color: SKColor.clear, size: tileSize)
        colorBlendFactor = 0
        isUserInteractionEnabled = true

        // TODO: check for crash here
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: self
        )
    }

    /// Initialize the tile with a tile texture.
    ///
    /// - Parameter texture: tile texture.
    public init(texture: SKTexture?) {
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = CGSize.zero
        super.init(texture: texture, color: SKColor.clear, size: tileSize)
        colorBlendFactor = 0
        isUserInteractionEnabled = true

        // TODO: check for crash here
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: self
        )
    }

    deinit {
        layer = nil
        object = nil
        removeAllActions()
        removeAllChildren()
        onDestroy?(self)
    }

    /// Removes this node from the scene graph. Signals the tile cache to remove the tile.
    open override func destroy() {

        // remove from cache
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileDestroyed,
            object: self
        )

        // remove from the parent layer
        if let tileLayer = layer as? SKTileLayer {
            if let thisTile = tileLayer.tileAt(coord: currentCoordinate) {
                if (thisTile == self) {
                    tileLayer.removeTile(at: currentCoordinate)
                }
            }
        }

        removeAnimationActions()
        super.destroy()
    }

    /// Creates and returns a new tile instance with the given tileset & global id.
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - tileset: tileset instance.
    /// - Returns: tile object with the given data.
    public class func newTile(globalID: UInt32, in tileset: SKTileset) -> SKTile {
        guard let tile = tileset.newTile(globalID: globalID) else {
            return SKTile()
        }

        // add to tile cache
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: tile
        )

        return tile
    }

    /// Creates and returns a new tile instance with the given tileset & local id.
    ///
    /// - Parameters:
    ///   - localID: tileset local id.
    ///   - tileset: tileset instance.
    /// - Returns: tile object with the given data.
    public class func newTile(localID: UInt32, in tileset: SKTileset) -> SKTile {
        guard let tile = tileset.newTile(localID: localID) else {
            return SKTile()
        }

        // add to tile cache
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: tile
        )

        return tile
    }

    // MARK: - Drawing

    /// Draw the tile. Forces the tile to update its textures.
    @objc open func draw() {
        removeAllActions()
        texture = tileData.texture
        size = tileData.texture.size()
        // TODO: animations?
        orientTile()
    }

    // MARK: - Physics

    /// Describes the tile's physics shape.
    ///
    /// ### Properties
    ///
    /// - `none`: No physics shape.
    /// - `rectangle`: Rectangular object shape.
    /// - `ellipse`: Circular object shape.
    /// - `texture`: Texture-based shape.
    /// - `path`: Open path.
    ///
    public enum PhysicsShape {
        case none
        case rectangle
        case ellipse
        case texture
        case path
    }

    /// Physics body shape.
    open var physicsShape: PhysicsShape = PhysicsShape.none

    /// Set up the tile's dynamics body.
    ///
    /// - Parameters:
    ///   - shapeOf: tile physics shape type.
    ///   - isDynamic: physics body is active.
    open func setupPhysics(shapeOf: PhysicsShape = PhysicsShape.rectangle, isDynamic: Bool = false) {
        physicsShape = shapeOf

        switch physicsShape {
            case .rectangle:
                physicsBody = SKPhysicsBody(rectangleOf: tileSize)

            case .texture:
                guard let texture = texture else {
                    physicsBody = nil
                    return
                }
                physicsBody = SKPhysicsBody(texture: texture, size: tileSize)

            default:
                physicsBody = nil
        }

        // set the dynamic flag
        physicsBody?.isDynamic = isDynamic
    }

    /// Set up the tile's dynamics body with a rectanglular shape.
    ///
    /// - Parameters:
    ///   - rectSize: rectangle size.
    ///   - isDynamic: physics body is active.
    open func setupPhysics(rectSize: CGSize, isDynamic: Bool = false) {
        physicsShape = PhysicsShape.rectangle
        physicsBody = SKPhysicsBody(rectangleOf: rectSize)
        physicsBody?.isDynamic = isDynamic
    }

    /// Set up the tile's dynamics body with a rectanglular shape.
    ///
    /// - Parameters:
    ///   - withSize: rectangle size.
    ///   - isDynamic: physics body is active.
    open func setupPhysics(withSize: CGFloat, isDynamic: Bool = false) {
        physicsShape = PhysicsShape.rectangle
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: withSize, height: withSize))
        physicsBody?.isDynamic = isDynamic
    }

    /// Set up the tile's dynamics body with a circular shape.
    ///
    /// - Parameters:
    ///   - radius: circle radius.
    ///   - isDynamic: physics body is active.
    open func setupPhysics(radius: CGFloat, isDynamic: Bool = false) {
        physicsShape = PhysicsShape.ellipse
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.isDynamic = isDynamic
    }

    /// Remove tile physics body.
    open func removePhysics() {
        physicsBody = nil
        physicsBody?.isDynamic = false
    }

    /// Set up the tile collision shape. Offset for tile objects should be zero.
    ///
    /// - Parameter zero: offset value.
    open func setupTileCollisions(offset: CGSize = CGSize.zero) {
        for collision in tileData.collisions {
            // TODO: expand `TileCollisionShape` class
            _ = collision.copy(with: nil) as! TileCollisionShape
        }
    }

    // MARK: - Animation

    /// Run the tile's animation.
    open func runAnimation() {
        tileData.runAnimation()
    }

    /// Remove tile animation.
    ///
    /// - Parameter restore: restore the initial texture.
    open func removeAnimation(restore: Bool = false) {
        tileData.removeAnimation(restore: restore)
    }

    /// Checks if the tile is animated and runs a [**SpriteKit action**][skaction-url] to animate it.
    ///
    /// [skaction-url]:https://developer.apple.com/documentation/spritekit/skaction
    open func runAnimationAsActions() {
        guard (tileData.isAnimated == true) else {
            return
        }
        removeAction(forKey: animationKey)

        // run tile action
        if let animationAction = tileData.animationAction {
            run(animationAction, withKey: animationKey)
        }
    }

    /// Remove the SpriteKit animation action for the current tile. If the `restore` argument is true, the tile's texture will reflect the tile data's initial texture.
    ///
    /// - Parameter restore: restore the tile's initial texture.
    open func removeAnimationActions(restore: Bool = false) {
        removeAction(forKey: animationKey)
        guard tileData.isAnimated == true else {
            return
        }

        if (restore == true) {
            texture = tileData.texture
        }
    }

    // MARK: - Overlap


    /// Set the tile overlap amount.
    ///
    /// - Parameter overlap: overlap amount.
    open func setTileOverlap(_ overlap: CGFloat) {
        // clamp the overlap value.
        var overlapValue = (overlap <= maxOverlap) ? overlap : maxOverlap
        overlapValue = overlapValue > 0 ? overlapValue : 0
        guard overlapValue != tileOverlap else { return }
        guard let tileTexture = tileData.texture else { return }

        let width: CGFloat = tileTexture.size().width
        let overlapWidth = width + (overlap / width)

        let height: CGFloat = tileTexture.size().height
        let overlapHeight = height + (overlap / height)

        xScale *= overlapWidth / width
        yScale *= overlapHeight / height
        tileOverlap = overlap
    }

    /// Orient the tile based on the current flip flags & sizing.
    internal func orientTile() {

        // reset orientation & scale
        zRotation = 0
        setScale(1)

        // get the map offset
        let mapOffset = tileData.tileset.mapOffset

        // map tile size
        let mapTileSize = CGSize(width: tileSize.width - mapOffset.x, height: tileSize.height - mapOffset.y)
        let mapTileSizeHalfWidth:  CGFloat = mapTileSize.width / 2
        let mapTileSizeHalfHeight: CGFloat = mapTileSize.height / 2

        // tileset tile size
        let tilesetTileSize: CGSize = tileData.tileset.tileSize
        let tilesetTileWidth: CGFloat = tilesetTileSize.width
        let tilesetTileHeight: CGFloat = tilesetTileSize.height

        // new values
        var newZRotation: CGFloat = 0
        var newXScale: CGFloat = xScale
        var newYScale: CGFloat = yScale

        let hFlip = _globalId.isFlippedHorizontally
        let vFlip = _globalId.isFlippedVertically
        let dFlip = _globalId.isFlippedDiagonally


        if (dFlip == true) {

            // rotate 90 (d, h)
            if (hFlip && !vFlip) {
                newZRotation = CGFloat(-Double.pi / 2)    // rotate 90deg
                alignment = .bottomRight
            }

            // rotate right, flip vertically  (d, h, v)
            if (hFlip && vFlip) {
                newZRotation = CGFloat(-Double.pi / 2)    // rotate 90deg
                newXScale *= -1                           // flip horizontally
                alignment = .bottomLeft
            }

            // rotate -90 (d, v)
            if (!hFlip && vFlip) {
                newZRotation = CGFloat(Double.pi / 2)     // rotate -90deg
                alignment = .topLeft
            }

            // rotate right, flip horiz (d)
            if (!hFlip && !vFlip) {
                newZRotation = CGFloat(Double.pi / 2)     // rotate -90deg
                newXScale *= -1                           // flip horizontally
                alignment = .topRight
            }

        } else {
            // reset to default
            alignment = .bottomLeft

            if (hFlip == true) {
                newXScale *= -1
                alignment = (vFlip == true) ? .topRight : .bottomRight
            }

            // (v)
            if (vFlip == true) {
                newYScale *= -1
                alignment = (hFlip == true) ? .topRight : .topLeft
            }
        }

        // anchor point translation
        let xAnchor: CGFloat
        let yAnchor: CGFloat


        /// default is `bottomLeft`
        switch alignment {
            case .bottomLeft:
                xAnchor = mapTileSizeHalfWidth / tilesetTileWidth
                yAnchor = mapTileSizeHalfHeight / tilesetTileHeight

            case .bottomRight:
                xAnchor = 1 - (mapTileSizeHalfWidth / tilesetTileWidth)
                yAnchor = mapTileSizeHalfHeight / tilesetTileHeight

            case .topLeft:
                xAnchor = mapTileSizeHalfWidth / tilesetTileWidth
                yAnchor = 1 - (mapTileSizeHalfHeight / tilesetTileHeight)

            case .topRight:
                xAnchor = 1 - (mapTileSizeHalfWidth / tilesetTileWidth)
                yAnchor = 1 - (mapTileSizeHalfHeight / tilesetTileHeight)

            default:
                xAnchor = mapTileSizeHalfWidth / tilesetTileWidth
                yAnchor = mapTileSizeHalfHeight / tilesetTileHeight
        }

        // if this is a tile object, the anchor point should be
        if (isTileObject == false) {
            // set the anchor point
            anchorPoint.x = xAnchor
            anchorPoint.y = yAnchor
        } else {
            alignment = .center
            newYScale = newYScale * -1
            position.x = 0
            position.y = 0
        }

        // rotate the sprite
        zRotation = newZRotation

        xScale = newXScale
        yScale = newYScale
    }


    // MARK: - Events & Handlers

    #if os(macOS)

    /// Informs the receiver that the mouse has moved.
    ///
    /// - Parameter event: mouse event.
    open override func mouseMoved(with event: NSEvent) {
        //guard (TiledGlobals.default.enableMouseEvents == true) else { return }
        if contains(touch: event.location(in: self)) {
            // for demo, this calls `Notification.Name.Demo.TileUnderCursor`
            onMouseOver?(self)
        }
    }

    /// Informs the receiver that the user has pressed the left mouse button.
    ///
    /// - Parameter event: mouse event.
    open override func mouseDown(with event: NSEvent) {
        // guard (TiledGlobals.default.enableMouseEvents == true) else { return }
        if contains(touch: event.location(in: self)) {
            // for demo, this calls `Notification.Name.Demo.TileClicked`
            onMouseClick?(self)
        }
    }

    open override func mouseEntered(with event: NSEvent) {
        print("tile entered!")
    }

    open override func mouseExited(with event: NSEvent) {
        print("tile exited!")
    }


    #elseif os(iOS)

    /// Tells this object that one or more new touches occurred in a view or window.
    ///
    /// - Parameters:
    ///   - touches: a set of touch instances.
    ///   - event: the touch event the touches belong to.
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if contains(touch: touch.location(in: self)) {
                onTouch?(self)
            }
        }
    }

    #endif

    /// Returns true if the touch event (mouse or touch) hits this node.
    ///
    /// - Parameter touch: touch point in this node.
    /// - Returns: node was touched.
    @objc public override func contains(touch: CGPoint) -> Bool {
        return objectPath.contains(touch)
    }

    // MARK: - Updating



    /// Render the tile before each frame is rendered.
    ///
    /// - Parameter deltaTime: update interval.
    open func update(_ deltaTime: TimeInterval) {
        guard (isPaused == false) && (renderMode != TileRenderMode.ignore) else { return }

        // update texture for static frames
        if (tileData.isAnimated == false) {

            // check texture is the tile data texture
            if (self.texture != tileData.texture) {

                // reset tile texture & size
                self.texture = tileData.texture
                self.size = tileData.texture.size()
            }

            return
        }

        // max cycle time (in ms)
        let cycleTime = tileData.animationTime
        guard (cycleTime > 0) else { return }

        // array of frame values
        let frames: [TileAnimationFrame] = (speed >= 0) ? tileData.frames : tileData.frames.reversed()

        // increment the current time value
        currentTime += (deltaTime * abs(Double(speed)))

        // current time in ms
        let ct: Int = Int(currentTime * 1000)

        // current frame
        var cf: UInt8? = nil

        var aggregate = 0

        // get the frame at the current time
        for (idx, frame) in frames.enumerated() {
            aggregate += frame.duration

            if ct < aggregate {
                if cf == nil {
                    cf = UInt8(idx)
                }
            }
        }

        // set texture for current frame
        if let currentFrame = cf {

            // stash the frame index
            frameIndex = currentFrame
            let frame = frames[Int(currentFrame)]
            if let frameTexture = frame.texture {

                // update sprite size
                self.texture = frameTexture
                self.size = frameTexture.size()
            }
        }

        // the the current time is greater than the animation cycle, reset current time to 0
        if ct >= cycleTime { currentTime = 0 }
    }

    // MARK: - Reflection

    /// Custom mirror for tile objects.
    public var customMirror: Mirror {

        var attributes: [(label: String?, value: Any)] = [
            //(label: "type", value: type as Any),
            (label: "global id", value: _globalId),
            (label: "tile size", value: tileSize),
            (label: "renderMode", value: renderMode),
            (label: "alignment", value: alignment),
            (label: "bounds", value: boundingRect),
            (label: "visibleToCamera", value: visibleToCamera),
            (label: "blockNotifications", value: blockNotifications),
            (label: "isUserInteractionEnabled", value: isUserInteractionEnabled),
            (label: "data", value: tileData)
        ]

        /// COLORS
        attributes.append(("frameColor", frameColor.hexString()))
        if let userfrmcolor = userFrameColor {
            attributes.append(("userFrameColor", userfrmcolor.hexString()))
        }


        attributes.append(("highlightColor", highlightColor.hexString()))
        if let userhicolor = userHighlightColor {
            attributes.append(("userHighlightColor", userhicolor.hexString()))
        }

        /// LAYER

        if let layer = layer {
            attributes.append(("layer", layer.layerDataStruct()))
        }

        
        if let tiletype = type {
            attributes.insert(("type", tiletype), at: 0)
        }
        
        
        /// DEBUGGING

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
}


// MARK: - Extensions

// :nodoc:
extension TileRenderMode: RawRepresentable {

    public typealias RawValue = Int

    /// Initialize with an integer value.
    ///
    /// - Parameter rawValue: raw integer.
    public init?(rawValue: RawValue) {
        switch rawValue {
            case 0: self = .default
            case 1: self = .static
            case 2: self = .ignore
            case -1: self = .animated(gid: nil)
            default: self = .animated(gid: rawValue)
        }
    }

    /// Returns the internal raw value.
    public var rawValue: RawValue {
        switch self {
            case .default: return 0
            case .static: return 1
            case .ignore: return 2
            case .animated(let gid):
                return gid ?? -1
        }
    }
}


/// :nodoc:
extension TileRenderMode: CustomStringConvertible, CustomDebugStringConvertible {

    /// Returns the next tile render mode in the array.
    ///
    /// - Returns: next tile render mode.
    public func next() -> TileRenderMode {
        switch self {
            case .default: return .static
            case .static:  return .ignore
            default: return .default
        }
    }

    /// Render mode string identifier.
    public var identifier: String {
        switch self {
            case .default: return "default"
            case .static: return "static"
            case .ignore: return "ignore"
            case .animated(let gid):
                let gidstr = (gid != nil) ? "-\(gid!)" : ""
                return "animated\(gidstr)"
        }
    }

    public var description: String {
        switch self {
            case .default: return "default"
            case .static: return "static"
            case .ignore: return "ignore"
            case .animated(let gid):
                let gidString = (gid != nil) ? "\(gid!)" : "nil"
                return "animated: \(gidString)"
        }
    }

    public var debugDescription: String {
        switch self {
            case .default: return ""
            case .static: return "(static)"
            case .ignore: return "(ignore)"
            case .animated(let gid):
                return (gid != nil) ? "(\(gid!))" : ""
        }
    }
}

/// :nodoc:
extension TileRenderMode: Equatable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}


// MARK: - Convenience Properties

extension SKTile {

    /// A reference to the tile data's containing tileset.
    ///
    /// - Returns: tileset instance, if one exists.
    open var tileset: SKTileset? {
        guard let tileset = tileData.tileset else {
            return nil
        }
        return tileset
    }

    /// Reference to the tile's parent tilemap.
    open var tilemap: SKTilemap? {
        guard let tileset = tileset, let map = tileset.tilemap else {
            return nil
        }
        return map
    }

    /// Opacity value of the tile.
    open var opacity: CGFloat {
        get {
            return self.alpha
        }
        set {
            self.alpha = newValue
        }
    }

    /// Toggle for tile visibility.
    open var isVisble: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }

    /// Tile flip flags.
    public var flipFlags: TileFlags {
        get {
            return _globalId.flags
        } set {
            _globalId.flags = newValue
            orientTile()
        }
    }

    /// Tile is flipped horizontally.
    public var isFlippedHorizontally: Bool {
        get {
            return _globalId.isFlippedHorizontally
        } set {
            _globalId.isFlippedHorizontally = newValue
            orientTile()
        }
    }

    /// Tile is flipped vertically.
    public var isFlippedVertically: Bool {
        get {
            return _globalId.isFlippedVertically
        } set {
            _globalId.isFlippedVertically = newValue
            orientTile()
        }
    }

    /// Tile is flipped diagonally.
    public var isFlippedDiagonally: Bool {
        get {
            return _globalId.isFlippedDiagonally
        } set {
            _globalId.isFlippedDiagonally = newValue
            orientTile()
        }
    }

    /// The offset position of the tile.
    public var tileOffset: CGPoint {

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        let mapOffset = tileData.tileset.mapOffset

        // map tile size
        let mapTileSize = CGSize(width: tileSize.width - mapOffset.x, height: tileSize.height - mapOffset.y)

        // tileset tile size
        let tilesetTileSize: CGSize = tileData.tileset.tileSize
        let tilesetTileHeight: CGFloat = tilesetTileSize.height


        // calculate the offset amount based on the current tile orientation
        if (alignment == .bottomRight) || (alignment == .topRight) {
            xOffset = -(tilesetTileHeight - mapTileSize.height)

            if (alignment == .topRight) {
                yOffset = -(tilesetTileHeight - mapTileSize.height)
            }
        }

        if (alignment == .topLeft) {
            yOffset = -(tilesetTileHeight - mapTileSize.height)
        }

        return CGPoint(x: xOffset, y: yOffset)
    }
}




/// :nodoc:
extension SKTile.TileAlignmentHint: CustomStringConvertible, CustomDebugStringConvertible {

    /// String representation of this node.
    public var description: String {
        switch self {
            case .topLeft: return "topLeft"
            case .top: return "top"
            case .topRight: return "topRight"
            case .left: return "left"
            case .center: return "center"
            case .right: return "right"
            case .bottomLeft: return "bottomLeft"
            case .bottom: return "bottom"
            case .bottomRight: return "bottomRight"
        }
    }

    /// Debug string representation of this node.
    public var debugDescription: String {
        return description
    }
}

/// :nodoc:
extension SKTile.PhysicsShape: CustomStringConvertible, CustomDebugStringConvertible {

    /// String representation of this node.
    public var description: String {
        switch self {
            case .none: return "Physics Shape: none"
            case .rectangle: return "Physics Shape: rectangle"
            case .ellipse: return "Physics Shape: ellipse"
            case .texture: return "Physics Shape: texture"
            case .path: return "Physics Shape: path"
        }
    }

    /// Debug string representation of this node.
    public var debugDescription: String {
        return description
    }
}



extension SKTile {

    /// Copies the tile object to a generic SpriteKit `SKSpriteNode` node. If the tile has animation, returns a sprite running a custom `SKAction`.
    ///
    /// - Returns: sprite copy of tile with current texture/animation.
    public func spriteCopy() -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: tileData.texture, color: self.color, size: tileData.texture.size())

        // run tile animation
        if (tileData.isAnimated == true) {
            if let action = tileData.animationAction {
                sprite.run(action, withKey: animationKey)
            }
        }

        // copy existing attributes
        sprite.position = position
        sprite.zPosition = zPosition
        sprite.zRotation = zRotation
        sprite.xScale = xScale
        sprite.yScale = yScale

        return sprite
    }

    /// Replace the tile object with sprite copy of the tile.
    ///
    /// - Returns: sprite with current animation.
    @discardableResult
    public func replaceWithSpriteCopy() -> SKSpriteNode {
        defer {
            self.destroy()
        }

        let sprite = self.spriteCopy()
        self.parent?.addChild(sprite)
        return sprite
    }

    /// Clone the tile data and apply it to this instance.
    public func withTileDataClone() {
        let clonedData = tileData.copy()
        self.tileData = clonedData as! SKTilesetData
    }

    /// Highlight the tile with a given color & duration.
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
        
        
        
        let fadeDuration: TimeInterval = 0.2
        
        self.color = color
        
        if (duration > 0) {
            let fadeInAction = SKAction.colorize(withColorBlendFactor: 0.5, duration: fadeDuration)
            let fadeOutAction = SKAction.colorize(withColorBlendFactor: 0, duration: fadeDuration)
            let groupAction = SKAction.group(
                [
                    fadeInAction,
                    SKAction.wait(forDuration: duration),
                    fadeOutAction
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


// MARK: - Debug Descriptions

/// :nodoc:
extension SKTile {

    /// String representation of the map.
    ///
    /// - "Tile: gid: 32, layer: 'Level2'"
    open override var description: String {
        let layerDescription = (layer != nil) ? ", layer: '\(layer.layerName)'" : ""
        let spacer = (renderMode == TileRenderMode.default) ? "" : " "
        return #"\#(tiledNodeNiceName): gid: \#(tileData.globalID)\#(layerDescription)\#(spacer)\#(renderMode.debugDescription)"#
    }

    /// Debug string representation of the tile.
    ///
    /// - "<SKTile: gid: 32, layer: 'Level2'>"
    open override var debugDescription: String {
        let layerDescription = (layer != nil) ? ", layer: '\(layer.layerName)'" : ""
        let spacer = (renderMode == TileRenderMode.default) ? "" : " "
        return #"<\#(className): gid: \#(tileData.globalID)\#(layerDescription)\#(spacer)\#(renderMode.debugDescription)>"#
    }
}


/// :nodoc: Tiled inspector attributes.
extension SKTile {

    /// Returns the internal **Tiled** node type.
    @objc public var tiledElementName: String {
        return "tile"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return tiledElementName.titleCased()
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public override var tiledIconName: String {
        return "tile-icon"
    }

    /// A description of the node.
    @objc public override var tiledListDescription: String {
        let tiledataString = "gid \(tileData.globalID)"
        return "Tile: \(tiledataString)"
    }

    /// A description of the node used for menu items.
    @objc public override var tiledMenuItemDescription: String {
        let tileGIDString = "gid \(tileData.globalID)"
        let layerNameString = (layer != nil) ? " layer: '\(layer.layerName)'" : ""
        return "Tile: \(tileGIDString)\(layerNameString)"
    }

    /// A description of the node used for debug output text.
    @objc public override var tiledDisplayItemDescription: String {
        let tileGIDString = " gid \(tileData.globalID)"
        let layerNameString = (layer != nil) ? " layer: '\(layer.layerName)'" : ""
        return #"<\#(className)\#(tileGIDString)\#(layerNameString)>"#
    }

    /// A description of the node.
    @objc public override var tiledHelpDescription: String {
        return "Represents a single map tile."
    }
}


// MARK: - Deprecations


extension SKTile {

    /// Toggle for tile visibility.
    @available(*, deprecated, renamed: "isVisible")
    open var visible: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }

    /// Returns the tile global id unmasked.
    @available(*, deprecated, renamed: "maskedTileId")
    public var realTileId: UInt32 {
        return maskedTileId
    }

    /// Pauses tile animation
    @available(*, deprecated, message: "Use the default `SKNode.isPaused` to pause animation.")
    open var pauseAnimation: Bool {
        get {
            return self.isPaused
        } set {
            self.isPaused = newValue
        }
    }

    /// Returns a shortened textual representation for debugging.
    @available(*, deprecated, renamed: "description")
    open var shortDescription: String {
        return description
    }

    /// Draw the tile. Forces the tile to update its textures.
    ///
    /// - Parameter debug: debug draw.
    @available(*, deprecated, renamed: "draw()")
    @objc open func draw(debug: Bool = false) {
        self.draw()
    }

    /// Draw the tile. Force the tile to update its textures.
    ///
    /// - Parameters:
    ///   - rect: rectangle.
    ///   - debug: debug draw.
    @available(*, deprecated, renamed: "draw()")
    open func draw(in rect: CGRect, debug: Bool = false) {
        self.draw()
    }

    /// Update the tile's tile data instance.
    ///
    /// - Parameter data: new tile data.
    @available(*, deprecated, message: "Use the `SKTile.tileData` property.")
    open func setTileData(data: SKTilesetData) {
        self.tileData = data
    }
}
