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

    ![Orthogonal Map](../../Images/orthogonal_mapping.png "Orthogonal Map")
 
 - `isometric`:    map is isometric type.
 
    ![Isometric Map](../../Images/isometric_mapping.png "Isometric Map")
 
 - `hexagonal`:    map is hexagonal type.
 
    ![Hexagonal Map](../../Images/hexagonal_mapping.png "Hexagonal Map")
 
 - `staggered`:    map is isometric staggered type.
 
    ![Staggered Map](../../Images/staggered_mapping.png "Staggered Isometric Map")
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
 Tile offset hint for coordinate conversion.
 
 ```
    center:        returns the center of the tile.
    top:           returns the top of the tile.
    topLeft:       returns the top left of the tile.
    topRight:      returns the top left of the tile.
    bottom:        returns the bottom of the tile.
    bottomLeft:    returns the bottom left of the tile.
    bottomRight:   returns the bottom right of the tile.
    left:          returns the left side of the tile.
    right:         returns the right side of the tile.
 ```
 */
public enum TileOffset: Int {
    case center
    case top
    case topLeft
    case topRight
    case bottom
    case bottomLeft
    case bottomRight
    case left
    case right
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
 */
public protocol SKTilemapDelegate: class {
    /// Called when the tilemap is instantiated.
    func didBeginParsing(_ tilemap: SKTilemap)
    /// Called when a tileset has been added.
    func didAddTileset(_ tileset: SKTileset)
    /// Called when a layer has been added.
    func didAddLayer(_ layer: TiledLayerObject)
    /// Called before layers are rendered.
    func didReadMap(_ tilemap: SKTilemap)
    /// Called when layers are rendered. Perform post-processing here.
    func didRenderMap(_ tilemap: SKTilemap)
}


/**
 The `SKTilemap` class represents a container which manages layers, tiles (sprites), vector objects & images.
 
 - size:         tile map size in tiles.
 - tileSize:     tile map tile size in pixels.
 - sizeInPoints: tile map size in points.
 
 Tile data is stored in `SKTileset` tile sets.
 */
open class SKTilemap: SKNode, SKTiledObject {
    
    open var filename: String!                                    // tilemap filename
    open var uuid: String = UUID().uuidString                     // unique id
    open var size: CGSize                                         // map size (in tiles)
    open var tileSize: CGSize                                     // tile size (in pixels)
    open var orientation: TilemapOrientation                      // map orientation
    internal var renderOrder: RenderOrder = .rightDown            // render order
    
    // hexagonal
    open var hexsidelength: Int = 0                               // hexagonal side length
    internal var staggeraxis: StaggerAxis = .y                    // stagger axis
    internal var staggerindex: StaggerIndex = .odd                // stagger index.
    
    // camera overrides
    open var worldScale: CGFloat = 1.0                            // initial world scale
    open var allowZoom: Bool = true                               // allow camera zoom
    open var allowMovement: Bool = true                           // allow camera movement
    open var minZoom: CGFloat = 0.2
    open var maxZoom: CGFloat = 5.0
    
    // current tile sets
    open var tilesets: Set<SKTileset> = []                        // tilesets
    
    // current layers
    private var layers: Set<TiledLayerObject> = []                // tile map layers
    open var layerCount: Int { return self.layers.count }         // layer count attribute
    open var properties: [String: String] = [:]                   // custom properties
    open var zDeltaForLayers: CGFloat = 50                        // z-position range for layers
    
    /// ignore Tiled background color
    open var ignoreBackground: Bool = false
    
