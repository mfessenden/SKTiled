//
//  SKTile.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/// represents a single tile object.
class SKTile: SKSpriteNode {
    
    public var tileData: SKTileData
    weak public var tileLayer: SKTileLayer!         // layer parent, assigned on add
    
    public init(data: SKTileData){
        self.tileData = data
        super.init(texture: SKTexture(), color: SKColor.clearColor(), size: tileData.tileSet.tileSize.cgSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}