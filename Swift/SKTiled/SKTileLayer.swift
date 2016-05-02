//
//  SKTileLayer.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit


// base class for all layer types
public class TiledLayerObject: SKNode {
    
    unowned var tilemap: SKTilemap
    
    // need to add UUID to hash each layer, as layer names can be the same
    public var uuid: String
    public var index: Int = 0                       // index of the layer in the tmx file
    public var visible: Bool = true                 // map this to hidden
    public var opacity: CGFloat = 1.0
    public var offset: CGPoint = CGPointZero
    
    // generic layer properties
    public var properties: [String: String] = [:]
    
    public init(layerName: String, tileMap: SKTilemap){
        // create a unique id right away
        self.uuid = NSUUID().UUIDString
        self.tilemap = tileMap
        super.init()
        self.name = layerName
    }
    
    required public  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Prune tiles out of the camera bounds.
     
     - parameter outsideOf: `CGRect` camera bounds.
     */
    public func pruneTiles(outsideOf: CGRect) {
        /* override in subclass */
    }
    
    /**
     Flatten (render) the tile layer.
     */
    public func flattenLayer() {
        /* override in subclass */
    }
    
    override public var hashValue: Int {
        return self.uuid.hashValue
    }
}


// represents a tile map layer
public class SKTileLayer: TiledLayerObject {
    
    private typealias TilesArray = Array2D<SKTile>
    
    // layer size
    public var mapSize: MapSize                     // map size, ie: 28 x 36
    
    // container for the tile sprites
    private var tiles: TilesArray
    public var render: Bool = false                 // render tile layer as a single image
    
    // MARK: - Init
    
    override public init(layerName: String, tileMap: SKTilemap) {
        self.mapSize = MapSize(width: tileMap.mapSize.width, height: tileMap.mapSize.height)
        self.tiles = TilesArray(columns: Int(tileMap.mapSize.width), rows: Int(tileMap.mapSize.height))
        super.init(layerName: layerName, tileMap: tileMap)
    }
    
    public init?(tileMap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero) {
        // name, width and height are required
        // TODO: according to tmx file format, width & height default to tilemap size
        guard let layerName = attributes["name"] else { return nil }
        guard let width = attributes["width"] else { return nil }
        guard let height = attributes["height"] else { return nil }
        
        self.mapSize = MapSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))
        self.tiles = TilesArray(columns: Int(tileMap.mapSize.width), rows: Int(tileMap.mapSize.height))
        super.init(layerName: layerName, tileMap: tileMap)
        self.offset = offset
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tiles
    /**
     Add tile data to the layer.
     
     - parameter data: `[Int]` tile data.
     
     - returns: `Bool` data is valid.
     */
    public func addTileData(data: [Int]) -> Bool {
        if !(data.count==mapSize.count) {
            print("\n[SKTileLayer]: ERROR: invalid data size: \(data.count), expected: \(mapSize.count)")
            return false
        }
        
        for id in 0..<data.count {
            let gid = data[id]
            print("id: \(gid)")
        }
        
        return true
        
    }
    
    public func setTileAtCoord(x: Int, y: Int, gid: Int) {
        print("[SKTileLayer]: setting tile at: \(x), \(y), id: \(gid)")
        //let tileData = SKTilesetData()
        //return SKTile()
    }
}


// object group draw order
public enum ObjectGroupDrawOrder: String {
    case TopDown
    case Manual
}


/// Objects group class
public class SKObjectGroup: TiledLayerObject {
    
    public var color: SKColor = SKColor.clearColor()
    public var drawOrder: ObjectGroupDrawOrder = ObjectGroupDrawOrder.TopDown
    public var objects: Set<SKTileObject> = []
    
    // MARK: - Init
    public init?(tileMap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero) {
        guard let layerName = attributes["name"] else { return nil }
        //guard let width = attributes["width"] else { return nil }
        //guard let height = attributes["height"] else { return nil }
        
        super.init(layerName: layerName, tileMap: tileMap)
        self.offset = offset
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Objects
    func addObject(object: SKTileObject) -> SKTileObject? {
        if objects.contains({ $0.hashValue == object.hashValue }) {
            return nil
        }
        objects.insert(object)
        return object
    }
}


/// Image layer class
public class SKImageLayer: TiledLayerObject {
    public var sprite: SKSpriteNode?
    
    public init?(tileMap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero) {
        guard let layerName = attributes["name"] else { return nil }
        /*
         guard let imageSource = attributes["source"] else { return nil }
         guard let imageWidth = attributes["width"] else { return nil }
         guard let imageHeight = attributes["height"] else { return nil }
         
         let texture = SKTexture(imageNamed: imageSource)
         texture.filteringMode = .Nearest
         sprite = SKSpriteNode(texture: texture)
         */
        
        super.init(layerName: layerName, tileMap: tileMap)
        self.offset = offset
        //addChild(sprite!)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



extension TiledLayerObject {
    override public var description: String {
        return "Layer: \"\(name!)\""
    }
    
    override public var debugDescription: String {
        return description
    }
}

