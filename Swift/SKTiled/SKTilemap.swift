//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
import GameplayKit


public enum TiledColors: String {
    case White  =  "#f7f5ef"
    case Grey   =  "#969696"
    case Red    =  "#990000"
    case Blue   =  "#86b9e3"
    case Green  =  "#33cc33"
    case Orange =  "#ff9933"
    case Debug  =  "#999999"
    
    public var color: SKColor {
        return SKColor.fromHexCode(self.rawValue)
    }
}


// MARK: - Tiled File Properties

/// Tile orientation
public enum TilemapOrientation: String {
    case Orthogonal   = "orthogonal"
    case Isometric    = "isometric"
    //case Hexagonal    = "hexagonal"
    //case Staggered    = "staggered"     // isometric staggered
}


public enum RenderOrder: String {
    case RightDown  = "right-down"
    case RightUp    = "right-up"
    case LeftDown   = "left-down"
    case LeftUp     = "left-up"
}


/**
 Tile offset used as a hint for coordinate conversion.
 
 - BottomLeft:  tile aligns at the bottom left corner.
 - TopLeft:     tile aligns at the top left corner.
 - TopRight:    tile aligns at the top right corner.
 - BottomRight: tile aligns at the bottom right corner.
 - Center:      tile aligns at the center.
 */
public enum TileOffset: Int {
    case bottomLeft = 0     // tile's upper left edge.
    case topLeft
    case topRight
    case bottomRight
    case center
}


/* Tilemap data encoding */
public enum TilemapEncoding: String {
    case Base64  = "base64"
    case CSV     = "csv"
    case XML     = "xml"
}


// MARK: - Sizing

/// Represents a tile x/y coordinate.
public struct TileCoord {
    public var x: Int32
    public var y: Int32
    
    public init(_ x: Int32, _ y: Int32){
        self.x = x
        self.y = y
    }
}


/// Cardinal direction
public enum CardinalDirection: Int {
    case north
    case northEast
    case east
    case southEast
    case south
    case southWest
    case west
    case northWest
}


public enum LayerPosition {
    case bottomLeft  // 0   - node bottom left rests at parent zeropoint
    case center      // 0.5 - node center rests at parent zeropoint
    case topRight    // 1   - node top right rests at parent zeropoint
}


///  Common tile size aliases
public let TileSizeZero  = CGSize(width: 0, height: 0)
public let TileSize8x8   = CGSize(width: 8, height: 8)
public let TileSize16x16 = CGSize(width: 16, height: 16)
public let TileSize32x32 = CGSize(width: 32, height: 32)



/// Represents a tiled map node.
public class SKTilemap: SKNode, TiledObject{
    
    public var filename: String!                                    // tilemap filename
    public var uuid: String = UUID().uuidString                   // unique id
    public var size: CGSize                                         // map size (in tiles)
    public var tileSize: CGSize                                     // tile size (in pixels)
    public var orientation: TilemapOrientation                      // map orientation
    public var renderOrder: RenderOrder = .RightDown                // render order
    
    // camera overrides
    public var worldScale: CGFloat = 1.0                            // initial world scale
    public var allowZoom: Bool = true                               // allow camera zoom
    public var allowMovement: Bool = true                           // allow camera movement
    
    // current tile sets
    public var tileSets: Set<SKTileset> = []                        // tilesets
    public var graphs: [String: GKGridGraph<GKGridGraphNode>] = [:]                  // pathfinding graphs
    
    // current layers
    public var layers: Set<TiledLayerObject> = []                   // layers (private)
    public var layerCount: Int { return self.layers.count }         // layer count attribute
    public var properties: [String: String] = [:]                   // custom properties
    public var zDeltaForLayers: CGFloat = 50                        // z-position range for layers
    public var backgroundColor: SKColor? = nil                      // optional background color (read from the Tiled file)
    public var baseLayer: SKTileLayer!                              // generic layer
    
    // debugging
    public var gridColor: SKColor = SKColor.black            // color used to visualize the tile grid
    public var frameColor: SKColor = SKColor.black           // bounding box color
    public var highlightColor: SKColor = SKColor.white       // color used to highlight tiles
    
    // convenience properties
    public var width: CGFloat { return size.width }
    public var height: CGFloat { return size.height }
    public var tileWidth: CGFloat { return tileSize.width }
    public var tileHeight: CGFloat { return tileSize.height }
    
