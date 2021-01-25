//
//  SKTileLayer.swift
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
import GameplayKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


/// Array of tiles.
typealias TilesArray = Array2D<SKTile>


/// ## Overview
///
/// Subclass of `TiledLayerObject`, the **tile layer** is a container for an array of tiles (sprites). Tiles maintain a link to the map's tileset via their `SKTilesetData` property.
///
///
/// ### Properties
///
/// | Property                  | Description                                            |
/// |:--------------------------|:-------------------------------------------------------|
/// | `tileCount`               | Returns a count of valid tiles.                        |
///
///
/// ### Instance Methods
///
/// | Method                      | Description                                           |
/// |:--------------------------- |:----------------------------------------------------- |
/// | `getTiles()`                | Returns an array of current tiles                     |
/// | `getTiles(ofType:)`         | Returns tiles of the given type                       |
/// | `getTiles(globalID:)`       | Returns all tiles matching a global id                |
/// | `getTilesWithProperty(_:_)` | Returns tiles matching the given property & value     |
/// | `animatedTiles()`           | Returns all animated tiles                            |
/// | `getTileData(globalID:)`    | Returns all tiles matching a global id                |
/// | `tileAt(coord:)`            | Returns a tile at the given coordinate, if one exists |
///
/// ### Usage
///
/// Accessing a tile at a given coordinate:
///
/// ```swift
/// let tile = tileLayer.tileAt(2, 6)!
/// ```
///
/// Query tiles of a certain type:
///
/// ```swift
/// let floorTiles = tileLayer.getTiles(ofType: "Floor")
/// ```
public class SKTileLayer: TiledLayerObject {

    /// Container for the tile sprites.
    internal var tiles: Array2D<SKTile>

    /// Tile chunks.
    public var chunks: [SKTileLayerChunk] = []

    /// Returns a count of valid tiles.
    public var tileCount: Int {
        return self.getTiles().count
    }

    /// Tuple of layer render statistics.
    override internal var renderInfo: RenderInfo {
        var current = super.renderInfo
        current.tc = tileCount
        if let graph = graph {
            current.gn = graph.nodes?.count ?? nil
        }
        return current
    }

    override var layerRenderStatistics: LayerRenderStatistics {
        var current = super.layerRenderStatistics

        var tc: Int
        switch updateMode {
            case .full:
                tc = self.tileCount
            case .dynamic:
                tc = 0
            default:
                tc = 0
        }

        current.tiles = tc
        return current
    }

    /// Debug visualization options.
    @objc public override var debugDrawOptions: DebugDrawOptions {
        didSet {
            guard oldValue != debugDrawOptions else { return }
            debugNode.draw()
            let doShowTileBounds = debugDrawOptions.contains(.drawObjectFrames)
            getTiles().forEach { tile in
                if (doShowTileBounds == true) {
                    tile.drawNodeBounds(with: tile.frameColor)
                }
            }
        }
    }

    /// Tile highlight duration
    public override var highlightDuration: TimeInterval {
        didSet {
            getTiles().forEach { $0.highlightDuration = highlightDuration }
        }
    }

