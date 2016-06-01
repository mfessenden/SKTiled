//
//  SKTileset+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public extension SKTileset {
    
    public func debugTileset(){
        for data in tileData.sort({$0.id < $1.id}) {
            print(data.description)
        }
    }
    
    /**
     Playground debugging visualization.
     
     - returns: `AnyObject` visualization
     */
    public func debugQuickLookObject() -> AnyObject {
        return SKTexture(imageNamed: source)
    }
}
