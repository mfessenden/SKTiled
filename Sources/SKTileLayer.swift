//
//  SKTileLayer.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
#if os(iOS) || os(tvOS)
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
 - group:   Group layer.
 */
public enum SKTiledLayerType: Int {
    case none     = -1
    case tile
    case object
    case image
    case group
}


internal enum SKObjectGroupColors: String {
    case pink     = "#c8a0a4"
    case blue     = "#6fc0f3"
    case green    = "#70d583"
    case orange   = "#f3dc8d"
}


/// index, zpos, size w, size h, tile size w, tile size h, offset x, offset y, anchor x, anchor y, tile count, object count
public typealias renderInfo = (idx: Int, path: String, zpos: Double, sw: Int, sh: Int, tsw: Int, tsh: Int, offx: Int, offy: Int, ancx: Int, ancy: Int, tc: Int, obj: Int, vis: Int)


/**
 The `TiledLayerObject` is the base class for all **SKTiled** layer types.  This class
 doesn't define any object or child types, but manages several important aspects of your scene:
    
 - validating coordinates
 - positioning and alignment
 - coordinate transformations
 
 Layer properties are accessed via properties shared with the parent tilemap:
 
 ```
  layer.size            // size (in tiles)
  layer.tileSize        // tile size (in pixels)
 ```
 Coordinate transformation functions return coordinates in the current tilemap projection:

 ```
  node.position = tileLayer.pointForCoordinate(2, 1)
 ```
 */
open class TiledLayerObject: SKNode, SKTiledObject {
    
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
    
    
    internal var layerType: SKTiledLayerType = .none
    open var tilemap: SKTilemap
    
    /// Unique object id.
    open var uuid: String = UUID().uuidString
    /// Object type
    open var type: String!
    
    /// Layer index. Matches the index of the layer in the source TMX file.
    open var index: Int = 0
    
    /// Custom layer properties.
    open var properties: [String: String] = [:]
    open var ignoreProperties: Bool = false
    
    /// Layer color.
    open var color: SKColor = SKColor.gray
    /// Grid visualization color.
    open var gridColor: SKColor = SKColor.black
    /// Bounding box color.
    open var frameColor: SKColor = SKColor.black
    /// Layer highlight color (for highlighting tiles)
    open var highlightColor: SKColor = SKColor.white
    /// Layer highlight duration
    open var highlightDuration: TimeInterval = 0
    
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
    
    internal var gidErrors: [UInt32] = []
    
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
    open var gridOpacity: CGFloat = 0.20
    internal var debugNode: TiledDebugDrawNode!
    
    open var debugDrawOptions: DebugDrawOptions = [] {
        didSet {
            guard oldValue != debugDrawOptions else { return }
            debugNode?.update()
        }
    }
    
    internal var isRendered: Bool = false
    open var antialiased: Bool = false
    open var colorBlendFactor: CGFloat = 1.0
    open var renderQuality: CGFloat = 8
    
    /// Optional background color.
    open var backgroundColor: SKColor? = nil {
        didSet {
            self.background.color = (backgroundColor != nil) ? backgroundColor! : SKColor.clear
            self.background.colorBlendFactor = (backgroundColor != nil) ? 1.0 : 0
        }
    }
    
