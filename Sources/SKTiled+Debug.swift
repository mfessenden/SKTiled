//
//  SKTiled+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 6/19/17.
//  Copyright © 2017 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit


/**

 ## Overview ##

 A structure representing debug drawing options for **SKTiled** objects.

 ## Properties ##

 ```
 DebugDrawOptions.drawGrid               // visualize the objects's grid (tilemap & layers).
 DebugDrawOptions.drawBounds             // visualize the objects's bounds.
 DebugDrawOptions.drawGraph              // visualize a layer's navigation graph.
 DebugDrawOptions.drawObjectBounds       // draw an object's bounds.
 DebugDrawOptions.drawTileBounds         // draw a tile's bounds.
 ```

 */
public struct DebugDrawOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }

    /// Draw the layer's grid.
    static public let drawGrid              = DebugDrawOptions(rawValue: 1 << 0)
    /// Draw the layer's boundary shape.
    static public let drawBounds            = DebugDrawOptions(rawValue: 1 << 1)
    /// Draw the layer's navigation graph.
    static public let drawGraph             = DebugDrawOptions(rawValue: 1 << 2)
    /// Draw object bounds.
    static public let drawObjectBounds      = DebugDrawOptions(rawValue: 1 << 3)
    /// Draw tile bounds.
    static public let drawTileBounds        = DebugDrawOptions(rawValue: 1 << 4)
    static public let drawMouseOverObject   = DebugDrawOptions(rawValue: 1 << 5)
    static public let drawBackground        = DebugDrawOptions(rawValue: 1 << 6)
    static public let drawAnchor            = DebugDrawOptions(rawValue: 1 << 7)

    static public let all: DebugDrawOptions = [.drawGrid, .drawBounds, .drawGraph, .drawObjectBounds,
                                                    .drawObjectBounds, .drawMouseOverObject,
                                                    .drawBackground, .drawAnchor]
}


/// Sprite object for visualizaing grid & graph.
internal class SKTiledDebugDrawNode: SKNode {

    private var layer: SKTiledLayerObject                     // parent layer

    private var gridSprite: SKSpriteNode!
    private var graphSprite: SKSpriteNode!
    private var frameShape: SKShapeNode!

    private var gridTexture: SKTexture?                      // grid texture
    private var graphTexture: SKTexture?                     // GKGridGraph texture
    private var anchorKey: String = "ANCHOR"

    init(tileLayer: SKTiledLayerObject) {
        layer = tileLayer
        anchorKey = "ANCHOR_\(layer.uuid)"
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        gridTexture = nil
        graphTexture = nil
    }

    var anchorPoint: CGPoint {
        return convert(layer.position, from: layer)
    }

    /// Debug visualization options.
    var debugDrawOptions: DebugDrawOptions {
        return layer.debugDrawOptions
    }

    var showGrid: Bool {
        get {
            return (gridSprite != nil) ? (gridSprite!.isHidden == false) : false
        } set {
            DispatchQueue.main.async {
                self.drawGrid()
            }
        }
    }

    var showBounds: Bool {
        get {
            return (frameShape != nil) ? (frameShape!.isHidden == false) : false
        } set {
            drawBounds()
        }
    }

    var showGraph: Bool {
        get {
            return (graphSprite != nil) ? (graphSprite!.isHidden == false) : false
        } set {
            DispatchQueue.main.async {
                self.drawGraph()
            }
        }
    }

    /**
     Align with the parent layer.
     */
    func setup() {
        // set the anchorpoints to 0,0 to match the frame
        gridSprite = SKSpriteNode(texture: nil, color: .clear, size: layer.sizeInPoints)
        gridSprite.anchorPoint = .zero
        addChild(gridSprite!)

        graphSprite = SKSpriteNode(texture: nil, color: .clear, size: layer.sizeInPoints)
        graphSprite.anchorPoint = .zero
        addChild(graphSprite!)

        frameShape = SKShapeNode()
        addChild(frameShape!)

        //isHidden = true

        // z-position values
        graphSprite!.zPosition = layer.zPosition + layer.tilemap.zDeltaForLayers
        gridSprite!.zPosition = layer.zPosition + (layer.tilemap.zDeltaForLayers + 10)
        frameShape!.zPosition = layer.zPosition + (layer.tilemap.zDeltaForLayers + 20)
    }

