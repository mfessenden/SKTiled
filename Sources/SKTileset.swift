//
//  SKTileset.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//
//  Reference:  http://doc.mapeditor.org/reference/tmx-map-format/

import SpriteKit


/**
 The `SKTileset` class manages a set of `SKTilesetData` objects, which store tile data including global id and texture.
 
 Tile data is accessed via the global id ('gid'):
 
 ```swift
 let data = tileset.getTileData(56)
 let tile = SKTile(data: data)
 ```
 */
open class SKTileset: SKTiledObject {
    
    open var name: String                                        // tileset name
    open var uuid: String = UUID().uuidString                    // unique id
    open var filename: String! = nil                             // source filename (external tileset)
    open var tilemap: SKTilemap!
    open var tileSize: CGSize                                    // tile size

    open var columns: Int = 0                                    // number of columns
    open var tilecount: Int = 0                                  // tile count
    open var firstGID: Int = 1                                   // first GID
        
    // image spacing
    open var spacing: Int = 0                                    // spacing between tiles
    open var margin: Int = 0                                     // border margin
    
    open var properties: [String: String] = [:]
    open var tileOffset = CGPoint.zero                           // draw offset for drawing tiles
    
    // texture
    open var source: String!                                     // texture (if created from source)
    open var atlas: SKTextureAtlas!                              // texture atlas
    
    // tile data
    private var tileData: Set<SKTilesetData> = []                // tile data attributes
    open var dataCount: Int { return tileData.count }
    
    // tileset properties
    open var isImageCollection: Bool = false                     // image collection tileset
    open var isExternalTileset: Bool { return filename != nil }  // tileset is an external file
    open var transparentColor: SKColor = SKColor.clear           // sprite transparency color
    open var isRendered: Bool = false                            // indicates the tileset is rendered
    
    /// Returns the last GID in the tileset
    open var lastGID: Int { return tileData.map { $0.id }.max() ?? firstGID }
    
    /**
     Initialize with basic properties.
     
     - parameter name:     `String` tileset name.
     - parameter size:     `CGSize` tile size.
     - parameter firstgid: `Int` first gid value.
     - parameter columns:  `Int` number of columns.
     - parameter offset:   `CGPoint` tileset offset value.
     - returns: `SKTileset` tileset object.
     */
    public init(name: String, tileSize size: CGSize, firstgid: Int=1, columns: Int=0, offset: CGPoint=CGPoint.zero) {
        self.name = name
        self.tileSize = size
        self.firstGID = firstgid
        self.columns = columns
        self.tileOffset = offset
    }
    
    /**
     Initialize with an external tileset (only source and first gid are given).
     
     - parameter source:   `String` source file name.
     - parameter firstgid: `Int` first gid value.
     - parameter tilemap:  `SKTilemap` parent tile map node.
     - returns: `SKTileset` tile set.
     */
    public init(source: String, firstgid: Int, tilemap: SKTilemap, offset: CGPoint=CGPoint.zero) {
        let filepath = source.components(separatedBy: "/").last!
        self.filename = filepath
        
        self.firstGID = firstgid
        self.tilemap = tilemap
        self.tileOffset = offset
        
        // setting these here, even though it may different later
        self.name = filepath.components(separatedBy: ".")[0]
        self.tileSize = tilemap.tileSize
    }
    
