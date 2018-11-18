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
 
 ### Usage ###
 
 ```swift
 // show the map's grid & bounds shape
 tilemap.debugDrawOptions = [.drawGrid, .drawBounds]
 
 // turn off layer grid visibility
 layer.debugDrawOptions.remove(.drawGrid)
 ```
 
 ### Properties ###
 
 | Property         | Description                              |
 |:-----------------|:-----------------------------------------|
 | drawGrid         | Draw the layer's tile grid.              |
 | drawBounds       | Draw the layer's boundary.               |
 | drawGraph        | Visualize the layer's pathfinding graph. |
 | drawObjectBounds | Draw vector object bounds.               |
 | drawTileBounds   | Draw tile boundary shapes.               |
 | drawBackground   | Draw the layer's background color.       |
 | drawAnchor       | Draw the layer's anchor point.           |
 
 */
public struct DebugDrawOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }

    static public let drawGrid              = DebugDrawOptions(rawValue: 1 << 0) // 1
    static public let drawBounds            = DebugDrawOptions(rawValue: 1 << 1) // 2
    static public let drawGraph             = DebugDrawOptions(rawValue: 1 << 2) // 4
    static public let drawObjectBounds      = DebugDrawOptions(rawValue: 1 << 3) // 8
    static public let drawTileBounds        = DebugDrawOptions(rawValue: 1 << 4) // 16
    static public let drawMouseOverObject   = DebugDrawOptions(rawValue: 1 << 5) // 32
    static public let drawBackground        = DebugDrawOptions(rawValue: 1 << 6) // 64
    static public let drawAnchor            = DebugDrawOptions(rawValue: 1 << 7) // 128

    static public let all: DebugDrawOptions = [.drawGrid, .drawBounds, .drawGraph, .drawObjectBounds,
                                               .drawObjectBounds, .drawMouseOverObject,
                                               .drawBackground, .drawAnchor]
}


// MARK: - SKTilemap Extensions


extension SKTilemap {