    /**
     Update the node with the various options.
     */
    func draw() {
        if self.debugDrawOptions.contains(.drawGrid) {
            self.drawGrid()
        } else {
            self.gridSprite?.isHidden = true
        }

        if self.debugDrawOptions.contains(.drawBounds) {
            self.drawBounds()
        } else {
            self.frameShape?.isHidden = true
        }

        if self.debugDrawOptions.contains(.drawGraph) {
            self.drawGraph()
        } else {
            self.graphSprite?.isHidden = true
        }

        if self.debugDrawOptions.contains(.drawAnchor) {
            self.drawAnchor()
        } else {
            childNode(withName: anchorKey)?.removeFromParent()
        }
    }

    /**
     Reset all visualizations.
     */
    func reset() {
        gridSprite.texture = nil
        graphSprite.texture = nil
        childNode(withName: anchorKey)?.removeFromParent()
    }

    /**
     Visualize the layer's boundary shape.
     */
    func drawBounds() {

        let objectPath: CGPath!

        // grab dimensions from the layer
        let width = layer.width
        let height = layer.height
        let tileSize = layer.tileSize

        switch layer.orientation {
        case .orthogonal:
            objectPath = polygonPath(layer.bounds.points)

        case .isometric:
            let topPoint = CGPoint(x: 0, y: 0)
            let rightPoint = CGPoint(x: (width - 1) * tileSize.height + tileSize.height, y: 0)
            let bottomPoint = CGPoint(x: (width - 1) * tileSize.height + tileSize.height, y: (height - 1) * tileSize.height + tileSize.height)
            let leftPoint = CGPoint(x: 0, y: (height - 1) * tileSize.height + tileSize.height)

            let points: [CGPoint] = [
                // point order is top, right, bottom, left
                layer.pixelToScreenCoords(topPoint),
                layer.pixelToScreenCoords(rightPoint),
                layer.pixelToScreenCoords(bottomPoint),
                layer.pixelToScreenCoords(leftPoint)
            ]

            let invertedPoints = points.map { $0.invertedY }
            objectPath = polygonPath(invertedPoints)

        case .hexagonal, .staggered:
            objectPath = polygonPath(layer.bounds.points)
        }

        if let objectPath = objectPath {
            frameShape.path = objectPath
            frameShape.isAntialiased = layer.antialiased
            frameShape.lineWidth = (layer.tileSize.halfHeight > 8) ? 2 : 0.75
            frameShape.lineJoin = .miter

            // don't draw bounds of hexagonal maps
            frameShape.strokeColor = layer.frameColor
            if (layer.orientation == .hexagonal) {
                frameShape.strokeColor = SKColor.clear
            }

            frameShape.fillColor = SKColor.clear
        }

        isHidden = false
        frameShape.isHidden = false
    }

    /// Display the current tile grid.
    func drawGrid() {

        if (gridTexture == nil) {
            gridSprite.isHidden = true

            // get the last z-position
            zPosition = layer.tilemap.lastZPosition + (layer.tilemap.zDeltaForLayers + 10)
            isHidden = false
            var gridSize = CGSize.zero

            // scale factor for texture
            let uiScale: CGFloat = SKTiledContentScaleFactor

            // multipliers used to generate smooth lines
            let imageScale: CGFloat = layer.tilemap.renderQuality
            let lineScale: CGFloat = (layer.tilemap.tileHeightHalf > 8) ? 1 : 0.75   // 2:1

            // generate the texture
            if let gridImage = drawLayerGrid(self.layer, imageScale: imageScale, lineScale: lineScale) {

                gridTexture = SKTexture(cgImage: gridImage)
                gridTexture?.filteringMode = .linear

                // sprite scaling factor
                let spriteScaleFactor: CGFloat = (1 / imageScale)
                gridSize = (gridTexture != nil) ? gridTexture!.size() / uiScale : .zero
                gridSprite.setScale(spriteScaleFactor)

                Logger.default.log("grid texture size: \(gridSize.shortDescription), bpc: \(gridImage.bitsPerComponent), scale: \(imageScale)", level: .debug)

                gridSprite.texture = gridTexture
                gridSprite.alpha = layer.gridOpacity
                gridSprite.size = gridSize / imageScale

                // need to flip the grid texture in y
                // currently not doing this to the parent node so that objects will draw correctly.
                #if os(iOS) || os(tvOS)
                gridSprite.position.y = -layer.sizeInPoints.height
                #else
                gridSprite.yScale *= -1
                #endif
            }
        }
        gridSprite.isHidden = false
    }

