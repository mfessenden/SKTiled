//
//  SKTilesetData.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.

import SpriteKit


/// Represents a single tileset tile data, with texture, id and properties
public class SKTilesetData {
    
    weak public var tileset: SKTileset!             // is assigned on add
    public var id: Int = 0
    public var texture: SKTexture!                  // initial tile texture
    public var probability: CGFloat = 1.0           // used in Tiled application, might not be useful here.
    public var properties: [String: String] = [:]
    
    // animation frames
    public var frames: [Int] = []
    public var duration: NSTimeInterval = 0.1
    public var isAnimated: Bool { return frames.count > 0 }
    
    // flipped flags
    public var flipHoriz: Bool = false
    public var flipVert:  Bool = false
    public var flipDiag:  Bool = false
    
    public init(tileId: Int, texture: SKTexture, tileSet: SKTileset) {
        self.id = tileId
        self.texture = texture
        self.texture.filteringMode = .Nearest
        self.tileset = tileSet
    }
    
    /**
     Add tile animation to the data.
     
     - parameter gid:         `Int` id for frame.
     - parameter duration:    `NSTimeInterval` frame interval.
     - parameter tileTexture: `SKTexture?` frame texture.
     */
    public func addFrame(gid: Int, interval: NSTimeInterval, tileTexture: SKTexture?=nil) {
        frames.append(gid)
        duration = interval
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
        var dataString = properties.count > 0 ? "Tile ID: \(id) @ \(tileset.tileSize), " : "Tile ID: \(id) @ \(tileset.tileSize)"
        for (index, pair) in properties.enumerate() {
            var pstring = (index < properties.count - 1) ? "\"\(pair.0)\": \(pair.1)," : "\"\(pair.0)\": \(pair.1)"
            dataString += pstring
        }
        return dataString
    }
    
    public var debugDescription: String {
        return description
    }
}

