//
//  SKTilemap.swift
//  SKTilemap
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public enum TiledColors: String {
    case White  =  "#f7f5ef"
    case Grey   =  "#969696"
    case Red    =  "#990000"
    case Blue   =  "#86b9e3"
    case Green  =  "#33cc33"
    case Orange =  "#ff9933"
    case Debug  =  "#999999"
    
    public var color: SKColor {
        return SKColor(hexString: self.rawValue)
    }
}


// MARK: - Tiled File Properties

/// Tile orientation
public enum TilemapOrientation: String {
    case Orthogonal   = "orthogonal"
    case Isometric    = "isometric"
    case Hexagonal    = "hexagonal"
    case Staggered    = "staggered"     // isometric staggered
}


public enum RenderOrder: String {
    case RightDown  = "right-down"
    case RightUp    = "right-up"
    case LeftDown   = "left-down"
    case LeftUp     = "left-up"
}


/**
 Tile offset hint for coordinate conversion.
 
 - BottomLeft:  tile aligns at the bottom left corner.
 - TopLeft:     tile aligns at the top left corner.
 - TopRight:    tile aligns at the top right corner.
 - BottomRight: tile aligns at the bottom right corner.
 - Center:      tile aligns at the center.
 */
public enum TileOffset: Int {
    case BottomLeft = 0     // tile's upper left edge.
    case TopLeft
    case TopRight
    case BottomRight
    case Center
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

/**
 Alignment hint used to position the layers within the `SKTilemap` node.
 
 - BottomLeft:   node bottom left rests at parent zeropoint (0)
 - Center:       node center rests at parent zeropoint (0.5)
 - TopRight:     node top right rests at parent zeropoint. (1)
 */
public enum LayerPosition {
    case BottomLeft
    case Center
    case TopRight
}

/**
 Hexagonal stagger axis.
 
 - X: axis is along the x-coordinate.
 - Y: axis is along the y-coordinate.
 */
public enum StaggerAxis: String {
    case X  = "x"
    case Y  = "y"
}


/**
 Hexagonal stagger index.
 
 - Even: stagger evens.
 - Odd:  stagger odds.
 */
public enum StaggerIndex: String {
    case Even  = "even"
    case Odd   = "odd"
}


///  Common tile size aliases
public let TileSizeZero  = CGSize(width: 0, height: 0)
public let TileSize8x8   = CGSize(width: 8, height: 8)
public let TileSize16x16 = CGSize(width: 16, height: 16)
public let TileSize32x32 = CGSize(width: 32, height: 32)



/// Represents a tiled map node.
public class SKTilemap: SKNode, SKTiledObject{
    
    public var filename: String!                                    // tilemap filename
    public var uuid: String = NSUUID().UUIDString                   // unique id
    public var size: CGSize                                         // map size (in tiles)
    public var tileSize: CGSize                                     // tile size (in pixels)
    public var orientation: TilemapOrientation                      // map orientation
    public var renderOrder: RenderOrder = .RightDown                // render order
    
    // hexagonal
    public var hexsidelength: Int = 0                               // hexagonal side length
    public var staggeraxis: StaggerAxis = .Y                        // stagger axis
    public var staggerindex: StaggerIndex = .Odd                    // stagger index.
    
    // camera overrides
    public var worldScale: CGFloat = 1.0                            // initial world scale
    public var allowZoom: Bool = true                               // allow camera zoom
    public var allowMovement: Bool = true                           // allow camera movement
    
    // current tile sets
    public var tileSets: Set<SKTileset> = []                        // tilesets
    
    // current layers
    private var layers: Set<TiledLayerObject> = []                  // layers
    public var layerCount: Int { return self.layers.count }         // layer count attribute
    public var properties: [String: String] = [:]                   // custom properties
    public var zDeltaForLayers: CGFloat = 50                        // z-position range for layers
    public var backgroundColor: SKColor? = nil                      // optional background color (read from the Tiled file)
    // default layer
    lazy public var baseLayer: SKTileLayer = {
        let layer = SKTileLayer(layerName: "Base", tileMap: self)
        self.addLayer(layer)
        return layer
    }()
    
    // debugging
    public var gridColor: SKColor = SKColor.blackColor()            // color used to visualize the tile grid
    public var frameColor: SKColor = SKColor.blackColor()           // bounding box color
    public var highlightColor: SKColor = SKColor.greenColor()       // color used to highlight tiles
    
    /// Rendered size of the map in pixels.
    public var sizeInPoints: CGSize {
        switch orientation {
        case .Orthogonal:
            return CGSizeMake(size.width * tileSize.width, size.height * tileSize.height)
        case .Isometric:
            let side = width + height
            return CGSizeMake(side * tileWidthHalf,  side * tileHeightHalf)
        case .Hexagonal, .Staggered:
            var result = CGSizeZero
            if staggerX == true {
                result = CGSize(width: width * columnWidth + sideOffsetX,
                                height: height * (tileHeight + sideLengthY))
                
                if width > 1 { result.height += rowHeight }
            } else {
                result = CGSize(width: width * (tileWidth + sideLengthX),
                                height: height * rowHeight + sideOffsetY)
            
                if height > 1 { result.width += columnWidth }
            }
            return result
        }
    }

