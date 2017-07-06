//
//  SKTilemap.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


internal enum TiledColors: String {
    case white  =  "#f7f5ef"
    case grey   =  "#969696"
    case red    =  "#990000"
    case blue   =  "#86b9e3"
    case green  =  "#33cc33"
    case orange =  "#ff9933"
    case debug  =  "#999999"
    
    public var color: SKColor {
        return SKColor(hexString: self.rawValue)
    }
}


/**
 Describes the map's tile orientation (shape).

 - `orthogonal`:   map is orthogonal type.

    ![Orthogonal Map](../Images/orthogonal_mapping.png "Orthogonal Map")
 
 - `isometric`:    map is isometric type.
 
    ![Isometric Map](../Images/isometric_mapping.png "Isometric Map")
 
 - `hexagonal`:    map is hexagonal type.
 
    ![Hexagonal Map](../Images/hexagonal_mapping.png "Hexagonal Map")
 
 - `staggered`:    map is isometric staggered type.

    ![Staggered Map](../Images/staggered_mapping.png "Staggered Isometric Map")
 */
public enum TilemapOrientation: String {
    case orthogonal   = "orthogonal"
    case isometric    = "isometric"
    case hexagonal    = "hexagonal"
    case staggered    = "staggered"
}


internal enum RenderOrder: String {
    case rightDown  = "right-down"
    case rightUp    = "right-up"
    case leftDown   = "left-down"
    case leftUp     = "left-up"
}


/**
 Tilemap data encoding.
 */
internal enum TilemapEncoding: String {
    case base64  = "base64"
    case csv     = "csv"
    case xml     = "xml"
}


/**
 Alignment hint used to position the layers within the `SKTilemap` node.

 - `bottomLeft`:   node bottom left rests at parent zeropoint (0)
 - `center`:       node center rests at parent zeropoint (0.5)
 - `topRight`:     node top right rests at parent zeropoint. (1)
 */
internal enum LayerPosition {
    case bottomLeft
    case center
    case topRight
}

/**
 Hexagonal stagger axis.
 
 - `x`: axis is along the x-coordinate.
 - `y`: axis is along the y-coordinate.
 */
internal enum StaggerAxis: String {
    case x  = "x"
    case y  = "y"
}


/**
 Hexagonal stagger index.
 
 - `even`: stagger evens.
 - `odd`:  stagger odds.
 */
internal enum StaggerIndex: String {
    case odd   
    case even
}


//  Common tile size aliases
internal let TileSizeZero  = CGSize(width: 0, height: 0)
internal let TileSize8x8   = CGSize(width: 8, height: 8)
internal let TileSize16x16 = CGSize(width: 16, height: 16)
internal let TileSize32x32 = CGSize(width: 32, height: 32)


/**
 The `SKTilemapDelegate` protocol is used to implement a delegate that allows your application to interact with a tile map as it is being created.
 
 ### **Symbols**
 
 - `didBeginParsing(_ tilemap: SKTilemap)`
    - called when the tilemap is initialized.
 - `didAddTileset(_ tileset: SKTileset)`
    - called when a tileset is added to the map.
 - `didAddLayer(_ layer: TiledLayerObject)`
    - called when a layer is added to the map.
 - `didReadMap(_ tilemap: SKTilemap)`
    - called when the map is finished parsing (before rendering).
 - `didRenderMap(_ tilemap: SKTilemap)`
    - called when the map is finished rendering.
 - `objectForTile: SKTile.Type`
    - return a `SKTile` object for use building tiles.
*/
public protocol SKTilemapDelegate: class {
    func didBeginParsing(_ tilemap: SKTilemap)
    func didAddTileset(_ tileset: SKTileset)
    func didAddLayer(_ layer: TiledLayerObject)
    func didReadMap(_ tilemap: SKTilemap)
    func didRenderMap(_ tilemap: SKTilemap)
    func objectForTile(className: String?) -> SKTile.Type
}


/**
 The `SKTilemap` class represents a container which manages layers, tiles (sprites), vector objects & images.
 

 - `size`:          `CGSize` tile map size in tiles.
 - `tileSize`:      `CGSize` tile map tile size in pixels.
 - `sizeInPoints`:  `CGSize` tile map size in points.
 
 Tile data is stored in `SKTileset` tile sets.
 */
open class SKTilemap: SKCropNode, SKTiledObject {
    
    open var filename: String!                                    // tiled tmx filename
    open var uuid: String = UUID().uuidString                     // unique id
    open var type: String!                                        // map type
    open var size: CGSize                                         // map size (in tiles)
    open var tileSize: CGSize                                     // tile size (in pixels)
    open var orientation: TilemapOrientation                      // map orientation
    internal var renderOrder: RenderOrder = .rightDown            // render order
    
    internal var maxRenderQuality: CGFloat = 16                   // max render quality
    /// Scaling value for text objects, etc.
    open var renderQuality: CGFloat = 8 {                         // object render quality.
        didSet {
            guard renderQuality != oldValue else { return }
            layers.forEach { $0.renderQuality = (renderQuality > maxRenderQuality) ? maxRenderQuality : renderQuality }
        }
    }
    
    open var isPortrait: Bool {
        return size.height > size.width
    }
    
    // hexagonal
    open var hexsidelength: Int = 0                               // hexagonal side length
    internal var staggeraxis: StaggerAxis = .y                    // stagger axis
    internal var staggerindex: StaggerIndex = .odd                // stagger index.
    
    // camera overrides
    open var worldScale: CGFloat = 1.0                            // initial world scale
    open var currentZoom: CGFloat = 1.0
    open var allowZoom: Bool = true                               // allow camera zoom
    open var allowMovement: Bool = true                           // allow camera movement
    open var minZoom: CGFloat = 0.2
    open var maxZoom: CGFloat = 5.0
    
    // current tile sets
    open var tilesets: Set<SKTileset> = []                        // tilesets
    
    // current layers
    private var _layers: Set<TiledLayerObject> = []               // tile map layers
    open var layerCount: Int { return self.layers.count }         // layer count attribute
    open var properties: [String: String] = [:]                   // custom properties
    open var zDeltaForLayers: CGFloat = 50                        // z-position range for layers
    open var bufferSize: CGFloat = 4.0
    
