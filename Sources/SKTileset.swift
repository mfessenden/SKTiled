//
//  SKTileset.swift
//  SKTiled
//
//  Created by Michael Fessenden.
//
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SpriteKit



/**

 ## Overview

 The tileset class manages a set of `SKTilesetData` objects, which store tile data including global id, texture and animation.

 Tile data is accessed via a local id, and tiles can be instantiated with the resulting `SKTilesetData` instance:

 ```swift
 if let data = tileset.getTileData(localID: 56) {
    let tile = SKTile(data: data)
 }
 ```

 ### Properties

 | Property              | Description                                     |
 |-----------------------|-------------------------------------------------|
 | name                  | Tileset name.                                   |
 | tilemap               | Reference to parent tilemap.                    |
 | tileSize              | Tile size (in pixels).                          |
 | columns               | Number of columns.                              |
 | tilecount             | Tile count.                                     |
 | firstGID              | First tile global id.                           |
 | lastGID               | Last tile global id.                            |
 | tileData              | Set of tile data structures.                    |


 ### Instance Methods ###

 | Method                | Description                                     |
 |-----------------------|-------------------------------------------------|
 | addTextures()         | Generate textures from a spritesheet image.     |
 | addTilesetTile()      | Add & return new tile data object.              |


 */
public class SKTileset: NSObject, SKTiledObject {

    /// Tileset url (external tileset).
    public var url: URL!

    /// Tiled tsx filename (external tileset).
    public var filename: String! = nil

    /// Unique object id.
    public var uuid: String = UUID().uuidString

    /// Tileset name
    public var name: String

    /// Object type.
    public var type: String!

    /// Custom tileset properties.
    public var properties: [String: String] = [:]

    /// Ignore custom properties.
    public var ignoreProperties: Bool = false

    /// Reference to parent tilemap.
    public var tilemap: SKTilemap!

    /// Tile size (in pixels).
    public var tileSize: CGSize
    
    /// Tileset logging level.
    internal var loggingLevel: LoggingLevel = LoggingLevel.warning

    /// The number of tile columns.
    public var columns: Int = 0

    /// The number of tiles contained in this set.
    public internal(set) var tilecount: Int = 0

    /// Tile data count.
    public var dataCount: Int {
        return tileData.count
    }

    /// Tile offset value.
    public var firstGID: Int = 0

    /// Returns the last global tile id in the tileset.
    public var lastGID: Int {
        return tileData.map { $0.id }.max() ?? firstGID
    }

    /// Returns a range of localized tile ids.
    public var localRange: ClosedRange<Int> {
        return 0...(dataCount - 1)
    }

    /// Returns a range of global tile id values.
    public var globalRange: ClosedRange<Int> {
        return firstGID...(firstGID + lastGID)
    }

    // MARK: - Spacing

    /// Spritesheet spacing between tiles.
    public var spacing: Int = 0

    /// Spritesheet border margin.
    public var margin: Int = 0

    /// Offset for drawing tiles.
    public var tileOffset = CGPoint.zero

    /// Texture name (if created from source)
    public var source: String!

    /// Tile data set.
    private var tileData: Set<SKTilesetData> = []

    /// Indicates the tileset is a collection of images.
    public var isImageCollection: Bool = false

    /// The tileset is stored in an external file.
    public var isExternalTileset: Bool {
        return filename != nil
    }

    /// Source image transparency color.
    public var transparentColor: SKColor?

    /// Indicates all of the tile data textures have been set.
    public internal(set) var isRendered: Bool = false

    /// Returns the difference in tile size vs. map tile size.
    internal var mapOffset: CGPoint {
        guard let tilemap = tilemap else { return .zero }
        return CGPoint(x: tileSize.width - tilemap.tileSize.width, y: tileSize.height - tilemap.tileSize.height)
    }

