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
#else
import Cocoa
#endif


/**
 Describes the layer type.
 
 - invalid: Layer is invalid.
 - tile:    Tile-based layers.
 - object:  Object group.
 - image:   Image layer.
 */
internal enum SKTiledLayerType: Int {
    case invalid    = -1
    case tile
    case object
    case image
}


internal enum SKObjectGroupColors: String {
    case pink     = "#c8a0a4"
    case blue     = "#6fc0f3"
    case green    = "#70d583"
    case orange   = "#f3dc8d"
}


/**
 The `TiledLayerObject` is the base class for all `SKTiled` layer types.  This class 
 doesn't define any object or child types, but manages several important aspects of your scene:
    
 - validating coordinates
 - positioning and alignment
 - coordinate transformations
 
 */
open class TiledLayerObject: SKNode, SKTiledObject {
    
    internal var layerType: SKTiledLayerType = .invalid
    open var tilemap: SKTilemap
    /// Unique object id (internal use only).
    open var uuid: String = UUID().uuidString
    
    /// Layer index. Matches the index of the layer in the source TMX file.
    open var index: Int = 0
    
    /// Custom layer properties.
    open var properties: [String: String] = [:]
    
    /// Layer color.
    open var color: SKColor = SKColor.gray
    /// Grid visualization color.
    open var gridColor: SKColor = SKColor.black
    /// Bounding box color.
    open var frameColor: SKColor = SKColor.black
    /// Layer highlight color
    open var highlightColor: SKColor = SKColor.white    
    /// Layer offset value.
    open var offset: CGPoint = CGPoint.zero
    
    /// Layer size (in tiles).
    open var size: CGSize { return tilemap.size }
    /// Layer tile size (in pixels).
    open var tileSize: CGSize { return tilemap.tileSize }
    /// Tile map orientation.
    internal var orientation: TilemapOrientation { return tilemap.orientation }
    /// Layer anchor point, used to position layers.
    open var anchorPoint: CGPoint { return tilemap.layerAlignment.anchorPoint }
    
    // convenience properties
    open var width: CGFloat { return tilemap.width }
    open var height: CGFloat { return tilemap.height }
    open var tileWidth: CGFloat { return tilemap.tileWidth }
    open var tileHeight: CGFloat { return tilemap.tileHeight }
    
    open var sizeHalved: CGSize { return tilemap.sizeHalved }
    open var tileWidthHalf: CGFloat { return tilemap.tileWidthHalf }
    open var tileHeightHalf: CGFloat { return tilemap.tileHeightHalf }
    open var sizeInPoints: CGSize { return tilemap.sizeInPoints }
    
    // debug visualizations
    open var gridOpacity: CGFloat = 0.25
    fileprivate var frameShape: SKShapeNode = SKShapeNode()
    fileprivate var grid: TiledLayerGrid!
    
    internal var rendered: Bool = false
    open var antialiased: Bool = false
    
    /// Returns the position of layer origin point (used to place tiles).
    open var origin: CGPoint {
        switch orientation {
        case .orthogonal:
            return CGPoint.zero
        case .isometric:
            return CGPoint(x: height * tileWidthHalf, y: tileHeightHalf)
        case .hexagonal, .staggered:
            return CGPoint.zero
        }
    }
    
    /// Returns the frame rectangle of the layer (used to draw bounds).
    override open var frame: CGRect {
        return CGRect(x: 0, y: 0, width: sizeInPoints.width, height: -sizeInPoints.height)
    }
    
    /// Layer transparency.
    open var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    /// Layer visibility.
    open var visible: Bool {
        get { return !self.isHidden }
        set { self.isHidden = !newValue }
    }
    
    /// Show the layer's grid.
    open var showGrid: Bool {
        get { return grid.showGrid }
        set { grid.showGrid = newValue }
    }
    
    /// Visualize the layer's bounds & tile grid.
    open var debugDraw: Bool {
        get {
            return frameShape.isHidden == false
        } set {
            frameShape.isHidden = !newValue
            drawBounds()
        }
    }
    
    // MARK: - Init
    
    /**
     Initialize via the parser.
     
     *This intializer is meant to be called by the `SKTilemapParser`, you should not use it directly.*
     
     - parameter layerName:  `String` layer name.
     - parameter tilemap:    `SKTilemap` parent tilemap node.
     - parameter attributes: `[String: String]` dictionary of layer attributes.
     - returns: `TiledLayerObject?` tiled layer, if initialization succeeds.
     */
    public init?(layerName: String, tilemap: SKTilemap, attributes: [String: String]) {
        
        self.tilemap = tilemap
        super.init()
        self.grid = TiledLayerGrid(tileLayer: self)
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
            self.visible = (visibility == "1") ? true : false
        }
        
        // set layer opacity
        if let layerOpacity = attributes["opacity"] {
            self.opacity = CGFloat(Double(layerOpacity)!)
        }
        