    public var sizeHalved: CGSize { return CGSize(width: size.width / 2, height: size.height / 2)}
    public var tileWidthHalf: CGFloat { return tileWidth / 2 }
    public var tileHeightHalf: CGFloat { return tileHeight / 2 }    
    
    
    /// Rendered size of the map in pixels.
    public var sizeInPoints: CGSize {
        switch orientation {
        case .Orthogonal:
            return CGSize(width: size.width * tileSize.width, height: size.height * tileSize.height)
        case .Isometric:
            let side = width + height
            return CGSize(width: side * tileWidthHalf,  height: side * tileHeightHalf)
        }
    }

    // used to align the layers within the tile map
    public var layerAlignment: LayerPosition = .center {
        didSet {
            layers.forEach({self.positionLayer($0)})
        }
    }
    
    // returns the last GID for all of the tilesets.
    public var lastGID: Int {
        return tileSets.count > 0 ? tileSets.map {$0.lastGID}.max()! : 0
    }    
    
    /// Returns the last GID for all tilesets.
    public var lastIndex: Int {
        return layers.count > 0 ? layers.map {$0.index}.max()! : 0
    }
    
    /// Returns the last (highest) z-position in the map.
    public var lastZPosition: CGFloat {
        return layers.count > 0 ? layers.map {$0.zPosition}.max()! : 0
    }
    
    /// Tile overlap amount. 1 is typically a good value.
    public var tileOverlap: CGFloat = 0.5 {
        didSet {
            guard oldValue != tileOverlap else { return }
            for tileLayer in tileLayers {
                tileLayer.setTileOverlap(tileOverlap)
            }
        }
    }
    
    /// Global property to show/hide all `SKTileObject` objects.
    public var showObjects: Bool = false {
        didSet {
            guard oldValue != showObjects else { return }
            for objectLayer in objectGroups {
                objectLayer.showObjects = showObjects
            }
        }
    }
    
    /// Convenience property to return all tile layers.
    public var tileLayers: [SKTileLayer] {
        return layers.sorted(by: {$0.index < $1.index}).filter({$0 as? SKTileLayer != nil}) as! [SKTileLayer]
    }
    
    /// Convenience property to return all object groups.
    public var objectGroups: [SKObjectGroup] {
        return layers.sorted(by: {$0.index < $1.index}).filter({$0 as? SKObjectGroup != nil}) as! [SKObjectGroup]
    }
    
    /// Convenience property to return all image layers.
    public var imageLayers: [SKImageLayer] {
        return layers.sorted(by: {$0.index < $1.index}).filter({$0 as? SKImageLayer != nil}) as! [SKImageLayer]
    }
    
    // MARK: - Loading
    
