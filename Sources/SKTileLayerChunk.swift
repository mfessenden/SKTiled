//
//  SKTileLayerChunk.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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


/// :nodoc:
/// The `SKTileLayerChunk` object is a container for tiles in an infinite tile map. It represents a sub-layer of a `SKTileLayer` layer type in infinite maps.
public class SKTileLayerChunk: TiledLayerObject {

    /// Container for the tile sprites.
    internal var tiles: Array2D<SKTile>

    /// Parent layer.
    public unowned var layer: SKTileLayer

    /// The size of the chunk (in tiles).
    internal var chunkSize: CGSize = CGSize.zero
    
    /// Represents the offset (in tiles) from the parent layer.
    internal var chunkOffset: CGPoint = CGPoint.zero

    /// Returns a count of valid tiles.
    public var tileCount: Int {
        return self.getTiles().count
    }

    /// Returns an array of current tiles.
    public func getTiles() -> [SKTile] {
        return tiles.compactMap { $0 }
    }

    /// Instantiate with a layer & attributes dictionary.
    ///
    /// - Parameters:
    ///   - layer: parent layer.
    ///   - attributes: optional custom attributes.
    public init?(layer: SKTileLayer, attributes: [String: String]) {
        // name, width and height are required
        self.layer = layer
        
        // chunk mapSize should be 128x128
        
        // chunk position
        guard let xpos = attributes["x"] else { return nil }
        guard let ypos = attributes["y"] else { return nil }
        
        // chunk size shoud be 16x16
        guard let width = attributes["width"] else { return nil }
        guard let height = attributes["height"] else { return nil }
        
        
        assert(Int(width) != nil, "cannot parse chunk width: '\(width)'")
        assert(Int(height) != nil, "cannot parse chunk height: '\(height)'")
        
        
        /// chunk size becomes 16x16
        self.chunkSize = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))
        self.chunkOffset = CGPoint(x: CGFloat(Int(xpos)!), y: CGFloat(Int(ypos)!))
        self.tiles = Array2D<SKTile>(columns: Int(chunkSize.width), rows: Int(chunkSize.height))
        
        // TODO: need a different super
        /// `mapSize` gets set here, but will be wrong
        super.init(tilemap: layer.tilemap)
        self.mapSize = self.chunkSize
        self.layerType = .tile
    
        
        self.offset = CGPoint(x: Int(xpos)!, y: Int(ypos)!)
        self.navigationKey = "\(layer.layerName)/Chunk"
        self.shouldEnableEffects = false
    }

    /// Instantiate the node with a decoder instance.
    ///
    /// - Parameter aDecoder: decoder.
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeAllActions()
        removeAllChildren()
        removeFromParent()
    }


    // MARK: - Layer Data


    /// Add tile data array to the layer and render it.
    ///
    /// - Parameters:
    ///   - data: tile data array.
    /// - Returns: data was sucessfully added.
    @discardableResult
    public func setLayerData(_ data: [UInt32]) -> Bool {
        if !(data.count == self.tiles.count) {
            log("invalid data size for chunk '\(self.layerName)': \(data.count), expected: \(mapSize.pointCount)", level: .error)
            return false
        }

        var errorCount: Int = 0

        autoreleasepool {
            for index in data.indices {
                let gid = data[index]

                // skip empty tiles
                if (gid == 0) {
                    continue
                }

                let x: Int = index % Int(self.chunkSize.width)
                let y: Int = index / Int(self.chunkSize.width)

                let coord = simd_int2(x: Int32(x), y: Int32(y))

                // build the tile
                let tile = self.buildTileAt(coord: coord, globalID: gid)

                if (tile == nil) {
                    errorCount += 1
                }
            }

            if (errorCount != 0) {
                log("layer chunk '\(self.layerName)': \(errorCount) \(errorCount > 1 ? "errors" : "error") loading data.", level: .warning)
            }
        }
        return errorCount == 0
    }

    /// Build a tile at the given coordinate with the given id. Returns nil if the id cannot be resolved.
    ///
    /// - Parameters:
    ///   - coord: x&y coordinate.
    ///   - id: tile id.
    /// - Returns: tile object (if created).
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

                // set the tile overlap amount
                tile.isUserInteractionEnabled = true
                tile.setTileOverlap(tilemap.tileOverlap)

                // set the layer property
                tile.layer = self.layer
                tile.tintColor = self.layer.tintColor
                tile.highlightDuration = highlightDuration

                // get the position in the layer (plus tileset offset)
                let tilePosition = pointForCoordinate(coord: coord, offsetX: tileData.tileset.tileOffset.x, offsetY: tileData.tileset.tileOffset.y)

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
                    Logger.default.log("cannot find a texture for id: \(tileId.wrappedValue)", level: .warning, symbol: self.logSymbol)
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
                    userInfo: ["chunk": self, "coord": coord]
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


                tilemap.delegate?.didAddTile?(tile, coord: coord, in: layer.name)
                return tile

            } else {
                Logger.default.log("invalid tileset data (id: \(tileId.wrappedValue))", level: .warning, symbol: self.logSymbol)
            }

        } else {
            // tile data not found, log it.
            gidErrors[coord] = tileId.wrappedValue
        }
        return nil
    }

    // MARK: - Coordinates


    /// Converts a coordinate in map/layer space to chunk coordinate space.
    ///
    /// - Parameter coord: parent layer coordinate.
    /// - Returns: coordinate in chunk space.
    public func coordinateForLayer(coord: simd_int2) -> simd_int2 {
        return simd_int2(Int32(coord.x - offset.xCoord), Int32(coord.y - offset.yCoord))
    }

    /// Returns true if the coordinate is valid.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: coordinate is valid.
    public override func isValid(_ x: Int32, _ y: Int32) -> Bool {
        return x >= 0 && x < Int(chunkSize.width) && y >= 0 && y < Int(chunkSize.height)
    }

    /// Returns a tile at the given **map** coordinate, if one exists.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: tile object, if it exists.
    public func tileAt(_ x: Int32, _ y: Int32) -> SKTile? {
        let xValue = x - offset.xCoord
        let yValue = y - offset.yCoord

        if (isValid(coord: simd_int2(xValue, yValue)) == false) {
            return nil
        }

        return tiles[xValue, yValue]
    }
    
    
    // MARK: - Reflection
    
    
    /// Returns a custom mirror for this layer.
    public override var customMirror: Mirror {
        
        var attributes: [(label: String?, value: Any)] = [
            (label: "path", value: path),
            (label: "uuid", uuid),
            (label: "xPath", value: xPath),
            (label: "size", value: mapSize),
            (label: "tile size", value: tileSize),
            (label: "chunkSize", value: chunkSize),
            (label: "chunkOffset", value: chunkOffset),
            (label: "position", value: position),
            (label: "offset", value: offset),
            (label: "isFocused", value: isFocused),
            (label: "data", value: tiles),
            (label: "properties", value: mirrorChildren())
        ]
        
        
        /// internal debugging attrs
        attributes.append(("tiled element name", tiledElementName))
        attributes.append(("tiled node nice name", tiledNodeNiceName))
        attributes.append(("tiled list description", #"\#(tiledListDescription)"#))
        attributes.append(("tiled menu item description", #"\#(tiledMenuItemDescription)"#))
        attributes.append(("tiled display description", #"\#(tiledDisplayItemDescription)"#))
        attributes.append(("tiled display description", #"\#(tiledDisplayItemDescription)"#))
        attributes.append(("tiled help description", tiledHelpDescription))
        
        attributes.append(("tiled description", description))
        attributes.append(("tiled debug description", debugDescription))
        
        #if SKTILED_DEMO
        attributes.append(contentsOf: attrsMirror())
        #endif
        return Mirror(self, children: attributes, ancestorRepresentation: .suppressed)
    }
}


// MARK: - Extensions



/// :nodoc:
extension SKTileLayerChunk {
    
    
    /// Returns the internal **Tiled** node type.
    @objc public var tiledElementName: String {
        return "chunk"
    }
    
    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return "Tile Layer Chunk"
    }
    
    /// Returns the internal **Tiled** node type icon.
    @objc public override var tiledIconName: String {
        return "chunk-icon"
    }
    
    @objc public override var tiledListDescription: String {
        return "\(tiledNodeNiceName): "
    }
    
    /// A description of the node type used for help features.
    @objc public override var tiledHelpDescription: String {
        return "Tile layer chunk."
    }
}


// MARK: - Deprecations

extension SKTileLayerChunk {
    
    /// Returns a tile at the given **map** coordinate, if one exists.
    ///
    /// - Parameters:
    ///   - x: x-coordinate.
    ///   - y: y-coordinate.
    /// - Returns: tile object, if it exists.
    @available(*, deprecated, renamed: "tileAt")
    public func tileAt(_ x: Int, _ y: Int) -> SKTile? {
        return tileAt(Int32(x), Int32(y))
    }
}
