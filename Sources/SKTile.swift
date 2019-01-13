//
//  SKTile.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/**

 ## Overview ##

 The `TileRenderMode` flag determines how a particular tile instance is rendered. If the default is
 specified, the tile renders however the parent tilemap tells it to. Only set this flag to override a
 particular tile instance's render behavior.

 ### Properties ###

 | Property | Description                                    |
 |:---------|:-----------------------------------------------|
 | default  | Tile renders at default settings.              |
 | static   | Tile ignores any animation data.               |
 | ignore   | Tile does not take into account its tile data. |
 | animated | Animate with a global id value.                |

 */
public enum TileRenderMode {
    case `default`
    case `static`
    case ignore
    case animated(gid: Int?)
}

/**

 ## Overview ##

 The `SKTile` class is a custom SpriteKit sprite node that references its data from a tileset.

 Tile data (including texture) is stored in `SKTilesetData` property.


 ### Properties ###

 | Property                          | Description                                 |
 |:----------------------------------|:--------------------------------------------|
 | tileSize                          | tile size (in pixels)                       |
 | tileData                          | tile data structure                         |
 | layer                             | parent tile layer                           |

 ### Instance Methods ###

 | Method                            | Description                                                 |
 |:----------------------------------|:------------------------------------------------------------|
 | setupPhysics(shapeOf:isDynamic:)  | Setup physics for the tile.                                 |
 | setupPhysics(rectSize:isDynamic:) | Setup physics for the tile.                                 |
 | setupPhysics(withSize:isDynamic:) | Setup physics for the tile.                                 |
 | runAnimation()                    | Play tile animation (if animated).                          |
 | removeAnimation(restore:)         | Remove animation.                                           |
 | runAnimationAsActions()           | Runs a SpriteKit action to animate tile tile (if animated). |
 | removeAnimationActions(restore:)  | Remove the animation for the current tile.                  |

 */
open class SKTile: SKSpriteNode {

    /// Tile size.
    open var tileSize: CGSize

    /// Animation frame index
    private var frameIndex: UInt8 = 0

    /// Tileset tile data.
    open var tileData: SKTilesetData

    /// Weak reference to the parent layer.
    weak open var layer: SKTileLayer!

    /// Object is visible in camera.
    open var visibleToCamera: Bool = true

    /// Don't send updates.
    internal var blockNotifications: Bool = false

    /// Render mode for this instance.
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


    /**
     ## Overview ##

     Alignment hint used to define how to handle tile positioning within layers &
     objects (in the event the tile size is different than the parent).

     ### Properties ###

     | Property       | Description                                 |
     |:---------------|:--------------------------------------------|
     | topLeft        | Tile is positioned at the upper left.       |
     | top            | Tile is positioned at top.                  |
     | topRight       | Tile is positioned at the upper right.      |
     | left           | Tile is positioned at the left.             |
     | center         | Tile is positioned in the center.           |
     | right          | Tile is positioned to the right.            |
     | bottomLeft     | Tile is positioned at the bottom left.      |
     | bottom         | Tile is positioned at the bottom.           |
     | bottomRight    | Tile is positioned at the bottom right.     |

     */
    public enum TileAlignmentHint: Int {
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

    // Overlap
    fileprivate var tileOverlap: CGFloat = 1.0                      // tile overlap amount
    fileprivate var maxOverlap: CGFloat = 3.0                       // maximum tile overlap

    // Update values
    private var currentTime : TimeInterval = 0

    /// Tile highlight color.
    open var highlightColor: SKColor = TiledGlobals.default.debug.tileHighlightColor
    /// Tile bounds color.
    open var frameColor: SKColor = TiledGlobals.default.debug.frameColor
    /// Tile highlight duration.
    open var highlightDuration: TimeInterval = TiledGlobals.default.debug.highlightDuration
    internal var boundsKey: String = "BOUNDS"
    internal var animationKey: String = "TILE-ANIMATION"
    
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
    
    /**
     ## Overview:

     Describes the tile's physics shape.

     ### Properties ###

     | Property  | Description                    |
     |:----------|:-------------------------------|
     | none      | No physics shape.              |
     | rectangle | Rectangular object shape.      |
     | ellipse   | Circular object shape.         |
     | texture   | Texture-based shape.           |
     | path      | Open path.                     |

     */
    public enum PhysicsShape {
        case none
        case rectangle
        case ellipse
        case texture
        case path
    }

