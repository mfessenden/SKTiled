//
//  SKTileLayer.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
#if os(iOS)
import UIKit
#endif


public enum SKTiledLayerType: Int {
    case invalid    = -1
    case tile
    case object
    case image
}


public enum ObjectGroupColors: String {
    case Pink     = "#c8a0a4"
    case Blue     = "#6fc0f3"
    case Green    = "#70d583"
    case Orange   = "#f3dc8d"
}


// MARK: - Base Layer Class

/// `TiledLayerObject` is the base class for all Tiled layer types.
public class TiledLayerObject: SKNode, TiledObject {
    
    public var layerType: SKTiledLayerType = .invalid
    public var tilemap: SKTilemap
    public var uuid: String = UUID().uuidString                   // unique object id
    public var index: Int = 0                                       // index of the layer in the tmx file
    
    // properties
    public var properties: [String: String] = [:]                   // generic layer properties
    
    // colors
    public var color: SKColor = SKColorWithRGB(200, g: 160, b: 164) // object group color
    public var gridColor: SKColor = SKColor.black            // grid visualization color
    public var frameColor: SKColor = SKColor.black           // bounding box color
    public var highlightColor: SKColor = SKColor.white       // layer highlight color
    
    // layer offset
    public var offset: CGPoint = CGPoint.zero                        // layer offset value
    
    // size & anchor point
    public var size: CGSize { return tilemap.size }
    public var tileSize: CGSize { return tilemap.tileSize }
    public var orientation: TilemapOrientation { return tilemap.orientation }
    public var anchorPoint: CGPoint { return tilemap.layerAlignment.anchorPoint }
    
    // convenience properties
    public var width: CGFloat { return tilemap.width }
    public var height: CGFloat { return tilemap.height }
    public var tileWidth: CGFloat { return tilemap.tileWidth }
    public var tileHeight: CGFloat { return tilemap.tileHeight }
    
    public var sizeHalved: CGSize { return tilemap.sizeHalved }
    public var tileWidthHalf: CGFloat { return tilemap.tileWidthHalf }
    public var tileHeightHalf: CGFloat { return tilemap.tileHeightHalf }
    public var sizeInPoints: CGSize { return tilemap.sizeInPoints }
    
    // debug visualizations
    fileprivate var frameShape: SKShapeNode = SKShapeNode()
    fileprivate var grid: SKSpriteNode
    
    public var origin: CGPoint {
        switch orientation {
        case .Orthogonal:
            return CGPoint.zero
        case .Isometric:
            return CGPoint(x: height * tileWidthHalf, y: tileHeightHalf)
        }
    }
    
    public var bounds: CGRect {
        return CGRect(x: -size.halfWidth, y: -size.halfHeight, width: size.width, height: size.height)
    }
    
    override public var frame: CGRect {
        return CGRect(x: 0, y: 0, width: sizeInPoints.width, height: -sizeInPoints.height)
    }
    
    // blending/visibility
    public var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    public var visible: Bool {
        get { return !self.isHidden }
        set { self.isHidden = !newValue }
    }
    
    public var showGrid: Bool {
        get {
            return grid.isHidden == false
        } set {
            grid.isHidden = !newValue
            grid.texture = generateGrid(self)
            grid.alpha = 0.2
        }
    }
    
    public var debugDraw: Bool {
        get {
            return frameShape.isHidden == false
        } set {
            frameShape.isHidden = !newValue
            drawObject()
        }
    }
    
    // MARK: - Init
    