    /// ignore Tiled background color
    open var ignoreBackground: Bool = false
    public var ignoreProperties: Bool = false                     // ignore custom properties
    
    /// Returns true if all of the child layers are rendered.
    open var isRendered: Bool {
        // make sure the map is finished rendering
        self.renderQueue.sync {}
        return layers.filter { $0.isRendered == false }.count == 0
    }
    
    // dispatch queues & groups
    internal let renderQueue = DispatchQueue(label: "com.sktiled.renderqueue", qos: .userInteractive)  // serial queue
    internal let renderGroup = DispatchGroup()
    internal var tiledversion: Float = 1.0
    
    /// Overlay color.
    open var overlayColor: SKColor = SKColor(hexString: "#40000000")
    /// Object color.
    open var objectColor: SKColor = SKColor.gray
    
    /// Returns a flattened array of child layers.
    open var layers: [TiledLayerObject] {
        var result: [TiledLayerObject] = []
        for layer in _layers.sorted(by: { $0.index > $1.index }) {
            result = result + layer.layers
        }
        return result
    }
    
    /// Optional background color (read from the Tiled file)
    open var backgroundColor: SKColor? = nil {
        didSet {
            self.backgroundSprite.color = (backgroundColor != nil) ? backgroundColor! : SKColor.clear
            self.backgroundSprite.colorBlendFactor = (backgroundColor != nil) ? 1.0 : 0
        }
    }
    
    /// Crop the tilemap at the map edges.
    open var cropAtBoundary: Bool = false {
        didSet {
            if let currentMask = maskNode { currentMask.removeFromParent() }
    
            maskNode = (cropAtBoundary == true) ? SKSpriteNode(color: SKColor.black, size: self.sizeInPoints) : nil
            (maskNode as? SKSpriteNode)?.texture?.filteringMode = .nearest
        }
    }

    /** 
    The tile map default base layer, used for displaying the current grid, getting coordinates, etc.
    */
    lazy open var baseLayer: SKTileLayer = {
        let layer = SKTileLayer(layerName: "Base", tilemap: self)
        self.addLayer(layer, base: true)
        layer.didFinishRendering()
        return layer
    }()
    
    /**
     Sprite background (if different than scene).
     */
    lazy var backgroundSprite: SKSpriteNode = {
        let background = SKSpriteNode(color: self.backgroundColor ?? SKColor.clear, size: self.sizeInPoints)
        self.addChild(background)
        return background
    }()
    
    /**
     Pause overlay.
     */
    lazy var overlay: SKSpriteNode = {
        let pauseOverlayColor = self.backgroundColor ?? SKColor.clear
        let overlayNode = SKSpriteNode(color: pauseOverlayColor.withAlphaComponent(0.5), size: self.sizeInPoints)
        self.addChild(overlayNode)
        overlayNode.zPosition = self.lastZPosition * self.zDeltaForLayers
        return overlayNode
    }()
    
    /// debugging
    internal var loggingLevel: LoggingLevel = .warning
    open var debugMode: Bool = false
    open var color: SKColor = SKColor.clear                            // used for pausing
    open var gridColor: SKColor = SKColor.black                        // color used to visualize the tile grid
    open var frameColor: SKColor = SKColor.black                       // bounding box color
    open var highlightColor: SKColor = SKColor.green                   // color used to highlight tiles
    open var autoResize: Bool = false                                  // indicates map should auto-resize when view changes
    
    open var currentLayerIndex: Int = -1 {
        didSet {
            guard currentLayerIndex != oldValue else { return }
            if currentLayerIndex > self.lastIndex {
                self.isolateLayer(at: -1)
            }
            self.isolateLayer(at: currentLayerIndex)
        }
    }
    
    /// dynamics
    open var gravity: CGVector = CGVector.zero
    
    /// Weak reference to `SKTilemapDelegate` delegate.
    weak open var delegate: SKTilemapDelegate?
    
    /// Size of the map in points.
    open var sizeInPoints: CGSize {
        switch orientation {
        case .orthogonal:
            return CGSize(width: size.width * tileSize.width, height: size.height * tileSize.height)
        case .isometric:
            let side = width + height
            return CGSize(width: side * tileWidthHalf,  height: side * tileHeightHalf)
        case .hexagonal, .staggered:
            var result = CGSize.zero
            if staggerX == true {
                result = CGSize(width: width * columnWidth + sideOffsetX,
                                height: height * (tileHeight + sideLengthY))
                
                if width > 1 { result.height += rowHeight }
            } else {
                result = CGSize(width: width * (tileWidth + sideLengthX),
                                height: height * rowHeight + sideOffsetY)
                
                if height > 1 { result.width += columnWidth }
            }
            return result
        }
    }
    
    /// Rendered size of the map.
    open var renderSize: CGSize {
        // tilesets with larger tile sizes extend render size.
        //var heightPadded = tilesets.map { ($0.tileSize.height + ($0.tileOffset.y) * -1) }.max() ?? 0
        var heightPadded = tilesets.map { $0.tileSize.height + $0.tileOffset.y }.max() ?? 0
        heightPadded = heightPadded - tileSize.height
        let scaledSize = CGSize(width: sizeInPoints.width * xScale, height: sizeInPoints.height * yScale)
        return CGSize(width: scaledSize.width, height: scaledSize.height + heightPadded)
    }
    
    // used to align the layers within the tile map
    internal var layerAlignment: LayerPosition = .center {
        didSet {
            layers.forEach { self.positionLayer($0) }
        }
    }
    
    /// Returns the last GID for all of the tilesets.
    open var lastGID: Int {
        return tilesets.count > 0 ? tilesets.map {$0.lastGID}.max()! : 0
    }    
    
    /// Returns the last index for all tilesets.
    open var lastIndex: Int {
        return _layers.count > 0 ? _layers.map { $0.index }.max()! : 0
    }
    
    /// Returns the last (highest) z-position in the map.
    open var lastZPosition: CGFloat {
        return layers.count > 0 ? layers.map { $0.actualZPosition }.max()! : 0
    }
    
