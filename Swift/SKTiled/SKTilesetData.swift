//
//  SKTilesetData.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.

import SpriteKit


/// represents a single tileset tile data, with texture, id and properties
public class SKTilesetData {
    
    weak public var tileset: SKTileset!     // is assigned on add
    public var id: Int = 0
    public var probability: CGFloat = 1.0
}

