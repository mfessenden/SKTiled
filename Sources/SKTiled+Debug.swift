//
//  SKTiled+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 6/19/17.
//  Copyright © 2017 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit



/// Shape node used for highlighting and placing tiles.
internal class DebugTileShape: SKShapeNode {
    
    open var tileSize: CGSize
    open var orientation: TilemapOrientation = .orthogonal
    open var color: SKColor
    open var layer: TiledLayerObject
    open var coord: CGPoint
    
    public init(layer: TiledLayerObject, coord: CGPoint, tileColor: SKColor){
        self.layer = layer
        self.coord = coord
        self.tileSize = layer.tileSize
        self.color = tileColor
        super.init()
        self.orientation = layer.orientation
        drawObject(withLabel: true)
    }
    
    public init(layer: TiledLayerObject, tileColor: SKColor){
        self.layer = layer
        self.coord = CGPoint.zero
        self.tileSize = layer.tileSize
        self.color = tileColor
        super.init()
        self.orientation = layer.orientation
        drawObject(withLabel: true)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Draw the object.
     */
    fileprivate func drawObject(withLabel: Bool=false) {
        // draw the path
        var points: [CGPoint] = []
        
        let tileSizeHalved = CGSize(width: tileSize.halfWidth, height: tileSize.halfHeight)
        
        switch orientation {
        case .orthogonal:
            let origin = CGPoint(x: -tileSize.halfWidth, y: tileSize.halfHeight)
            points = rectPointArray(tileSize, origin: origin)
            
        case .isometric, .staggered:
            points = polygonPointArray(4, radius: tileSizeHalved)
            
        case .hexagonal:
            var hexPoints = Array(repeating: CGPoint.zero, count: 6)
            let staggerX = layer.tilemap.staggerX
            let tileWidth = layer.tilemap.tileWidth
            let tileHeight = layer.tilemap.tileHeight
            
            let sideLengthX = layer.tilemap.sideLengthX
            let sideLengthY = layer.tilemap.sideLengthY
            var variableSize: CGFloat = 0
            
            // flat (broken)
            if (staggerX == true) {
                let r = (tileWidth - sideLengthX) / 2
                let h = tileHeight / 2
                variableSize = tileWidth - (r * 2)
                hexPoints[0] = CGPoint(x: position.x - (variableSize / 2), y: position.y + h)
                hexPoints[1] = CGPoint(x: position.x + (variableSize / 2), y: position.y + h)
                hexPoints[2] = CGPoint(x: position.x + (tileWidth / 2), y: position.y)
                hexPoints[3] = CGPoint(x: position.x + (variableSize / 2), y: position.y - h)
                hexPoints[4] = CGPoint(x: position.x - (variableSize / 2), y: position.y - h)
                hexPoints[5] = CGPoint(x: position.x - (tileWidth / 2), y: position.y)
            } else {
                //let r = tileWidth / 2
                let h = (tileHeight - sideLengthY) / 2
                variableSize = tileHeight - (h * 2)
                hexPoints[0] = CGPoint(x: position.x, y: position.y + (tileHeight / 2))
                hexPoints[1] = CGPoint(x: position.x + (tileWidth / 2), y: position.y + (variableSize / 2))
                hexPoints[2] = CGPoint(x: position.x + (tileWidth / 2), y: position.y - (variableSize / 2))
                hexPoints[3] = CGPoint(x: position.x, y: position.y - (tileHeight / 2))
                hexPoints[4] = CGPoint(x: position.x - (tileWidth / 2), y: position.y - (variableSize / 2))
                hexPoints[5] = CGPoint(x: position.x - (tileWidth / 2), y: position.y + (variableSize / 2))
            }
            
            points = hexPoints.map{$0.invertedY}
        }
        
        // draw the path
        self.path = polygonPath(points)
        self.isAntialiased = false
        self.lineJoin = .miter
        self.miterLimit = 0
        self.lineWidth = 0.5
        
        self.strokeColor = SKColor.clear
        self.fillColor = self.color.withAlphaComponent(0.35)
        
        // anchor
        childNode(withName: "Anchor")?.removeFromParent()
        let anchorRadius: CGFloat = tileSize.width / 24 > 1.0 ? tileSize.width / 18 > 4.0 ? 4 : tileSize.width / 18 : 1.0
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)
        anchor.name = "Anchor"
        addChild(anchor)
        anchor.fillColor = self.color.withAlphaComponent(0.2)
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = zPosition + 10
        anchor.isAntialiased = true
        
        childNode(withName: "CoordinateLabel")?.removeFromParent()
        // draw the coordinate label
        if (withLabel == true) {
            let label = SKLabelNode(fontNamed: "Courier")
            label.name = "CoordinateLabel"
            label.fontSize = anchorRadius * 24   // was 6
            label.text = "\(Int(coord.x)),\(Int(coord.y))"
            addChild(label)
            label.setScale(0.2)
        }
    }
}


