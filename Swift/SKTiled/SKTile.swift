//
//  SKTile.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/// represents a single tile object.
public class SKTile: SKSpriteNode {
    
    weak public var layer: SKTileLayer!                         // layer parent, assigned on add
    private var tileOverlap: CGFloat = 1.5                      // tile overlap amount
    public var tileData: SKTilesetData                          // tile data
    public var tileSize: CGSize                                 // tile size
    public var highlightColor: SKColor = SKColor.whiteColor()   // tile highlight color
    
    // blending/visibility
    public var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    public var visible: Bool {
        get { return !self.hidden }
        set { self.hidden = !newValue }
    }
    
    /// Boolean flag to enable/disable texture filtering.
    public var smoothing: Bool {
        get { return texture?.filteringMode != .Nearest }
        set { texture?.filteringMode = newValue ? SKTextureFilteringMode.Linear : SKTextureFilteringMode.Nearest }
    }
    
    // MARK: - Init
    /**
     Initialize the tile with a tile size.
     
     - parameter tileSize: `CGSize` tile size in pixels.
     
     - returns: `SKTile` tile sprite.
     */
    public init(tileSize size: CGSize){
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = size
        super.init(texture: SKTexture(), color: SKColor.clearColor(), size: tileSize)
    }
    
    /**
     Initialize the tile object with `SKTilesetData`.
     
     - parameter data: `SKTilesetData` tile data.
     
     - returns: `SKTile` tile sprite.
     */
    public init?(data: SKTilesetData){
        guard let tileset = data.tileset else { return nil }
        self.tileData = data

        self.tileSize = tileset.tileSize
        super.init(texture: data.texture, color: SKColor.clearColor(), size: data.texture.size())
        orientTile()
    }
    
    public func setupDynamics(){
        physicsBody = SKPhysicsBody(rectangleOfSize: size)
        physicsBody?.dynamic = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Animation
    
    /**
     Check if the tile is animated and run an action to animated it.
     */
    public func runAnimation(){
        guard tileData.isAnimated == true else { return }
        var framesData: [(texture: SKTexture, duration: NSTimeInterval)] = []
        for frame in tileData.frames {
            guard let frameTexture = tileData.tileset.getTileData(frame.gid)?.texture else {
                print("Error: Cannot access texture for id: \(frame.gid)")
                return
            }
            framesData.append((texture: frameTexture, duration: frame.duration))
        }
        
        let animationAction = SKAction.tileAnimation(framesData)
        runAction(animationAction, withKey: "Animation")
    }
    
    /// Pauses tile animation
    public var pauseAnimation: Bool = false {
        didSet {
            guard oldValue != pauseAnimation else { return }
            guard let action = actionForKey("Animation") else { return }
            action.speed = (pauseAnimation == true) ? 0 : 1.0
        }
    }
    
    /**
     Set the tile overlap amount.
     
     - parameter overlap: `CGFloat` tile overlap.
     */
    public func setTileOverlap(overlap: CGFloat) {
        // clamp the overlap value.
        var overlapValue = overlap <= 1.5 ? overlap : 1.5
        overlapValue = overlapValue > 0 ? overlapValue : 0
        guard overlapValue != tileOverlap else { return }
        
        var width: CGFloat = tileData.texture.size().width
        let overlapWidth = width + (overlap / width)

        var height: CGFloat = tileData.texture.size().height
        let overlapHeight = height + (overlap / height)
        
        xScale *= overlapWidth / width
        yScale *= overlapHeight / height
        
        tileOverlap = overlap
    }

        /**
     Orient the tile based on the current flip flags.
     */
    private func orientTile() {
        // reset orientation
        zRotation = 0
        setScale(1)
        
        if (tileData.flipDiag) {
            if (tileData.flipHoriz && !tileData.flipVert) {
                zRotation = CGFloat(-M_PI_2)   // rotate 90deg
            }
            
            if (tileData.flipHoriz && tileData.flipVert) {
                zRotation = CGFloat(-M_PI_2)   // rotate 90deg
                xScale *= -1                   // flip horizontally
            }
            
            if (!tileData.flipHoriz && tileData.flipVert) {
                zRotation = CGFloat(M_PI_2)    // rotate -90deg
            }
            
            if (!tileData.flipHoriz && !tileData.flipVert) {
                zRotation = CGFloat(M_PI_2)    // rotate -90deg
                xScale *= -1                   // flip horizontally
            }
        } else {
            if (tileData.flipHoriz) {
                xScale *= -1
            }
            
            if (tileData.flipVert) {
                yScale *= -1
            }
        }
    }
}


extension SKTile {
    