        self.frameShape.isHidden = true
        addChild(grid)
        addChild(frameShape)
    }

    /**
     Create a new layer within the parent tilemap node.

     - parameter layerName:  `String` layer name.
     - parameter tilemap:    `SKTilemap` parent tilemap node.
     - returns: `TiledLayerObject` tiled layer object.
     */
    public init(layerName: String, tilemap: SKTilemap){
        self.tilemap = tilemap
        super.init()
        self.grid = TiledLayerGrid(tileLayer: self)
        self.name = layerName
        
        self.frameShape.isHidden = true
        addChild(grid)
        addChild(frameShape)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Color
    /**
     Set the layer color with an `SKColor`.
     
     - parameter color: `SKColor` object color.
     */
    open func setColor(color: SKColor) {
        self.color = color
    }
    
    /**
     Set the layer color with a hex string.
     
     - parameter hexString: `String` color hex string.
     */
    open func setColor(hexString: String) {
        self.color = SKColor(hexString: hexString)
    }
    
    // MARK: - Coordinates
    /**
     Returns true if the coordinate is valid.
     
     - parameter x: `Int` x-coordinate.
     - parameter y: `Int` y-coordinate.
     - returns: `Bool` coodinate is valid.
     */
    open func isValid(_ x: Int, _ y: Int) -> Bool {
        return x >= 0 && x < Int(size.width) && y >= 0 && y < Int(size.height)
    }
    
    /**
     Returns true if the coordinate is valid.
     
     - parameter coord: `CGPoint` tile coordinate.
     - returns: `Bool` coodinate is valid.
     */
    open func isValid(_ coord: CGPoint) -> Bool {
        return isValid(Int(coord.x), Int(coord.y))
    }
        
    /**
     Converts a point to a point in the layer.
     
     - parameter coord: `CGPoint` input point.
     - returns: `CGPoint` point with y-value inverted.
     */
    open func convertPoint(_ point: CGPoint) -> CGPoint {
        return point.invertedY
    }
    
    /**
     Returns a converted touch location.
     
     - parameter point: `CGPoint` scene point.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    #if os(iOS)
    open func touchLocation(_ touch: UITouch) -> CGPoint {
        return convertPoint(touch.location(in: self))
    }
    #endif
    
    #if os(OSX)
    public func mouseLocation(event: NSEvent) -> CGPoint {
        return convertPoint(event.location(in: self))
    }
    #endif
    
    /**
     Returns a point for a given coordinate in the layer.
     
     - parameter coord: `CGPoint` tile coordinate.
     - returns: `CGPoint` point in layer.
     */
    open func pointForCoordinate(coord: CGPoint, offsetX: CGFloat=0, offsetY: CGFloat=0) -> CGPoint {
        var screenPoint = tileToScreenCoords(coord)
        
        var tileOffsetX: CGFloat = offsetX
        var tileOffsetY: CGFloat = offsetY
        
        // return a point at the center of the tile
        switch orientation {
        case .orthogonal:
            tileOffsetX += tileWidthHalf
            tileOffsetY += tileHeightHalf
        
        case .isometric:
            tileOffsetY += tileHeightHalf
            
        case .hexagonal, .staggered:
            tileOffsetX += tileWidthHalf
            tileOffsetY += tileHeightHalf
        }
        
        screenPoint.x += tileOffsetX
        screenPoint.y += tileOffsetY
        
        return screenPoint.invertedY
    }
    
    /**
     Returns a tile coordinate for a given point in the layer.
     
     - parameter point: `CGPoint` point in layer.
     - returns: `CGPoint` tile coordinate.
     */
    open func coordinateForPoint(_ point: CGPoint) -> CGPoint {
        let coordinate = screenToTileCoords(point)
        return floor(point: coordinate).invertedY
    }
        
    /**
     Converts a tile coordinate from a point in map space.
            
     - parameter point: `CGPoint` point in map space.
     - returns: `CGPoint` tile coordinate.
     */
    open func pixelToTileCoords(_ point: CGPoint) -> CGPoint {
        switch orientation {
        case .orthogonal:
            return CGPoint(x: point.x / tileWidth, y: point.y / tileHeight)
        case .isometric:
            return CGPoint(x: point.x / tileHeight, y: point.y / tileHeight)
        case .hexagonal:
            return screenToTileCoords(point)
        case .staggered:
            return screenToTileCoords(point)
        }
    }
        
    /**
     Converts a tile coordinate to a coordinate in map space.
     
     - parameter coord: `CGPoint` tile coordinate.
     - returns: `CGPoint` point in map space.
     */
    open func tileToPixelCoords(_ coord: CGPoint) -> CGPoint {
        switch orientation {
        case .orthogonal:
            return CGPoint(x: coord.x * tileWidth, y: coord.y * tileHeight)
        case .isometric:
            return CGPoint(x: coord.x * tileHeight, y: coord.y * tileHeight)
        case .hexagonal:
            return tileToScreenCoords(coord)
        case .staggered:
            return tileToScreenCoords(coord)
        }
    }
        
    /**
     Converts a screen point to a tile coordinate. Note that this function
     expects scene points to be inverted in y before being passed as input.
     
     - parameter point: `CGPoint` point in screen space.
     - returns: `CGPoint` tile coordinate.
     */
    open func screenToTileCoords(_ point: CGPoint) -> CGPoint {
        
        //var pixelX = floor(point.x)
        //var pixelY = floor(point.y)
        var pixelX = point.x
        var pixelY = point.y
        
        switch orientation {
            
        case .orthogonal:
            return CGPoint(x: pixelX / tileWidth, y: pixelY / tileHeight)
            
        case .isometric:
            pixelX -= height * tileWidthHalf
            let tileY = pixelY / tileHeight
            let tileX = pixelX / tileWidth
            return CGPoint(x: tileY + tileX, y: tileY - tileX)
            
        case .hexagonal:
            
            // calculate r, h, & s
            var r: CGFloat = 0
            var h: CGFloat = 0
            var s: CGFloat = 0
            
            // variables for grid divisions
            var sectionX: CGFloat = 0
            var sectionY: CGFloat = 0
            
            //flat
            if (tilemap.staggerX == true) {
                s = tilemap.sideLengthX
                r = (tileWidth - tilemap.sideLengthX) / 2
                h = tileHeight / 2
                
                pixelX -= r
                sectionX = pixelX / (r + s)
                sectionY = pixelY / (h * 2)
                
                // y-offset
                if tilemap.doStaggerX(Int(sectionX)){
                    sectionY -= 0.5
                }
                
            // pointy
            } else {
                s = tilemap.sideLengthY
                r = tileWidth / 2
                h = (tileHeight - tilemap.sideLengthY) / 2
                
                pixelY -= h
                sectionX = pixelX / (r * 2)
                sectionY = pixelY / (h + s)
                
                // x-offset
                if tilemap.doStaggerY(Int(sectionY)){
                    sectionX -= 0.5
                }
            }
            
            return floor(point: CGPoint(x: sectionX, y: sectionY))
            
            
        case .staggered:
            
            if tilemap.staggerX {
                pixelX -= tilemap.staggerEven ? tilemap.sideOffsetX : 0
            } else {
                pixelY -= tilemap.staggerEven ? tilemap.sideOffsetY : 0
            }
            
            // get a point in the reference grid
            var referencePoint = CGPoint(x: floor(pixelX / tileWidth), y: floor(pixelY / tileHeight))
            
            // relative x & y position to grid aligned tile
            var relativePoint = CGPoint(x: pixelX - referencePoint.x * tileWidth, y: pixelY - referencePoint.y * tileHeight)
            
            // make adjustments to reference point
            if tilemap.staggerX {
                relativePoint.x *= 2
                if tilemap.staggerEven {
                    referencePoint.x += 1
                }
            } else {
                referencePoint.y *= 2
                if tilemap.staggerEven {
                    referencePoint.y += 1
                }
            }
            
            let yPosition: CGFloat = relativePoint.x * (tileHeight / tileWidth)
            //print("# y-pos: \(yPosition)")
            /*
            // check if the screen position is in the corners
            if (tilemap.sideOffsetY - yPosition > relativePoint.y) {
                return tilemap.topLeft(referencePoint.x, referencePoint.y)
            }
            
            if (tilemap.sideOffsetY + yPosition > relativePoint.y) {
                return tilemap.topRight(referencePoint.x, referencePoint.y)
            }
            
            if (tilemap.sideOffsetY + yPosition < relativePoint.y) {
                return tilemap.bottomLeft(referencePoint.x, referencePoint.y)
            }
            
            if (tilemap.sideOffsetY * 3 - yPosition < relativePoint.y) {
                return tilemap.bottomRight(referencePoint.x, referencePoint.y)
            }*/

            return referencePoint
        }
    }


    /**
     Converts a tile coordinate into a screen point.
     
     - parameter coord: `CGPoint` tile coordinate.     
     - returns: `CGPoint` point in screen space.
     */
    public func tileToScreenCoords(_ coord: CGPoint) -> CGPoint {
        switch orientation {
        case .orthogonal:
            return CGPoint(x: coord.x * tileWidth, y: coord.y * tileHeight)
            
        case .isometric:
            let x = coord.x
            let y = coord.y
            let originX = height * tileWidthHalf
            return CGPoint(x: (x - y) * tileWidthHalf + originX,
                               y: (x + y) * tileHeightHalf)
            
        case .hexagonal, .staggered:
            
            let tileX = Int(coord.x)
            let tileY = Int(coord.y)
            
            var pixelX: Int = 0
            var pixelY: Int = 0
            
            // flat
            if (tilemap.staggerX) {
                pixelY = tileY * Int(tileHeight + tilemap.sideLengthY)
                
                if tilemap.doStaggerX(tileX) {
                    pixelY += Int(tilemap.rowHeight)
                }
                
                pixelX = tileX * Int(tilemap.columnWidth)
            // pointy
            } else {
                pixelX = tileX * Int(tileWidth + tilemap.sideLengthX)
                
                if tilemap.doStaggerY(tileY) {
                    // hex error here?
                    pixelX += Int(tilemap.columnWidth)
                }
                
                pixelY = tileY * Int(tilemap.rowHeight)
            }
    
            return CGPoint(x: pixelX, y: pixelY)
        }
    }
    
    /**
     Converts a screen (isometric) coordinate to a coordinate in map space.
     
     - parameter point: `CGPoint` point in screen space.
     - returns: `CGPoint` point in map space.
     */
    public func screenToPixelCoords(_ point: CGPoint) -> CGPoint {
        switch orientation {
        case .isometric:
            var x = point.x
            let y = point.y
            x -= height * tileWidthHalf
            let tileY = y / tileHeight
            let tileX = x / tileWidth
            
            return CGPoint(x: (tileY + tileX) * tileHeight,
                               y: (tileY - tileX) * tileHeight)
        default:
            return point
        }
    }
    
    /**
     Converts a coordinate in map space to screen space. See:
     http://stackoverflow.com/questions/24747420/tiled-map-editor-size-of-isometric-tile-side
     
     - parameter point: `CGPoint` point in map space.
     - returns: `CGPoint` point in screen space.
     */
    public func pixelToScreenCoords(_ point: CGPoint) -> CGPoint {
        switch orientation {
            
        case .isometric:
            let originX = height * tileWidthHalf
            //let originY = tileHeightHalf
            let tileY = point.y / tileHeight
            let tileX = point.x / tileHeight
            return CGPoint(x: (tileX - tileY) * tileWidthHalf + originX,
                               y: (tileX + tileY) * tileHeightHalf)
        default:
            return point
        }
    }
    
    /**
     Returns a coordinate in the given direction.
    
     - parameter coord:     `CGPoint` tile coordinate.
     - parameter direction: `CardinalDirection` direction from input coordinate.
     - returns: `CGPoint?`
     */
    public func coordinateInDirection(from coord: CGPoint, inDirection direction: CardinalDirection) -> CGPoint? {
        // TODO: need to add this
        return nil
    }
    
    // MARK: - Adding & Removing Nodes
    /**
     Add a child node at the given x/y coordinates. By default, the zPositon
     will be higher than all of the other nodes in the layer.
     
     - parameter node:      `SKNode` object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter offset:    `CGPoint` offset amount.
     - parameter zpos: `CGFloat?` optional z-position.
     */
    public func addChild(_ node: SKNode, _ x: Int=0, _ y: Int=0, offset: CGPoint = CGPoint.zero, zpos: CGFloat? = nil) {
        let coord = CGPoint(x, y)
        addChild(node, coord: coord, offset: offset, zpos: zpos)
    }
    
    /**
     Add a node at the given coordinates. By default, the zPositon
     will be higher than all of the other nodes in the layer.
     
     - parameter node:      `SKNode` object.
     - parameter coord:     `CGPoint` tile coordinate.
     - parameter offset:    `CGPoint` offset amount.
     - parameter zpos: `CGFloat?` optional z-position.
     */
    public func addChild(_ node: SKNode, coord: CGPoint, offset: CGPoint = CGPoint.zero, zpos: CGFloat? = nil) {
        addChild(node)
        node.position = pointForCoordinate(coord: coord, offsetX: offset.y, offsetY: offset.y)
        node.position.x += offset.x
        node.position.y += offset.y
        node.zPosition = zpos != nil ? zpos! : zPosition + tilemap.zDeltaForLayers
    }
    
    /**
     Visualize the layer's bounds.
     */
    fileprivate func drawBounds() {
        let objectPath: CGPath!
        
        switch orientation {
        case .orthogonal:
            objectPath = polygonPath(self.frame.points)
            
        case .isometric:
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
            
        case .hexagonal, .staggered:            
            objectPath = polygonPath(self.frame.points)
        }
        
        if let objectPath = objectPath {
            frameShape.path = objectPath
            frameShape.isAntialiased = false
            frameShape.lineWidth = 1
            
            // don't draw bounds of hexagonal maps
            frameShape.strokeColor = frameColor
            if (orientation == .hexagonal){
                frameShape.strokeColor = SKColor.clear
            }
            
            frameShape.fillColor = SKColor.clear
        }
    }
    
    /**
     Prune tiles out of the camera bounds.
     
     - parameter outsideOf: `CGRect` camera bounds.
     */
    fileprivate func pruneTiles(_ outsideOf: CGRect) {
        /* override in subclass */
    }
    
    /**
     Flatten (render) the tile layer.
     */
    fileprivate func flattenLayer() {
        /* override in subclass */
    }
    
    override open var hashValue: Int {
        return self.uuid.hashValue
    }
}

 