    /**
     Layer background sprite.
     */
    lazy open var background: SKSpriteNode = {
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
    
    /// Returns the position of layer origin point (used to place tiles).
    open var origin: CGPoint {
        switch orientation {
        case .orthogonal:
            return CGPoint.zero
        case .isometric:
            return CGPoint(x: height * tileWidthHalf, y: tileHeightHalf)
        // TODO: check for errors with objects
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
    open var boundingRect: CGRect {
        return CGRect(x: 0, y: 0, width: sizeInPoints.width, height: -sizeInPoints.height)
    }
    
    /// Layer transparency.
    open var opacity: CGFloat {
        get {
            return self.alpha
        }
        set {
            self.alpha = newValue
        }
    }
    
    /// Layer visibility.
    open var visible: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }
    
    /// Returns the render statisics
    open var renderStatistics: renderInfo {
        return (index, path, Double(zPosition), Int(tilemap.size.width), Int(tilemap.size.height), Int(tileSize.width), Int(tileSize.height),  Int(offset.x), Int(offset.y), Int(anchorPoint.x), Int(anchorPoint.y), 0, 0, (isHidden == true) ? 0 : 1)
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
        self.ignoreProperties = tilemap.ignoreProperties
        super.init()
        self.debugNode = TiledDebugDrawNode(tileLayer: self)
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
            print("setting layer opacity: \(layerOpacity)")
            self.opacity = CGFloat(Double(layerOpacity)!)
        }
        
        // set the layer's antialiasing based on tile size
        self.antialiased = self.tilemap.tileSize.width > 16 ? true : false
        addChild(debugNode)
        
        // TODO: Cleanup
        //self.frameShape.isHidden = true
        //addChild(frameShape)
    }

    /**
     Create a new layer within the parent tilemap node.

     - parameter layerName:  `String` layer name.
     - parameter tilemap:    `SKTilemap` parent tilemap node.
     - returns: `TiledLayerObject` tiled layer object.
     */
    public init(layerName: String, tilemap: SKTilemap){
        self.tilemap = tilemap
        self.ignoreProperties = tilemap.ignoreProperties
        super.init()
        self.debugNode = TiledDebugDrawNode(tileLayer: self)
        self.name = layerName
        
        // set the layer's antialiasing based on tile size
        self.antialiased = self.tilemap.tileSize.width > 16 ? true : false
        addChild(debugNode)
        
        // TODO: Cleanup
        //self.frameShape.isHidden = true
        //addChild(frameShape)
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
    
    // MARK: - Children
    open var layers: [TiledLayerObject] {
        return [self]
    }
    
    // MARK: - Event Handling
    
    #if os(iOS) || os(tvOS)
    /**
     Returns a converted touch location.
     
     - parameter touch: `UITouch` touch location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    open func touchLocation(_ touch: UITouch) -> CGPoint {
        return convertPoint(touch.location(in: self))
    }
    
    /**
     Returns the tile coordinate for a touch location.
     
     - parameter touch: `UITouch` touch location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    open func coordinateAtTouchLocation(_ touch: UITouch) -> CGPoint {
        return screenToTileCoords(touchLocation(touch))
    }
    #endif
    
    #if os(OSX)
    /**
     Returns a mouse event location.
     
     - parameter event: `NSEvent` mouse event location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    public func mouseLocation(event: NSEvent) -> CGPoint {
        return convertPoint(event.location(in: self))
    }
    
    /**
     Returns the tile coordinate for a touch location.
     
     - parameter event: `NSEvent` mouse event location.
     - returns: `CGPoint` converted point in layer coordinate system.
     */
    open func coordinateAtMouseEvent(event: NSEvent) -> CGPoint {
        return screenToTileCoords(mouseLocation(event: event))
    }
    #endif
    
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
    open func isValid(coord: CGPoint) -> Bool {
        return isValid(Int(coord.x), Int(coord.y))
    }
        
    /**
     Convert a point into the tile map's coordinate space.
     
     - parameter point: `CGPoint` input point.
     - returns: `CGPoint` point with y-value inverted.
     */
    open func convertPoint(_ point: CGPoint) -> CGPoint {
        return point.invertedY
    }
    
    /**
     Returns a point for a given coordinate in the layer.
     
     - parameter coord: `CGPoint` tile coordinate.
     - returns: `CGPoint` point in layer (spritekit space).
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
        
        return floor(point: screenPoint.invertedY)
    }
    
    /**
     Returns a tile coordinate for a given point in the layer.
     
     - parameter point: `CGPoint` point in layer (spritekit space).
     - returns: `CGPoint` tile coordinate.
     */
    open func coordinateForPoint(_ point: CGPoint) -> CGPoint {
        return screenToTileCoords(point.invertedY)
        //return floor(point: coordinate)
    }
        
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
            
            // flat
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
                CGPoint(x: 2, y: 0),
            ]
            
            //pointy
            let offsetsStaggerY: [CGPoint] = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: -1, y: 1),
                CGPoint(x: 0, y: 1),
                CGPoint(x: 0, y: 2),
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
     Converts a coordinate in map space to screen space. See:
     http://stackoverflow.com/questions/24747420/tiled-map-editor-size-of-isometric-tile-side
     
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
     Add a child node at the given x/y coordinates. By default, the zPositon
     will be higher than all of the other nodes in the layer.
     
