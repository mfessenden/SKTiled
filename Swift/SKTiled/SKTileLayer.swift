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
    public var uuid: Int = 0
    public var visible: Bool = true
    public var opacity: CGFloat = 1.0
    public var offset: CGPoint = CGPointZero
    
    // generic layer properties
    public var properties: [String: String] = [:]
    
    public init(layerName: String, tileMap: SKTilemap){
        self.tilemap = tileMap
        super.init()
        self.name = layerName
    }
    
    required public  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var hashValue: Int {
        return self.name!.hashValue
    }
}


// represents a tile map layer
public class SKTileLayer: TiledLayerObject {
    
    private typealias TilesArray = Array2D<SKTile>
    
    // layer size
    public var size: CGSize
    public var index: Int = 1
    
    // container for the tile sprites
    private var tiles: TilesArray
    
    override public init(layerName: String, tileMap: SKTilemap) {
        self.size = tileMap.mapSize.cgSize
        self.tiles = TilesArray(columns: Int(tileMap.mapSize.width), rows: Int(tileMap.mapSize.height))
        super.init(layerName: layerName, tileMap: tileMap)
    }

    public init?(tileMap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero) {
        // name, width and height are required
        // TODO: according to tmx file format, width & height default to tilemap size
        guard let layerName = attributes["name"] as String! else { return nil }
        guard let width = attributes["width"] as String! else { return nil }
        guard let height = attributes["height"] as String! else { return nil }
        
        self.size = CGSizeMake(CGFloat(Int(width)!), CGFloat(Int(height)!))
        self.tiles = TilesArray(columns: Int(tileMap.mapSize.width), rows: Int(tileMap.mapSize.height))
        super.init(layerName: layerName, tileMap: tileMap)
        self.offset = offset
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var hashValue: Int {
        return self.name!.hashValue
    }
}

public enum ObjectGroupDrawOrder: String {
    case TopDown
    case Manual
}


/// Objects group class
public class SKObjectGroup: TiledLayerObject {
    
    public var color: SKColor = SKColor.clearColor()
    public var drawOrder: ObjectGroupDrawOrder = ObjectGroupDrawOrder.TopDown
    private var objects: Set<SKTileObject> = []
    
    public init?(tileMap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero) {
        guard let layerName = attributes["name"] as String! else { return nil }
        //guard let width = attributes["width"] as String! else { return nil }
        //guard let height = attributes["height"] as String! else { return nil }

        super.init(layerName: layerName, tileMap: tileMap)
        self.offset = offset
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// Image layer class
public class SKImageLayer: TiledLayerObject {
    public var sprite: SKSpriteNode?
    
    public init?(tileMap: SKTilemap, attributes: [String: String], offset: CGPoint=CGPointZero) {
        guard let layerName = attributes["name"] as String! else { return nil }
        /*
        guard let imageSource = attributes["source"] as String! else { return nil }
        guard let imageWidth = attributes["width"] as String! else { return nil }
        guard let imageHeight = attributes["height"] as String! else { return nil }
        
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
