//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// MARK: - Tiled File Properties
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


/* offset used as a hint for coordinate conversion */
public enum TileOffset: Int {
    case BottomLeft = 0     // tile's upper left edge.
    case TopLeft
    case TopRight
    case BottomRight
    case Center
}


public enum TilemapEncoding: String {
    case Base64  = "base64"
    case CSV     = "csv"
    case XML     = "xml"
}


/* valid property types */
public enum PropertyType: String {
    case bool
    case int
    case float
    case string
}


/* generic property */
public struct Property {
    public var name: String
    public var value: AnyObject
    public var type: PropertyType = .string
}


// MARK: - Sizing
public struct TileSize {
    public var width: CGFloat
    public var height: CGFloat
}


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
    case North
    case NorthEast
    case East
    case SouthEast
    case South
    case SouthWest
    case West
    case NorthWest
}


///  Common tile size aliases
public let TileSizeZero = TileSize(width: 0, height: 0)
public let TileSize8x8  = TileSize(width: 8, height: 8)
public let TileSize16x16 = TileSize(width: 16, height: 16)
public let TileSize32x32 = TileSize(width: 32, height: 32)


/// Represents tiled map size in tiles.
public struct MapSize {
    public var width: CGFloat
    public var height: CGFloat
    public var tileSize: TileSize = TileSize8x8
}


/// Represents a tile map.
public class SKTilemap: SKNode {
    
    public var mapSize: MapSize                                     // map size (in tiles)
    public var tileSize: TileSize { return mapSize.tileSize }       // tile size (in pixels)
    public var orientation: TilemapOrientation!                     // map orientation
    public var renderOrder: RenderOrder = .RightDown                // render order
    
    // current tile sets
    public var tileSets: Set<SKTileset> = []                        // tilesets
    
    // current layers
    private var layers: Set<TiledLayerObject> = []                  // layers
    public var layerCount: Int { return self.layers.count }         // layer count attribute
    public var properties: [String: String] = [:]                   // custom properties
    public var zDeltaForLayers: CGFloat = 50                        // z-position range for layers
    public var backgroundColor: SKColor? = nil                      // optional background color (read from the Tiled file)
    
    // debugging
    public var debugColor: SKColor = SKColor.blackColor()
    
    /// Rendered size of the map in pixels.
    public var renderSize: CGSize {
        var rsize = CGSizeZero
        if (orientation == .Orthogonal) {
            rsize = CGSizeMake(mapSize.width * tileSize.width, mapSize.height * tileSize.height)
        }
    
        if (orientation == .Isometric) {            
            rsize = CGSizeMake((mapSize.width + mapSize.height) * tileSize.halfWidth, (mapSize.width + mapSize.height) * tileSize.halfHeight)
        }
        return rsize
    }
    
    // used to align the layers within the tile map
    public var anchorPoint: CGPoint { return CGPointMake(0.5, 0.5) }
    // return the center position for layer nodes
    public var center: CGPoint {
        return CGPointMake(-renderSize.width * anchorPoint.x, renderSize.height - anchorPoint.y * renderSize.height * anchorPoint.y)
    }
    
    // returns the last GID for all of the tilesets.
    public var lastGID: Int {
        return tileSets.count > 0 ? tileSets.map {$0.lastGID}.maxElement()! : 0
    }    
    
    /// Returns the last GID for all tilesets.
    public var lastIndex: Int {
        return layers.count > 0 ? layers.map {$0.index}.maxElement()! : 0
    }
    