    /// Scaling factor for text objects, etc.
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
    public init(name: String, tileSize size: CGSize,
                firstgid: Int = 1, columns: Int = 0,
                offset: CGPoint = CGPoint.zero) {

        self.name = name
        self.tileSize = size

        super.init()
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
    public init(source: String, firstgid: Int,
                tilemap: SKTilemap, offset: CGPoint = CGPoint.zero) {


        let filepath = source.components(separatedBy: "/").last!
        self.filename = filepath

        self.firstGID = firstgid
        self.tilemap = tilemap
        self.tileOffset = offset

        // setting these here, even though it may different later
        self.name = filepath.components(separatedBy: ".")[0]
        self.tileSize = tilemap.tileSize

        super.init()
        self.ignoreProperties = tilemap.ignoreProperties
    }

    /**
     Initialize with attributes directly from TMX file.

     - parameter attributes: `[String: String]` attributes dictionary.
     - parameter offset:     `CGPoint` pixel offset in x/y.
     */
    public init?(attributes: [String: String],
                 offset: CGPoint = CGPoint.zero) {

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

        super.init()
        self.tileOffset = offset
    }

    /**
     Initialize with a TSX file name.

     - parameter fileNamed:  `String` tileset file name.
     - parameter delegate:   `SKTilemapDelegate?` optional tilemap delegate.
     */
    public init(fileNamed: String) {
        self.name = ""
        self.tileSize = CGSize.zero
        super.init()
    }

    // MARK: - Loading
    /**
     Loads Tiled tsx files and returns an array of `SKTileset` objects.

     - parameter tsxFiles:          `[String]` Tiled tileset filenames.
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
    public func addTextures(fromSpriteSheet source: String, replace: Bool = false, transparent: String? = nil) {
        let timer = Date()

        self.source = source

        // parse the transparent color
        if let transparent = transparent {
            transparentColor = SKColor(hexString: transparent)
        }

        if (replace == true) {
            let url = URL(fileURLWithPath: source)
            self.log("replacing spritesheet with: \"\(url.lastPathComponent)\"", level: .info)
        }

        let inputURL = URL(fileURLWithPath: self.source!)
        self.log("spritesheet: \"\(inputURL.relativePath.filename)\"", level: .debug)

        // read image from file
        guard let imageDataProvider = CGDataProvider(url: inputURL as CFURL) else {
            self.log("Error reading image: \"\(source)\"", level: .fatal)
            fatalError("Error reading image: \"\(source)\"")
        }

        // creare an image data provider
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

        let usableHeight = margin + rowHeight + rowSpacing
        let tileSizeHeight = Int(tileSize.height)
        let heightDifference = textureHeight - usableHeight

        // invert the y-coord
        var y = (usableHeight - tileSizeHeight) + heightDifference

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
                _ = self.setDataTexture(tileID, texture: tileTexture)
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
            Logger.default.log("tileset \"\(name)\" built in: \(timeStamp)s (\(tilesAdded) tiles)", level: .debug, symbol: self.logSymbol)
        } else {

            let animatedData: [SKTilesetData] = self.tileData.filter { $0.isAnimated == true }

            // update animated data
            NotificationCenter.default.post(
                name: Notification.Name.Tileset.SpriteSheetUpdated,
                object: self,
                userInfo: ["animatedTiles": animatedData]
            )

        }
    }

    // MARK: - Tile Data

    /**
     Add tileset tile data attributes. Returns a new `SKTilesetData` object, or nil if tile data already exists with the given id.

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

        // add to tile cache

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
    
        isImageCollection = true

        // standardize the url
        let inputURL = URL(fileURLWithPath: source).standardized
        
        // check to see if
        guard let imageDataProvider = CGDataProvider(url: inputURL as CFURL) else {
            log("invalid image source '\(inputURL.path)'.", level: .error)
            return nil
        }
        
        // create a data provider
        let image = CGImage(pngDataProviderSource: imageDataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let sourceTexture = SKTexture(cgImage: image)
        sourceTexture.filteringMode = .nearest
        
        // create the tile data and set the source size here (as tileset size won't be accurate)
        let data = SKTilesetData(id: tileID, texture: sourceTexture, tileSet: self)
        data.sourceSize = sourceTexture.size()
        data.ignoreProperties = ignoreProperties
        
        // add the image name to the source attribute
        data.source = source
        self.tileData.insert(data)
        data.parseProperties(completion: nil)
        return data
    }

    /**
     Create new data from the given texture image path. Returns a new tileset data instance & the local id associated with it.

     - parameter source: source image name.
     - returns: local tile id & tileset data (or nil if the data exists).
     */
    public func addTilesetTile(source: String) -> (id: UInt32, data: SKTilesetData)? {
        let nextTileId = tilecount + 1
        let nextData = SKTilesetData(id: nextTileId, texture: SKTexture(imageNamed: source), tileSet: self)
        return (UInt32(nextTileId), nextData)
    }

    /**
     Set(replace) the texture for a given tile id.

     - parameter tileID:  `Int` tile ID.
     - parameter texture: `SKTexture` texture for tile at the given id.
     - returns: `SKTexture?` previous tile data texture.
     */
    @discardableResult
    public func setDataTexture(_ id: Int, texture: SKTexture) -> SKTexture? {
        guard let data = getTileData(localID: id) else {
            if (loggingLevel.rawValue <= 1) {
                log("tile data not found for id: \(id)", level: .error)
            }
            return nil
        }

        let current = data.texture.copy() as? SKTexture
        let userInfo: [String: Any] = (current != nil) ? ["old": current!] : [:]

        texture.filteringMode = .nearest
        data.texture = texture

        // update observers
        NotificationCenter.default.post(
            name: Notification.Name.TileData.TextureChanged,
            object: data,
            userInfo: userInfo
        )

        return current
    }

    /**
     Set(replace) the texture for a given tile id.

     - parameter tileID:     `Int` tile ID.
     - parameter imageNamed: `String` source texture name.
     - returns: `SKTexture?` old tile data texture.
     */
    @discardableResult
    public func setDataTexture(_ id: Int, imageNamed: String) -> SKTexture? {
        let inputURL = URL(fileURLWithPath: imageNamed)
        // read image from file
        guard let imageDataProvider = CGDataProvider(url: inputURL as CFURL) else {
            return nil
        }

        // creare an image data provider
        let image = CGImage(pngDataProviderSource: imageDataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let texture = SKTexture(cgImage: image)
        return setDataTexture(id, texture: texture)
    }

    /**
     Returns true if the tileset contains the given ID (local).

     - parameter localID:  `UInt32` local tile id.
     - returns: `Bool` tileset contains the local id.
     */
    internal func contains(localID: UInt32) -> Bool {
        return localRange ~= Int(localID)
    }

    /**
     Returns true if the tileset contains the global ID.

     - parameter globalID:  `UInt32` global tile id.
     - returns: `Bool` tileset contains the global id.
     */
    public func contains(globalID gid: UInt32) -> Bool {
        return globalRange ~= Int(gid)
    }

    /**
     Returns tile data for the given global tile ID.

     ** Tiled ID == GID + 1

     - parameter globalID: `Int` global tile id.
     - returns: `SKTilesetData?` tile data object.
     */
    public func getTileData(globalID gid: Int) -> SKTilesetData? {
        // parse out flipped flags
        var id = rawTileID(id: gid)
        id = getLocalID(forGlobalID: id)
        if let index = tileData.firstIndex(where: { $0.id == id }) {
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
        let localID = rawTileID(id: id)
        if let index = tileData.firstIndex(where: { $0.id == localID }) {
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
     Returns tile data with the given name & animated state.

     - parameter named:      `String` data name.
     - parameter isAnimated: `Bool` filter data that is animated.
     - returns: `[SKTilesetData]` array of tile data.
     */
    public func getTileData(named name: String, isAnimated: Bool = false) -> [SKTilesetData] {
        return tileData.filter {
            ($0.name == name) && ($0.isAnimated == isAnimated)
        }
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

     - parameter gid: `Int` global id.
     - returns: `Int`  local tile ID.
     */
    public func getLocalID(forGlobalID gid: Int) -> Int {
        // firstGID is greater than 0 only when added to a tilemap
        let id = (firstGID > 0) ? (gid - firstGID) : gid
        // if the id is less than zero, return the gid
        return (id < 0) ? gid : id
    }

    /**
     Convert a global ID to the tileset's local ID.

     - parameter id: `Int` local id.
     - returns: `Int` global tile ID.
     */
    public func getGlobalID(forLocalID id: Int) -> Int {
        let gid = (firstGID > 0) ? (firstGID + id) - 1 : id
        return gid
    }

    /**
     Check for tile ID flip flags.

     - parameter id: `Int` tile ID.
     - returns: `Int` translated ID.
     */
    internal func rawTileID(id: Int) -> Int {
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
     Refresh textures for animated tile data.
     */
    internal func setupAnimatedTileData() {
        let animatedData = getAnimatedTileData()
        var framesAdded = 0
        var dataFixed = 0
        if (animatedData.isEmpty == false) {
            animatedData.forEach { data in
                for frame in data.frames where frame.texture == nil{
                    if let frameData = getTileData(localID: frame.id) {
                        if frameData.texture != nil {
                            frame.texture = frameData.texture
                            framesAdded += 1
                        }
                    }
                }
                dataFixed += 1
            }
        }

        if (framesAdded > 0) {
            log("updated \(dataFixed) tile data animations for tileset: \"\(name)\"", level: .debug)
        }
    }
}




public func == (lhs: SKTileset, rhs: SKTileset) -> Bool {
    return (lhs.hash == rhs.hash)
}


extension SKTileset {

    override public var hash: Int {
        return name.hashValue
    }

    /// String representation of the tileset object.
    override public var description: String {
        var desc = "Tileset: \"\(name)\" @ \(tileSize), firstgid: \(firstGID), \(dataCount) tiles"
        if tileOffset.x != 0 || tileOffset.y != 0 {
            desc += ", offset: \(tileOffset.x)x\(tileOffset.y)"
        }
        return desc
    }

    override public var debugDescription: String { return description }
}