    /// Physics body shape.
    open var physicsShape: PhysicsShape = .none

    /// Tile positioning hint.
    internal var alignment: TileAlignmentHint = TileAlignmentHint.bottomLeft

    /// Returns the bounding box of the shape.
    open var bounds: CGRect {
        return CGRect(x: 0, y: 0, width: tileSize.width, height: -tileSize.height)
    }

    // MARK: - Init

    /**
     Initialize the tile object with `SKTilesetData`.

     - parameter data: `SKTilesetData` tile data.
     - returns: `SKTile` tile sprite.
     */
    required public init?(data: SKTilesetData) {
        guard let tileset = data.tileset else { return nil }
        self.tileData = data
        self.animationKey += "-\(data.globalID)"
        self.tileSize = tileset.tileSize
        super.init(texture: data.texture, color: SKColor.clear, size: fabs(tileset.tileSize))

        // get render mode from tile data properties
        if let rawRenderMode = data.intForKey("renderMode") {
            if let newRenderMode = TileRenderMode.init(rawValue: rawRenderMode) {
                self.renderMode = newRenderMode
            }
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        tileData = SKTilesetData()
        tileSize = CGSize.zero
        super.init(coder: aDecoder)
    }

    /**
     Initialize an empty tile.
     */
    required public init() {
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = CGSize.zero
        super.init(texture: SKTexture(), color: SKColor.clear, size: tileSize)
        colorBlendFactor = 0
    }

    /**
     Initialize the tile with a tile size.

     - parameter tileSize: `CGSize` tile size in pixels.
     - returns: `SKTile` tile sprite.
     */
    public init(tileSize size: CGSize) {
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = size
        super.init(texture: SKTexture(), color: SKColor.clear, size: tileSize)
        colorBlendFactor = 0
    }

    /**
     Initialize the tile texture.

     - parameter texture: `SKTexture?` tile texture.
     - returns: `SKTile` tile sprite.
     */
    public init(texture: SKTexture?) {
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = CGSize.zero
        super.init(texture: texture, color: SKColor.clear, size: tileSize)
        colorBlendFactor = 0
    }


    /**
     Draw the tile. Force the tile to update its textures.

     - parameter debug: `Bool` debug draw.
     */
    open func draw(debug: Bool = false) {
        removeAllActions()
        texture = tileData.texture
        size = tileData.texture.size()
    }

    // MARK: - Physics

    /**
     Set up the tile's dynamics body.

     - parameter shapeOf:   `PhysicsShape` tile physics shape type.
     - parameter isDynamic: `Bool` physics body is active.
     */
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

    /**
     Set up the tile's dynamics body with a rectanglular shape.

     - parameter rectSize:  `CGSize` rectangle size.
     - parameter isDynamic: `Bool` physics body is active.
     */
    open func setupPhysics(rectSize: CGSize, isDynamic: Bool = false) {
        physicsShape = .rectangle
        physicsBody = SKPhysicsBody(rectangleOf: rectSize)
        physicsBody?.isDynamic = isDynamic
    }
    /**

     Set up the tile's dynamics body with a rectanglular shape.

     - parameter withSize:  `CGFloat` rectangle size.
     - parameter isDynamic: `Bool` physics body is active.
     */
    open func setupPhysics(withSize: CGFloat, isDynamic: Bool = false) {
        physicsShape = .rectangle
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: withSize, height: withSize))
        physicsBody?.isDynamic = isDynamic
    }

    /**
     Set up the tile's dynamics body with a circular shape.

     - parameter radius:    `CGFloat` circle radius.
     - parameter isDynamic: `Bool` physics body is active.
     */
    open func setupPhysics(radius: CGFloat, isDynamic: Bool = false) {
        physicsShape = .ellipse
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.isDynamic = isDynamic
    }

    /**
     Remove tile physics body.

     - parameter withSize: `CGFloat` dynamics body size.
     */
    open func removePhysics() {
        physicsBody = nil
        physicsBody?.isDynamic = false
    }

    // MARK: - Animation

