//
//  SKTiledLayerObject.swift
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
import GameplayKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif




// tuple representing the current render stats
typealias RenderInfo = (idx: Int, path: String, zpos: Double,
                        sw: Int, sh: Int, tsw: Int, tsh: Int,
                        offx: Int, offy: Int, ancx: Int, ancy: Int,
                        tc: Int, obj: Int, vis: Int, gn: Int?)



/// Layer render statistics.
typealias LayerRenderStatistics = (tiles: Int, objects: Int)


/**
 
 ## Overview
 
 The `SKTiledLayerObject` is the generic base class for all layer types.  This class doesn't
 define any object or child types, but provides base behaviors for layered content, including:
 
 - coordinate transformations
 - validating coordinates
 - positioning and alignment
 
 
 ### Properties
 
 | Property    | Description                                                          |
 |-------------|----------------------------------------------------------------------|
 | tilemap     | Parent tilemap.                                                      |
 | index       | Layer index. Matches the index of the layer in the source TMX file.  |
 | size        | Layer size (in tiles).                                               |
 | tileSize    | Layer tile size (in pixels).                                         |
 | anchorPoint | Layer anchor point, used to position layers.                         |
 | origin      | Layer origin point, used for placing tiles.                          |
 
 
 ### Instance Methods ###
 
 | Method                            | Description                                                          |
 |-----------------------------------|----------------------------------------------------------------------|
 | pointForCoordinate(coord:offset:) | Returns a point for a coordinate in the layer, with optional offset. |
 | coordinateForPoint(_:)            | Returns a tile coordinate for a given point in the layer.            |
 | touchLocation(_:)                 | Returns a converted touch location in map space.                     |
 | coordinateAtTouchLocation(_:)     | Returns the tile coordinate at a touch location.                     |
 | isValid(coord:)                   | Returns true if the coordinate is valid.                             |
 
 
 ### Usage
 
 Coordinate transformation functions return points in the current tilemap projection:
 
 ```swift
 node.position = tileLayer.pointForCoordinate(2, 1)
 ```
 Coordinate transformation functions translate points to map coordinates:
 
 ```swift
 coord = coordinateForPoint(touchPosition)
 ```
 
 Return the tile coordinate at a touch event (iOS):
 
 ```swift
 coord = imageLayer.coordinateAtTouchLocation(touchPosition)
 ```
 
 Return the tile coordinate at a mouse event (macOS):
 
 ```swift
 coord = groupLayer.coordinateAtMouseEvent(event: mouseClicked)
 ```
 */
public class SKTiledLayerObject: SKEffectNode, SKTiledObject {
    
    /// Reference to the parent tilemap.
    public var tilemap: SKTilemap
    
    /// Unique layer id.
    public var uuid: String = UUID().uuidString
    
    /// Layer type.
    public var type: String!
    
    /// Layer index. Matches the index of the layer in the source TMX file.
    public var index: Int = 0
    
    /// Logging verbosity.
    internal var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel
    
    /// Position in the render tree.
    public var rawIndex: Int = 0
    
    /// Flattened layer index (internal use only).
    internal var realIndex: Int {
        return tilemap.layers.firstIndex(where: { $0 === self }) ?? self.index
    }
    
    /// Custom layer properties.
    public var properties: [String: String] = [:]
    
    /// Ignore custom properties.
    public var ignoreProperties: Bool = false
    
    /**
     ## Overview
     
     Enum describing layer type.
     
     ### Constants ###
     
     | Property    | Description                               |
     |:------------|:------------------------------------------|
     | tile        | Layer contains tile sprite data.          |
     | object      | Layer contains vector objects, text, etc. |
     | image       | Layer contains a static image.            |
     | group       | Layer container.                          |
     
     */
    enum TiledLayerType: Int {
        case none     = -1
        case tile
        case object
        case image
        case group
    }
    