    /// Speed modifier applied to all actions executed by the layer and its descendants.
    public override var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.getTiles().forEach { $0.speed = speed }
        }
    }

    // MARK: Colors


    /// Layer tint color.
    public override var tintColor: SKColor? {
        didSet {
            guard let newColor = tintColor else {

                // reset color blending attributes
                colorBlendFactor = 0
                color = SKColor(hexString: "#ffffff00")
                blendMode = .alpha

                
                getTiles().forEach { tile in
                    tile.tintColor = nil
                }

                return
            }

            self.color = newColor
            self.blendMode = TiledGlobals.default.layerTintAttributes.blendMode
            self.colorBlendFactor = 1
            
            getTiles().forEach { tile in
                tile.tintColor = newColor
            }
        }
    }


    // MARK: - Initialization

    /// Initialize with layer name and parent `SKTilemap`.
    /// - Parameters:
    ///   - layerName: layer name.
    ///   - tilemap: parent map.
    public override init(layerName: String, tilemap: SKTilemap) {
        self.tiles = Array2D<SKTile>(columns: Int(tilemap.mapSize.width), rows: Int(tilemap.mapSize.height))
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .tile
    }

    /// Initialize with parent `SKTilemap` and layer attributes.
    ///   **Do not use this intializer directly.**
    ///
    /// - Parameters:
    ///   - tilemap: parent map.
    ///   - attributes: layer attributes.
    public init?(tilemap: SKTilemap, attributes: [String: String]) {
        // name, width and height are required
        let layerName = attributes["name"] ?? "null"
        self.tiles = Array2D<SKTile>(columns: Int(tilemap.mapSize.width), rows: Int(tilemap.mapSize.height))
        super.init(layerName: layerName, tilemap: tilemap, attributes: attributes)
        self.layerType = .tile
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeAllActions()
        removeAllChildren()
        removeFromParent()
        // clean up graph nodes
        if let graphNodes = graph?.nodes {
            graph?.remove(graphNodes)
        }
        graph = nil
        gidErrors = [:]
        chunks = []
    }


    // MARK: - Chunks


    /// Returns the number of chunks contained in this layer.
    public var chunkCount: Int {
        return chunks.count
    }

    /// Add a tile layer chunk to the stack.
    ///
    /// - Parameters:
    ///   - chunk: tile layer chunk.
    ///   - position: chunkk position.
    internal func addChunk(_ chunk: SKTileLayerChunk, at position: CGPoint) {
        if (chunks.contains(chunk) == false) {
            chunks.append(chunk)
            
            
            chunk.position = pointForCoordinate(coord: simd_int2(x: chunk.offset.xCoord, y: chunk.offset.yCoord))
            addChild(chunk)
            
            /*
            let label = SKLabelNode(text: chunk.xPath)
            
            label.fontSize = 8
            label.zPosition = chunk.zPosition + 100
            
            chunk.addChild(label)
            
            
            let randColor = TiledObjectColors.random
            chunk.boundsShape?.strokeColor = randColor
            label.position.x = chunk.sizeInPoints.halfWidth
            label.position.y = chunk.sizeInPoints.halfHeight
            label.color = randColor
            
            chunk.highlightNode(with: randColor, duration: 0.5)
             */
        }
    }

    /// Returns a chunk at the given point.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: chunk at the given coordinate.
    internal func chunkAt(_ x: Int32, _ y: Int32) -> SKTileLayerChunk? {
        guard (isInfinite == true) else {
            return nil
        }

        for chunk in chunks {
            let chunkcoord = simd_int2(x: x - chunk.offset.xCoord, y: y - chunk.offset.yCoord)
            if chunk.isValid(coord: chunkcoord) {
                return chunk
            }
        }
        return nil
    }

    /// Returns a chunk at the given point.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    /// - Returns: chunk at the given coordinate.
    internal func chunkAt(coord: simd_int2) -> SKTileLayerChunk? {
        return chunkAt(coord.x, coord.y)
    }

    // MARK: - Tiles

    /// Returns a tile at the given coordinate, if one exists.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: tile object, if it exists.
    public func tileAt(_ x: Int, _ y: Int) -> SKTile? {
        let cx = Int32(x)
        let cy = Int32(y)
        if (isInfinite == true) {
            for chunk in chunks {
                if let foundTile = chunk.tileAt(x, y) {
                    return foundTile
                }
            }
            return nil
        } else {
            if (isValid(cx,cy) == false) {
                return nil
            }
            return tiles[x,y]
        }
    }

    /// Returns a tile at the given coordinate, if one exists.
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: tile object, if it exists.
    public func tileAt(coord: simd_int2) -> SKTile? {
        return tileAt(Int(coord.x), Int(coord.y))
    }

    /// Returns a tile at the given screen position, if one exists.
    ///
    /// - Parameters:
    ///   - point: screen point.
    ///   - offset: pixel offset.
    /// - Returns: tile object, if it exists.
    public func tileAt(point:  CGPoint, offset: CGPoint = CGPoint.zero) -> SKTile? {
        let coord = coordinateForPoint(point: point)
        return tileAt(coord: coord)
    }

    /// Returns an array of all tiles in the layer.
    ///
    /// - Returns: array of tiles.
    public func getTiles() -> [SKTile] {
        return (chunks.isEmpty == true) ? tiles.compactMap { $0 } : chunks.reduce([], { (aggregate: [SKTile], chunk) -> [SKTile] in
            return aggregate + chunk.getTiles()
        })
    }

    /// Returns all of the tiles with a property of the given type.
    ///
    /// - Parameter ofType: tile type.
    /// - Returns: array of tiles.
    public func getTiles(ofType: String) -> [SKTile] {
        return getTiles().compactMap { $0 }.filter { $0.tileData.type == ofType }
    }

    /// Returns tiles with a property matching the given name.
    ///
    /// - Parameter named: property name.
    /// - Returns: array of tiles.
    public func getTilesWithProperty(_ named: String) -> [SKTile] {
        return getTiles().compactMap { $0 }.filter { $0.tileData.hasKey(named)}
    }

    /// Returns tiles matching the given global id.
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: array of tiles.
    public func getTiles(globalID: UInt32) -> [SKTile] {
        return getTiles().compactMap { $0 }.filter { $0.tileData.globalID == globalID }
    }

    /// Returns tiles with a property matching the given name & value.
    ///
    /// - Parameters:
    ///   - named: property name.
    ///   - value: property value.
    /// - Returns: array of tiles matching the given property name/value.
    public func getTilesWithProperty(_ named: String, _ value: Any) -> [SKTile] {
        var result: [SKTile] = []
        for tile in getTiles() {
            if let pairValue = tile.tileData.keyValuePair(key: named) {
                if pairValue.value == String(describing: value) {
                    result.append(tile)
                }
            }
        }
        return result
    }

    /// Returns an array of all the animated tiles in the layer.
    ///
    /// - Returns: array of animated tiles.
    public func animatedTiles() -> [SKTile] {
        return getTiles().filter { $0.tileData.isAnimated == true }
    }

    /// Return tile data matching a global id.
    ///
    /// - Parameter globalID: global tile id.
    /// - Returns: tile data (for valid id).
    public func getTileData(globalID: UInt32) -> SKTilesetData? {
        return tilemap.getTileData(globalID: globalID)
    }

    /// Returns tiles with a property of the given type.
    ///
    /// - Parameter named: type.
    /// - Returns: array of tiles.
    public func getTileData(withProperty named: String) -> [SKTilesetData] {
        var result: [SKTilesetData] = []
        for tile in getTiles() {
            if tile.tileData.hasKey(named) && !result.contains(tile.tileData) {
                result.append(tile.tileData)
            }
        }
        return result
    }

    // MARK: - Layer Data

    /// Add tile data array to the layer and render it.
    ///
    /// - Parameters:
    ///   - data: tile data.
    /// - Returns: data was successfully added.
    @discardableResult
    public func setLayerData(_ data: [UInt32]) -> Bool {
        if !(data.count == mapSize.pointCount) {
            log("invalid data size for layer '\(self.layerName)': \(data.count), expected: \(mapSize.pointCount)", level: .error)
            return false
        }

        var errorCount: Int = 0

        autoreleasepool {

            for index in data.indices {
                let globalId = data[index]

                // skip empty tiles
                if (globalId == 0) {
                    continue
                }

                let x: Int = index % Int(self.mapSize.width)
                let y: Int = index / Int(self.mapSize.width)

                let coordinate = simd_int2(Int32(x), Int32(y))


                // build the tile
                let tile = self.buildTileAt(coord: coordinate, globalID: globalId)

                if (tile == nil) {
                    errorCount += 1
                }
            }

            if (errorCount != 0) {
                log("layer '\(self.layerName)': \(errorCount) \(errorCount > 1 ? "errors" : "error") loading data.", level: .warning)
            }
        }


        return errorCount == 0
    }

    /// Clear the layer of tiles.
    public func clearLayer() {
        self.tiles.forEach { tile in
            tile?.removeFromParent()
        }
        self.tiles = Array2D<SKTile>(columns: Int(tilemap.mapSize.width), rows: Int(tilemap.mapSize.height))
    }

    /// Build an empty tile at the given coordinates. Returns an existing tile if one already exists, or nil if the coordinate is invalid.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate
    ///   - gid: tile id.
    ///   - tileType: optional tile class name.
    /// - Returns: newly created tile (if successful).
    public func addTileAt(coord: simd_int2,
                          globalID: UInt32? = nil,
                          tileType: String? = nil) -> SKTile? {

        guard isValid(coord: coord) else {
            return nil
        }

        // remove the current tile
        let existingTile = removeTileAt(coord: coord)
        let thisTileId: UInt32? = (globalID != nil) ? tilemap.delegate?.willAddTile?(globalID: globalID!, coord: coord, in: layerName) : tilemap.delegate?.willAddTile?(globalID: globalID!, in: layerName)

        let tileData: SKTilesetData? = (thisTileId != nil) ? getTileData(globalID: thisTileId!) : nil

        let Tile = (tilemap.delegate != nil) ? tilemap.delegate!.objectForTileType?(named: tileType) ?? SKTile.self : SKTile.self

        let tile = Tile.init()
        tile.tileSize = tileSize
        tile.isUserInteractionEnabled = true

        if let tileData = tileData {
            tile.tileData = tileData
            tile.texture = tileData.texture
            tile.size = tileData.texture.size()
            tile.tileSize = (tileData.tileset != nil) ? tileData.tileset!.tileSize : self.tileSize
        }

        // set the tile overlap amount
        tile.setTileOverlap(tilemap.tileOverlap)

        // set the layer property
        tile.layer = self
        tile.tintColor = tintColor
        self.tiles[Int(coord.x), Int(coord.y)] = tile


        // get the position in the layer (plus tileset offset)
        let tilePosition = pointForCoordinate(coord: coord, offsetX: offset.x, offsetY: offset.y)
        tile.position = tilePosition
        tile.currentCoordinate = coord

        // take attributes from existing tile
        if let currentTile = existingTile {
            tile.zPosition = currentTile.zPosition
            tile.zRotation = currentTile.zRotation
        }

        addChild(tile)

        // add to tile cache
        NotificationCenter.default.post(
            name: Notification.Name.Layer.TileAdded,
            object: tile,
            userInfo: ["layer": self, "coord": coord]
        )

        #if os(macOS)

        // add mouse handlers
        if (thisTileId != nil) {

            if let tilemapDelegate = tilemap.delegate {
                if let mouseOverCallback = tilemapDelegate.mouseOverTileHandler?(globalID: thisTileId!, ofType: tileData?.type) {
                    tile.onMouseOver = mouseOverCallback
                }

                if let mouseClickCallback = tilemapDelegate.tileClickedHandler?(globalID: thisTileId!, ofType: tileData?.type, button: 0) {
                    tile.onMouseClick = mouseClickCallback
                }
            }
        }
        #endif

        tilemap.delegate?.didAddTile?(tile, coord: coord, in: name)
        tile.draw()
        return tile
    }

    /// Build an empty tile at the given coordinates with a custom texture. Returns `nil` if the coordinate is invalid.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    ///   - texture: optional tile texture.
    ///   - tileType: optional tile type.
    /// - Returns: newly created tile.
    public func addTileAt(coord: simd_int2,
                          texture: SKTexture? = nil,
                          tileType: String? = nil) -> SKTile? {

        guard isValid(coord: coord) else {
            return nil
        }

        let Tile = (tilemap.delegate != nil) ? tilemap.delegate!.objectForTileType?(named: tileType) ?? SKTile.self : SKTile.self
        let tile = Tile.init()

        tile.isUserInteractionEnabled = true
        tile.tileSize = tileSize
        tile.texture = texture

        // set the tile overlap amount
        tile.setTileOverlap(tilemap.tileOverlap)

        // set the layer property
        tile.layer = self
        tile.tintColor = tintColor
        self.tiles[Int(coord.x), Int(coord.y)] = tile

        // get the position in the layer (plus tileset offset)
        let tilePosition = pointForCoordinate(coord: coord, offsetX: offset.x, offsetY: offset.y)
        tile.position = tilePosition
        tile.currentCoordinate = coord
        addChild(tile)

        tilemap.delegate?.didAddTile?(tile, coord: coord, in: name)
        tile.draw()
        return tile
    }

    /// Build an empty tile at the given coordinates. Returns an existing tile if one already exists, or nil if the coordinate is invalid.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    ///   - gid: tile global id.
    /// - Returns: newly created tile (if successful).
    public func addTileAt(_ x: Int, _ y: Int, globalID: UInt32? = nil) -> SKTile? {
        let coord = simd_int2(x: Int32(x), y: Int32(y))
        return addTileAt(coord: coord, globalID: globalID)
    }

    /// Build an empty tile at the given coordinates with a custom texture. Returns `nil` if the coordinate is invalid.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    ///   - texture: optional tile texture.
    /// - Returns: newly created tile (if successful).
    public func addTileAt(_ x: Int, _ y: Int, texture: SKTexture? = nil) -> SKTile? {
        let coord = simd_int2(x: Int32(x), y: Int32(y))
        return addTileAt(coord: coord, texture: texture)
    }

    /// Replace an existing tile at the given coordinates. Returns an existing tile if one already exists, or nil if the coordinate is invalid.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate
    ///   - gid: tile id.
    ///   - tileType: optional tile class name.
    /// - Returns: tuple of current tile (if it exists) & newly created tile (if successful).
    public func replaceTileAt(coord: simd_int2,
                          globalID: UInt32? = nil,
                          tileType: String? = nil) -> (old: SKTile?, new: SKTile?) {


        guard isValid(coord: coord) else {
            return (nil, nil)
        }


        // remove existing tile, if one exists
        let existingTile = removeTileAt(coord: coord)

        // resolve the gid and create a new tile
        let thisTileId: UInt32? = (globalID != nil) ? tilemap.delegate?.willAddTile?(globalID: globalID!, coord: coord, in: layerName) : tilemap.delegate?.willAddTile?(globalID: globalID!, in: layerName)
        let tileData: SKTilesetData? = (thisTileId != nil) ? getTileData(globalID: thisTileId!) : nil

        let Tile = (tilemap.delegate != nil) ? tilemap.delegate!.objectForTileType?(named: tileType) ?? SKTile.self : SKTile.self
        let tile = Tile.init()
        tile.isUserInteractionEnabled = true
        tile.tileSize = tileSize


        if let tileData = tileData {
            tile.tileData = tileData
            tile.texture = tileData.texture
            tile.size = tileData.texture.size()
            tile.tileSize = (tileData.tileset != nil) ? tileData.tileset!.tileSize : self.tileSize
        }


        return (existingTile, tile)
    }


    /// Clear all tiles.
    public func clearTiles() {
        getTiles().forEach { tile in
            tile.removeAnimation()
            tile.removeFromParent()
        }
        self.tiles = Array2D<SKTile>(columns: Int(tilemap.mapSize.width), rows: Int(tilemap.mapSize.height))
    }

    /// Remove the tile at a given coordinate.
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: removed tile, if one exists.
    public func removeTileAt(coord: simd_int2) -> SKTile? {
        let current = tileAt(coord: coord)
        if let current = current {
            current.removeFromParent()
            self.tiles[Int(coord.x), Int(coord.y)] = nil
        }
        return current
    }

    /// Remove the tile at the given x/y coordinates.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: removed tile, if one exists.
    public func removeTileAt(_ x: Int, _ y: Int) -> SKTile? {
        let coord = simd_int2(x: Int32(x), y: Int32(y))
        return removeTileAt(coord: coord)
    }

    /// Build a tile at the given coordinate with the given id. Returns nil if the id cannot be resolved.
    ///
    /// - Parameters:
    ///   - coord: x&y coordinate.
    ///   - id: tile id.
    /// - Returns: tile object.
    internal func buildTileAt(coord: simd_int2, globalID: UInt32) -> SKTile? {

        // get gid from delegate (if one exists)
        let thisTileId = (tilemap.delegate != nil) ? tilemap.delegate!.willAddTile?(globalID: globalID, coord: coord, in: layerName) ?? globalID : globalID

        // get tile attributes from the current id
        let tileId = TileID(wrappedValue: thisTileId)

        let wrappedID = tileId.wrappedValue

        if let tileData = tilemap.getTileData(globalID: wrappedID) {

            // get tile object from delegate
            let Tile = (tilemap.delegate != nil) ? tilemap.delegate!.objectForTileType?(named: tileData.type) ?? SKTile.self : SKTile.self

            if let tile = Tile.init(data: tileData) {

                tile.isUserInteractionEnabled = true
                tile.globalId = thisTileId

                // set the tile overlap amount
                tile.setTileOverlap(tilemap.tileOverlap)

                // set the layer property
                tile.layer = self
                //tile.tintColor = tintColor
                tile.highlightDuration = highlightDuration

                // get the position in the layer (plus tileset offset)
                let tilePosition = pointForCoordinate(coord: coord, offsetX: tileData.tileset.tileOffset.x, offsetY: tileData.tileset.tileOffset.y)

                tile.currentCoordinate = coord

                // add to the layer
                addChild(tile)

                tile.globalId = thisTileId

                // set orientation & position
                tile.orientTile()
                tile.position = tilePosition

                // add to the tiles array
                self.tiles[Int(coord.x), Int(coord.y)] = tile

                // set the tile zPosition to the current y-coordinate
                //tile.zPosition = coord.y

                if tile.texture == nil {
                    Logger.default.log("cannot find a texture for id: \(tileId)", level: .warning, symbol: self.logSymbol)
                }

                if let customProperties = tilemap.delegate?.attributesForNodes?(ofType: tileData.type, named: nil, globalIDs: [wrappedID]) {
                    for (attr, value) in customProperties {
                        tileData.properties[attr] = value
                    }
                }


                // add to tile cache
                NotificationCenter.default.post(
                    name: Notification.Name.Layer.TileAdded,
                    object: tile,
                    userInfo: ["layer": self, "coord": coord]
                )



                if let tilemapDelegate = tilemap.delegate {

                    #if os(macOS)
                    if let mouseOverCallback = tilemapDelegate.mouseOverTileHandler?(globalID: thisTileId, ofType: tileData.type) {
                        tile.onMouseOver = mouseOverCallback
                    }

                    if let mouseClickCallback = tilemapDelegate.tileClickedHandler?(globalID: thisTileId, ofType: tileData.type, button: 0) {
                        tile.onMouseClick = mouseClickCallback
                    }

                    #elseif os(iOS)
                    if let touchHandler = tilemapDelegate.tileTouchedHandler?(globalID: thisTileId, ofType: tileData.type, userData: nil) {
                        tile.onTouch = touchHandler
                    }
                    #endif
                }



                tilemap.delegate?.didAddTile?(tile, coord: coord, in: name)
                return tile

            } else {
                Logger.default.log("invalid tileset data (gid: \(globalID))", level: .warning, symbol: self.logSymbol)
            }

        } else {
            // tile data not found, log it.
            gidErrors[coord] = tileId.wrappedValue

        }
        return nil
    }

    /// Set a tile at the given coordinate.
    ///
    /// - Parameters:
    ///   - coord: coordinate.
    ///   - tile: tile instance.
    /// - Returns: tile instance.
    @discardableResult
    public func setTile(coord: simd_int2, tile: SKTile? = nil) -> SKTile? {
        self.tiles[Int(coord.x), Int(coord.y)] = tile
        return tile
    }

    /// Set a tile at the given coordinate.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    ///   - tile: tile instance.
    /// - Returns: tile instance.
    @discardableResult
    public func setTile(_ x: Int, _ y: Int, tile: SKTile? = nil) -> SKTile? {
        self.tiles[x, y] = tile
        return tile
    }

    // MARK: - Physics

    /// Setup tile collisions.
    public override func setupTileCollisions() {
        tiles.forEach { tile in
            //tile?.setupTileCollisions(offset: CGSize(width: -(tileWidthHalf), height: -(tileHeightHalf)))
            tile?.setupTileCollisions(offset: CGSize.zero)
        }
    }

    // MARK: - Overlap

    /// Set the tile overlap. Valid values are (0 - 1.0).
    ///
    /// - Parameter overlap: tile overlap value.
    public func setTileOverlap(_ overlap: CGFloat) {
        for tile in tiles where tile != nil {
            tile!.setTileOverlap(overlap)
        }
    }

    // MARK: - Callbacks

    /// Called when the layer is finished rendering.
    ///
    /// - Parameter duration: fade-in duration.
    public override func didFinishRendering(duration: TimeInterval = 0) {
        super.didFinishRendering(duration: duration)

        if (isStatic == true) {
            shouldRasterize = true
            //rasterizeStaticLayer()
        } else {
            shouldRasterize = false
        }
    }

    // MARK: - Shaders

    /// Set a shader for tiles in this layer.
    /// - Parameters:
    ///   - sktiles: tiles to apply shader to.
    ///   - named: shader file name.
    ///   - uniforms: array of shader uniforms.
    public func setShader(for sktiles: [SKTile], named: String, uniforms: [SKUniform] = []) {
        let shader = SKShader(fileNamed: named)
        shader.uniforms = uniforms
        for tile in sktiles {
            tile.shader = shader
        }
    }

    // MARK: - Debugging

    public override func debugLayer() {
        super.debugLayer()
        for tile in getTiles() {
            log(tile.debugDescription, level: .debug)
        }
    }

        /// Rasterize a static layer into an image.
    public override func rasterizeStaticLayer() {

        #if os(macOS)
        let staticRectSize = CGSize(width: sizeInPoints.width, height: sizeInPoints.height)
        let staticRectOrigin = CGPoint(x: 0, y: -sizeInPoints.height)
        var staticRect = CGRect(origin: staticRectOrigin, size: staticRectSize)


        let staticImage = NSImage(size: sizeInPoints)
        staticImage.lockFocus()
        let nsContext = NSGraphicsContext.current!
        nsContext.imageInterpolation = .medium

        print("⭑ rasterizing static layer '\(layerName)' -> \(sizeInPoints.shortDescription)")
        #endif


        autoreleasepool {

            for (index, tile) in tiles.enumerated() {

                guard let tile = tile else {
                    continue
                }

                let x: Int = index % Int(self.mapSize.width)
                let y: Int = index / Int(self.mapSize.width)

                //let coordinate = simd_int2(Int32(x), Int32(y))


                if let tileTexture = tile.texture {
                    let positionInLayer = pointForCoordinate(x, y).invertedY

                    let rectToDrawIn = CGRect(x: positionInLayer.x, y: positionInLayer.y, width: self.tileSize.width, height: -self.tileSize.height)
                    let tileimage = tileTexture.cgImage()

                    #if os(macOS)
                    let nsimage = NSImage(cgImage: tileimage, size: self.tileSize)
                    nsimage.draw(in: rectToDrawIn)
                    #endif
                }
            }
        }

        #if os(macOS)
        staticImage.unlockFocus()
        let imageRef = staticImage.cgImage(forProposedRect: &staticRect, context: nil, hints: nil)
        nsContext.flushGraphics()


        if let staticImageRef = imageRef {

            let staticImageTexture = SKTexture(cgImage: staticImageRef)
            staticTexture = staticImageTexture

            // save the image
            let exportedFileName = "\(layerName)-exported"
            let exportPath = "/Users/michael/exported/\(exportedFileName).png"
            let wasWritten = writeCGImage(staticImageRef, to: exportPath.url)
            if (wasWritten == true) {
                Logger.default.log("writing image to: '\(exportPath)'", level: .info, symbol: className)
            } else {
                Logger.default.log("failed to write image", level: .error, symbol: className)
            }
        }

        #endif

    }

    // MARK: - Updating


    /// Run animation actions on all of the tiles in this layer.
    public override func runAnimationAsActions() {
        super.runAnimationAsActions()
        let animatedTiles = getTiles().filter { tile in
            tile.tileData.isAnimated == true
        }
        animatedTiles.forEach { $0.runAnimationAsActions() }
    }

    /// Remove tile animations.
    ///
    /// - Parameter restore: restore tile/object texture.
    public override func removeAnimationActions(restore: Bool = false) {
        super.removeAnimationActions(restore: restore)
        let animatedTiles = getTiles().filter { tile in
            tile.tileData.isAnimated == true
        }
        animatedTiles.forEach { $0.removeAnimationActions(restore: restore) }
    }

    /// Update the tile layer before each frame is rendered.
    ///
    /// - Parameter currentTime: update interval.
    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard (self.updateMode != TileUpdateMode.actions) else { return }
    }


    // MARK: - Reflection
    
    
    /// Returns a custom mirror for this layer.
    public override var customMirror: Mirror {
        var attributes: [(label: String?, value: Any)] = [
            (label: "name", value: layerName),
            (label: "uuid", uuid),
            (label: "xPath", value: xPath),
            (label: "path", value: path),
            (label: "size", value: mapSize),
            (label: "tileSize", value: tileSize)
        ]
        
        if (isInfinite == true) {
            attributes.append(("chunks", chunks))
        } else {
            attributes.append(("data", tiles))
        }
        
        return Mirror(self, children: attributes, ancestorRepresentation: .suppressed)
    }

}


