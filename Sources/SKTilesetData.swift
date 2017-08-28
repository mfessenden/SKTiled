//
//  SKTilesetData.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.

import SpriteKit


/**
 A structure representing frame of animation.

 - parameter gid:       `Int` unique tile id.
 - parameter duration:  `TimeInterval` frame duration.
  - parameter texture:  `SKTexture?` optional tile texture.
 */
internal struct AnimationFrame {
    public var gid: Int = 0
    public var duration: TimeInterval = 0
    public var texture: SKTexture?
}


/**
 A structure representing a tile collision shape.

 - parameter points:  `[CGPoint]` frame duration.
 */
internal class SKTileCollisionShape: SKTiledObject {

    var uuid: String = UUID().uuidString
    var type: String!
    var properties: [String: String] = [:]
    var ignoreProperties: Bool = false
    var renderQuality: CGFloat = 1

    public var id: Int = 0
    public var points: [CGPoint] = []
}


/**

 ## Overview ##

 The `SKTilesetData` object stores data for a single tileset tile, referencing the tile texture, animation frames (for animated tiles) as well as tile orientation.

 Also includes navigation properties for tile accessability, and graph node weight.
*/
public class SKTilesetData: SKTiledObject {

    weak public var tileset: SKTileset!             // reference to parent tileset
    public var uuid: String = UUID().uuidString     // unique id
    /// Object type.
    public var type: String!
    public var id: Int = 0                          // tile id (local)
    /// Tile texture.
    public var texture: SKTexture!
    /// Source image name (collections tileset)
    public var source: String! = nil
    public var probability: CGFloat = 1.0           // used in Tiled application, might not be useful here.
    public var properties: [String: String] = [:]
    public var ignoreProperties: Bool = false       // ignore custom properties
    public var tileOffset: CGPoint = .zero          // tile offset
    /// Render scaling property.
    public var renderQuality: CGFloat = 8

    /// Animated frames.
    internal var frames: [AnimationFrame] = []
    /// Indicates the tile is animated.
    public var isAnimated: Bool { return frames.isEmpty == false }

    // MARK: Tile Orientation

    /// Tile is flipped horizontally
    public var flipHoriz: Bool = false
    /// Tile is flipped vertically.
    public var flipVert:  Bool = false
    /// Tile is flipped diagonally.
    public var flipDiag:  Bool = false

    // MARK: Pathfinding Attributes

    /// Tile is walkable.
    public var walkable: Bool = false
    /// Tile is an obstacle.
    public var obstacle: Bool = false
    /// Pathfinding weight.
    public var weight: CGFloat = 1

    /// Collision objects (not yet implemented).
    public var collisions: [SKTileObject] = []

    /// Local id for this tile.
    public var localID: Int {
        guard let tileset = tileset else { return id }
        return tileset.getLocalID(forGlobalID: id)
    }

    /// Global id for this tile.
    public var globalID: Int {
        guard let tileset = tileset else { return id }
        return (localID == id) ? (tileset.firstGID + id) : id
    }

    // MARK: - Init

    /**
     Initialize an empty data structure.
     */
    public init() {}

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
        self.tileOffset = tileSet.tileOffset
        self.ignoreProperties = tileSet.ignoreProperties
    }

    /**
     Initialize the data with a tileset, id & texture.

     - parameter id:      `Int` unique tile id.
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

        self.tileOffset = tileSet.tileOffset
        self.ignoreProperties = tileSet.ignoreProperties
    }

    // MARK: - Animation

    /**
     Add tile animation to the data.

     - parameter gid:         `Int` id for frame.
     - parameter duration:    `TimeInterval` frame interval.
     - parameter tileTexture: `SKTexture?` frame texture.
     */
    public func addFrame(withID: Int, interval: TimeInterval, tileTexture: SKTexture? = nil) {
        var id = withID
        // if the tileset firstGID is already set, subtract it to get the internal id
        if let tileset = tileset, tileset.firstGID > 0 {
            id = withID - tileset.firstGID
        }
        frames.append(AnimationFrame(gid: id, duration: interval, texture: tileTexture))
    }

    /**
     Remove a tile animation frame at a given index.

     - parameter at: `Int` frame index.
     - returns: `AnimationFrame?` animation frame (if it exists).
     */
    func removeFrame(at index: Int) -> AnimationFrame? {
        return frames.remove(at: index)
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


public func == (lhs: SKTilesetData, rhs: SKTilesetData) -> Bool {
    return (lhs.hashValue == rhs.hashValue)
}


extension SKTilesetData: Hashable {
    public var hashValue: Int { return id.hashValue }
}


extension AnimationFrame: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String { return "Frame: \(gid): \(duration * 1000)" }
    var debugDescription: String { return description }
}


extension SKTilesetData: CustomStringConvertible, CustomDebugStringConvertible {

    /// Tile data description.
    public var description: String {
        guard let tileset = tileset else { return "Tile ID: \(id) (no tileset)" }
        let typeString = (type != nil) ? ", type: \"\(type!)\"" : ""
        let framesString = (isAnimated == true) ? ", \(frames.count) frames" : ""
        let dataString = properties.isEmpty == false ? "Tile ID: \(globalID)\(typeString) @ \(tileset.tileSize.shortDescription)\(framesString), " : "Tile ID: \(globalID)\(typeString) @ \(tileset.tileSize.shortDescription)\(framesString)"

        return "\(dataString)\(propertiesString)"
    }

    public var debugDescription: String {
        return "<\(description)>"
    }
}
