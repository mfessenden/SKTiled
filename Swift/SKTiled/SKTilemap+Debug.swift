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
    
    /**
     Returns a representative grid texture to be used as an overlay.
     
     - parameter scale: image scale (2 seems to work best for fine detail).
     
     - returns: `SKTexture` grid texture.
     */
    public func generateGridTexture(scale: CGFloat=2.0, gridColor: UIColor=UIColor.greenColor()) -> SKTexture {
        let image: UIImage = imageOfSize(self.renderSize, scale: scale) {
            
            for col in 0 ..< Int(self.mapSize.width) {
                for row in (0 ..< Int(self.mapSize.height)) {
                    
                    let tileWidth = self.tileSize.width
                    let tileHeight = self.tileSize.height
                    
                    let boxRect = CGRect(x: tileWidth * CGFloat(col), y: tileHeight * CGFloat(row), width: tileWidth, height: tileHeight)
                    
                    let context = UIGraphicsGetCurrentContext()
                    let boxPath = UIBezierPath(rect: boxRect)
                    
                    gridColor.setStroke()
                    boxPath.lineWidth = 1
                    CGContextSaveGState(context)
                    CGContextSetLineDash(context, 4, [4, 4], 2)
                    boxPath.stroke()
                    CGContextRestoreGState(context)
                }
            }
        }
        
        let result = SKTexture(CGImage: image.CGImage!)
        //result.filteringMode = .Nearest
        return result
    }
    
    /// Visualize the tilemap's anchorpoint and frame.
    public var debugDraw: Bool {
        get {
            return childNodeWithName("DEBUG_ANCHOR") != nil
        } set {
            
            // remove existing node
            childNodeWithName("DEBUG_ANCHOR")?.removeFromParent()
            
            if (newValue==true) {
                
                let debugNode = SKNode()
                debugNode.name = "DEBUG_ANCHOR"
                addChild(debugNode)
                debugNode.zPosition = lastZPosition + 10
                
                // draw anchor point
                let anchorShape = SKShapeNode(circleOfRadius: tileSize.width * 0.25)
                anchorShape.zPosition = CGFloat(lastIndex + 1) * zDeltaForLayers
                anchorShape.strokeColor = debugColor
                anchorShape.antialiased = false
                anchorShape.fillColor = debugColor.colorWithAlphaComponent(0.3)
                debugNode.addChild(anchorShape)
                
                let frameShape = SKShapeNode(rectOfSize: renderSize)
                frameShape.antialiased = false
                debugNode.addChild(frameShape)
                
                
                
                frameShape.strokeColor = debugColor
                frameShape.lineWidth = 1
                
            }
        }
    }
}