    /**
     Initialize from the parser.
     
     - parameter layerName:  `String` layer name.
     - parameter tileMap:    `SKTilemap` parent tilemap node.
     - parameter attributes: `[String: String]` dictionary of layer attributes.
     
     - returns: `TiledLayerObject?` tiled layer, if initialization succeeds.
     */
    public init?(layerName: String, tileMap: SKTilemap, attributes: [String: String]) {
        
        self.tilemap = tileMap
        self.grid = SKSpriteNode(texture: nil, color: SKColor.clear, size: tilemap.sizeInPoints)
        super.init()
        self.name = layerName
        
        // layer offset
        var offsetx: CGFloat = 0
        var offsety: CGFloat = 0
        
        if let offsetX = attributes["offsetx"] {
            offsetx = CGFloat(Double(offsetX)!)
        }
        
        if let offsetY = attributes["offsety"] {
            offsety = CGFloat(Double(offsetY)!)
        }
        
        self.offset = CGPoint(x: offsetx, y: offsety)
        
        // set the visibility property
        if let visibility = attributes["visible"] {
            self.visible = Int(visibility)! != 0
        }
        
        // set layer opacity
        if let layerOpacity = attributes["opacity"] {
            self.opacity = CGFloat(Double(layerOpacity)!)
        }
        
        // set the anchorpoint to 0,0 to match the frame
        self.grid.anchorPoint = CGPoint.zero
        self.grid.isHidden = true
        self.grid.position.y -= tilemap.sizeInPoints.height
        self.frameShape.isHidden = true
        
        addChild(grid)
        addChild(frameShape)
    }

