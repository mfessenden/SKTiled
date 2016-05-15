//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// MARK: - Protocols

/* generic SKTilemap object */
protocol TiledObject {
    var uuid: String { get set }                  // unique id (layer object names are not unique).
    var properties: [String: String] { get set }  // properties shared by most objects.
    // size
    var anchorPoint: CGPoint { get set }          // emulates a sprite node.
    var size: CGSize { get }                      // emulates a sprite node.
    var visible: Bool { get set }
    
    var center: CGPoint { get }
    func distanceFromOrigin(pos: CGPoint) -> CGVector
}


// screen format
public enum ScreenFormat: Int {
    case Universal
    case Portrait
    case Landscape
}

// MARK: - Tiled File Properties
public enum TilemapOrientation: String {
    case Orthogonal   = "orthogonal"
    case Isometric    = "isometric"
    case Hexagonal    = "hexagonal"
    case Staggered    = "staggered"
}


public enum RenderOrder: String {
    case RightDown  = "right-down"
    case RightUp    = "right-up"
    case LeftDown   = "left-down"
    case LeftUp     = "left-up"
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


public enum FlippedFlags: CUnsignedLong {
    case Horizontal = 0x80000000
    case Vertical   = 0x40000000
    case Diagonal   = 0x20000000
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


public struct TileCoord {
    public var x: Int32
    public var y: Int32
    
    public init(_ x: Int32, _ y: Int32){
        self.x = x
        self.y = y
    }
}


public var TileSizeZero = TileSize(width: 0, height: 0)
public var TileSize8x8  = TileSize(width: 8, height: 8)
public var TileSize16x16 = TileSize(width: 16, height: 16)



public struct MapSize {
    public var width: CGFloat
    public var height: CGFloat
    public var tileSize: TileSize = TileSize8x8
}


public class SKTilemap: SKNode {
    
    public var mapSize: MapSize
    public var orientation: TilemapOrientation!
    // current tile sets
    public var tileSets: Set<SKTileset> = []
    
    // current layers
    public var layers: Set<TiledLayerObject> = []
    public var properties: [String: String] = [:]
    public var zDeltaForLayers: CGFloat = 50
    
    // debugging
    public var debugLabel: SKLabelNode!
    public var debugColor: SKColor = SKColor(red: 0, green: 1, blue: 0, alpha: 1)
    
    // emulate size & anchor point
    public var size: CGSize { return mapSize.renderSize }
    
    public var anchorPoint: CGPoint { return CGPointMake(0.5, 0.5) }
    public var center: CGPoint {
        return CGPointMake((size.width / 2) - (size.width * anchorPoint.x), (size.height / 2) - (size.height * anchorPoint.y))
        //return CGPointMake((size.width * anchorPoint.x) * -1, (size.height * anchorPoint.y) * -1)
    }
    
    public var renderSize: CGSize {
        return mapSize.renderSize
    }
    
    public var tileSize: TileSize {
        return mapSize.tileSize
    }
    
    // returns the last GID for all of the tilesets.
    public var lastGID: Int {
        return tileSets.count > 0 ? tileSets.map {$0.lastGID}.maxElement()! : 0
    }    
    
    // returns the last GID for all of the tilesets.
    public var lastIndex: Int {
        return layers.count > 0 ? layers.map {$0.index}.maxElement()! : 0
    }
    
    // MARK: - Loading
    public class func loadTMX(fileNamed: String) -> SKTilemap? {
        if let tilemap = SKTiledmapParser().loadFromFile(fileNamed) {
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
        
        // initialize tile size
        let tileSize = TileSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        mapSize = MapSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!), tileSize: tileSize)
        
        if let fileOrientation: TilemapOrientation = TilemapOrientation(rawValue: orient){
            self.orientation = fileOrientation
        }
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tilesets
    public func addTileset(tileset: SKTileset) {
        print("[SKTilemap]: adding tileset: \"\(tileset.name)\"")
        tileSets.insert(tileset)
    }
    
    /**
     Returns a named tileset from the tilesets set.
     
     - parameter name: `String` tileset to return.
     
     - returns: `SKTileset?` tileset object.
     */
    public func getTileset(name: String) -> SKTileset? {
        if let index = tileSets.indexOf( { $0.name == name } ) {
            let tileset = tileSets[index]
            return tileset
        }
        return nil
    }

    
    // MARK: - Layers
    public func layerNames() -> [String] {
        return layers.flatMap { $0.name }
    }
    
    public func addLayer(layer: TiledLayerObject) {
        layer.index = layers.count > 0 ? lastIndex + 1 : 0

        // query the layer type
        var layerType = "tile"
        if let _ = layer as? SKObjectGroup { layerType = "object" }
        if let _ = layer as? SKImageLayer { layerType = "image" }
        
        print("[SKTilemap]: adding \(layerType) layer: \"\(layer.name!)\"...")
        layers.insert(layer)
        addChild(layer)
        positionLayer(layer)
        layer.zPosition = zDeltaForLayers * CGFloat(layer.index)
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
    
    // position the layer so that it aligns with the anchorpoint.
    private func positionLayer(layer: TiledLayerObject) {
        var layerPosition = CGPointZero
        
        if orientation == .Orthogonal {
            layerPosition.x = -(renderSize.width * anchorPoint.x)
            layerPosition.y = (renderSize.height * anchorPoint.y) // was not negative in other
        }
        
        layer.position = layerPosition
        
        //layer.position.x += (layer.offset.x + layer.offset.x * anchorPoint.x)
        //layer.position.y -= (layer.offset.y - layer.offset.y * anchorPoint.y)
        
        print("\(name): position: \(layer.position)")
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
            // do something with node or stop
            if let node = node as? SKTileObject {
                result.append(node)
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


public extension TileCoord {
    
    public init(_ x: Int, _ y: Int){
        self.init(Int32(x), Int32(y))
    }
    
    /// Convert the coordinate to vector2.
    public var vec2: int2 {
        return int2(x, y)
    }
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
        return "Tilemap: \(tilemapName), \(mapSize)"
    }
    
    override public var debugDescription: String { return description }
}
