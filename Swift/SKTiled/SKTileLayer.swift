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


public enum SKTiledLayerType: Int {
    case invalid    = -1
    case tile
    case object
    case image
}


public enum ObjectGroupColors: String {
    case pink     = "#c8a0a4"
    case blue     = "#6fc0f3"
    case green    = "#70d583"
    case orange   = "#f3dc8d"
}


// MARK: - Base Layer Class

/// `TiledLayerObject` is the base class for all Tiled layer types.
open class TiledLayerObject: SKNode, SKTiledObject {
    
    open var layerType: SKTiledLayerType = .invalid
    open var tilemap: SKTilemap
    open var uuid: String = UUID().uuidString                         // unique object id
    open var index: Int = 0                                           // index of the layer in the tmx file
    
    // properties
    open var properties: [String: String] = [:]                       // generic layer properties
    
    // colors
    open var color: SKColor = SKColor.gray                            // layer color
    open var gridColor: SKColor = SKColor.black                       // grid visualization color
    open var frameColor: SKColor = SKColor.black                      // bounding box color
    open var highlightColor: SKColor = SKColor.white                  // layer highlight color
    
    // layer offset
    open var offset: CGPoint = CGPoint.zero                           // layer offset value
    
    // size & anchor point
    open var size: CGSize { return tilemap.size }
    open var tileSize: CGSize { return tilemap.tileSize }
    open var orientation: TilemapOrientation { return tilemap.orientation }
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
    fileprivate var frameShape: SKShapeNode = SKShapeNode()
    fileprivate var grid: SKSpriteNode
    open var gridOpacity: CGFloat = 0.1
    
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
    
    /// Returns a bounding box for the given layer
    open var bounds: CGRect {
        return CGRect(x: -sizeInPoints.halfWidth, y: -sizeInPoints.halfHeight, width: sizeInPoints.width, height: sizeInPoints.height)
    }
    
    override open var frame: CGRect {
        return CGRect(x: 0, y: 0, width: sizeInPoints.width, height: -sizeInPoints.height)
    }
    
    // blending/visibility
    open var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    open var visible: Bool {
        get { return !self.isHidden }
        set { self.isHidden = !newValue }
    }
    