    /**
     Run tile animation.
     */
    open func runAnimation() {
        tileData.runAnimation()
    }

    /**
     Remove tile animation.

     - parameter restore: `Bool` restore the initial texture.
     */
    open func removeAnimation(restore: Bool = false) {
        tileData.removeAnimation(restore: restore)
    }

    // MARK: - Legacy Animation

    /**
     Checks if the tile is animated and runs a SpriteKit action to animate it.
     */
    open func runAnimationAsActions() {
        guard (tileData.isAnimated == true) else { return }
        removeAction(forKey: animationKey)

        // run tile action
        if let animationAction = tileData.animationAction {
            run(animationAction, withKey: animationKey)
        } else {
            fatalError("cannot get animation action for tile data.")
        }
    }

    /**
     Remove the animation for the current tile.

     - parameter restore: `Bool` restore the tile's first texture.
     */
    open func removeAnimationActions(restore: Bool = false) {
        removeAction(forKey: animationKey)

        guard tileData.isAnimated == true else { return }

        if (restore == true) {
            texture = tileData.texture
        }
    }

    // MARK: - Overlap

    /**
     Set the tile overlap amount.

     - parameter overlap: `CGFloat` overlap amount.
     */
    open func setTileOverlap(_ overlap: CGFloat) {
        // clamp the overlap value.
        var overlapValue = overlap <= maxOverlap ? overlap : maxOverlap
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

    /**
     Orient the tile based on the current flip flags.
     */
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

        if (tileData.flipDiag) {

            // rotate 90 (d, h)
            if (tileData.flipHoriz && !tileData.flipVert) {
                newZRotation = CGFloat(-Double.pi / 2)    // rotate 90deg
                alignment = .bottomRight
            }

            // rotate right, flip vertically  (d, h, v)
            if (tileData.flipHoriz && tileData.flipVert) {
                newZRotation = CGFloat(-Double.pi / 2)    // rotate 90deg
                newXScale *= -1                           // flip horizontally
                alignment = .bottomLeft
            }

            // rotate -90 (d, v)
            if (!tileData.flipHoriz && tileData.flipVert) {
                newZRotation = CGFloat(Double.pi / 2)     // rotate -90deg
                alignment = .topLeft
            }

            // rotate right, flip horiz (d)
            if (!tileData.flipHoriz && !tileData.flipVert) {
                newZRotation = CGFloat(Double.pi / 2)     // rotate -90deg
                newXScale *= -1                           // flip horizontally
                alignment = .topRight
            }

        } else {
            if (tileData.flipHoriz == true) {
                newXScale *= -1
                alignment = (tileData.flipVert == true) ? .topRight : .bottomRight
            }

            // (v)
            if (tileData.flipVert == true) {
                newYScale *= -1
                alignment = (tileData.flipHoriz == true) ? .topRight : .topLeft
            }
        }

        // anchor point translation
        let xAnchor: CGFloat
        let yAnchor: CGFloat

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

        // set the anchor point
        anchorPoint.x = xAnchor
        anchorPoint.y = yAnchor

        // rotate the sprite
        zRotation = newZRotation

        xScale = newXScale
        yScale = newYScale
    }

    // MARK: - Geometry