/**
 The `SKTileLayer` class  manages an array of tiles (sprites) that it renders as a single image.
 
 This class manages setting and querying tile data.
 
 Accessing a tile:
 
 ```swift
 let tile = tileLayer.tileAt(2, 6)!
 ```
 
 Getting tiles of a certain type:
 
 ```swift
 let floorTiles = tileLayer.getTiles(ofType: "Floor")
 ```
*/
open class SKTileLayer: TiledLayerObject {

    fileprivate typealias TilesArray = Array2D<SKTile>

    // container for the tile sprites
    fileprivate var tiles: TilesArray                   // array of tiles
    open var render: Bool = false                 // render tile layer as a single image
    
    // MARK: - Init
    /**
     Initialize with layer name and parent `SKTilemap`.
     
     - parameter layerName:    `String` layer name.
     - parameter tilemap:      `SKTilemap` parent map.
     */
    override public init(layerName: String, tilemap: SKTilemap) {
        self.tiles = TilesArray(columns: Int(tilemap.size.width), rows: Int(tilemap.size.height))
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .tile
    }
    
    /**
     Initialize with parent `SKTilemap` and layer attributes.
     
     **Do not use this intializer directly**
    
     - parameter tilemap:      `SKTilemap` parent map.
     - parameter attributes:   `[String: String]` layer attributes.
     */
    public init?(tilemap: SKTilemap, attributes: [String: String]) {
        // name, width and height are required
        guard let layerName = attributes["name"] else { return nil }
        self.tiles = TilesArray(columns: Int(tilemap.size.width), rows: Int(tilemap.size.height))
        super.init(layerName: layerName, tilemap: tilemap, attributes: attributes)
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
    open func tileAt(_ x: Int, _ y: Int) -> SKTile? {
        if isValid(x, y) == false { return nil }
        return tiles[x,y]
    }
    
    /**
     Returns a tile at the given coordinate, if one exists.
     
     - parameter coord:   `CGPoint` tile coordinate.
     - returns: `SKTile?` tile object, if it exists.
     */
    open func tileAt(_ coord: CGPoint) -> SKTile? {
        if isValid(coord) == false { return nil }
        return tiles[Int(coord.x), Int(coord.y)]
    }
    
    /**
     Returns all current tiles.
     
     - returns: `[SKTile]` array of tiles.
     */
    open func getTiles() -> [SKTile] {
        return tiles.flatMap { $0 }
    }

    /**
     Returns tiles with a property of the given type.
     
     - parameter type: `String` type.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTiles(ofType type: String) -> [SKTile] {
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
    open func getTiles(withID id: Int) -> [SKTile] {
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
    open func getTilesWithProperty(_ named: String, _ value: AnyObject) -> [SKTile] {
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

    /**
     Returns all tiles with animation.
     
     - returns: `[SKTile]` array of animated tiles.
     */
    open func getAnimatedTiles() -> [SKTile] {
        return validTiles().filter({ $0.tileData.isAnimated == true })
    }
    
    /**
     Return tile data from a global id.
     
     - parameter withID: `Int` global tile id.
     - returns: `SKTilesetData?` tile data (for valid id).
     */
    open func getTileData(withID gid: Int) -> SKTilesetData? {
        return tilemap.getTileData(gid)
    }
    
    /**
     Returns tiles with a property of the given type.
                
     - parameter type: `String` type.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTileData(withProperty named: String) -> [SKTilesetData] {
        var result: [SKTilesetData] = []
        for tile in tiles {
            if let tile = tile {
                if tile.tileData.hasKey(named) && !result.contains(tile.tileData) {
                    result.append(tile.tileData)
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
    open func setLayerData(_ data: [UInt32]) -> Bool {
        if !(data.count==size.count) {
            print("[SKTileLayer]: Error: invalid data size: \(data.count), expected: \(size.count)")
            return false
        }
        
        var errorCount: Int = 0
        for index in data.indices {
            let gid = data[index]
            
            // skip empty tiles
            if (gid == 0) { continue }
            
            let coord = CGPoint(index % Int(self.size.width), index / Int(self.size.width))
            let tile = self.buildTileAt(coord, id: gid)
            
            if (tile == nil) {
                errorCount += 1
            }
        }
        
        
        if (errorCount != 0){
            print("[SKTileLayer]: \(errorCount) \(errorCount > 1 ? "errors" : "error") loading data.")
        }
        return errorCount == 0
    }
    
    /*
     Build an empty tile at the given coordinates. Returns an existing tile if one already exists,
     or nil if the coordinate is invalid.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - returns: `SKTile` tile.
     */
    open func addTileAt(_ x: Int, _ y: Int, gid: Int? = nil) -> SKTile? {
        let coord = CGPoint(x, y)
        return addTileAt(coord, gid: gid)
    }
    
    /*
     Build an empty tile at the given coordinates. Returns an existing tile if one already exists, 
     or nil if the coordinate is invalid.
     
     - parameter coord:   `CGPoint` tile coordinate
     - returns: `SKTile` tile.
     */
    open func addTileAt(_ coord: CGPoint, gid: Int? = nil) -> SKTile? {
        guard isValid(coord) else { return nil }
        
        // remove the current tile
        let current = removeTileAt(coord)
        
        var tileData: SKTilesetData? = nil
        if (gid != nil) {
            tileData = getTileData(withID: gid!)
        }
        
        let tile = SKTile(tileSize: tileSize)
    
        // set the tile overlap amount
        tile.setTileOverlap(tilemap.tileOverlap)
        tile.highlightColor = highlightColor
        
        // set the layer property
        tile.layer = self
        self.tiles[Int(coord.x), Int(coord.y)] = tile
        
        // get the position in the layer (plus tileset offset)
        let tilePosition = pointForCoordinate(coord: coord, offsetX: offset.x, offsetY: offset.y)
        tile.position = tilePosition
        addChild(tile)
        return tile
    }
    
    /*
     Remove the tile at a given x/y coordinates.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - returns: `SKTile?` removed tile.
     */
    open func removeTileAt(_ x: Int, _ y: Int) -> SKTile? {
        let coord = CGPoint(x, y)
        return removeTileAt(coord)
    }
    
    /*
     Remove the tile at a given coordinate.
     
     - parameter coord:   `CGPoint` tile coordinate.
     - returns: `SKTile?` removed tile.
     */
    open func removeTileAt(_ coord: CGPoint) -> SKTile? {
        let current = tileAt(coord)
        if let current = current {
            current.removeFromParent()
            self.tiles[Int(coord.x), Int(coord.y)] = nil
        }
        return current
    }
    
    /**
     Build a tile at the given coordinate with the given id. Returns nil if the id cannot be resolved.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - parameter gid: `Int` tile id.
     - returns: `SKTile?` tile.
     */
    fileprivate func buildTileAt(_ coord: CGPoint, id: UInt32) -> SKTile? {
        
        // masks for tile flipping
        let flippedDiagonalFlag: UInt32   = 0x20000000
        let flippedVerticalFlag: UInt32   = 0x40000000
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
                
                // set the tile overlap amount
                tile.setTileOverlap(tilemap.tileOverlap)
                tile.highlightColor = highlightColor
                
                // set the layer property
                tile.layer = self
                
                // get the position in the layer (plus tileset offset)
                let tilePosition = pointForCoordinate(coord: coord, offsetX: tileData.tileset.tileOffset.x, offsetY: tileData.tileset.tileOffset.y)
                
                // get the y-anchor point (half tile height / tileset height) to align the sprite properly to the grid
                let tileAlignment = tileHeightHalf / tileData.tileset.tileSize.height

                
                self.tiles[Int(coord.x), Int(coord.y)] = tile

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
    
    /**
     Set a tile at the given coordinate.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - returns: `SKTile?` tile.
     */
    public func setTile(_ x: Int, _ y: Int, tile: SKTile? = nil) -> SKTile? {
        self.tiles[x, y] = tile
        return tile
    }
    
    /**
     Set a tile at the given coordinate.
     
     - parameter coord:   `CGPoint` tile coordinate.
     - returns: `SKTile?` tile.
     */
    public func setTile(at coord: CGPoint, tile: SKTile? = nil) -> SKTile? {
        self.tiles[Int(coord.x), Int(coord.y)] = tile
        return tile
    }
    
    // MARK: - Overlap

    /**
     Set the tile overlap. Only accepts a value between 0 - 1.0
     
     - parameter overlap: `CGFloat` tile overlap value.
     */
    open func setTileOverlap(_ overlap: CGFloat) {
        for tile in tiles {
            if let tile = tile {
                tile.setTileOverlap(overlap)
            }
        }
    }
}

/**
 Represents object group draw order:

 - topDown:  objects are rendered from top-down
 - manual:   objects are rendered manually
 */
internal enum SKObjectGroupDrawOrder: String {
    case topDown   // default
    case manual
}



/**
 The `SKObjectGroup` class  child objects that are drawn in the current coordinate space.
 
 Most object properties can be set on the parent `SKObjectGroup` which is then applied to all child objects.
 
 Adding a child object with optional color override:
 
 ```swift
 objectGroup.addObject(myObject, withColor: SKColor.red)
 ```
 
 Querying an object with a specific name:
 
 ```swift
 let doorObject = objectGroup.getObject(named: "Door")
 ```
 
 Getting objects of a certain type:

 ```swift
 let rockObjects = objectGroup.getObjects(ofType: "Rock")
 ```
 */
open class SKObjectGroup: TiledLayerObject {
    
    internal var drawOrder: SKObjectGroupDrawOrder = SKObjectGroupDrawOrder.topDown
    fileprivate var objects: Set<SKTileObject> = []
    
    /**
     Toggle visibility for all of the objects in the layer.
     */
    open var showObjects: Bool = false {
        didSet {
            objects.forEach {$0.visible = showObjects}
        }
    }
    
    /**
     Returns the number of objects in this layer.
     */
    open var count: Int { return objects.count }
    
    /// Controls antialiasing for each object
    override open var antialiased: Bool {
        didSet {
            objects.forEach({$0.isAntialiased = antialiased})
        }
    }
    
    /**
     Governs object line width for each object.
     */
    open var lineWidth: CGFloat = 1.5 {
        didSet {
            objects.forEach {$0.lineWidth = lineWidth}
        }
    }
    
    // MARK: - Init
    /**
     Initialize with layer name and parent `SKTilemap`.
     
     - parameter layerName:    `String` layer name.
     - parameter tilemap:      `SKTilemap` parent map.
     */
    override public init(layerName: String, tilemap: SKTilemap) {
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .object
    }    
    
    /**
     Initialize with parent `SKTilemap` and layer attributes.
     
     **Do not use this intializer directly**
     
     - parameter tilemap:      `SKTilemap` parent map.
     - parameter attributes:   `[String: String]` layer attributes.
     */
    public init?(tilemap: SKTilemap, attributes: [String: String]) {
        guard let layerName = attributes["name"] else { return nil }
        super.init(layerName: layerName, tilemap: tilemap, attributes: attributes)
        
        // set objects color
        if let hexColor = attributes["color"] {
            self.color = SKColor(hexString: hexColor)
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
    open func addObject(_ object: SKTileObject, withColor: SKColor? = nil) -> SKTileObject? {
        if objects.contains(where: { $0.hashValue == object.hashValue }) {
            return nil
        }
        
        // if the override color is nil, use the layer color
        var objectColor: SKColor = (withColor == nil) ? self.color : withColor!
        
        // if the object has a color property override, use that instead
        if object.hasKey("color") {
            if let hexColor = object.stringForKey("color") {
                objectColor = SKColor(hexString: hexColor)
            }
        }
        
        // position the object
        let pixelPosition = object.position
        let screenPosition = pixelToScreenCoords(pixelPosition)
        object.position = screenPosition.invertedY
        
        // transfer object properties
        object.setColor(color: objectColor)
        object.isAntialiased = antialiased
        object.lineWidth = lineWidth
        objects.insert(object)
        object.layer = self
        addChild(object)
        
        // render the object
        object.drawObject()
        
        // hide the object if the tilemap is set to
        object.visible = tilemap.showObjects
        return object
    }
    
    /**
     Remove an `SKTileObject` object from the objects set.
     
     - parameter object:    `SKTileObject` object.
     - returns: `SKTileObject?` removed object.
     */
    open func removeObject(_ object: SKTileObject) -> SKTileObject? {
        return objects.remove(object)
    }
    
    /**
     Render all of the objects in the group.
     */
    open func drawObjects() {
        objects.forEach({$0.drawObject()})
    }
    
    /**
     Set the color for all objects.
     
     - parameter color: `SKColor` object color.
     - parameter force: `Bool` force color on objects that have an override.
     */
    override open func setColor(color: SKColor) {
        super.setColor(color: color)
        for object in objects {
            if !object.hasKey("color") {
                object.setColor(color: color)
            }
        }
    }
    
    /**
     Set the color for all objects.
        
     - parameter color: `SKColor` object color.
     - parameter force: `Bool` force color on objects that have an override.
     */
    override open func setColor(hexString: String) {
        super.setColor(hexString: hexString)
        for object in objects {
            if !object.hasKey("color") {
                object.setColor(hexString: hexString)
    }
        }
    }
    
    /**
     Returns an array of object names.
    
     - returns: `[String]` object names in the layer.
     */
    open func objectNames() -> [String] {
        // flatmap will ignore nil name values.
        return objects.flatMap({$0.name})
    }
    
    /**
     Returns an object with the given id.
     
     - parameter id: `Int` Object id.
     - returns: `SKTileObject?`
     */
    open func getObject(withID id: Int) -> SKTileObject? {
        if let index = objects.index( where: { $0.id == id } ) {
            return objects[index]
        }
        return nil
    }
    
    /**
     Returns an object with the given name.
     
     - parameter name: `String` Object name.
     - returns: `SKTileObject?`
     */
    open func getObject(named name: String) -> SKTileObject? {
        if let index = objects.index( where: { $0.name == name } ) {
            return objects[index]
        }
        return nil
    }
     
    /**
     Return all child objects.
     
     - returns: `[SKTileObject]` array of matching objects.
     */
    open func getObjects() -> [SKTileObject] {
        return Array(objects)
    }
    
    /**
     Return objects of a given type.
     
     - parameter type: `String` object type.
     - returns: `[SKTileObject]` array of matching objects.
     */
    open func getObjects(ofType type: String) -> [SKTileObject] {
        return objects.filter( {$0.type == type})
    }
}



/**
 The `SKImageLayer` object is really nothing more than a sprite with positioning attributes.
 
 Set the layer image with:
 
 ```swift
 imageLayer.setLayerImage("clouds-background")
 ```
 
 */
open class SKImageLayer: TiledLayerObject {
    
    open var image: String!                       // image name for layer
    fileprivate var sprite: SKSpriteNode?         // sprite
    
    open var wrapX: Bool = false                  // wrap horizontally
    open var wrapY: Bool = false                  // wrap vertically
    
    // MARK: - Init
    /**
     Initialize with a layer name, and parent `SKTilemap` node.
     
     - parameter layerName: `String` image layer name.
     - parameter tilemap:   `SKTilemap` parent map.
    */
    override public init(layerName: String, tilemap: SKTilemap) {
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .image
    }
    
    /**
     Initialize with parent `SKTilemap` and layer attributes. 

     **Do not use this intializer directly**
     
     - parameter tilemap:      `SKTilemap` parent map.
     - parameter attributes:   `[String: String]` layer attributes.
    */
    public init?(tilemap: SKTilemap, attributes: [String: String]) {
        guard let layerName = attributes["name"] else { return nil }
        super.init(layerName: layerName, tilemap: tilemap, attributes: attributes)
        self.layerType = .image
    }
    
    /**
     Set the layer image as a sprite.
     
     - parameter named: `String` image name.
     */
    open func setLayerImage(_ named: String) {
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

// MARK: - Debugging

// Sprite object for visualizaing grid & graph.
fileprivate class TiledLayerGrid: SKSpriteNode {
    
    private var layer: TiledLayerObject
    private var gridTexture: SKTexture! = nil
    private var graphTexture: SKTexture! = nil
    private var imageScale: CGFloat = 3.0

    private var gridOpacity: CGFloat { return layer.gridOpacity }

    init(tileLayer: TiledLayerObject){
        layer = tileLayer
        super.init(texture: SKTexture(), color: SKColor.clear, size: tileLayer.sizeInPoints)
        positionLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Align the sprite with the layer.
     */
    func positionLayer() {
        // set the anchorpoint to 0,0 to match the frame
        anchorPoint = CGPoint.zero
        isHidden = true
        
        #if os(iOS)
        position.y = -layer.sizeInPoints.height
        #endif
    }
    
    var showGrid: Bool = false {
        didSet {
            guard oldValue != showGrid else { return }
            texture = nil
            isHidden = true
            if (showGrid == true){
                // get the last z-position
                zPosition = layer.tilemap.lastZPosition + layer.tilemap.zDeltaForLayers
                isHidden = false
                var gridSize = CGSize.zero
                
                // generate the texture
                if (gridTexture == nil) {
                    let gridImage = drawGrid(self.layer, scale: imageScale)
                    gridTexture = SKTexture(cgImage: gridImage)
                    //let textureFilter: SKTextureFilteringMode = (layer.antialiased == true) ? .linear : .nearest
                    gridTexture.filteringMode = .linear
                }
                
                
                gridSize = gridTexture.size() / imageScale
                #if os(OSX)
                gridSize = gridTexture.size()
                #endif
                texture = gridTexture
                alpha = gridOpacity
                size = gridSize
                #if os(iOS)
                position.y = -gridSize.height
                #else
                yScale = -1
                #endif
            }
        }
    }
}


/**
 *  Two-dimensional array structure.
 */
internal struct Array2D<T> {
    public let columns: Int
    public let rows: Int
    public var array: [T?]
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array(repeating: nil, count: rows*columns)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        }
        set {
            array[row*columns + column] = newValue
        }
    }
    
    var count: Int { return self.array.count }
    var isEmpty: Bool { return array.isEmpty }
    
    func contains<T : Equatable>(_ obj: T) -> Bool {
        let filtered = self.array.filter {$0 as? T == obj}
        return filtered.count > 0
    }
}



// MARK: - Extensions

extension TiledLayerObject {
    
    /**
     Add a node at the given coordinates. By default, the zPositon
     will be higher than all of the other nodes in the layer.
     
     - parameter node:      `SKNode` object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter dx:        `CGFloat` offset x-amount.
     - parameter dy:        `CGFloat` offset y-amount.
     - parameter zpos:      `CGFloat?` optional z-position.
     */
    public func addChild(_ node: SKNode, _ x: Int, _ y: Int, dx: CGFloat = 0, dy: CGFloat = 0, zpos: CGFloat? = nil) {
        let coord = CGPoint(x, y)
        let offset = CGPoint(x: dx, y: dy)
        addChild(node, coord: coord, offset: offset, zpos: zpos)
    }
    
    /**
     Add a node at the given coordinates. By default, the zPositon
     will be higher than all of the other nodes in the layer.
     
     - parameter node:      `SKNode` object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter zpos:      `CGFloat?` optional z-position.
     */
    public func addChild(_ node: SKNode, _ x: Int, _ y: Int, zpos: CGFloat? = nil) {
        let coord = CGPoint(x, y)
        addChild(node, coord: coord, offset: CGPoint.zero, zpos: zpos)
    }
    
    /**
     Returns a point for a given coordinate in the layer.
     
     - parameter x:       `Int` x-coordinate.
     - parameter y:       `Int` y-coordinate.
     - parameter offsetX: `CGFloat` x-offset value.
     - parameter offsetY: `CGFloat` y-offset value.
     - returns: `CGPoint` position in layer.
     */
    public func pointForCoordinate(_ x: Int, _ y: Int, offsetX: CGFloat=0, offsetY: CGFloat=0) -> CGPoint {
        return self.pointForCoordinate(coord: CGPoint(x, y), offsetX: offsetX, offsetY: offsetY)
    }
    
    /**
     Returns a point for a given coordinate in the layer.
     
     - parameter coord:  `CGPoint` tile coordinate.
     - parameter offset: `CGPoint` tile offset.
     - returns: `CGPoint` point in layer.
     */
    public func pointForCoordinate(coord: CGPoint, offset: CGPoint) -> CGPoint {
        return self.pointForCoordinate(coord: coord, offsetX: offset.x, offsetY: offset.y)
    }
    
    /**
     Returns a point for a given coordinate in the layer.
     
     - parameter coord:  `CGPoint` tile coordinate.
     - parameter offset: `TileOffset` tile offset hint.
     - returns: `CGPoint` point in layer.
     */
    public func pointForCoordinate(coord: CGPoint, tileOffset: TileOffset = .center) -> CGPoint {
        var offset = CGPoint(x: 0, y: 0)
        switch tileOffset {
        case .top:
            offset = CGPoint(x: 0, y: -tileHeightHalf)
        case .topLeft:
            offset = CGPoint(x: -tileWidthHalf, y: -tileHeightHalf)
        case .topRight:
            offset = CGPoint(x: tileWidthHalf, y: -tileHeightHalf)
        case .bottom:
            offset = CGPoint(x: 0, y: tileHeightHalf)
        case .bottomLeft:
            offset = CGPoint(x: -tileWidthHalf, y: tileHeightHalf)
        case .bottomRight:
            offset = CGPoint(x: tileWidthHalf, y: tileHeightHalf)
        case .left:
            offset = CGPoint(x: -tileWidthHalf, y: 0)
        case .right:
            offset = CGPoint(x: tileWidthHalf, y: 0)
        default:
            break
        }
        return self.pointForCoordinate(coord: coord, offsetX: offset.x, offsetY: offset.y)
    }
    
    /**
     Returns a tile coordinate for a given point in the layer.
     
     - parameter x:       `Int` x-position.
     - parameter y:       `Int` y-position.
     - returns: `CGPoint` position in layer.
     */
    public func coordinateForPoint(_ x: Int, _ y: Int) -> CGPoint {
        return self.coordinateForPoint(CGPoint(x, y))
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
    
    override open var description: String { return "\(layerType.stringValue.capitalized) Layer: \"\(name!)\"" }
    override open var debugDescription: String { return description }
}


extension SKTiledLayerType {
    /// Returns a string representation of the layer type.
    internal var stringValue: String { return "\(self)".lowercased() }
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


extension Array2D: Sequence {
    
    internal func makeIterator() -> AnyIterator<T?> {
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
internal func SKColorWithRGB(_ r: Int, g: Int, b: Int) -> SKColor {
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
internal func SKColorWithRGBA(_ r: Int, g: Int, b: Int, a: Int) -> SKColor {
    return SKColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a)/255.0)
}