    /// Tile overlap amount. 1 is typically a good value.
    open var tileOverlap: CGFloat = 0.5 {
        didSet {
            guard oldValue != tileOverlap else { return }
            for tileLayer in tileLayers(recursive: true) {
                tileLayer.setTileOverlap(tileOverlap)
            }
        }
    }
    
    /// Global property to show/hide all `SKTileObject` objects.
    open var showObjects: Bool = false {
        didSet {
            guard oldValue != showObjects else { return }
            for objectGroup in objectGroups(recursive: true) {
                objectGroup.showObjects = showObjects
            }
        }
    }
    
    /**
     Return all tile layers. If recursive is false, only returns top-level layers.
     
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    open func tileLayers(recursive: Bool=true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter({ $0 as? SKTileLayer != nil }) as! [SKTileLayer]
    }
    
    /**
     Return all object groups. If recursive is false, only returns top-level layers.
     
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKObjectGroup]` array of object groups.
     */
    open func objectGroups(recursive: Bool=true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter({ $0 as? SKObjectGroup != nil }) as! [SKObjectGroup]
    }
    
    /**
     Return all image layers. If recursive is false, only returns top-level layers.
     
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKImageLayer]` array of image layers.
     */
    open func imageLayers(recursive: Bool=true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter({ $0 as? SKImageLayer != nil }) as! [SKImageLayer]
    }
    
    /**
     Return all group layers. If recursive is false, only returns top-level layers.
     
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKGroupLayer]` array of image layers.
     */
    open func groupLayers(recursive: Bool=true) -> [SKGroupLayer] {
        return getLayers(recursive: recursive).sorted(by: { $0.index < $1.index }).filter({ $0 as? SKGroupLayer != nil }) as! [SKGroupLayer]
    }

    
    /// Global antialiasing of lines
    open var antialiasLines: Bool = false {
        didSet {
            layers.forEach { $0.antialiased = antialiasLines }
        }
    }
    
    /// Global tile count
    open var tileCount: Int {
        return tileLayers(recursive: true).reduce(0) { (result: Int, layer: SKTileLayer) in
            return result + layer.tileCount
        }
    }
    
    /// Pauses the node, and colors all of its children darker.
    override open var isPaused: Bool {
        willSet (pauseValue) {
            // make sure the map is finished rendering
            self.renderQueue.sync {}
            overlay.isHidden = (pauseValue == false)
        }
    }
    
    
    // MARK: - Loading
    
