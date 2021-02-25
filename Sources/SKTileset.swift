//
//  SKTileset.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "S   oftware"), to deal
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


/// The `SKTileset` class manages a set of `SKTilesetData` objects, which store tile data including global id, texture and animation.
///
/// ![Tileset Setup][tiledata-diagram-url]
///
/// Tile data is accessed via a local id, and tiles can be instantiated with the resulting `SKTilesetData` instance:
///
/// ```swift
/// if let data = tileset.getTileData(localID: 56) {
///    let tile = SKTile(data: data)
/// }
/// ```
///
/// ### Properties
///
/// - `name`: tileset name.
/// - `tilemap`: reference to parent tilemap.
/// - `tileSize`: tile size (in pixels).
/// - `localRange`: range of local tile data id values.
/// - `globalRange`: range of global tile data id values.
/// - `columns`: number of columns.
/// - `tilecount`: tile count.
/// - `firstGID`: first tile global id.
/// - `lastGID`: last tile global id.
/// - `tileData`: set of tile data structures.
///
/// ### Class Functions
///
/// - `load(tsxFile:delegate:)`: Load a tileset from a file.
/// - `load(tsxFiles:delegate:)`: Load multiple tilesets.
///
/// ### Instance Methods
///
/// - `addTextures()`: Generate textures from a spritesheet image.
/// - `addTilesetTile()`: Add & return new tile data object.
///
/// For more information, see the **[Working with Tilesets][tilesets-doc-url]** page in the **[official documentation][sktiled-docroot-url]**.
///
/// [tilesets-doc-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKTileset.html
/// [sktiled-docroot-url]:https://mfessenden.github.io/SKTiled/1.3/index.html
/// [tiledata-diagram-url]:https://mfessenden.github.io/SKTiled/1.3/images/tiledata-setup.svg
public class SKTileset: NSObject, CustomReflectable, TiledObjectType {

    /// Tileset url (external tileset).
    public var url: URL!

    /// Unique object id.
    public var uuid: String = UUID().uuidString

    /// Tiled tsx filename (external tileset, ie: "tileset.tsx").
    public var filename: String!

    /// Tileset name
    public var name: String

    /// Object type.
    public var type: String!

    /// Custom tileset properties.
    public var properties: [String: String] = [:]

    /// Private **Tiled** properties.
    public var _tiled_properties: [String: String] = [:]
    
    /// Ignore custom properties.
    public var ignoreProperties: Bool = false

    /// Reference to parent tilemap.
    public weak var tilemap: SKTilemap!

    /// Tileset tile size (in pixels).
    public var tileSize: CGSize

    /// Tileset logging level.
    internal var loggingLevel: LoggingLevel = LoggingLevel.warning

    /// Number of tileset columns.
    public var columns: Int = 0

    /// Tile data set.
    private var tileData: Set<SKTilesetData> = []

    /// Tileset tile count.
    public internal(set) var tilecount: Int = 0

    /// Tileset tile data count (not the same as tile count).
    public var dataCount: Int {
        return tileData.count
    }

    /// Tileset first gid.
    public internal(set) var firstGID: UInt32 = 0

    /// Returns the last global tile id in the tileset.
    public var lastGID: UInt32 {
        return tileData.map { $0.id }.max() ?? firstGID
    }

    /// Returns a range of localized tile id values.
    public var localRange: ClosedRange<UInt32> {
        return 0...UInt32(dataCount - 1)
    }

    /// Returns a range of global tile id values.
    public var globalRange: ClosedRange<UInt32> {
        return firstGID...(firstGID + UInt32(lastGID))
    }

    // MARK: - Spacing

    /// Spritesheet spacing between tiles.
    public var spacing: Int = 0

    /// Spritesheet border margin.
    public var margin: Int = 0

    /// Offset for drawing tiles.
    public var tileOffset = CGPoint.zero

    /// Texture name (if created from source).
    public var source: String!

    /// Indicates the tileset is a collection of images.
    public var isImageCollection: Bool = false

    /// The tileset is stored in an external file.
    public var isExternalTileset: Bool {
        return filename != nil
    }

    /// Source image transparency color.
    public var transparentColor: SKColor?