    /**
     Create a new layer within the parent tilemap node.
     
     - parameter layerName:  `String` layer name.
     - parameter tileMap:    `SKTilemap` parent tilemap node.
     
     - returns: `TiledLayerObject` tiled layer object.
     */
    public init(layerName: String, tileMap: SKTilemap){
        self.tilemap = tileMap
        self.grid = SKSpriteNode(texture: nil, color: SKColor.clear, size: tilemap.sizeInPoints)
        
        super.init()
        self.name = layerName
        
        // set the anchorpoint to 0,0 to match the frame
        self.grid.anchorPoint = CGPoint.zero
        self.grid.isHidden = true
        self.grid.position.y -= tilemap.sizeInPoints.height
        self.frameShape.isHidden = true
        
        addChild(grid)
        addChild(frameShape)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Coordinates
    /**
     Returns true if the coordinate is valid.
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` y-coordinate.
     
     - returns: `Bool` coodinate is valid.
     */
    public func isValid(_ x: Int, _ y: Int) -> Bool {
        return x >= 0 && x < Int(size.width) && y >= 0 && y < Int(size.height)
    }
    
    /**
     Returns true if the coordinate is valid.
     
     - parameter coord: `TiledCoord` tile coordinate.
     
     - returns: `Bool` coodinate is valid.
     */
    public func isValid(_ coord: TileCoord) -> Bool {
        return isValid(Int(coord.x), Int(coord.y))
    }
    
    /**
     Converts a point to a point in the layer.
     
     - parameter coord: `CGPoint` input point.
     
     - returns: `CGPoint` point with y-value inverted.
     */
    public func convertPoint(_ point: CGPoint) -> CGPoint {
        return point.invertedY
    }
    
    /**
     Returns a converted touch location.
     
     - parameter point: `CGPoint` scene point.
     
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    #if os(iOS)
    public func touchLocation(_ touch: UITouch) -> CGPoint {
        return convertPoint(touch.location(in: self))
    }
    #endif
    
    /**
     Returns a point for a given coordinate in the layer.
     
     - parameter x: `Int` y-coordinate.
     - parameter y: `Int` x-coordinate.
     
     - returns: `CGPoint` position in layer.
     */
    public func pointForCoordinate(_ coord: TileCoord, offsetX: CGFloat=0, offsetY: CGFloat=0) -> CGPoint {
        var screenPoint = tileToScreenCoords(coord)
        
        var tileOffsetX: CGFloat = offsetX
        var tileOffsetY: CGFloat = offsetY
        
        // we want to return a point at the center of the tile
        switch orientation {
        case .Orthogonal:
            tileOffsetX += tileWidthHalf
            tileOffsetY += tileHeightHalf
            
        case .Isometric:
            tileOffsetY += tileHeightHalf  // this flips the drawing
        }
        
        screenPoint.x += tileOffsetX
        screenPoint.y += tileOffsetY
        
        return screenPoint.invertedY
    }
    
    /**
     Returns a tile coordinate for a point in the layer.
     
     - parameter point:   `CGPoint` position in layer (in pixels).
     - parameter offsetX: `CGFloat` offset in X.
     - parameter offsetY: `CGFloat` offset in Y.
     
     - returns: `TileCoord` coordinate for the point.
     */
    public func coordinateForPoint(_ point: CGPoint, offsetX: CGFloat=0, offsetY: CGFloat=0) -> TileCoord {
        let x = point.x + offsetX
        var y = point.y + offsetY
        
        switch orientation {
        case .Orthogonal: break
        case .Isometric:
            y -= tileWidth
        }
        
        return screenToTileCoords(CGPoint(x: x, y: y))
    }
    
    /**
     Converts a tile coordinate from a point in map space.
     
     - parameter point: `CGPoint` point in map space.
     
     - returns: `TileCoord` tile coordinate.
     */
    public func pixelToTileCoords(_ point: CGPoint) -> TileCoord {
        switch orientation {
        case .Orthogonal:
            return TileCoord(point.x / tileWidth, point.y / tileHeight)
        case .Isometric:
            return TileCoord(point.x / tileHeight, point.y / tileHeight)
        }
    }
    
    /**
     Converts a tile coordinate to a coordinate in map space.
     
     - parameter coord: `TileCoord` tile coordinate.
     
     - returns: `CGPoint` point in map space.
     */
    public func tileToPixelCoords(_ coord: TileCoord) -> CGPoint {
        switch orientation {
        case .Orthogonal:
            return CGPoint(x: coord.x * tileWidth, y: coord.y * tileHeight)
            
        case .Isometric:
            return CGPoint(x: coord.x * tileHeight, y: coord.y * tileHeight)
        }
    }
    
    /**
     Converts a screen point to a tile coordinate.
     
     - parameter point: `CGPoint` point in screen space.
     
     - returns: `TileCoord` tile coordinate.
     */
    public func screenToTileCoords(_ point: CGPoint) -> TileCoord {
        switch orientation {
        case .Orthogonal:
            return TileCoord(point.x / tileWidth, point.y / tileHeight)
            
        case .Isometric:
            var x = point.x
            let y = point.y
            
            x -= height * tileWidthHalf
            let tileY = y / tileHeight
            let tileX = x / tileWidth
            return TileCoord(tileY + tileX, tileY - tileX)
        }
    }
    
    /**
     Converts a tile coordinate into a screen point.
     
     - parameter coord: `TileCoord` tile coordinate.
     
     - returns: `CGPoint` point in screen space.
     */
    public func tileToScreenCoords(_ coord: TileCoord) -> CGPoint {
        switch orientation {
        case .Orthogonal:
            return CGPoint(x: coord.x * tileWidth, y: coord.y * tileHeight)
            
        case .Isometric:
            let x = CGFloat(coord.x)
            let y = CGFloat(coord.y)
            let originX = height * tileWidthHalf
            return CGPoint(x: (x - y) * tileWidthHalf + originX,
                               y: (x + y) * tileHeightHalf)
        }
    }
    
    /**
     Converts a screen (isometric) coordinate to a coordinate in map space.
     
     - parameter point: `CGPoint` point in screen space.
     
     - returns: `CGPoint` point in map space.
     */
    public func screenToPixelCoords(_ point: CGPoint) -> CGPoint {
        switch orientation {
        case .Orthogonal:
            return point
            
        case .Isometric:
            var x = point.x
            let y = point.y
            x -= height * tileWidthHalf
            let tileY = y / tileHeight
            let tileX = x / tileWidth
            
            return CGPoint(x: (tileY + tileX) * tileHeight,
                               y: (tileY - tileX) * tileHeight)
        }
    }
    
    /**
     Converts a coordinate in map space to screen space.
     see: http://stackoverflow.com/questions/24747420/tiled-map-editor-size-of-isometric-tile-side
     - parameter point: `CGPoint` point in map space.
     
     - returns: `CGPoint` point in screen space.

     */
    public func pixelToScreenCoords(_ point: CGPoint) -> CGPoint {
        switch orientation {
        case .Orthogonal:
            return point
            
        case .Isometric:
            let originX = height * tileWidthHalf
            //let originY = tileHeightHalf
            let tileY = point.y / tileHeight
            let tileX = point.x / tileHeight
            return CGPoint(x: (tileX - tileY) * tileWidthHalf + originX,
                               y: (tileX + tileY) * tileHeightHalf)
        }
    }
    
    /**
     Returns a coordinate in the given direction.
     
     - parameter coord:     `TileCoord` tile coordinate.
     - parameter direction: `CardinalDirection` direction from input coordinate.
     
     - returns: `TileCoord?`
     */
    public func coordinateInDirection(from coord: TileCoord, inDirection direction: CardinalDirection) -> TileCoord? {
        // TODO: need to add this
        return nil
    }
        
    // MARK: - Adding & Removing Nodes
    /**
     Add a node at the given coordinates. By default, the zPositon 
     will be higher than all of the other nodes in the layer.
     
     - parameter node:      `SKNode` object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter zPosition: `CGFloat` z-position.
     */
    public func addNode(_ node: SKNode, _ x: Int=0, _ y: Int=0, zPosition: CGFloat? = nil) {
        addChild(node)
        node.position = pointForCoordinate(TileCoord(x, y))
        node.zPosition = zPosition != nil ? zPosition! : self.zPosition + tilemap.zDeltaForLayers
    }
    
    /**
     Visualize the layer's bounds.
     */
    fileprivate func drawObject() {
        let objectPath: CGPath!
        
        switch orientation {
        case .Orthogonal:
            objectPath = polygonPath(self.frame.points)
            
        case .Isometric:
            let topPoint = CGPoint(x: 0, y: 0)
            let rightPoint = CGPoint(x: (width - 1) * tileHeight + tileHeight, y: 0)
            let bottomPoint = CGPoint(x: (width - 1) * tileHeight + tileHeight, y: (height - 1) * tileHeight + tileHeight)
            let leftPoint = CGPoint(x: 0, y: (height - 1) * tileHeight + tileHeight)
            
            let points: [CGPoint] = [
                // point order is top, right, bottom, left
                pixelToScreenCoords(topPoint),
                pixelToScreenCoords(rightPoint),
                pixelToScreenCoords(bottomPoint),
                pixelToScreenCoords(leftPoint)
            ]
            
            let invertedPoints = points.map{$0.invertedY}
            objectPath = polygonPath(invertedPoints)

        }
        
        if let objectPath = objectPath {
            frameShape.path = objectPath
            frameShape.isAntialiased = true
            frameShape.lineWidth = 1.5
            frameShape.strokeColor = frameColor
        }
    }

    // MARK: - Future Stuff
    
    /**
     Prune tiles out of the camera bounds.
     
     - parameter outsideOf: `CGRect` camera bounds.
     */
    public func pruneTiles(_ outsideOf: CGRect) {
        /* override in subclass */
    }
    
    /**
     Flatten (render) the tile layer.
     */
    public func flattenLayer() {
        /* override in subclass */
    }
    
    override public var hashValue: Int {
        return self.uuid.hashValue
    }
}


// MARK: - Tiled Layer

public class SKTileLayer: TiledLayerObject {
    