    /**
     Load a Tiled tmx file and return a new `SKTilemap` object. Returns nil if there is a parsing error.
     
     - parameter filename:           `String` Tiled file name.
     - parameter delegate:           `SKTilemapDelegate?` optional [`SKTilemapDelegate`](Protocols/SKTilemapDelegate.html) instance.
     - parameter withTilesets:       `[SKTileset]?` optional tilesets.
     - parameter ignoreProperties:   `Bool` ignore custom properties from Tiled.
     - parameter verbosity:          `LoggingLevel` logging verbosity.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    open class func load(fromFile filename: String,
                         delegate: SKTilemapDelegate? = nil,
                         withTilesets: [SKTileset]? = nil,
                         ignoreProperties noparse: Bool = false,
                         verbosity: LoggingLevel = .info) -> SKTilemap? {
        
        if let tilemap = SKTilemapParser().load(fromFile: filename, delegate: delegate, withTilesets: withTilesets, ignoreProperties: noparse, verbosity: verbosity) {
            return tilemap
        }
        return nil
    }
    
    // MARK: - Init
    /**
     Initialize with dictionary attributes from xml parser.
     
     - parameter attributes: `Dictionary` attributes dictionary.     
     - returns: `SKTileMapNode?`
     */
    public init?(attributes: [String: String]) {
        guard let width = attributes["width"] else { return nil }
        guard let height = attributes["height"] else { return nil }
        guard let tilewidth = attributes["tilewidth"] else { return nil }
        guard let tileheight = attributes["tileheight"] else { return nil }
        guard let orient = attributes["orientation"] else { return nil }
        
        // initialize tile size & map size
        tileSize = CGSize(width: CGFloat(Int(tilewidth)!), height: CGFloat(Int(tileheight)!))
        size = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))
        
        // tile orientation
        guard let tileOrientation: TilemapOrientation = TilemapOrientation(rawValue: orient) else {
            fatalError("orientation \"\(orient)\" not supported.")
        }
        
        self.orientation = tileOrientation
        
        // render order
        if let rendorder = attributes["renderorder"] {
            guard let renderorder: RenderOrder = RenderOrder(rawValue: rendorder) else {
                fatalError("orientation \"\(rendorder)\" not supported.")
            }
            self.renderOrder = renderorder
        }
        
        // hex side
        if let hexside = attributes["hexsidelength"] {
            self.hexsidelength = Int(hexside)!
        }
        
        // hex stagger axis
        if let hexStagger = attributes["staggeraxis"] {
            guard let staggerAxis: StaggerAxis = StaggerAxis(rawValue: hexStagger) else {
                fatalError("stagger axis \"\(hexStagger)\" not supported.")
            }
            self.staggeraxis = staggerAxis
        }
        
        // hex stagger index
        if let hexIndex = attributes["staggerindex"] {
            guard let hexindex: StaggerIndex = StaggerIndex(rawValue: hexIndex) else {
                fatalError("stagger index \"\(hexIndex)\" not supported.")
            }
            self.staggerindex = hexindex
        }
        
        // global antialiasing
        antialiasLines = tileSize.width > 16 ? true : false
        super.init()
        
        // set the background color
        if let backgroundHexColor = attributes["backgroundcolor"] {
            if (ignoreBackground == false){
                backgroundColor = SKColor(hexString: backgroundHexColor)
                
                if let backgroundCGColor = backgroundColor?.withAlphaComponent(0.6) {
                    overlayColor = backgroundCGColor
                }
            }
        }
    }
    
    /**
     Initialize with map size/tile size
     
     - parameter sizeX:     `Int` map width in tiles.
     - parameter sizeY:     `Int` map height in tiles.
     - parameter tileSizeX: `Int` tile width in pixels.
     - parameter tileSizeY: `Int` tile height in pixels.
     - returns: `SKTilemap`
     */
    public init(_ sizeX: Int, _ sizeY: Int,
                _ tileSizeX: Int, _ tileSizeY: Int,
                  orientation: TilemapOrientation = .orthogonal) {
        self.size = CGSize(width: CGFloat(sizeX), height: CGFloat(sizeY))
        self.tileSize = CGSize(width: CGFloat(tileSizeX), height: CGFloat(tileSizeY))
        self.orientation = orientation
        self.antialiasLines = tileSize.width > 16 ? true : false
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tilesets
    
    /**
     Add a tileset to tileset set.
     
     - parameter tileset: `SKTileset` tileset object.
     */
    open func addTileset(_ tileset: SKTileset) {
        tilesets.insert(tileset)
        tileset.tilemap = self
        tileset.ignoreProperties = ignoreProperties
        tileset.parseProperties(completion: nil)
    }
    
    /**
     Remove a tileset from the tilesets.
     
     - parameter tileset: `SKTileset` removed tileset.
     */
    open func removeTileset(_ tileset: SKTileset) -> SKTileset? {
        return tilesets.remove(tileset)
    }
    
    /**
     Returns a named tileset from the tilesets set.
     
     - parameter name: `String` tileset to return.
     - returns: `SKTileset?` tileset object.
     */
    open func getTileset(named name: String) -> SKTileset? {
        if let index = tilesets.index( where: { $0.name == name } ) {
            let tileset = tilesets[index]
            return tileset
        }
        return nil
    }

    /**
     Returns an external tileset with a given filename.

     - parameter filename: `String` tileset source file.
     - returns: `SKTileset?`
     */
    open func getTileset(fileNamed filename: String) -> SKTileset? {
        if let index = tilesets.index( where: { $0.filename == filename } ) {
            let tileset = tilesets[index]
            return tileset
        }
        return nil
    }
    
    // MARK: Coordinates
    /**
     Returns a point for a given coordinate in the layer.
     
     - parameter coord: `CGPoint` tile coordinate.
     - returns: `CGPoint` point in layer.
     */
    open func pointForCoordinate(coord: CGPoint, offsetX: CGFloat=0, offsetY: CGFloat=0) -> CGPoint {
        return baseLayer.pointForCoordinate(coord: coord, offsetX: offsetX, offsetY: offsetY)
    }
    
    /**
     Returns a tile coordinate for a given point in the layer.
     
     - parameter point: `CGPoint` point in layer.
     - returns: `CGPoint` tile coordinate.
     */
    open func coordinateForPoint(_ point: CGPoint) -> CGPoint {
        return baseLayer.coordinateForPoint(point)
    }
    
    // MARK: - Layers
    /**
     Returns an array of child layers, sorted by index (first is lowest, last is highest).
     
     - parameter recursive: `Bool` include nested layers.
     - returns: `[TiledLayerObject]` array of layers.
     */
    open func getLayers(recursive: Bool=true) -> [TiledLayerObject] {
        return (recursive == true) ? self.layers : Array(self._layers)
    }
    
    /**
     Returns all content layers (ie. not groups). Sorted by zPosition in scene.
     
     - returns: `[TiledLayerObject]` array of layers.
     */
    open func getContentLayers() -> [TiledLayerObject] {
        return self.layers.filter( { $0 as? SKGroupLayer == nil }).sorted(by: { $0.actualZPosition > $1.actualZPosition })
    }
    
    /**
     Returns an array of layer names.
     
     - returns: `[String]` layer names.
     */
    open func layerNames() -> [String] {
        return layers.flatMap { $0.name }
    }
    
    /**
     Add a layer to the layers set. Automatically sets zPosition based on the zDeltaForLayers attributes.
     
     - parameter layer:  `TiledLayerObject` layer object.
     - parameter base:   `Bool` layer represents default layer.
     */
    open func addLayer(_ layer: TiledLayerObject, base: Bool=false) {
        
        let nextZPosition = (_layers.count > 0) ? zDeltaForLayers * CGFloat(_layers.count + 1) : zDeltaForLayers
        
        // set the layer index
        layer.index = layers.count > 0 ? lastIndex + 1 : 0
        
        // don't add the default layer
        if base == false { _layers.insert(layer) }
        
        // add the layer as a child
        addChild(layer)
        
        // align the layer to the anchorpoint
        positionLayer(layer)
        layer.zPosition = nextZPosition
        
        // override debugging colors
        layer.gridColor = self.gridColor
        layer.frameColor = self.frameColor
        layer.highlightColor = self.highlightColor
    }
    
    /**
     Remove a layer from the current layers set.
     
     - parameter layer: `TiledLayerObject` layer object.
     - returns: `TiledLayerObject?` removed layer.
     */
    open func removeLayer(_ layer: TiledLayerObject) -> TiledLayerObject? {
        return _layers.remove(layer)
    }
    
    /**
     Create and add a new tile layer.
     
     - parameter named: `String` layer name.
     - returns: `SKTileLayer` new layer.
     */
    open func addNewTileLayer(_ named: String) -> SKTileLayer {
        let layer = SKTileLayer(layerName: named, tilemap: self)
        addLayer(layer)
        return layer
    }
    
    /**
     Return layers matching the given name.
     
     - parameter name:      `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[TiledLayerObject]` layer objects.
     */
    open func getLayers(named layerName: String, recursive: Bool=true) -> [TiledLayerObject] {
        var result: [TiledLayerObject] = []
        let layersToCheck = self.getLayers(recursive: recursive)
        if let index = layersToCheck.index( where: { $0.name == layerName } ) {
            result.append(layersToCheck[index])
        }
        return result
    }
    
    /**
     Returns a layer matching the given UUID.
     
     - parameter uuid: `String` tile layer UUID.
     - returns: `TiledLayerObject?` layer object.
     */
    open func getLayer(withID uuid: String) -> TiledLayerObject? {
        if let index = layers.index( where: { $0.uuid == uuid } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Returns a layer given the index (0 being the lowest).
     
     - parameter index: `Int` layer index.
     - returns: `TiledLayerObject?` layer object.
     */
    open func getLayer(atIndex index: Int) -> TiledLayerObject? {
        if let index = _layers.index( where: { $0.index == index } ) {
            let layer = _layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Return layers assigned a custom `type` property.
     
     - parameter ofType:    `String` layer type.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[TiledLayerObject]` array of layers.
     */
    open func getLayers(ofType: String, recursive: Bool=true) -> [TiledLayerObject] {
        return getLayers(recursive: recursive).filter { $0.type != nil }.filter { $0.type! == ofType }
    }
    
    /**
     Isolate a layer at the given index.
     
     - parameter at: `Int` layer index.
     */
    open func isolateLayer(at index: Int) {
        guard index >= 0 else {
            let _ = _layers.map { $0.visible = true }
            return
        }
        
        _layers.forEach { layer in
            let hideLayer = (layer.index == index) ? false : true
            layer.isHidden = hideLayer
        }
    }
    
    /**
     Return tile layers matching the given name. If recursive is false, only returns top-level layers.
     
     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileLayer]` array of tile layers.
     */
    open func tileLayers(named layerName: String, recursive: Bool=true) -> [SKTileLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKTileLayer != nil }.filter { $0.name == layerName } as! [SKTileLayer]
    }
    
    /**
     Returns a tile layer at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.
     - returns: `SKTileLayer?` matching tile layer.
     */
    open func tileLayer(atIndex index: Int) -> SKTileLayer? {
        if let layerIndex = tileLayers(recursive: false).index( where: { $0.index == index } ) {
            let layer = tileLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Return object groups matching the given name. If recursive is false, only returns top-level layers.
     
     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKObjectGroup]` array of object groups.
     */
    open func objectGroups(named layerName: String, recursive: Bool=true) -> [SKObjectGroup] {
        return getLayers(recursive: recursive).filter { $0 as? SKObjectGroup != nil }.filter { $0.name == layerName } as! [SKObjectGroup]
    }
    
    /**
     Returns an object group at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.
     - returns: `SKObjectGroup?` matching group layer.
     */
    open func objectGroup(atIndex index: Int) -> SKObjectGroup? {
        if let layerIndex = objectGroups(recursive: false).index( where: { $0.index == index } ) {
            let layer = objectGroups(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Return image layers matching the given name. If recursive is false, only returns top-level layers.
     
     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKImageLayer]` array of image layers.
     */
    open func imageLayers(named layerName: String, recursive: Bool=true) -> [SKImageLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKImageLayer != nil }.filter { $0.name == layerName } as! [SKImageLayer]
    }
    
    /**
     Returns an image layer at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.
     - returns: `SKImageLayer?` matching image layer.
     */
    open func imageLayer(atIndex index: Int) -> SKImageLayer? {
        if let layerIndex = imageLayers(recursive: false).index( where: { $0.index == index } ) {
            let layer = imageLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Return group layers matching the given name. If recursive is false, only returns top-level layers.
     
     - parameter named:     `String` tile layer name.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKGroupLayer]` array of group layers.
     */
    open func groupLayers(named layerName: String, recursive: Bool=true) -> [SKGroupLayer] {
        return getLayers(recursive: recursive).filter { $0 as? SKGroupLayer != nil }.filter { $0.name == layerName } as! [SKGroupLayer]
    }
    
    /**
     Returns an group layer at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.
     - returns: `SKGroupLayer?` matching group layer.
     */
    open func groupLayer(atIndex index: Int) -> SKGroupLayer? {
        if let layerIndex = groupLayers(recursive: false).index( where: { $0.index == index } ) {
            let layer = groupLayers(recursive: false)[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Position child layers in relation to the map's anchorpoint.
     
     - parameter layer: `TiledLayerObject` layer.
     */
    internal func positionLayer(_ layer: TiledLayerObject) {
        var layerPos = CGPoint.zero
        switch orientation {
            
        case .orthogonal:
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
        
            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
        
        case .isometric:
            // layer offset
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
            
        case .hexagonal, .staggered:
            layerPos.x = -sizeInPoints.width * layerAlignment.anchorPoint.x
            layerPos.y = sizeInPoints.height * layerAlignment.anchorPoint.y
            
            // layer offset
            layerPos.x += layer.offset.x
            layerPos.y -= layer.offset.y
        }
        
        layer.position = layerPos
    }
    
    /**
     Sort the layers in z based on a starting value (defaults to the current zPosition).
        
     - parameter from: `CGFloat?` optional starting z-positon.
     */
    open func sortLayers(from: CGFloat?=nil) {
        let startingZ: CGFloat = (from != nil) ? from! : zPosition
        getLayers().forEach { $0.zPosition = startingZ + (zDeltaForLayers * CGFloat($0.index)) }
    }
    
    // MARK: - Tiles
    
    /**
     Return tiles at the given point (all tile layers).
     
     - parameter point: `CGPoint` position in tilemap.
     - returns: `[SKTile]` array of tiles.
     */
    open func tilesAt(point: CGPoint) -> [SKTile] {
        return nodes(at: point).filter { node in
            node as? SKTile != nil
        } as! [SKTile]
    }
    
    /**
     Return tiles at the given coordinate (all tile layers).
     
     - parameter coord: `CGPoint` coordinate.
     - returns: `[SKTile]` array of tiles.
     */
    open func tilesAt(coord: CGPoint) -> [SKTile] {
        return tileLayers(recursive: true).flatMap { $0.tileAt(coord: coord) }
    }

    /**
     Return tiles at the given coordinate (all tile layers).
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` - y-coordinate.
     - returns: `[SKTile]` array of tiles.
     */
    open func tilesAt(_ x: Int, _ y: Int) -> [SKTile] {
        return tilesAt(coord: CGPoint(x: CGFloat(x), y: CGFloat(y)))
    }
    
    /**
     Returns a tile at the given coordinate from a layer.
     
     - parameter coord:    `CGPoint` tile coordinate.
     - parameter inLayer:  `String?` layer name.
     - returns: `SKTile?` tile, or nil.
     */
    open func tileAt(coord: CGPoint, inLayer named: String?) -> SKTile? {
        if let named = named {
            if let layer = getLayers(named: named).first as? SKTileLayer {
                return layer.tileAt(coord: coord)
            }
        }
        return nil
    }
    
    /**
     Returns a tile at the given coordinate from a layer.
     
     - parameter x: `Int` tile x-coordinate.
     - parameter y: `Int` tile y-coordinate.
     - parameter named: `String?` layer name.
     - returns: `SKTile?` tile, or nil.
     */
    open func tileAt(_ x: Int, _ y: Int, inLayer named: String?) -> SKTile? {
        return tileAt(coord: CGPoint(x: CGFloat(x), y: CGFloat(y)), inLayer: named)
    }
    
    /**
     Returns tiles with a property of the given type. If recursive is false, only returns tiles from top-level layers.
     
     - parameter type:      `String` type.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTiles(ofType type: String, recursive: Bool=true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles(ofType: type) }
    }
    
    /**
     Returns tiles with the given global id. If recursive is false, only returns tiles from top-level layers.
     
     - parameter globalID:  `Int` tile globla id.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTiles(globalID: Int, recursive: Bool=true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.getTiles(globalID: globalID) }
    }
    
    /**
     Returns tiles with a property of the given type & value. If recursive is false, only returns tiles from top-level layers.
     
     - parameter named: `String` property name.
     - parameter value: `Any` property value.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTilesWithProperty(_ named: String, _ value: Any, recursive: Bool=true) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers(recursive: recursive) {
            result += layer.getTilesWithProperty(named, value as! String as Any)
        }
        return result
    }
    
    /**
     Returns an array of all animated tile objects.
     
     - returns: `[SKTile]` array of tiles.
     */
    open func animatedTiles(recursive: Bool=true) -> [SKTile] {
        return tileLayers(recursive: recursive).flatMap { $0.animatedTiles() }
    }
    
    /**
     Return the top-most tile at the given coordinate.
     
     - parameter coord: `CGPoint` coordinate.
     - returns: `SKTile?` first tile in layers.
     */
    open func firstTileAt(coord: CGPoint) -> SKTile? {
        for layer in tileLayers(recursive: true).reversed().filter({ $0.visible == true }) {
            if let tile = layer.tileAt(coord: coord) {
                return tile
            }
        }
        return nil
    }
    
    // MARK: - Data
    /**
     Returns data for a global tile id.
     
     - parameter globalID: `Int` global tile id.
     - returns: `SKTilesetData` tile data, if it exists.
     */
    open func getTileData(globalID gid: Int) -> SKTilesetData? {
        let realID = flippedTileFlags(id: UInt32(gid)).gid
        for tileset in tilesets where tileset.contains(globalID: realID){
            if let tileData = tileset.getTileData(globalID: Int(realID)) {
                return tileData
            }
        }
        return nil
    }
    
    /**
     Return tile data with a property of the given type (all tilesets).
     
     - parameter named: `String` property name.
     - returns: `[SKTilesetData]` array of tile data.
     */
    open func getTileData(withProperty named: String) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(withProperty: named) }
    }
    
    /**
     Return tile data with a property of the given type (all tile layers).
     
     - parameter named: `String` property name.
     - parameter value: `Any` property value.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTileData(withProperty named: String, _ value: Any) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(withProperty: named, value) }
    }
    
    // MARK: - Objects
    
    /**
     Return obejects at the given point (all object groups).
     
     - parameter coord: `CGPoint` coordinate.
     - returns: `[SKTileObject]` array of objects.
     */
    open func objectsAt(point: CGPoint) -> [SKTileObject] {
        return nodes(at: point).filter { node in
            node as? SKTileObject != nil
            } as! [SKTileObject]
    }
    
    /**
     Return all of the current tile objects. If recursive is false, only returns tiles from top-level layers.
     
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    open func getObjects(recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects() }
    }
    
    /**
     Return objects matching a given type. If recursive is false, only returns tiles from top-level layers.
     
     - parameter type:      `String` object type to query.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    open func getObjects(ofType type: String, recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(ofType: type) }
    }
    
    /**
     Return objects matching a given name. If recursive is false, only returns tiles from top-level layers.
     
     - parameter named:     `String` object name to query.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    open func getObjects(named: String, recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(named: named) }
    }
    
    /**
     Return objects with the given text value. If recursive is false, only returns tiles from top-level layers.
     
     - parameter withText:   `String` text value.
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` array of objects.
     */
    open func getObjects(withText text: String, recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.getObjects(withText: text) }
    }
    
    /**
     Returns an object with the given id.
     
     - parameter id: `Int` Object id.
     - returns: `SKTileObject?`
     */
    open func getObject(withID id: Int) -> SKTileObject? {
        return objectGroups(recursive: true).flatMap { $0.getObject(withID: id) }.first
    }
    
    /**
     Return objects with a tile id. If recursive is false, only returns tiles from top-level layers.
     
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` objects with a tile gid.
     */
    open func tileObjects(recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.tileObjects() }
    }
    
    /**
     Return text objects. If recursive is false, only returns tiles from top-level layers.
     
     - parameter recursive: `Bool` include nested layers.
     - returns: `[SKTileObject]` text objects.
     */
    open func textObjects(recursive: Bool=true) -> [SKTileObject] {
        return objectGroups(recursive: recursive).flatMap { $0.textObjects() }
    }
    
    // MARK: - Coordinates
    
    
    /**
     Returns a touch location in negative-y space.
     
     *Position is in converted space*
     
     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    #if os(iOS) || os(tvOS)
    open func touchLocation(_ touch: UITouch) -> CGPoint {
        return baseLayer.touchLocation(touch)
    }
    #endif
    
    /**
     Returns a mouse event location in negative-y space.
     
     *Position is in converted space*
    
     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    #if os(OSX)
    public func mouseLocation(event: NSEvent) -> CGPoint {
        return baseLayer.mouseLocation(event: event)
    }
    #endif
    
    // MARK: - Callbacks
    /**
     Called when parser has finished reading the map.
     
     - parameter timeStarted: `Date` render start time.
     - parameter tasks:       `Int`  number of tasks to complete.
     */
    open func didFinishParsing(timeStarted: Date, tasks: Int=0) {}
    
    /**
     Called when parser has finished rendering the map.
     
     - parameter timeStarted: `Date` render start time.
     */
    open func didFinishRendering(timeStarted: Date) {
        
        // set the z-depth of the baseLayer & background sprite
        baseLayer.zPosition = lastZPosition + (zDeltaForLayers * 0.5)
        backgroundSprite.zPosition = -zDeltaForLayers
        
        // time results
        let timeInterval = Date().timeIntervalSince(timeStarted)
        let timeStamp = String(format: "%.\(String(3))f", timeInterval)        
        if loggingLevel.rawValue <= 1 {
            print("\n ✽ Success! tilemap \"\(name != nil ? name! : "null")\" rendered in: \(timeStamp)s ✽\n")
        }
        
        // transfer attributes
        scene?.physicsWorld.gravity = gravity
        
        // delegate callback
        defer {
            self.delegate?.didRenderMap(self)
        }
    }
}