    /**
     Load a Tiled tmx file and return a new `SKTilemap` object.
     
     - parameter filename: `String` Tiled file name.
     
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    public class func load(fromFile filename: String) -> SKTilemap? {
        if let tilemap = SKTilemapParser().load(fromFile: filename) {
            return tilemap
        }
        return nil
    }
    
    // MARK: - Init
    /**
     Initialize with dictionary attributes from xml parser.
     
     - parameter attributes: `Dictionary` attributes dictionary.
     
     - returns: `SKTileMapNode?`
     */
    public init?(attributes: [String: String]) {
        guard let width = attributes["width"] else { return nil }
        guard let height = attributes["height"] else { return nil }
        guard let tilewidth = attributes["tilewidth"] else { return nil }
        guard let tileheight = attributes["tileheight"] else { return nil }
        guard let orient = attributes["orientation"] else { return nil }
        
        // initialize tile size & map size
        tileSize = CGSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        size = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))
        
        // tile orientation
        guard let tileOrientation: TilemapOrientation = TilemapOrientation(rawValue: orient) else {
            fatalError("orientation \"\(orient)\" not supported.")
        }
        
        // render order
        if let rendorder = attributes["renderorder"] {
            guard let renderorder: RenderOrder = RenderOrder(rawValue: rendorder) else {
                fatalError("orientation \"\(orient)\" not supported.")
            }
            self.renderOrder = renderorder
        }
        
        self.orientation = tileOrientation

        // background color
        if let backgroundHexColor = attributes["backgroundcolor"] {
            self.backgroundColor = SKColor.fromHexCode(backgroundHexColor)
        }
        
        super.init()
        
        // setup the debug layer
        baseLayer = addNewTileLayer("Base")
    }
    
    /**
     Initialize with map size/tile size
     
     - parameter sizeX:     `Int` map width in tiles.
     - parameter sizeY:     `Int` map height in tiles.
     - parameter tileSizeX: `Int` tile width in pixels.
     - parameter tileSizeY: `Int` tile height in pixels.
     
     - returns: `SKTilemap`
     */
    public init(_ sizeX: Int, _ sizeY: Int,
                _ tileSizeX: Int, _ tileSizeY: Int,
                  orientation: TilemapOrientation = .Orthogonal) {
        self.size = CGSize(width: CGFloat(sizeX), height: CGFloat(sizeY))
        self.tileSize = CGSize(width: CGFloat(tileSizeX), height: CGFloat(tileSizeY))
        self.orientation = orientation
        super.init()
        
        // setup the debug layer
        baseLayer = addNewTileLayer("Base")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tilesets
    
    /**
     Add a tileset to tileset set.
     
     - parameter tileset: `SKTileset` tileset object.
     */
    public func addTileset(_ tileset: SKTileset) {
        tileSets.insert(tileset)
        tileset.tilemap = self
        tileset.parseProperties()
    }
    
    /**
     Returns a named tileset from the tilesets set.
     
     - parameter name: `String` tileset to return.
     
     - returns: `SKTileset?` tileset object.
     */
    public func getTileset(named name: String) -> SKTileset? {
        if let index = tileSets.index( where: { $0.name == name } ) {
            let tileset = tileSets[index]
            return tileset
        }
        return nil
    }

    /**
     Returns an external tileset with a given filename.
     
     - parameter filename: `String` tileset source file.
     
     - returns: `SKTileset?` tileset object, if it exists.
     */
    public func getTileset(fileNamed filename: String) -> SKTileset? {
        if let index = tileSets.index( where: { $0.filename == filename } ) {
            let tileset = tileSets[index]
            return tileset
        }
        return nil
    }

    
    // MARK: - Layers
    /**
     Returns all layers, sorted by index (first is lowest, last is highest).
     
     - returns: `[TiledLayerObject]` array of layers.
     */
    public func allLayers() -> [TiledLayerObject] {
        return layers.sorted(by: {$0.index < $1.index})
    }
    
    /**
     Returns an array of layer names.
     
     - returns: `[String]` layer names.
     */
    public func layerNames() -> [String] {
        return layers.flatMap { $0.name }
    }
    
    /**
     Add a layer to the layers set. Automatically sets zPosition based on the zDeltaForLayers attributes.
     
     - parameter layer: `TiledLayerObject` layer object.
     */
    public func addLayer(_ layer: TiledLayerObject) {
        
        // set the layer index
        layer.index = layers.count > 0 ? lastIndex + 1 : 0
        
        layers.insert(layer)
        addChild(layer)
        
        // align the layer to the anchorpoint
        positionLayer(layer)
        print("[SKTilemap]: positioning: \"\(layer.name!)\"...")
        layer.zPosition = zDeltaForLayers * CGFloat(layer.index)
        
        // override debugging colors
        layer.gridColor = self.gridColor
        layer.frameColor = self.frameColor
        layer.highlightColor = self.highlightColor
        layer.parseProperties()
    }
    
    public func addNewTileLayer(_ named: String) -> SKTileLayer {
        let layer = SKTileLayer(layerName: named, tileMap: self)
        addLayer(layer)
        return layer
    }
    
    /**
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer name.
     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(named layerName: String) -> TiledLayerObject? {
        if let index = layers.index( where: { $0.name == layerName } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Returns a layer matching the given UUID.
     
     - parameter uuid: `String` tile layer UUID.
     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(withID uuid: String) -> TiledLayerObject? {
        if let index = layers.index( where: { $0.uuid == uuid } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Returns a layer given the index (0 being the lowest).
     
     - parameter index: `Int` layer index.
     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(atIndex index: Int) -> TiledLayerObject? {
        if let index = layers.index( where: { $0.index == index } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Isolate a named layer (hides other layers). Pass `nil`
     to show all layers.
     
     - parameter named: `String` layer name.
     */
    public func isolateLayer(_ named: String?) {
        guard let name = named else {
            layers.map({$0.visible = true})
            return
        }
        layers.map({
            let isHidden: Bool = $0.name == named ? true : false
            $0.visible = isHidden
        })
    }
    
    /**
     Returns a named tile layer if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.
     
     - returns: `SKTileLayer?`
     */
    public func tileLayer(named name: String) -> SKTileLayer? {
        if let layerIndex = tileLayers.index( where: { $0.name == name } ) {
            let layer = tileLayers[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns a tile layer at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.
     
     - returns: `SKTileLayer?`
     */
    public func tileLayer(atIndex index: Int) -> SKTileLayer? {
        if let layerIndex = tileLayers.index( where: { $0.index == index } ) {
            let layer = tileLayers[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns a named object group if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.
     
     - returns: `SKObjectGroup?`
     */
    public func objectGroup(named name: String) -> SKObjectGroup? {
        if let layerIndex = objectGroups.index( where: { $0.name == name } ) {
            let layer = objectGroups[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns an object group at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.
     
     - returns: `SKObjectGroup?`
     */
    public func objectGroup(atIndex index: Int) -> SKObjectGroup? {
        if let layerIndex = objectGroups.index( where: { $0.index == index } ) {
            let layer = objectGroups[layerIndex]
            return layer
        }
        return nil
    }
    
    public func indexOf(layer: TiledLayerObject) -> Int {
        return 0
    }
    
    public func indexOf(layedNamed name: String) -> Int {
        return 0
    }
    
    /**
     Position child layers in relation to the anchorpoint.
     
     - parameter layer: `TiledLayerObject` layer.
     */
    fileprivate func positionLayer(_ layer: TiledLayerObject) {
        var layerPos = CGPoint.zero
        switch orientation {
        case .Orthogonal:
            
            let renderSize = CGSize(width: size.width * tileSize.width, height: size.height * tileSize.height)
            layerPos.x = -renderSize.width * layerAlignment.anchorPoint.x
            layerPos.y = renderSize.height * layerAlignment.anchorPoint.y
            
            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
            
        case .Isometric:
            let renderSize = CGSize(width: (size.width + size.height) * tileSize.halfWidth, height: (size.width + size.height) * tileSize.halfHeight)
            
            // layer offset
            layerPos.x = -renderSize.width * layerAlignment.anchorPoint.x
            layerPos.y = renderSize.height * layerAlignment.anchorPoint.y
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
        }
        
        layer.position = layerPos
    }
    
    /**
     Sort the layers in z based on a starting value (defaults to the current zPosition).
     
     - parameter fromZ: `CGFloat?` optional starting z-positon.
     */
    public func sortLayers(_ fromZ: CGFloat?=nil) {
        let startingZ: CGFloat = (fromZ != nil) ? fromZ! : zPosition
        allLayers().map {$0.zPosition = startingZ + (zDeltaForLayers * CGFloat($0.index))}
    }
    
    // MARK: - Tiles
    
    /**
     Return tiles at the given coordinate (all tile layers).
     
     - parameter coord: `TileCoord` coordinate.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func tilesAt(_ coord: TileCoord) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            if let tile = layer.tileAt(coord){
                result.append(tile)
            }
        }
        return result
    }
    
    /**
     Return tiles at the given coordinate (all tile layers).
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` - y-coordinate.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func tilesAt(_ x: Int, _ y: Int) -> [SKTile] {
        return tilesAt(TileCoord(x,y))
    }
    
    /**
     Returns a tile at the given coordinate from a layer.
     
     - parameter coord: `TileCoord` tile coordinate.
     - parameter name:  `String?` layer name.
     
     - returns: `SKTile?` tile, or nil.
     */
    public func tileAt(_ coord: TileCoord, inLayer name: String?) -> SKTile? {
        if let name = name {
            if let layer = getLayer(named: name) as? SKTileLayer {
                return layer.tileAt(coord)
            }
        }
        return nil
    }
    
    public func tileAt(_ x: Int, _ y: Int, inLayer name: String?) -> SKTile? {
        return tileAt(TileCoord(x,y), inLayer: name)
    }
    
    /**
     Returns tiles with a property of the given type (all tile layers).
     
     - parameter type: `String` type.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(ofType type: String) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTiles(ofType: type)
        }
        return result
    }
    
    /**
     Returns tiles matching the given gid (all tile layers).
     
     - parameter type: `Int` tile gid.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(withID id: Int) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTiles(withID: id)
        }
        return result
    }
    
    /**
     Returns tiles with a property of the given type & value (all tile layers).
     
     - parameter named: `String` property name.
     - parameter value: `AnyObject` property value.
     - returns: `[SKTile]` array of tiles.
     */
    public func getTilesWithProperty(_ named: String, _ value: AnyObject) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTilesWithProperty(named, value)
        }
        return result
    }
    
    /**
     Returns an array of all animated tile objects.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func getAnimatedTiles() -> [SKTile] {
        var result: [SKTile] = []
        enumerateChildNodes(withName: "//*") {
            node, stop in
            if let tile = node as? SKTile {
                if (tile.tileData.isAnimated == true) {
                    result.append(tile)
                }
            }
        }
        return result
    }
    
    // MARK: - Objects
    
    /**
     Return all of the current tile objects.
     
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects() -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodes(withName: "//*") {
            node, stop in
            if let node = node as? SKTileObject {
                result.append(node)
            }
        }
        return result
    }
    
    /**
     Return objects matching a given type.
     
     - parameter type: `String` object name to query.
     
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(ofType type: String) -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodes(withName: "//*") {
            node, stop in
            // do something with node or stop
            if let node = node as? SKTileObject {
                if let objectType = node.type {
                    if objectType == type {
                        result.append(node)
                    }
                }
            }
        }
        return result
    }
    
    /**
     Return objects matching a given name.
     
     - parameter named: `String` object name to query.
     
     - returns: `[SKTileObject]` array of objects.
     */
    public func getObjects(_ named: String) -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodes(withName: "//*") {
            node, stop in
            // do something with node or stop
            if let node = node as? SKTileObject {
                if let objectName = node.name {
                    if objectName == named {
                
                        result.append(node)
                    }
                }
            }
        }
        return result
        }
    
    // MARK: - Data
    /**
     Returns data for a global tile id.
     
     - parameter gid: `Int` global tile id.
     
     - returns: `SKTilesetData` tile data, if it exists.
     */
    public func getTileData(_ gid: Int) -> SKTilesetData? {
        for tileset in tileSets {
            if let tileData = tileset.getTileData(gid) {
                return tileData
            }
        }
        return nil
    }
    }


// MARK: - Extensions

extension TileCoord: CustomStringConvertible, CustomDebugStringConvertible {
    
    /**
     Initialize coordinate with two integers.
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` y-coordinate.
     
     - returns: `TileCoord` coordinate.
     */
    public init(_ x: Int, _ y: Int){
        self.init(Int32(x), Int32(y))
    }
    
    /**
     Initialize coordinate with a CGPoint.
     
     - parameter point: `CGPoint`
     
     - returns: `TileCoord` coordinate.
     */
    public init(point: CGPoint){
        self.init(Int32(point.x), Int32(point.y))
    }
    
    public init(_ x: CGFloat, _ y: CGFloat) {
        self.x = Int32(floor(x))
        self.y = Int32(floor(y))
    }
    
    /// Convert the coordinate to vector2 (for GKGridGraph).
    public var vec2: int2 {
        return int2(x, y)
    }
    
    public var description: String { return "x: \(Int(x)), y: \(Int(y))" }
    public var debugDescription: String { return description }
}


public extension TilemapOrientation {
    
    /// Hint for aligning tiles within each layer.
    public var alignmentHint: CGPoint {
        switch self {
        case .Orthogonal:
            return CGPoint(x: 0.5, y: 0.5)
        case .Isometric:
            return CGPoint(x: 0.5, y: 0.5)
        }
    }
}


extension LayerPosition: CustomStringConvertible {
    
    public var description: String {
        return "\(name): (\(self.anchorPoint.x), \(self.anchorPoint.y))"
    }
    
    public var name: String {
        switch self {
        case .bottomLeft: return "Bottom Left"
        case .center: return "Center"
        case .topRight: return "Top Right"
        }
    }
    
    public var anchorPoint: CGPoint {
        switch self {
        case .bottomLeft: return CGPoint(x: 0, y: 0)
        case .center: return CGPoint(x: 0.5, y: 0.5)
        case .topRight: return CGPoint(x: 1, y: 1)
        }
    }
}



public extension SKTilemap {
    
    override public var description: String {
        var tilemapName = "(None)"
        if let name = name {
            tilemapName = "\"\(name)\""
        }
        let renderSizeDesc = "\(sizeInPoints.width.roundoff(1)) x \(sizeInPoints.height.roundoff(1))"
        let sizeDesc = "\(Int(size.width)) x \(Int(size.height))"
        let tileSizeDesc = "\(Int(tileSize.width)) x \(Int(tileSize.height))"
        
        return "Map: \(tilemapName), \(renderSizeDesc): (\(sizeDesc) @ \(tileSizeDesc))"
    }
    
    override public var debugDescription: String { return description }
}
