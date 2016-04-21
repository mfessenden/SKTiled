//
//  SKTileLayer.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit

// tile layer:     name, visible, opacity, offsetx, offsety
// objects layer: +color, drawing order (manual, top down)
// image layer:   + image, transparent color, x, y
protocol TiledLayerObject: class, Hashable {
    // tile layer: name, visible, opacity, offset
    //var name: String { get set }
    var visible: Bool { get set }
    var opacity: CGFloat { get set }
    var offset: CGPoint { get set }
    
    var size: CGSize { get set }
    
    var index: Int { get set }
    weak var tilemap: SKTilemap! { get set }
    var hashValue: Int { get }
}


// represents a tile map layer
public class SKTileLayer: SKNode, TiledLayerObject {
    
    private typealias TilesArray = Array2D<Tile>
    
    weak public var tilemap: SKTilemap!
    public var properties: [String: String] = [:]
    
    // layer size
    public var size: CGSize
    public var visible: Bool = true
    public var opacity: CGFloat = 1.0
    public var offset: CGPoint
    public var index: Int = 1
    
    // container for the tile sprites
    private var tiles: TilesArray
    
    public init(name: String, tilemap: SKTilemap, offset: CGPoint=CGPointZero) {
        self.tilemap = tilemap
        self.offset = offset
        self.size = CGSizeMake(tilemap.mapSize.width, tilemap.mapSize.height)
        self.tiles = TilesArray(columns: Int(tilemap.mapSize.width), rows: Int(tilemap.mapSize.height))
        super.init()
        self.name = name
    }

    public init?(name: String, tilemap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero) {
        // name, width and height are required
        guard let layerName = attributes["name"] as String! else { return nil }
        guard let width = attributes["width"] as String! else { return nil }
        guard let height = attributes["height"] as String! else { return nil }
        // opacity,
        
        self.tilemap = tilemap
        self.offset = offset
        self.size = CGSizeMake(CGFloat(Int(width)!), CGFloat(Int(height)!))
        self.tiles = TilesArray(columns: Int(tilemap.mapSize.width), rows: Int(tilemap.mapSize.height))
        super.init()
        self.name = layerName
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var hashValue: Int {
        return self.name!.hashValue
    }
}