// MARK: - Extensions

extension TilemapOrientation {
    
    /// Hint for aligning tiles within each layer.
    public var alignmentHint: CGPoint {
        switch self {
        case .orthogonal:
            return CGPoint(x: 0.5, y: 0.5)
        case .isometric:
            return CGPoint(x: 0.5, y: 0.5)
        case .hexagonal:
            return CGPoint(x: 0.5, y: 0.5)
        case .staggered:
            return CGPoint(x: 0.5, y: 0.5)
        }
    }
}


extension LayerPosition: CustomStringConvertible {
    
    internal var description: String {
        return "\(name): (\(self.anchorPoint.x), \(self.anchorPoint.y))"
    }

    internal var name: String {
        switch self {
        case .bottomLeft: return "Bottom Left"
        case .center: return "Center"
        case .topRight: return "Top Right"
        }
    }
    
    internal var anchorPoint: CGPoint {
        switch self {
        case .bottomLeft: return CGPoint(x: 0, y: 0)
        case .center: return CGPoint(x: 0.5, y: 0.5)
        case .topRight: return CGPoint(x: 1, y: 1)
        }
    }
}


extension StaggerAxis {
    internal var hextype: String {
        switch self {
        case .x:
            return "flat"
        default:
            return "pointy"
        }
    }
}


