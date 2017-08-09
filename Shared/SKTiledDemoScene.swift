//
//  SKTiledDemoScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit
import Foundation
import GameplayKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


public class SKTiledDemoScene: SKTiledScene {
    
    public var uiScale: CGFloat = 1
    public var mouseTracker = MouseTracker()
    
    /// global information label font size.
    private let labelFontSize: CGFloat = 11
    
    internal var selected: [TiledLayerObject] = []
    
    internal var tileshapes: Set<TileShape> = []
    
    internal var editMode: Bool = false
    internal var liveMode: Bool = true                     // highlight tiles under the mouse
    
    internal let cleanupQueue = DispatchQueue(label: "com.sktiled.cleanup", qos: .userInteractive)
    
    internal var coordinate: CGPoint = .zero {
        didSet {
            guard oldValue != coordinate else { return }
            
            self.enumerateChildNodes(withName: "*") {  // was //*
                node, stop in
                
                if let tile = node as? TileShape {
                    if (tile.coord != self.coordinate) {
                        if self.tileshapes.contains(tile) {
                            print("tile is in tileshapes")
                        }
                    }
                }
            }
        }
    }
    
    override public var isPaused: Bool {
        willSet {
            let pauseMessage = (newValue == true) ? "Paused" : ""
            updatePauseInfo(msg: pauseMessage)
        }
    }
    
    override public func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // setup demo UI
        updateHud()
        