    fileprivate typealias TilesArray = Array2D<SKTile>
    
    // container for the tile sprites
    fileprivate var tiles: TilesArray                   // array of tiles
    public var render: Bool = false                 // render tile layer as a single image
    
    // MARK: - Init
    override public init(layerName: String, tileMap: SKTilemap) {
        self.tiles = TilesArray(columns: Int(tileMap.size.width), rows: Int(tileMap.size.height))
        super.init(layerName: layerName, tileMap: tileMap)
        self.layerType = .tile
    }
    
    public init?(tileMap: SKTilemap, attributes: [String: String]) {
        // name, width and height are required
        guard let layerName = attributes["name"] else { return nil }
        self.tiles = TilesArray(columns: Int(tileMap.size.width), rows: Int(tileMap.size.height))
        super.init(layerName: layerName, tileMap: tileMap, attributes: attributes)
        self.layerType = .tile
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Tiles
    
    /**
     Returns a tile at the given coordinate, if one exists.
     
     - parameter x: `Int` y-coordinate.
     - parameter y: `Int` x-coordinate.
     
     - returns: `SKTile?` tile object, if it exists.
     */
    public func tileAt(_ x: Int, _ y: Int) -> SKTile? {
        if isValid(x, y) == false { return nil }
        return tiles[x,y]
    }
    
    /**
     Returns a tile at the given coordinate, if one exists.
     
     - parameter coord:   `TileCoord` tile coordinate.
     
     - returns: `SKTile?` tile object, if it exists.
     */
    public func tileAt(_ coord: TileCoord) -> SKTile? {
        if isValid(coord) == false { return nil }
        return tiles[Int(coord.x), Int(coord.y)]
    }
    
    /**
     Returns tiles with a property of the given type.
     
     - parameter type: `String` type.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func getTiles(ofType type: String) -> [SKTile] {
        var result: [SKTile] = []
        for tile in tiles {
            if let tile = tile {
                if let ttype = tile.tileData.properties["type"] , ttype == type {
                    result.append(tile)
                }
            }
        }
        return result
    }
    
    /**
     Returns tiles matching the given gid.
     
     - parameter type: `Int` tile gid.
     
     - returns: `[SKTile]` array of tiles.
    */
    public func getTiles(withID id: Int) -> [SKTile] {
        var result: [SKTile] = []
        for tile in tiles {
            if let tile = tile {
                if tile.tileData.id == id {
                    result.append(tile)
                }
            }
        }
        return result
    }
    
    /**
     Returns tiles with a property of the given type.
     
     - parameter type: `String` type.
     
     - returns: `[SKTile]` array of tiles.
     */
    public func getTilesWithProperty(_ named: String, _ value: AnyObject) -> [SKTile] {
        var result: [SKTile] = []
        for tile in tiles {
            if let tile = tile {
                if let pvalue = tile.tileData.properties[named] , pvalue == value as! String {
                    result.append(tile)
                }
                
            }
        }
        return result
    }
    
    // MARK: - Layer Data
    
    /**
     Add tile data array to the layer and render it. Rendering takes place on a background queue.
     
     - parameter data: `[Int]` tile data.
     
     - returns: `Bool` data was successfully added.
     */
    public func setLayerData(_ data: [UInt32]) -> Bool {
        if !(data.count==size.count) {
            print("[SKTileLayer]: Error: invalid data size: \(data.count), expected: \(size.count)")
            return false
        }
        
        //let renderQueue = dispatch_queue_create("renderLayer", DISPATCH_QUEUE_SERIAL)
        var errorCount: Int = 0
        
        // render the layer in the background
        //dispatch_async(renderQueue){
            
        for index in data.indices {
            let gid = data[index]
            
            // skip empty tiles
            if (gid == 0) { continue }
            
            let coord = TileCoord(index % Int(self.size.width), index / Int(self.size.width))
            let tile = self.buildTileAt(coord, id: gid)
            
            if (tile == nil) {
                errorCount += 1
            }
        }
        
        if (errorCount != 0){
            print("[SKTileLayer]: \(errorCount) \(errorCount > 1 ? "errors" : "error") loading data.")
        }
        //}
        return errorCount == 0
    }
    
    /**
     Build a tile at the given coordinate.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - parameter gid: `Int` tile id.
     
     - returns: `SKTile?` tile.
     */
    fileprivate func buildTileAt(_ coord: TileCoord, id: UInt32) -> SKTile? {
        
        // masks for tile flipping
        let flippedDiagonalFlag: UInt32   = 0x20000000
        let flippedVerticalFlag: UInt32	  = 0x40000000
        let flippedHorizontalFlag: UInt32 = 0x80000000
        
        let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
        let flippedMask = ~(flippedAll)
        
        let flipHoriz: Bool = (id & flippedHorizontalFlag) != 0
        let flipVert: Bool = (id & flippedVerticalFlag) != 0
        let flipDiag: Bool = (id & flippedDiagonalFlag) != 0
        
        // get the actual gid from the mask
        let gid = id & flippedMask
        
        if let tileData = tilemap.getTileData(Int(gid)) {
            
            tileData.flipHoriz = flipHoriz
            tileData.flipVert = flipVert
            tileData.flipDiag = flipDiag
            
            if let tile = SKTile(data: tileData) {
                
                tile.setTileOverlap(tilemap.tileOverlap)
                tile.highlightColor = highlightColor
                
                // set the layer property
                tile.layer = self
                self.tiles[Int(coord.x), Int(coord.y)] = tile
                
                // get the point in the layer (plus tileset offset)
                
                let tileAlignment = tileHeightHalf / tileData.tileset.tileSize.height
                let tilePosition = pointForCoordinate(coord, offsetX: tileData.tileset.tileOffset.x, offsetY: tileData.tileset.tileOffset.y)

                tile.position = tilePosition
                tile.anchorPoint.y = tileAlignment
                addChild(tile)
                
                // run animation for tiles with multiple frames
                tile.runAnimation()
                return tile
            } else {
                print("[SKTileLayer]: Error: invalid tileset data (id: \(id))")
            }
        }
        return nil
    }
    
    // MARK: - Overlap
    
    /**
     Set the tile overlap. Only accepts a value between 0 - 1.0
     
     - parameter overlap: `CGFloat` tile overlap value.
     */
    public func setTileOverlap(_ overlap: CGFloat) {
        for tile in tiles {
            if let tile = tile {
                tile.setTileOverlap(overlap)
            }
        }
    }
}


// object group draw order
public enum ObjectGroupDrawOrder: String {
    case TopDown   // default
    case Manual
}


// MARK: - Objects Group

public class SKObjectGroup: TiledLayerObject {
    
