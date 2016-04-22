//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
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
    
    public var size: CGSize {
        return CGSizeMake((mapSize.width * tileSize.width), (mapSize.height * tileSize.height))
    }
    
    // MARK: - Loading
    public class func loadTMX(fileNamed: String) -> SKTilemap? {
        if let tilemap = TMXParser().loadFromFile(fileNamed) {
            return tilemap
        }
        return nil
    }
    
    // MARK: - Init
    /**
     Initialize with dictionary attributes from xml parser.
     
     - parameter attributes: `Dictionary` attributes dictionary.
     
     - returns: `SKTilemap?`
     */
    public init?(attributes: [String: String]) {
        guard let width = attributes["width"] as String! else { return nil }
        guard let height = attributes["height"] as String! else { return nil }
        guard let tilewidth = attributes["tilewidth"] as String! else { return nil }
        guard let tileheight = attributes["tileheight"] as String! else { return nil }
        guard let orient = attributes["orientation"] as String! else { return nil }

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
    
    // MARK: - Layers
    public func addTileLayer(layer: TiledLayerObject) {
        print("[SKTilemap]: adding layer: \"\(layer.name!)\"")
        tileLayers.insert(layer)
        // TODO: zPosition
        // TODO: alignment/anchorpoint
    }
    
    /**
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer to query.
     
     - returns: `SKTileLayer?` tile layer object.
     */
    public func getTileLayer(name: String) -> TiledLayerObject? {
        if let index = tileLayers.indexOf( { $0.name == name } ) {
            let layer = tileLayers[index]
            return layer
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