    open var showGrid: Bool {
        get {
            return grid.isHidden == false
        } set {
            grid.isHidden = !newValue
            let imageScale: CGFloat = 2.0
            let gridImage = drawGrid(self, scale: imageScale)
            let gridTexture = SKTexture(cgImage: gridImage)
            
            var gridSize = CGSize.zero
            
            #if os(iOS)
            gridSize = gridTexture.size() / imageScale
            #else
            gridSize = gridTexture.size()
            #endif
            
            let textureFilter: SKTextureFilteringMode = tileWidth > 16 ? .linear : .linear
            gridTexture.filteringMode = textureFilter
            
            grid.texture = gridTexture
            grid.alpha = gridOpacity
            grid.size = gridSize
            #if os(iOS)
            grid.position.y = -gridSize.height
            #else
            grid.position.y = -sizeInPoints.height
            #endif
        }
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
            self.visible = (visibility == "1") ? true : false
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
    
    /**
     Set the layer color.
     
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
     
     - parameter coord: `TiledCoord` tile coordinate.
     
     - returns: `Bool` coodinate is valid.
     */
    open func isValid(_ coord: TileCoord) -> Bool {
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
     
     - parameter x: `Int` y-coordinate.
     - parameter y: `Int` x-coordinate.
     
     - returns: `CGPoint` position in layer.
     */
    open func pointForCoordinate(_ coord: TileCoord, offsetX: CGFloat=0, offsetY: CGFloat=0) -> CGPoint {
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
            
        case .hexagonal:
            tileOffsetX += tileWidthHalf
            tileOffsetY += tileHeightHalf
            
        case .staggered:
            tileOffsetX += tileWidthHalf
            //tileOffsetY += tileHeightHalf
        }
        
        screenPoint.x += tileOffsetX
        screenPoint.y += tileOffsetY
        
        return screenPoint.invertedY
    }
        
    /**
     Converts a tile coordinate from a point in map space.
            
     - parameter point: `CGPoint` point in map space.
     
     - returns: `TileCoord` tile coordinate.
     */
    open func pixelToTileCoords(_ point: CGPoint) -> TileCoord {
        switch orientation {
        case .orthogonal:
            return TileCoord(point.x / tileWidth, point.y / tileHeight)
        case .isometric:
            return TileCoord(point.x / tileHeight, point.y / tileHeight)
        case .hexagonal:
            return screenToTileCoords(point)
        case .staggered:
            return screenToTileCoords(point)
        }
    }
        
    /**
     Converts a tile coordinate to a coordinate in map space.
     
     - parameter coord: `TileCoord` tile coordinate.
     
     - returns: `CGPoint` point in map space.
     */
    open func tileToPixelCoords(_ coord: TileCoord) -> CGPoint {
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
     
     - returns: `TileCoord` tile coordinate.
     */
    open func screenToTileCoords(_ point: CGPoint) -> TileCoord {
        var pixelX = point.x
        var pixelY = point.y
        //print("\n")
        switch orientation {
        case .orthogonal:
            return TileCoord(pixelX / tileWidth, pixelY / tileHeight)
            
        case .isometric:
            pixelX -= height * tileWidthHalf
            let tileY = pixelY / tileHeight
            let tileX = pixelX / tileWidth
            return TileCoord(tileY + tileX, tileY - tileX)
            
        case .hexagonal:
            // calculate r, h, & s
            var r: CGFloat = 0
            var h: CGFloat = 0
            var s: CGFloat = 0
            
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
                
            // pointy
            } else {
                s = tilemap.sideLengthY
                r = tileWidth / 2
                h = (tileHeight - tilemap.sideLengthY) / 2
                pixelY -= h
                sectionX = pixelX / (r * 2)
                sectionY = pixelY / (h + s)                
            }
           
            var gridPosition = CGPoint(x: sectionX, y: sectionY)
            return TileCoord(point: gridPosition)
            
            
        case .staggered:
            if (tilemap.staggerX) {
                pixelX -= tilemap.staggerEven ? tilemap.sideOffsetX: 0
            } else {
                pixelY -= tilemap.staggerEven ? tilemap.sideOffsetY : 0
            }
            
            var gridPosition = CGPoint(x: floor(pixelX), y: floor(pixelY))
            return TileCoord(point: gridPosition)
        }
    }
    
    /**
     Converts a tile coordinate into a screen point.
     
     - parameter coord: `TileCoord` tile coordinate.
     
     - returns: `CGPoint` point in screen space.
     */
    public func tileToScreenCoords(_ coord: TileCoord) -> CGPoint {
        switch orientation {
        case .orthogonal:
            return CGPoint(x: coord.x * tileWidth, y: coord.y * tileHeight)
            
        case .isometric:
            let x = CGFloat(coord.x)
            let y = CGFloat(coord.y)
            let originX = height * tileWidthHalf
            return CGPoint(x: (x - y) * tileWidthHalf + originX,
                               y: (x + y) * tileHeightHalf)
            
        case .hexagonal, .staggered:
            let tileX = Int(coord.x)  // use floor?
            let tileY = Int(coord.y)
            
            var pixelX: Int = 0
            var pixelY: Int = 0
            
            if (tilemap.staggerX) {
                pixelY = tileY * Int(tileHeight + tilemap.sideLengthY)
                
                if tilemap.doStaggerX(tileX) {
                    pixelY += Int(tilemap.rowHeight)
                }
                
                pixelX = tileX * Int(tilemap.columnWidth)
            } else {
                pixelX = tileX * Int(tileWidth + tilemap.sideLengthX)
                
                if tilemap.doStaggerY(tileY) {
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
        case .orthogonal:
            return point
            
        case .isometric:
            var x = point.x
            let y = point.y
            x -= height * tileWidthHalf
            let tileY = y / tileHeight
            let tileX = x / tileWidth
            
            return CGPoint(x: (tileY + tileX) * tileHeight,
                               y: (tileY - tileX) * tileHeight)
        case .hexagonal, .staggered:
            return point
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
        case .orthogonal:
            return point
            
        case .isometric:
            let originX = height * tileWidthHalf
            //let originY = tileHeightHalf
            let tileY = point.y / tileHeight
            let tileX = point.x / tileHeight
            return CGPoint(x: (tileX - tileY) * tileWidthHalf + originX,
                               y: (tileX + tileY) * tileHeightHalf)
        case .hexagonal, .staggered:
            return point
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
    
    override open var hashValue: Int {
        return self.uuid.hashValue
    }
}


// MARK: - Tiled Layer

open class SKTileLayer: TiledLayerObject {
    
    fileprivate typealias TilesArray = Array2D<SKTile>
    
    // container for the tile sprites
    fileprivate var tiles: TilesArray                   // array of tiles
    open var render: Bool = false                 // render tile layer as a single image
    
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
    open func tileAt(_ x: Int, _ y: Int) -> SKTile? {
        if isValid(x, y) == false { return nil }
        return tiles[x,y]
    }
    
    /**
     Returns a tile at the given coordinate, if one exists.
     
     - parameter coord:   `TileCoord` tile coordinate.
     
     - returns: `SKTile?` tile object, if it exists.
     */
    open func tileAt(_ coord: TileCoord) -> SKTile? {
        if isValid(coord) == false { return nil }
        return tiles[Int(coord.x), Int(coord.y)]
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
            
        // render the layer in the background
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
                // TODO: threaded renderer not liking mutation here
                self.tiles[Int(coord.x), Int(coord.y)] = tile
                    
                // get the position in the layer (plus tileset offset)
                let tilePosition = pointForCoordinate(coord, offsetX: tileData.tileset.tileOffset.x, offsetY: tileData.tileset.tileOffset.y)
                    
                // get the y-anchor point (half tile height / tileset height) to align the sprite properly to the grid
                let tileAlignment = tileHeightHalf / tileData.tileset.tileSize.height

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
    open func setTileOverlap(_ overlap: CGFloat) {
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

open class SKObjectGroup: TiledLayerObject {
    
    open var drawOrder: ObjectGroupDrawOrder = ObjectGroupDrawOrder.TopDown
    fileprivate var objects: Set<SKTileObject> = []
    
    open var showObjects: Bool = false {
        didSet {
            objects.map({$0.visible = showObjects})
        }
    }
    
    /// Returns the number of objects in this layer.
    open var count: Int { return objects.count }
    
    /// Controls antialiasing for each object
    open var antialiased: Bool = false {
        didSet {
            objects.forEach({$0.isAntialiased = antialiased})
        }
    }
    
    /// Governs object line width for each object
    open var lineWidth: CGFloat = 1.5 {
        didSet {
            objects.map({$0.lineWidth = lineWidth})
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
     
     - parameter id: `Int` Object id
     
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


// MARK: - Image Layer

open class SKImageLayer: TiledLayerObject {
    
    open var image: String!                       // image name for layer
    fileprivate var sprite: SKSpriteNode?         // sprite
    
    open var wrapX: Bool = false                  // wrap horizontally
    open var wrapY: Bool = false                  // wrap vertically
    
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
    
    override open var description: String { return "\(layerType.stringValue.capitalized) Layer: \"\(name!)\"" }
    override open var debugDescription: String { return description }
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
     Initialize an SKColor with a hexidecimal string.
     
     - parameter hexString:  `String` hexidecimal code.
     
     - returns: `SKColor`
     */
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
                }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
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