    /// Returns the last (highest) z-position in the map.
    public var lastZPosition: CGFloat {
        return layers.count > 0 ? layers.map {$0.zPosition}.maxElement()! : 0
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
                objectLayer.hidden = !showObjects
            }
        }
    }
    
    /// Convenience property to return all tile layers.
    public var tileLayers: [SKTileLayer] {
        var layers: [SKTileLayer] = []
        // use `SKTilemap.getLayers` to return sorted layers.
        for layer in getLayers() {
            if let layer = layer as? SKTileLayer {
                layers.append(layer)
            }
        }
        return layers
    }
    
    /// Convenience property to return all object groups.
    public var objectGroups: [SKObjectGroup] {
        var layers: [SKObjectGroup] = []
        for layer in getLayers() {
            if let layer = layer as? SKObjectGroup {
                layers.append(layer)
            }
        }
        return layers
    }
    
    /// Convenience property to return all image layers.
    public var imageLayers: [SKImageLayer] {
        var layers: [SKImageLayer] = []
        for layer in getLayers() {
            if let layer = layer as? SKImageLayer {
                layers.append(layer)
            }
        }
        return layers
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
        let tileSize = TileSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        mapSize = MapSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!), tileSize: tileSize)
        
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
        self.mapSize = MapSize(width: CGFloat(sizeX), height: CGFloat(sizeY),
                          tileSize: TileSize(width: CGFloat(tileSizeX), height: CGFloat(tileSizeY)))
        self.orientation = orientation
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tilesets
    
    /**
     Add a tileset to tileset set.
     
     - parameter tileset: `SKTileset` tileset object.
     */
    public func addTileset(tileset: SKTileset) {
        print("[SKTilemap]: adding tileset: \"\(tileset.name)\"")
        tileSets.insert(tileset)
        tileset.tilemap = self
    }
    
    /**
     Returns a named tileset from the tilesets set.
     
     - parameter name: `String` tileset to return.
     
     - returns: `SKTileset?` tileset object.
     */
    public func getTileset(named name: String) -> SKTileset? {
        if let index = tileSets.indexOf( { $0.name == name } ) {
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
        if let index = tileSets.indexOf( { $0.filename == filename } ) {
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
    public func getLayers() -> [TiledLayerObject] {
        return layers.sort({$0.index < $1.index})
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
    public func addLayer(layer: TiledLayerObject) {
        
        // set the layer index
        layer.index = layers.count > 0 ? lastIndex + 1 : 0
        
        layers.insert(layer)
        addChild(layer)
        
        // align the layer to the anchorpoint
        positionLayer(layer)
        layer.zPosition = zDeltaForLayers * CGFloat(layer.index)
        // override debugging colors
        layer.setDebugColor(self.debugColor)
    }
    
    /**
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer name.
     
     - returns: `TiledLayerObject?` layer object.
     */
    public func getLayer(named layerName: String) -> TiledLayerObject? {
        if let index = layers.indexOf( { $0.name == layerName } ) {
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
        if let index = layers.indexOf( { $0.uuid == uuid } ) {
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
        if let index = layers.indexOf( { $0.index == index } ) {
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
    public func isolateLayer(named: String?) {
        guard let name = named else {
            layers.map({$0.visible = true})
            return
        }
        layers.map({
            var isHidden: Bool = $0.name == named ? true : false
            $0.visible = isHidden
        })
    }
    
    /**
     Returns a named tile layer if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.
     
     - returns: `SKTileLayer?`
     */
    public func tileLayer(named name: String) -> SKTileLayer? {
        if let layerIndex = tileLayers.indexOf( { $0.name == name } ) {
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
        if let layerIndex = tileLayers.indexOf( { $0.index == index } ) {
            let layer = tileLayers[layerIndex]
            return layer
        }
        return nil
    }
    
    public func indexOf(layer layer: TiledLayerObject) -> Int {
        return 0
    }
    
    public func indexOf(layedNamed name: String) -> Int {
        return 0
    }
    
    /**
     Position child layers in relation to the anchorpoint.
     
     - parameter layer: `TiledLayerObject` layer.
     */
    private func positionLayer(layer: TiledLayerObject) {
        
        var layerPosition = CGPointZero
        if orientation == .Orthogonal {
            //layerPosition.x = -(renderSize.width * anchorPoint.x)
            //layerPosition.y = (renderSize.height * anchorPoint.y)
            
            layerPosition.x = -renderSize.width * anchorPoint.x
            layerPosition.y = renderSize.height - anchorPoint.y * renderSize.height
        }
            
        /*
         if orientation == .Isometric {
            //layerPosition.y = (renderSize.height * anchorPoint.y)
            layerPosition.y = (mapSize.height * tileSize.height) * anchorPoint.y
        }
        */
        if orientation == .Isometric {
            //layerPosition.x = layerPosition.x + tileSize.width / 2
            layerPosition.y = (renderSize.height * anchorPoint.y) + tileSize.height / 2
        }
        
        layer.position = layerPosition
        
        // layer offset
        layer.position.x += layer.offset.x
        layer.position.y -= layer.offset.y
    }
    
    /**
     Sort the layers in z based on a starting value (defaults to the current zPosition).
     
     - parameter fromZ: `CGFloat?` optional starting z-positon.
     */
    public func sortLayers(fromZ: CGFloat?=nil) {
        let startingZ: CGFloat = (fromZ != nil) ? fromZ! : zPosition
        getLayers().map {$0.zPosition = startingZ + (zDeltaForLayers * CGFloat($0.index))}
    }
    
    // MARK: - Tiles
    
    /**
     Return tiles at the given coordinate (all tile layers).
     
     - parameter coord: `TileCoord` coordinate.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func tilesAt(coord: TileCoord) -> [SKTile] {
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
    public func tilesAt(x: Int, _ y: Int) -> [SKTile] {
        return tilesAt(TileCoord(x,y))
    }
    
    /**
     Returns a tile at the given coordinate from a layer.
     
     - parameter coord: `TileCoord` tile coordinate.
     - parameter name:  `String?` layer name.
     
     - returns: `SKTile?` tile, or nil.
     */
    public func tileAt(coord: TileCoord, inLayer name: String?) -> SKTile? {
        if let name = name {
            if let layer = getLayer(named: name) as? SKTileLayer {
                return layer.tileAt(coord)
            }
        }
        return nil
    }
    
    public func tileAt(x: Int, _ y: Int, inLayer name: String?) -> SKTile? {
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
    public func getTilesWithProperty(named: String, _ value: AnyObject) -> [SKTile] {
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
        enumerateChildNodesWithName("//*") {
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
        enumerateChildNodesWithName("//*") {
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
        enumerateChildNodesWithName("//*") {
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
    public func getObjects(named: String) -> [SKTileObject] {
        var result: [SKTileObject] = []
        enumerateChildNodesWithName("//*") {
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
    public func getTileData(gid: Int) -> SKTilesetData? {
        for tileset in tileSets {
            if let tileData = tileset.getTileData(gid) {
                return tileData
            }
        }
        return nil
    }
}


// MARK: - Extensions


extension MapSize: CustomStringConvertible, CustomDebugStringConvertible {
    
    public init(_ w: Int, _ h: Int, _ tw: Int, _ th: Int) {
        let tileSize = TileSize(width: CGFloat(tw), height: CGFloat(th))
        self.init(width: CGFloat(w), height: CGFloat(h), tileSize: tileSize)
    }
    
    public var halfWidth: CGFloat {
        return width / 2.0
    }
    
    public var halfHeight: CGFloat {
        return height / 2.0
    }
    
    /// Returns the map size as `CGSize`
    public var size: CGSize { return CGSizeMake(width, height) }
    
    /// Returns total tile `Int` count
    public var count: Int { return Int(width) * Int(height) }
    

    // Debugging
    public var description: String { return "\(Int(width)) x \(Int(height)) @ \(tileSize)" }
    public var debugDescription: String { return description }
}


extension TileSize: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var halfWidth: CGFloat {
        return width / 2.0
    }
    
    public var halfHeight: CGFloat {
        return height / 2.0
    }
    
    /**
     Initialize `TileSize` with two integers.
     
     - parameter x: `Int` tile width.
     - parameter y: `Int` tile height.
     
     - returns: `TileSize` tile size.
     */
    public init(_ x: Int, _ y: Int){
        self.init(width: CGFloat(x), height: CGFloat(y))
    }
    
    /**
     Initialize `TileSize` a single integer representing w/h values.
     
     - parameter tile: `Int` tile height & width.
     
     - returns: `TileSize` tile size.
     */
    public init(_ tile: Int){
        self.init(width: CGFloat(tile), height: CGFloat(tile))
    }
    
    /**
     Initialize `TileSize` a single CGFloat representing w/h values.
     
     - parameter tile: `CGFloat` tile height & width.
    
     - returns: `TileSize` tile size.
     */
    public init(_ tile: CGFloat){
        self.init(width: tile, height: tile)
    }
    
    /// Returns the tile size as `CGSize`
    public var size: CGSize { return CGSizeMake(width, height) }
    // Debugging
    public var description: String { return "\(Int(width)) x \(Int(height))" }
    public var debugDescription: String { return description }
}


public extension TileCoord {
    
    /**
     Initialize coordinate with two integers.
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` y-coordinate.
     
     - returns: `TileCoord` coordinate.
     */
    public init(_ x: Int, _ y: Int){
        self.init(Int32(x), Int32(y))
    }
    
    /// Convert the coordinate to vector2.
    public var vec2: int2 {
        return int2(x, y)
    }
}


public extension TilemapOrientation {
    
    /// Point used to align tiles within the layer.
    public var alignment: CGPoint {
        switch self {
        case .Orthogonal:
            return CGPointMake(0.5, 0.5)
        case .Isometric:
            return CGPointMake(0.5, 0.5)
        }
    }
}


extension TileCoord: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { return "x: \(Int(x)), y: \(Int(y))" }
    public var debugDescription: String { return description }
}


public extension SKTilemap {

    /**
     Calculate the distance from the node's origin
     */
    public func distanceFromOrigin(pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVectorMake(dx, dy)
    }
    
    override public var description: String {
        var tilemapName = "(null)"
        if let name = name {
            tilemapName = "\"\(name)\""
        }
        return "Tilemap: \(tilemapName), \(mapSize) \(renderSize)"
    }
    
    override public var debugDescription: String { return description }
}