    /**
     Returns the points of the tile's shape.

     - returns: `[CGPoint]?` array of points.
     */
    open func getVertices(offset: CGPoint = CGPoint.zero) -> [CGPoint] {
        var vertices: [CGPoint] = []
        guard let layer = layer else {
            log("tile \(tileData.id) does not have a layer reference.", level: .debug)
            return vertices
        }

        let tileSizeHalved = CGSize(width: layer.tileSize.halfWidth, height: layer.tileSize.halfHeight)

        switch layer.orientation {

        case .orthogonal:

            var origin = CGPoint(x: -tileSizeHalved.width, y: tileSizeHalved.height)

            // adjust for tileset.tileOffset here
            origin.x += tileData.tileOffset.x
            //origin.y -= tileData.tileOffset.y

            vertices = rectPointArray(tileSize, origin: origin)
            vertices = vertices.map { $0.invertedY }

        case .isometric, .staggered:
            vertices = [
                CGPoint(x: -tileSizeHalved.width, y: 0),    // left-side
                CGPoint(x: 0, y: tileSizeHalved.height),
                CGPoint(x: tileSizeHalved.width, y: 0),
                CGPoint(x: 0, y: -tileSizeHalved.height)    // bottom
            ]

        case .hexagonal:
            var hexPoints = Array(repeating: CGPoint.zero, count: 6)
            let staggerX = layer.tilemap.staggerX
            let tileWidth = layer.tilemap.tileWidth
            let tileHeight = layer.tilemap.tileHeight

            let sideLengthX = layer.tilemap.sideLengthX
            let sideLengthY = layer.tilemap.sideLengthY
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

        return vertices.map { $0 + offset }
    }

    /**
     Draw the tile's boundary shape.

     - parameter withColor: `SKColor?` optional highlight color.
     - parameter zpos:      `CGFloat?` optional z-position of bounds shape.
     - parameter duration:  `TimeInterval` effect length.
     */
    internal func drawBounds(withColor: SKColor? = nil, zpos: CGFloat? = nil, duration: TimeInterval = 0) {
        childNode(withName: boundsKey)?.removeFromParent()

        // if a color is not passed, use the default frame color
        let drawColor = (withColor != nil) ? withColor! : self.frameColor


        // default line width
        let defaultLineWidth: CGFloat = 1
        let mapOffset = tileData.tileset.mapOffset

        // map tile size
        let mapTileSize = CGSize(width: tileSize.width - mapOffset.x, height: tileSize.height - mapOffset.y)

        // tileset tile size
        let tilesetTileSize: CGSize = tileData.tileset.tileSize
        let tilesetTileHeight: CGFloat = tilesetTileSize.height

        // calculate the offset
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        if let layer = layer {
            switch layer.orientation {
            case .orthogonal:
                // calculate the offset amount based on the current tile orientation
                if alignment == .bottomRight || alignment == .topRight {
                    xOffset = -(tilesetTileHeight - mapTileSize.height)

                    if alignment == .topRight {
                        yOffset = -(tilesetTileHeight - mapTileSize.height)
                    }
                }

                if alignment == .topLeft {
                    yOffset = -(tilesetTileHeight - mapTileSize.height)
                }

            default:
                xOffset = 0
                yOffset = 0
            }
        }

        let alignmentOffset = CGPoint(x: xOffset, y: yOffset)

        let vertices = getVertices(offset: alignmentOffset)

        guard (vertices.isEmpty == false) else { return }

        let renderQuality = tileData.renderQuality

        // scale vertices
        let scaledVertices = vertices.map { $0 * renderQuality }
        let path = polygonPath(scaledVertices)
        let bounds = SKShapeNode(path: path)
        bounds.name = boundsKey
        let shapeZPos = zPosition + 50

        // draw the path
        bounds.isAntialiased = layer.antialiased
        bounds.lineCap = .round
        bounds.lineJoin = .miter
        bounds.miterLimit = 0
        bounds.lineWidth = defaultLineWidth * (renderQuality / 2)

        bounds.strokeColor = drawColor.withAlphaComponent(0.4)
        bounds.fillColor = drawColor.withAlphaComponent(0.15)
        bounds.zPosition = shapeZPos

        // add the bounding shape
        addChild(bounds)

        // anchor point
        let tileHeight = (layer != nil) ? layer.tilemap.tileHeight : tileSize.height
        let tileHeightDivisor = (tileHeight <= 16) ? 8 : 16
        let anchorRadius: CGFloat = ((tileHeight / 2) / tileHeightDivisor) * renderQuality
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)

        anchor.name = "ANCHOR"
        bounds.addChild(anchor)
        anchor.fillColor = bounds.strokeColor
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = shapeZPos
        anchor.isAntialiased = layer.antialiased


        // first point
        let firstPoint = scaledVertices[0]
        let pointShape = SKShapeNode(circleOfRadius: anchorRadius)

        pointShape.name = "FIRST_POINT"
        bounds.addChild(pointShape)
        pointShape.fillColor = bounds.strokeColor
        pointShape.strokeColor = SKColor.clear
        pointShape.zPosition = shapeZPos * 15
        pointShape.isAntialiased = layer.antialiased

        pointShape.position = firstPoint
        bounds.setScale(1 / renderQuality)


        if (duration > 0) {
            let fadeAction = SKAction.fadeAfter(wait: duration, alpha: 0)
            bounds.run(fadeAction, withKey: "FADEOUT_ACTION", completion: {
                bounds.removeFromParent()
            })
        }
    }

