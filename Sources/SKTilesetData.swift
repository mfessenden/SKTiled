//
//  SKTilesetData.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.

import SpriteKit


/**
 A simple data structure representing an animated tile frame.
 
 - parameter gid:       `Int` unique tile id.
 - parameter duration:  `TimeInterval` frame duration.
  - parameter texture:  `SKTexture?` optional tile texture.
 */
internal struct AnimationFrame {
    public var gid: Int = 0
    public var duration: TimeInterval = 0
    public var texture: SKTexture? = nil
}


/**
 The `SKTilesetData` object stores data for a single tileset tile, referencing the
 tile texture, animation frames (for animated tiles) as well as tile flip flags.
 
 Also includes pathfinding properties for tile accessability, and graph node weight.
*/
open class SKTilesetData: SKTiledObject  {
    
    weak open var tileset: SKTileset!             // reference to parent tileset
    open var uuid: String = UUID().uuidString     // unique id
    open var id: Int = 0                          // tile id
    open var texture: SKTexture!                  // initial tile texture
    open var source: String! = nil                // source image name (part of a collections tileset)
    open var probability: CGFloat = 1.0           // used in Tiled application, might not be useful here.
    open var properties: [String: String] = [:]
    
    // animation frames
    internal var frames: [AnimationFrame] = []    // animation frames
    open var isAnimated: Bool { return frames.count > 0 }
    
    // flipped flags
    open var flipHoriz: Bool = false              // tile is flipped horizontally
    open var flipVert:  Bool = false              // tile is flipped vertically
    open var flipDiag:  Bool = false              // tile is flipped diagonally
    
    // pathfinding
    open var walkable: Bool = false               // tile is walkable.
    open var weight: CGFloat = 1                  // tile weight.
    
    open var localID: Int {                       // return the local id for this tile
        guard let tileset = tileset else { return id }
        return tileset.getLocalID(forGlobalID: id)
    }
    
    // MARK: - Init
    public init(){}
    
    /**
     Initialize the data with a tileset, id.
    
     - parameter tileId:  `Int` unique tile id.
     - parameter tileSet: `SKTileset` tileset reference.
     - returns: `SKTilesetData` tile data.
     */
    public init(id: Int, withTileset tileSet: SKTileset) {
        self.id = id
        self.tileset = tileSet
        self.parseTileID(id: id)
    }
    
    /**
     Initialize the data with a tileset, id & texture.
     
     - parameter tileId:  `Int` unique tile id.
     - parameter texture: `SKTexture` tile texture.
     - parameter tileSet: `SKTileset` tileset reference.
     - returns: `SKTilesetData` tile data.
     */
    public init(id: Int, texture: SKTexture, tileSet: SKTileset) {
        self.id = id
        self.texture = texture
        self.texture.filteringMode = .nearest
        self.tileset = tileSet
        self.parseTileID(id: id)
    }
    
    // MARK: - Animation
    
    /**
     Add tile animation to the data.
     
     - parameter gid:         `Int` id for frame.
     - parameter duration:    `TimeInterval` frame interval.
     - parameter tileTexture: `SKTexture?` frame texture.
     */
    open func addFrame(withID: Int, interval: TimeInterval, tileTexture: SKTexture? = nil) {
        frames.append(AnimationFrame(gid: withID, duration: interval, texture: tileTexture))
    }
    
    /**
     Remove a tile animation frame.
     
     - parameter gid: `Int` id for frame.
     - returns: `AnimationFrame?` animation frame (if it exists).
     */
    func removeFrame(_ gid: Int) -> AnimationFrame? {
        if let index = frames.index( where: { $0.gid == gid } ) {
            return frames.remove(at: index)
        }
        return nil
    }
    
    /**
     Translate the global id. Returns the translated tile ID
     and the corresponding flip flags.
     
     - parameter id: `Int` tile ID
     */
    private func parseTileID(id: Int) {
        // masks for tile flipping
        let flippedDiagonalFlag: UInt32   = 0x20000000
        let flippedVerticalFlag: UInt32   = 0x40000000
        let flippedHorizontalFlag: UInt32 = 0x80000000
        
        let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
        let flippedMask = ~(flippedAll)
        
        // set the current flip flags
        self.flipHoriz = (UInt32(id) & flippedHorizontalFlag) != 0
        self.flipVert  = (UInt32(id) & flippedVerticalFlag) != 0
        self.flipDiag  = (UInt32(id) & flippedDiagonalFlag) != 0
        
        // get the actual gid from the mask
        self.id = Int(UInt32(id) & flippedMask)
    }
}


public func ==(lhs: SKTilesetData, rhs: SKTilesetData) -> Bool {
    return (lhs.hashValue == rhs.hashValue)
}


extension SKTilesetData: Hashable {
    public var hashValue: Int { return id.hashValue }
}


extension AnimationFrame: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String { return "\(gid): \(duration)" }
    var debugDescription: String { return description }
}


extension SKTilesetData: CustomStringConvertible, CustomDebugStringConvertible {
    
    /// Tile data description.
    public var description: String {
        guard let tileset = tileset else { return "Tile ID: \(id) (no tileset)" }
        let tileSizeString = "\(Int(tileset.tileSize.width))x\(Int(tileset.tileSize.height))"
        let dataString = properties.count > 0 ? "Tile ID: \(id) @ \(tileSizeString), " : "Tile ID: \(id) @ \(tileSizeString)"
        return "\(dataString)\(propertiesString)"
    }
    
    public var debugDescription: String { return description }
}
