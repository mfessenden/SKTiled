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
    
    weak public var layer: SKTileLayer!         // layer parent, assigned on add
    private var tileOverlap: CGFloat = 1.5      // tile overlap amount
    public var tileData: SKTilesetData          // tile data
    public var tileSize: TileSize               // tile size 
    private var debugColor: SKColor = SKColor.whiteColor()
    
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
     
     - parameter tileSize: `TileSize` tile size in pixels.
     
     - returns: `SKTile` tile sprite.
     */
    public init(tileSize size: TileSize){
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = size
        super.init(texture: SKTexture(), color: SKColor.clearColor(), size: tileSize.size)
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
    
    /**
     Highlight the tile with a given color.
     
     - parameter color: `SKColor` highlight color.
     */
    public func highlightWithColor(color: SKColor) {
        guard let orientation = tileData.tileset.tilemap.orientation else { return }
        
        if orientation == .Orthogonal {
            childNodeWithName("HIGHLIGHT")?.removeFromParent()
            let highlightNode = SKShapeNode(rectOfSize: tileSize.size, cornerRadius: 0)
            highlightNode.strokeColor = color
            highlightNode.fillColor = color.colorWithAlphaComponent(0.25)
            highlightNode.name = "HIGHLIGHT"
            highlightNode.alpha = 0.5
            //highlightNode.antialiased = false
            addChild(highlightNode)
            highlightNode.zPosition = zPosition + 10
            let fadeAction = SKAction.fadeOutWithDuration(1.5)
            highlightNode.runAction(fadeAction, completion: {
                highlightNode.removeFromParent()
            })
        }
        
        if orientation == .Isometric {
            removeActionForKey("HIGHLIGHT")
            let fadeAction = SKAction.colorizeWithColor(SKColor.clearColor(), colorBlendFactor: 1, duration: 1.0)
            let waitAction = SKAction.waitForDuration(1.5)
            runAction(SKAction.sequence([fadeAction, waitAction, fadeAction.reversedAction()]), withKey: "HIGHLIGHT")
        }
    }
    
}
