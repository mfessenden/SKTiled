//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit

import SpriteKit
import GameplayKit


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
        return CGSizeMake(mapSize.width * tileSize.width, mapSize.height * tileSize.height)
    }
    
    // returns the last GID for all of the tilesets.
    public var lastGID: Int {
        var lastID = 0
        for tileset in tileSets {
            if tileset.lastGID > lastID {
                lastID = tileset.lastGID
            }
        }
        return lastID + 1
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
     
     - returns: `SKTilemap?`
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
        // debugging
        var layerType = "tile"
        if let _ = layer as? SKObjectGroup { layerType = "object" }
        if let _ = layer as? SKImageLayer { layerType = "image" }
        
        print("[SKTilemap]: adding \(layerType) layer: \"\(layer.index):\(layer.name!)\"")
        tileLayers.insert(layer)
        addChild(layer)
        positionLayer(layer)
        //layer.zPosition = zDeltaForLayers * CGFloat(layer.index)
    }
    
    // position the layer so that it aligns with the anchorpoint.
    private func positionLayer(layer: TiledLayerObject) {
        var layerPosition = CGPointZero
        if orientation == .Orthogonal {
            // -608 * 0.5 = -304
            layerPosition.x = -renderSize.width * anchorPoint.x
            // 608 - (0.5 * 608) = 304
            layerPosition.y = -renderSize.height * anchorPoint.y
        }
        
        layer.position = layerPosition
    }
    
    /**
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer to return.
     
     - returns: `SKTileLayer?` tile layer object.
     */
    public func getLayer(named: String) -> TiledLayerObject? {
        if let index = tileLayers.indexOf( { $0.name == named } ) {
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
        var tilemapName = "(null)"
        if let name = name {
            tilemapName = "\"\(name)\""
        }
        return "Tilemap: \(tilemapName), \(mapSize) @ \(tileSize)"
    }
    
    override public var debugDescription: String {
        return description
    }
}
