//
//  SKTilesetData.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.

import SpriteKit


public struct AnimationFrame {
    public var gid: Int
    public var duration: NSTimeInterval
    public var texture: SKTexture?
}


/// Represents a single tileset tile data, with texture, id and properties
public class SKTilesetData {
    
    weak public var tileset: SKTileset!             // is assigned on add
    public var id: Int = 0
    public var texture: SKTexture!                  // initial tile texture
    public var probability: CGFloat = 1.0           // used in Tiled application, might not be useful here.
    public var properties: [String: String] = [:]
    
    public var frames: [AnimationFrame] = []
    public var isAnimated: Bool { return frames.count > 0 }
    
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
    public func addFrame(gid: Int, duration: NSTimeInterval, tileTexture: SKTexture?=nil) {
        //print("[SKTilesetData]: tile id: \(id), adding frame: \(gid)")
        frames.append(AnimationFrame(gid: gid, duration: duration, texture: tileTexture))
    }
    
    public func animationAction() -> SKAction? {
        if (isAnimated == false) {
            return nil
        }
        
        var textures: [SKTexture] = []
        var duration: NSTimeInterval = 0.1
        for frame in frames {
            duration = frame.duration
            if let frameTexture = tileset.tilemap.getTileData(frame.gid)?.texture {
                textures.append(frameTexture)
            }
        }
        
        if (textures.count > 0) {
            return SKAction.animateWithTextures(textures, timePerFrame: duration, resize: true, restore: false)
        }
        return nil
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