    /// Display the current tile graph (if it exists).
    func drawGraph() {

        // drawLayerGrid
        graphTexture = nil
        graphSprite.isHidden = true

        // get the last z-position
        zPosition = layer.tilemap.lastZPosition + (layer.tilemap.zDeltaForLayers - 10)
        isHidden = false
        var graphSize = CGSize.zero

        // scale factor for texture
        let uiScale: CGFloat = SKTiledContentScaleFactor

        // multipliers used to generate smooth lines
        let imageScale: CGFloat = layer.tilemap.renderQuality
        let lineScale: CGFloat = (layer.tilemap.tileHeightHalf > 8) ? 2 : 1


        // generate the texture
        if (graphTexture == nil) {

            if let graphImage = drawLayerGraph(self.layer, imageScale: imageScale, lineScale: lineScale) {

                graphTexture = SKTexture(cgImage: graphImage)
                graphTexture?.filteringMode = .linear

                // sprite scaling factor
                let spriteScaleFactor: CGFloat = (1 / imageScale)
                graphSize = (graphTexture != nil) ? graphTexture!.size() / uiScale : .zero
                graphSprite.setScale(spriteScaleFactor)
                Logger.default.log("graph texture size: \(graphSize.shortDescription), bpc: \(graphImage.bitsPerComponent), scale: \(imageScale)", level: .debug)

                graphSprite.texture = graphTexture
                graphSprite.alpha = layer.gridOpacity * 3
                graphSprite.size = graphSize / imageScale

                // need to flip the graph texture in y
                // currently not doing this to the parent node so that objects will draw correctly.
                #if os(iOS) || os(tvOS)
                graphSprite.position.y = -layer.sizeInPoints.height
                #else
                graphSprite.yScale *= -1
                #endif

            }
        }
        graphSprite.isHidden = false
    }

    /**
     Visualize the layer's anchor point.
     */
    func drawAnchor() {
        childNode(withName: anchorKey)?.removeFromParent()

        let anchor = SKShapeNode(circleOfRadius: 0.75)
        anchor.name = anchorKey
        anchor.strokeColor = .clear
        anchor.zPosition = zPosition * 4

        addChild(anchor)
        anchor.position = anchorPoint
    }

    // MARK: - Memory

    /**
     Flush large textures.
     */
    func flush() {
        gridSprite.texture = nil
        graphSprite.texture = nil
        gridTexture = nil
        graphTexture = nil
    }
}


// Shape node used for highlighting and placing tiles.
public class TileShape: SKShapeNode {

    public enum DebugRole: Int {
        case none
        case highlight
        case coordinate
        case pathfinding
    }


    var tileSize: CGSize
    var orientation: SKTilemap.TilemapOrientation = .orthogonal
    var color: SKColor
    var layer: SKTiledLayerObject
    var coord: CGPoint

    var weight: Float = 1
    var role: DebugRole = .none
    var useLabel: Bool = false

    var initialized: Bool = false
    var interactions: Int = 0

    var renderQuality: CGFloat = 4
    var zoomFactor: CGFloat {
        return layer.tilemap.currentZoom
    }

    /**
     Initialize with parent layer reference, and coordinate.
     
     - parameter layer:     `SKTiledLayerObject` parent layer.
     - parameter coord      `CGPoint` tile coordinate.
     - parameter tileColor: `SKColor` shape color.
     - parameter withLabel: `Bool` render shape with label.
     */
    init(layer: SKTiledLayerObject, coord: CGPoint, tileColor: SKColor, role: DebugRole = .none, weight: Float = 1) {
        self.layer = layer
        self.coord = coord
        self.tileSize = layer.tileSize
        self.color = tileColor
        self.role = role
        self.weight = weight
        self.useLabel = (self.role == .coordinate)
        super.init()
        self.orientation = layer.orientation
        drawObject()
    }

