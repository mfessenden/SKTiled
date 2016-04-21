//
//  SKTileset.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// <tileset firstgid="1" name="Roguelike" tilewidth="16" tileheight="16" spacing="1" tilecount="1767" columns="57">
public class SKTileset {
    
    public var name: String
    weak public var tilemap: SKTilemap!
    public var firstGID: Int = 1                    // first GID
    public var tileSize: TileSize
    
    // image spacing
    public var spacing: CGFloat = 0                 // spacing between tiles
    public var margin: CGFloat = 0                  // border margin
    
    public var properties: [String: String] = [:]
    public var offset: CGPoint                      // check this...forget if TileSet has offset
    
    public init(name: String, tilemap: SKTilemap, offset: CGPoint=CGPointZero) {
        self.name = name
        self.tilemap = tilemap
        self.tileSize = tilemap.tileSize
        self.offset = offset
    }
    
    public init?(name: String, tilemap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero){
        // name, width and height are required
        guard let layerName = attributes["name"] as String! else { return nil }
        guard let width = attributes["width"] as String! else { return nil }
        guard let height = attributes["height"] as String! else { return nil }
        
        self.name = layerName
        self.tilemap = tilemap
        self.tileSize = tilemap.tileSize
        self.offset = offset
    }
    
    // MARK: - Textures
    
    /**
     Add tile data from a sprite sheet.
     
     - parameter spritesheet: `String` image named referenced in the tileset.
     */
    public func addTextures(spritesheet: String) {
        
    }
}


public func ==(lhs: SKTileset, rhs: SKTileset) -> Bool{
    return (lhs.hashValue == rhs.hashValue)
}


extension SKTileset: Equatable, Hashable {
    
    public var hashValue: Int {
        return name.hashValue
    }
}
