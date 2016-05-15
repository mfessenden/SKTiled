//
//  SKTilemap+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public extension SKTilemap {
    
    /**
     Prints out all the data it has on the tilemap's layers.
     */
    public func debugLayers() {
        guard (layers.count > 0) else { return }
        
        for layer in layers.sort({ $0.index < $1.index }) {
            var propertiesString = ""
            for (pname, pvalue) in layer.properties {
                propertiesString += "\"\(pname)\": \(pvalue)"
            }
            print("\(layer.index): \"\(layer.name!), z: \(layer.zPosition)\" \(propertiesString)")
        }
    }
    
    /// Visualize the tilemap's anchorpoint and frame.
    public var debugDraw: Bool {
        get {
            return childNodeWithName("Anchor") != nil
        } set {
            // remove any existing node
            childNodeWithName("Anchor")?.removeFromParent()
            
            if (newValue==true) {
                
                let debugNode = SKNode()
                debugNode.name = "Anchor"
                addChild(debugNode)
                debugNode.position = center
                
                // draw anchor point
                let anchorShape = SKShapeNode(circleOfRadius: tileSize.width * 0.25)
                anchorShape.zPosition = CGFloat(lastIndex + 1) * zDeltaForLayers
                anchorShape.strokeColor = debugColor
                anchorShape.fillColor = debugColor.colorWithAlphaComponent(0.3)
                //anchorShape.lineWidth = debugLineWidth
                debugNode.addChild(anchorShape)
                
                anchorShape.xScale = 1.0 / xScale
                anchorShape.yScale = 1.0 / yScale
                
                // reposition the anchor shape based on the node's anchor point.
                anchorShape.position.x = anchorPoint.x
                anchorShape.position.y = anchorPoint.y
                
                let frameShape = SKShapeNode(rectOfSize: mapSize.renderSize)
                debugNode.addChild(frameShape)
                frameShape.position = center
                frameShape.zPosition = zPosition + 100
                frameShape.antialiased = false
                
                frameShape.strokeColor = debugColor
                frameShape.lineWidth = 1
                
                //frameShape.position = CGPointMake(size.width * anchorPoint.x, size.height * anchorPoint.y)
                
            }
        }
    }
}