    /**
     Initialize with parent layer reference and color.

     - parameter layer:     `SKTiledLayerObject` parent layer.
     - parameter tileColor: `SKColor` shape color.
     - parameter withLabel: `Bool` render shape with label.
     */
    public init(layer: SKTiledLayerObject, tileColor: SKColor, role: DebugRole = .none) {
        self.layer = layer
        self.coord = CGPoint.zero
        self.tileSize = layer.tileSize
        self.color = tileColor
        self.role = role
        self.useLabel = (self.role == .coordinate)
        super.init()
        self.orientation = layer.orientation
        drawObject()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Run an action that removes the node after a set duration.
     */
    public func cleanup() {
        let fadeAction = SKAction.fadeAlpha(to: 0, duration: 0.1)
        run(fadeAction, completion: { self.removeFromParent()})
    }

    /**
     Draw the object.
     */
    internal func drawObject() {
        // draw the path
        var points: [CGPoint] = []

        let scaledTilesize: CGSize = (tileSize * renderQuality)
        let halfWidth: CGFloat = (tileSize.width / 2) * renderQuality
        let halfHeight: CGFloat = (tileSize.height / 2) * renderQuality
        let tileWidth: CGFloat = (tileSize.width * renderQuality)
        let tileHeight: CGFloat = (tileSize.height * renderQuality)

        let tileSizeHalved = CGSize(width: halfWidth, height: halfHeight)

        switch orientation {
        case .orthogonal:
            let origin = CGPoint(x: -halfWidth, y: halfHeight)
            points = rectPointArray(scaledTilesize, origin: origin)

        case .isometric, .staggered:
            points = polygonPointArray(4, radius: tileSizeHalved)

        case .hexagonal:
            var hexPoints = Array(repeating: CGPoint.zero, count: 6)
            let staggerX = layer.tilemap.staggerX
            let sideLengthX = layer.tilemap.sideLengthX * renderQuality
            let sideLengthY = layer.tilemap.sideLengthY * renderQuality
            var variableSize: CGFloat = 0

            // flat
            if (staggerX == true) {
                let r = (tileWidth - sideLengthX) / 2
                let h = tileHeight / 2
                variableSize = tileWidth - (r * 2)
                hexPoints[0] = CGPoint(x: position.x - (variableSize / 2), y: position.y + h)
                hexPoints[1] = CGPoint(x: position.x + (variableSize / 2), y: position.y + h)
                hexPoints[2] = CGPoint(x: position.x + (tileWidth / 2), y: position.y)
                hexPoints[3] = CGPoint(x: position.x + (variableSize / 2), y: position.y - h)
                hexPoints[4] = CGPoint(x: position.x - (variableSize / 2), y: position.y - h)
                hexPoints[5] = CGPoint(x: position.x - (tileWidth / 2), y: position.y)
            } else {
                //let r = tileWidth / 2
                let h = (tileHeight - sideLengthY) / 2
                variableSize = tileHeight - (h * 2)
                hexPoints[0] = CGPoint(x: position.x, y: position.y + (tileHeight / 2))
                hexPoints[1] = CGPoint(x: position.x + (tileWidth / 2), y: position.y + (variableSize / 2))
                hexPoints[2] = CGPoint(x: position.x + (tileWidth / 2), y: position.y - (variableSize / 2))
                hexPoints[3] = CGPoint(x: position.x, y: position.y - (tileHeight / 2))
                hexPoints[4] = CGPoint(x: position.x - (tileWidth / 2), y: position.y - (variableSize / 2))
                hexPoints[5] = CGPoint(x: position.x - (tileWidth / 2), y: position.y + (variableSize / 2))
            }

            points = hexPoints.map { $0.invertedY }
        }

        // draw the path
        self.path = polygonPath(points)
        self.isAntialiased = layer.antialiased
        self.lineJoin = .miter
        self.miterLimit = 0
        self.lineWidth = 1

        var baseOpacity = layer.gridOpacity

        switch self.role {
        case .pathfinding:
            var baseColor = SKColor.gray

            switch weight {
            case (-2000)...(-1):
                baseColor = TiledObjectColors.lime
            case 0...10:
                baseColor = SKColor.gray
            case 11...200:
                baseColor = TiledObjectColors.dandelion
            case 201...Float.greatestFiniteMagnitude:
                baseColor = TiledObjectColors.english
            default:
                baseColor = SKColor.gray
            }

            baseOpacity = 0.8
            self.strokeColor = baseColor.withAlphaComponent(baseOpacity * 2)
            self.fillColor = baseColor.withAlphaComponent(baseOpacity * 1.5)


        default:
            self.strokeColor = SKColor.clear
            self.fillColor = self.color.withAlphaComponent(baseOpacity * 1.5)
        }


        // anchor
        childNode(withName: "ANCHOR")?.removeFromParent()
        let anchorRadius: CGFloat = (tileSize.halfHeight / 8) * renderQuality
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)
        anchor.name = "ANCHOR"
        addChild(anchor)
        anchor.fillColor = self.color.withAlphaComponent(0.05)
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = zPosition + 10
        anchor.isAntialiased = layer.antialiased



        // coordinate label
        childNode(withName: "COORDINATE")?.removeFromParent()
        if (useLabel == true) {
            let label = SKLabelNode(fontNamed: "Courier")
            label.name = "COORDINATE"
            label.fontSize = anchorRadius * renderQuality
            label.text = "\(Int(coord.x)),\(Int(coord.y))"
            addChild(label)
            label.zPosition = anchor.zPosition + 10
        }

        setScale(1 / renderQuality)
    }
}



