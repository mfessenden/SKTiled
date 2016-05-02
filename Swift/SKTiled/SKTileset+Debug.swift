//
//  SKTileset+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


extension SKTileset {
    
    /**
     Playground debugging visualization.
     
     - returns: `AnyObject` visualization
     */
    func debugQuickLookObject() -> AnyObject {
        return SKTexture(imageNamed: source)
    }
}