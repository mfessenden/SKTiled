//
//  SKTiled+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 6/19/17.
//  Copyright © 2017 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit


/// globals
var TILE_BOUNDS_USE_OFFSET: Bool = false

/// Options for debugging the map
public struct DebugDrawOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }

    static public let drawGrid             = DebugDrawOptions(rawValue: 1 << 0)  // 2
    static public let drawBounds           = DebugDrawOptions(rawValue: 1 << 1)  // 2
    static public let drawGraph            = DebugDrawOptions(rawValue: 1 << 2)  // 4
    static public let drawObjectBounds     = DebugDrawOptions(rawValue: 1 << 3)
    static public let drawTileBounds       = DebugDrawOptions(rawValue: 1 << 4)
    static public let drawMouseOverObject  = DebugDrawOptions(rawValue: 1 << 5)
    static public let drawBackground       = DebugDrawOptions(rawValue: 1 << 6)

    static public let demo:  DebugDrawOptions  = [.drawGrid, .drawBounds]
    static public let graph: DebugDrawOptions  = [.demo, .drawGraph]
    static public let all:   DebugDrawOptions  = [.demo, .drawGraph, .drawObjectBounds, .drawTileBounds, .drawMouseOverObject, .drawBackground]
}


/// Sprite object for visualizaing grid & graph.
// TODO: at some point the grid & graph textures should be a shader.
internal class TiledDebugDrawNode: SKNode {

    private var layer: TiledLayerObject                     // parent layer

    private var gridSprite: SKSpriteNode!
    private var graphSprite: SKSpriteNode!
    private var frameShape: SKShapeNode!

    private var gridTexture: SKTexture! = nil               // grid texture
    private var graphTexture: SKTexture! = nil              // GKGridGraph texture

