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
    
    public var tilemap: SKTilemap
    // layer size
    public var mapSize: MapSize                     // map size, ie: 28 x 36
    public var uuid: String = NSUUID().UUIDString   // unique layer id
    public var index: Int = 0                       // index of the layer in the tmx file
    // properties
    public var properties: [String: String] = [:]   // generic layer properties
    
    public var offset: CGPoint = CGPointZero {       // layer offset value
        didSet {
            guard oldValue != offset else { return }
            position = offset
        }
    }
    
    // blending/visibility
    public var opacity: CGFloat = 1.0 {
        didSet {
            guard oldValue != opacity else { return }
            self.alpha = opacity
        }
    }
    
    public var visible: Bool = true {
        didSet {
            guard oldValue != visible else { return }
            self.hidden = !visible
        }
    }

    public init(layerName: String, tileMap: SKTilemap){
        // create a unique id right away
        self.tilemap = tileMap
        self.mapSize = tileMap.mapSize
        super.init()
        self.name = layerName
    }
    
    required public init?(coder aDecoder: NSCoder) {
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
    
    // container for the tile sprites
    private var tiles: TilesArray
    public var render: Bool = false                 // render tile layer as a single image
    
    // MARK: - Init
    
    override public init(layerName: String, tileMap: SKTilemap) {
        self.tiles = TilesArray(columns: Int(tileMap.mapSize.width), rows: Int(tileMap.mapSize.height))
        super.init(layerName: layerName, tileMap: tileMap)
    }
    
    public init?(tileMap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero) {
        // name, width and height are required
        guard let layerName = attributes["name"] else { return nil }
        // according to tmx file format, width & height default to tilemap size
        //guard let width = attributes["width"] else { return nil }
        //guard let height = attributes["height"] else { return nil }
        
        self.tiles = TilesArray(columns: Int(tileMap.mapSize.width), rows: Int(tileMap.mapSize.height))
        super.init(layerName: layerName, tileMap: tileMap)
        self.offset = offset        
        
        // set the visibility property
        if let visibility = attributes["visible"] {
            self.visible = Bool(Int(visibility)!)
        }
        
        // set layer opacity
        if let layerOpacity = attributes["opacity"] {
            self.opacity = CGFloat(Double(layerOpacity)!)
        }
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
    public func setLayerData(data: [Int]) -> Bool {
        if !(data.count==mapSize.count) {
            print("[SKTileLayer]: ERROR: invalid data size: \(data.count), expected: \(mapSize.count)")
            return false
        }

        for index in data.indices {
            let gid = data[index]
            
            // skip empty tiles
            if (gid == 0) { continue }
            
            let xpos = index % Int(mapSize.width)
            let ypos = index / Int(mapSize.width)
            
            let tile = addTileAtCoord(xpos, y: ypos, gid: gid)
        }
        return true
    }
    
    /**
     Add a tile at the given coordinate.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - parameter gid: `Int` tile id.
     
     - returns: `SKTile?` tile.
     */
    public func addTileAtCoord(x: Int, y: Int, gid: Int) -> SKTile? {
        //let zDelta = tilemap.zDeltaForLayers
        if let tileData = tilemap.getTileData(gid) {
            let tile = SKTile(data: tileData)
            self.tiles[Int(x), Int(y)] = tile
            
            // add the coordinate methods from TileSprite
            //tile.position = CGPointMake(CGFloat(x) * tilemap.tileSize.width, CGFloat(y) * tilemap.tileSize.height)
            tile.position = tilemap.pointForCoordinate(x, y: y)
            //tile.zPosition = CGFloat(index) * zDelta
            addChild(tile)
            return tile
        }
        return nil
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
        
        // set the visibility property
        if let visibility = attributes["visible"] {
            self.visible = Bool(Int(visibility)!)
        }
        
        // set layer opacity
        if let layerOpacity = attributes["opacity"] {
            self.opacity = CGFloat(Double(layerOpacity)!)
        }
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
        
        super.init(layerName: layerName, tileMap: tileMap)
        self.offset = offset
        
        // set the visibility property
        if let visibility = attributes["visible"] {
            self.visible = Bool(Int(visibility)!)
        }
        
        // set layer opacity
        if let layerOpacity = attributes["opacity"] {
            self.opacity = CGFloat(Double(layerOpacity)!)
        }
    }
    
    public func setLayerImage(named: String) {
        let texture = SKTexture(imageNamed: named)
        texture.filteringMode = .Nearest
        self.sprite = SKSpriteNode(texture: texture)
        addChild(self.sprite!)
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

