//
//  SKTilemap+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
import GameplayKit



public extension SKTilemap {
    
    public var debugDraw: Bool {
        get {
            return childNodeWithName("CENTER") != nil
        } set {
            
            // remove any existing node
            childNodeWithName("CENTER")?.removeFromParent()
            
            if (newValue==true) {
                let fillcolor = SKColor(red: 1.0, green: 0, blue: 0, alpha: 0.5)
                let strokecolor = SKColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)
                // anchor point
                let anchorShape = SKShapeNode(circleOfRadius: tileSize.width * 0.5)
                anchorShape.zPosition = zPosition + 10000
                anchorShape.strokeColor = strokecolor
                anchorShape.fillColor = fillcolor
                //anchorShape.lineWidth = debugLineWidth
                addChild(anchorShape)
                
                anchorShape.xScale = 1.0 / xScale
                anchorShape.yScale = 1.0 / yScale
                
                // reposition the anchor shape based on the node's anchor point.
                anchorShape.position.x = anchorPoint.x
                anchorShape.position.y = anchorPoint.y
            }
        }
    }
    
    public func debugLayers() {        
        for layer in tileLayers {
            if let name = layer.name {
                print("Layer: \"\(name)\"")
            }
        }
    }
}