internal func == (lhs: DebugTileShape, rhs: DebugTileShape) -> Bool {
    return lhs.coord == rhs.coord
}



extension SKTile {
    /**
     Highlight the tile with a given color.
     
     - parameter color:        `SKColor?` optional highlight color.
     - parameter duration:     `TimeInterval` duration of effect.
     - parameter antialiasing: `Bool` antialias edges.
     */
    public func highlightWithColor(_ color: SKColor?=nil,
                                   duration: TimeInterval=1.0,
                                   antialiasing: Bool=true) {
        
        let highlight: SKColor = (color == nil) ? highlightColor : color!
        let orientation = tileData.tileset.tilemap.orientation
        
        if orientation == .orthogonal || orientation == .hexagonal {
            childNode(withName: "Highlight")?.removeFromParent()
            
            var highlightNode: SKShapeNode? = nil
            if orientation == .orthogonal {
                highlightNode = SKShapeNode(rectOf: tileSize, cornerRadius: 0)
            }
            
            if orientation == .hexagonal {
                let hexPath = polygonPath(self.getVertices())
                highlightNode = SKShapeNode(path: hexPath, centered: true)
            }
            
            if let highlightNode = highlightNode {
                highlightNode.strokeColor = SKColor.clear
                highlightNode.fillColor = highlight.withAlphaComponent(0.35)
                highlightNode.name = "Highlight"
                
                highlightNode.isAntialiased = antialiasing
                addChild(highlightNode)
                highlightNode.zPosition = zPosition + 10
                
                // fade out highlight
                removeAction(forKey: "Highlight_Fade")
                let fadeAction = SKAction.sequence([
                    SKAction.wait(forDuration: duration * 1.5),
                    SKAction.fadeAlpha(to: 0, duration: duration/4.0)
                    ])
                
                highlightNode.run(fadeAction, withKey: "Highlight_Fade", optionalCompletion: {
                    highlightNode.removeFromParent()
                })
            }
        }
        
        if orientation == .isometric || orientation == .staggered {
            removeAction(forKey: "Highlight_Fade")
            let fadeOutAction = SKAction.colorize(with: SKColor.clear, colorBlendFactor: 1, duration: duration)
            run(fadeOutAction, withKey: "Highlight_Fade", optionalCompletion: {
                let fadeInAction = SKAction.sequence([
                    SKAction.wait(forDuration: duration * 2.5),
                    //fadeOutAction.reversedAction()
                    SKAction.colorize(with: SKColor.clear, colorBlendFactor: 0, duration: duration/4.0)
                    ])
                self.run(fadeInAction, withKey: "Highlight_Fade")
            })
        }
    }
    
    /**
     Clear highlighting.
     */
    public func clearHighlight() {
        let orientation = tileData.tileset.tilemap.orientation
        
        if orientation == .orthogonal {
            childNode(withName: "Highlight")?.removeFromParent()
        }
        if orientation == .isometric {
            removeAction(forKey: "Highlight_Fade")
        }
    }
}