    public var drawOrder: ObjectGroupDrawOrder = ObjectGroupDrawOrder.TopDown
    fileprivate var objects: Set<SKTileObject> = []
    
    public var showObjects: Bool = false {
        didSet {
            objects.map({ $0.visible = showObjects})
        }
    }
    
    /// Returns the number of objects in this layer.
    public var count: Int { return objects.count }
    
    /// Controls antialiasing for each object
    public var antialiased: Bool = true {
        didSet {
            objects.forEach({$0.isAntialiased = antialiased})
        }
    }
    
    /// Governs object line width for each object
    public var lineWidth: CGFloat = 2.0 {
        didSet {
            objects.map({ $0.lineWidth = lineWidth })
        }
    }
    
    // MARK: - Init
    override public init(layerName: String, tileMap: SKTilemap) {
        super.init(layerName: layerName, tileMap: tileMap)
        self.layerType = .object
    }
    
    public init?(tileMap: SKTilemap, attributes: [String: String]) {
        guard let layerName = attributes["name"] else { return nil }
        super.init(layerName: layerName, tileMap: tileMap, attributes: attributes)
        
        // set objects color
        if let layerColor = attributes["color"] {
            self.color = SKColor.fromHexCode(layerColor)
        }
        
        self.layerType = .object
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Objects
    
    /**
     Add an `SKTileObject` object to the objects set.
     
     - parameter object:    `SKTileObject` object.
     - parameter withColor: `SKColor?` optional override color (otherwise defaults to parent layer color).
     
     - returns: `SKTileObject?` added object.
     */
    public func addObject(_ object: SKTileObject, withColor: SKColor? = nil) -> SKTileObject? {
        if objects.contains(where: { $0.hashValue == object.hashValue }) {
            return nil
        }
        
        // if the override color is nil, use the layer color
        var objectColor: SKColor = (withColor == nil) ? self.color : withColor!
        
        // if the object has a color property override, use that instead
        if object.hasKey("color") {
            if let hexColor = object.stringForKey("color") {
                objectColor = SKColor.fromHexCode(hexColor)
            }
        }
        
        // position the object
        let pixelPosition = object.position
        let screenPosition = pixelToScreenCoords(pixelPosition)
        object.position = screenPosition.invertedY
        
        
        object.setColor(objectColor)
        object.isAntialiased = antialiased
        object.lineWidth = lineWidth
        objects.insert(object)
        object.layer = self
        addChild(object)
        drawObject()
        // hide the object if the tilemap is set to
        object.visible = tilemap.showObjects
        return object
    }
    
    /**
     Render all of the objects in the group.
     */
    public func drawObjects() {
        objects.forEach({$0.drawObject()})
    }
    
    /**
     Set the color for all objects.
     
     - parameter color: `SKColor` object color.
     - parameter force: `Bool` force color on objects that have an override.
     */
    public func setColor(_ color: SKColor, force: Bool=true) {
        self.color = color
        
        for object in objects {
            if !object.hasKey("color") || force == true{
                object.setColor(color)
            }
        }
    }
    
    /**
     Returns an array of object names.
     
     - returns: `[String]` object names in the layer.
     */
    public func objectNames() -> [String] {
        // flatmap will ignore nil name values.
        return objects.flatMap({$0.name})
    }
    
    /**
     Returns an object with the given id.
     
     - parameter id: `Int` Object id
     
     - returns: `SKTileObject?`
     */
    public func getObject(id: Int) -> SKTileObject? {
        if let index = objects.index( where: { $0.id == id } ) {
            return objects[index]
        }
        return nil
    }
    
    /**
     Return objects of a given type.
     
     - parameter type: `String` object type.
     
     - returns: `[SKTileObject]` array of matching objects.
     */
    public func getObjects(ofType type: String) -> [SKTileObject] {
        return objects.filter( {$0.type == type})
    }
    
    /**
     Returns an object with the given name.
     
     - parameter name: `String` Object name.
     
     - returns: `SKTileObject?`
     */
    public func getObject(named name: String) -> SKTileObject? {
        if let index = objects.index( where: { $0.name == name } ) {
            return objects[index]
        }
        return nil
    }
}


// MARK: - Image Layer

public class SKImageLayer: TiledLayerObject {
    