// MARK: - Extensions



extension SKTileLayer {

    /// Dump the contents of the tile data array to the console.
    ///
    /// - Parameter spacing: spacing length.
    public func dumpLayerData(spacing: Int = 3) {
        var rowdata: [String] = []
        var tcount = 0
        for r in 0..<tiles.rows {
            var rowResult: String = ""

            for c in 0..<tiles.columns {
                let comma: String = (c < tiles.columns - 1) ? ", " : ""

                if let tile = tiles[c, r] {
                    tcount += 1
                    // was `id`
                    let gid = tile.tileData.globalID
                    let gidString = "\(gid)".padRight(toLength: spacing, withPad: " ")
                    rowResult += "\(gidString)\(comma)"

                } else {
                    let nilData = String(repeating: "-", count: spacing)
                    rowResult += "\(nilData)\(comma)"
                }
            }
            rowdata.append(rowResult)
        }


        var layerHeaderString = "Tile Layer: '\(layerName)', \(tcount) tiles:"
        layerHeaderString += "\n" + String(repeating: "-", count: layerHeaderString.count)
        print("\n" + layerHeaderString)

        for (_, data) in rowdata.enumerated() {
            print(" \(data)")
        }
    }
}


/// :nodoc:
extension SKTileLayer {
    
    /// Returns the internal **Tiled** node type.
    @objc public var tiledNodeName: String {
        return "layer"
    }
    
    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return "Tile Layer"
    }
    
    /// Returns the internal **Tiled** node type icon.
    @objc public override var tiledIconName: String {
        return "tilelayer-icon"
    }
    
    /// A description of the node.
    @objc public override var tiledListDescription: String {
        let nameString = "'\(layerName)'"
        return "Tile Layer \(nameString) (\(tileCount) tiles)"
    }
    
    /// A description of the node.
    @objc public override var tiledDescription: String {
        return "Layer container for tiles."
    }
}