    /**
     Initialize with attributes directly from TMX file.
     
     - parameter attributes: `[String: String]` attributes dictionary.
     - parameter offset:     `CGPoint` offset in x/y.
     */
    public init?(attributes: [String: String], offset: CGPoint=CGPoint.zero){
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
     Add tile texture data from a sprite sheet image.
     
     - parameter source:  `String` image named referenced in the tileset.
     - parameter replace: `Bool` replace the current texture.
     */
    open func addTextures(fromSpriteSheet source: String, replace: Bool = false) {
        // images are stored in separate directories in the project will render incorrectly unless we use just the filename
        let sourceFilename = source.components(separatedBy: "/").last!
        let timer = Date()
        self.source = sourceFilename
        
        let sourceTexture = SKTexture(imageNamed: self.source!)
        let textureSize = sourceTexture.size()
        
        sourceTexture.filteringMode = .nearest
        
        let actionName: String = (replace == false) ? "adding" : "replacing"
        print("[SKTileset]: \(actionName) sprite sheet source: \"\(self.source!)\": (\(Int(textureSize.width)) x \(Int(textureSize.height)))")
        
        let textureWidth = Int(sourceTexture.size().width)
        let textureHeight = Int(sourceTexture.size().height)
        
        // calculate the number of tiles in the texture
        let marginReal = margin * 2
        let rowTileCount = (textureHeight - marginReal + spacing) / (Int(tileSize.height) + spacing)  // number of tiles (height)
        let colTileCount = (textureWidth - marginReal + spacing) / (Int(tileSize.width) + spacing)    // number of tiles (width)
        
        // tile count
        let totalTileCount = colTileCount * rowTileCount
        tilecount = tilecount > 0 ? tilecount : totalTileCount
        
        let rowHeight = Int(tileSize.height) * rowTileCount     // row height (minus spacing)
        let rowSpacing = spacing * (rowTileCount - 1)           // actual row spacing
        
        // initial x/y coordinates
        var x = margin
        // invert the y-coord
        var y = margin + rowHeight + rowSpacing - Int(tileSize.height)
        
        var tilesAdded: Int = 0
        for gid in self.firstGID..<(self.firstGID + totalTileCount) {
            let rectStartX = CGFloat(x) / CGFloat(textureWidth)
            let rectStartY = CGFloat(y) / CGFloat(textureHeight)
            
            let rectWidth = self.tileSize.width / CGFloat(textureWidth)
            let rectHeight = self.tileSize.height / CGFloat(textureHeight)
            
            // create texture rectangle
            let tileRect = CGRect(x: rectStartX, y: rectStartY, width: rectWidth, height: rectHeight)
            let tileTexture = SKTexture(rect: tileRect, in: sourceTexture)
            
            // add the tile data properties, or replace the texture
            if replace == false {
                let _ = self.addTilesetTile(gid, texture: tileTexture)
            } else {
                self.setDataTexture(gid, texture: tileTexture)
            }
            
            x += Int(self.tileSize.width) + self.spacing
            if x >= textureWidth {
                x = self.margin
                y -= Int(self.tileSize.height) + self.spacing
            }
            
            tilesAdded += 1
        }
        
        self.isRendered = true
        
        // time results
        if replace == false {
            let timeInterval = Date().timeIntervalSince(timer)
            let timeStamp = String(format: "%.\(String(3))f", timeInterval)
            print("[SKTileset]: tileset \"\(name)\" built in: \(timeStamp)s (\(tilesAdded) tiles)")
        }
    }
    
    // MARK: - Tile Data
    
    /**
     Add tileset data attributes.
     
     - parameter tileID:  `Int` tile ID.
     - parameter texture: `SKTexture` texture for tile at the given id.
     - returns: `SKTilesetData?` tileset data (or nil if the data exists).
     */
    open func addTilesetTile(_ tileID: Int, texture: SKTexture) -> SKTilesetData? {
        guard !(self.tileData.contains( where: { $0.hashValue == tileID.hashValue } )) else {
            print("[SKTileset]: tile data exists at id: \(tileID)")
            return nil
        }
        
        let data = SKTilesetData(id: tileID, texture: texture, tileSet: self)
        self.tileData.insert(data)
        data.parseProperties(completion: nil)
        return data
    }
    
    /**
     Add tileset data from an image source (tileset is a collections tileset).
     
     - parameter tileID: `Int` tile ID.
     - parameter source: `String` source image name.
     - returns: `SKTilesetData?` tileset data (or nil if the data exists).
     */
    open func addTilesetTile(_ tileID: Int, source: String) -> SKTilesetData? {
        guard !(self.tileData.contains( where: { $0.hashValue == tileID.hashValue } )) else {
            print("[SKTileset]: tile data exists at id: \(tileID)")
            return nil
        }
        // bundled images shouldn't have file paths
        //let imageName = source.componentsSeparatedByString("/").last!
        
        isImageCollection = true
        let texture = SKTexture(imageNamed: source)
        
        texture.filteringMode = .nearest
        let data = SKTilesetData(id: tileID, texture: texture, tileSet: self)
        
        // add the image name to the source attribute
        data.source = source
        self.tileData.insert(data)
        data.parseProperties(completion: nil)
        return data
    }
    
    /**
     Set(replace) the texture for a given tile gid.
     
     - parameter tileID:  `Int` tile ID.
     - parameter texture: `SKTexture` texture for tile at the given id.
     */
    open func setDataTexture(_ tileID: Int, texture: SKTexture) {
        guard let data = getTileData(tileID) else {
            print("[SKTileset]: tile data not found for id: \(tileID)")
            return
        }
        data.texture = texture
    }
    
    /**
     Returns tile data for the given tile ID.
     
     ** Tiled ID == GID + 1
     
     - parameter byID: `Int` tile GID
     - returns: `SKTilesetData?` tile data object.
     */
    open func getTileData(_ gid: Int) -> SKTilesetData? {
        let id = getTileRealID(id: gid)
        if let index = tileData.index( where: { $0.id == id } ) {
            return tileData[index]
        }
        return nil
    }
    
    /**
     Returns tile data with the given property.
     
     - parameter withProperty: `String` property name.
     - returns: `[SKTilesetData]` array of tile data.
     */
    open func getTileData(withProperty property: String) -> [SKTilesetData] {
        return tileData.filter { $0.properties[property] != nil }
    }
    
    /**
     Returns tile data with the given property.
     
     - parameter property: `String` property name.
     - parameter value:    `AnyObject` value
     - returns: `[SKTilesetData]` array of tile data.
     */
    open func getTileData(_ property: String, _ value: AnyObject) -> [SKTilesetData] {
        var result: [SKTilesetData] = []
        let tiledata = getTileData(withProperty: property)
        for data in tiledata {
            if data.stringForKey(property)! == value as! String {
                result.append(data)
            }
        }
        return result
    }
    
    /**
     Convert a global ID to the tileset's local ID (or -1 if invalid).
     
     - parameter id: `Int` global id.
     - returns: `Int` local tile ID.
     */
    open func getLocalID(forGlobalID id: Int) -> Int {
        return (id - firstGID) > 0 ? (id - firstGID) : -1
    }
    
    
    /**
     Check for tile ID flip flags.
     
     - parameter id: `Int` tile ID.
     - returns: `Int` translated ID.
     */
    internal func getTileRealID(id: Int) -> Int {
        let uid: UInt32 = UInt32(id)
        // masks for tile flipping
        let flippedDiagonalFlag: UInt32   = 0x20000000
        let flippedVerticalFlag: UInt32   = 0x40000000
        let flippedHorizontalFlag: UInt32 = 0x80000000
        
        let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
        let flippedMask = ~(flippedAll)
        
        // get the actual gid from the mask
        let gid = uid & flippedMask
        return Int(gid)
    }
    
    /**
     Print out tileset data values.
     */
    internal func debugTileset(){
        print("# Tileset: \"\(name)\":")
        for data in tileData.sorted(by: {$0.id < $1.id}) {
            if data.hasProperties {
                print(data.description)
            }
        }
    }
}


public func ==(lhs: SKTileset, rhs: SKTileset) -> Bool {
    return (lhs.hashValue == rhs.hashValue)
}


extension SKTileset: Hashable {
    public var hashValue: Int { return name.hashValue }
}


extension SKTileset: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Tile Set: \"\(name)\" @ \(tileSize), firstgid: \(firstGID), \(dataCount) tiles"
    }
    
    public var debugDescription: String { return description }
}