    /// Indicates tileset is rendered.
    public var isRendered: Bool = false

    /// Returns the difference in tileset tile size vs. tilemap tile size.
    internal var mapOffset: CGPoint {
        guard let tilemap = tilemap else {
            return .zero
        }
        // TODO: is this causing hex offset errors?
        return CGPoint(x: tileSize.width - tilemap.tileSize.width, y: tileSize.height - tilemap.tileSize.height)
    }

    /// Scaling factor for text objects, etc.
    public var renderQuality: CGFloat = 8 {
        didSet {
            guard renderQuality != oldValue else { return }
            tileData.forEach { $0.renderQuality = renderQuality }
        }
    }

    // MARK: - Initialization

    /// Initialize with basic properties.
    /// - Parameters:
    ///   - name: tileset name.
    ///   - size: tile size.
    ///   - firstgid: first gid value.
    ///   - columns: number of columns.
    ///   - offset: tileset offset value.
    public init(name: String,
                tileSize size: CGSize,
                firstgid: UInt32 = 1,
                columns: Int = 0,
                offset: CGPoint = CGPoint.zero) {

        self.name = name
        self.tileSize = size

        super.init()
        self.firstGID = firstgid
        self.columns = columns
        self.tileOffset = offset
    }

    /// Initialize with an external tileset (only source and first gid are given).
    ///
    /// - Parameters:
    ///   - source: source file name.
    ///   - firstgid: first gid value.
    ///   - tilemap: parent tile map node.
    ///   - offset: tile offset value.
    public init(source: String,
                firstgid: UInt32,
                tilemap: SKTilemap,
                offset: CGPoint = CGPoint.zero) {

        // get the filename for this tileset
        let filepath = source.components(separatedBy: "/").last!
        self.filename = filepath

        self.firstGID = UInt32(firstgid)
        self.tilemap = tilemap
        self.tileOffset = offset

        // setting these here, even though it may different later
        self.name = filepath.components(separatedBy: ".")[0]
        self.tileSize = tilemap.tileSize

        super.init()
        self.ignoreProperties = tilemap.ignoreProperties
    }

    /// Initialize with attributes directly from TMX file.
    ///
    /// - Parameters:
    ///   - attributes: attributes dictionary.
    ///   - offset: pixel offset in x/y.
    public init?(attributes: [String: String],
                 offset: CGPoint = CGPoint.zero) {

        // name, width and height are required
        guard let tilesetName = attributes["name"],
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
            self.firstGID = UInt32(firstgid)!
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

        self.name = tilesetName
        self.tileSize = CGSize(width: Int(width)!, height: Int(height)!)

        super.init()
        self.tileOffset = offset
    }

    // MARK: - Loading

    /// Loads Tiled tsx files and returns an array of `SKTileset` objects.
    ///
    /// - Parameters:
    ///   - tsxFiles: Tiled tileset filenames.
    ///   - delegate: optional [`TilemapDelegate`](Protocols/TilemapDelegate.html) instance.
    ///   - noparse: ignore custom properties from Tiled.
    /// - Returns: array of tilesets.
    public class func load(tsxFiles: [String],
                           delegate: TilemapDelegate? = nil,
                           ignoreProperties noparse: Bool = false) -> [SKTileset] {

        let startTime = Date()
        let queue = DispatchQueue(label: "org.sktiled.renderqueue", qos: .userInitiated)
        let tilesets = SKTilemapParser().load(tsxFiles: tsxFiles, delegate: delegate, ignoreProperties: noparse, renderQueue: queue)
        let renderTime = Date().timeIntervalSince(startTime)
        let timeStamp = String(format: "%.\(String(3))f", renderTime)
        Logger.default.log("\(tilesets.count) tilesets rendered in: \(timeStamp)s", level: .success)
        return tilesets
    }

