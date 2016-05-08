//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public class SKTilemap: SKNode {
    
    public var mapSize: MapSize
    public var orientation: TilemapOrientation!
    // current tile sets
    public var tileSets: Set<SKTileset> = []
    
    // current layers
    public var tileLayers: Set<TiledLayerObject> = []
    public var properties: [String: String] = [:]
    public var zDeltaForLayers: CGFloat = 50
    
    // debugging
    public var debugLabel: SKLabelNode!
    public var debugColor: SKColor = SKColor(red: 0, green: 1, blue: 0, alpha: 1)
    public var visualizeGrid: Bool = false {
        didSet {
            guard oldValue != visualizeGrid else { return }
        }
    }
    
    // emulate size & anchor point
    public var size: CGSize {
        return CGSizeMake((mapSize.width * tileSize.width), (mapSize.height * tileSize.height))
    }
    
    public var anchorPoint: CGPoint {
        return CGPointMake(0.5, 0.5)
    }
    
    public var centerPoint: CGPoint {
        return CGPointMake((self.size.width * anchorPoint.x) * -1, (self.size.height * anchorPoint.y) * -1)
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
        return tileLayers.count > 0 ? tileLayers.map {$0.index}.maxElement()! : 0
    }
    
    // MARK: - Loading
    public class func loadTMX(fileNamed: String) -> SKTilemap? {
        if let tilemap = SKTilemapParser().loadFromFile(fileNamed) {
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
    
    // MARK: - Coordinates
    public func pointForCoordinate(x: Int, y: Int) -> CGPoint {
        // invert the y-coordinate value
        let ry = (Int(mapSize.height) - y) - 1
        let xPos: CGFloat = CGFloat(x * Int(tileSize.width) + Int(anchorPoint.x * tileSize.width))
        let yPos: CGFloat = CGFloat(ry * Int(tileSize.height) + Int(anchorPoint.y * tileSize.height))
        return CGPointMake(xPos, yPos)
    }
    
    // MARK: - Layers
    public func layerNames() -> [String] {
        return tileLayers.flatMap { $0.name }
    }
    
    public func addLayer(layer: TiledLayerObject) {
        layer.index = tileLayers.count > 0 ? lastIndex + 1 : 0
        // debugging
        var layerType = "tile"
        if let _ = layer as? SKObjectGroup { layerType = "object" }
        if let _ = layer as? SKImageLayer { layerType = "image" }
        
        print("[SKTilemap]: adding \(layerType) layer: \"\(layer.name!)\"...")
        tileLayers.insert(layer)
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
        if let index = tileLayers.indexOf( { $0.name == layerName } ) {
            let layer = tileLayers[index]
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
        if let index = tileLayers.indexOf( { $0.uuid == uuid } ) {
            let layer = tileLayers[index]
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
        if let index = tileLayers.indexOf( { $0.index == index } ) {
            let layer = tileLayers[index]
            return layer
        }
        return nil
    }
    
    // position the layer so that it aligns with the anchorpoint.
    private func positionLayer(layer: TiledLayerObject) {
        var layerPosition = CGPointZero
        
        if orientation == .Orthogonal {
            layerPosition.x = -renderSize.width * anchorPoint.x
            layerPosition.y = -renderSize.height * anchorPoint.y
        }
        layer.position = layerPosition
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



extension SKTilemap {
    
    override public var description: String {
        var tilemapName = "(null)"
        if let name = name {
            tilemapName = "\"\(name)\""
        }
        return "Tilemap: \(tilemapName), \(mapSize)"
    }
    
    override public var debugDescription: String {
        return description
    }
}