extension SKTilemap {
    
    /// Return a string representing the map name.
    public var mapName: String {
        return self.name ?? "null"
    }
    
    /// convenience properties
    public var width: CGFloat { return size.width }
    public var height: CGFloat { return size.height }
   
    /// Returns the current tile width
    public var tileWidth: CGFloat {
        switch orientation {
        case .staggered:
            return CGFloat(Int(tileSize.width) & ~1)
        default:
            return tileSize.width
        }
    }
    
    /// Returns the current tile height
    public var tileHeight: CGFloat {
        switch orientation {
        case .staggered:
            return CGFloat(Int(tileSize.height) & ~1)
        default:
            return tileSize.height
        }
    }
    
    public var tileWidthHalf: CGFloat { return tileWidth / 2 }
    public var tileHeightHalf: CGFloat { return tileHeight / 2 }
    public var sizeHalved: CGSize { return CGSize(width: size.width / 2, height: size.height / 2)}
    public var tileSizeHalved: CGSize { return CGSize(width: tileWidthHalf, height: tileHeightHalf)}
    
    // hexagonal/staggered
    public var staggerX: Bool { return (staggeraxis == .x) }
    public var staggerEven: Bool { return staggerindex == .even }
    
    public var sideLengthX: CGFloat { return (staggeraxis == .x) ? CGFloat(hexsidelength) : 0 }
    public var sideLengthY: CGFloat { return (staggeraxis == .y) ? CGFloat(hexsidelength) : 0 }
    
