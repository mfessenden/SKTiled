//
//  SKTilemap+Extensions.swift
//  SKTiled
//
//  Created by Michael Fessenden on 4/5/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit


/**
 Returns an image of the given size.
 
 - parameter size:       `CGSize` size of resulting image.
 - parameter scale:      `CGFloat` scale of result (0 seems to scale 2x, using 1 seems best)
 - parameter whatToDraw: function detailing what to draw the image.
 
 - returns: `UIImage` result.
 */
public func imageOfSize(_ size: CGSize, scale: CGFloat=1, _ whatToDraw: ()->()) -> UIImage {
    // create an image of size, not opaque, not scaled
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    whatToDraw()
    let result = UIGraphicsGetImageFromCurrentImageContext()
    return result!
}


public extension CGFloat {
    
    /**
     Convert a float to radians.
     
     - returns: `CGFloat`
     */
    public func radians() -> CGFloat {
        let b = CGFloat(M_PI) * (self/180)
        return b
    }
    
    /**
     Clamp the CGFloat between two values. Returns a new value.
     
     - parameter v1: `CGFloat` min value
     - parameter v2: `CGFloat` min value
     
     - returns: `CGFloat` clamped result.
     */
    public func clamped(_ minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        let min = minv < maxv ? minv : maxv
        let max = minv > maxv ? minv : maxv
        return self < min ? min : (self > max ? max : self)
    }
    
    /**
     Clamp the current value between min & max values.
     
     - parameter v1: `CGFloat` min value
     - parameter v2: `CGFloat` min value
     
     - returns: `CGFloat` clamped result.
     */
    public mutating func clamp(_ minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        self = clamped(minv, maxv)
        return self
    }
    
    /**
     Returns a string representation of the value rounded to the current decimals.
     
     - parameter decimals: `Int` number of decimals to round to.
     
     - returns: `String` rounded display string.
     */
    public func roundoff(_ decimals: Int=2) -> String {
        return String(format: "%.\(String(decimals))f", self)
    }
    
    /**
     Returns the value rounded to the nearest .5 increment.
     
     - returns: `CGFloat` rounded value.
     */
    public func roundToHalf() -> CGFloat {
        let scaled = self * 10.0
        let result = scaled - (scaled.truncatingRemainder(dividingBy: 5))
        return result.rounded() / 10
    }
}



public extension CGPoint {
    
    /// Returns an point inverted in the Y-coordinate.
    public var invertedY: CGPoint {
        return CGPoint(x: self.x, y: self.y * -1)
    }
    
    /**
     Returns a display string rounded.
     
     - parameter decimals: `Int` decimals to round to.
     
     - returns: `String` display string.
     */
    public func roundoff(_ decimals: Int=1) -> String {
        return "x: \(self.x.roundoff(decimals)), y: \(self.y.roundoff(decimals))"
    }
}


public extension CGSize {
    
    public init(width: Int, height: Int) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
    
    public var count: Int { return Int(width) * Int(height) }
    
    public var halfWidth: CGFloat {
        return width / 2.0
    }
    
    public var halfHeight: CGFloat {
        return height / 2.0
    }
    
    public func roundoff(_ decimals: Int=1) -> String {
        return "w: \(self.width.roundoff(decimals)), h: \(self.height.roundoff(decimals))"
    }
}


public extension CGRect {
    
    public var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    public var topLeft: CGPoint {
        return origin
    }
    
    public var topRight: CGPoint {
        return CGPoint(x: self.maxX, y: origin.y)
    }
    
    public var bottomLeft: CGPoint {
        return CGPoint(x: origin.x, y: self.maxY)
    }
    
    public var bottomRight: CGPoint {
        return CGPoint(x: self.maxX, y: self.maxY)
    }

    public var points: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
}


public extension SKScene {
    /**
     Returns the center point of a scene.
     */
    public var center: CGPoint {
        return CGPoint(x: (size.width / 2) - (size.width * anchorPoint.x), y: (size.height / 2) - (size.height * anchorPoint.y))
    }
    
    /**
     Calculate the distance from the scene's origin
     */
    public func distanceFromOrigin(_ pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVector(dx: dx, dy: dy)
    }

    public func tilesAt(scenePoint point: CGPoint) -> [SKTile] {
        let result: [SKTile] = []
        return result
    }
}



public extension SKNode {
    