    /**
     ## Overview
     
     Tile offset hint for coordinate conversion.
     
     ### Constants ###
     
     | Property    | Description                               |
     |:------------|:------------------------------------------|
     | center      | Tile is centered.                         |
     | top         | Tile is offset at the top.                |
     | topLeft     | Tile is offset at the upper left.         |
     | topRight    | Tile is offset at the upper right.        |
     | bottom      | Tile is offset at the bottom.             |
     | bottomLeft  | Tile is offset at the bottom left.        |
     | bottomRight | Tile is offset at the bottom right.       |
     | left        | Tile is offset at the left side.          |
     | right       | Tile is offset at the right side.         |
     
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
    
    internal var layerType: TiledLayerType = TiledLayerType.none
    
    /// Layer color.
    public dynamic var color: SKColor = TiledObjectColors.gun
    
    /// Grid visualization color.
    public var gridColor: SKColor = TiledGlobals.default.debug.gridColor
    
    /// Bounding box color.
    public var frameColor: SKColor = TiledGlobals.default.debug.frameColor
    
    /// Layer highlight color (for highlighting tiles)
    public var highlightColor: SKColor = SKColor.white
    
    /// Layer highlight duration
    public var highlightDuration: TimeInterval = TiledGlobals.default.debug.highlightDuration
    
    /// Layer is isolated.
    public private(set) var isolated: Bool = false
    
    /// Layer offset value.
    public var offset: CGPoint = CGPoint.zero
    
    /// Layer size (in tiles).
    public var size: CGSize {
        return tilemap.size
    }
    
    /// Layer tile size (in pixels).
    public var tileSize: CGSize {
        return tilemap.tileSize
    }
    
    /// Tile map orientation.
    internal var orientation: SKTilemap.TilemapOrientation {
        return tilemap.orientation
    }
    
    /// Layer anchor point, used to position layers.
    public var anchorPoint: CGPoint {
        return tilemap.layerAlignment.anchorPoint
    }
    
    /// Storage for parsing errors.
    internal var gidErrors: [UInt32] = []
    
    /// Pathfinding graph.
    public var graph: GKGridGraph<GKGridGraphNode>!
    
    // debug visualizations
    public var gridOpacity: CGFloat = TiledGlobals.default.debug.gridOpactity
    
    /// Debug visualization node
    internal var debugNode: SKTiledDebugDrawNode!
    
    /// Debug visualization options.
    public var debugDrawOptions: DebugDrawOptions = [] {
        didSet {
            guard oldValue != debugDrawOptions else { return }
            debugNode?.draw()
        }
    }
    
    /// Indicates the layer has been rendered.
    internal private(set) var isRendered: Bool = false
    
    /// Antialias lines.
    public var antialiased: Bool = false
    
    /// Map color blending value.
    public var colorBlendFactor: CGFloat = 1.0
    
    /// Render scaling property.
    public var renderQuality: CGFloat = TiledGlobals.default.renderQuality.default
    
    /// Name used to access navigation graph.
    public var navigationKey: String
    
    /// Output current zPosition
    public var currentZPosition: CGFloat {
        return self.zPosition
    }
    
    /// Optional background color.
    public var backgroundColor: SKColor? = nil {
        didSet {
            self.background.color = (backgroundColor != nil) ? backgroundColor! : SKColor.clear
            self.background.colorBlendFactor = (backgroundColor != nil) ? 1.0 : 0
        }
    }
    
    /// Layer background sprite.
    lazy public var background: SKSpriteNode = {
        let sprite = SKSpriteNode(color: SKColor.clear, size: self.tilemap.sizeInPoints)
        sprite.anchorPoint = CGPoint.zero
        
        #if os(iOS) || os(tvOS)
        sprite.position.y = -self.tilemap.sizeInPoints.height
        #else
        sprite.yScale *= -1
        #endif
        self.addChild(sprite)
        return sprite
    }()
    
    // MARK: - Geometry
    
    /// Returns the position of layer origin point (used to place tiles).
    public var origin: CGPoint {
        switch orientation {
            case .orthogonal:
                return CGPoint.zero
            case .isometric:
                return CGPoint(x: height * tileWidthHalf, y: tileHeightHalf)
            case .hexagonal:
                let startPoint = CGPoint.zero
                //startPoint.x -= tileWidthHalf
                //startPoint.y -= tileHeightHalf
                return startPoint
            case .staggered:
                return CGPoint.zero
        }
    }
    
    /// Returns the frame rectangle of the layer (used to draw bounds).
    public var bounds: CGRect {
        return CGRect(x: 0, y: 0, width: sizeInPoints.width, height: -sizeInPoints.height)
    }
    
    /**
     Returns the points of the layer's bounding shape.
     
     - returns: `[CGPoint]` array of points.
     */
    public func getVertices() -> [CGPoint] {
        return self.bounds.points
    }
    
