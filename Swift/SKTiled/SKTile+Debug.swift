//
//  SKTile+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


extension SKTile {
    
    /**
     Playground debugging visualization.
     
     - returns: `AnyObject` visualization
     */
    func debugQuickLookObject() -> AnyObject {
        let size = self.tileData.tileset.tileSize
        let shape = SKShapeNode(rectOfSize: size.cgSize)
        return shape
    }
}