        #if os(macOS)
        updateTrackingViews()
        addChild(mouseTracker)
        mouseTracker.zPosition = 1000
        #endif
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCoordinate), name: NSNotification.Name(rawValue: "updateCoordinate"), object: nil)
    }

    /**
     Add a tile shape to a layer at the given coordinate.
     
     - parameter layer:     `TiledLayerObject` layer object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    func addTileToLayer(_ layer: TiledLayerObject, _ x: Int, _ y: Int, useLabel: Bool=true)  {
        guard let tilemap = tilemap else { return  }
        
        // validate the coordinate
        let validCoord = layer.isValid(x, y)
        
        let coord = CGPoint(x: x, y: y)
        
        let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
        let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)
        // add debug tile shape
        let tile = TileShape(layer: layer, coord: coord, tileColor: tileColor, withLabel: useLabel)
            
        tile.zPosition = lastZosition
        tile.position = layer.pointForCoordinate(x, y)
        layer.addChild(tile)
    }
    
    /**
     Add a temporary tile shape to the world at the given coordinate.
     
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    func addTileToWorld(_ x: Int, _ y: Int, useLabel: Bool=false) {
        guard let tilemap = tilemap,
                let worldNode = worldNode else { return }
        
        // validate the coordinate
        let layer = tilemap.baseLayer
        let validCoord = layer.isValid(x, y)
        
        let coord = CGPoint(x: x, y: y)

        if (coord != coordinate) || (useLabel == true) {
            let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
            let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)
            
            // add debug tile shape

            let tile = TileShape(layer: layer, coord: coord, tileColor: tileColor, withLabel: useLabel)
            
            tile.zPosition = lastZosition
            let tilePosition = layer.pointForCoordinate(x, y)
            tile.position = worldNode.convert(tilePosition, from: layer)
            worldNode.addChild(tile)
            
            if (useLabel == false) {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCoordinate"), object: nil, userInfo: ["x": x, "y": y])
            } else {
                tileshapes.insert(tile)
            }
        }
    }
    
    // MARK: - Deinitialization
    deinit {
        // Deregister for scene updates
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "reloadScene"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "loadPreviousScene"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "updateDebugLabels"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "updateCoordinate"), object: nil)
        
        removeAllActions()
        removeAllChildren()
    }
    
    /**
     Callback to the GameViewController to reload the current scene.
     */
    public func reloadScene() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadScene"), object: nil)
    }
    
    /**
     Callback to the GameViewController to load the next scene.
     */
    public func loadNextScene() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadNextScene"), object: nil)
    }
    
    /**
     Callback to the GameViewController to reload the previous scene.
     */
    public func loadPreviousScene() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadPreviousScene"), object: nil)
    }
    
    public func updateMapInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["mapInfo": msg])
    }
        
    public func updateTileInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["tileInfo": msg])
    }
        
    public func updatePropertiesInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["propertiesInfo": msg])
    }
    
    public func updateDebugInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["debugInfo": msg])
    }
    
    public func updateCameraInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": msg])
    }
    
    public func updatePauseInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["pauseInfo": msg])
    }

    /**
     Callback to remove coordinates.
     */
    public func updateCoordinate(notification: Notification) {
        let tempCoord = CGPoint(x: notification.userInfo!["x"] as! Int,
                                y: notification.userInfo!["y"] as! Int)
        
        guard tempCoord != coordinate else { return }
        // get the current coordinate
        if (coordinate != tempCoord) {
            coordinate = tempCoord
        }
    }
    
    override public func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateHud()
        #if os(OSX)
        updateTrackingViews()
        #endif
    }

    /**
     Update HUD elements when the view size changes.
     */
    fileprivate func updateHud(){
        guard let tilemap = tilemap else { return }
        updateMapInfo(msg: tilemap.description)
                
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateWindowTitle"), object: nil, userInfo: ["wintitle": tilemap.url.lastPathComponent])
    }
    
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        self.enumerateChildNodes(withName: "//*") { 
            node, stop in
            
            if let tile = node as? TileShape {
                if (tile.coord != self.coordinate) && (tile.useLabel == false) {
                    
                    // remove the node asyncronously
                    self.cleanupQueue.async {
                        let fadeAction = SKAction.fadeAlpha(to: 0, duration: 0.1)
                        tile.run(fadeAction, completion: {
                            tile.removeFromParent()
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - Callbacks
    override open func didReadMap(_ tilemap: SKTilemap) {
        self.physicsWorld.speed = 0
        //print(" ❊ `SKTiledDemoScene.didReadMap`...")
    }
    
    override open func didRenderMap(_ tilemap: SKTilemap) {
        // update the HUD to reflect the number of tiles created
        print(" ❊ `SKTiledDemoScene.didRenderMap`...")
        updateHud()
        tilemap.mapStatistics()
    }
    
    override open func didAddPathfindingGraph(_ graph: GKGridGraph<GKGridGraphNode>) {
        super.didAddPathfindingGraph(graph)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateGraphControls"), object: nil, userInfo: ["hasGraphs": true])
    }
}



#if os(iOS) || os(tvOS)
// Touch-based event handling
extension SKTiledDemoScene {
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        
        for touch in touches {
            
            // get the position in the baseLayer
            let positionInLayer = baseLayer.touchLocation(touch)
            
            let coord = baseLayer.coordinateAtTouchLocation(touch)
            // add a tile shape to the base layer where the user has clicked
            
            // highlight the current coordinate
            addTileToWorld(Int(coord.x), Int(coord.y), useLabel: true)
            
            // update the tile information label
            let coordStr = "Coord: \(coord.shortDescription), \(positionInLayer.roundTo())"
            
            updateTileInfo(msg: coordStr)
            
            // tile properties output
            var propertiesInfoString = ""
            if let tile = tilemap.firstTileAt(coord: coord) {
                propertiesInfoString = tile.tileData.description
            }
            
            updatePropertiesInfo(msg: propertiesInfoString)
        }
    }
}
#endif


#if os(OSX)
// Mouse-based event handling
extension SKTiledDemoScene {
        
    override open func mouseDown(with event: NSEvent) {
        guard let tilemap = tilemap,
            let cameraNode = cameraNode else { return }
        
        cameraNode.mouseDown(with: event)
        
        let positionInScene = event.location(in: self)
        let baseLayer = tilemap.baseLayer
        
        // get the position in the baseLayer
        let positionInLayer = baseLayer.mouseLocation(event: event)
        // get the coordinate at that position
        let coord = baseLayer.coordinateAtMouseEvent(event: event)
        let nodesUnderCursor = nodes(at: positionInScene).filter( { $0 as? TileShape != nil }) as! [TileShape]
        let tilesUnderCursor = nodesUnderCursor.filter( { $0.useLabel == true } )

        if (tilemap.isPaused == false) {
            // highlight the current coordinate
            if tilesUnderCursor.count == 0 {
                addTileToWorld(Int(coord.x), Int(coord.y), useLabel: true)
            }
        }
 
        // update the tile information label
        let coordDescription = "\(Int(coord.x)), \(Int(coord.y))"
        let coordStr = "Coord: \(coordDescription), \(positionInLayer.roundTo())"
        updateTileInfo(msg: coordStr)
        
        // tile properties output
        var propertiesInfoString = ""
        if let tile = tilemap.firstTileAt(coord: coord) {
            propertiesInfoString = tile.tileData.description

            if let layer = tile.layer {
                if !selected.contains(layer) {
                    selected.append(layer)
                }
            }
        }
        updatePropertiesInfo(msg: propertiesInfoString)
    }
    
    override open func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard let tilemap = tilemap else { return }
        
        if let view = view {
            let viewSize = view.bounds.size
            
            let positionInWindow = event.locationInWindow
            let xpos = positionInWindow.x
            let ypos = positionInWindow.y
            
            let xDistanceToCenter = (xpos / viewSize.width) - 0.5
            let yDistanceToCenter = (ypos / viewSize.height) - 0.5
            
            mouseTracker.position = positionInWindow
            mouseTracker.offset = CGPoint(x: xDistanceToCenter, y: yDistanceToCenter)
        }
        
        let baseLayer = tilemap.baseLayer

        // get the position relative as drawn by the
        let positionInScene = event.location(in: self)
        let positionInLayer = baseLayer.mouseLocation(event: event)
        let coord = baseLayer.coordinateAtMouseEvent(event: event)
        let validCoord = baseLayer.isValid(Int(coord.x), Int(coord.y))
        
        // query nodes under the cursor to update the properties label
        var propertiesInfoString = ""
        let positionInMap = event.location(in: tilemap)
        let tiledObjectsUnderCursor = tilemap.renderableObjectsAt(point: positionInMap)
        
        if (tiledObjectsUnderCursor.count) > 0 {
            propertiesInfoString = tiledObjectsUnderCursor.first!.description
        }
        
        // update the mouse tracking node
        mouseTracker.position = positionInScene
        mouseTracker.zPosition = tilemap.lastZPosition * 10
        mouseTracker.coord = coord
        mouseTracker.isValid = validCoord
        
        if (liveMode == true) && (isPaused == false) {
            self.addTileToWorld(Int(coord.x), Int(coord.y))
        }
        
        let coordDescription = "\(Int(coord.x)), \(Int(coord.y))"
        updateTileInfo(msg: "Coord: \(coordDescription), \(positionInLayer.roundTo())")
        updatePropertiesInfo(msg: propertiesInfoString)
        
        
        //let nodesUnderCursor = nodes(at: positionInScene).filter( { $0 as? TileShape != nil }) as! [TileShape]
        //let tilesUnderCursor = nodesUnderCursor.filter( { $0.useLabel == true } )
    }

    override open func mouseDragged(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scenePositionChanged(event)
    }
    
    override open func mouseUp(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseUp(with: event)
        selected = []
    }
    
    override open func scrollWheel(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scrollWheel(with: event)
    }
    
    override open func keyDown(with event: NSEvent) {
        self.keyboardEvent(eventKey: event.keyCode)
    }


    /**
     Remove old tracking views and add the current.
    */
    open func updateTrackingViews(){
        if let view = self.view {
            let options = [NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.activeAlways] as NSTrackingAreaOptions
            // clear out old tracking areas
            for oldTrackingArea in view.trackingAreas {
                view.removeTrackingArea(oldTrackingArea)
            }
            
            let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: self, userInfo: nil)
            view.addTrackingArea(trackingArea)
            
            
            if let cameraNode = cameraNode {
                updateCameraInfo(msg: cameraNode.description)
            }
        }
    }
    
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
            tilemap.layers.forEach { layer in
                print("layer: \(layer.path)")
            }
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
                layer.run(fadeAction, completion: {
                    print("layer: \"\(layer.layerName)\"")
                })
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
        
        // 'p' pauses the scene
        if eventKey == 0x23 {
            self.isPaused = !self.isPaused
            print(" → paused: \(self.isPaused)")
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
            self.enumerateChildNodes(withName: "*") {   // was //*
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
        
        // 'i' shows the center point of each tile
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
                fadeTime += 0.02
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
            print("➜ drawing map bounds: \(tilemap.frame.shortDescription)")
            tilemap.drawBounds()
        }
        
        // 't' runs a custom command
        if eventKey == 0x11 {
            print(" ○ clearing tile textures...")
            tilemap.tileLayers().filter( { $0.graph != nil } ).forEach { $0.getTiles().forEach { $0.texture = nil }}
        }
        
        // 'u' runs a custom command
        if eventKey == 0x20 {
            print(" ○ updating tile textures...")
            tilemap.tileLayers().filter( { $0.graph != nil } ).forEach { $0.getTiles().forEach { $0.update() }}
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
        
        // 'z' is a custom test
        if eventKey == 0x06 {

        }
        
        // '↑' clamps layer positions
        if eventKey == 0x7e {
            let scaleFactor =  getContentScaleFactor()
            var nodesUpdated = 0
            tilemap.enumerateChildNodes(withName: "*") {
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


open class MouseTracker: SKNode {
    
    private var label = SKLabelNode(fontNamed: "Courier")
    private var shadow = SKLabelNode(fontNamed: "Courier")
    private var shadowOffset: CGFloat = 1
    private var circle = SKShapeNode()
    private let scaleAction = SKAction.scale(by: 1.55, duration: 0.025)
    private let scaleSequence: SKAction
    
    private let scaleSize: CGFloat = 8
    
    public var coord: CGPoint = .zero {
        didSet {
            label.text = "(\(Int(coord.x)), \(Int(coord.y)))"
            shadow.text = label.text
        }
    }
    
    public var fontSize: CGFloat = 12 {
        didSet {
            label.fontSize = fontSize
            shadow.fontSize = label.fontSize
        }
    }
    
    public var isValid: Bool = false {
        didSet {
            guard oldValue != isValid else { return }
            circle.run(scaleSequence)
            circle.fillColor = (isValid == true) ? SKColor(hexString: "#84EC1C") : SKColor(hexString: "#FE2929")
        }
    }
    
    public var radius: CGFloat = 4 {
        didSet {
            circle = SKShapeNode(circleOfRadius: radius)
        }
    }
    
    public var offset: CGPoint = .zero {
        didSet {
            let ox = lerp(start: 0, end: 48, t: -offset.x)
            let oy = lerp(start: 0, end: 48, t: -offset.y)
            
            //label.position.x = offset.x * -48
            //label.position.y = offset.y * -48
            
            label.position.x = ox * 1.5
            label.position.y = oy
            
            //print("offset: \(label.position.roundTo())")
        }
    }
    
    
    override public init() {
        scaleSequence = SKAction.sequence([scaleAction, scaleAction.reversed()])
        super.init()
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func update() {
        circle = SKShapeNode(circleOfRadius: radius)
        addChild(circle)
        
        addChild(label)
        label.addChild(shadow)
        shadow.zPosition = label.zPosition - 1        
        fontSize = scaleSize * 1.5
        
        circle.strokeColor = .clear
        label.fontSize = fontSize
        shadow.fontSize = fontSize
        shadow.fontColor = SKColor.black.withAlphaComponent(0.7)
        
        shadow.position.x += shadowOffset
        shadow.position.y -= shadowOffset
    }
}
