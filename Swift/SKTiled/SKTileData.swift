//
//  SKTileData.swift
//  SKTiled
//
//  Created by Michael Fessenden on 5/17/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// represents a single tile's attributes
public class SKTileData {
    
    weak public var tileSet: SKTileset!
    public let id: Int
    public var probability: CGFloat = 1.0
    
    public init(id: Int){
        self.id = id
    }
}