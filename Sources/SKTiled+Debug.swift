//
//  SKTiled+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden.
//
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import SpriteKit


/**
 
 ## Overview
 
 A structure representing debug drawing options for **SKTiled** objects.
 
 ### Usage
 
 ```swift
 // show the map's grid & bounds shape
 tilemap.debugDrawOptions = [.drawGrid, .drawBounds]
 
 // turn off layer grid visibility
 layer.debugDrawOptions.remove(.drawGrid)
 ```
 
 ### Properties
 
 | Property         | Description                              |
 |:-----------------|:-----------------------------------------|
 | drawGrid         | Draw the layer's tile grid.              |
 | drawBounds       | Draw the layer's boundary.               |
 | drawGraph        | Visualize the layer's pathfinding graph. |
 | drawObjectBounds | Draw vector object bounds.               |
 | drawTileBounds   | Draw tile boundary shapes.               |
 | drawBackground   | Draw the layer's background color.       |
 | drawAnchor       | Draw the layer's anchor point.           |
 
 */
public struct DebugDrawOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }
    
    static public let drawGrid              = DebugDrawOptions(rawValue: 1 << 0) // 1
    static public let drawBounds            = DebugDrawOptions(rawValue: 1 << 1) // 2
    static public let drawGraph             = DebugDrawOptions(rawValue: 1 << 2) // 4
    static public let drawObjectBounds      = DebugDrawOptions(rawValue: 1 << 3) // 8
    static public let drawTileBounds        = DebugDrawOptions(rawValue: 1 << 4) // 16
    static public let drawMouseOverObject   = DebugDrawOptions(rawValue: 1 << 5) // 32
    static public let drawBackground        = DebugDrawOptions(rawValue: 1 << 6) // 64
    static public let drawAnchor            = DebugDrawOptions(rawValue: 1 << 7) // 128
    
    static public let all: DebugDrawOptions = [.drawGrid, .drawBounds, .drawGraph, .drawObjectBounds,
                                               .drawObjectBounds, .drawMouseOverObject,
                                               .drawBackground, .drawAnchor]
}


// MARK: - SKTilemap Extensions


extension SKTilemap {
    
    /**
     Draw the map bounds.
     
     - parameter withColor: `SKColor?` optional highlight color.
     - parameter zpos:      `CGFloat?` optional z-position of bounds shape.
     - parameter duration:  `TimeInterval` effect length.
     */
    internal func drawBounds(withColor: SKColor? = nil, zpos: CGFloat? = nil, duration: TimeInterval = 0) {
        // remove old nodes
        self.childNode(withName: "MAP_BOUNDS")?.removeFromParent()
        self.childNode(withName: "MAP_ANCHOR")?.removeFromParent()
        
        // if a color is not passed, use the default frame color
        let drawColor = (withColor != nil) ? withColor! : self.frameColor
        
        
        let debugZPos = lastZPosition * 50
        
        let scaledVertices = getVertices().map { $0 * renderQuality }
        let tilemapPath = polygonPath(scaledVertices)
        
        
        let boundsShape = SKShapeNode(path: tilemapPath) // , centered: true)
        boundsShape.name = "MAP_BOUNDS"
        boundsShape.fillColor = drawColor.withAlphaComponent(0.2)
        boundsShape.strokeColor = drawColor
        self.addChild(boundsShape)
        
        
        boundsShape.isAntialiased = true
        boundsShape.lineCap = .round
        boundsShape.lineJoin = .miter
        boundsShape.miterLimit = 0
        boundsShape.lineWidth = 1 * (renderQuality / 2)
        boundsShape.setScale(1 / renderQuality)
        
        let anchorRadius = self.tileHeightHalf / 4
        let anchorShape = SKShapeNode(circleOfRadius: anchorRadius * renderQuality)
        anchorShape.name = "MAP_ANCHOR"
        anchorShape.fillColor = drawColor.withAlphaComponent(0.25)
        anchorShape.strokeColor = .clear
        boundsShape.addChild(anchorShape)
        boundsShape.zPosition = debugZPos
        
        if (duration > 0) {
            let fadeAction = SKAction.fadeAfter(wait: duration, alpha: 0)
            boundsShape.run(fadeAction, withKey: "MAP_FADEOUT_ACTION", completion: {
                boundsShape.removeFromParent()
            })
        }
    }
}






extension DebugDrawOptions {
    
    public var strings: [String] {
        var result: [String] = []
        
        if self.contains(.drawGrid) {
            result.append("Draw Grid")
        }
        if self.contains(.drawBounds) {
            result.append("Draw Bounds")
        }
        if self.contains(.drawGraph) {
            result.append("Draw Graph")
        }
        if self.contains(.drawObjectBounds) {
            result.append("Draw Object Bounds")
        }
        if self.contains(.drawTileBounds) {
            result.append("Draw Tile Bounds")
        }
        if self.contains(.drawMouseOverObject) {
            result.append("Draw Mouse Over Object")
        }
        if self.contains(.drawBackground) {
            result.append("Draw Background")
        }
        if self.contains(.drawAnchor) {
            result.append("Draw Anchor")
        }
        return result
    }
}


extension DebugDrawOptions: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    
    public var description: String {
        guard (strings.isEmpty == false) else {
            return "none"
        }
        return strings.joined(separator: ", ")
    }
    
    public var debugDescription: String {
        return description
    }
    
    public var customMirror: Mirror {
        return Mirror(reflecting: DebugDrawOptions.self)
    }
}


extension SKTilemap: Loggable {}
extension SKTiledLayerObject: Loggable {}
extension SKTileset: Loggable {}
extension SKTilemapParser: Loggable {}
extension SKTiledDebugDrawNode: Loggable {}




/// :nodoc:
protocol CustomDebugReflectable: AnyObject {
    func dumpStatistics()
}



extension CustomDebugReflectable {
    
    func underlined(for string: String, symbol: String? = nil, colon: Bool = true) -> String {
        let symbolString = symbol ?? "#"
        let colonString = (colon == true) ? ":" : ""
        let spacer = String(repeating: " ", count: symbolString.count)
        let formattedString = "\(symbolString)\(spacer)\(string)\(colonString)"
        let underlinedString = String(repeating: "-", count: formattedString.count)
        return "\n\(formattedString)\n\(underlinedString)\n"
    }
}
