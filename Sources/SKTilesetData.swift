//
//  SKTilesetData.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.

import SpriteKit


/**
 
 ## Overview ##
 
 A structure representing a single frame of animation. Time is stored in milliseconds.
 
 ### Properties ###
 
 | Property | Description             |
 |----------|-------------------------|
 | id       | unique tile (local) id. |
 | duration | frame duration.         |
 | texture  | optional tile texture.  |

 */
public class TileAnimationFrame: NSObject {
    public var id: Int = 0
    public var duration: Int = 0
    public var texture: SKTexture?

    public init(id: Int, duration: Int, texture: SKTexture? = nil) {
        super.init()
        self.id = id
        self.duration = duration
        self.texture = texture
    }
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

 ### Properties ###

 | Property   | Description     |
 |------------|-----------------|
 | id         | Tile id (local) |
 | type       | Tiled type      |
 | texture    | Tile texture    |
 | tileOffset | Tile offset     |

*/
public class SKTilesetData: SKTiledObject {

    weak public var tileset: SKTileset!                     // reference to parent tileset

    /// Unique id.
    public var uuid: String = UUID().uuidString
    /// Tile id (local).
    public var id: Int = 0
    /// Tiled type.
    public var type: String!
    /// Tile data name.
    public var name: String? {
        return properties["name"]
    }
    
    /// Tile texture.
    public var texture: SKTexture!
    /// Source image name (collections tileset)
    public var source: String! = nil
    public var probability: CGFloat = 1.0                   // carried over from Tiled application.
    public var properties: [String: String] = [:]
    public var ignoreProperties: Bool = false               // ignore custom properties
    
    /// Tile offset.
    public var tileOffset: CGPoint = CGPoint.zero

    /// Render scaling property.
    public var renderQuality: CGFloat = 8

    /// Animated frames.
    internal var currentTime: TimeInterval = 0
    internal var frameIndex: UInt8 = 0
    
    /// Supress tile animation.
    internal var blockAnimation: Bool = false
    internal var _frames: [TileAnimationFrame] = []
    public var frames:  [TileAnimationFrame] {
        return (blockAnimation == false) ? _frames : []
    }

    /// Indicates the tile is animated.
    public var isAnimated: Bool { return frames.isEmpty == false }
    
    /// Signifies that the tile data has changed.
    internal var dataChanged: Bool = false {
        didSet {
            guard (oldValue != dataChanged) else { return }
            // if something has changed, we need to regenerate the skaction
            if (dataChanged == true) {
                _animationAction = nil
            }
        }
    }
    
    /// Private animation action.
    private var _animationAction: SKAction?
    
    /// Returns an aniamtion action for the tile data.
    public var animationAction: SKAction? {
        if (_animationAction != nil) {
            return _animationAction
        }

        guard (isAnimated == true),
            let tileset = tileset else { return nil }
        
        var framesData: [(texture: SKTexture, duration: TimeInterval)] = []
        
        for frame in frames {
            guard let frameTexture = tileset.getTileData(localID: frame.id)?.texture else {
                Logger.default.log("cannot access texture data for id: \(frame.id)", level: .error, symbol: "SKTilesetData")
                return nil
            }
            
            frameTexture.filteringMode = .nearest
            framesData.append((texture: frameTexture, duration:  TimeInterval(frame.duration) / 1000))
        }
        // return the resulting action
        let newAction = SKAction.tileAnimation(framesData)
        
        NotificationCenter.default.post(
            name: Notification.Name.TileData.ActionAdded,
            object: self,
            userInfo: ["action": newAction]
        )
        
        _animationAction = newAction
        return newAction
    }

    /// Tile animation duration (in milliseconds).
    internal var animationTime: Int {
        guard (isAnimated == true) else { return 0 }
        let durations: [Int] = frames.map { $0.duration }
        return durations.reduce(0, { $0 + $1 })
    }

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
    /// Tile represents an obstacle.
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

     - parameter withID:      `Int` id for frame.
     - parameter interval:    `Int` frame interval (in milliseconds).
     - parameter tileTexture: `SKTexture?` frame texture.
     - returns: `TileAnimationFrame` animation frame container.
     */
    public func addFrame(withID: Int, interval: Int, tileTexture: SKTexture? = nil) -> TileAnimationFrame {
        var id = withID
        // if the tileset firstGID is already set, subtract it to get the internal (local) id
        if let tileset = tileset, tileset.firstGID > 0 {
            id = withID - tileset.firstGID
        }
        let frame = TileAnimationFrame(id: id, duration: interval, texture: tileTexture)
        
        NotificationCenter.default.post(
            name: Notification.Name.TileData.FrameAdded,
            object: self,
            userInfo: nil
        )
        
        _frames.append(frame)
        return frame
    }

