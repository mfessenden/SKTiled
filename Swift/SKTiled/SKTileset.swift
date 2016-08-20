//
//  SKTileset.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//
//  Reference:  http://doc.mapeditor.org/reference/tmx-map-format/

import SpriteKit


/// Represents tileset data
public class SKTileset: SKTiledObject {
    
    public var name: String                         // tileset name
    public var uuid: String = NSUUID().UUIDString   // unique id
    public var filename: String! = nil              // source filename (external tileset)
    public var tilemap: SKTilemap!
    public var tileSize: CGSize                     // tile size

    public var columns: Int = 0                     // number of columns
    public var tilecount: Int = 0                   // tile count
    public var firstGID: Int = 1                    // first GID
        
    // image spacing
    public var spacing: Int = 0                     // spacing between tiles
    public var margin: Int = 0                      // border margin
    
    public var properties: [String: String] = [:]
    public var tileOffset = CGPointZero             // draw offset for drawing tiles
    
    // texture
    public var source: String!                      // texture (if created from source)
    public var atlas: SKTextureAtlas!               // texture atlas
    
    // tile data
    private var tileData: Set<SKTilesetData> = []   // tile data attributes
    public var dataCount: Int { return tileData.count }
    
    // tileset properties
    public var isImageCollection: Bool = false      // image collection tileset
    public var isExternalTileset: Bool { return filename != nil }
    
    // returns the last GID in the tileset
    public var lastGID: Int {
        var gid = firstGID
        for data in tileData {
            if data.id > gid {
                gid = data.id
            }
        }
        return gid
    }

    /**
     Initialize with basic properties.
     
     - parameter name:     `String` tileset name.
     - parameter size:     `CGSize` tile size.
     - parameter firstgid: `Int` first gid value.
     - parameter columns:  `Int` number of columns.
     - parameter offset:   `CGPoint` tileset offset value.
     
     - returns: `SKTileset` tileset object.
     */
    public init(name: String, tileSize size: CGSize, firstgid: Int=1, columns: Int=0, offset: CGPoint=CGPointZero) {
        self.name = name
        self.tileSize = size
        self.firstGID = firstgid
        self.columns = columns
        self.tileOffset = offset
    }
    
    /**
     Initialize from an external tileset. (only source and first gid are given).
     
     - parameter source:   `String` source file name.
     - parameter firstgid: `Int` first gid value.
     - parameter tilemap:  `SKTilemap` parent tile map node.
     
     - returns: `SKTileset` tile set.
     */
    public init(source: String, firstgid: Int, tilemap: SKTilemap, offset: CGPoint=CGPointZero) {
        let filepath = source.componentsSeparatedByString("/").last!
        self.filename = filepath
        
        self.firstGID = firstgid
        self.tilemap = tilemap
        self.tileOffset = offset
        
        // setting these here, even though it may different later
        self.name = filepath.componentsSeparatedByString(".")[0]
        self.tileSize = tilemap.tileSize
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
        
        if let tileCount = attributes["tilecount"] {
            self.tilecount = Int(tileCount)!
        }
        
        // optionals
        if let spacing = attributes["spacing"] {
            self.spacing = Int(spacing)!
        }
        
        if let margins = attributes["margin"] {
            self.margin = Int(margins)!
        }
        
        self.name = layerName
        self.firstGID = Int(firstgid)!
        self.tileSize = CGSize(width: Int(width)!, height: Int(height)!)
        self.columns = Int(columns)!
        self.tileOffset = offset
    }
    
    // MARK: - Textures
    
    /**
     Add tile data from a sprite sheet image.
     
     - parameter source: `String` image named referenced in the tileset.
     */
    public func addTextures(fromSpriteSheet source: String) {
        let timer = NSDate()
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
        
        let rowHeight = Int(tileSize.height) * rowTileCount     // row height (minus spacing)
        let rowSpacing = spacing * (rowTileCount - 1)           // actual row spacing
        
        // initial x/y coordinates
        var x = margin
        // invert the y-coord
        var y = margin + rowHeight + rowSpacing - Int(tileSize.height)
        
        for gid in firstGID..<(firstGID + totalTileCount) {
            let rectStartX = CGFloat(x) / CGFloat(textureWidth)
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
        
        // time results
        let timeInterval = NSDate().timeIntervalSinceDate(timer)
        let timeStamp = String(format: "%.\(String(3))f", timeInterval)
        print("[SKTileset]: tileset built in: \(timeStamp)s\n")
    }
    
    // TODO: - Need this?
    public func addTextures(fromAtlas: String) {
        print("[SKTileset]: adding texture atlas: \"\(fromAtlas)\"")
        atlas = SKTextureAtlas(named: fromAtlas)
        guard atlas.textureNames.count == tilemap.size.count else {
            fatalError("")
        }
    }
    
    // MARK: - Tile Data
    
    /**
     Add tileset data attributes.
     
     - parameter tileID:  `Int` tile ID.
     - parameter texture: `SKTexture` texture for tile at the given id.
     
     - returns: `SKTilesetData?` tileset data (or nil if the data exists).
     */
    public func addTilesetTile(tileID: Int, texture: SKTexture) -> SKTilesetData? {
        guard !(self.tileData.contains( { $0.hashValue == tileID.hashValue } )) else {
            print("[SKTileset]: tile data exists at id: \(tileID)")
            return nil
        }
        
        let data = SKTilesetData(tileId: tileID, texture: texture, tileSet: self)
        self.tileData.insert(data)
        data.parseProperties()
        return data
    }
    
    /**
     Add tileset data from an image source (tileset is a collections tileset).
     
     - parameter tileID: `Int` tile ID.
     - parameter source: `String` source image name.
     
     - returns: `SKTilesetData?` tileset data (or nil if the data exists).
     */
    public func addTilesetTile(tileID: Int, source: String) -> SKTilesetData? {
        guard !(self.tileData.contains( { $0.hashValue == tileID.hashValue } )) else {
            print("[SKTileset]: tile data exists at id: \(tileID)")
            return nil
        }
        // bundled images shouldn't have file paths
        //let imageName = source.componentsSeparatedByString("/").last!
        
        isImageCollection = true
        let texture = SKTexture(imageNamed: source)
        
        texture.filteringMode = .Nearest
        let data = SKTilesetData(tileId: tileID, texture: texture, tileSet: self)
        
        // add the image name to the source attribute
        data.source = source
        self.tileData.insert(data)
        data.parseProperties()
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
    
    /**
     Convert a global ID to the tileset's local ID (or -1 if invalid).
     
     - parameter id: `Int` global id.
     
     - returns: `Int` local tile ID.
     */
    public func getLocalID(forGlobalID id: Int) -> Int {
        return (id - firstGID) > 0 ? (id - firstGID) : -1
    }
    
    /**
     Print out tileset data values.
     */
    public func debugTileset(){
        for data in tileData.sort({$0.id < $1.id}) {
            print(data.description)
        }
    }
}


public func ==(lhs: SKTileset, rhs: SKTileset) -> Bool{
    return (lhs.hashValue == rhs.hashValue)
}


// Hashable requires == & hashValue: Int
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


