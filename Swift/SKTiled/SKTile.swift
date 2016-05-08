//
//  SKTile.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/// represents a single tile object.
public class SKTile: SKSpriteNode {
    
    public var tileData: SKTilesetData
    weak public var tileLayer: SKTileLayer!         // layer parent, assigned on add
    
    public init(data: SKTilesetData){
        self.tileData = data
        super.init(texture: data.texture, color: SKColor.clearColor(), size: data.texture.size())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension SKTile {
    
    override public var description: String {
        return "Sprite ID: \(tileData.id) @ \(tileData.tileset.tileSize)"
    }
    
    override public var debugDescription: String {
        return description
    }
}