extension TileShape {
    override public var description: String {
        return "Tile Shape: \(coord.shortDescription)"
    }
    override public var debugDescription: String { return description }
    override public var hashValue: Int { return coord.hashValue }
}



internal func == (lhs: TileShape, rhs: TileShape) -> Bool {
    return lhs.coord.hashValue == rhs.coord.hashValue
}


// MARK: - SKTilemap
extension SKTilemap {

    /**
     Return tiles & objects at the given point in the map.

     - parameter point: `CGPoint` position in tilemap.
     - returns: `[SKNode]` array of tiles.
     */
    public func renderableObjectsAt(point: CGPoint) -> [SKNode] {
        let pixelPosition = defaultLayer.screenToPixelCoords(point)
        return nodes(at: pixelPosition).filter { node in
            (node as? SKTile != nil) || (node as? SKTileObject != nil)
            }
    }

    /**
     Draw the map bounds.
     
     - parameter withColor: `SKColor?` optional highlight color.
     - parameter zpos:      `CGFloat?` optional z-position of bounds shape.
     - parameter duration:  `TimeInterval` effect length.
     */
    internal func drawBounds(withColor: SKColor?=nil, zpos: CGFloat?=nil, duration: TimeInterval = 0) {
        // remove old nodes
        self.childNode(withName: "MAP_BOUNDS")?.removeFromParent()
        self.childNode(withName: "MAP_ANCHOR")?.removeFromParent()

        // if a color is not passed, use the default frame color
        let drawColor = (withColor != nil) ? withColor! : self.frameColor


        let debugZPos = lastZPosition * 50

        let scaledVertices = getVertices().map { $0 * renderQuality }
        let tilemapPath = polygonPath(scaledVertices)


        let boundsShape = SKShapeNode(path: tilemapPath) // , centered: true)
        boundsShape.name = "MAP_BOUNDS"
        boundsShape.fillColor = drawColor.withAlphaComponent(0.2)
        boundsShape.strokeColor = drawColor
        self.addChild(boundsShape)


        boundsShape.isAntialiased = true
        boundsShape.lineCap = .round
        boundsShape.lineJoin = .miter
        boundsShape.miterLimit = 0
        boundsShape.lineWidth = 1 * (renderQuality / 2)

        boundsShape.setScale(1 / renderQuality)

        let anchorRadius = self.tileHeightHalf / 4
        let anchorShape = SKShapeNode(circleOfRadius: anchorRadius * renderQuality)
        anchorShape.name = "MAP_ANCHOR"
        anchorShape.fillColor = drawColor.withAlphaComponent(0.25)
        anchorShape.strokeColor = .clear
        boundsShape.addChild(anchorShape)
        boundsShape.zPosition = debugZPos

        if (duration > 0) {
            let fadeAction = SKAction.fadeAfter(wait: duration, alpha: 0)
            boundsShape.run(fadeAction, withKey: "MAP_FADEOUT_ACTION", completion: {
                boundsShape.removeFromParent()
            })
        }
    }
}



// MARK: - Logging

// Logging level.
public enum LoggingLevel: Int {
    case none
    case fatal
    case error
    case warning
    case success
    case status
    case info
    case debug
    case custom
}


// Log event
public struct LogEvent: Hashable {
    var message: String
    let level: LoggingLevel
    let uuid: String = UUID().uuidString

    var symbol: String?
    let date = Date()

    let file: String = #file
    let method: String = #function
    let line: UInt = #line
    let column: UInt = #column

    public init(_ message: String, level: LoggingLevel = .info, caller: String? = nil) {
        self.message = message
        self.level = level
        self.symbol = caller
    }

    public var hashValue: Int {
        return uuid.hashValue
    }
}


