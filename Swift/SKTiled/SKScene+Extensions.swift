//
//  SKScene+Extensions.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/23/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit


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