    public var sideOffsetX: CGFloat { return (tileWidth - sideLengthX) / 2 }
    public var sideOffsetY: CGFloat { return (tileHeight - sideLengthY) / 2 }
    
    // coordinate grid values for hex/staggered
    public var columnWidth: CGFloat { return sideOffsetX + sideLengthX }
    public var rowHeight: CGFloat { return sideOffsetY + sideLengthY }
    
    // MARK: - Hexagonal / Staggered methods
    /**
     Returns true if the given x-coordinate represents a staggered (offset) column.
     
     - parameter x:  `Int` map x-coordinate.
     - returns: `Bool` column should be staggered.
     */
    internal func doStaggerX(_ x: Int) -> Bool {
        return staggerX && Bool((x & 1) ^ staggerEven.hashValue)
    }
    
    /**
     Returns true if the given y-coordinate represents a staggered (offset) row.
     
     - parameter x:  `Int` map y-coordinate.
     - returns: `Bool` row should be staggered.
     */
    internal func doStaggerY(_ y: Int) -> Bool {
        return !staggerX && Bool((y & 1) ^ staggerEven.hashValue)
    }
        
    internal func topLeft(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        // if the value of y is odd & stagger index is odd
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y - 1)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        } else {
            // if the value of x is odd & stagger index is odd
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        }
    }
            
    internal func topRight(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {           
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y - 1)
            } else {
                return CGPoint(x: x, y: y - 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y)
            } else {
                return CGPoint(x: x + 1, y: y - 1)
            }
        }
    }
    
    internal func bottomLeft(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y + 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y)
            }
        }
    }
    
    internal func bottomRight(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x, y: y + 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x + 1, y: y)
            }
        }
    }
    
    override open var description: String {
        var sizedesc = "\(sizeInPoints.shortDescription): (\(size.shortDescription) @ \(tileSize.shortDescription))"
        if (orientation == .hexagonal) {
            sizedesc += " hex: \(staggeraxis.hextype), axis: \(staggeraxis), index: \(staggerindex)"
        }
        return "Map: \(mapName), \(sizedesc), \(tileCount) tiles"
    }
    
    override open var debugDescription: String { return description }
    
    /// Visualize the map's grid.
    open var showGrid: Bool {
        get {
            return baseLayer.showGrid
        }
        set {
            guard newValue != baseLayer.showGrid else { return }
            baseLayer.showGrid = newValue
        }
    }
    
    /// Visualize the map's bounding box.
    open var showBounds: Bool {
        get {
            return baseLayer.showBounds
        }
        set {
            guard newValue != baseLayer.showBounds else { return }
            baseLayer.showBounds = newValue
        }
    }
    
    /// Visualize the current grid & bounds.
    open var debugDraw: Bool {
        get {
            return baseLayer.debugDraw
        } set {
            guard newValue != baseLayer.debugDraw else { return }
            baseLayer.debugDraw = newValue
            // show bounding box for renderable objects
            for objectLayer in objectGroups(recursive: true) {
                (objectLayer.getObjects().filter { $0.isRenderableType == true }.forEach { $0.drawObject(debug: newValue) })
            }
        }
    }
    
    /**
     Dump a summary of the current scenes layer data.
     */
    open func layerStatistics() {
        guard (layerCount > 0) else {
            print("# Tilemap \"\(mapName)\": 0 Layers")
            return
        }
        
        
        // format the header
        let headerString = "# Tilemap \"\(mapName)\": \(tileCount) Tiles: \(layerCount) Layers"
        let titleUnderline = String(repeating: "-", count: headerString.characters.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"
        
        var allLayers = self.layers
        allLayers.insert(self.baseLayer, at: 0)
        // grab the stats from each layer
        let allLayerStats = allLayers.map { $0.layerStatsDescription }
        
        
        var prefixes: [String] = ["", "", "", "", "pos", "size", "offset", "anc", "zpos", "opac"]
        var buffers: [Int] = [1, 2, 0, 0, 1, 1, 1, 1, 1, 1]
        var columnSizes: [Int] = Array(repeating: 0, count: prefixes.count)
        
        
        for (_, stats) in allLayerStats.enumerated() {
            for stat in stats {
                let colIndex = Int(stats.index(of: stat)!)
                
                let colCharacters = stat.characters.count
                let prefix = prefixes[colIndex]
                let buffer = buffers[colIndex]

                if colCharacters > 0 {
                    let bufferSize = (prefix.characters.count > 0 ) ? prefix.characters.count + buffer : 2
                    let columnSize = colCharacters + bufferSize
                    if columnSize > columnSizes[colIndex] {
                         columnSizes[colIndex] = columnSize
                    }
                }
            }
        }
        
        
        
        for (_, stats) in allLayerStats.enumerated() {
            var layerOutputString = ""
            for (sidx, stat) in stats.enumerated() {
                
                let columnSize = columnSizes[sidx]
                let buffer = buffers[sidx]
                
                let isLastColumn = (sidx == stats.count - 1)
                // format the prefix for each column
                var prefix  = ""
                var divider = ""
                var comma   = ""
                
                var currentColumnValue = " "
                
                // for empty values, add an extra buffer
                var emptyBuffer = 2
                if stat.characters.count > 0 {
                    emptyBuffer = 0
                    prefix = prefixes[sidx]
                    if prefix.characters.count > 0 {
                        divider = ": "
                        if isLastColumn == false {
                            comma = ", "
                        }
                        prefix = "\(prefix)\(divider)"
                    }
                    
                    currentColumnValue = "\(prefix)\(stat)\(comma)"
                }
                
                let fillSize = columnSize + comma.characters.count + buffer + emptyBuffer
                layerOutputString += currentColumnValue.zfill(length: fillSize, pattern: " ", padLeft: false)
            }
            
            outputString += "\n\(layerOutputString)"
        }

        print("\n" + outputString + "\n")
    }
}