    public var image: String!                       // image name for layer
    fileprivate var sprite: SKSpriteNode?               // sprite (private)
    
    public var wrapX: Bool = false                  // wrap horizontally
    public var wrapY: Bool = false                  // wrap vertically
    
    // MARK: - Init
    override public init(layerName: String, tileMap: SKTilemap) {
        super.init(layerName: layerName, tileMap: tileMap)
        self.layerType = .image
    }
    
    public init?(tileMap: SKTilemap, attributes: [String: String]) {
        guard let layerName = attributes["name"] else { return nil }
        super.init(layerName: layerName, tileMap: tileMap, attributes: attributes)
        self.layerType = .image
    }
    
    /**
     Set the layer image as a sprite.
     
     - parameter named: `String` image name.
     */
    public func setLayerImage(_ named: String) {
        self.image = named
        
        let texture = SKTexture(imageNamed: named)
        let textureSize = texture.size()
        texture.filteringMode = .nearest
        
        self.sprite = SKSpriteNode(texture: texture)
        addChild(self.sprite!)
        
        self.sprite!.position.x += textureSize.width / 2
        // if we're going to flip coordinates, this should be +=
        self.sprite!.position.y -= textureSize.height / 2.0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/**
 *  Two-dimensional array structure.
 */
public struct Array2D<T> {
    public let columns: Int
    public let rows: Int
    public var array: [T?]
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array(repeating: nil, count: rows*columns)
    }
    
    public subscript(column: Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        }
        set {
            array[row*columns + column] = newValue
        }
    }
    