    /**
     Returns an animation frame at the given index.

     - parameter index: `Int` frame index.
     - returns: `TileAnimationFrame?` animation frame container.
     */
    public func frameAt(index: Int) -> TileAnimationFrame? {
        guard _frames.indices.contains(index) else {
            return nil
        }
        return frames[index]
    }

    /**
     Force the animated frames to update textuers.
     */
    public func forceAnimatedFramesUpdate() {
        removeAnimation()
        _frames.forEach { frame in
            if let data = tileset.getTileData(localID: frame.id) {
                frame.texture = data.texture
            }
        }
        runAnimation()
    }

    /**
     Set the texture for the tile data.

     - parameter texture:   `SKTexture?` new texture.
     - returns: `SKTexture?` old texture (if it exists).
     */
    public func setTexture(_ newTexture: SKTexture?) -> SKTexture? {
        let previousTexture = self.texture
        newTexture?.filteringMode = .nearest
        self.texture = newTexture
        return previousTexture
    }

    /**
     Set the texture for an animated frame at the given index.

     - parameter texture:   `SKTexture?` new texture.
     - parameter forFrame:  `Int` frame index.
     - returns: `SKTexture?` old texture (if it exists).
     */
    public func setTexture(_ texture: SKTexture?, forFrame: Int) -> SKTexture? {
        if let frame = frameAt(index: forFrame) {
            let previousTexture = frame.texture
            texture?.filteringMode = .nearest
            frame.texture = texture
            return previousTexture
        }
        return nil
    }

    /**
     Set the duration for an animated frame at the given index.

     - parameter interval:  `Int` frame interval (in milliseconds).
     - parameter forFrame:  `Int` frame index.
     - returns: `Bool` frame duration was set correctly.
     */
    public func setDuration(interval: Int, forFrame: Int) -> Bool {
        if let frame = frameAt(index: forFrame) {
            frame.duration = interval
            return true
        }
        return false
    }

    /**
     Remove a tile animation frame at a given index.

     - parameter at: `Int` frame index.
     - returns: `TileAnimationFrame?` animation frame (if it exists).
     */
    public func removeFrame(at index: Int) -> TileAnimationFrame? {
        return _frames.remove(at: index)
    }

    /**
     Run tile animation.
     */
    public func runAnimation() {
        self.blockAnimation = false
    }

    /**
     Remove tile animation. Animation is not actually destroyed, but rather blocked.

     - parameter restore: `Bool` restore the initial texture.
     */
    public func removeAnimation(restore: Bool = false) {
        guard (isAnimated == true) else { return }
        self.blockAnimation = true
        if (restore == true) {
            self.texture = _frames.first!.texture
        }
    }

    // MARK: - Flip Flags

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
    public var hashValue: Int {
        return id.hashValue << 32 ^ globalID.hashValue
    }
}


extension TileAnimationFrame {
    override public var description: String { return "Frame: \(id): \(duration)" }
    override public var debugDescription: String { return "<\(description)>" }
}


extension SKTilesetData: CustomStringConvertible, CustomDebugStringConvertible {

    /// Tile data description.
    public var description: String {
        guard let tileset = tileset else { return "Tile ID: \(id) (no tileset)" }
        let typeString = (type != nil) ? ", type: \"\(type!)\"" : ""

        var sourceString = ""
        if (source != nil) {
            let sourceURL = URL(fileURLWithPath: source!, relativeTo: Bundle.main.bundleURL)
            sourceString = sourceURL.relativeString
        }
        let framesString = (isAnimated == true) ? ", \(frames.count) frames" : ""
        let idValue = localID  // globalID
        let dataString = (properties.isEmpty == false) ? "Tile ID: \(idValue)\(typeString)\(sourceString) @ \(tileset.tileSize.shortDescription)\(framesString), "
            : "Tile ID: \(idValue)\(typeString) @ \(tileset.tileSize.shortDescription)\(framesString)"

        return "\(dataString)\(propertiesString)"
    }

    public var debugDescription: String {
        return "<\(description)>"
    }
}