    /// Returns layer render statisics
    internal var renderInfo: RenderInfo {
        return (index, path, Double(zPosition), Int(tilemap.size.width),
                Int(tilemap.size.height), Int(tileSize.width),
                Int(tileSize.height),  Int(offset.x), Int(offset.y),
                Int(anchorPoint.x), Int(anchorPoint.y), 0, 0, (isHidden == true) ? 0 : 1, nil)
    }
    
    internal var layerRenderStatistics: LayerRenderStatistics {
        return (tiles: 0, objects: 0)
    }
    
    /// Tile update mode.
    public var updateMode: TileUpdateMode {
        return tilemap.updateMode
    }
    
    
    // MARK: - Init
    
    /**
     Initialize via the parser.
     
     *This intializer is meant to be called by the `SKTilemapParser`, you should not use it directly.*
     
     - parameter layerName:  `String` layer name.
     - parameter tilemap:    `SKTilemap` parent tilemap node.
     - parameter attributes: `[String: String]` dictionary of layer attributes.
     - returns: `SKTiledLayerObject?` tiled layer, if initialization succeeds.
     */
    public init?(layerName: String, tilemap: SKTilemap, attributes: [String: String]) {
        self.tilemap = tilemap
        self.ignoreProperties = tilemap.ignoreProperties
        self.navigationKey = layerName
        super.init()
        self.debugNode = SKTiledDebugDrawNode(tileLayer: self)
        self.name = layerName
        self.shouldEnableEffects = false
        
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
        
        // set the layer's antialiasing based on tile size
        self.antialiased = (self.tilemap.currentZoom < 1)
        addChild(debugNode)
    }
    
