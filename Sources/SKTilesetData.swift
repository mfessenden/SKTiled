//
//  SKTilesetData.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SpriteKit


/// ## Overview
///
/// The `SKTilesetData` structure stores data for a single tileset tile, referencing the tile texture or animation frames (for animated tiles).
///
/// This class optionally includes navigation properties for tile accessability, and graph node weight.
///
/// ### Properties
///
/// | Property   | Description     |
/// |------------|-----------------|
/// | id         | Tile id (local) |
/// | type       | Tiled type      |
/// | texture    | Tile texture    |
/// | tileOffset | Tile offset     |
///
public class SKTilesetData: CustomReflectable, TiledAttributedType {

    /// Reference to parent tileset.
    public weak var tileset: SKTileset!

    /// Unique id.
    public var uuid: String = UUID().uuidString

    /// Local tile id.
    public var id: UInt32 = 0

    /// Tiled type.
    public var type: String!

    /// Tile data name.
    public var name: String? {
        return properties["name"]
    }

    /// Tile texture.
    public var texture: SKTexture!

    /// Source image name (collections tileset)
    public var source: String!

    /// Source image size (collections tileset)
    public var sourceSize: CGSize?

    /// Probability value. This is parsed from the **Tiled** tileset data, though not used anywhere.
    public var probability: CGFloat = 1.0

    /// Custom node properties.
    public var properties: [String: String] = [:]

    /// Ignore custom properties.
    public var ignoreProperties: Bool = false

    /// Getter for the size of this tile. (collections tile size may be different than that of the tileset).
    public var tileSize: CGSize {
        return sourceSize ?? tileset.tileSize
    }

    /// Tile offset.
    public var tileOffset: CGPoint = CGPoint.zero

    /// Render scaling property.
    public var renderQuality: CGFloat = 8

    // MARK: - Animation

    /// Current frame time.
    internal var currentTime: TimeInterval = 0

    /// Current frame index.
    internal var frameIndex: UInt8 = 0

    /// Supress tile animation.
    internal var blockAnimation: Bool = false

    /// Animation frames.
    internal var _frames: [TileAnimationFrame] = []

    /// If animation is enabled, returns the current frames data.
    ///
    /// - Returns: array of animation frames.
    public var frames: [TileAnimationFrame] {
        return (blockAnimation == false) ? _frames : []
    }

    /// Indicates the tile is animated.
    public var isAnimated: Bool {
        return frames.isEmpty == false
    }

