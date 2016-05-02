//
//  SKTileset.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//
//  Reference:  http://doc.mapeditor.org/reference/tmx-map-format/


import SpriteKit

// Tileset tag in tmx (inline):
// <tileset firstgid="1" name="Roguelike" tilewidth="16" tileheight="16" spacing="1" tilecount="1767" columns="57">

// Tileset tag in tmx (external):
// <tileset firstgid="1" source="msp1-spritesheet-8x8.tsx"/>


// tileset tag in tsx
// <tileset name="msp-spritesheet1-8x8" tilewidth="8" tileheight="8" spacing="1" tilecount="176" columns="22">
public class SKTileset {
    
    public var name: String
    weak public var tilemap: SKTilemap!
    public var tileSize: TileSize!
    
    public var columns: Int = 0                     // number of columns
    public var firstGID: Int = 1                    // first GID
    
    // image spacing
    public var spacing: Int = 0                     // spacing between tiles
    public var margin: Int = 0                      // border margin
    
    public var properties: [String: String] = [:]
    public var offset: CGPoint                      // check this...forget if TileSet has offset
    
    // texture
    public var source: String!                      // texture (if created from source)
    public var atlas: SKTextureAtlas!               // texture atlas
    
    // tile data
    public var tileData: Set<SKTilesetData> = []    // tile data attributes
    
    public init(name: String, tilemap: SKTilemap, columns: Int=0, offset: CGPoint=CGPointZero) {
        self.name = name
        self.tilemap = tilemap
        self.tileSize = tilemap.tileSize
        self.columns = columns
        self.offset = offset
    }
    
    
    /**
     Initialize from an external tileset
     
     - parameter source:   `String` source file name.
     - parameter firstgid: `Int` first GID value.
     - parameter tilemap:  `SKTilemap` parent tile map node.
     
     - returns: `SKTileset` tile set.
     */
    public init(source: String, firstgid: Int, tilemap: SKTilemap) {
        let basename = source.componentsSeparatedByString("/").last!
        self.name = basename.componentsSeparatedByString(".")[0]
        self.firstGID = firstgid
        self.tilemap = tilemap
        self.offset = CGPointZero
    }
    
    /**
     Initialize with attributes directly from tmx file.
     
     - parameter attributes: `[String: String]` attributes dictionary.
     - parameter offset:     `CGPoint` offset in x/y.
     */
    public init?(attributes: [String: String], offset: CGPoint=CGPointZero){
        // name, width and height are required
        guard let layerName = attributes["name"] else { return nil }
        guard let firstgid = attributes["firstgid"] else { return nil }
        guard let width = attributes["tilewidth"] else { return nil }
        guard let height = attributes["tileheight"] else { return nil }
        guard let columns = attributes["columns"] else { return nil }
        
        // optionals
        if let spacing = attributes["spacing"] {
            self.spacing = Int(spacing)!
        }
        
        if let margins = attributes["margin"] {
            self.margin = Int(margins)!
        }
        
        self.name = layerName
        self.firstGID = Int(firstgid)!
        self.tileSize = TileSize(width: CGFloat(Int(width)!), height: CGFloat(Int(width)!))
        self.columns = Int(columns)!
        self.offset = offset
    }
    
    // MARK: - Textures
    
    /**
     Add tile data from a sprite sheet image.
     
     - parameter source: `String` image named referenced in the tileset.
     */
    public func addTextures(fromSpriteSheet source: String) {
        
        self.source = source
        print("[SKTileset]: adding sprite sheet source: \"\(self.source)\"")
        
        let sourceTexture = SKTexture(imageNamed: self.source)
        sourceTexture.filteringMode = .Nearest
        //print("  -> texture size: \(sourceTexture.size())")
        let textureWidth = Int(sourceTexture.size().width)
        let textureHeight = Int(sourceTexture.size().height)
        
        // calculate the number of tiles in the texture
        let marginReal = margin * 2
        let rowTileCount = (textureHeight - marginReal + spacing) / (Int(tileSize.height) + spacing)  // number of tiles (height)
        let colTileCount = (textureWidth - marginReal + spacing) / (Int(tileSize.width) + spacing)    // number of tiles (width)
        
        let totalTileCount = colTileCount * rowTileCount
        
        //print("  -> tiles: \(totalTileCount), columns: \(colTileCount), rows: \(rowTileCount), firstGID: \(firstGID)")
        //print("  -> margin: \(margin), spacing: \(spacing)")
        
        let rowHeight = Int(tileSize.height) * rowTileCount     // row height (minus spacing)
        let rowSpacing = spacing * (rowTileCount - 1)           // actual row spacing
        
        // initial x/y coordinates
        var x = margin
        // invert the y-coord
        var y = margin + rowHeight + rowSpacing - Int(tileSize.height)
        
        // column = x, row = y
        var row: Int = 0
        var column: Int = 0
        
        for gid in firstGID..<(firstGID + totalTileCount) {
            
            let rectStartX = CGFloat(x) / CGFloat(textureWidth)
            // 64.0 / 56.0
            let rectStartY = CGFloat(y) / CGFloat(textureHeight)
            
            let rectWidth = tileSize.width / CGFloat(textureWidth)
            let rectHeight = tileSize.height / CGFloat(textureHeight)
            
            // create texture rectangle
            let tileRect = CGRect(x: rectStartX, y: rectStartY, width: rectWidth, height: rectHeight)
            let tileTexture = SKTexture(rect: tileRect, inTexture: sourceTexture)
            
            // add the tile data properties
            addTilesetTile(gid, texture: tileTexture)
            
            x += Int(tileSize.width) + spacing
            if x >= textureWidth {
                x = margin
                y -= Int(tileSize.height) + spacing
            }
        }
    }
    
    public func addTextures(fromAtlas: String) {
        print("[SKTileset]: adding texture atlas: \"\(fromAtlas)\"")
        atlas = SKTextureAtlas(named: fromAtlas)
    }
    
    // MARK: - Tile Data
    
    /**
     Add tileset data attributes.
     
     - parameter tileID:  `Int` tile ID
     - parameter texture: `SKTexture` texture for tile at the given id.
     */
    public func addTilesetTile(tileID: Int, texture: SKTexture) -> SKTilesetData? {
        // TODO: clean up
        guard !(self.tileData.contains( { $0.hashValue == tileID.hashValue } )) else {
            print("[SKTileset]: tile data exists at id: \(tileID)")
            return nil
        }
        
        let data = SKTilesetData(tileId: tileID, texture: texture, tileSet: self)
        self.tileData.insert(data)
        return data
    }
    
    /**
     Returns tile data for the given tile ID.
     
     ** Tiled ID == GID + 1
     
     - parameter byID: `Int` tile GID
     
     - returns: `SKTilesetData?` tile data object.
     */
    public func getTileData(gid: Int) -> SKTilesetData? {
        if let index = tileData.indexOf( { $0.id == gid } ) {
            return tileData[index]
        }
        return nil
    }
}


public func ==(lhs: SKTileset, rhs: SKTileset) -> Bool{
    return (lhs.hashValue == rhs.hashValue)
}


// Hashable requires == func & hashValue: Int
extension SKTileset: Hashable {
    
    public var hashValue: Int {
        return name.hashValue
    }
}


extension SKTileset: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Tile Set: \"\(name)\" @ \(tileSize), firstgid: \(firstGID), \(tileData.count) tiles"
    }
    
    public var debugDescription: String {
        return description
    }
}

