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

    public var uiScale: CGFloat = SKTiledContentScaleFactor
    var mouseTracker = MouseTracker()

    /// global information label font size.
    private let labelFontSize: CGFloat = 11

    internal var selected: [SKTiledLayerObject] = []
    internal var tileshapes: Set<TileShape> = []
    internal var editMode: Bool = false
    internal var liveMode: Bool = true                     // highlight tiles under the mouse

    internal let cleanupQueue = DispatchQueue(label: "com.sktiled.cleanup", qos: .userInteractive)

    internal var coordinate: CGPoint = .zero {
        didSet {
            guard oldValue != coordinate else { return }

            self.enumerateChildNodes(withName: "*") { node, _ in

                if let tile = node as? TileShape {
                    if (tile.coord != self.coordinate) {
                        if self.tileshapes.contains(tile) {
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

        #if os(macOS)
        updateTrackingViews()
        addChild(mouseTracker)
        mouseTracker.zPosition = 1000
        #endif

        NotificationCenter.default.addObserver(self, selector: #selector(updateCoordinate), name: NSNotification.Name(rawValue: "updateCoordinate"), object: nil)
    }

    override public func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        print("[SKTiledDemoScene]: `SKTiledDemoScene.didChangeSize`: \(oldSize.shortDescription)")
        #if os(OSX)
        updateTrackingViews()
        #endif
        updateHud(tilemap)
    }

    /**
     Add a tile shape to a layer at the given coordinate.

     - parameter layer:     `SKTiledLayerObject` layer object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    func addTileToLayer(_ layer: SKTiledLayerObject, _ x: Int, _ y: Int, useLabel: Bool=true)  {
        guard let tilemap = tilemap else { return  }

        // validate the coordinate
        let validCoord = layer.isValid(x, y)

        let coord = CGPoint(x: x, y: y)

        let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledObjectColors.crimson
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
        guard let tilemap = tilemap else { return }

        // validate the coordinate
        let layer = tilemap.defaultLayer
        let validCoord = layer.isValid(x, y)

        let coord = CGPoint(x: x, y: y)

        if (coord != coordinate) || (useLabel == true) {
            let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledObjectColors.crimson
            let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)

            // add debug tile shape

            let tile = TileShape(layer: layer, coord: coord, tileColor: tileColor, withLabel: useLabel)

            tile.zPosition = lastZosition
            let tilePosition = layer.pointForCoordinate(x, y)
            tile.position = tilemap.convert(tilePosition, from: layer)
            tilemap.addChild(tile)

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

    // MARK: - Demo

    func setupDemoLevel(fileNamed: String) {
        guard let tilemap = tilemap else { return }


        switch fileNamed {
        case "pacman-8x8.tmx":
            setupPacman()
        case "tetris-dynamics.tmx":
            setupTetris()
        case "ortho4-16x16.tmx":
            setupOrtho4()
        case "staggered-64x33.tmx":
            setupStaggered()
        default:
            return
        }
    }

    func setupPacman() {


        guard let playerGraphLayer = tilemap.tileLayers(named: "Player").first else {
            log("layer \"layer\" does not exist.", level: .error)
            return
        }


        guard let ghostsGraphLayer = tilemap.tileLayers(named: "Ghosts").first else {
            log("layer \"Ghosts\" does not exist.", level: .error)
            return
        }


        guard let fruitGraphLayer = tilemap.tileLayers(named: "Fruit").first else {
            log("layer \"Fruit\" does not exist.", level: .error)
            return
        }


        for tileset in tilemap.tilesets {
            if tileset.hasKey("walkable") {
                if (tileset.keyValuePair(key: "walkable") != nil) {
                    let ids = tileset.integerArrayForKey("walkable")
                    for id in ids {
                        if let tiledata = tileset.getTileData(localID: id) {
                            tiledata.walkable = true
                        }
                    }
                }
            }
        }


        let playerWalkable = playerGraphLayer.getTiles().filter { $0.tileData.walkable == true }
        if (playerWalkable.isEmpty == false) {
            log("\"\(playerGraphLayer.layerName)\": walkable: \(playerWalkable.count)", level: .debug)
            _ = playerGraphLayer.initializeGraph(walkable: playerWalkable, obstacles: [], diagonalsAllowed: false)
        }


        let ghostWalkable = ghostsGraphLayer.getTiles().filter { $0.tileData.walkable == true }
        if (ghostWalkable.isEmpty == false) {
            log("\"\(ghostsGraphLayer.layerName)\": walkable: \(ghostWalkable.count)", level: .debug)
            _ = ghostsGraphLayer.initializeGraph(walkable: ghostWalkable, obstacles: [], diagonalsAllowed: false)
        }


        let fruitWalkable = fruitGraphLayer.getTiles().filter { $0.tileData.walkable == true }
        if (fruitWalkable.isEmpty == false) {
            log("\"\(fruitGraphLayer.layerName)\": walkable: \(fruitWalkable.count)", level: .debug)
            _ = fruitGraphLayer.initializeGraph(walkable: fruitWalkable, obstacles: [], diagonalsAllowed: false)
        }

    }

    func setupTetris() {
        let lights = tilemap.getObjects(ofType: "Light")
        let fields = tilemap.getObjects(ofType: "Field")

        for lightObj in lights {
            let light = SKLightNode()
            addChild(light)
            light.position = convert(lightObj.position, from: lightObj)
            light.isEnabled = true
            light.lightColor = .white
            light.categoryBitMask = 1
            light.shadowColor = .black
            light.falloff = 0
        }

        for fieldObj in fields {
            let field = SKFieldNode()
            field.categoryBitMask = 1
            field.strength = 50
            addChild(field)
            field.position = convert(fieldObj.position, from: fieldObj)
        }

        tilemap.getObjects().forEach {
            if let tile = $0.tile {
                tile.shadowedBitMask = 1
                tile.shadowCastBitMask = 1
            }
        }
    }

    func setupOrtho4() {
        guard let graphLayer = tilemap.tileLayers(named: "Graph").first else {
            log("layer \"Graph\" does not exist.", level: .error)
            return
        }

        let walkable = graphLayer.getTiles().filter { $0.tileData.walkable == true }
        log("walkable tiles: \(walkable.count)", level: .debug)
        if (walkable.isEmpty == false) {
            log("\"\(graphLayer.layerName)\": walkable: \(walkable.count)", level: .debug)
            _ = graphLayer.initializeGraph(walkable: walkable, obstacles: [], diagonalsAllowed: false)
        }

        let chests = tilemap.getTiles(ofType: "chest")
        chests.forEach { $0.showBounds = true }

    }

    func setupStaggered() {
        guard let graphLayer = tilemap.tileLayers(named: "Graph").first else {
            log("layer \"Graph\" does not exist.", level: .error)
            return
        }

        let walkable = graphLayer.getTiles().filter { $0.tileData.walkable == true }
        log("walkable tiles: \(walkable.count)", level: .debug)
        if (walkable.isEmpty == false) {
            log("\"\(graphLayer.layerName)\": walkable: \(walkable.count)", level: .debug)
            _ = graphLayer.initializeGraph(walkable: walkable, obstacles: [], diagonalsAllowed: false)
        }
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

    /**
     Update HUD elements when the view size changes.
     */
    public func updateHud(_ map: SKTilemap?) {
        guard let map = map else { return }
        updateMapInfo(msg: map.description)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateWindowTitle"), object: nil, userInfo: ["wintitle": map.url.lastPathComponent])
    }

    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        self.enumerateChildNodes(withName: "//*") { node, _ in

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

    // MARK: - SKTilemapDelegate Callbacks

    override open func didReadMap(_ tilemap: SKTilemap) {
        log("map read: \"\(tilemap.mapName)\"", level: .debug)
        self.physicsWorld.speed = 1
    }

    override open func didAddTileset(_ tileset: SKTileset) {
        let imageCount = (tileset.isImageCollection == true) ? tileset.dataCount : 0
        let statusMessage = (imageCount > 0) ? "images: \(imageCount)" : "rendered: \(tileset.isRendered)"
        log("tileset added: \"\(tileset.name)\", \(statusMessage)", level: .debug)
    }

    override open func didRenderMap(_ tilemap: SKTilemap) {
        // update the HUD to reflect the number of tiles created
        updateHud(tilemap)
    }

    override open func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>) {
        super.didAddNavigationGraph(graph)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateUIControls"),
                                        object: nil, userInfo: ["hasGraphs": true])
    }
}


#if os(iOS) || os(tvOS)
// Touch-based event handling
extension SKTiledDemoScene {

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        let defaultLayer = tilemap.defaultLayer

        for touch in touches {

            // get the position in the defaultLayer
            let positionInLayer = defaultLayer.touchLocation(touch)

            let coord = defaultLayer.coordinateAtTouchLocation(touch)
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
        super.mouseDown(with: event)

        guard let tilemap = tilemap,
            let cameraNode = cameraNode else { return }

        cameraNode.mouseDown(with: event)

        let defaultLayer = tilemap.defaultLayer

        // get the position relative as drawn by the
        let positionInScene = event.location(in: self)
        let positionInLayer = defaultLayer.mouseLocation(event: event)
        let coord = defaultLayer.coordinateAtMouseEvent(event: event)

        // query nodes under the cursor to update the properties label
        var propertiesInfoString = ""
        let nodesUnderCursor = nodes(at: positionInScene).filter { $0 as? TileShape != nil } as! [TileShape]
        let tilesUnderCursor = nodesUnderCursor.filter { $0.useLabel == true }

        if (tilemap.isPaused == false) {
            // highlight the current coordinate
            if (tilesUnderCursor.isEmpty == false) {
                addTileToWorld(Int(coord.x), Int(coord.y), useLabel: true)
            }
        }

        // update the tile information label
        let coordDescription = "\(Int(coord.x)), \(Int(coord.y))"
        let coordStr = "Coord: \(coordDescription), \(positionInLayer.roundTo())"
        updateTileInfo(msg: coordStr)

        // tile properties output
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

    /**
     Highlight and get properties for objects at the current mouse position.
     
     - parameter event: `NSEvent` mouse event.
     */
    override open func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)

        guard let tilemap = tilemap else { return }

        if let view = view {
            let viewSize = view.bounds.size


            var positionInWindow = event.locationInWindow
            let xpos = positionInWindow.x
            let ypos = positionInWindow.y

            let dx = (xpos / viewSize.width) - 0.5
            let dy = (ypos / viewSize.height) - 0.5



            mouseTracker.position.x = positionInWindow.x * (3 * dx)
            mouseTracker.position.y = positionInWindow.y * (3 * dy)
            //mouseTracker.setOffset(dx: dx, dy: dy)
        }

        let defaultLayer = tilemap.defaultLayer

        // get the position relative as drawn by the
        let positionInScene = event.location(in: self)
        let positionInLayer = defaultLayer.mouseLocation(event: event)
        let coord = defaultLayer.coordinateAtMouseEvent(event: event)
        let validCoord = defaultLayer.isValid(Int(coord.x), Int(coord.y))

        // query nodes under the cursor to update the properties label
        var propertiesInfoString = ""
        let nodesUnderCursor = nodes(at: positionInScene).filter( { $0 as? TileShape != nil }) as! [TileShape]
        if (nodesUnderCursor.count) > 0 {
            if let tile = tilemap.firstTileAt(coord: coord) {
                propertiesInfoString = tile.tileData.description
            }
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

    override open func mouseEntered(with event: NSEvent) {
        self.mouseTracker.isHidden = false
    }

    override open func mouseExited(with event: NSEvent) {
        self.mouseTracker.isHidden = true
    }

    override open func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        guard let cameraNode = cameraNode else { return }
        cameraNode.scenePositionChanged(event)
    }

    override open func keyDown(with event: NSEvent) {
        self.keyboardEvent(eventKey: event.keyCode)
    }

    /**
     Remove old tracking views and add the current.

     // TODO: implement `NSView.updateTrackingAreas` (should be super)
    */
    open func updateTrackingViews() {
        if let view = self.view {
            let options: NSTrackingAreaOptions = [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .cursorUpdate]
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
}

#endif

// TODO: look at `NSTrackingCursorUpdate`
internal class MouseTracker: SKNode {

    private var label = SKLabelNode(fontNamed: "Courier")
    private var shadow = SKLabelNode(fontNamed: "Courier")
    private var shadowOffset: CGFloat = 1
    private var circle = SKShapeNode()
    private let scaleAction = SKAction.scale(by: 1.55, duration: 0.025)
    private let scaleSequence: SKAction

    private let scaleSize: CGFloat = 8

    var coord: CGPoint = .zero {
        didSet {
            label.text = "(\(Int(coord.x)), \(Int(coord.y)))"
            shadow.text = label.text
        }
    }

    var fontSize: CGFloat = 12 {
        didSet {
            label.fontSize = fontSize
            shadow.fontSize = label.fontSize
        }
    }

    var isValid: Bool = false {
        didSet {
            guard oldValue != isValid else { return }
            circle.run(scaleSequence)
            circle.fillColor = (isValid == true) ? SKColor(hexString: "#84EC1C") : SKColor(hexString: "#FE2929")
        }
    }

    var radius: CGFloat = 4 {
        didSet {
            circle = SKShapeNode(circleOfRadius: radius)
        }
    }

    override init() {
        scaleSequence = SKAction.sequence([scaleAction, scaleAction.reversed()])
        super.init()
        update()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setOffset(dx: CGFloat, dy: CGFloat) {
        var vector = (1 / -dy) * (fabs(dy) * 2)
        label.position.y = vector * (scaleSize * 2)
    }

    func update() {
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
        label.position.y += scaleSize * 2
    }
}