    public var count: Int { return self.array.count }
    public var isEmpty: Bool { return array.isEmpty }
    
    public func contains<T : Equatable>(_ obj: T) -> Bool {
        let filtered = self.array.filter {$0 as? T == obj}
        return filtered.count > 0
    }
}



// MARK: - Extensions

extension TiledLayerObject {
    
    public func pointForCoordinate(_ x: Int, _ y: Int, offsetX: CGFloat=0, offsetY: CGFloat=0) -> CGPoint {
        return self.pointForCoordinate(TileCoord(x, y), offsetX: offsetX, offsetY: offsetY)
    }
    
    /**
     Returns the center point of a layer.
     */
    public var center: CGPoint {
        return CGPoint(x: (size.width / 2) - (size.width * anchorPoint.x), y: (size.height / 2) - (size.height * anchorPoint.y))
    }
    
    /**
     Calculate the distance from the layer's origin
     */
    public func distanceFromOrigin(_ pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVector(dx: dx, dy: dy)
    }
    
    override public var description: String { return "\(layerType.stringValue.capitalized) Layer: \"\(name!)\"" }
    override public var debugDescription: String { return description }
}


public extension SKTiledLayerType {
    
    /// Returns a string representation of the layer type.
    public var stringValue: String {
        return "\(self)".lowercased()
    }
}


public extension SKTileLayer {
    
