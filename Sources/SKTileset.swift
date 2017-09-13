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

 ## Overview ##

 The tileset class manages a set of `SKTilesetData` objects, which store tile data including global id and texture.

 Tile data is accessed via a local id, and tiles can be instantiated with the resulting `SKTilesetData` instance:

 ```swift
 let data = tileset.getTileData(localID: 56)
 let tile = SKTile(data: data)
 ```
 */
public class SKTileset: SKTiledObject {
    /// Tileset url (external tileset).
    public var url: URL!
    /// Tiled tsx filename (external tileset).
    public var filename: String! = nil
    /// Unique object id.
    public var uuid: String = UUID().uuidString
    public var name: String                                        // tileset name (without file extension)
    /// Object type.
    public var type: String!
    /// Reference to parent tilemap.
    public var tilemap: SKTilemap!
    /// Tile size (in pixels).
    public var tileSize: CGSize

    internal var loggingLevel: LoggingLevel = .warning

    public var columns: Int = 0                                    // number of columns
    public var tilecount: Int = 0                                  // tile count
    public var firstGID: Int = 0                                   // first GID

    // image spacing
    public var spacing: Int = 0                                    // spacing between tiles
    public var margin: Int = 0                                     // border margin

    public var properties: [String: String] = [:]
    public var ignoreProperties: Bool = false                      // ignore custom properties
    public var tileOffset = CGPoint.zero                           // draw offset for drawing tiles

    /// Texture name (if created from source)
    public var source: String!

    /// Tile data set.
    private var tileData: Set<SKTilesetData> = []
    /// Tile data count.
    public var dataCount: Int { return tileData.count }

    /// Image collection tileset.
    public var isImageCollection: Bool = false
    /// Tileset is stored in an external file.
    public var isExternalTileset: Bool { return filename != nil }
    /// Source image transparency color.
    public var transparentColor: SKColor?
    public var isRendered: Bool = false

    /// Returns the last GID in the tileset.
    public var lastGID: Int { return tileData.map { $0.id }.max() ?? firstGID }

    /// Returns the difference in tile size vs. map tile size.
    internal var mapOffset: CGPoint {
        guard let tilemap = tilemap else { return .zero }
        return CGPoint(x: tileSize.width - tilemap.tileSize.width, y: tileSize.height - tilemap.tileSize.height)
    }

    /// Render scaling property.
    public var renderQuality: CGFloat = 8 {
        didSet {
            guard renderQuality != oldValue else { return }
            tileData.forEach { $0.renderQuality = renderQuality }
        }
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
        self.ignoreProperties = tilemap.ignoreProperties
    }

    /**
     Initialize with attributes directly from TMX file.

     - parameter attributes: `[String: String]` attributes dictionary.
     - parameter offset:     `CGPoint` offset in x/y.
     */
    public init?(attributes: [String: String], offset: CGPoint=CGPoint.zero) {
        // name, width and height are required
        guard let setName = attributes["name"],
            let width = attributes["tilewidth"],
            let height = attributes["tileheight"] else {
                return nil
        }

        // columns is optional in older maps
        if let columnCount = attributes["columns"] {
            self.columns = Int(columnCount)!
        }

        // first gid won't be in an external tileset
        if let firstgid = attributes["firstgid"] {
            self.firstGID = Int(firstgid)!
        }

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

        self.name = setName
        self.tileSize = CGSize(width: Int(width)!, height: Int(height)!)
        self.tileOffset = offset
    }

    /**
     Initialize with a TSX file name.

     - parameter fileNamed: `String` tileset file name.
     */
    public init(fileNamed: String) {
        self.name = ""
        self.tileSize = CGSize.zero
    }

    // MARK: - Loading
    /**
     Loads Tiled tsx files and returns an array of `SKTileset` objects.

     - parameter tsxFiles:         `[String]` Tiled tileset filenames.
     - parameter delegate:          `SKTilemapDelegate?` optional [`SKTilemapDelegate`](Protocols/SKTilemapDelegate.html) instance.
     - parameter ignoreProperties:  `Bool` ignore custom properties from Tiled.
     - returns: `[SKTileset]` tileset objects.
     */
    public class func load(tsxFiles: [String],
                           delegate: SKTilemapDelegate? = nil,
                           ignoreProperties noparse: Bool = false) -> [SKTileset] {

        let startTime = Date()
        let queue = DispatchQueue(label: "com.sktiled.renderqueue", qos: .userInteractive)
        let tilesets = SKTilemapParser().load(tsxFiles: tsxFiles, delegate: delegate, ignoreProperties: noparse, renderQueue: queue)
        let renderTime = Date().timeIntervalSince(startTime)
        let timeStamp = String(format: "%.\(String(3))f", renderTime)
        Logger.default.log("\(tilesets.count) tilesets rendered in: \(timeStamp)s", level: .success)
        return tilesets
    }

    // MARK: - Textures