    /**
     Create a new layer within the parent tilemap node.
     
     - parameter layerName:  `String` layer name.
     - parameter tilemap:    `SKTilemap` parent tilemap node.
     - returns: `SKTiledLayerObject` tiled layer object.
     */
    public init(layerName: String, tilemap: SKTilemap) {
        self.tilemap = tilemap
        self.ignoreProperties = tilemap.ignoreProperties
        self.navigationKey = layerName
        super.init()
        self.debugNode = SKTiledDebugDrawNode(tileLayer: self)
        self.name = layerName
        
        // set the layer's antialiasing based on tile size
        self.antialiased = (self.tilemap.currentZoom < 1)
        addChild(debugNode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeAllActions()
        removeAllChildren()
    }
    
    // MARK: - Color
    
    /**
     Set the layer color with an `SKColor`.
     
     - parameter color: `SKColor` object color.
     */
    public func setColor(color: SKColor) {
        self.color = color
    }
    
    /**
     Set the layer color with a hex string.
     
     - parameter hexString: `String` color hex string.
     */
    public func setColor(hexString: String) {
        self.color = SKColor(hexString: hexString)
    }
    
    // MARK: - Children
    
    /// Child layer array.
    public var layers: [SKTiledLayerObject] {
        return [self]
    }
    
    #if os(iOS) || os(tvOS)
    
    // MARK: - Touch Events
    
    /**
     Returns a converted touch location.
     
     - parameter touch: `UITouch` touch location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    public func touchLocation(_ touch: UITouch) -> CGPoint {
        return convertPoint(touch.location(in: self))
    }
    
    /**
     Returns the tile coordinate at a touch location.
     
     - parameter touch: `UITouch` touch location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    public func coordinateAtTouchLocation(_ touch: UITouch) -> CGPoint {
        return screenToTileCoords(touchLocation(touch))
    }
    #endif
    
    #if os(macOS)
    
    // MARK: - Mouse Events
    
    /**
     Returns a mouse event location in the current layer.
     
     - parameter event: `NSEvent` mouse event location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    public func mouseLocation(event: NSEvent) -> CGPoint {
        return convertPoint(event.location(in: self))
    }
    
    /**
     Returns the tile coordinate at a mouse event location.
     
     - parameter event: `NSEvent` mouse event location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    public func coordinateAtMouseEvent(event: NSEvent) -> CGPoint {
        return screenToTileCoords(mouseLocation(event: event))
    }
    #endif
    
    // MARK: - Coordinate Conversion
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
     
     - parameter coord: `CGPoint` tile coordinate.
     - returns: `Bool` coodinate is valid.
     */
    public func isValid(coord: CGPoint) -> Bool {
        return isValid(Int(coord.x), Int(coord.y))
    }
    
    /**
     Convert a point into the tile map's coordinate space.
     
     - parameter point: `CGPoint` input point.
     - returns: `CGPoint` point with y-value inverted.
     */
    public func convertPoint(_ point: CGPoint) -> CGPoint {
        return point.invertedY
    }
    
    /**
     Returns a point for a given coordinate in the layer, with optional offset values for x/y.
     
     - parameter coord:   `CGPoint` tile coordinate.
     - parameter offsetX: `CGFloat` x-offset value.
     - parameter offsetY: `CGFloat` y-offset value.
     - returns: `CGPoint` point in layer (spritekit space).
     */
    public func pointForCoordinate(coord: CGPoint, offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> CGPoint {
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
        
        return floor(point: screenPoint.invertedY)
    }
    
    /**
     Returns a tile coordinate for a given point in the layer.
     
     - parameter point: `CGPoint` point in layer (spritekit space).
     - returns: `CGPoint` tile coordinate.
     */
    public func coordinateForPoint(_ point: CGPoint) -> CGPoint {
        return screenToTileCoords(point.invertedY)
    }
    
    /**
     Returns a tile coordinate for a given point in the layer as a `vector_int2`.
     
     - parameter point: `CGPoint` point in layer.
     - returns: `int2` tile coordinate.
     */
    public func vectorCoordinateForPoint(_ point: CGPoint) -> int2 {
        return screenToTileCoords(point.invertedY).toVec2
    }
    
    // MARK: Internal Coordinate Mapping
    
    /**
     Converts a tile coordinate from a point in map space. Note that this function
     expects scene points to be inverted in y before being passed as input.
     
     - parameter point: `CGPoint` point in map space.
     - returns: `CGPoint` tile coordinate.
     */
    internal func pixelToTileCoords(_ point: CGPoint) -> CGPoint {
        switch orientation {
            case .orthogonal:
                return CGPoint(x: floor(point.x / tileWidth), y: floor(point.y / tileHeight))
            case .isometric:
                return CGPoint(x: floor(point.x / tileHeight), y: floor(point.y / tileHeight))
            case .hexagonal:
                return screenToTileCoords(point)
            case .staggered:
                return screenToTileCoords(point)
        }
    }
    
    /**
     Converts a tile coordinate to a coordinate in map space. Note that this function
     returns a point that needs to be converted to negative-y space.
     
     - parameter coord: `CGPoint` tile coordinate.
     - returns: `CGPoint` point in map space.
     */
    internal func tileToPixelCoords(_ coord: CGPoint) -> CGPoint {
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
    internal func screenToTileCoords(_ point: CGPoint) -> CGPoint {
        
        var pixelX = point.x
        var pixelY = point.y
        
        switch orientation {
            
            case .orthogonal:
                return CGPoint(x: floor(pixelX / tileWidth), y: floor(pixelY / tileHeight))
                
            case .isometric:
                pixelX -= height * tileWidthHalf
                let tileY = pixelY / tileHeight
                let tileX = pixelX / tileWidth
                return CGPoint(x: floor(tileY + tileX), y: floor(tileY - tileX))
                
            case .hexagonal:
                
                // initial offset
                if (tilemap.staggerX == true) {
                    pixelX -= (tilemap.staggerEven) ? tilemap.tileWidth : tilemap.sideOffsetX
                } else {
                    pixelY -= (tilemap.staggerEven) ? tilemap.tileHeight : tilemap.sideOffsetY
                }
                
                // reference coordinates on a grid aligned tile
                var referencePoint = CGPoint(x: floor(pixelX / (tilemap.columnWidth * 2)),
                                             y: floor(pixelY / (tilemap.rowHeight * 2)))
                
                
                // relative distance between hex centers
                let relative = CGVector(dx: pixelX - referencePoint.x * (tilemap.columnWidth * 2),
                                        dy: pixelY - referencePoint.y * (tilemap.rowHeight * 2))
                
                // reference point adjustment
                let indexOffset: CGFloat = (tilemap.staggerEven == true) ? 1 : 0
                if (tilemap.staggerX == true) {
                    referencePoint.x *= 2
                    referencePoint.x += indexOffset
                    
                } else {
                    referencePoint.y *= 2
                    referencePoint.y += indexOffset
                }
                
                // get nearest hexagon
                var centers: [CGVector]
                
                // flat-topped
                if (tilemap.staggerX == true) {
                    let left: Int = Int(tilemap.sideLengthX / 2)
                    let centerX: Int = left + Int(tilemap.columnWidth)
                    let centerY: Int = Int(tilemap.tileHeight / 2)
                    centers = [CGVector(dx: left, dy: centerY),
                               CGVector(dx: centerX, dy: centerY - Int(tilemap.rowHeight)),
                               CGVector(dx: centerX, dy: centerY + Int(tilemap.rowHeight)),
                               CGVector(dx: centerX + Int(tilemap.columnWidth), dy: centerY)
                    ]
                    
                    // pointy
                } else {
                    let top: Int = Int(tilemap.sideLengthY / 2)
                    let centerX: Int = Int(tilemap.tileWidth / 2)
                    let centerY: Int = top + Int(tilemap.rowHeight)
                    
                    centers = [CGVector(dx: centerX, dy: top),
                               CGVector(dx: centerX - Int(tilemap.columnWidth), dy: centerY),
                               CGVector(dx: centerX + Int(tilemap.columnWidth), dy: centerY),
                               CGVector(dx: centerX, dy: centerY + Int(tilemap.rowHeight))
                    ]
                }
                
                var nearest: Int = 0
                var minDist = CGFloat.greatestFiniteMagnitude
                
                // get the nearest center
                for i in 0..<4 {
                    let center = centers[i]
                    let dc = (center - relative).lengthSquared()
                    if (dc < minDist) {
                        minDist = dc
                        nearest = i
                    }
                }
                
                // flat
                let offsetsStaggerX: [CGPoint] = [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: 1, y: -1),
                    CGPoint(x: 1, y: 0),
                    CGPoint(x: 2, y: 0)
                ]
                
                //pointy
                let offsetsStaggerY: [CGPoint] = [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: -1, y: 1),
                    CGPoint(x: 0, y: 1),
                    CGPoint(x: 0, y: 2)
                ]
                
                let offsets: [CGPoint] = (tilemap.staggerX == true) ? offsetsStaggerX : offsetsStaggerY
                return referencePoint + offsets[nearest]
                
                
            case .staggered:
                
                if tilemap.staggerX {
                    pixelX -= tilemap.staggerEven ? tilemap.sideOffsetX : 0
                } else {
                    pixelY -= tilemap.staggerEven ? tilemap.sideOffsetY : 0
                }
                
                // get a point in the reference grid
                var referencePoint = CGPoint(x: floor(pixelX / tileWidth), y: floor(pixelY / tileHeight))
                
                // relative x & y position to grid aligned tile
                var relativePoint = CGPoint(x: pixelX - referencePoint.x * tileWidth,
                                            y: pixelY - referencePoint.y * tileHeight)
                
                
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
                
                let delta: CGFloat = relativePoint.x * (tileHeight / tileWidth)
                
                // check if the screen position is in the corners
                if (tilemap.sideOffsetY - delta > relativePoint.y) {
                    return tilemap.topLeft(referencePoint.x, referencePoint.y)
                }
                
                if (-tilemap.sideOffsetY + delta > relativePoint.y) {
                    return tilemap.topRight(referencePoint.x, referencePoint.y)
                }
                
                if (tilemap.sideOffsetY + delta < relativePoint.y) {
                    return tilemap.bottomLeft(referencePoint.x, referencePoint.y)
                }
                
                if (tilemap.sideOffsetY * 3 - delta < relativePoint.y) {
                    return tilemap.bottomRight(referencePoint.x, referencePoint.y)
                }
                
                return referencePoint
        }
    }
    
    /**
     Converts a tile coordinate into a screen point. Note that this function
     returns a point that needs to be converted to negative-y space.
     
     - parameter coord: `CGPoint` tile coordinate.
     - returns: `CGPoint` point in screen space.
     */
    internal func tileToScreenCoords(_ coord: CGPoint) -> CGPoint {
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
     Converts a screen (isometric) coordinate to a coordinate in map space. Note that this function
     returns a point that needs to be converted to negative-y space.
     
     - parameter point: `CGPoint` point in screen space.
     - returns: `CGPoint` point in map space.
     */
    internal func screenToPixelCoords(_ point: CGPoint) -> CGPoint {
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
     Converts a coordinate in map space to screen space.
     
     See: http://stackoverflow.com/questions/24747420/tiled-map-editor-size-of-isometric-tile-side
     
     - parameter point: `CGPoint` point in map space.
     - returns: `CGPoint` point in screen space.
     */
    internal func pixelToScreenCoords(_ point: CGPoint) -> CGPoint {
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
    
    // MARK: - Adding & Removing Nodes
    
    /**
     Add an `SKNode` child node at the given x/y coordinates. By default, the zPositon
     will be higher than all of the other nodes in the layer.
     
     - parameter node:      `SKNode` object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter offset:    `CGPoint` offset amount.
     - parameter zpos: `CGFloat?` optional z-position.
     */
    public func addChild(_ node: SKNode, x: Int = 0, y: Int = 0, offset: CGPoint = CGPoint.zero, zpos: CGFloat? = nil) {
        let coord = CGPoint(x: CGFloat(x), y: CGFloat(y))
        addChild(node, coord: coord, offset: offset, zpos: zpos)
    }
    
    /**
     Add an `SKNode` child node at the given coordinates. By default, the zPositon
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
        node.zPosition = (zpos != nil) ? zpos! : zPosition + tilemap.zDeltaForLayers
    }
    
    /**
     Prune tiles out of the camera bounds.
     
     - parameter outsideOf: `CGRect` camera bounds.
     */
    internal func pruneTiles(_ outsideOf: CGRect? = nil, zoom: CGFloat = 1, buffer: CGFloat = 2) {
        /* override in subclass */
    }
    
    // MARK: - Callbacks
    
    /**
     Called when the layer is finished rendering.
     
     - parameter duration: `TimeInterval` fade-in duration.
     */
    public func didFinishRendering(duration: TimeInterval = 0) {
        log("  - layer rendered: \"\(layerName)\"", level: .debug)
        self.parseProperties(completion: nil)
        // setup physics for the layer boundary
        if hasKey("isDynamic") && boolForKey("isDynamic") == true || hasKey("isCollider") && boolForKey("isCollider") == true {
            setupLayerPhysicsBoundary()
        }
        isRendered = true
    }
    
    // MARK: - Dynamics
    
    /**
     Set up physics boundary for the entire layer.
     
     - parameter isDynamic: `Bool` layer is dynamic.
     */
    public func setupLayerPhysicsBoundary(isDynamic: Bool = false) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.bounds)
        physicsBody?.isDynamic = isDynamic
    }
    
    /**
     Set up physics for child objects.
     */
    public func setupPhysics() {
        // override in subclass
    }
    
    override public var hash: Int {
        return self.uuid.hashValue
    }
    
    // MARK: - Shaders
    
    /**
     Set a shader effect for the layer.
     
     - parameter named:    `String` shader file name.
     - parameter uniforms: `[SKUniform]` array of shader uniforms.
     */
    public func setShader(named: String, uniforms: [SKUniform] = []) {
        let layerShader = SKShader(fileNamed: named)
        layerShader.uniforms = uniforms
        shouldEnableEffects = true
        self.shader = layerShader
    }
    
    // MARK: - Debugging
    
    /**
     Visualize the layer's boundary shape.
     */
    public func drawBounds() {
        guard let debugNode = debugNode else { return }
        debugNode.drawBounds()
    }
    
    public func debugLayer() {
        /* override in subclass */
        let comma = (propertiesString.isEmpty == false) ? ", " : ""
        self.log("Layer: \(name != nil ? "\"\(layerName)\"" : "null")\(comma)\(propertiesString)", level: .debug)
    }
    
    /// Toggle layer isolation on/off.
    public func isolateLayer(duration: TimeInterval = 0) {
        let hideLayers = (self.isolated == false)
        
        let layersToIgnore = self.parents
        let layersToProtect = self.childLayers
        
        tilemap.layers.filter { (layersToIgnore.contains($0) == false) && (layersToProtect.contains($0) == false)}.forEach { layer in
            
            if (duration == 0) {
                layer.isHidden = hideLayers
            } else {
                let fadeAction = (hideLayers == true) ? SKAction.fadeOut(withDuration: duration) : SKAction.fadeIn(withDuration: duration)
                layer.run(fadeAction, completion: {
                    layer.isHidden = hideLayers
                    layer.alpha = 1
                })
            }
        }
        
        self.isolated = !self.isolated
    }
    
    /** Render the layer to a texture.
     
     - Returns: `SKTexture?` rendered texture.
     */
    internal func render() -> SKTexture? {
        let renderSize = tilemap.sizeInPoints * TiledGlobals.default.contentScale
        let cropRect = CGRect(x: 0, y: -renderSize.height,
                              width: renderSize.width,
                              height: renderSize.height)
        
        if let rendered = SKView().texture(from: self, crop: cropRect) {
            rendered.filteringMode = .nearest
            return rendered
        }
        return nil
    }
    
    // MARK: - Updating
    
    /**
     Initialize SpriteKit animation actions for the layer.
     */
    public func runAnimationAsActions() {
        // override in subclass
    }
    
    /**
     Remove SpriteKit animations in the layer.
     
     - parameter restore: `Bool` restore tile/obejct texture.
     */
    public func removeAnimationActions(restore: Bool = false) {
        self.log("removing SpriteKit actions for layer \"\(self.layerName)\"...", level: .debug)
    }
    
    /**
     Update the layer before each frame is rendered.
     
     - parameter currentTime: `TimeInterval` update interval.
     */
    public func update(_ currentTime: TimeInterval) {
        guard (isRendered == true) else { return }
        // clamp the position of the map & parent nodes
        // clampNodePosition(node: self, scale: SKTiledGlobals.default.contentScale)
    }
}