    init(tileLayer: TiledLayerObject){
        layer = tileLayer
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var debugDrawOptions: DebugDrawOptions {
        return layer.debugDrawOptions
    }

    var showGrid: Bool {
        get {
            return (gridSprite != nil) ? (gridSprite!.isHidden == false) : false
        } set {
            if (gridTexture == nil) {
                drawGrid()
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
            drawGraph()
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

    func update() {
        print("[TiledDebugDrawNode]: debug options: \(debugDrawOptions.rawValue), hidden: \(isHidden)")
        if debugDrawOptions.contains(.drawGrid) {
            drawGrid()
        } else {
            gridSprite?.isHidden = true
        }

        if debugDrawOptions.contains(.drawBounds) {
            drawBounds()
        } else {
            frameShape?.isHidden = true
        }
        
        if debugDrawOptions.contains(.drawGraph) {
            drawGraph()
        } else {
            graphSprite?.isHidden = true
        }
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
            objectPath = polygonPath(layer.boundingRect.points)

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

            let invertedPoints = points.map{ $0.invertedY }
            objectPath = polygonPath(invertedPoints)

        case .hexagonal, .staggered:
            objectPath = polygonPath(layer.boundingRect.points)
        }

        if let objectPath = objectPath {
            frameShape.path = objectPath
            frameShape.isAntialiased = false
            frameShape.lineWidth = (layer.tileSize.halfHeight) < 8 ? 0.5 : 1
            frameShape.lineJoin = .miter

            // don't draw bounds of hexagonal maps
            frameShape.strokeColor = layer.frameColor
            if (layer.orientation == .hexagonal){
                frameShape.strokeColor = SKColor.clear
            }

            frameShape.fillColor = SKColor.clear
        }

        isHidden = false
        frameShape.isHidden = false
    }

    /// Display the current tile grid.
    func drawGrid() {

        gridTexture = nil
        gridSprite.isHidden = true

        // get the last z-position
        zPosition = layer.tilemap.lastZPosition + layer.tilemap.zDeltaForLayers
        isHidden = false
        var gridSize = CGSize.zero

        // scale factor for texture
        let uiScale: CGFloat = getContentScaleFactor()

        // multipliers used to generate smooth lines
        let defaultImageScale: CGFloat = (layer.tilemap.tileHeight < 16) ? 8 : 8   // was 4
        let imageScale: CGFloat = (uiScale > 1) ? (defaultImageScale / 2) : defaultImageScale
        let lineScale: CGFloat = (layer.tilemap.tileHeightHalf > 8) ? 1 : 0.85 //0.5 : 0.25    // 1 : 0.85

        // generate the texture
        if (gridTexture == nil) {
            let gridImage = drawLayerGrid(self.layer, imageScale: imageScale, lineScale: lineScale)
            gridTexture = SKTexture(cgImage: gridImage)
            gridTexture.filteringMode = .linear
        }

        // sprite scaling factor
        let spriteScaleFactor: CGFloat = (1 / imageScale)
        gridSize = gridTexture.size() / uiScale
        gridSprite.setScale(spriteScaleFactor)


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
        gridSprite.isHidden = false
    }
    
    /// Display the current tile graph (if it exists).
    func drawGraph() {
        // drawLayerGrid
        graphTexture = nil
        graphSprite.isHidden = true
        
        // get the last z-position
        zPosition = layer.tilemap.lastZPosition + layer.tilemap.zDeltaForLayers
        isHidden = false
        var gridSize = CGSize.zero
        
        // scale factor for texture
        let uiScale: CGFloat = getContentScaleFactor()
        
        // multipliers used to generate smooth lines
        let defaultImageScale: CGFloat = (layer.tilemap.tileHeight < 16) ? 8 : 8
        let imageScale: CGFloat = (uiScale > 1) ? (defaultImageScale / 2) : defaultImageScale
        let lineScale: CGFloat = (layer.tilemap.tileHeightHalf > 8) ? 1 : 0.85 //0.5 : 0.25    // 1 : 0.85
        
        
        // generate the texture
        if (graphTexture == nil) {
            let gridImage = drawLayerGraph(self.layer, imageScale: imageScale, lineScale: lineScale)
            graphTexture = SKTexture(cgImage: gridImage)
            graphTexture.filteringMode = .linear
        }
        
        // sprite scaling factor
        let spriteScaleFactor: CGFloat = (1 / imageScale)
        gridSize = graphTexture.size() / uiScale
        graphSprite.setScale(spriteScaleFactor)
        
        
        graphSprite.texture = graphTexture
        graphSprite.alpha = layer.gridOpacity
        graphSprite.size = gridSize / imageScale
        
        // need to flip the grid texture in y
        // currently not doing this to the parent node so that objects will draw correctly.
        #if os(iOS) || os(tvOS)
        graphSprite.position.y = -layer.sizeInPoints.height
        #else
        graphSprite.yScale *= -1
        #endif
        graphSprite.isHidden = false
    }
}


/// Shape node used for highlighting and placing tiles.
internal class TileShape: SKShapeNode {

    var tileSize: CGSize
    var orientation: TilemapOrientation = .orthogonal
    var color: SKColor
    var layer: TiledLayerObject
    var coord: CGPoint
    var useLabel: Bool = false
    var renderQuality: CGFloat = 4
    public var clickCount: Int = 0 {
        didSet {
            guard oldValue != clickCount else { return }

            if clickCount > 0 {
                //detonate()
            }
        }
    }

    init(layer: TiledLayerObject, coord: CGPoint, tileColor: SKColor, withLabel: Bool=false){
        self.layer = layer
        self.coord = coord
        self.tileSize = layer.tileSize
        self.color = tileColor
        self.useLabel = withLabel
        super.init()
        self.orientation = layer.orientation
        drawObject()
    }

    init(layer: TiledLayerObject, tileColor: SKColor, withLabel: Bool=false){
        self.layer = layer
        self.coord = CGPoint.zero
        self.tileSize = layer.tileSize
        self.color = tileColor
        self.useLabel = withLabel
        super.init()
        self.orientation = layer.orientation
        drawObject()

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func detonate() {
        let fadeAction = SKAction.fadeAlpha(to: 0, duration: 0.1)
        run(fadeAction, completion: { self.removeFromParent()})
    }

    /**
     Draw the object.
     */
    private func drawObject() {
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

            points = hexPoints.map{ $0.invertedY }
        }

        // draw the path
        self.path = polygonPath(points)
        self.isAntialiased = true
        self.lineJoin = .miter
        self.miterLimit = 0
        self.lineWidth = 1

        self.strokeColor = self.color.withAlphaComponent(0.75)
        self.fillColor = self.color.withAlphaComponent(0.18)

        // anchor
        childNode(withName: "ANCHOR")?.removeFromParent()
        let anchorRadius: CGFloat = (tileSize.halfHeight / 8) * renderQuality
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)
        anchor.name = "ANCHOR"
        addChild(anchor)
        anchor.fillColor = self.color.withAlphaComponent(0.05)
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = zPosition + 10
        anchor.isAntialiased = true



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

    override public var debugDescription: String {
        return description
    }
}



internal func == (lhs: TileShape, rhs: TileShape) -> Bool {
    return lhs.coord.hashValue == rhs.coord.hashValue
}


extension SKTilemap {

    /**
     Return tiles & objects at the given point in the map.

     - parameter point: `CGPoint` position in tilemap.
     - returns: `[SKNode]` array of tiles.
     */
    open func renderableObjectsAt(point: CGPoint) -> [SKNode] {
        return nodes(at: point).filter { node in
            (node as? SKTile != nil) || (node as? SKTileObject != nil)
        }
    }
}


extension SKTile {
    /**
     Highlight the tile with a given color.

     - parameter color:        `SKColor?` optional highlight color.
     - parameter duration:     `TimeInterval` duration of effect.
     - parameter antialiasing: `Bool` antialias edges.
     */
    public func highlightWithColor(_ color: SKColor?=nil,
                                   duration: TimeInterval=1.0,
                                   antialiasing: Bool=true) {

        let highlight: SKColor = (color == nil) ? highlightColor : color!
        let orientation = tileData.tileset.tilemap.orientation

        if orientation == .orthogonal || orientation == .hexagonal {
            childNode(withName: "HIGHLIGHT")?.removeFromParent()

            var highlightNode: SKShapeNode? = nil
            if orientation == .orthogonal {
                highlightNode = SKShapeNode(rectOf: tileSize, cornerRadius: 0)
            }

            if orientation == .hexagonal {
                let hexPath = polygonPath(self.getVertices())
                highlightNode = SKShapeNode(path: hexPath, centered: true)
            }

            if let highlightNode = highlightNode {
                highlightNode.strokeColor = SKColor.clear
                highlightNode.fillColor = highlight.withAlphaComponent(0.35)
                highlightNode.name = "HIGHLIGHT"

                highlightNode.isAntialiased = antialiasing
                addChild(highlightNode)
                highlightNode.zPosition = zPosition + 50

                // fade out highlight
                removeAction(forKey: "HIGHLIGHT_FADE")
                let fadeAction = SKAction.sequence([
                    SKAction.wait(forDuration: duration * 1.5),
                    SKAction.fadeAlpha(to: 0, duration: duration/4.0)
                    ])

                highlightNode.run(fadeAction, withKey: "HIGHLIGHT_FADE", optionalCompletion: {
                    highlightNode.removeFromParent()
                })
            }
        }

        if orientation == .isometric || orientation == .staggered {
            removeAction(forKey: "HIGHLIGHT_FADE")
            let fadeOutAction = SKAction.colorize(with: SKColor.clear, colorBlendFactor: 1, duration: duration)
            run(fadeOutAction, withKey: "HIGHLIGHT_FADE", optionalCompletion: {
                let fadeInAction = SKAction.sequence([
                    SKAction.wait(forDuration: duration * 2.5),
                    //fadeOutAction.reversedAction()
                    SKAction.colorize(with: SKColor.clear, colorBlendFactor: 0, duration: duration/4.0)
                    ])
                self.run(fadeInAction, withKey: "HIGHLIGHT_FADE")
            })
        }
    }

    /**
     Clear highlighting.
     */
    public func clearHighlight() {
        let orientation = tileData.tileset.tilemap.orientation

        if orientation == .orthogonal {
            childNode(withName: "Highlight")?.removeFromParent()
        }
        if orientation == .isometric {
            removeAction(forKey: "Highlight_Fade")
        }
    }
}


public extension TiledLayerObject {
    /**
     Communicate with the scene.
     */
    public func updateSceneDebugInfo(_ msg: String) {
        if let demoScene = self.scene as? SKTiledDemoScene {
            demoScene.updateDebugInfo(msg: msg)
        }
    }
}

#if os(OSX)
extension SKTiledDemoScene {

    /**
     Run demo keyboard events (macOS).

     - parameter eventKey: `UInt16` event key.

     */
    public func keyboardEvent(eventKey: UInt16) {
        guard let view = view,
            let cameraNode = cameraNode,
            let tilemap = tilemap,
            let worldNode = worldNode else {
                return
        }

        // 'a' or 'f' fits the map to the current view
        if eventKey == 0x0 || eventKey == 0x3 {
            cameraNode.fitToView(newSize: view.bounds.size)
        }

        // 'd' shows/hides debug view
        if eventKey == 0x02 {
            print("[SKTiledDemoScene]: no debug drawing options available.")

        }

        // 'h' hides the HUD
        if eventKey == 0x04 {
            if let view = self.view {
                let debugState = !view.showsFPS
                view.showsFPS = debugState
                view.showsNodeCount = debugState
                view.showsDrawCount = debugState
            }
        }


        // 'j' fades the layers in succession
        if eventKey == 0x26 {
            var fadeTime: TimeInterval = 3
            let additionalTime: TimeInterval = (tilemap.layerCount > 6) ? 1.25 : 2.25
            for layer in tilemap.getContentLayers() {
                let fadeAction = SKAction.fadeAfter(wait: fadeTime, alpha: 0)
                layer.run(fadeAction)
                fadeTime += additionalTime
            }
        }

        // 'k' updates the render quality
        if eventKey == 0x28 {
            if tilemap.renderQuality < 16 {
                tilemap.renderQuality *= 2
            }
        }

        // 'l' toggles object bounds drawing
        if eventKey == 0x25 {
            // if objects are shown...
            if tilemap.debugDrawOptions.contains(.drawObjectBounds) {
                tilemap.debugDrawOptions.remove(.drawObjectBounds)
            } else {
                tilemap.debugDrawOptions.insert(.drawObjectBounds)
            }
        }

        // 'o' shows/hides object layers
        if eventKey == 0x1f {
            tilemap.showObjects = !tilemap.showObjects
        }

        // 'p' pauses the map
        if eventKey == 0x23 {
            self.isPaused = !self.isPaused
        }

        // 'q' print layer stats
        if eventKey == 0xc {
            tilemap.mapStatistics()
        }

        // '←' advances to the next scene
        if eventKey == 0x7B {
            self.loadPreviousScene()
        }

        // '1' zooms to 100%
        if eventKey == 0x12 || eventKey == 0x53 {
            cameraNode.resetCamera()
        }

        // 'clear' clears TileShapes
        if eventKey == 0x47 {
            self.enumerateChildNodes(withName: "//*") {
                node, stop in

                if let tile = node as? TileShape {
                    tile.removeFromParent()
                }
            }
        }

        // MARK: - DEBUGGING TESTS
        // TODO: get rid of these in master


        // 'm' toggles tile bounds drawing
        if eventKey == 0x2e {
            // if objects are shown...
            if tilemap.debugDrawOptions.contains(.drawTileBounds) {
                tilemap.debugDrawOptions.remove(.drawTileBounds)
            } else {
                tilemap.debugDrawOptions.insert(.drawTileBounds)
            }
        }

        // 'g' shows the grid for the map default layer.
        if eventKey == 0x5 {
            tilemap.baseLayer.debugDrawOptions = (tilemap.baseLayer.debugDrawOptions != []) ? [] : [.demo]
        }

        // 'i' runs a custom event
        if eventKey == 0x22 {
            var fadeTime: TimeInterval = 3
            let shapeRadius = (tilemap.tileHeightHalf / 4) - 0.5
            for x in 0..<Int(tilemap.size.width) {
                for y in 0..<Int(tilemap.size.height) {

                    let shape = SKShapeNode(circleOfRadius: shapeRadius)
                    shape.alpha = 0.7
                    shape.fillColor = SKColor(hexString: "#FD4444")
                    shape.strokeColor = .clear
                    worldNode.addChild(shape)

                    let shapePos = tilemap.baseLayer.pointForCoordinate(x, y)
                    shape.position = worldNode.convert(shapePos, from: tilemap.baseLayer)
                    shape.zPosition = tilemap.lastZPosition + tilemap.zDeltaForLayers

                    let fadeAction = SKAction.fadeAfter(wait: fadeTime, alpha: 0)
                    shape.run(fadeAction, completion: {
                        shape.removeFromParent()
                    })
                    fadeTime += 0.003

                }
                //fadeTime += 0.02
            }
        }

        // 'n' changes the background color
        if eventKey == 0x2d {
            //tilemap.backgroundColor = SKColor(hexString: "#ea32fa")
            // if objects are shown...
            if tilemap.baseLayer.debugDrawOptions.contains(.drawBackground) {
                tilemap.baseLayer.debugDrawOptions.remove(.drawBackground)
            } else {
                tilemap.baseLayer.debugDrawOptions.insert(.drawBackground)
            }
        }

        // 'r' reloads the scene
        if eventKey == 0xf {
            self.reloadScene()
        }

        // 's' runs a custom command
        if eventKey == 0x1 {
        }

        // 't' runs a custom command
        if eventKey == 0x11 {

        }

        // 'u' runs a custom command
        if eventKey == 0x20 {

        }

        // 'v' runs a custom test
        if eventKey == 0x9 {
            view.showsPhysics = !view.showsPhysics
        }

        // 'w' toggles debug layer visibility
        if eventKey == 0xd {
            tilemap.getLayers(ofType: "DEBUG").forEach{ $0.isHidden = !$0.isHidden }
        }

        // 'y' runs a custom test
        if eventKey == 0x10 {
            tilemap.getLayers(ofType: "DEBUG").forEach{ $0.isHidden = !$0.isHidden }
        }


        // '↑' runs a custom test
        if eventKey == 0x7e {
            let scaleFactor =  getContentScaleFactor()
            var nodesUpdated = 0
            tilemap.enumerateChildNodes(withName: "//*") {
                node, stop in


                let className = String(describing: type(of: node))

                let oldPos = node.position
                node.position = clampedPosition(point: node.position, scale: scaleFactor)
                print("- \(className): \(node.position), \(oldPos)")
                nodesUpdated += 1
            }


            print("[SKTiledDemoScene]: \(nodesUpdated) nodes updated.")
        }
    }
}
#endif


// TODO: Temporary

public func flipFlagsDebug(hflip: Bool, vflip: Bool, dflip: Bool) -> String {
    var result: String = "none"
    if (dflip == true) {
        if (hflip && !vflip) {
            result = "rotate 90"   // rotate 90deg
        }

        if (hflip && vflip) {
            result = "rotate 90, xScale * -1"
        }

        if (!hflip && vflip) {
            result = "rotate -90"    // rotate -90deg
        }

        if (!hflip && !vflip) {
            result = "rotate -90, xScale * -1"
        }
    } else {
        if (hflip == true) {
            result = "xScale * -1"
        }

        if (vflip == true) {
            result = "yScale * -1"
        }
    }
    return result
}


public extension SignedInteger {
    public var hexString: String { return "0x" + String(self, radix: 16) }
    public var binaryString: String { return "0b" + String(self, radix: 2) }
}


public extension UnsignedInteger {
    public var hexString: String { return "0x" + String(self, radix: 16) }
    public var binaryString: String { return "0b" + String(self, radix: 2) }
}


#if os(iOS) || os(tvOS)
public extension UIFont {
    // print all fonts
    public static func allFontNames() {
        for family: String in UIFont.familyNames {
            print("\(family)")
            for names: String in UIFont.fontNames(forFamilyName: family){
                print("== \(names)")
            }
        }
    }
}
#else
public extension NSFont {
    public static func allFontNames() {
        let fm = NSFontManager.shared()
        for family in fm.availableFonts {
            print("\(family)")
        }
    }
}
#endif