/**
 Default implementations of callbacks.
 */
extension SKTilemapDelegate {
    /**
     Called when the tilemap is instantiated.

     - parameter tilemap:  `SKTilemap` tilemap instance.
     */
    public func didBeginParsing(_ tilemap: SKTilemap) {}
    /**
     Called when a tileset is instantiated.

     - parameter tileset:  `SKTileset` tileset instance.
     */
    public func didAddTileset(_ tileset: SKTileset) {}
    /**
     Called when a layer is added to a tilemap.

     - parameter layer:  `TiledLayerObject` tilemap instance.
     */
    public func didAddLayer(_ layer: TiledLayerObject) {}
    /**
     Called when the tilemap is finished parsing.

     - parameter tilemap:  `SKTilemap` tilemap instance.
     */
    public func didReadMap(_ tilemap: SKTilemap) {}
    /**
     Called when the tilemap layers are finished rendering.

     - parameter tilemap:  `SKTilemap` tilemap instance.
     */
    public func didRenderMap(_ tilemap: SKTilemap, _ completion: (()->())? = nil) {}
    /**
     Returns a tile object for use in tile layers.

     - parameter className:  `String` optional class name.
     - returns `SKTile.self`:  `SKTile` subclass.
     */
    public func objectForTile(className: String? = nil) -> SKTile.Type { return SKTile.self }
}


// MARK: - Deprecated

extension SKTilemap {
    
    /**
     Returns an array of all child layers, sorted by index (first is lowest, last is highest).
     
     - returns: `[TiledLayerObject]` array of layers.
     */
    @available(*, deprecated, message: "use `getLayers()` instead")
    open func allLayers() -> [TiledLayerObject] {
        return layers.sorted(by: { $0.index < $1.index })
    }
    
    /**
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer name.
     - returns: `TiledLayerObject?` layer object.
     */
    @available(*, deprecated, message: "use `getLayers(named:)` instead")
    open func getLayer(named layerName: String) -> TiledLayerObject? {
        if let index = layers.index( where: { $0.name == layerName } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Returns a named tile layer if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.
     - returns: `SKTileLayer?`
     */
    @available(*, deprecated, message: "use `tileLayers(named:)` instead")
    open func tileLayer(named name: String) -> SKTileLayer? {
        if let layerIndex = tileLayers().index( where: { $0.name == name } ) {
            let layer = tileLayers()[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns a named object group if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.
     - returns: `SKObjectGroup?`
     */
    @available(*, deprecated, message: "use `objectGroups(named:)` instead")
    open func objectGroup(named name: String) -> SKObjectGroup? {
        if let layerIndex = objectGroups().index( where: { $0.name == name } ) {
            let layer = objectGroups()[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Output a summary of the current scenes layer data.
     */
    @available(*, deprecated, message: "use `layerStatistics()` instead")
    open func debugLayers(reverse: Bool=false) {
        layerStatistics()
    }
}

