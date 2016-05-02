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
    public var tileSize: TileSize
    public var orientation: TilemapOrientation!
    // current tile sets
    public var tileSets: Set<SKTileset> = []
    
    // current layers
    public var tileLayers: Set<TiledLayerObject> = []
    public var properties: [String: String] = [:]
    
    public var zDeltaForLayers: CGFloat = 50
    
    public var size: CGSize {
        return CGSizeMake((mapSize.width * tileSize.width), (mapSize.height * tileSize.height))
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
        
        mapSize = MapSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))
        tileSize = TileSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
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
        return tileLayers.flatMap { $0.name }
    }
    
    public func addTileLayer(layer: TiledLayerObject) {
        // debugging
        var layerType = "tile"
        if let _ = layer as? SKObjectGroup { layerType = "object" }
        if let _ = layer as? SKImageLayer { layerType = "image" }
        
        print("[SKTilemap]: adding \(layerType) layer: \"\(layer.name!)\" at index \(layer.index)")
        tileLayers.insert(layer)
        // TODO: zPosition
        // TODO: alignment/anchorpoint
    }
    
    /**
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer to return.
     
     - returns: `SKTileLayer?` tile layer object.
     */
    public func getTileLayer(name: String) -> TiledLayerObject? {
        if let index = tileLayers.indexOf( { $0.name == name } ) {
            let layer = tileLayers[index]
            return layer
        }
        return nil
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
        if let name = name {
            return "Tilemap: \"\(name)\", \(mapSize)"
        }
        return "Tilemap: (null), \(mapSize)"
    }
    
    override public var debugDescription: String {
        return description
    }
}
