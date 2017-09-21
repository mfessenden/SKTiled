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

 The `SKTile` class is a custom SpriteKit sprite that references data from a tileset.

 Tile data (including texture) is stored in `SKTilesetData` property.
 */
open class SKTile: SKSpriteNode, Loggable {

    /// Tile size.
    open var tileSize: CGSize
    /// Tileset tile data.
    open var tileData: SKTilesetData
    /// Weak reference to the parent layer.
    weak open var layer: SKTileLayer!

    /**
     ## Overview:

     Alignment hint used to define how to handle tile positioning within layers &
     objects (in the event the tile size is different than the parent).
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
    fileprivate var tileOverlap: CGFloat = 1.5                      // tile overlap amount
    fileprivate var maxOverlap: CGFloat = 3.0                       // maximum tile overlap

    // Update values
    private var currentTime : TimeInterval = 0

    /// Tile highlight color.
    open var highlightColor: SKColor = TiledObjectColors.lime
    /// Tile bounds color.
    open var frameColor: SKColor = TiledObjectColors.magenta
    /// Tile highlight duration.
    open var highlightDuration: TimeInterval = 0
    internal var boundsKey: String = "BOUNDS"

    /// Enum describing the tile's physics shape.
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
    internal var alignment: TileAlignmentHint = .bottomLeft

    /// Returns the bounding box of the shape.
    open var bounds: CGRect {
        return CGRect(x: 0, y: 0, width: tileSize.width, height: -tileSize.height)
    }

    // MARK: - Init
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
     Initialize the tile object with `SKTilesetData`.

     - parameter data: `SKTilesetData` tile data.
     - returns: `SKTile` tile sprite.
     */
    required public init?(data: SKTilesetData) {
        guard let tileset = data.tileset else { return nil }
        self.tileData = data
        self.tileSize = tileset.tileSize
        super.init(texture: data.texture, color: SKColor.clear, size: fabs(tileset.tileSize))
    }

    required public init?(coder aDecoder: NSCoder) {
        tileData = SKTilesetData()
        tileSize = .zero
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
     Force the tile to update it's textures.

     - parameter data: `SKTilesetData` tile data.
     - returns: `SKTile` tile sprite.
     */
    internal func draw() {
        removeAllActions()
        texture = nil
        texture = tileData.texture
    }

    // MARK: - Physics

    /**
     Set up the tile's dynamics body.

     - parameter shapeOf:   `PhysicsShape` tile physics shape type.
     - parameter isDynamic: `Bool` physics body is active.
     */
    open func setupPhysics(shapeOf: PhysicsShape = .rectangle, isDynamic: Bool = false) {
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
    public func runAnimation() {
        tileData.runAnimation()
    }

    /**
     Remove tile animation.

     - parameter restore: `Bool` restore the initial texture.
     */
    open func removeAnimation(restore: Bool = false) {
        tileData.removeAnimation(restore: restore)
    }

    // MARK: - Overlap

    /**
     Set the tile overlap amount.

     - parameter overlap: `CGFloat` tile overlap.
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
                newZRotation = CGFloat(-Double.pi / 2)   // rotate 90deg
                newXScale *= -1                          // flip horizontally
                alignment = .bottomLeft
            }

            // rotate -90 (d, v)
            if (!tileData.flipHoriz && tileData.flipVert) {
                newZRotation = CGFloat(Double.pi / 2)   // rotate -90deg
                alignment = .topLeft
            }

            // rotate right, flip horiz (d)
            if (!tileData.flipHoriz && !tileData.flipVert) {

                newZRotation = CGFloat(Double.pi / 2)   // rotate -90deg
                newXScale *= -1                         // flip horizontally
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
    open func getVertices(offset: CGPoint = .zero) -> [CGPoint] {
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
    internal func drawBounds(withColor: SKColor?=nil, zpos: CGFloat?=nil, duration: TimeInterval = 0) {
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
        // TODO: do this in getvertices?
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

    // MARK: - Memory
    internal func flush() {
        self.texture = nil
        self.tileData.removeAnimation()
    }

    // MARK: - Updating
    /**
     Render the tile before each frame is rendered.

     - parameter deltaTime: `TimeInterval` update interval.
     */
    open func update(_ deltaTime: TimeInterval) {
        guard (isPaused == false) else { return }
        // max cycle time (in ms)
        let cycleTime = tileData.animationTime
        guard (cycleTime > 0) else { return }

        // array of frame values
        let frames: [AnimationFrame] = (speed >= 0) ? tileData.frames : tileData.frames.reversed()
        // increment the current time value
        currentTime += (deltaTime * abs(Double(speed)))

        // current time in ms
        let ct: Int = Int(currentTime * 1000)

        // current frame
        var cf: Int? = nil

        var aggregate = 0
        // get the frame at the current time
        for (idx, frame) in frames.enumerated() {
            aggregate += frame.duration
            if ct < aggregate  {
                if cf == nil {
                    cf = idx
                }
            }
        }

        if let currentFrame = cf {
            let frame = frames[currentFrame]
            if let frameTexture = frame.texture {
                self.texture = frameTexture
                // update sprite size
                self.size = frameTexture.size()
            }
        }

        // the the current time is greater than the animation cycle, reset current time to 0
        if ct >= cycleTime { currentTime = 0 }
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
        return "\(tileData.description)\(layerDescription)"
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