    // MARK: - Updating
    /**
     Render the tile before each frame is rendered.

     - parameter deltaTime: `TimeInterval` update interval.
     */
    open func update(_ deltaTime: TimeInterval) {
        guard (isPaused == false) && (renderMode != TileRenderMode.ignore) else { return }

        // update texture for static frames
        if (tileData.isAnimated == false) {

            // check texture is the tile data texture
            if (self.texture != tileData.texture) {

                // reset tile texture & size
                self.texture = tileData.texture
                self.size = tileData.texture.size()
                //self.log("updating static tile id: \(tileData.id)", level: .debug)
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
                //self.log("updating animated tile id: \(tileData.id)", level: .debug)
                self.size = frameTexture.size()
            }
        }

        // the the current time is greater than the animation cycle, reset current time to 0
        if ct >= cycleTime { currentTime = 0 }
    }
}


extension TileRenderMode: RawRepresentable {
    public typealias RawValue = Int

    public init?(rawValue: RawValue) {
        switch rawValue {
        case 0: self = .default
        case 1: self = .static
        case 2: self = .ignore
        case -1: self = .animated(gid: nil)
        default: self = .animated(gid: rawValue)
        }
    }

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



extension TileRenderMode: CustomStringConvertible, CustomDebugStringConvertible {

    public func next() -> TileRenderMode {
        switch self {
        case .default: return .static
        case .static:  return .ignore
        default: return .default
        }
    }

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


extension TileRenderMode: Equatable {
    public var hashValue: Int {
        return identifier.hashValue
    }
}


extension SKTile {

    /// Opacity value of the tile.
    open var opacity: CGFloat {
        get {
            return self.alpha
        }
        set {
            self.alpha = newValue
        }
    }

    /// Visibility value of the tile.
    open var visible: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }

    /// Show/hide the tile's bounding shape.
    open var showBounds: Bool {
        get {
            return (childNode(withName: boundsKey) != nil) ? childNode(withName: boundsKey)!.isHidden == false : false
        }
        set {
            childNode(withName: boundsKey)?.removeFromParent()

            if (newValue == true) {

                // draw the tile boundary shape
                drawBounds()

                guard let frameShape = childNode(withName: boundsKey) else { return }

                if (highlightDuration > 0) {
                    let fadeAction = SKAction.fadeOut(withDuration: highlightDuration)
                    frameShape.run(fadeAction, completion: {
                        frameShape.removeFromParent()
                    })
                }
            }
        }
    }

    /// Tile description.
    override open var description: String {
        let layerDescription = (layer != nil) ? ", Layer: \"\(layer.layerName)\"" : ""
        return "\(tileData.description)\(layerDescription) \(renderMode.debugDescription)"
    }

    /// Tile debug description.
    override open var debugDescription: String { return "<\(description)>" }

    open var shortDescription: String {
        var result = "Tile id: \(self.tileData.id)"
        result += (self.tileData.type != nil) ? ", type: \"\(self.tileData.type!)\"" : ""
        return result
    }
}



extension SKTile {


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


// MARK: - Deprecated


extension SKTile {

    /// Pauses tile animation
    @available(*, deprecated, message: "Use the default `SKNode.isPaused` to pause animation.")
    open var pauseAnimation: Bool {
        get {
            return self.isPaused
        } set {
            self.isPaused = newValue
        }
    }
}


extension SKTile.TileAlignmentHint: CustomStringConvertible, CustomDebugStringConvertible {
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
    
    public var debugDescription: String {
        return description
    }
}


extension SKTile.PhysicsShape: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .none: return "Physics Shape: none"
        case .rectangle: return "Physics Shape: rectangle"
        case .ellipse: return "Physics Shape: ellipse"
        case .texture: return "Physics Shape: texture"
        case .path: return "Physics Shape: path"
        }
    }
    
    public var debugDescription: String {
        return description
    }
}


extension SKTile: SKTiledGeometry {}
extension SKTile: Loggable {}