     - parameter node:      `SKNode` object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter offset:    `CGPoint` offset amount.
     - parameter zpos: `CGFloat?` optional z-position.
     */
    public func addChild(_ node: SKNode, x: Int=0, y: Int=0, offset: CGPoint = CGPoint.zero, zpos: CGFloat? = nil) {
        let coord = CGPoint(x: CGFloat(x), y: CGFloat(y))
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
     Visualize the layer's boundary shape.
     */
    public func drawBounds() {
        guard let debugNode = debugNode else  { return }
        debugNode.drawBounds()
    }
    
    /**
     Prune tiles out of the camera bounds.
     
     - parameter outsideOf: `CGRect` camera bounds.
     */
    fileprivate func pruneTiles(_ outsideOf: CGRect) {
        /* override in subclass */
    }
    
    /**
     Flatten (render) the layer.
     */
    fileprivate func flattenLayer() {
        /* override in subclass */
    }
    
    // MARK: - Callbacks
    /**
     Called when the layer is finished rendering.
     
     - parameter duration: `TimeInterval` fade-in duration.
     */
    open func didFinishRendering(duration: TimeInterval=0) {
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: duration)
        
        run(fadeIn, completion: {
            self.isRendered = true
            self.parseProperties(completion: nil)
        })
        
        //self.parseProperties(completion: nil)
        // setup physics for the layer boundary
        if hasKey("isDynamic") && boolForKey("isDynamic") == true || hasKey("isCollider") && boolForKey("isCollider") == true {
            setupLayerPhysicsBoundary()
        }
    }
    
    // MARK: - Dynamics
    
