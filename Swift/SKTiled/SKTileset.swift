//
//  SKTileset.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//
//  Reference:  http://doc.mapeditor.org/reference/tmx-map-format/

import SpriteKit


// <tileset firstgid="1" name="Roguelike" tilewidth="16" tileheight="16" spacing="1" tilecount="1767" columns="57">
public class SKTileset {
    
    public var name: String
    weak public var tilemap: SKTilemap!
    public var tileSize: TileSize
    
    public var firstGID: Int = 1                    // first GID
    public var columns: Int = 0                     // number of columns
    
    
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
    
    public init?(attributes: [String: String], offset: CGPoint=CGPointZero){
        // name, width and height are required
        guard let layerName = attributes["name"] as String! else { return nil }
        guard let width = attributes["tilewidth"] as String! else { return nil }
        guard let height = attributes["tileheight"] as String! else { return nil }
        
        self.name = layerName
        self.tileSize = TileSize(width: CGFloat(Int(width)!), height: CGFloat(Int(width)!))
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


// Hashable requires == func & hashValue: Int
extension SKTileset: Hashable {
    
    public var hashValue: Int {
        return name.hashValue
    }
}
