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
        
        // tile flipping
        let fh = tileData.flipHoriz
        let fv = tileData.flipVert
        let fd = tileData.flipDiag
        
        if (fd == true) {
            if (fh == true) && (fv == false) {
                zRotation = CGFloat(-M_PI_2)   // rotate 90deg
            }
            
            if (fh == true) && (fv == true) {
                zRotation = CGFloat(-M_PI_2)   // rotate 90deg
                xScale *= -1                   // flip horizontally
            }
            
            if (fh == false) && (fv == true) {
                zRotation = CGFloat(M_PI_2)    // rotate -90deg
            }
        
            if (fh == false) && (fv == false) {
                zRotation = CGFloat(M_PI_2)    // rotate -90deg
                xScale *= -1                   // flip horizontally
            }
        } else {
            if (fh == true) {
                xScale *= -1
            }

            if (fv == true) {
                yScale *= -1
            }
        }
    }
    
    public func setupDynamics(){
        physicsBody = SKPhysicsBody(rectangleOfSize: size)
        physicsBody?.dynamic = false
    }
    
    /**
     Orient the tile based on the current flip flags.
     */
    private func orientTile() {
        
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
        
        var tileTextures: [SKTexture] = []
        for frameID in tileData.frames {
            guard let frameTexture = tileData.tileset.getTileData(frameID)?.texture else {
                print("Error: Cannot access texture for id: \(frameID)")
                return
            }
            tileTextures.append(frameTexture)
                }

        var animAction = SKAction.animateWithTextures(tileTextures, timePerFrame: tileData.duration, resize: false, restore: true)
        var repeatAction = SKAction.repeatActionForever(animAction)
        runAction(repeatAction, withKey: "TILE_ANIMATION")
    }
    
    /// Pauses tile animation
    public var pauseAnimation: Bool = false {
        didSet {
            guard oldValue != pauseAnimation else { return }
            guard let action = actionForKey("TILE_ANIMATION") else { return }
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
}


extension SKTile {
    
    /// Tile description.
    override public var description: String {
        var descString = "\(tileData.description)"
        let descGroup = descString.componentsSeparatedByString(",")
        var resultString = descGroup.first!
        if let layer = layer {resultString += ", Layer: \"\(layer.name!)\"" }

        // add the properties
        if descGroup.count > 1 {
            for i in 1..<descGroup.count {
                resultString += ", \(descGroup[i])"
            }
        }
        return resultString
    }
    
    override public var debugDescription: String {
        return description
    }
    
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
}


/// Shape node used for highlighting and placing tiles.
public class DebugTileShape: SKShapeNode {
    
    public var tileSize: CGSize
    public var orientation: TilemapOrientation = .Orthogonal
    public var color: SKColor
    public var layer: TiledLayerObject!
    
    
    public init(tileSize: CGSize, tileOrientation: TilemapOrientation = .Orthogonal, tileColor: SKColor){
        self.tileSize = tileSize
        self.color = tileColor
        super.init()
        self.orientation = tileOrientation
        drawObject()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func drawObject() {
        // draw the path
        var points: [CGPoint] = []
        
        let tileSizeHalved = CGSizeMake(tileSize.halfWidth, tileSize.halfHeight)
        
        switch orientation {
        case .Orthogonal:
            let origin = CGPoint(x: -tileSize.halfWidth, y: tileSize.halfHeight)  // invert y here
            points = rectPointArray(tileSize, origin: origin)
            
        case .Isometric:
            points = polygonPointArray(4, radius: tileSizeHalved)
            
        case .Hexagonal:
            points = polygonPointArray(6, radius: tileSizeHalved)
            
        case .Staggered:
            points = polygonPointArray(4, radius: tileSizeHalved)
        }

        self.path = polygonPath(points)
        self.antialiased = false
        self.lineWidth = 1.0
        
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
    }
}


public extension DebugTileShape {
    
    public convenience init(_ width: CGFloat, _ height: CGFloat, tileOrientation: TilemapOrientation = .Orthogonal, tileColor: SKColor = SKColor.blueColor()){
        self.init(tileSize: CGSizeMake(width, height), tileOrientation: tileOrientation, tileColor: tileColor)
    }
    
    public convenience init(_ width: Int, _ height: Int, tileOrientation: TilemapOrientation = .Orthogonal, tileColor: SKColor = SKColor.blueColor()){
        self.init(tileSize: CGSizeMake(CGFloat(width), CGFloat(height)), tileOrientation: tileOrientation, tileColor: tileColor)
    }
}