    /// Signifies that the tile data has been modified in some way.
    internal var dataChanged: Bool = false {
        didSet {
            guard (oldValue != dataChanged) else { return }
            // if something has changed, we need to regenerate the SKAction
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
            let tileset = tileset else {
            return nil
        }

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
        guard (isAnimated == true) else {
            return 0
        }
        let durations: [Int] = frames.map { $0.duration }
        return durations.reduce(0, { $0 + $1 })
    }

    // MARK: Pathfinding Attributes

    /// Tile is walkable.
    public var walkable: Bool = false

    /// Tile represents an obstacle.
    public var obstacle: Bool = false

    /// Pathfinding weight.
    public var weight: CGFloat = 1

    /// Collision objects (not yet implemented).
    internal var collisions: [TileCollisionShape] = []

    /// Global id for this tile.
    public var globalID: UInt32 {
        let firstGID = (tileset != nil) ? tileset.firstGID : 0
        return id + firstGID
    }

    // MARK: - Initialization

    /// Initialize an empty data structure.
    public init() {}

    /// Initialize the data with a tileset, id.
    ///
    /// - Parameters:
    ///   - id: unique tile id.
    ///   - tileSet: tileset reference.
    public init(id: UInt32, withTileset tset: SKTileset) {

        self.id = id
        self.tileset = tset
        self.tileOffset = tset.tileOffset
        self.ignoreProperties = tset.ignoreProperties
    }

    /// Initialize the data with a tileset, id & texture.
    ///
    /// - Parameters:
    ///   - id: unique tile id.
    ///   - texture: tile texture.
    ///   - tileSet: tileset reference.
    public init(id: UInt32, texture: SKTexture, tileSet: SKTileset) {

        self.id = id
        self.texture = texture
        self.texture.filteringMode = .nearest
        self.tileset = tileSet

        self.tileOffset = tileSet.tileOffset
        self.ignoreProperties = tileSet.ignoreProperties
    }

    deinit {
        texture = nil
        _frames = []
    }

    // MARK: - Animation


    /// Add tile animation to the data.
    ///
    /// - Parameters:
    ///   - withID: id for frame.
    ///   - interval: frame interval (in milliseconds).
    ///   - tileTexture: frame texture.
    /// - Returns: animation frame container.
    public func addFrame(withID: UInt32,
                         interval: Int,
                         texture: SKTexture? = nil) -> TileAnimationFrame {

        var id = withID
        // if the tileset firstGID is already set, subtract it to get the internal (local) id
        if let tileset = tileset, tileset.firstGID > 0 {
            id = withID - tileset.firstGID
        }

        let frame = TileAnimationFrame(id: id, duration: interval, texture: texture)

        NotificationCenter.default.post(
            name: Notification.Name.TileData.FrameAdded,
            object: self,
            userInfo: nil
        )

        _frames.append(frame)
        return frame
    }

    /// Returns an animation frame at the given index.
    ///
    /// - Parameter index: frame index.
    /// - Returns: animation frame container.
    public func frameAt(index: Int) -> TileAnimationFrame? {
        guard _frames.indices.contains(index) else {
            return nil
        }
        return frames[index]
    }

    /// Force animated frames to update textures.
    public func forceAnimatedFramesUpdate() {
        removeAnimation()
        _frames.forEach { frame in
            if let data = tileset.getTileData(localID: frame.id) {
                frame.texture = data.texture
            }
        }
        runAnimation()
    }

    /// Set the texture for the tile data.
    ///
    /// - Parameter newTexture: new texture.
    /// - Returns: old texture (if it exists).
    public func setTexture(_ newTexture: SKTexture?) -> SKTexture? {
        let previousTexture = self.texture
        newTexture?.filteringMode = .nearest
        self.texture = newTexture

        // send notification
        let userInfo: [String: Any] = (previousTexture != nil) ? ["old": previousTexture!] : [:]

        // update observers
        NotificationCenter.default.post(
            name: Notification.Name.TileData.TextureChanged,
            object: self,
            userInfo: userInfo
        )

        return previousTexture
    }

    /// Set the texture for an animated frame at the given index.
    ///
    /// - Parameters:
    ///   - texture: new texture.
    ///   - forFrame: frame index.
    /// - Returns: old texture (if it exists).
    public func setTexture(_ texture: SKTexture?, forFrame: Int) -> SKTexture? {
        if let frame = frameAt(index: forFrame) {
            let previousTexture = frame.texture
            texture?.filteringMode = .nearest
            frame.texture = texture
            return previousTexture
        }
        return nil
    }

    /// Set the duration for an animated frame at the given index.
    ///
    /// - Parameters:
    ///   - interval: frame interval (in milliseconds).
    ///   - forFrame: frame index.
    /// - Returns: frame duration was set correctly.
    public func setDuration(interval: Int, forFrame: Int) -> Bool {
        if let frame = frameAt(index: forFrame) {
            frame.duration = interval
            return true
        }
        return false
    }

    /// Remove a tile animation frame at a given index.
    ///
    /// - Parameter index: frame index.
    /// - Returns: animation frame (if it exists).
    public func removeFrame(at index: Int) -> TileAnimationFrame? {
        return _frames.remove(at: index)
    }

    /// Run tile animation.
    public func runAnimation() {
        self.blockAnimation = false
    }

    /// Remove tile animation. Animation is not actually destroyed, but rather blocked.
    ///
    /// - Parameter restore: restore the initial texture.
    public func removeAnimation(restore: Bool = false) {
        guard (isAnimated == true) else {
            return
        }
        self.blockAnimation = true
        if (restore == true) {
            self.texture = _frames.first!.texture
        }
    }
    
    // MARK: - Reflection
    
    
    /// Returns a custom mirror for this object.
    public var customMirror: Mirror {
        
        let attributes: [(label: String?, value: Any)] = [
            (label: "id", value: id),
            (label: "gid", value: globalID),
            (label: "type", value: type as Any),
            (label: "frames", value: frames),
            (label: "source", value: source as Any),
            (label: "probability", value: probability),
            (label: "tile size", value:  tileSize),
            (label: "tileoffset", value: tileOffset),
            (label: "properties", value: mirrorChildren()),
            (label: "tileset", value: tileset.tilesetDataStruct())
        ]
        
        return Mirror(self, children: attributes, displayStyle: .optional)   // was .class
    }
}



public func == (lhs: SKTilesetData, rhs: SKTilesetData) -> Bool {
    return (lhs.hashValue == rhs.hashValue)
}


// MARK: - Extensions

/// :nodoc:
extension SKTilesetData: NSCopying {