    /// visualize a node's anchor point.
    public var drawAnchor: Bool {
        get {
            return childNode(withName: "Anchor") != nil
        } set {
            childNode(withName: "Anchor")?.removeFromParent()
            
            if (newValue == true) {
                let anchorNode = SKNode()
                anchorNode.name = "Anchor"
                addChild(anchorNode)
                
                let radius: CGFloat = self.frame.size.width / 24 < 2 ? 1.0 : self.frame.size.width / 36
                
                let anchorShape = SKShapeNode(circleOfRadius: radius)
                anchorShape.strokeColor = SKColor.clear
                anchorShape.fillColor = SKColor(white: 1, alpha: 0.4)
                anchorShape.zPosition = zPosition + 10
                anchorNode.addChild(anchorShape)
                
                
                
                if let name = name {
                    let label = SKLabelNode(fontNamed: "Courier")
                    label.fontSize = 8
                    label.position.y -= 10
                    label.position.x -= 6
                    anchorNode.addChild(label)
                    var labelText = name
                    if let scene = scene {
                        labelText += ": \(scene.convertPoint(fromView: position).roundoff(1))"
                        labelText += ": \(position.roundoff(1))"
                    }
                    label.text = labelText
                }
            }
        }
    }
    
    /**
     Run an action with key & optional completion function.
     
     - parameter action:             `SKAction` SpriteKit action.
     - parameter withKey:            `String` action key.
     - parameter optionalCompletion: `() -> ()` optional completion function.
     */
    public func runAction(_ action: SKAction!, withKey: String!, optionalCompletion block: (()->())?) {
        if let block = block {
            let completionAction = SKAction.run( block )
            let compositeAction = SKAction.sequence([ action, completionAction ])
            run(compositeAction, withKey: withKey)
        } else {
            run(action, withKey: withKey)
        }
    }
}


public extension SKColor {

    /**
     Lightens the color by the given percentage.
     
     - parameter percent: `CGFloat`
     
     - returns: `SKColor` lightened color.
     */
    public func lighten(by percent: CGFloat) -> SKColor {
        return colorWithBrightness(1.0 + percent)
    }
    
    /**
     Darkens the color by the given percentage.
     
     - parameter percent: `CGFloat`
     
     - returns: `SKColor` darkened color.
     */
    public func darken(by percent: CGFloat) -> SKColor {
        return colorWithBrightness(1.0 - percent)
    }
    
    public func colorWithBrightness(_ factor: CGFloat) -> SKColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return SKColor(hue: hue, saturation: saturation, brightness: brightness * factor, alpha: alpha)
        } else {
            return self;
        }
    }
}


public extension String {
    
    /**
     Initialize a string by repeating a character (or string)
     
     - parameter repeating: `String` pattern to repeat.
     - parameter count:     `Int` number of repetitions.
     */
    public init?(repeating str: String, count: Int) {
        var newString = ""
        for _ in 0 ..< count {
            newString += str
        }
        self.init(newString)
    }
    
    /// Returns `Int` length of the string.
    public var length: Int {
        return self.characters.count
    }
    
    /**
     Simple function to split the
     
     - parameter pattern: `String` pattern to split string with.
     
     - returns: `[String]` groups of split strings.
     */
    public func split(_ pattern: String) -> [String] {
        return self.components(separatedBy: pattern)
    }
    
    /**
     Returns an array of characters.
     
     - returns: `[String]`
     */
    public func toStringArray() -> [String]{
        return self.unicodeScalars.map { String($0) }
    }
    
    /**
     Pads string on the with a pattern to fill width.
     
     - parameter length:  `Int` length to fill.
     - parameter value:   `String` pattern.
     - parameter padLeft: `Bool` toggle this to pad the right.
     
     - returns: `String` padded string.
     */
    public func zfill(_ length: Int, pattern: String="0", padLeft: Bool=true) -> String {
        if length < 0 { return "" }
        guard length > self.characters.count else { return self }
        var filler = ""
        for _ in 0..<(length - self.characters.count) {
            filler += pattern
        }
        return (padLeft == true) ? filler + self : self + filler
    }
    
    /**
     Pad a string with zero's (for binary conversion).
     
     - parameter toSize: `Int` size of resulting string.
     
     - returns: `String` padded string.
     */
    public func pad(_ toSize: Int) -> String {
        if (toSize < 1) { return self }
        var padded = self
        for _ in 0..<toSize - self.characters.count {
            padded = " " + padded
        }
        return padded
    }
    