// Simple logging class.
public class Logger {

    public enum DateFormat {
        case none
        case short
        case long
    }

    public var locale = Locale.current
    public var dateFormat: DateFormat = .none
    static public let `default` = Logger()

    private var logcache: Set<LogEvent> = []
    private let logQueue = DispatchQueue.global(qos: .background)

    public var loggingLevel: LoggingLevel = .info {
        didSet {
            print("[\(String(describing: type(of: self)))]: logging level changed: \(loggingLevel)")
        }
    }

    /// Print a formatted log message to output.
    public func log(_ message: String, level: LoggingLevel = .info,
                    symbol: String? = nil, file: String = #file,
                    method: String = #function, line: UInt = #line) {

        // filter events at the current logging level (or higher)
        if (self.loggingLevel.rawValue > LoggingLevel.none.rawValue) && (level.rawValue <= self.loggingLevel.rawValue) {
            // format the message
            let formattedMessage = formatMessage(message, level: level,
                                                 symbol: symbol, file: file,
                                                 method: method, line: line)
            print(formattedMessage)
            return
        }
    }

    /// Queue log events to be run later.
    public func cache(_ event: LogEvent) {
        logcache.insert(event)
    }

    /// Run and release log events asyncronously.
    public func release() {
        for event in logcache.sorted() {
            logQueue.async {
                self.log(event.message, level: event.level)
            }
        }
        logcache = []
    }

    /// Formatted time stamp
    private var timeStamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = dateFormat.formatString
        let dateStamp = formatter.string(from: Date())
        return "[" + dateStamp + "]"
    }

    /**
     Format the message.
     */
    private func formatMessage(_ message: String, level: LoggingLevel = .info, symbol: String? = nil, file: String = #file, method: String = #function, line: UInt = #line) -> String {
        // shorten file name
        let filename = URL(fileURLWithPath: file).lastPathComponent


        if (level == .custom) {
            var formatted = "\(message)"
            if let symbol = symbol {
                formatted = "[\(symbol)]: \(formatted)"
            }
            return "❗️ \(formatted)"
        }

        if (level == .status) {
            var formatted = "\(message)"
            if let symbol = symbol {
                formatted = "[\(symbol)]: \(formatted)"
            }
            return "▹ \(formatted)"
        }

        if (level == .success) {
            return "\n ❊ Success! \(message)"
        }


        // result string
        var result: [String] = (dateFormat == .none) ? [] : [timeStamp]

        result += (symbol == nil) ? [filename] : ["[" + symbol! + "]"]
        result += [String(describing: level), message]
        return result.joined(separator: ": ")
    }
}


// Loggable object protcol.
public protocol Loggable {
    var logSymbol: String { get }
    func log(_ message: String, level: LoggingLevel, file: String, method: String, line: UInt)
}


// Methods for all loggable objects.
extension Loggable {
    public var logSymbol: String {
        return String(describing: type(of: self))
    }

    public func log(_ message: String, level: LoggingLevel, file: String = #file, method: String = #function, line: UInt = #line) {
        Logger.default.log(message, level: level, symbol: self.logSymbol, file: file, method: method, line: line)
    }
}


extension Logger.DateFormat {
    public var formatString: String {
        switch self {
        case .long:
            return "yyyy-MM-dd HH:mm:ss"
        default:
            return "HH:mm:ss"
        }
    }
}


extension LogEvent: Comparable {
    static public func < (lhs: LogEvent, rhs: LogEvent) -> Bool {
        return lhs.level.rawValue < rhs.level.rawValue
    }

    static public func == (lhs: LogEvent, rhs: LogEvent) -> Bool {
        return lhs.level.rawValue == rhs.level.rawValue
    }
}


extension LoggingLevel: Comparable {
    static public func < (lhs: LoggingLevel, rhs: LoggingLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static public func == (lhs: LoggingLevel, rhs: LoggingLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}


extension LoggingLevel: CustomStringConvertible {

    /// String representation of logging level.
    public var description: String {
        switch self {
        case .fatal:
            return "FATAL"
        case .error:
            return "ERROR"
        case .warning:
            return "WARNING"
        case .success:
            return "Success"
        case .info:
            return "INFO"
        case .debug:
            return "DEBUG"
        default:
            return ""
        }
    }

    /// Array of all options.
    public static let all: [LoggingLevel] = [.none, .fatal, .error, .warning, .success, .info, .debug, .custom]
}

