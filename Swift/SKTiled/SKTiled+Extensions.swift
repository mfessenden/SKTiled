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
    
    public func displayRounded(decimals: Int=2) -> String {
        return String(format: "%.\(String(decimals))f", self)
    }
    
    // round to nearest .5
    public func roundToHalf() -> CGFloat {
        let scaled = self * 10.0
        let result = scaled - (scaled % 5)
        return round(result) / 10.0
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