    /**
     Substitute a pattern in the string
     
     - parameter pattern:     `String` pattern to replace.
     - parameter replaceWith: replacement `String`
     
     - returns: `String` result.
     */
    public func substitute(_ pattern: String, replaceWith: String) -> String {
        return self.replacingOccurrences(of: pattern, with: replaceWith)
    }
}


// MARK: - Operators

// MARK: CGFloat
public func + (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) + rhs
}


public func + (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs + CGFloat(rhs)
}


public func - (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) - rhs
}


public func - (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs - CGFloat(rhs)
}


public func * (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) * rhs
}


public func * (lhs: Int32, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) * rhs
}


public func * (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs * CGFloat(rhs)
}


public func / (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) / rhs
}


public func / (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs / CGFloat(rhs)
}


// MARK: CGPoint

public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}


public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}


public func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
}


public func / (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
}


public func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}

public func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}




/**
 Generate a visual grid texture.
 
 - parameter layer: `TiledLayerObject` layer instance.
 - parameter scale: `CGFloat` image scale.
 
 - returns: `SKTexture?` visual grid texture.
 */
public func generateGrid(_ layer: TiledLayerObject, scale: CGFloat=2.0) -> SKTexture? {
    let image: UIImage = imageOfSize(layer.sizeInPoints, scale: scale) {
        
        for col in 0 ..< Int(layer.width) {
            for row in (0 ..< Int(layer.height)) {
                
                // inverted y-coordinate
                let ry = Int(layer.height - 1) - row
                
                let innerColor = layer.color.withAlphaComponent(0.25)
                
                let tileWidth = layer.tileWidth
                let tileHeight = layer.tileHeight
                
                let halfTileWidth = layer.tileWidthHalf
                let halfTileHeight = layer.tileHeightHalf
                
                let originX = layer.height * layer.tileWidthHalf
                
                let context = UIGraphicsGetCurrentContext()
                
                var shapePath: UIBezierPath? = nil
                innerColor.setStroke()
                
                
                var xpos: CGFloat = 0
                var ypos: CGFloat = 0
                
                switch layer.orientation {
                    
                case .Orthogonal:
                    xpos = tileWidth * CGFloat(col)
                    ypos = tileHeight * CGFloat(row)
                    
                    // rectangle shape
                    shapePath = UIBezierPath(rect: CGRect(x: xpos, y: ypos, width: tileWidth, height: tileHeight))
                    
                    
                case .Isometric:
                    xpos = (col - row) * halfTileWidth + originX
                    ypos = (col + row) * halfTileHeight
                    
                    
                    shapePath = UIBezierPath()
                    
                    // xpos, ypos is the top point of the diamond
                    shapePath!.move(to: CGPoint(x: xpos, y: ypos))
                    shapePath!.addLine(to: CGPoint(x: xpos - halfTileWidth, y: ypos + halfTileHeight))
                    shapePath!.addLine(to: CGPoint(x: xpos, y: ypos + tileHeight))
                    shapePath!.addLine(to: CGPoint(x: xpos + halfTileWidth, y: ypos + halfTileHeight))
                    shapePath!.addLine(to: CGPoint(x: xpos, y: ypos))
                    shapePath!.close()

                }
                
                
                if let shapePath = shapePath {
                    layer.gridColor.setStroke()
                    shapePath.lineWidth = 1
                    shapePath.stroke()
                }
                
                context?.saveGState()
                context?.restoreGState()
            }
        }
    }
    
    let result = SKTexture(cgImage: image.cgImage!)
    result.filteringMode = .nearest
    return result
}


// MARK: - Polygon Drawing

public func rectPointArray(_ width: CGFloat, height: CGFloat, origin: CGPoint=CGPoint.zero) -> [CGPoint] {
    let points: [CGPoint] = [
        origin,
        CGPoint(x: origin.x + width, y: origin.y),
        CGPoint(x: origin.x + width, y: origin.y - height),
        CGPoint(x: origin.x, y: origin.y - height)
    ]
    return points
}


public func rectPointArray(_ size: CGSize, origin: CGPoint=CGPoint.zero) -> [CGPoint] {
    return rectPointArray(size.width, height: size.height, origin: origin)
}


