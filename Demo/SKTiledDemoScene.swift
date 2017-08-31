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

    /// objects stored for debugging
    internal var currentLayer: SKTiledLayerObject?
    internal var currentTile: SKTile?
    internal var currentVectorObject: SKTileObject?

    internal var selected: [SKTiledLayerObject] = []

    internal var clickshapes: Set<TileShape> = []
    internal var pathshapes: Set<TileShape> = []
    internal var cleanup: Set<TileShape> = []

    internal var graphCoordinates: [CGPoint] = []
    internal var currentPath: [GKGridGraphNode] = []

    /// Cleanup tile shapes queue
    internal let cleanupQueue = DispatchQueue(label: "com.sktiled.cleanup", qos: .background)

    internal var editMode: Bool = false
    
    /// Highlight tiles under the mouse
    internal var liveMode: Bool = false {
        didSet {
            guard oldValue != liveMode else { return }
            self.cleanupTileShapes()
            self.graphCoordinates = []
        }
    }

    /// Current coordinate for mouse/touch location.
    internal var currentCoordinate: CGPoint = .zero {
        didSet {
            guard oldValue != currentCoordinate else { return }
            self.cleanupTileShapes(coord: currentCoordinate)
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
        #if os(OSX)
        updateTrackingViews()
        #endif
        updateHud(tilemap)
    }

    func getTilesAt(coord: CGPoint) -> [SKTile] {
        var result: [SKTile] = []
        guard let tilemap = tilemap else { return result }
        let tileLayers = tilemap.tileLayers(recursive: true).reversed().filter({ $0.visible == true })
        for tileLayer in tileLayers {
            if let tile = tileLayer.tileAt(coord: coord) {
                result.append(tile)
            }
        }
        return result
    }

    func renderableNodesAt(point: CGPoint) -> [SKNode] {
        var result: [SKNode] = []
        let nodes = self.nodes(at: point)
        for node in nodes {
            if node is SKTile {
                result.append(node)
            }

            if node is SKTileObject {
                result.append(node)
            }
        }
        return result
    }

    /**
     Add a temporary tile shape to the world at the given coordinate.

     - parameter x:            `Int` x-coordinate.
     - parameter y:            `Int` y-coordinate.
     - parameter role:         `TileShape.DebugRole` tile display role.
     - parameter weight:       `CGFloat` pathfinding weight.
     */
    func addTileToWorld(_ x: Int, _ y: Int,
                        role: TileShape.DebugRole = .none,
                        weight: Float = 1) -> TileShape? {

        guard let tilemap = tilemap else { return nil }

        // validate the coordinate
        let layer = tilemap.defaultLayer
        let validCoord = layer.isValid(x, y)

        let coord = CGPoint(x: x, y: y)

        let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledObjectColors.crimson
        let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)

        // add debug tile shape
        let tile = TileShape(layer: layer, coord: coord, tileColor: tileColor, role: role, weight: weight)

        tile.zPosition = lastZosition
        let tilePosition = layer.pointForCoordinate(x, y)
        tile.position = tilemap.convert(tilePosition, from: layer)
        tilemap.addChild(tile)


        if (role == .highlight) {
            let fadeAction = SKAction.fadeOut(withDuration: 0.4)
            tile.run(fadeAction, completion: {
                tile.removeFromParent()
            })
        }

        return tile

    }

    func buildPath(start: int2, end: int2) {

    }

    // MARK: - Deinitialization
    deinit {
        // Deregister for scene updates
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "updateCoordinate"), object: nil)

        removeAllActions()
        removeAllChildren()
    }

    // MARK: - Demo

    func setupDemoLevel(fileNamed: String) {
        guard let tilemap = tilemap else { return }

        let walkableTiles = tilemap.getTilesWithProperty("walkable", true)
        let walkableString = (walkableTiles.isEmpty == true) ? "" : ", \(walkableTiles.count) walkable tiles."
        log("setting up level: \"\(fileNamed)\"\(walkableString)", level: .info)

        switch fileNamed {

        case "dungeon-16x16.tmx":
            if let upperGraphLayer = tilemap.tileLayers(named: "Graph-Upper").first {
                _ = upperGraphLayer.initializeGraph(walkable: walkableTiles)
            }

            if let lowerGraphLayer = tilemap.tileLayers(named: "Graph-Lower").first {
                _ = lowerGraphLayer.initializeGraph(walkable: walkableTiles)
            }

        case "graphtest-8x8.tmx":
            if let graphLayer = tilemap.tileLayers(named: "Graph").first {
                _ = graphLayer.initializeGraph(walkable: walkableTiles)
            }

        case "pacman.tmx":
            if let graphLayer = tilemap.tileLayers(named: "Graph").first {
                if let graph = graphLayer.initializeGraph(walkable: walkableTiles) {

                    // connect the two tunnels
                    if let leftTunnel = graph.node(atGridPosition: int2(0, 17) ) {
                        if let rightTunnel = graph.node(atGridPosition: int2(27, 17)) {
                            leftTunnel.addConnections(to: [rightTunnel], bidirectional: true)
                        }
                    }
                }
            }

        default:
            return
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

    public func updateCameraInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": msg])
    }

    public func updatePauseInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["pauseInfo": msg])
    }

    public func updateIsolatedInfo(msg: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["isolatedInfo": msg])
    }

    /**
     Send a command to the UI to update status.

     - parameter command:  `String` command string.
     - parameter duration: `TimeInterval` how long the message should be displayed (0 is indefinite).
     */
    public func updateCommandString(_ command: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCommandString"), object: nil, userInfo: ["command": command, "duration": duration])
        }
    }

    /**
     Callback to remove coordinates.
     
     - parameter notification: `Notification` notification center callback.
     */
    public func updateCoordinate(notification: Notification) {
        let tempCoord = CGPoint(x: notification.userInfo!["x"] as! Int,
                                y: notification.userInfo!["y"] as! Int)

        guard (tempCoord != currentCoordinate) else { return }
        currentCoordinate = tempCoord
    }

    /**
     Update HUD elements when the view size changes.
     
     - parameter map: `SKTilemap?` tile map.
     */
    public func updateHud(_ map: SKTilemap?) {
        guard let map = map else { return }
        updateMapInfo(msg: map.description)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateWindowTitle"), object: nil, userInfo: ["wintitle": map.url.lastPathComponent])
    }

    /**
     Plot a path between the last two points clicked.
     */
    func plotNavigationPath() {
        currentPath = []
        guard (graphCoordinates.count == 2) else { return }

        // cleanup

        let startPoint = graphCoordinates.first!.toVec2
        let endPoint = graphCoordinates[1].toVec2

        for (_, graph) in graphs {
            if let startNode = graph.node(atGridPosition: startPoint) {
                if let endNode = graph.node(atGridPosition: endPoint) {
                    currentPath = startNode.findPath(to: endNode) as! [GKGridGraphNode]
                }
            }
        }
    }

    /**
     Cleanup all tile shapes outside of the given coordinate.
     
     - parameter coord: `CGPoint?` current focus coord.
     */
    func cleanupTileShapes(coord: CGPoint? = nil) {
        // cleanup everything
        guard let currentCoord = coord else {
            self.enumerateChildNodes(withName: "//*") { node, _ in
                if let tile = node as? TileShape {
                    self.cleanup.insert(tile)
                }
            }
            return
        }

        self.enumerateChildNodes(withName: "//*") { node, _ in

            if let tile = node as? TileShape {

                switch tile.role {
                case .pathfinding:
                    break
                default:

                    // if focus coordinate has changed, initialize all of the current tile shapes
                    if (tile.coord != currentCoord) {
                        if (tile.initialized == false) {
                            if self.clickshapes.contains(tile) {
                                tile.initialized = true
                            }
                        }
                    } else {
                        if (tile.initialized == true) {
                            tile.interactions += 1
                        }
                    }

                }
            }
        }
    }

    /**
     Cleanup all tile shapes representing the current path.
     */
    open func cleanupPathfindingShapes() {
        // clean the current path shapes...
        for pathshape in self.pathshapes {
            let fadeAction = SKAction.fadeOut(withDuration: 0.2)
            pathshape.run(fadeAction, completion: {
                self.pathshapes.remove(pathshape)
                self.cleanup.insert(pathshape)
            })
        }
    }

    /**
     Called before each frame is rendered.

     - parameter currentTime: `TimeInterval` update interval.
     */
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        for shape in self.clickshapes {
            // move moused-over shapes to cleanup...
            if (shape.initialized == true) && (shape.interactions > 0) {

                let fadeAction = SKAction.fadeOut(withDuration: 0.2)
                shape.run(fadeAction, completion: {
                    self.clickshapes.remove(shape)
                    self.cleanup.insert(shape)
                })
            }
        }

        // cleanup everything in the queue
        for tile in self.cleanup {
            self.cleanupQueue.async {
                self.cleanup.remove(tile)
                tile.removeFromParent()
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
            let tile = addTileToWorld(Int(coord.x), Int(coord.y), role: .coordinate)

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

        let coord = defaultLayer.coordinateAtMouseEvent(event: event)
        let tileShapesUnderCursor = tileShapesAt(event: event)

        for tile in tileShapesUnderCursor where tile.role == .coordinate {
            tile.interactions += 1
        }

        if (liveMode == true) && (isPaused == false) {

            if (event.clickCount > 1) {

                if graphCoordinates.contains(coord) {
                    cleanupPathfindingShapes()
                    return
                }

                graphCoordinates.append(coord)
                if graphCoordinates.count > 2 {

                    cleanupPathfindingShapes()
                    graphCoordinates = graphCoordinates.reversed()[0...1].reversed()
                }

                if (graphCoordinates.count == 2) {
                    plotNavigationPath()
                    if (currentPath.isEmpty == false) {
                        for node in currentPath {
                            let xcoord = Int(node.gridPosition.x)
                            let ycoord = Int(node.gridPosition.y)

                            var nodeWeight: Float = 1
                            if let weightedNode = node as? SKTiledGraphNode {
                                nodeWeight = weightedNode.weight
                            }

                            if let tile = addTileToWorld(xcoord, ycoord, role: .pathfinding, weight: nodeWeight) {
                                self.pathshapes.insert(tile)
                            }
                        }
                    }
                }
            } else {
                // highlight the current coordinate
                if let tile = addTileToWorld(Int(coord.x), Int(coord.y), role: .coordinate) {
                    self.clickshapes.insert(tile)
                }
            }
        }
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

            let positionInWindow = event.locationInWindow
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
        var propertiesInfoString = "--"
        let tileShapesUnderCursor = tileShapesAt(event: event)

        currentTile = nil
        currentVectorObject = nil

        var currentLayerSet = false
        if currentLayer != nil {
            if currentLayer!.isolated == true {
                currentLayerSet = true
            }
        }

        if currentLayerSet == false {
            currentLayer = nil
        }

        // let renderableNodes = renderableNodesAt(point: positionInScene)
        if let focusObject = tilemap.focusObjects.first {
            propertiesInfoString = focusObject.description


            if let firstTile = focusObject as? SKTile {
                currentTile = firstTile
                if currentLayerSet == false {
                    currentLayer = firstTile.layer
                }
            }

            if let firstObject = focusObject as? SKTileObject {
                currentVectorObject = firstObject
                if currentLayerSet == false {
                    currentLayer = firstObject.layer
                }
            }
        }

        // update the mouse tracking node
        mouseTracker.position = positionInScene
        mouseTracker.zPosition = tilemap.lastZPosition * 10
        mouseTracker.coord = coord
        mouseTracker.isValid = validCoord


        if (tileShapesUnderCursor.isEmpty) {
            if (liveMode == true) && (isPaused == false) {
                _ = self.addTileToWorld(Int(coord.x), Int(coord.y), role: .highlight)
            }
        }

        // update the focused coordinate
        let coordDescription = "\(Int(coord.x)), \(Int(coord.y))"
        updateTileInfo(msg: "Coord: \(coordDescription), \(positionInLayer.roundTo())")
        updatePropertiesInfo(msg: propertiesInfoString)

        let x = Int(coord.x)
        let y = Int(coord.y)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCoordinate"), object: nil, userInfo: ["x": x, "y": y])


        // highlight tile & text objects
        if (liveMode == true) {
            if (currentVectorObject != nil) {
                if (currentVectorObject!.isRenderableType == true) {
                    currentVectorObject!.drawBounds(withColor: TiledObjectColors.coral, zpos: nil, duration: 0.2)
                    currentVectorObject = nil
                }
            }
        }
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

    override open func keyUp(with event: NSEvent) {
        super.keyUp(with: event)
    }

    open func tileShapesAt(event: NSEvent) -> [TileShape] {
        let positionInScene = event.location(in: self)
        return nodes(at: positionInScene).filter { $0 as? TileShape != nil } as! [TileShape]
    }

    /**
     Remove old tracking views and add the current.
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
            label.text = "x: \(Int(coord.x)), y: \(Int(coord.y))"
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
        let vector = (1 / -dy) * (fabs(dy) * 2)
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


extension SKTiledDemoScene {
    // MARK: - Delegate Methods
    /**
     Called when the camera positon changes.

     - parameter newPositon: `CGPoint` updated camera position.
     */
    override public func cameraPositionChanged(newPosition: CGPoint) {
        // TODO: remove this notification callback in master
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"),
                                        object: nil,
                                        userInfo: ["cameraInfo": cameraNode?.description ?? "nil"])
    }

    /**
     Called when the camera zoom changes.

     - parameter newZoom: `CGFloat` camera zoom amount.
     */
    override public func cameraZoomChanged(newZoom: CGFloat) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"),
                                        object: nil,
                                        userInfo: ["cameraInfo": cameraNode?.description ?? "nil"])
    }

    /**
     Called when the camera bounds updated.

     - parameter bounds:  `CGRect` camera view bounds.
     - parameter positon: `CGPoint` camera position.
     - parameter zoom:    `CGFloat` camera zoom amount.
     */
    override public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {
        // override in subclass
        log("camera bounds updated: \(bounds.roundTo()), pos: \(position.roundTo()), zoom: \(zoom.roundTo())",
            level: .debug)

    }

    #if os(iOS) || os(tvOS)
    /**
     Called when the scene is double-tapped. (iOS only)

     - parameter location: `CGPoint` touch location.
     */
    override public func sceneDoubleTapped(location: CGPoint) {
        log("scene was double tapped.", level: .debug)
        //self.isPaused = !self.isPaused
    }
    #else

    /**
     Called when the scene is double-clicked. (macOS only)

     - parameter event: `NSEvent` mouse click event.
     */
    override public func sceneDoubleClicked(event: NSEvent) {
        let location = event.location(in: self)
        log("mouse double-clicked at: \(location.shortDescription)", level: .debug)
    }

    /**
     Called when the mouse moves in the scene. (macOS only)

     - parameter event: `NSEvent` mouse event.
     */
    override public func mousePositionChanged(event: NSEvent) {
        //let location = event.location(in: self)
    }
    #endif

    // MARK: - Keyboard Events

    /**
     Run demo keyboard events (macOS).

     - parameter eventKey: `UInt16` event key.
     */
    public func keyboardEvent(eventKey: UInt16) {
        guard let view = view,
            let cameraNode = cameraNode,
            let tilemap = tilemap,
            let _ = worldNode else {
                return
        }

        // '→' advances to the next scene
        if eventKey == 0x7c {
            self.loadNextScene()
        }

        // '←' loads the previous scene
        if eventKey == 0x7B {
            self.loadPreviousScene()
        }

        // '1' sets the camera zoom to 100%
        if [0x12, 0x53].contains(eventKey) {
            cameraNode.setCameraZoom(1)
            updateCommandString("setting camera zoom at 100%", duration: 3.0)
        }

        // '2' sets the camera zoom to 200%
        if [0x13, 0x54].contains(eventKey) {
            cameraNode.setCameraZoom(2)
            updateCommandString("setting camera zoom at 200%", duration: 3.0)
        }

        // 'a' or 'f' fits the map to the current view
        if eventKey == 0x0 || eventKey == 0x3 {
            cameraNode.fitToView(newSize: view.bounds.size)
            updateCommandString("fitting map to view...", duration: 3.0)
        }

        // 'd' key is free
        if eventKey == 0x2 {
            print("path shapes: \(self.pathshapes)")
        }

        // 'g' shows the grid for the map default layer.
        if eventKey == 0x5 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "toggleMapDemoDrawGridBounds"), object: nil)
        }

        // 'h' shows/hides SpriteKit stats
        if eventKey == 0x04 {
            if let view = self.view {
                let debugState = !view.showsFPS

                view.showsFPS = debugState
                view.showsNodeCount = debugState
                view.showsDrawCount = debugState
                view.showsPhysics = debugState
                view.showsFields = debugState
            }
        }

        // 'i' isolates current layer under the mouse (macOS)
        if eventKey == 0x22 {
            if let currentLayer = currentLayer {
                let willIsolateLayer = (currentLayer.isolated == false)
                let command = (willIsolateLayer == true) ? "isolating layer: \"\(currentLayer.layerName)\"" : "restoring all layers"
                log(command, level: .debug)
                updateCommandString(command, duration: 3.0)

                // update the info label (macOS)
                let isolatedInfoString = (willIsolateLayer == true) ? "Isolating: \(currentLayer.description)" : ""
                updateIsolatedInfo(msg: isolatedInfoString)

                // isolate the layer
                currentLayer.isolateLayer()
            }
        }

        // 'l' toggles live mode
        if eventKey == 0x25 {
            let command = (self.liveMode == true) ? "disabling live mode" : "enabling live mode"
            updateCommandString(command, duration: 3.0)
            liveMode = !liveMode
        }

        // 'o' shows/hides object layers
        if eventKey == 0x1f {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "toggleMapObjectDrawing"), object: nil)
        }

        // 'p' pauses the scene
        if eventKey == 0x23 {
            self.isPaused = !self.isPaused
        }

        // 'r' reloads the scene
        if eventKey == 0xf {
            self.reloadScene()
        }
    }
}
