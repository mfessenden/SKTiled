//
//  SKTile.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/**
 Describes a tile's physics body shape.
 
 - `none`:       tile has no physics body.
 - `rectangle`:  tile physics shape is a rectangle.
 - `texture`:    tile physics shape is based on texture.
 - `path`:       tile physics shape is derived from a path.
 */
public enum PhysicsShape {
    case none
    case rectangle
    case ellipse
    case texture
    case path
}


/**
 Custom sprite type for rendering tile objects. Tile data (including texture) stored in `SKTilesetData` property.
 */
public class SKTile: SKSpriteNode {
    /// Tile size.
    open var tileSize: CGSize
    /// Reference to the parent layer.
    weak public var layer: SKTileLayer!
    /// Tile data reference.
    open var tileData: SKTilesetData
    
    // MARK: Overlap
    fileprivate var tileOverlap: CGFloat = 1.5          // tile overlap amount
    fileprivate var maxOverlap: CGFloat = 3.0           // maximum tile overlap
    
    // MARK: Highlighting
    open var highlightColor: SKColor = SKColor.white    // tile highlight color
    open var highlightDuration: TimeInterval = 0.25     // tile highlight duration
    
    // dynamics
    open var physicsShape: PhysicsShape = .rectangle    // physics type
    
    /// Returns the bounding box of the shape.
    open var boundingRect: CGRect {
        return CGRect(x: 0, y: 0, width: tileSize.width, height: -tileSize.height)
    }
    
    /// Opacity value of the tile
    open var opacity: CGFloat {
        get {
            return self.alpha
        }
        set {
            self.alpha = newValue
        }
    }
    