// MARK: - Deprecations


@available(*, deprecated, renamed: "TiledLayerObject")
public typealias SKTiledLayerObject = TiledLayerObject


extension TiledLayerObject {

    /// Initialize SpriteKit animation actions for the layer.
    @available(*, deprecated, renamed: "runAnimationAsActions")
    public func runAnimationAsAction() {
        self.runAnimationAsActions()
    }
}



extension SKTileLayer {

    /// Returns an array of valid tiles.
    ///
    /// - Returns: array of current tiles.
    @available(*, deprecated, message: "use `getTiles()` instead")
    public func validTiles() -> [SKTile] {
        return self.getTiles()
    }

    /// Returns a tile at the given coordinate, if one exists.
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: tile object, if it exists.
    @available(*, deprecated, renamed: "tileAt(coord:)")
    public func tileAt(coord: CGPoint) -> SKTile? {
        return tileAt(Int(coord.x), Int(coord.y))
    }

    /// Returns tiles matching the given global id.
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: array of tiles.
    @available(*, deprecated, renamed: "getTiles(globalID:)")
    public func getTiles(globalID: Int) -> [SKTile] {
        return getTiles().compactMap { $0 }.filter { $0.tileData.globalID == globalID }
    }

    /// Build an empty tile at the given coordinates. Returns an existing tile if one already exists, or nil if the coordinate is invalid.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate
    ///   - gid: tile id.
    ///   - tileType: optional tile class name.
    /// - Returns: newly created tile (if successful).
    @available(*, deprecated, renamed: "addTileAt(coord:globalID:tileType:)")
    public func addTileAt(coord: CGPoint, gid: Int? = nil, tileType: String? = nil) -> SKTile? {
        let gidVal: UInt32? = (gid != nil) ? UInt32(gid!) : nil
        return addTileAt(coord: coord.toVec2, globalID: gidVal, tileType: tileType)
    }