    /**
     Add tile texture data from a sprite sheet image.

     - parameter source:      `String` image named referenced in the tileset.
     - parameter replace:     `Bool` replace the current texture.
     - parameter transparent: `String?` optional transparent color hex value.
     */
    public func addTextures(fromSpriteSheet source: String, replace: Bool=false, transparent: String?=nil) {
        let timer = Date()
        self.source = source

        // parse the transparent color (NYI)
        if let transparent = transparent {
            transparentColor = SKColor(hexString: transparent)
        }

        let inputURL = URL(fileURLWithPath: self.source!)
        // read image from file
        let imageDataProvider = CGDataProvider(url: inputURL as CFURL)!
        // creare a data provider
        let image = CGImage(pngDataProviderSource: imageDataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!

        // create the texture
        let sourceTexture = SKTexture(cgImage: image)
        sourceTexture.filteringMode = .nearest

        let textureWidth = Int(sourceTexture.size().width)
        let textureHeight = Int(sourceTexture.size().height)

        // calculate the number of tiles in the texture
        let marginReal = margin * 2
        let rowTileCount = (textureHeight - marginReal + spacing) / (Int(tileSize.height) + spacing)  // number of tiles (height)
        let colTileCount = (textureWidth - marginReal + spacing) / (Int(tileSize.width) + spacing)    // number of tiles (width)

        // set columns property
        if columns == 0 {
            columns = colTileCount
        }

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

        for tileID in 0..<totalTileCount {
            let rectStartX = CGFloat(x) / CGFloat(textureWidth)
            let rectStartY = CGFloat(y) / CGFloat(textureHeight)

            let rectWidth = self.tileSize.width / CGFloat(textureWidth)
            let rectHeight = self.tileSize.height / CGFloat(textureHeight)

            // create texture rectangle
            let tileRect = CGRect(x: rectStartX, y: rectStartY, width: rectWidth, height: rectHeight)
            let tileTexture = SKTexture(rect: tileRect, in: sourceTexture)
            tileTexture.filteringMode = .nearest

            // add the tile data properties, or replace the texture
            if (replace == false) {
                _ = self.addTilesetTile(tileID, texture: tileTexture)
            } else {
                self.setDataTexture(tileID, texture: tileTexture)
            }

            x += Int(self.tileSize.width) + self.spacing
            if x >= textureWidth {
                x = self.margin
                y -= Int(self.tileSize.height) + self.spacing
            }

            tilesAdded += 1
        }

        self.isRendered = true
        let tilesetBuildTime = Date().timeIntervalSince(timer)

        // time results
        if (replace == false) {
            let timeStamp = String(format: "%.\(String(3))f", tilesetBuildTime)
            Logger.default.cache(LogEvent("tileset \"\(name)\" built in: \(timeStamp)s (\(tilesAdded) tiles)", level: .debug, caller: self.logSymbol))
        }
    }

    // MARK: - Tile Data

    /**
     Add tileset data attributes.

     - parameter tileID:  `Int` local tile ID.
     - parameter texture: `SKTexture` texture for tile at the given id.
     - returns: `SKTilesetData?` tileset data (or nil if the data exists).
     */
    public func addTilesetTile(_ tileID: Int, texture: SKTexture) -> SKTilesetData? {
        guard !(self.tileData.contains(where: { $0.hashValue == tileID.hashValue })) else {
            log("tile data exists at id: \(tileID)", level: .error)
            return nil
        }

        texture.filteringMode = .nearest
        let data = SKTilesetData(id: tileID, texture: texture, tileSet: self)
        data.ignoreProperties = ignoreProperties
        self.tileData.insert(data)
        data.parseProperties(completion: nil)
        return data
    }

    /**
     Add tileset data from an image source (tileset is a collections tileset).

     - parameter tileID: `Int` local tile ID.
     - parameter source: `String` source image name.
     - returns: `SKTilesetData?` tileset data (or nil if the data exists).
     */
    public func addTilesetTile(_ tileID: Int, source: String) -> SKTilesetData? {
        guard !(self.tileData.contains(where: { $0.hashValue == tileID.hashValue })) else {
            log("tile data exists at id: \(tileID)", level: .error)
            return nil
        }

        // bundled images shouldn't have file paths
        //let imageName = source.componentsSeparatedByString("/").last!

        isImageCollection = true

        let inputURL = URL(fileURLWithPath: source)
        // read image from file
        let imageDataProvider = CGDataProvider(url: inputURL as CFURL)!
        // create a data provider
        let image = CGImage(pngDataProviderSource: imageDataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let sourceTexture = SKTexture(cgImage: image)
        sourceTexture.filteringMode = .nearest

        let data = SKTilesetData(id: tileID, texture: sourceTexture, tileSet: self)
        data.ignoreProperties = ignoreProperties
        // add the image name to the source attribute
        data.source = source
        self.tileData.insert(data)
        data.parseProperties(completion: nil)
        return data
    }

    /**
     Set(replace) the texture for a given tile id.

     - parameter tileID:  `Int` tile ID.
     - parameter texture: `SKTexture` texture for tile at the given id.
     */
    public func setDataTexture(_ id: Int, texture: SKTexture) {
        guard let data = getTileData(localID: id) else {
            if loggingLevel.rawValue <= 1 {
                log("tile data not found for id: \(id)", level: .error)
            }
            return
        }
        texture.filteringMode = .nearest
        data.texture = texture
    }

    /**
     Returns true if the tileset contains the global ID.

     - parameter globalID:  `UInt32` global tile id.
      - returns: `Bool` tileset contains the global id.
     */
    public func contains(globalID gid: UInt32) -> Bool {
        if firstGID...(firstGID + lastGID) ~= Int(gid) {
            return true
        }
        return false
    }

    /**
     Returns tile data for the given global tile ID.

     ** Tiled ID == GID + 1

     - parameter globalID: `Int` global tile id.
     - returns: `SKTilesetData?` tile data object.
     */
    public func getTileData(globalID gid: Int) -> SKTilesetData? {
        var id = getTileRealID(id: gid)
        id = getLocalID(forGlobalID: id)
        if let index = tileData.index(where: { $0.id == id }) {
            return tileData[index]
        }
        return nil
    }

    /**
     Returns tile data for the given local tile ID.

     - parameter localID: `Int` local tile id.
     - returns: `SKTilesetData?` tile data object.
     */
    public func getTileData(localID id: Int) -> SKTilesetData? {
        let localID = getTileRealID(id: id)
        if let index = tileData.index(where: { $0.id == localID }) {
            return tileData[index]
        }
        return nil
    }

    /**
     Returns tile data with the given property.

     - parameter withProperty: `String` property name.
     - returns: `[SKTilesetData]` array of tile data.
     */
    public func getTileData(withProperty property: String) -> [SKTilesetData] {
        return tileData.filter { $0.properties[property] != nil }
    }

    /**
     Returns tile data with the given type.

     - parameter ofType: `String` data type.
     - returns: `[SKTilesetData]` array of tile data.
     */
    public func getTileData(ofType: String) -> [SKTilesetData] {
        return tileData.filter { $0.type == ofType }
    }

    /**
     Returns tile data with the given property.

     - parameter property: `String` property name.
     - parameter value:    `AnyObject` value
     - returns: `[SKTilesetData]` array of tile data.
     */
    public func getTileData(withProperty property: String, _ value: Any) -> [SKTilesetData] {
        var result: [SKTilesetData] = []
        let tiledata = getTileData(withProperty: property)
        for data in tiledata {
            if data.stringForKey(property)! == value as? String {
                result.append(data)
            }
        }
        return result
    }

    /**
     Returns animated tile data.

     - returns: `[SKTilesetData]` array of animated tile data.
     */
    public func getAnimatedTileData() -> [SKTilesetData] {
        return tileData.filter { $0.isAnimated == true }
    }

    /**
     Convert a global ID to the tileset's local ID.

     - parameter id: `Int` global id.
     - returns: `Int` local tile ID.
     */
    public func getLocalID(forGlobalID gid: Int) -> Int {
        // firstGID is greater than 0 only when added to a tilemap
        let id = (firstGID > 0) ? (gid - firstGID) : gid
        // if the id is less than zero, return the gid
        return (id < 0) ? gid : id
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

    // MARK: - Rendering

    /**
     Check that all animated frames have textures.
     */
    internal func renderTileData() {
        let animatedData = getAnimatedTileData()
        var framesAdded = 0
        var dataFixed = 0
        if (animatedData.isEmpty == false) {
            animatedData.forEach { data in
                for frame in data.frames {
                    if frame.texture == nil {
                        if let frameData = getTileData(localID: frame.gid) {
                            if frameData.texture != nil {
                                frame.texture = frameData.texture
                                framesAdded += 1
                            }
                        }

                    }
                }
                dataFixed += 1
            }
        }

        if framesAdded > 0 {
            log("updated \(dataFixed) tile data animations for tileset: \"\(name)\"", level: .debug)
        }
    }

    // MARK: - Debugging
    /**
     Print out tileset data values.
     */
    internal func debugTileset() {
        log("# Tileset: \"\(name)\":", level: .debug)
        for data in tileData.sorted(by: {$0.id < $1.id}) {
            log("data:  \(data)", level: .debug)
        }
    }
}


public func == (lhs: SKTileset, rhs: SKTileset) -> Bool {
    return (lhs.hashValue == rhs.hashValue)
}


extension SKTileset: Hashable {
    public var hashValue: Int { return name.hashValue }
}


extension SKTileset: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        var desc = "Tileset: \"\(name)\" @ \(tileSize), firstgid: \(firstGID), \(dataCount) tiles"
        if tileOffset.x != 0 || tileOffset.y != 0 {
            desc += ", offset: \(tileOffset.x)x\(tileOffset.y)"
        }
        return desc
    }

    public var debugDescription: String { return description }
}