    /// Load a Tiled tsx file and return a `SKTileset` object.
    ///
    /// - Parameters:
    ///   - tsxFile: tileset filename.
    ///   - dataSource: tileset data source delegate.
    ///   - noparse: ignore custom properties.
    /// - Returns: tileset, if created.
    public class func load(tsxFile: String,
                           dataSource: TilesetDataSource? = nil,
                           ignoreProperties noparse: Bool = false) -> SKTileset? {

        let startTime = Date()
        let queue = DispatchQueue(label: "org.sktiled.renderqueue", qos: .userInitiated)
        if let tileset = SKTilemapParser().load(tsxFiles: [tsxFile], delegate: nil, tilesetDataSource: dataSource, ignoreProperties: noparse, renderQueue: queue).first {
            let renderTime = Date().timeIntervalSince(startTime)
            let timeStamp = String(format: "%.\(String(3))f", renderTime)
            Logger.default.log("tileset rendered in: \(timeStamp)s", level: .success)
            return tileset
        }
        return nil
    }


    // MARK: - Textures

    /// Create tile texture data from a spritesheet image.
    ///
    /// - Parameters:
    ///   - source: image named referenced in the tileset.
    ///   - replace: replace the current texture.
    ///   - transparent: optional transparent color hex value.
    public func addTextures(fromSpriteSheet source: String,
                            replace: Bool = false,
                            transparent: String? = nil) {

        let timer = Date()

        self.source = source

        // parse the transparent color
        if let transparent = transparent {
            transparentColor = SKColor(hexString: transparent)
        }

        if (replace == true) {
            let url = URL(fileURLWithPath: source)
            self.log("replacing spritesheet with: '\(url.lastPathComponent)'", level: .debug)
        }


        autoreleasepool {

            let inputUrl = URL(fileURLWithPath: self.source!)

            // read the file and create a texture
            guard let _ = CGDataProvider(url: inputUrl as CFURL),
                  let sourceTexture = SKTexture(contentsOf: inputUrl) else {
                  self.log("Error reading image '\(source)'", level: .fatal)
                  fatalError("Error reading image '\(source)'")
            }

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
            // TODO: need to flip this?
            var y = (usableHeight - tileSizeHeight) + heightDifference

            var tilesAdded: Int = 0


            for index in 0..<totalTileCount {

                let tileId = UInt32(index)

                let rectStartX = CGFloat(x) / CGFloat(textureWidth)
                let rectStartY = CGFloat(y) / CGFloat(textureHeight)

                let rectWidth = self.tileSize.width / CGFloat(textureWidth)
                let rectHeight = self.tileSize.height / CGFloat(textureHeight)

                // create texture rectangle & extract texture
                let tileRect = CGRect(x: rectStartX, y: rectStartY, width: rectWidth, height: rectHeight)
                let tileTexture = SKTexture(rect: tileRect, in: sourceTexture)
                tileTexture.filteringMode = .nearest

                // add the tile data properties, or replace the texture
                if (replace == false) {
                    _ = self.addTilesetTile(tileID: tileId, texture: tileTexture)
                } else {
                    _ = self.setDataTexture(tileID: tileId, texture: tileTexture)
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
                Logger.default.log("tileset '\(name)' built in: \(timeStamp)s (\(tilesAdded) tiles)", level: .debug, symbol: self.logSymbol)
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
    }

    // MARK: - Tile Data

    /// Add tileset tile data attributes. Returns a new `SKTilesetData` object, or nil if tile data already exists with the given id.
    ///
    /// - Parameters:
    ///   - tileID: local tile ID.
    ///   - texture: texture for tile at the given id.
    /// - Returns: tileset data (or nil if the data exists).
    public func addTilesetTile(tileID: UInt32, texture: SKTexture) -> SKTilesetData? {
        guard !(self.tileData.contains(where: { $0.hashValue == tileID.hashValue })) else {
            log("tile data exists at id: \(tileID)", level: .error)
            return nil
        }

        texture.filteringMode = .nearest
        let data = SKTilesetData(id: tileID, texture: texture, tileSet: self)

        /// add custom attributes for the data
        let globalId = getGlobalID(forLocalID: tileID)
        if let customProperties = tilemap.delegate?.attributesForNodes?(ofType: data.type, named: data.name, globalIDs: [globalId]) {
            for (attr, value) in customProperties {
                data.properties[attr] = value
            }
        }

        data.ignoreProperties = ignoreProperties
        self.tileData.insert(data)
        data.parseProperties(completion: nil)
        return data
    }

    /// Add tileset data from an image source (tileset is a collections tileset).
    ///
    /// - Parameters:
    ///   - tileID: local tile ID.
    ///   - source: source image name.
    /// - Returns: tileset data (or nil if the data exists).
    public func addTilesetTile(tileID: UInt32, source: String) -> SKTilesetData? {
        guard !(self.tileData.contains(where: { $0.hashValue == tileID.hashValue })) else {
            log("invalid tile id '\(tileID)'", level: .error)
            return nil
        }

        // flag the tileset as being a collections tileset
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

        /// add custom attributes for the data
        let globalId = getGlobalID(forLocalID: tileID)
        if let customProperties = tilemap.delegate?.attributesForNodes?(ofType: data.type, named: data.name, globalIDs: [globalId]) {
            for (attr, value) in customProperties {
                data.properties[attr] = value
            }
        }

        data.ignoreProperties = ignoreProperties
        // add the image name to the source attribute
        data.source = source
        self.tileData.insert(data)
        data.parseProperties(completion: nil)
        return data
    }

    /// Create new data from the given texture image path. Returns a new tileset data instance & the local id associated with it.
    ///
    /// - Parameter source: source image name.
    /// - Returns: local tile id & tileset data (or nil if the data exists)
    public func addTilesetTile(source: String) -> (id: UInt32, data: SKTilesetData)? {
        let nextTileId = UInt32(tilecount + 1)
        let nextData = SKTilesetData(id: nextTileId, texture: SKTexture(imageNamed: source), tileSet: self)
        return (nextTileId, nextData)
    }

    /// Set(replace) the texture for a given tile id.
    ///
    /// - Parameters:
    ///   - tileID: tile ID.
    ///   - texture: texture for tile at the given id.
    /// - Returns: previous tile data texture.
    @discardableResult
    public func setDataTexture(tileID: UInt32, texture: SKTexture) -> SKTexture? {
        guard let data = getTileData(localID: tileID) else {
            if (loggingLevel.rawValue <= 1) {
                log("tile data not found for id: \(tileID)", level: .error)
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

    /// Set(replace) the texture for a given tile id.
    ///
    /// - Parameters:
    ///   - tileID: tile ID.
    ///   - imageNamed: source texture name.
    /// - Returns: old tile data texture.
    @discardableResult
    public func setDataTexture(tileID: UInt32, imageNamed: String) -> SKTexture? {
        let inputURL = URL(fileURLWithPath: imageNamed)
        // read image from file
        guard let imageDataProvider = CGDataProvider(url: inputURL as CFURL) else {
            return nil
        }

        // creare an image data provider
        let image = CGImage(pngDataProviderSource: imageDataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let texture = SKTexture(cgImage: image)
        return setDataTexture(tileID: tileID, texture: texture)
    }

    /// Returns true if the tileset contains the given ID (local).
    ///
    /// - Parameter localID: local tile id.
    /// - Returns: tileset contains the global id.
    internal func contains(localID: UInt32) -> Bool {
        return localRange ~= localID
    }

    /// Returns true if the tileset contains the global ID.
    ///
    /// - Parameter globalID: global tile id.
    /// - Returns: tileset contains the global id.
    public func contains(globalID: UInt32) -> Bool {
        return globalRange ~= globalID
    }

    /// Returns tile data for the given global tile ID (if it exists).
    ///
    /// - Parameter gid: global tile id.
    /// - Returns: tile data object.
    public func getTileData(globalID gid: UInt32) -> SKTilesetData? {
        // parse out flipped flags
        var id = realTileId(globalID: gid)
        id = getLocalID(globalID: id)
        if let index = tileData.firstIndex(where: { $0.id == id }) {
            return tileData[index]
        }
        return nil
    }

    /// Returns tile data for the given local tile ID.
    ///
    /// - Parameter id: local tile id.
    /// - Returns: tile data.
    public func getTileData(localID id: UInt32) -> SKTilesetData? {
        let realId = realTileId(globalID: id)
        if let index = tileData.firstIndex(where: { $0.id == realId }) {
            return tileData[index]
        }
        return nil
    }

    /// Returns tile data matching the given property.
    ///
    /// - Parameter property: property name.
    /// - Returns: array of tile data.
    public func getTileData(withProperty property: String) -> [SKTilesetData] {
        return tileData.filter { $0.properties[property] != nil }
    }

    /// Returns tile data with the given property & value.
    ///
    /// - Parameters:
    ///   - property: property name.
    ///   - value: property value.
    /// - Returns: array of tile data.
    public func getTileData(withProperty property: String,
                            _ value: Any) -> [SKTilesetData] {

        var result: [SKTilesetData] = []
        let tiledata = getTileData(withProperty: property)
        for data in tiledata {
            if data.stringForKey(property)! == value as? String {
                result.append(data)
            }
        }
        return result
    }

    /// Returns tile data with the given name & animated state.
    /// - Parameters:
    ///   - name: data name.
    ///   - isAnimated: filter data that is animated.
    /// - Returns: array of tile data.
    public func getTileData(named name: String,
                            isAnimated: Bool = false) -> [SKTilesetData] {

        return tileData.filter {
            ($0.name == name) && ($0.isAnimated == isAnimated)
        }
    }

    /// Returns tile data with the given type.
    ///
    /// - Parameter ofType: data type.
    /// - Returns: array of tile data.
    public func getTileData(ofType: String) -> [SKTilesetData] {
        return tileData.filter { $0.type == ofType }
    }

    /// Returns animated tile data.
    ///
    /// - Returns: array of animated tile data.
    public func getAnimatedTileData() -> [SKTilesetData] {
        return tileData.filter { $0.isAnimated == true }
    }

    /// Returns tile data with collision shapes.
    ///
    /// - Returns: array of tile data.
    public func getTileDataWithCollisionShapes() -> [SKTilesetData] {
        return tileData.filter { data in
            return data.collisions.count > 0
        }
    }

    ///  Convert a global ID to the tileset's local ID.
    ///
    /// - Parameter id: local id.
    /// - Returns: global tile ID.
    public func getGlobalID(forLocalID id: UInt32) -> UInt32 {
        //let gid = (firstGID > 0) ? (firstGID + id) - 1 : id + 1
        let gid = (firstGID > 0) ? (firstGID + id) - 1 : id
        return gid
    }

    /// Convert a global ID to the tileset's local ID.
    ///
    /// - Parameter globalID: global id.
    /// - Returns: local tile id.
    public func getLocalID(globalID: UInt32) -> UInt32 {
        // firstGID is greater than 0 only when added to a tilemap
        var gid = Int(globalID)
        let fgid = Int(firstGID)
        if (fgid > 0) {  // this works with `1`, was `0`
            gid = Int(globalID) - fgid
        }
        // if the id is less than zero, return the gid
        return (gid < 0) ? globalID : UInt32(gid)
    }

    /// Returns the actual global id from a masked global id.
    ///
    /// - Parameter id: global id.
    /// - Returns: actual global id.
    internal func realTileId(globalID: UInt32) -> UInt32 {
        // masks for tile flipping
        let flippedDiagonalFlag: UInt32   = 0x20000000
        let flippedVerticalFlag: UInt32   = 0x40000000
        let flippedHorizontalFlag: UInt32 = 0x80000000

        let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
        let flippedMask = ~(flippedAll)

        // get the actual gid from the mask
        let gid = globalID & flippedMask
        return gid
    }


    // MARK: - Rendering

    /// Refresh textures for animated tile data.
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
            log("updated \(dataFixed) tile data animations for tileset: '\(name)'", level: .debug)
        }
    }

    // MARK: - Reflection


    struct TilesetMirror {
        var name: String
        var firstGID: UInt32
        var lastGID: UInt32
        var dataCount: Int
        var localRange: ClosedRange<UInt32>
        var globalRange: ClosedRange<UInt32>
    }


    /// Referenced as `(label: "tileset", value: tileset.tilesetDataStruct())`
    ///
    /// - Returns: custom mirror data
    func tilesetDataStruct() -> TilesetMirror {
        let nameValue = (url != nil) ? url.relativePath : name
        return TilesetMirror(name: nameValue,
                             firstGID: firstGID,
                             lastGID: lastGID,
                             dataCount: dataCount,
                             localRange: localRange,
                             globalRange: globalRange
                )

    }

    /// Returns a custom mirror for this object.
    public var customMirror: Mirror {
        var attributes: [(label: String?, value: Any)] = [
            (label: "name", value: name),
            (label: "tile size", value: tileSize),
            (label: "firstgid", value: firstGID),
            (label: "lastgid", value: lastGID),
            (label: "tilecount", value: tilecount),
            (label: "collection", value: isImageCollection),
            (label: "data", value: tileData),
            (label: "properties", value: mirrorChildren())
        ]


        /// internal debugging attrs
        attributes.append(("tiled element name", tiledElementName))
        attributes.append(("tiled help description", tiledHelpDescription))
        attributes.append(("tiled description", description))
        attributes.append(("tiled debug description", debugDescription))

        return Mirror(self, children: attributes, displayStyle: .class)
    }
}


// MARK: - Helpers


public func == (lhs: SKTileset, rhs: SKTileset) -> Bool {
    return (lhs.hash == rhs.hash)
}


// MARK: - Extensions


extension SKTileset {

    public override var hash: Int {
        return name.hashValue
    }

    /// String representation of the tileset object.
    public override var description: String {
        let className = String(describing: Swift.type(of: self))
        let gidRangeString = "\(firstGID)...\(lastGID)"
        var desc = "\(className): '\(name)' @ \(tileSize), range: \(gidRangeString), \(dataCount) tiles"

        if (tileOffset.x != 0) || (tileOffset.y != 0) {
            desc += ", offset: \(tileOffset.x)x\(tileOffset.y)"
        }
        return desc
    }

    /// Debugging string representation of the tileset object.
    public override var debugDescription: String {
        return "<\(description)>"
    }

    /*
    /// Indicates the tileset contains the given local id.
    ///
    /// - Parameter localID: local tile data id.
    /// - Returns: tileset contains the local id.
    public func contains(localID: UInt32) -> Bool {
        return localRange.contains(Int(localID))
    }

    /// Indicates the tileset contains the given global id.
    ///
    /// - Parameter localID: local tile data id.
    /// - Returns: tileset contains the local id.
    public func contains(globalID: UInt32) -> Bool {
        return globalRange.contains(Int(globalID))

    }*/
}




extension SKTileset {

    /// Creates and returns a new tile instance with the given global id.
    ///
    /// - Parameters:
    ///   - localID: tile global id.
    ///   - tileType: tile object type.
    /// - Returns: tile instance, if tile data exists.
    public func newTile(globalID: UInt32, type tileType: SKTile.Type = SKTile.self) -> SKTile? {
        guard let tiledata = getTileData(globalID: globalID),
              let tile = tileType.init(data: tiledata) else {
            return nil
        }
        
        // add to tile cache
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: tile
        )
        
        
        return tile
    }

    /// Creates and returns a new tile instance with the given local id.
    ///
    /// - Parameters:
    ///   - localID: tile local id.
    ///   - tileType: tile object type.
    /// - Returns: tile instance, if tile data exists.
    public func newTile(localID: UInt32, type tileType: SKTile.Type = SKTile.self) -> SKTile? {
        guard let tiledata = getTileData(localID: localID),
              let tile = tileType.init(data: tiledata) else {
            return nil
        }
        
        // add to tile cache
        NotificationCenter.default.post(
            name: Notification.Name.Tile.TileCreated,
            object: tile
        )
        
        return tile
    }
}


/// :nodoc
extension SKTileset {

    /// Returns the internal **Tiled** node type.
    @objc public var tiledElementName: String {
        return "tileset"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "tileset-icon"
    }

    /// A description of the node.
    @objc public var tiledHelpDescription: String {
        return "\(tiledElementName.titleCased()): "
    }
}


/// :nodoc
extension SKTileset.TilesetMirror: CustomStringConvertible, CustomDebugStringConvertible {

    /// A textual representation of the object.
    public var description: String {
        return #"'\#(name)'"#
    }

    /// A textual representation of the object, used for debugging.
    public var debugDescription: String {
        return #"\#(description)"#
    }

}


// MARK: - Deprecations


extension SKTileset {

    /// Initialize with basic properties.
    ///
    /// - Parameters:
    ///   - name: tileset name.
    ///   - size: tile size.
    ///   - firstgid: first gid value.
    ///   - columns: number of columns.
    ///   - offset: tileset offset value.
    @available(*, deprecated, renamed: "init(name:tileSize:firstgid:columns:offset:)")
    public convenience init(name: String,
                tileSize size: CGSize,
                firstgid: Int = 1,
                columns: Int = 0,
                offset: CGPoint = CGPoint.zero) {

        self.init(name: name, tileSize: size, firstgid: UInt32(firstgid), columns: columns, offset: offset)
    }

    /// Initialize with an external tileset (only source and first gid are given).
    ///
    /// - Parameters:
    ///   - source: source file name.
    ///   - firstgid: first gid value.
    ///   - tilemap: parent tile map node.
    ///   - offset: tile offset value.
    @available(*, deprecated, renamed: "init(source:firstgid:tilemap:offset:)")
    public convenience init(source: String,
                firstgid: Int,
                tilemap: SKTilemap,
                offset: CGPoint = CGPoint.zero) {

        self.init(source: source, firstgid: UInt32(firstgid), tilemap: tilemap, offset: offset)
    }

    /// Returns tile data for the given global tile ID (if it exists).
    ///
    /// - Parameter gid: global tile id.
    /// - Returns: tile data object.
    @available(*, deprecated, message: "tile ids should be `UInt32` type.")
    public func getTileData(globalID gid: Int) -> SKTilesetData? {
        return getTileData(globalID: UInt32(gid))
    }

    ///  Convert a global ID to the tileset's local ID.
    ///
    /// - Parameter id: local id.
    /// - Returns: global tile ID.
    @available(*, deprecated, message: "tile ids should be `UInt32` type.")
    public func getGlobalID(forLocalID id: Int) -> Int {
        if (id > firstGID) {
            return Int(id)
        }

        let gid = (firstGID > 0) ? (firstGID + UInt32(id)) - 1 : UInt32(id) + 1
        return Int(gid)
    }

    /// Convert a global ID to the tileset's local ID.
    ///
    /// - Parameter gid: global id.
    /// - Returns: local tile id.
    @available(*, deprecated, renamed: "getLocalID(globalID:)")
    public func getLocalID(forGlobalID gid: UInt32) -> UInt32 {
        return getLocalID(globalID: gid)
    }

    /// Returns tile data for the given local tile ID.
    ///
    /// - Parameter id: local tile id.
    /// - Returns: tile data.
    @available(*, deprecated, message: "tile ids should be `UInt32` type.")
    public func getTileData(localID id: Int) -> SKTilesetData? {
        let localID = realTileId(globalID: UInt32(id))
        if let index = tileData.firstIndex(where: { $0.id == localID }) {
            return tileData[index]
        }
        return nil
    }

    /// Add tileset tile data attributes. Returns a new `SKTilesetData` object, or nil if tile data already exists with the given id.
    ///
    /// - Parameters:
    ///   - tileID: local tile ID.
    ///   - texture: texture for tile at the given id.
    /// - Returns: tileset data (or nil if the data exists).
    @available(*, deprecated, renamed: "addTilesetTile(tileID:texture:)")
    public func addTilesetTile(_ tileID: Int, texture: SKTexture) -> SKTilesetData? {
        return addTilesetTile(tileID: UInt32(tileID), texture: texture)
    }

    /// Add tileset data from an image source (tileset is a collections tileset).
    ///
    /// - Parameters:
    ///   - tileID: local tile ID.
    ///   - source: source image name.
    /// - Returns: tileset data (or nil if the data exists).
    @available(*, deprecated, renamed: "addTilesetTile(tileID:source:)")
    public func addTilesetTile(_ tileID: Int, source: String) -> SKTilesetData? {
        return addTilesetTile(tileID: UInt32(tileID), source: source)
    }

    /// Set(replace) the texture for a given tile id.
    ///
    /// - Parameters:
    ///   - id: tile ID.
    ///   - texture: texture for tile at the given id.
    /// - Returns: previous tile data texture.
    @discardableResult
    @available(*, deprecated, renamed: "setDataTexture(_:texture:)")
    public func setDataTexture(_ id: Int, texture: SKTexture) -> SKTexture? {
        return setDataTexture(tileID: UInt32(id), texture: texture)
    }
}