    /// Build an empty tile at the given coordinates with a custom texture. Returns nil is the coordinate is invalid.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    ///   - texture: optional tile texture.
    ///   - tileType: optional tile type.
    /// - Returns: newly created tile.
    @available(*, deprecated, renamed: "addTileAt(coord:texture:tileType:)")
    public func addTileAt(coord: CGPoint, texture: SKTexture? = nil, tileType: String? = nil) -> SKTile? {
        return addTileAt(coord: coord.toVec2, texture: texture, tileType: tileType)
    }

    /// Build an empty tile at the given coordinates. Returns an existing tile if one already exists, or nil if the coordinate is invalid.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    ///   - gid: tile global id.
    /// - Returns: newly created tile (if successful).
    @available(*, deprecated, renamed: "addTileAt(x:y:gid:)")
    public func addTileAt(_ x: Int, _ y: Int, gid: Int? = nil) -> SKTile? {
        let coord = CGPoint(x: CGFloat(x), y: CGFloat(y))
        return addTileAt(coord: coord, gid: gid)
    }

    /// Remove the tile at a given coordinate.
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: removed tile, if one exists.
    @available(*, deprecated, renamed: "removeTileAt(coord:)")
    public func removeTileAt(coord: CGPoint) -> SKTile? {
        return removeTileAt(coord: coord.toVec2)
    }

    /// Set a tile at the given coordinate.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    ///   - tile: tile instance.
    /// - Returns: tile instance.
    @available(*, deprecated, renamed: "setTile(coord:tile:)")
    public func setTile(at coord: CGPoint, tile: SKTile? = nil) -> SKTile? {
        self.tiles[Int(coord.x), Int(coord.y)] = tile
        return tile
    }

    /// Add tile data array to the layer and render it.
    ///
    /// - Parameters:
    ///   - data: tile data.
    ///   - debug: debug mode.
    /// - Returns: data was successfully added.
    @available(*, deprecated, renamed: "setLayerData(_:)")
    @discardableResult public func setLayerData(_ data: [UInt32], debug: Bool = false) -> Bool {
        self.setLayerData(data)
    }
}