    /// Returns a count of valid tiles.
    public var tileCount: Int {
        return self.validTiles().count
    }
    
    /**
     Returns only tiles that are valid (not empty).
     
     - returns: `[SKTile]` array of tiles.
     */
    public func validTiles() -> [SKTile] {
        return tiles.flatMap({$0})
    }
}


public extension String {
    /**
     Returns an array of hexadecimal components.
     
     - returns: `[String]?` hexadecimal components.
     */
    public func hexComponents() -> [String?] {
        let code = self
        let offset = code.hasPrefix("#") ? 1 : 0
        let startIndex = code.index(code.startIndex, offsetBy: offset)
        let firstIndex = code.index(startIndex, offsetBy: 2)
        let secondIndex = code.index(firstIndex, offsetBy: 2)
        let thirdIndex = code.index(secondIndex, offsetBy: 2)
        return [code[startIndex..<firstIndex], code[firstIndex..<secondIndex], code[secondIndex..<thirdIndex]]
    }
}


public extension SKColor {
    
    /**
     Returns an SKColor from a hexidecimal string.
     
     - parameter code:  `String` hexidecimal code.
     - parameter alpha: `Double` alpha value.
     
     - returns: `SKColor`
     */
    public class func fromHexCode(_ code: String, alpha: Double=1.0) -> SKColor {
        let rgbValues = code.hexComponents().map {
            (component: String?) -> CGFloat in
            if let hex = component {
                var rgb: CUnsignedInt = 0
                if Scanner(string: hex).scanHexInt32(&rgb) {
                    return CGFloat(rgb) / 255.0
                }
            }
            return 0.0
        }
        return SKColor(red: rgbValues[0], green: rgbValues[1], blue: rgbValues[2], alpha: 1.0)
    }
}


extension Array2D: Sequence {
    
    public func makeIterator() -> AnyIterator<T?> {
        var arrayIndex = 0
        return AnyIterator {
            if arrayIndex < self.count {
                let element = self.array[arrayIndex]
                arrayIndex+=1
                return element
            } else {
                arrayIndex = 0
                return nil
            }
        }
    }
}


/**
 Initialize a color with RGB Integer values (0-255).
 
 - parameter r: `Int` red component.
 - parameter g: `Int` green component.
 - parameter b: `Int` blue component.
 
 - returns: `SKColor` color with given values.
 */
public func SKColorWithRGB(_ r: Int, g: Int, b: Int) -> SKColor {
    return SKColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
}


/**
 Initialize a color with RGBA Integer values (0-255).
 
 - parameter r: `Int` red component.
 - parameter g: `Int` green component.
 - parameter b: `Int` blue component.
 - parameter a: `Int` alpha component.
 
 - returns: `SKColor` color with given values.
 */
public func SKColorWithRGBA(_ r: Int, g: Int, b: Int, a: Int) -> SKColor {
    return SKColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a)/255.0)
}