    /// Visibility value of the tile
    open var visible: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }
    
    /// Boolean flag to enable/disable texture filtering.
    open var smoothing: Bool {
        get {
            return texture?.filteringMode != .nearest
        }
        set {
            texture?.filteringMode = newValue ? SKTextureFilteringMode.linear : SKTextureFilteringMode.nearest
        }
    }
    
    /// Show/hide the tile's bounding shape.
    open var showBounds: Bool {
        get {
            return childNode(withName: "BOUNDS") != nil ? childNode(withName: "BOUNDS")!.isHidden : false
        }
        set {
            // draw the tile boundardy shape
            drawBounds()
            guard let frameShape = childNode(withName: "BOUNDS") else { return }
            if (highlightDuration > 0) {
                let fadeAction = SKAction.fadeOut(withDuration: highlightDuration)
                frameShape.run(fadeAction, completion: {
                    frameShape.removeFromParent()
                    
                })
            }
        }
    }
    
    // MARK: - Init
    /**
     Initialize the tile with a tile size.
     
     - parameter tileSize: `CGSize` tile size in pixels.
     - returns: `SKTile` tile sprite.
     */
    required public init(tileSize size: CGSize){
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
        super.init(texture: data.texture, color: SKColor.clear, size: data.texture.size())
        //orientTile()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Initialize an empty tile.
     */
    public init(){
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
    internal func update(){
        removeAllActions()
        texture = nil
        texture = tileData.texture
        runAnimation()
    }
    
    // MARK: - Physics
    
    /**
     Set up the tile's dynamics body.
     
     - parameter shapeOf:   `PhysicsShape` tile physics shape type.
     - parameter isDynamic: `Bool` physics body is active.
     */
    public func setupPhysics(shapeOf: PhysicsShape = .rectangle, isDynamic: Bool = false){
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
    public func setupPhysics(rectSize: CGSize, isDynamic: Bool = false){
        physicsShape = .rectangle
        physicsBody = SKPhysicsBody(rectangleOf: rectSize)
        physicsBody?.isDynamic = isDynamic
    }
    
    /**
     Set up the tile's dynamics body with a rectanglular shape.
     
     - parameter withSize:  `CGFloat` rectangle size.
     - parameter isDynamic: `Bool` physics body is active.
     */
    public func setupPhysics(withSize: CGFloat, isDynamic: Bool = false){
        physicsShape = .rectangle
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: withSize, height: withSize))
        physicsBody?.isDynamic = isDynamic
    }
    
    /**
     Set up the tile's dynamics body with a circular shape.
     
     - parameter radius:  `CGFloat` circle radius.
     - parameter isDynamic: `Bool` physics body is active.
     */
    public func setupPhysics(radius: CGFloat, isDynamic: Bool = false){
        physicsShape = .ellipse
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.isDynamic = isDynamic
    }
    
    /**
     Remove tile physics body.
     
     - parameter withSize: `CGFloat` dynamics body size.
     */
    public func removePhysics(){
        physicsBody = nil
        physicsBody?.isDynamic = false
    }
    
    // MARK: - Animation
    
    /**
     Checks if the tile is animated and runs an action to animate it.
     */
    public func runAnimation(){
        guard tileData.isAnimated == true else { return }
        guard let tileset = tileData.tileset else { return }
        var framesData: [(texture: SKTexture, duration: TimeInterval)] = []
        for frame in tileData.frames {
            guard let frameTexture = tileset.getTileData(localID: frame.gid)?.texture else {
                print("ERROR: Cannot access texture for id: \(frame.gid)")
                return
            }
            frameTexture.filteringMode = .nearest
            framesData.append((texture: frameTexture, duration: frame.duration))
        }
        
        // run tile action
        let animationAction = SKAction.tileAnimation(framesData)
        run(animationAction, withKey: "Animation")
    }
    
    /// Pauses tile animation
    public var pauseAnimation: Bool = false {
        didSet {
            guard oldValue != pauseAnimation else { return }
            guard let action = action(forKey: "Animation") else { return }
            action.speed = (pauseAnimation == true) ? 0 : 1.0
        }
    }
    
    /**
     Remove the animation for the current tile.
     
     - parameter restore: `Bool` restore the tile's first texture.
     */
    public func removeAnimation(restore: Bool = false){
        guard tileData.isAnimated == true else { return }
        removeAction(forKey: "Animation")
        if (restore == true){
            texture = tileData.texture
        }
    }

    /**
     Set the tile overlap amount.
     
     - parameter overlap: `CGFloat` tile overlap.
     */
    public func setTileOverlap(_ overlap: CGFloat) {
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
    // TODO: this was private
    public func orientTile() {
        // reset orientation
        zRotation = 0
        setScale(1)
        
        // 24 - 8, 16 - 8
        let mapOffset = tileData.tileset.mapOffset
        let mapTileSize = CGSize(width: tileSize.width - mapOffset.x, height: tileSize.height - mapOffset.y)
        
        print(" -> map offset:    \(mapOffset.shortDescription)")
        print(" -> map tile size: \(mapTileSize.shortDescription)")
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        if (tileData.flipDiag) {
            if (tileData.flipHoriz && !tileData.flipVert) {
                zRotation = CGFloat(-Double.pi / 2)   // rotate 90deg
            }
            
            if (tileData.flipHoriz && tileData.flipVert) {
                zRotation = CGFloat(-Double.pi / 2)   // rotate 90deg
                xScale *= -1                          // flip horizontally

            }

            if (!tileData.flipHoriz && tileData.flipVert) {
                zRotation = CGFloat(Double.pi / 2)    // rotate -90deg
            }

            if (!tileData.flipHoriz && !tileData.flipVert) {
                zRotation = CGFloat(Double.pi / 2)    // rotate -90deg
                xScale *= -1                          // flip horizontally

            }
        } else {
            if (tileData.flipHoriz) {
                xScale *= -1

            }
            
            if (tileData.flipVert) {
                yScale *= -1

            }
        }
        
        let frameSize = frame.size  // 16, 24
        
        
    }

    /**
     Returns the points of the tile's shape.
     
     - returns: `[CGPoint]?` array of points.
     */
    public func getVertices() -> [CGPoint] {
        var vertices: [CGPoint] = []
        guard let layer = layer else {
            print("ERROR: tile \(tileData.id) does not have a layer reference.")
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
                CGPoint(x: 0, y: -tileSizeHalved.height),   // bottom
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
            
            vertices = hexPoints.map{ $0.invertedY }
        }
        return vertices
    }

    /**
     Draw the tile's boundary shape.
     */
    public func drawBounds() {
        
        childNode(withName: "ANCHOR")?.removeFromParent()
        childNode(withName: "BOUNDS")?.removeFromParent()
        
        let vertices = getVertices()
        guard vertices.count > 0 else { return }
        
        let renderQuality = tileData.renderQuality
        let path = polygonPath(vertices.map { $0 * renderQuality })
        let shape = SKShapeNode(path: path)
        shape.name = "BOUNDS"
        let shapeZPos = zPosition + 10
        
        // draw the path
        shape.isAntialiased = layer.antialiased
        shape.lineCap = .round
        shape.lineJoin = .miter
        shape.miterLimit = 0
        shape.lineWidth = 0.5 * (renderQuality / 2)
        
        shape.strokeColor = highlightColor.withAlphaComponent(0.4)
        //shape.fillColor = SKColor(hexString: "85d8ff")
        shape.fillColor = highlightColor.withAlphaComponent(0.15)  // 0.35
        shape.zPosition = shapeZPos
        addChild(shape)
        
        // anchor point
        let tileHeight = (layer != nil) ? layer.tilemap.tileHeight : tileSize.height
        let tileHeightDivisor = (tileHeight <= 16) ? 8 : 16
        let anchorRadius: CGFloat = ((tileHeight / 2) / tileHeightDivisor) * renderQuality
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)
        
        anchor.name = "ANCHOR"
        shape.addChild(anchor)
        anchor.fillColor = highlightColor.withAlphaComponent(0.2)
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = shapeZPos + 10
        anchor.isAntialiased = layer.antialiased
        
        
        shape.setScale(1 / renderQuality)

    }
}
    


extension SKTile {
    
    /// Tile description.
    override public var description: String {
        let layerDescription = (layer != nil) ? ", Layer: \"\(layer.layerName)\"" : ""
        return "\(tileData.description)\(layerDescription)"
    }
    
    override public var debugDescription: String {
        return description
    }
}