    /// Optional background color (read from the Tiled file)
    open var backgroundColor: SKColor? = nil {
        didSet {
            self.backgroundSprite.color = (backgroundColor != nil) ? backgroundColor! : SKColor.clear
            self.backgroundSprite.colorBlendFactor = (backgroundColor != nil) ? 1.0 : 0
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
    
    // debugging
    open var debugMode: Bool = false
    open var color: SKColor = SKColor.clear                            // used for pausing
    open var gridColor: SKColor = SKColor.black                        // color used to visualize the tile grid
    open var frameColor: SKColor = SKColor.black                       // bounding box color
    open var highlightColor: SKColor = SKColor.green                   // color used to highlight tiles
    open var autoResize: Bool = false                                  // auto-size the map when resized
    
    // dynamics
    open var gravity: CGVector = CGVector.zero
    
    /// Weak reference to `SKTilemapDelegate` delegate.
    weak open var delegate: SKTilemapDelegate?
    
    /// Rendered size of the map in points.
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
        return layers.count > 0 ? layers.map {$0.index}.max()! : 0
    }
    
    /// Returns the last (highest) z-position in the map.
    open var lastZPosition: CGFloat {
        return layers.count > 0 ? layers.map {$0.zPosition}.max()! : 0
    }
    
    /// Tile overlap amount. 1 is typically a good value.
    open var tileOverlap: CGFloat = 0.5 {
        didSet {
            guard oldValue != tileOverlap else { return }
            for tileLayer in tileLayers {
                tileLayer.setTileOverlap(tileOverlap)
            }
        }
    }
    
    /// Global property to show/hide all `SKTileObject` objects.
    open var showObjects: Bool = false {
        didSet {
            guard oldValue != showObjects else { return }
            for objectGroup in objectGroups {
                // show any hidden object layers
                objectGroup.visible = (showObjects == true) ? true : objectGroup.visible
                objectGroup.showObjects = showObjects
            }
        }
    }
    
    /// Convenience property to return all tile layers.
    open var tileLayers: [SKTileLayer] {
        return layers.sorted(by: {$0.index < $1.index}).filter({$0 as? SKTileLayer != nil}) as! [SKTileLayer]
    }
    
    /// Convenience property to return all object groups.
    open var objectGroups: [SKObjectGroup] {
        return layers.sorted(by: {$0.index < $1.index}).filter({$0 as? SKObjectGroup != nil}) as! [SKObjectGroup]
    }
    
    /// Convenience property to return all image layers.
    open var imageLayers: [SKImageLayer] {
        return layers.sorted(by: {$0.index < $1.index}).filter({$0 as? SKImageLayer != nil}) as! [SKImageLayer]
    }
    
    /// Global antialiasing of lines
    open var antialiasLines: Bool = false {
        didSet {
            layers.forEach { $0.antialiased = antialiasLines }
        }
    }
    
    /// Global tile count
    open var tileCount: Int {
        return tileLayers.reduce(0) { (result: Int, layer: SKTileLayer) in
            return result + layer.tileCount
        }
    }
    
    /// Pauses the node, and colors all of its children darker.
    override open var isPaused: Bool {
        didSet {
            guard oldValue != isPaused else { return }
            let newColor: SKColor = isPaused ? SKColor(white: 0, alpha: 0.25) : SKColor.clear
            let newColorBlendFactor: CGFloat = isPaused ? 0.2 : 0.0
            
            speed = isPaused ? 0 : 1.0
            color = newColor
            
            layers.forEach { layer in
                layer.color = newColor
                layer.colorBlendFactor = newColorBlendFactor
                layer.isPaused = isPaused
                //layer.speed = speed
            }
        }
    }

    // MARK: - Loading
    
    /**
     Load a Tiled tmx file and return a new `SKTilemap` object. Returns nil if there is a problem reading the file
     
     - parameter filename:    `String` Tiled file name.
     - parameter delegate:    `SKTilemapDelegate?` optional tilemap delegate instance.
     - parameter withTilesets `[SKTileset]?` optional tilesets.
     - returns: `SKTilemap?` tilemap object (if file read succeeds).
     */
    open class func load(fromFile filename: String,
                         delegate: SKTilemapDelegate? = nil,
                         withTilesets: [SKTileset]? = nil) -> SKTilemap? {
        if let tilemap = SKTilemapParser().load(fromFile: filename, delegate: delegate, withTilesets: withTilesets) {
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
        
        // background color
        if let backgroundHexColor = attributes["backgroundcolor"] {
            if (ignoreBackground == false){
                backgroundColor = SKColor(hexString: backgroundHexColor)
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
     Returns all layers, sorted by index (first is lowest, last is highest).
     
     - returns: `[TiledLayerObject]` array of layers.
     */
    open func allLayers() -> [TiledLayerObject] {
        return layers.sorted(by: {$0.index < $1.index})
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
        // set the layer index
        layer.index = layers.count > 0 ? lastIndex + 1 : 0
        
        // setup the layer
        layer.opacity = 0
        
        // don't add the default layer
        if base == false {
            layers.insert(layer)
        }
        addChild(layer)
        
        // align the layer to the anchorpoint
        positionLayer(layer)
        layer.zPosition = zDeltaForLayers * CGFloat(layer.index)
        
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
        return layers.remove(layer)
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
     Returns a named tile layer from the layers set.
     
     - parameter name: `String` tile layer name.
     - returns: `TiledLayerObject?` layer object.
     */
    open func getLayer(named layerName: String) -> TiledLayerObject? {
        if let index = layers.index( where: { $0.name == layerName } ) {
            let layer = layers[index]
            return layer
        }
        return nil
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
        if let index = layers.index( where: { $0.index == index } ) {
            let layer = layers[index]
            return layer
        }
        return nil
    }
    
    /**
     Isolate a named layer (hides other layers). Pass `nil`
     to show all layers.
     
     - parameter named: `String` layer name.
     */
    open func isolateLayer(_ named: String? = nil) {
        guard named != nil else {
            layers.forEach {$0.visible = true}
            return
        }
        
        layers.forEach {
            let isHidden: Bool = $0.name == named ? true : false
            $0.visible = isHidden
        }
    }
    
    /**
     Returns a named tile layer if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.
     - returns: `SKTileLayer?`
     */
    open func tileLayer(named name: String) -> SKTileLayer? {
        if let layerIndex = tileLayers.index( where: { $0.name == name } ) {
            let layer = tileLayers[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns a tile layer at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.
     - returns: `SKTileLayer?`
     */
    open func tileLayer(atIndex index: Int) -> SKTileLayer? {
        if let layerIndex = tileLayers.index( where: { $0.index == index } ) {
            let layer = tileLayers[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns a named object group if it exists, otherwise, nil.
     
     - parameter named: `String` tile layer name.
     - returns: `SKObjectGroup?`
     */
    open func objectGroup(named name: String) -> SKObjectGroup? {
        if let layerIndex = objectGroups.index( where: { $0.name == name } ) {
            let layer = objectGroups[layerIndex]
            return layer
        }
        return nil
    }
    
    /**
     Returns an object group at the given index, otherwise, nil.
     
     - parameter atIndex: `Int` layer index.
     - returns: `SKObjectGroup?`
     */
    open func objectGroup(atIndex index: Int) -> SKObjectGroup? {
        if let layerIndex = objectGroups.index( where: { $0.index == index } ) {
            let layer = objectGroups[layerIndex]
            return layer
        }
        return nil
    }

    /**
     Returns the index of a named layer.
     
     - parameter named: `String` layer name.
     - returns: `Int` layer index.
     */
    open func indexOf(layedNamed named: String) -> Int {
        if let layer = getLayer(named: named) {
            return layer.index
        }
        return 0
    }
    
    /**
     Position child layers in relation to the anchorpoint.
     
     - parameter layer: `TiledLayerObject` layer.
     */
    fileprivate func positionLayer(_ layer: TiledLayerObject) {
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
        
     - parameter fromZ: `CGFloat?` optional starting z-positon.
     */
    open func sortLayers(_ fromZ: CGFloat?=nil) {
        let startingZ: CGFloat = (fromZ != nil) ? fromZ! : zPosition
        allLayers().forEach {$0.zPosition = startingZ + (zDeltaForLayers * CGFloat($0.index))}
    }
    
    // MARK: - Tiles
    
    /**
     Return tiles at the given coordinate (all tile layers).
     
     - parameter coord: `CGPoint` coordinate.
     - returns: `[SKTile]` array of tiles.
     */
    open func tilesAt(coord: CGPoint) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            if let tile = layer.tileAt(coord: coord){
                result.append(tile)
            }
        }
        return result
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
     
     - parameter coord: `CGPoint` tile coordinate.
     - parameter name:  `String?` layer name.
     - returns: `SKTile?` tile, or nil.
     */
    open func tileAt(coord: CGPoint, inLayer name: String?) -> SKTile? {
        if let name = name {
            if let layer = getLayer(named: name) as? SKTileLayer {
                return layer.tileAt(coord: coord)
            }
        }
        return nil
    }
    
    open func tileAt(_ x: Int, _ y: Int, inLayer name: String?) -> SKTile? {
        return tileAt(coord: CGPoint(x: CGFloat(x), y: CGFloat(y)), inLayer: name)
    }
    
    /**
     Returns tiles with a property of the given type (all tile layers).
     
     - parameter type: `String` type.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTiles(ofType type: String) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTiles(ofType: type)
        }
        return result
    }
    
    /**
     Returns tiles matching the given gid (all tile layers).
     
     - parameter type: `Int` tile gid.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTiles(withID id: Int) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTiles(withID: id)
        }
        return result
    }
    
    /**
     Returns tiles with a property of the given type & value (all tile layers).
     
     - parameter named: `String` property name.
     - parameter value: `AnyObject` property value.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTilesWithProperty(_ named: String, _ value: AnyObject) -> [SKTile] {
        var result: [SKTile] = []
        for layer in tileLayers {
            result += layer.getTilesWithProperty(named, value as! String as AnyObject)
        }
        return result
    }
    
    /**
     Return tile data with a property of the given type (all tile layers).
     
     - parameter named: `String` property name.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTileData(withProperty named: String) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(withProperty: named) }
    }
    
    /**
     Return tile data with a property of the given type (all tile layers).
     
     - parameter named: `String` property name.
     - parameter value: `AnyObject` property value.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTileData(_ named: String, _ value: AnyObject) -> [SKTilesetData] {
        return tilesets.flatMap { $0.getTileData(named, value) }
    }
    
    /**
     Returns an array of all animated tile objects.
     
     - returns: `[SKTile]` array of tiles.
     */
    open func getAnimatedTiles() -> [SKTile] {
        return tileLayers.flatMap { $0.getAnimatedTiles() }
    }
    
    /**
     Return the top-most tile at the given coordinate.
     
     - parameter coord: `CGPoint` coordinate.
     - returns: `SKTile?` first tile in layers.
     */
    open func firstTileAt(coord: CGPoint) -> SKTile? {
        for layer in tileLayers.reversed() {
            if layer.visible == true {
                if let tile = layer.tileAt(coord: coord) {
                    return tile
                }
            }
        }
        return nil
    }
    
    // MARK: - Objects
    
    /**
     Return all of the current tile objects.
     
     - returns: `[SKTileObject]` array of objects.
     */
    open func getObjects() -> [SKTileObject] {
        return objectGroups.flatMap { $0.getObjects() }
    }
    
    /**
     Return objects matching a given type.
     
     - parameter type: `String` object type to query.
     - returns: `[SKTileObject]` array of objects.
     */
    open func getObjects(ofType type: String) -> [SKTileObject] {
        return objectGroups.flatMap { $0.getObjects(ofType: type) }
    }
    
    /**
     Return objects matching a given name.
     
     - parameter named: `String` object name to query.
     - returns: `[SKTileObject]` array of objects.
     */
    open func getObjects(_ named: String) -> [SKTileObject] {
        return objectGroups.flatMap { $0.getObjects(named: named) }
    }
    
    // MARK: - Data
    /**
     Returns data for a global tile id.
     
     - parameter gid: `Int` global tile id.
     - returns: `SKTilesetData` tile data, if it exists.
     */
    open func getTileData(_ gid: Int) -> SKTilesetData? {
        for tileset in tilesets {
            if let tileData = tileset.getTileData(gid) {
                return tileData
            }
        }
        return nil
    }
    
    // MARK: - Coordinates
    
    
    /**
     Returns a touch location in negative-y space.
     
     *Position is in converted space*
     
     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    #if os(iOS)
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
    
    
    /**
     Returns a positing in negative-y space.
     
     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    open func positionInMap(point: CGPoint) -> CGPoint {
        return convert(point, to: baseLayer).invertedY
    }
    
    // MARK: - Callbacks
    
    /**
     Called when parser has finished reading the map.
     
     - parameter timeStarted: `Date` render start time.
     */
    open func didFinishRendering(timeStarted: Date) {
        // set the z-depth of the baseLayer
        baseLayer.zPosition = lastZPosition + (zDeltaForLayers * 0.5)
        
        // time results
        let timeInterval = Date().timeIntervalSince(timeStarted)
        let timeStamp = String(format: "%.\(String(3))f", timeInterval)        
        print("\n -> Success! tile map \"\(name != nil ? name! : "null")\" rendered in: \(timeStamp)s\n")
        
        // transfer attributes
        if let scene = scene as? SKTiledScene {
            scene.physicsWorld.gravity = gravity
        }
        
        // delegate callbacks
        if self.delegate != nil { delegate!.didRenderMap(self) }
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


extension SKTilemap {
    
    // convenience properties
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
    
    public var sizeHalved: CGSize { return CGSize(width: size.width / 2, height: size.height / 2)}
    public var tileWidthHalf: CGFloat { return tileWidth / 2 }
    public var tileHeightHalf: CGFloat { return tileHeight / 2 }
    
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
     Returns true if the given x-coordinate represents a staggered column.
     
     - parameter x:  `Int` map x-coordinate.
     - returns: `Bool` column should be staggered.
     */
    internal func doStaggerX(_ x: Int) -> Bool {
        return staggerX && Bool((x & 1) ^ staggerEven.hashValue)
    }
    
    /**
     Returns true if the given y-coordinate represents a staggered row.
     
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
        let renderSizeDesc = "\(sizeInPoints.width.roundTo(1)) x \(sizeInPoints.height.roundTo(1))"
        let sizeDesc = "\(Int(size.width)) x \(Int(size.height))"
        let tileSizeDesc = "\(Int(tileSize.width)) x \(Int(tileSize.height))"
        
        return "Map: \(name ?? "(None)"), \(renderSizeDesc): (\(sizeDesc) @ \(tileSizeDesc)): \(tileCount) tiles"
    }
    
    override open var debugDescription: String { return description }
    
    /// Visualize the current grid & bounds.
    public var debugDraw: Bool {
        get {
            return baseLayer.debugDraw
        } set {
            guard newValue != baseLayer.debugDraw else { return }
            baseLayer.debugDraw = newValue
        }
    }
    
    /**
     Output a summary of the current scenes layer data.
     */
    public func debugLayers(reverse: Bool = false) {
        guard (layerCount > 0) else {
            print("# Tilemap \"\(name != nil ? name! : "null")\": 0 Layers")
            return
        }
        
        let largestName = layerNames().max() { (a, b) -> Bool in a.characters.count < b.characters.count }
        
        // format the header
        let tilemapHeaderString = "# Tilemap \"\(name != nil ? name! : "null")\": \(tileCount) Tiles: \(layerCount) Layers"
        let filled = String(repeating: "-", count: tilemapHeaderString.characters.count)
        print("\n\(tilemapHeaderString)\n\(filled)")
        
        // create an array of layers to output
        let layersToPrint = (reverse == true) ? allLayers().reversed() : allLayers()
        
        for layer in layersToPrint {
            let layerName = layer.name!
            let nameString = "\"\(layerName)\""
            
            // format the layer index
            let indexString = "\(layer.index): ".zfill(length: 3, pattern: " ", padLeft: false)
            
            // format the layer name
            let layerNameString = "\(layer.layerType.stringValue.capitalized.zfill(length: 7, pattern: " ", padLeft: false)) \(nameString.zfill(length: largestName!.characters.count + 3, pattern: " ", padLeft: false))"
            let positionString = "pos: \(layer.position.roundTo(1)), size: \(layer.sizeInPoints.roundTo(1))"
            let offsetString = "offset: \(layer.offset.roundTo(1)), anc: \(layer.anchorPoint.roundTo()), z: \(Int(layer.zPosition))"

            let layerOutput = "\(indexString) \(layerNameString) \(positionString),  \(offsetString)"
            print(layerOutput)
        }
        
        print("\n")
    }
}


/**
 Default implementations of callbacks.
 */
extension SKTilemapDelegate {
    public func didBeginParsing(_ tilemap: SKTilemap) {}
    public func didAddTileset(_ tileset: SKTileset) {}
    public func didAddLayer(_ layer: TiledLayerObject) {}
    public func didReadMap(_ tilemap: SKTilemap) {}
    public func didRenderMap(_ tilemap: SKTilemap) {}
}