    /**
     Draw the map bounds.

     - parameter withColor: `SKColor?` optional highlight color.
     - parameter zpos:      `CGFloat?` optional z-position of bounds shape.
     - parameter duration:  `TimeInterval` effect length.
     */
    internal func drawBounds(withColor: SKColor? = nil, zpos: CGFloat? = nil, duration: TimeInterval = 0) {
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



/// Anchor point visualization.
internal class AnchorNode: SKNode {

    var radius: CGFloat = 0
    var color: SKColor = SKColor.clear
    var labelText = "Anchor"
    var labelSize: CGFloat = 18.0
    var renderQuality: CGFloat = TiledGlobals.default.renderQuality.default

    var labelOffsetX: CGFloat = 0
    var labelOffsetY: CGFloat = 0

    var receiveCameraUpdates: Bool = true

    private var shapeKey = "ANCHOR_SHAPE"
    private var labelKey = "ANCHOR_LABEL"

    var sceneScale: CGFloat = 1

    private var shape: SKShapeNode? {
        return childNode(withName: shapeKey) as? SKShapeNode
    }
    private var label: SKLabelNode? {
        return childNode(withName: labelKey) as? SKLabelNode
    }

    init(radius: CGFloat, color shapeColor: SKColor, label text: String? = nil, offsetX: CGFloat = 0, offsetY: CGFloat = 0, zoom: CGFloat = 1) {
        self.radius = radius
        self.color = shapeColor
        self.labelOffsetX = offsetX
        self.labelOffsetY = offsetY
        self.sceneScale = zoom
        super.init()
        self.labelText = text ?? ""
        self.name = "ANCHOR"
        self.draw()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func draw() {
        shape?.removeFromParent()
        label?.removeFromParent()


        //let sceneScaleInverted = (sceneScale > 1) ? abs(1 - sceneScale) : sceneScale
        let scaledRenderQuality = renderQuality * sceneScale

        let minRadius: CGFloat = 4.0
        let maxRadius: CGFloat = 8.0
        var zoomedRadius = (radius / sceneScale)

        // clamp the anchor radius to min/max values
        zoomedRadius = (zoomedRadius > maxRadius) ? maxRadius : (zoomedRadius < minRadius) ? minRadius : zoomedRadius

        // debugging
        //let clampedString = (isClampedAtMin == true || isClampedAtMax == true) ? " (clamped)" : ""
        //let outputString = " - radius: \(zoomedRadius.roundTo(1)) -> \(radius.roundTo())"

        let scaledFontSize = (labelSize * renderQuality) * sceneScale
        let scaledOffsetX = (labelOffsetX / sceneScale)
        let scaledOffsetY = (labelOffsetY / sceneScale)

        let anchor = SKShapeNode(circleOfRadius: zoomedRadius)
        anchor.name = shapeKey
        addChild(anchor)
        anchor.fillColor = color
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = parent?.zPosition ?? 100

        // label
        let nameLabel = SKLabelNode(fontNamed: "Courier")
        nameLabel.name = labelKey
        nameLabel.text = labelText
        nameLabel.fontSize = scaledFontSize
        anchor.addChild(nameLabel)
        nameLabel.zPosition = anchor.zPosition + 1
        nameLabel.position.x += scaledOffsetX
        nameLabel.position.y += scaledOffsetY
        nameLabel.setScale(1.0 / scaledRenderQuality)
        nameLabel.color = .white
    }
}


extension AnchorNode: SKTiledSceneCameraDelegate {

    func cameraZoomChanged(newZoom: CGFloat) {
        if (newZoom != sceneScale) {
            sceneScale = newZoom
            draw()
        }
    }
}


/// Vector object proxy container overlay.
internal class TileObjectOverlay: SKNode {
    
    var initialized: Bool = false
    var cameraZoom: CGFloat = 1.0
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
    }
}


/// Vector object proxy.
internal class TileObjectProxy: SKShapeNode, SKTiledGeometry {
    
    weak var container: TileObjectOverlay?
    weak var reference: SKTileObject?
    
    var visibleToCamera: Bool = false
    var isRenderable: Bool = false
    var animationKey: String = "proxy"
    
    var showObjects: Bool = false {
        didSet {
            self.draw()
        }
    }
    
    var objectColor = TiledGlobals.default.debug.objectHighlightColor {
        didSet {
            self.draw()
        }
    }
    
    var fillOpacity = TiledGlobals.default.debug.objectFillOpacity {
        didSet {
            self.draw()
        }
    }
    
    var isFocused: Bool = false {
        didSet {
            guard (oldValue != isFocused) else { return }
            removeAction(forKey: animationKey)
            if (isFocused == false) && (showObjects == false) {
                let fadeAction = SKAction.colorFadeAction(after: 0.5)
                self.run(fadeAction, withKey: animationKey)
            } else {
                self.draw()
            }
        }
    }
    
    required init(object: SKTileObject, visible: Bool = false, renderable: Bool = false) {
        self.reference = object
        super.init()
        self.animationKey = "highlight-proxy-\(object.id)"
        self.name = "proxy-\(object.id)"
        object.proxy = self
        showObjects = visible
        isRenderable = renderable
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
    }
    
    func draw(debug: Bool = false) {
        
        let showFocused = TiledGlobals.default.debug.mouseFilters.contains(.objectsUnderCursor)
        let proxyIsVisible = (showObjects == true) || (isFocused == true && showFocused == true)

        self.removeAction(forKey: self.animationKey)
        guard let object = reference,
            let vertices = object.translatedVertices() else {
                self.path = nil
                return
        }
        
        // reset scale
        self.setScale(1)
        
        let convertedPoints = vertices.map {
            self.convert($0, from: object)
        }
        
        let renderQuality = TiledGlobals.default.renderQuality.object
        let objectRenderQuality = renderQuality / 2
        
        if (convertedPoints.isEmpty == false) {
            
            let scaledVertices = convertedPoints.map { $0 * renderQuality }
            
            let objectPath: CGPath
            switch object.shapeType {
            case .ellipse:
                objectPath = bezierPath(scaledVertices, closed: true, alpha: object.shapeType.curvature).path
            default:
                objectPath = polygonPath(scaledVertices, closed: true)
            }
            
            self.path = objectPath
            self.setScale(1 / renderQuality)

            
            let currentStrokeColor = (proxyIsVisible == true) ? self.objectColor : SKColor.clear
            let currentFillColor = (proxyIsVisible == true) ? (isRenderable == false) ? currentStrokeColor.withAlphaComponent(fillOpacity) : SKColor.clear : SKColor.clear
            
            self.strokeColor = currentStrokeColor
            self.fillColor = currentFillColor
            self.lineWidth = objectRenderQuality
        }
    }
}


/// Sprite object for visualizaing grid & graph.
internal class SKTiledDebugDrawNode: SKNode {

    private var layer: SKTiledLayerObject                     // parent layer
    private var isDefault: Bool = false                       // is the tilemap default layer

    private var gridSprite: SKSpriteNode!
    private var graphSprite: SKSpriteNode!
    private var frameShape: SKShapeNode!

    private var gridTexture: SKTexture?                      // grid texture
    private var graphTexture: SKTexture?                     // GKGridGraph texture
    private var anchorKey: String = "ANCHOR"

    init(tileLayer: SKTiledLayerObject, isDefault def: Bool = false) {
        layer = tileLayer
        isDefault = def
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
        return (isDefault == true) ? layer.tilemap.debugDrawOptions : layer.debugDrawOptions
    }

    /**
     Align with the parent layer.
     */
    func setup() {
        let nodeName = (isDefault == true) ? "MAP_DEBUG_DRAW" : "\(layer.layerName.uppercased())_DEBUG_DRAW"
        name = nodeName

        // set the anchorpoints to 0,0 to match the frame
        gridSprite = SKSpriteNode(texture: nil, color: .clear, size: layer.sizeInPoints)
        gridSprite.anchorPoint = CGPoint.zero
        addChild(gridSprite!)

        graphSprite = SKSpriteNode(texture: nil, color: .clear, size: layer.sizeInPoints)
        graphSprite.anchorPoint = CGPoint.zero
        addChild(graphSprite!)

        frameShape = SKShapeNode()
        addChild(frameShape!)
        //updateZPosition()
    }

    func updateZPosition() {
        let tilemap = layer.tilemap
        let zDeltaValue: CGFloat = tilemap.zDeltaForLayers

        // z-position values
        let startZposition = (isDefault == true) ? (tilemap.lastZPosition + zDeltaValue) : layer.zPosition

        graphSprite!.zPosition = startZposition + zDeltaValue
        gridSprite!.zPosition = startZposition + (zDeltaValue + 10)
        frameShape!.zPosition = startZposition + (zDeltaValue + 20)
    }

    /**
     Update the node with the various options.
     */
    func draw() {
        DispatchQueue.main.async {
            self.isHidden = self.debugDrawOptions.isEmpty
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
                self.drawLayerAnchor()
            } else {
                self.childNode(withName: self.anchorKey)?.removeFromParent()
            }
            self.updateZPosition()
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
            frameShape.alpha = layer.gridOpacity * 3

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
            let uiScale: CGFloat = TiledGlobals.default.contentScale

            // multipliers used to generate smooth lines
            let imageScale: CGFloat = layer.tilemap.renderQuality
            
            // line scale should be a multiple of 1
            let lineScale: CGFloat = (layer.tilemap.tileHeightHalf > 8) ? 2 : (layer.tilemap.tileHeightHalf > 4) ? 1 : 0.75

            // generate the texture
            if let gridImage = drawLayerGrid(self.layer, imageScale: imageScale, lineScale: lineScale) {
                gridTexture = SKTexture(cgImage: gridImage)
                gridTexture?.filteringMode = .linear

                // sprite scaling factor
                let spriteScaleFactor: CGFloat = (1 / imageScale)
                gridSize = (gridTexture != nil) ? gridTexture!.size() / uiScale : .zero
                gridSprite.setScale(spriteScaleFactor)
                Logger.default.log("grid texture size: \(gridSize.shortDescription), bpc: \(gridImage.bitsPerComponent), line scale: \(lineScale), scale: \(imageScale), content scale: \(uiScale)", level: .debug, symbol: "SKTiledDebugDrawNode")

                gridSprite.texture = gridTexture
                gridSprite.alpha = layer.gridOpacity
                gridSprite.size = gridSize / imageScale
                gridSprite.zPosition = zPosition * 3

                // need to flip the grid texture in y
                // currently not doing this to the parent node so that objects will draw correctly.
                #if os(iOS) || os(tvOS)
                gridSprite.position.y = -layer.sizeInPoints.height
                #else
                gridSprite.yScale *= -1
                #endif
            } else {
                self.log("error drawing layer grid.", level: .error)
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
        let uiScale: CGFloat = TiledGlobals.default.contentScale

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
                graphSprite.zPosition = zPosition * 3

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
    func drawLayerAnchor() {
        let anchor = drawAnchor(self, withKey: anchorKey)
        anchor.name = anchorKey
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
struct LogEvent: Hashable {
    var message: String
    let level: LoggingLevel
    let uuid: String = UUID().uuidString

    var symbol: String?
    let date = Date()

    let file: String   = #file
    let method: String = #function
    let line: UInt     = #line
    let column: UInt   = #column

    init(_ message: String, level: LoggingLevel = .info, caller: String? = nil) {
        self.message = message
        self.level = level
        self.symbol = caller
    }

    var hashValue: Int {
        return uuid.hashValue
    }
}


// Simple log event structure.
struct LogQueue {
    fileprivate var events: [LogEvent] = []
    mutating func push(_ event: LogEvent) {
        if !events.contains(event) {
            events.append(event)
        }
    }

    mutating func pop() -> LogEvent? {
        return events.popLast()
    }

    func peek() -> LogEvent? {
        return events.last
    }
}


// Simple logging class.
class Logger {

    enum DateFormat {
        case none
        case short
        case long
    }

    public var locale = Locale.current
    public var dateFormat: DateFormat = DateFormat.none
    public static let `default` = Logger()


    private var logcache: Set<LogEvent> = []
    private let logQueue = DispatchQueue(label: "com.sktiled.logger")

    var loggingLevel: LoggingLevel = LoggingLevel.info
    
    /**
     Print a formatted log message to output.

     - parameter message: `String` logging message.
     - parameter level:   `LoggingLevel` output verbosity.
     - parameter symbol:  `String?` class sending the message.
     */
    func log(_ message: String,
             level: LoggingLevel = LoggingLevel.info,
             symbol: String? = nil,
             file: String = #file,
             method: String = #function,
             line: UInt = #line) {
        
        // MARK: Logging Level
        
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
     Logger message formatter.
     */
    private func formatMessage(_ message: String,
                               level: LoggingLevel = LoggingLevel.info,
                               symbol: String? = nil,
                               file: String = #file,
                               method: String = #function,
                               line: UInt = #line) -> String {

        // shorten file name
        let filename = URL(fileURLWithPath: file).lastPathComponent


        if (level == LoggingLevel.custom) {
            var formatted = "\(message)"
            if let symbol = symbol {
                formatted = "[\(symbol)]: \(formatted)"
            }
            return "❗️ \(formatted)"
        }

        if (level == LoggingLevel.status) {
            var formatted = "\(message)"
            if let symbol = symbol {
                formatted = "[\(symbol)]: \(formatted)"
            }
            return "▹ \(formatted)"
        }

        if (level == LoggingLevel.success) {
            return "\n ✽ Success! \(message)"
        }


        // result string
        var result: [String] = (dateFormat == DateFormat.none) ? [] : [timeStamp]

        result += (symbol == nil) ? [filename] : ["[" + symbol! + "]"]
        result += [String(describing: level), message]
        return result.joined(separator: ": ")
    }
}


// Loggable object protcol.
protocol Loggable {
    var logSymbol: String { get }
    func log(_ message: String, level: LoggingLevel, file: String, method: String, line: UInt)
}


// Methods for all loggable objects.
extension Loggable {
    var logSymbol: String {
        return String(describing: type(of: self))
    }

    func log(_ message: String, level: LoggingLevel, file: String = #file, method: String = #function, line: UInt = #line) {
        Logger.default.log(message, level: level, symbol: self.logSymbol, file: file, method: method, line: line)
    }
}


extension Logger.DateFormat {
    var formatString: String {
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

extension LogEvent: CustomStringConvertible {
    var description: String {
        return message
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
        case .none: return "none"
        case .fatal: return "FATAL"
        case .error: return "ERROR"
        case .warning: return "WARNING"
        case .success: return "Success"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        default: return "?"
        }
    }

    /// Array of all options.
    public static let all: [LoggingLevel] = [.none, .fatal, .error, .warning, .success, .info, .debug, .custom]
}


extension TileObjectOverlay {
    
    internal var objects: [TileObjectProxy] {
        let proxies = children.filter { $0 as? TileObjectProxy != nil }
        return proxies as? [TileObjectProxy] ?? [TileObjectProxy]()
    }
    
    override var description: String {
        return "Objects Overlay: \(objects.count) objects."
    }
}


extension TileObjectProxy {
    
    override var description: String {
        guard let object = reference else {
            return "Object Proxy: nil"
        }
        return "Object Proxy: \(object.id)"
    }
    
    override var debugDescription: String {
        return description
    }
}



extension DebugDrawOptions {
    
    public var strings: [String] {
        var result: [String] = []
        
        if self.contains(.drawGrid) {
            result.append("Draw Grid")
        }
        if self.contains(.drawBounds) {
            result.append("Draw Bounds")
        }
        if self.contains(.drawGraph) {
            result.append("Draw Graph")
        }
        if self.contains(.drawObjectBounds) {
            result.append("Draw Object Bounds")
        }
        if self.contains(.drawTileBounds) {
            result.append("Draw Tile Bounds")
        }
        if self.contains(.drawMouseOverObject) {
            result.append("Draw Mouse Over Object")
        }
        if self.contains(.drawBackground) {
            result.append("Draw Background")
        }
        if self.contains(.drawAnchor) {
            result.append("Draw Anchor")
        }
        return result
    }
}


extension DebugDrawOptions: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    
    public var description: String {
        guard (strings.isEmpty == false) else {
            return "none"
        }
        return strings.joined(separator: ", ")
    }
    
    public var debugDescription: String {
        return description
    }
    
    public var customMirror: Mirror {
        return Mirror(reflecting: DebugDrawOptions.self)
    }
}


extension SKTilemap: Loggable {}
extension SKTiledLayerObject: Loggable {}
extension SKTileset: Loggable {}
extension SKTilemapParser: Loggable {}
extension SKTiledDebugDrawNode: Loggable {}


extension SKTiledDebugDrawNode: CustomReflectable {
    
    var customMirror: Mirror {
        return Mirror(reflecting: SKTiledDebugDrawNode.self)
    }
    
    override var description: String {
        return "Debug Draw Node: \(layer.layerName)"
    }
    
    override var debugDescription: String {
        return description
    }
}


protocol CustomDebugReflectable: class {
    func dumpStatistics()
}



extension CustomDebugReflectable {
    
    func underlined(for string: String, symbol: String? = nil, colon: Bool = true) -> String {
        let symbolString = symbol ?? "#"
        let colonString = (colon == true) ? ":" : ""
        let spacer = String(repeating: " ", count: symbolString.count)
        let formattedString = "\(symbolString)\(spacer)\(string)\(colonString)"
        let underlinedString = String(repeating: "-", count: formattedString.count)
        return "\n\(formattedString)\n\(underlinedString)\n"
    }
}