    // used to align the layers within the tile map
    public var layerAlignment: LayerPosition = .Center {
        didSet {
            layers.forEach({self.positionLayer($0)})
        }
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
                objectLayer.showObjects = showObjects
            }
        }
    }
    
    /// Convenience property to return all tile layers.
    public var tileLayers: [SKTileLayer] {
        return layers.sort({$0.index < $1.index}).filter({$0 as? SKTileLayer != nil}) as! [SKTileLayer]
    }
    
    /// Convenience property to return all object groups.
    public var objectGroups: [SKObjectGroup] {
        return layers.sort({$0.index < $1.index}).filter({$0 as? SKObjectGroup != nil}) as! [SKObjectGroup]
    }
    
    /// Convenience property to return all image layers.
    public var imageLayers: [SKImageLayer] {
        return layers.sort({$0.index < $1.index}).filter({$0 as? SKImageLayer != nil}) as! [SKImageLayer]
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
        
        self.orientation = tileOrientation
        
        // render order
        if let rendorder = attributes["renderorder"] {
            guard let renderorder: RenderOrder = RenderOrder(rawValue: rendorder) else {
                fatalError("orientation \"\(rendorder)\" not supported.")
            }
            self.renderOrder = renderorder
        }
        
        // hex side
        if let hexside = attributes["hexsidelength"] {
            self.hexsidelength = Int(hexside)!
        }
        
        // hex stagger axis
        if let hexStagger = attributes["staggeraxis"] {
            guard let staggerAxis: StaggerAxis = StaggerAxis(rawValue: hexStagger) else {
                fatalError("stagger axis \"\(hexStagger)\" not supported.")
            }
            self.staggeraxis = staggerAxis
        }
        
        // hex stagger index
        if let hexIndex = attributes["staggerindex"] {
            guard let hexindex: StaggerIndex = StaggerIndex(rawValue: hexIndex) else {
                fatalError("stagger index \"\(hexIndex)\" not supported.")
            }
            self.staggerindex = hexindex
        }

        // background color
        if let backgroundHexColor = attributes["backgroundcolor"] {
            self.backgroundColor = SKColor(hexString: backgroundHexColor)
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
        self.size = CGSize(width: CGFloat(sizeX), height: CGFloat(sizeY))
        self.tileSize = CGSize(width: CGFloat(tileSizeX), height: CGFloat(tileSizeY))
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
    public func allLayers() -> [TiledLayerObject] {
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
        layer.gridColor = self.gridColor
        layer.frameColor = self.frameColor
        layer.highlightColor = self.highlightColor
        layer.parseProperties()
    }
    
    public func addNewTileLayer(named: String) -> SKTileLayer {
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
    
    /**
     Returns a named object group if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.
     
     - returns: `SKObjectGroup?`
     */
    public func objectGroup(named name: String) -> SKObjectGroup? {
        if let layerIndex = objectGroups.indexOf( { $0.name == name } ) {
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
        if let layerIndex = objectGroups.indexOf( { $0.index == index } ) {
            let layer = objectGroups[layerIndex]
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
        var layerPos = CGPointZero
        switch orientation {
            
        case .Orthogonal:
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            
            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
            
        case .Isometric:
            // layer offset
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
        
        case .Hexagonal, .Staggered:
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            
            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
        }
    
        layer.position = layerPos
    }
    
    /**
     Sort the layers in z based on a starting value (defaults to the current zPosition).
     
     - parameter fromZ: `CGFloat?` optional starting z-positon.
     */
    public func sortLayers(fromZ: CGFloat?=nil) {
        let startingZ: CGFloat = (fromZ != nil) ? fromZ! : zPosition
        allLayers().map {$0.zPosition = startingZ + (zDeltaForLayers * CGFloat($0.index))}
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
    /**
     Returns data for a global tile id.
     
     - parameter gid: `Int` global tile id.
     
     - returns: `SKTilesetData` tile data, if it exists.
     */
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

extension TileCoord: CustomStringConvertible, CustomDebugStringConvertible {
    
    /**
     Initialize coordinate with two integers.
     
     - parameter x: `Int32` x-coordinate.
     - parameter y: `Int32` y-coordinate.
     
     - returns: `TileCoord` coordinate.
     */
    public init(_ x: Int32, _ y: Int32){
        self.x = x
        self.y = y
    }
    
    /**
     Initialize coordinate with two integers.
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` y-coordinate.
     
     - returns: `TileCoord` coordinate.
     */
    public init(_ x: Int, _ y: Int){
        self.init(Int32(x), Int32(y))
    }
    
    public init(_ x: CGFloat, _ y: CGFloat) {
        self.x = Int32(floor(x))
        self.y = Int32(floor(y))
    }
    
    /**
     Initialize coordinate with a CGPoint.
     
     - parameter point: `CGPoint`
     
     - returns: `TileCoord` coordinate.
     */
    public init(point: CGPoint){
        self.init(point.x, point.y)
    }
    
    /**
     Convert the coordinate values to CGPoint.
     
     - returns: `CGPoint` point.
     */
    public func toPoint() -> CGPoint {
        return CGPoint(x: Int(x), y: Int(y))
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
        case .Hexagonal:
            return CGPoint(x: 0.5, y: 0.5)
        case .Staggered:
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
        case .BottomLeft: return "Bottom Left"
        case .Center: return "Center"
        case .TopRight: return "Top Right"
        }
    }
    
    public var anchorPoint: CGPoint {
        switch self {
        case .BottomLeft: return CGPoint(x: 0, y: 0)
        case .Center: return CGPoint(x: 0.5, y: 0.5)
        case .TopRight: return CGPoint(x: 1, y: 1)
        }
    }
}



public extension SKTilemap {
    
    // convenience properties
    public var width: CGFloat { return size.width }
    public var height: CGFloat { return size.height }
    public var tileWidth: CGFloat { return tileSize.width }
    public var tileHeight: CGFloat { return tileSize.height }
    
    public var sizeHalved: CGSize { return CGSize(width: size.width / 2, height: size.height / 2)}
    public var tileWidthHalf: CGFloat { return tileWidth / 2 }
    public var tileHeightHalf: CGFloat { return tileHeight / 2 }
    
    // hexagonal/staggered
    public var staggerX: Bool { return (staggeraxis == .X) }
    public var staggerEven: Bool { return staggerindex == .Even }
    
    public var sideLengthX: CGFloat { return (staggeraxis == .X) ? CGFloat(hexsidelength) : 0 }
    public var sideLengthY: CGFloat { return (staggeraxis == .Y) ? CGFloat(hexsidelength) : 0 }
    
    public var sideOffsetX: CGFloat { return (tileWidth - sideLengthX) / 2 }
    public var sideOffsetY: CGFloat { return (tileHeight - sideLengthY) / 2 }
    
    // coordinate grid values
    public var columnWidth: CGFloat { return sideOffsetX + sideLengthX }
    public var rowHeight: CGFloat { return sideOffsetY + sideLengthY }
    
    // MARK: - Hexagonal / Staggered methods
    /**
     Returns true if the given x-coordinate represents a staggered column.
     
     - parameter x:  `Int` map x-coordinate.
     - returns: `Bool` column should be staggered.
     */
    public func doStaggerX(x: Int) -> Bool {
        return staggerX && Bool((x & 1) ^ staggerEven.hashValue)
    }
    
    /**
     Returns true if the given y-coordinate represents a staggered row.
     
     - parameter x:  `Int` map y-coordinate.
     - returns: `Bool` row should be staggered.
     */
    public func doStaggerY(y: Int) -> Bool {
        return !staggerX && Bool((y & 1) ^ staggerEven.hashValue)
    }
    
    public func topLeft(x: CGFloat, _ y: CGFloat) -> CGPoint {
        // pointy-topped
        if (staggerX == false) {
            // y is odd = 1, y is even = 0
            // stagger index hash: Int = 0 (even), 1 (odd)
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y - 1)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
            // flat-topped
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        }
    }
    
    public func topRight(x: Int, _ y: Int) -> CGPoint {
        if (staggerX == false) {
            if Bool((y & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y - 1)
            } else {
                return CGPoint(x: x, y: y - 1)
            }
        } else {
            if Bool((x & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y)
            } else {
                return CGPoint(x: x + 1, y: y - 1)
            }
        }
    }
    
    public func bottomLeft(x: Int, _ y: Int) -> CGPoint {
        if (staggerX == false) {
            if Bool((y & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y + 1)
            }
        } else {
            if Bool((x & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y)
            }
        }
    }
    
    public func bottomRight(x: Int, _ y: Int) -> CGPoint {
        if (staggerX == false) {
            if Bool((y & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x, y: y + 1)
            }
        } else {
            if Bool((x & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x + 1, y: y)
            }
        }
    }
    
    override public var description: String {
        var tilemapName = "(None)"
        if let name = name {
            tilemapName = "\"\(name)\""
        }
        let renderSizeDesc = "\(sizeInPoints.width.roundTo(1)) x \(sizeInPoints.height.roundTo(1))"
        let sizeDesc = "\(Int(size.width)) x \(Int(size.height))"
        let tileSizeDesc = "\(Int(tileSize.width)) x \(Int(tileSize.height))"
        
        return "Map: \(tilemapName), \(renderSizeDesc): (\(sizeDesc) @ \(tileSizeDesc))"
    }
    
    override public var debugDescription: String { return description }
}