    /// Creates a new copy of the tile data. This data is not stored in the tileset tile data set, though it is still accessible.
    ///
    /// - Parameter zone: memory handler.
    /// - Returns: tile data copy.
    public func copy(with zone: NSZone? = nil) -> Any {
        let cloned = SKTilesetData()

        cloned.tileset = tileset
        cloned.id = id
        cloned.type = type
        cloned.texture = texture
        cloned.source = source
        cloned.sourceSize = sourceSize
        cloned.probability = probability

        cloned.properties = properties
        cloned.ignoreProperties = ignoreProperties
        cloned.tileOffset = tileOffset
        cloned.renderQuality = renderQuality
        cloned.currentTime = currentTime
        cloned.frameIndex = frameIndex
        cloned.blockAnimation = blockAnimation
        cloned._frames = _frames
        cloned._animationAction = _animationAction

        cloned.walkable = walkable
        cloned.weight = weight
        cloned.collisions = collisions
        return cloned
    }
}


/// :nodoc: Hash value for the tile data.
extension SKTilesetData: Hashable {

    public func hash(into hasher: inout Hasher) {
        // return id.hashValue << 32 ^ globalID.hashValue
        hasher.combine(id)
        hasher.combine(globalID)
    }
}


/// :nodoc:
extension SKTilesetData: CustomStringConvertible, CustomDebugStringConvertible {

    /// String representation of the tile data.
    public var description: String {
        let className = String(describing: Swift.type(of: self))
        guard let tileset = tileset else {
            return "\(className): tile id: \(id) (no tileset)"
        }

        // add the tile data type, if it exists...
        let typeString = (type != nil) ? ", type: '\(type!)'" : ""
        
        // for collections data, add the image source path
        var sourceString = ""
        if (source != nil) {
            let sourceURL = URL(fileURLWithPath: source!, relativeTo: Bundle.main.bundleURL)
            sourceString = sourceURL.relativeString
        }

        // animated fromes description
        let framesString = (isAnimated == true) ? ", \(frames.count) frames" : ""
        let frameOutput = (properties.isEmpty == false) ? "tile id: \(id)\(typeString)\(sourceString) @ \(tileset.tileSize.shortDescription)\(framesString), "
            : "tile id: \(id)\(typeString) @ \(tileset.tileSize.shortDescription)\(framesString)"
        
        let collisionOutput = (collisions.count > 0) ? ", collisions: \(collisions.count)" : ""
        return "\(className): \(frameOutput)\(propertiesString)\(collisionOutput)"
    }

    public var debugDescription: String {
        return "<\(description)>"
    }
}



// MARK: - Deprecations


extension SKTilesetData {

    /// Local id for this tile data.
    @available(*, deprecated, renamed: "id")
    public var localID: UInt32 {
        return id
    }

    /// Add tile an animation frame to the data.
    ///
    /// - Parameters:
    ///   - withID: id for frame.
    ///   - interval: frame interval (in milliseconds).
    ///   - tileTexture: frame texture.
    /// - Returns: animation frame container.
    @available(*, deprecated, renamed: "addFrame(withID:interval:texture:)")
    public func addFrame(withID: Int,
                         interval: Int,
                         tileTexture: SKTexture? = nil) -> TileAnimationFrame {

        return addFrame(withID: UInt32(withID), interval: interval, texture: tileTexture)
    }

    /// Initialize the data with a tileset, id & texture.
    ///
    /// - Parameters:
    ///   - id: unique tile id.
    ///   - texture: tile texture.
    ///   - tileSet: tileset reference.
    @available(*, deprecated, renamed: "init(id:texture:tileSet:)")
    public convenience init(id: Int, texture: SKTexture, tileSet: SKTileset) {
        self.init(id: UInt32(id), texture: texture, tileSet: tileSet)
    }

    /// Initialize the data with a tileset, id.
    ///
    /// - Parameters:
    ///   - id: unique tile id.
    ///   - tileSet: tileset reference.
    @available(*, deprecated, renamed: "init(id:withTileset:)")
    public convenience init(id: Int, withTileset tileSet: SKTileset) {
        self.init(id: UInt32(id), withTileset: tileSet)
    }

    /// Tile is flipped horizontally.
    @available(*, unavailable, message: "Tile flip flags are stored in the individual tile instances.")
    public var flipHoriz: Bool {
        get {
            return false
        } set {}
    }

    /// Tile is flipped vertically.
    @available(*, unavailable, message: "Tile flip flags are stored in the individual tile instances.")
    public var flipVert: Bool {
        get {
            return false
        } set {}
    }

    /// Tile is flipped diagonally.
    @available(*, unavailable, message: "Tile flip flags are stored in the individual tile instances.")
    public var flipDiag: Bool {
        get {
            return false
        } set {}
    }
}