/**
 Returns an array of points describing a polygon shape.
 
 - parameter sides:  `Int` number of sides.
 - parameter radius: `CGSize` radius of circle.
 - parameter offset: `CGFloat` rotation offset (45 to return a rectangle).
 - parameter origin: `CGPoint` origin point.
 
 - returns: `[CGPoint]` array of points.
 */
public func polygonPointArray(_ sides: Int, radius: CGSize, offset: CGFloat=0, origin: CGPoint=CGPoint.zero) -> [CGPoint] {
    let angle = (360 / CGFloat(sides)).radians()
    let cx = origin.x // x origin
    let cy = origin.y // y origin
    let rx = radius.width // radius of circle
    let ry = radius.height
    var i = 0
    var points: [CGPoint] = []
    while i <= sides {
        let xpo = cx + rx * cos(angle * CGFloat(i) - offset.radians())
        let ypo = cy + ry * sin(angle * CGFloat(i) - offset.radians())
        points.append(CGPoint(x: xpo, y: ypo))
        i += 1
    }
    return points
}

/**
 Takes an array of points and returns a path.
 
 - parameter points:  `[CGPoint]` polygon points.
 - parameter closed:  `Bool` path should be closed.
 
 - returns: `CGPathRef` path from the given points.
 */
public func polygonPath(_ points: [CGPoint], closed: Bool=true) -> CGPath {
    let path = CGMutablePath()
    var mpoints = points
    let first = mpoints.remove(at: 0)
    path.move(to: first)
    
    for p in mpoints {
        path.addLine(to: p)
    }
    if (closed == true) {path.closeSubpath()}
    return path
}


/**
 Takes an array of points and returns a path.
 
 - parameter points:  `[CGPoint]` polygon points.
 - parameter closed:  `Bool` path should be closed.
 
 - returns: `CGPathRef` path from the given points.
 */
public func bezierPath(_ points: [CGPoint], radius: CGFloat, closed: Bool=true) -> CGPath {
    let path = CGMutablePath()
    var mpoints = points
    let first = mpoints.remove(at: 0)
    path.move(to: first)
    
    for p in mpoints {
        // TODO: check this
        path.addRelativeArc(center: p, radius: CGFloat(M_PI_2/2), startAngle: CGFloat(-M_PI_2/2), delta: radius)
    }
    if (closed == true) {path.closeSubpath()}
    return path
}


public func drawPolygonShape(_ sides: Int, radius: CGSize, color: UIColor, offset: CGFloat=0, origin: CGPoint=CGPoint.zero) -> SKShapeNode {
    let shape = SKShapeNode()
    shape.path = polygonPath(sides, radius: radius, offset: offset, origin: origin)
    shape.strokeColor = color
    shape.fillColor = color.withAlphaComponent(0.25)
    return shape
}


public func polygonPath(_ sides: Int, radius: CGSize, offset: CGFloat=0, origin: CGPoint=CGPoint.zero) -> CGPath {
    let path = CGMutablePath()
    let points = polygonPointArray(sides, radius: radius, offset: offset)
    let first = points[0]
    path.move(to: first)
    for p in points {
        path.addLine(to: p)
    }
    path.closeSubpath()
    return path
}


public func drawPolygonUsingPath(_ ctx: CGContext, sides: Int, radius: CGSize, color: UIColor, offset: CGFloat=0, origin: CGPoint=CGPoint.zero) {
    let path = polygonPath(sides, radius: radius, offset: offset, origin: origin)
    ctx.addPath(path)
    let cgcolor = color.cgColor
    ctx.setFillColor(cgcolor)
    ctx.fillPath()
}


public func drawPolygon(_ ctx: CGContext, sides: Int, radius: CGSize, color: UIColor, offset: CGFloat=0) {
    let points = polygonPointArray(sides, radius: radius, offset: offset)
    ctx.addLines(between: points)    
    let cgcolor = color.cgColor
    ctx.setFillColor(cgcolor)
    ctx.fillPath()
}


public func drawPolygonLayer(_ sides: Int, radius: CGSize, color: UIColor, offset: CGFloat=0, origin: CGPoint=CGPoint.zero) -> CAShapeLayer {
    let shape = CAShapeLayer()
    shape.path = polygonPath(sides, radius: radius, offset: offset, origin: origin)
    shape.fillColor = color.cgColor
    return shape
}