    /**
     Set up physics boundary for the entire layer.
     
     - parameter isDynamic: `Bool` layer is dynamic.
     */
    open func setupLayerPhysicsBoundary(isDynamic: Bool=false){
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.boundingRect)
        physicsBody?.isDynamic = isDynamic
    }
    
    /**
     Set up physics for child objects.
     */
    open func setupPhysics(){
        // override in subclass
    }
    
    
    override open var hashValue: Int {
        return self.uuid.hashValue
    }
    
    // MARK: - Debugging
    open func debugLayer() {
        /* override in subclass */
        let comma = propertiesString.characters.count > 0 ? ", " : ""
        print("Layer: \(name != nil ? "\"\(name!)\"" : "null")\(comma)\(propertiesString)")
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
    open var render: Bool = false                       // render tile layer as a single image
    open var graph: GKGridGraph<GKGridGraphNode>?       // pathfinding graph
    
    /// Tuple of layer render statistics.
    override open var renderStatistics: renderInfo {
        var current = super.renderStatistics
        current.tc = tileCount
        return current
    }
    
    override open var debugDrawOptions: DebugDrawOptions {
        didSet {
            guard oldValue != debugDrawOptions else { return }
            debugNode?.update()
            
            let doShowTileBounds = debugDrawOptions.contains(.drawTileBounds)
            tiles.forEach { $0?.showBounds = doShowTileBounds }
        }
    }
        
    /// Tile highlight duration
    override open var highlightDuration: TimeInterval {
        didSet{
            _ = tiles.flatMap({ $0?.highlightDuration = highlightDuration})
        }
    }
    
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
    
    
    deinit {
        removeAllActions()
        removeAllChildren()
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
    open func tileAt(coord: CGPoint) -> SKTile? {
        return tileAt(Int(coord.x), Int(coord.y))
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
        return tiles.flatMap { $0 }.filter { $0.tileData.type == type }
    }
    
    /**
     Returns tiles matching the given global id.
     
     - parameter globalID: `Int` tile global id.
     - returns: `[SKTile]` array of tiles.
    */
    open func getTiles(globalID: Int) -> [SKTile] {
        return tiles.flatMap { $0 }.filter { $0.tileData.id == globalID }
    }
    
    /**
     Returns tiles with a property of the given type.
     
     - parameter type: `String` type.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTilesWithProperty(_ named: String, _ value: Any) -> [SKTile] {
        var result: [SKTile] = []
        for tile in tiles where tile != nil {
            if let pvalue = tile!.tileData.properties[named] , pvalue == value as! String {
                result.append(tile!)
            }
        }
        return result
    }

    /**
     Returns all tiles with animation.
     
     - returns: `[SKTile]` array of animated tiles.
     */
    open func animatedTiles() -> [SKTile] {
        return validTiles().filter({ $0.tileData.isAnimated == true })
    }
    
    /**
     Return tile data from a global id.
     
     - parameter globalID: `Int` global tile id.
     - returns: `SKTilesetData?` tile data (for valid id).
     */
    open func getTileData(globalID gid: Int) -> SKTilesetData? {
        return tilemap.getTileData(globalID: gid)
    }
    
    /**
     Returns tiles with a property of the given type.
                
     - parameter type: `String` type.
     - returns: `[SKTile]` array of tiles.
     */
    open func getTileData(withProperty named: String) -> [SKTilesetData] {
        var result: [SKTilesetData] = []
        for tile in tiles where tile != nil {
            if tile!.tileData.hasKey(named) && !result.contains(tile!.tileData) {
                result.append(tile!.tileData)
            }
        }
        return result
    }
    
    // MARK: - Layer Data
    
    /**
     Add tile data array to the layer and render it.
     
     - parameter data: `[Int]` tile data.
     - returns: `Bool` data was successfully added.
     */
    open func setLayerData(_ data: [UInt32], debug: Bool=false) -> Bool {
        if !(data.count == size.count) {
            print("ERROR: invalid data size for layer \"\(self.layerName)\": \(data.count), expected: \(size.count)")
            return false
        }
        
        var errorCount: Int = 0
        for index in data.indices {
            let gid = data[index]
            
            // skip empty tiles
            if (gid == 0) { continue }
            
            let x: Int = index % Int(self.size.width)
            let y: Int = index / Int(self.size.width)
            
            let coord = CGPoint(x: CGFloat(x), y: CGFloat(y))
            let tile = self.buildTileAt(coord: coord, id: gid)
            
            if (tile == nil) {
                errorCount += 1
            }
        }
            
        if (errorCount != 0){
            print("Warning: layer \"\(self.name!)\": \(errorCount) \(errorCount > 1 ? "errors" : "error") loading data.")
        }
        return errorCount == 0
    }
    
    /**
     Build an empty tile at the given coordinates. Returns an existing tile if one already exists, 
     or nil if the coordinate is invalid.
     
     - parameter coord:     `CGPoint` tile coordinate
     - parameter gid:       `Int?` tile id.
     - parameter tileType:  `String` optional tile class name.
     - returns: `SKTile?` tile.
     */
    open func addTileAt(coord: CGPoint, gid: Int? = nil, tileType: String? = nil) -> SKTile? {
        guard isValid(coord: coord) else { return nil }
        
        // remove the current tile
        let _ = removeTileAt(coord: coord)
        
        let tileData: SKTilesetData? = (gid != nil) ? getTileData(globalID: gid!) : nil
        
        let Tile = tilemap.delegate != nil ? tilemap.delegate!.objectForTile(className: tileType) : SKTile.self
        let tile = Tile.init(tileSize: tileSize)
        
        if let tileData = tileData {
            tile.tileData = tileData
            tile.texture = tileData.texture
            tile.tileSize = (tileData.tileset != nil) ? tileData.tileset!.tileSize : self.tileSize
        }
        
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
    
    /**
     Build an empty tile at the given coordinates with a custom texture. Returns nil is the coordinate
     is invalid.
     
     - parameter coord:   `CGPoint` tile coordinate.
     - parameter texture: `SKTexture?` optional tile texture.
     - returns: `SKTile?` tile.
     */
    open func addTileAt(coord: CGPoint, texture: SKTexture? = nil, tileType: String? = nil) -> SKTile? {
        guard isValid(coord: coord) else { return nil }
        
        let Tile = tilemap.delegate != nil ? tilemap.delegate!.objectForTile(className: tileType) : SKTile.self
        let tile = Tile.init(tileSize: tileSize)
        tile.texture = texture
        
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
    
    /**
     Build an empty tile at the given coordinates. Returns an existing tile if one already exists,
     or nil if the coordinate is invalid.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - parameter gid: `Int?` tile id.
     - returns: `SKTile?` tile.
     */
    open func addTileAt(_ x: Int, _ y: Int, gid: Int? = nil) -> SKTile? {
        let coord = CGPoint(x: CGFloat(x), y: CGFloat(y))
        return addTileAt(coord: coord, gid: gid)
    }
    
    /**
     Build an empty tile at the given coordinates with a custom texture. Returns nil is the coordinate
     is invalid.
     
     - parameter x:       `Int` x-coordinate
     - parameter y:       `Int` y-coordinate
     - parameter texture: `SKTexture?` optional tile texture.
     - returns: `SKTile?` tile.
     */
    open func addTileAt(_ x: Int, _ y: Int, texture: SKTexture? = nil) -> SKTile? {
        let coord = CGPoint(x: CGFloat(x), y: CGFloat(y))
        return addTileAt(coord: coord, texture: texture)
    }
    
    /**
     Remove the tile at a given x/y coordinates.
     
     - parameter x:   `Int` x-coordinate
     - parameter y:   `Int` y-coordinate
     - returns: `SKTile?` removed tile.
     */
    open func removeTileAt(_ x: Int, _ y: Int) -> SKTile? {
        let coord = CGPoint(x: CGFloat(x), y: CGFloat(y))
        return removeTileAt(coord: coord)
    }
    
    /**
     Remove the tile at a given coordinate.
     
     - parameter coord:   `CGPoint` tile coordinate.
     - returns: `SKTile?` removed tile.
     */
    open func removeTileAt(coord: CGPoint) -> SKTile? {
        let current = tileAt(coord: coord)
        if let current = current {
            current.removeFromParent()
            self.tiles[Int(coord.x), Int(coord.y)] = nil
        }
        return current
    }
    
    /**
     Build a tile at the given coordinate with the given id. Returns nil if the id cannot be resolved.
     
     - parameter coord:    `CGPoint` x&y coordinate.
     - parameter id:       `UInt32` tile id.
     - parameter tileType: `String?` optional tile type string.
     - returns: `SKTile?`  tile object.
     */
    fileprivate func buildTileAt(coord: CGPoint, id: UInt32, tileType: String? = nil) -> SKTile? {
        
        // get tile attributes from the current id
        let tileAttrs = flippedTileFlags(id: id)
    
        if let tileData = tilemap.getTileData(globalID: Int(tileAttrs.gid)) {
            
            // set the tile data flip flags
            tileData.flipHoriz = tileAttrs.hflip
            tileData.flipVert  = tileAttrs.vflip
            tileData.flipDiag  = tileAttrs.dflip
            
            // get tile object from delegate
            let Tile = (tilemap.delegate != nil) ? tilemap.delegate!.objectForTile(className: tileType) : SKTile.self

            if let tile = Tile.init(data: tileData) {
                
                // set the tile overlap amount
                tile.setTileOverlap(tilemap.tileOverlap)
                tile.highlightColor = highlightColor
                
                // set the layer property
                tile.layer = self
                tile.highlightDuration = highlightDuration
                
                // get the position in the layer (plus tileset offset)
                let tilePosition = pointForCoordinate(coord: coord, offsetX: tileData.tileset.tileOffset.x, offsetY: tileData.tileset.tileOffset.y)
                
                // add to the layer
                addChild(tile)
                
                // set orientation & position
                tile.orientTile()
                tile.position = tilePosition
                
                // add to the tiles array
                self.tiles[Int(coord.x), Int(coord.y)] = tile

                // set the tile zPosition to the current y-coordinate
                tile.zPosition = coord.y

                // run animation for tiles with multiple frames
                tile.runAnimation()

                if tile.texture == nil {
                    print("Warning: cannot find a texture for id: \(tileAttrs.gid)")
                }
                
                return tile
                
            } else {
                print("ERROR: invalid tileset data (id: \(id))")
            }
        } else {
            // check for bad gid calls
            if !gidErrors.contains(tileAttrs.gid) {
                gidErrors.append(tileAttrs.gid)
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
        for tile in tiles where tile != nil {
            tile!.setTileOverlap(overlap)
        }
    }
    // MARK: - Callbacks
    /**
     Called when the layer is finished rendering.
     
     - parameter duration: `TimeInterval` fade-in duration.
     */
    override open func didFinishRendering(duration: TimeInterval=0) {
        super.didFinishRendering(duration: duration)
    }
    
    // MARK: - Shaders
    
    /**
     Set a shader for the tile layer.
     
     - parameter named:    `String` shader file name.
     - parameter uniforms: `[SKUniform]` array of shader uniforms.
     */
    open func setShader(named: String, uniforms: [SKUniform]=[]) {
        let shader = SKShader(fileNamed: named)
        shader.uniforms = uniforms
        for tile in tiles.flatMap({$0}) {
            tile.shader = shader
        }
    }
    
    // MARK: - Debugging
    /**
     Visualize the layer's boundary shape.
     */
    override open func drawBounds() {
        tiles.flatMap({ $0 }).forEach { $0.drawBounds() }
        super.drawBounds()
    }
    
    override open func debugLayer() {
        super.debugLayer()
        for tile in validTiles() {
            print(tile.debugDescription)
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
            objects.filter { $0.isRenderableType == false }.forEach { $0.visible = showObjects }
        }
    }
    
    /**
     Returns the number of objects in this layer.
     */
    open var count: Int { return objects.count }
    
    
    /// Controls antialiasing for each object
    override open var antialiased: Bool {
        didSet {
            objects.forEach { $0.isAntialiased = antialiased }
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
    
    /**
     Returns a tuple of render stats used for debugging.
     */
    override open var renderStatistics: renderInfo {
        var current = super.renderStatistics
        current.obj = count
        return current
    }
    
    /**
     Set the render quality of every object.
     */
    override open var renderQuality: CGFloat {
        didSet {
            guard renderQuality != oldValue else { return }
            for object in objects {
                if (object.isRenderableType == true) {
                    object.renderQuality = renderQuality
                }
            }
        }
    }
    
    override open var debugDrawOptions: DebugDrawOptions {
        didSet {
            guard oldValue != debugDrawOptions else { return }
            debugNode?.update()
            
            let doShowObjects = debugDrawOptions.contains(.drawObjectBounds)
            objects.forEach { $0.showBounds = doShowObjects }
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
        self.color = tilemap.objectColor
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
        self.color = tilemap.objectColor
        
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
        if objects.contains( where: { $0.hashValue == object.hashValue } ) {
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
        object.ignoreProperties = ignoreProperties
        addChild(object)
        
        // hide the object if the tilemap `showObjects` property is set to false
        object.visible = (object.isRenderableType == true) ? true : tilemap.showObjects
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
        objects.forEach { $0.drawObject() }
    }
    
    /**
     Set the color for all objects.
     
     - parameter color: `SKColor` object color.
     - parameter force: `Bool` force color on objects that have an override.
     */
    override open func setColor(color: SKColor) {
        super.setColor(color: color)
        objects.forEach { object in
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
        objects.forEach { object in
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
     Return objects with matching text.
     
     - parameter withText: `String` text string to match.
     - returns: `[SKTileObject]` array of matching objects.
     */
    open func getObjects(withText text: String) -> [SKTileObject] {
        return objects.filter { $0.text == text }
    }
    
    /**
     Return objects with the given name.
     
     - parameter named: `String` Object name.
     - returns: `[SKTileObject]` array of matching objects.
     */
    open func getObjects(named: String) -> [SKTileObject] {
        return objects.filter { $0.name == named }
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
    
    // MARK: - Tile Objects
    
    /**
     Return objects with a tile id.
     
     - returns: `[SKTileObject]` objects with a tile gid.
     */
    open func tileObjects() -> [SKTileObject] {
        return objects.filter { $0.gid != nil }
    }
    
    /**
     Returns an `SKTileObject` object from the objects set.
     
     - parameter object:    `SKTileObject` object.
     - returns: `SKTileObject?` removed object.
     */
    open func tileObjects(globalID: Int) -> [SKTileObject] {
        return objects.filter { $0.gid == globalID }
    }
    
    // MARK: - Text Objects
    
    /**
     Return text objects.
     
     - returns: `[SKTileObject]` text objects.
     */
    open func textObjects() -> [SKTileObject] {
        return objects.filter { $0.textAttributes != nil }
    }
    
    // MARK: - Callbacks
    
    /**
     Called when the layer is finished rendering.
     
     - parameter duration: `TimeInterval` fade-in duration.
     */
    override open func didFinishRendering(duration: TimeInterval=0) {
        super.didFinishRendering(duration: duration)
                
        // setup dynamics for objects.
        for object in objects {
            if object.hasKey("isDynamic") || object.hasKey("isCollider") {
                object.setupPhysics()
                // override object visibility
                object.visible = true
            }
        }
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


/**
 The `BackgroundLayer` object represents the default background for a tilemap.
 
 Set the layer image with:
 
 ```swift
 imageLayer.setLayerImage("clouds-background")
 ```
 */
open class BackgroundLayer: TiledLayerObject {
    
    private var sprite: SKSpriteNode!
    private var _debugColor: SKColor? = nil
    
    override open var color: SKColor {
        didSet {
            guard let sprite = sprite else { return }
            sprite.color = (_debugColor == nil) ? color : _debugColor!
        }
    }
    
    override open var colorBlendFactor: CGFloat {
        didSet {
            guard let sprite = sprite else { return }
            sprite.colorBlendFactor = colorBlendFactor
        }
    }
    
    // MARK: - Init
    /**
     Initialize with the parent `SKTilemap` node.
     
     - parameter tilemap:   `SKTilemap` parent map.
     */
    public init(tilemap: SKTilemap) {
        super.init(layerName: "DEFAULT", tilemap: tilemap)
        layerType = .none
        index = -1
        sprite = SKSpriteNode(texture: nil, color: tilemap.backgroundColor ?? SKColor.clear, size: tilemap.sizeInPoints)
        addChild(self.sprite!)
        
        // position sprite
        sprite!.position.x += tilemap.sizeInPoints.width / 2
        sprite!.position.y -= tilemap.sizeInPoints.height / 2
    }
    
    /**
     Set the color of the background node.
     
     - parameter tilemap:   `SKTilemap` parent map.
     */
    public func setBackground(color: SKColor) {
        self.sprite?.color = color
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/**
 The `SKGroupLayer` object is a container for grouping other layers.
 
 Add layers to the group with:
 
 ```swift
 groupLayer.addLayer(playerLayer)
 ```
 
 Remove with:

 ```swift
 groupLayer.removeLayer(playerLayer)
 ```
 */
open class SKGroupLayer: TiledLayerObject {
    
    private var _layers: Set<TiledLayerObject> = []
    
    /// Returns the last index for all layers.
    open var lastIndex: Int {
        return layers.count > 0 ? layers.map { $0.index }.max()! : self.index
    }
    
    /// Returns the last (highest) z-position in the map.
    open var lastZPosition: CGFloat {
        return layers.count > 0 ? layers.map {$0.zPosition}.max()! : 0
    }
    
    /// Returns a flattened array of child layers.
    override open var layers: [TiledLayerObject] {
        var result: [TiledLayerObject] = [self]
        for layer in _layers.sorted(by: { $0.index > $1.index }) {
            result = result + layer.layers
        }
        return result
    }
    
    // MARK: - Init
    /**
     Initialize with a layer name, and parent `SKTilemap` node.
     
     - parameter layerName: `String` image layer name.
     - parameter tilemap:   `SKTilemap` parent map.
     */
    override public init(layerName: String, tilemap: SKTilemap) {
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .group
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
        self.layerType = .group
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
     Add a layer to the layers set. Automatically sets zPosition based on the tilemap zDeltaForLayers attributes.
     
     - parameter layer:  `TiledLayerObject` layer object.
     - parameter base:   `Bool` layer represents default layer.
     */
    open func addLayer(_ layer: TiledLayerObject) {
        let nextZPosition = (_layers.count > 0) ? (tilemap.zDeltaForLayers / 2) * CGFloat(_layers.count) : 0
        
        // set the layer index
        layer.index = lastIndex + 1
        
        _layers.insert(layer)
        addChild(layer)
        layer.zPosition = nextZPosition
        
        // override debugging colors
        layer.gridColor = gridColor
        layer.frameColor = frameColor
        layer.highlightColor = highlightColor
    }
    
    /**
     Remove a layer from the current layers set.
     
     - parameter layer: `TiledLayerObject` layer object.
     - returns: `TiledLayerObject?` removed layer.
     */
    open func removeLayer(_ layer: TiledLayerObject) -> TiledLayerObject? {
        return _layers.remove(layer)
    }
}


/**
 Two-dimensional array structure.
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



extension TiledLayerObject {
    
    // MARK: - Extensions
    
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
        let coord = CGPoint(x: CGFloat(x), y: CGFloat(y))
        let offset = CGPoint(x: dx, y: dy)
        addChild(node, coord: coord, offset: offset, zpos: zpos)
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
        return self.pointForCoordinate(coord: CGPoint(x: CGFloat(x), y: CGFloat(y)), offsetX: offsetX, offsetY: offsetY)
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
        return self.coordinateForPoint(CGPoint(x: CGFloat(x), y: CGFloat(y)))
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
    
    override open var description: String {
        let topLevel = self.parents.count == 1
        let indexString = (topLevel == true) ? ", index: \(index)" : ""
        return "<\(layerType.stringValue.capitalized) Layer: \"\(self.path)\"\(indexString)>"
    }
    
    override open var debugDescription: String { return description }
}


extension TiledLayerObject {
    /// Return a string representing the layer name.
    public var layerName: String {
        return self.name ?? "null"
    }
    
    /// Returns an array of parent layers.
    public var parents: [SKNode] {
        var current = self as SKNode
        var result: [SKNode] = [current]
        while current.parent != nil {
            if let _ = current.parent! as? TiledLayerObject {
                result.append(current.parent!)
            }
            current = current.parent!
        }
        return result
    }
    
    /// Returns an array of child layers.
    public var childLayers: [SKNode] {
        var result: [SKNode] = []
        enumerateChildNodes(withName: "*") {
            node, stop in
            
            if let node = node as? TiledLayerObject {
                result.append(node)
            }
        }
        return result
    }
    
    /// Returns an array of tile and objects.
    open func renderableObjects() -> [SKNode] {
        var result: [SKNode] = []
        enumerateChildNodes(withName: "//*") {
            node, stop in
            if (node as? SKTile != nil) || (node as? SKTileObject != nil) {
                result.append(node)
            }
        }
        return result
    }
    
    /// Indicates the layer is a top-level layer.
    public var isTopLevel: Bool { return self.parents.count <= 1 }

    /// Translate the parent hierarchy to a path string
    public var path: String {
        let allParents: [SKNode] = self.parents.reversed()
        if (allParents.count == 1) { return self.layerName }
        return allParents.reduce("") { result, node in
            let comma = allParents.index(of: node)! < allParents.count - 1 ? "/" : ""
            return result + "\(node.name ?? "nil")" + comma
        }
    }
    
    /// Returns the actual zPosition as rendered by the scene.
    internal var actualZPosition: CGFloat {
        return (isTopLevel == true) ? zPosition : parents.reduce(zPosition, { result, parent in
            return result + parent.zPosition
        })
    }
    
    /// Returns a string representing the current layer name & index.
    public var layerStatsDescription: [String] {
        let digitCount: Int = self.tilemap.lastIndex.digitCount + 1
        
        let parentNodes = self.parents
        let isGrouped: Bool = (parentNodes.count > 1)
        
        let indexString = (isGrouped == true) ? String(repeating: " ", count: digitCount) : "\(index).".zfill(length: digitCount, pattern: " ")
        let typeString = self.layerType.stringValue.capitalized.zfill(length: 6, pattern: " ", padLeft: false)
        let hasChildren: Bool = (childLayers.count > 0)
        
        let layerSymbol = (hasChildren == true) ? "▿" : "-"
        let filler = (isGrouped == true) ? String(repeating: "  ", count: parentNodes.count - 1) : ""
        
        let layerPathString = "\(filler)\(layerSymbol) \"\(layerName)\""
        let layerVisibilityString: String = (self.visible == true) ? "(x)" : "( )"
        
        // layer position string, filters out child layers with no offset
        var positionString = self.position.shortDescription
        if (self.position.x == 0) && (self.position.y == 0) {
            positionString = ""
        }
        
        return [indexString, typeString, layerVisibilityString, layerPathString, positionString,
                self.sizeInPoints.shortDescription, self.offset.shortDescription,
                self.anchorPoint.shortDescription, "\(Int(self.zPosition))", self.opacity.roundTo(2)]
    }
}


extension SKTiledLayerType {
    /// Returns a string representation of the layer type.
    internal var stringValue: String { return "\(self)".lowercased() }
}


public extension SKTileLayer {
    
    /**
     Returns only tiles that are valid (not empty).
     
     - returns: `[SKTile]` array of tiles.
     */
    public func validTiles() -> [SKTile] {
        return tiles.flatMap({ $0 })
    }
    
    /// Returns a count of valid tiles.
    public var tileCount: Int {
        return self.validTiles().count
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


extension Array2D: CustomReflectable {
    
    public var customMirror: Mirror {
        var rowdata: [String] = []
        for r in 0..<rows {
            var rowResult: String = ""
            
            for c in 0..<columns {
                let comma: String = (c < columns - 1) ? ", " : ""
                if let value = self[c, r] {
                    if let tile = value as? SKTile {
                        rowResult += "\(tile.tileData.id)\(comma)"
                    } else {
                        rowResult += "\(value)\(comma)"
                    }
                } else {
                    rowResult += "-\(comma)"
                }
            }
            rowdata.append(rowResult)
        }
        
        let children = DictionaryLiteral<String, Any>(dictionaryLiteral:
            ("columns", columns),
            ("rows", rowdata))
        return Mirror(self, children: children)
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


// MARK: - Deprecated

extension SKObjectGroup {
    /**
     Returns an object with the given name.
     
     - parameter named: `String` Object name.
     - returns: `SKTileObject?`
     */
    @available(*, deprecated, message: "use `getObjects(named:,recursive:)` instead")
    open func getObject(named: String) -> SKTileObject? {
        if let objIndex = objects.index( where: { $0.name == named } ) {
            let object = objects[objIndex]
            return object
        }
        return nil
    }
}
