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
public func imageOfSize(size: CGSize, scale: CGFloat=1, _ whatToDraw: ()->()) -> UIImage {
    // create an image of size, not opaque, not scaled
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    whatToDraw()
    let result = UIGraphicsGetImageFromCurrentImageContext()
    return result
}


public extension CGFloat {
    
    /**
     Clamp the CGFloat between two values. Returns a new value.
     
     - parameter v1: `CGFloat` min value
     - parameter v2: `CGFloat` min value
     
     - returns: `CGFloat` clamped result.
     */
    public func clamped(minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
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
    public mutating func clamp(minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        self = clamped(minv, maxv)
        return self
    }
    
    /**
     Returns a string representation of the value rounded to the current decimals.
     
     - parameter decimals: `Int` number of decimals to round to.
     
     - returns: `String` rounded display string.
     */
    public func displayRounded(decimals: Int=2) -> String {
        return String(format: "%.\(String(decimals))f", self)
    }
    
    /**
     Returns the value rounded to the nearest .5 increment.
     
     - returns: `CGFloat` rounded value.
     */
    public func roundToHalf() -> CGFloat {
        let scaled = self * 10.0
        let result = scaled - (scaled % 5)
        return round(result) / 10.0
    }
}


public extension CGPoint {
    
    public func displayRounded() -> String {
        return "x: \(self.x.displayRounded()), y: \(self.y.displayRounded())"
    }
}


public extension SKScene {
    /**
     Returns the center point of a scene.
     */
    public var center: CGPoint {
        return CGPointMake((size.width / 2) - (size.width * anchorPoint.x), (size.height / 2) - (size.height * anchorPoint.y))
    }
    
    /**
     Calculate the distance from the scene's origin
     */
    public func distanceFromOrigin(pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVectorMake(dx, dy)
    }
}



public extension SKNode {
    
    
    public var drawAnchor: Bool {
        get {
            return childNodeWithName("ANCHOR") != nil
        } set {
            childNodeWithName("ANCHOR")?.removeFromParent()
            
            if (newValue == true) {
                let anchorNode = SKNode()
                anchorNode.name = "ANCHOR"
                addChild(anchorNode)
                let anchorShape = SKShapeNode(circleOfRadius: 4.0)
                anchorShape.fillColor = SKColor.whiteColor()
                anchorShape.zPosition = zPosition + 10
                anchorNode.addChild(anchorShape)
                
                if let name = name {
                    let label = SKLabelNode(fontNamed: "Courier")
                    label.fontSize = 8
                    label.position.y -= 10
                    anchorNode.addChild(label)
                    var labelText = name
                    if let scene = scene {
                        labelText += ": \(scene.convertPointFromView(position))"
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
    public func runAction(action: SKAction!, withKey: String!, optionalCompletion: dispatch_block_t? ){
        if let completion = optionalCompletion {
            let completionAction = SKAction.runBlock( completion )
            let compositeAction = SKAction.sequence([ action, completionAction ])
            runAction(compositeAction, withKey: withKey)
        } else {
            runAction(action, withKey: withKey)
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
    
    public func colorWithBrightness(factor: CGFloat) -> SKColor {
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