//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
import GameplayKit


public class SKTilemap: SKNode {
    
    public var mapSize: MapSize
    public var tileSize: TileSize
    public var orientation: TilemapOrientation!
    // current tile sets
    public var tileSets: Set<SKTileset> = []
    
    // current layers
    public var tileLayers: Set<SKTileLayer> = []
    public var properties: [String: String] = [:]
    
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
    
    // MARK: - Layers
    public func addLayer(layer: SKTileLayer) {
        tileLayers.insert(layer)
        // TODO: zPosition
        // TODO: alignment/anchorpoint
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