    /**
     Highlight the tile with a given color.
     
     - parameter color: `SKColor` highlight color.
     */
    public func highlightWithColor(color: SKColor?=nil, duration: NSTimeInterval=1.0, antialiasing: Bool=true) {
        
        let highlight: SKColor = (color == nil) ? highlightColor : color!
        
        let orientation = tileData.tileset.tilemap.orientation
        
        if orientation == .Orthogonal {
            childNodeWithName("HIGHLIGHT")?.removeFromParent()
            let highlightNode = SKShapeNode(rectOfSize: tileSize, cornerRadius: 0)
            highlightNode.strokeColor = highlight.colorWithAlphaComponent(0.1)
            highlightNode.fillColor = highlight.colorWithAlphaComponent(0.35)
            highlightNode.name = "HIGHLIGHT"
            
            highlightNode.antialiased = antialiasing
            addChild(highlightNode)
            highlightNode.zPosition = zPosition + 10
            
            // fade out highlight
            removeActionForKey("HIGHLIGHT_FADE")
            let fadeAction = SKAction.sequence([
                SKAction.waitForDuration(duration * 1.5),
                SKAction.fadeAlphaTo(0, duration: duration/4.0)
                ])
            
            highlightNode.runAction(fadeAction, withKey: "HIGHLIGHT_FADE", optionalCompletion: {
                highlightNode.removeFromParent()
            })
        }
        
        if orientation == .Isometric {
            removeActionForKey("HIGHLIGHT_FADE")
            let fadeOutAction = SKAction.colorizeWithColor(SKColor.clearColor(), colorBlendFactor: 1, duration: duration)
            runAction(fadeOutAction, withKey: "HIGHLIGHT_FADE", optionalCompletion: {
                let fadeInAction = SKAction.sequence([
                    SKAction.waitForDuration(duration * 1.5),
                    //fadeOutAction.reversedAction()
                    SKAction.colorizeWithColor(SKColor.clearColor(), colorBlendFactor: 0, duration: duration/4.0)
                    ])
                self.runAction(fadeInAction, withKey: "HIGHLIGHT_FADE")
            })
        }
    }
    
    /**
     Clear highlighting.
     */
    public func clearHighlight() {
        let orientation = tileData.tileset.tilemap.orientation
        
        if orientation == .Orthogonal {
            childNodeWithName("HIGHLIGHT")?.removeFromParent()
        }
        if orientation == .Isometric {
            removeActionForKey("HIGHLIGHT")
        }
    }
    
    /**
     Playground debugging visualization.
     
     - returns: `AnyObject` visualization
     */
    func debugQuickLookObject() -> AnyObject {
        let shape = SKShapeNode(rectOfSize: self.tileData.tileset.tileSize)
        return shape
    }
}


/// Shape node used for highlighting and placing tiles.
public class DebugTileShape: SKShapeNode {
    
    public var tileSize: CGSize
    public var orientation: TilemapOrientation = .Orthogonal
    public var color: SKColor
    public var layer: TiledLayerObject
    
    
    public init(layer: TiledLayerObject, tileColor: SKColor){
        self.layer = layer
        self.tileSize = layer.tileSize
        self.color = tileColor
        super.init()
        self.orientation = layer.orientation
        drawObject()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func drawObject() {
        // draw the path
        var points: [CGPoint] = []
        
        let tileSizeHalved = CGSizeMake(tileSize.halfWidth, tileSize.halfHeight)
        
        switch orientation {
        case .Orthogonal:
            let origin = CGPoint(x: -tileSize.halfWidth, y: tileSize.halfHeight)
            points = rectPointArray(tileSize, origin: origin)
            
        case .Isometric:
            points = polygonPointArray(4, radius: tileSizeHalved)
            
        case .Hexagonal:
            var hexPoints = Array(count: 8, repeatedValue: CGPointZero)
            let tileWidth = layer.tilemap.tileWidth
            let sideOffsetX = layer.tilemap.sideOffsetX
            let tileHeight = layer.tilemap.tileHeight
            let sideOffsetY = layer.tilemap.sideOffsetY
            
            hexPoints[0] = CGPoint(x: 0, y: tileHeight - sideOffsetY)
            hexPoints[1] = CGPoint(x: 0, y: sideOffsetY)
            hexPoints[2] = CGPoint(x: sideOffsetX, y: 0)
            hexPoints[3] = CGPoint(x: tileWidth - sideOffsetX, y: 0)
            hexPoints[4] = CGPoint(x: tileWidth, y: sideOffsetY)
            hexPoints[5] = CGPoint(x: tileWidth, y: tileHeight - sideOffsetY)
            hexPoints[6] = CGPoint(x: tileWidth - sideOffsetX, y: tileHeight)
            hexPoints[7] = CGPoint(x: sideOffsetX, y: tileHeight)
            
            points = hexPoints.map{$0.invertedY}
            
        case .Staggered:
            points = polygonPointArray(4, radius: tileSizeHalved)
        }
        
        // draw the path
        self.path = polygonPath(points)
        self.antialiased = false
        self.lineCap = .Butt
        self.miterLimit = 0
        self.lineWidth = 0.5
        
        self.strokeColor = self.color.colorWithAlphaComponent(0.4)
        self.fillColor = self.color.colorWithAlphaComponent(0.35)
        
        // anchor
        childNodeWithName("Anchor")?.removeFromParent()
        let anchorRadius: CGFloat = tileSize.height / 12 > 1.0 ? tileSize.height / 12 : 1.0
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)
        anchor.name = "Anchor"
        addChild(anchor)
        anchor.fillColor = self.color.colorWithAlphaComponent(0.2)
        anchor.strokeColor = SKColor.clearColor()
        anchor.zPosition = zPosition + 10
        anchor.antialiased = true
    }
}
