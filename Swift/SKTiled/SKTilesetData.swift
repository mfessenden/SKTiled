//
//  SKTileData.swift
//  SKTiled
//
//  Created by Michael Fessenden on 5/17/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/// represents a single tileset tile data, with texture, id and properties
public class SKTilesetData {
    
    weak public var tileset: SKTileset!     // is assigned on add
    public var id: Int = 0
    public var texture: SKTexture!
    public var probability: CGFloat = 1.0
    public var properties: [String: String] = [:]
    
    public init(tileId: Int, texture: SKTexture, tileSet: SKTileset) {
        self.id = tileId
        self.texture = texture
        self.texture.filteringMode = .Nearest
        self.tileset = tileSet
    }
}


public func ==(lhs: SKTilesetData, rhs: SKTilesetData) -> Bool{
    return (lhs.hashValue == rhs.hashValue)
}


// Hashable requires == func & hashValue: Int
extension SKTilesetData: Hashable {
    
    public var hashValue: Int {
        return id.hashValue
    }
}



extension SKTilesetData: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Tile ID: \(id) @ \(tileset.tileSize)"
    }
    
    public var debugDescription: String {
        return description
    }
}