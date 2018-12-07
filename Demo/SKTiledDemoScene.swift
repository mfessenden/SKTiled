//
//  SKTiledDemoScene.swift
//  SKTiled Demo
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.

import SpriteKit
import Foundation
import GameplayKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


// special scene class used for the demo
public class SKTiledDemoScene: SKTiledScene {

    weak internal var demoController: DemoController?
    public var uiScale: CGFloat = TiledGlobals.default.contentScale

    /// global information label font size.
    private let labelFontSize: CGFloat = 11

    /// objects stored for debugging
    internal var currentLayer: SKTiledLayerObject?
    internal var currentTile: SKTile?
    internal var currentVectorObject: SKTileObject?
    internal var currentProxyObject: TileObjectProxy?

    internal var selected: [SKTiledLayerObject] = []
    internal var focusObjects: [SKNode] = []

    internal var plotPathfindingPath: Bool = true
    internal var graphStartCoordinate: CGPoint?
    internal var graphEndCoordinate: CGPoint?

    internal var currentPath: [GKGridGraphNode] = []
    #if os(macOS)
    internal var mousePointer: MousePointer!
    #endif
    private let demoQueue = DispatchQueue(label: "com.sktiled.sktiledDemoScene.demoQueue", qos: .utility)


    override public var isPaused: Bool {
        willSet {
            let pauseMessage = (newValue == true) ? "Paused" : ""
            updatePauseInfo(msg: pauseMessage)
        }
    }

    override public func didMove(to view: SKView) {
        super.didMove(to: view)

        // game controllers
        setupControllerObservers()
        connectControllers()

        #if os(macOS)
        cameraNode.ignoreZoomClamping = false
        updateTrackingViews()
        #elseif os(iOS)
        cameraNode.ignoreZoomClamping = false
        #else
        cameraNode.ignoreZoomClamping = true
        #endif

        // allow gestures on iOS
        cameraNode.allowGestures = true
        #if os(macOS)
        if (mousePointer == nil) {
            mousePointer = MousePointer()
            addChild(mousePointer)
            cameraNode.addDelegate(mousePointer)
            mousePointer.isHidden = true
        }
        #endif
    }

    override public func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        #if os(macOS)
        updateTrackingViews()
        #endif
        updateHud(tilemap)

        guard let cameraNode = cameraNode else { return }
        updateCameraInfo(msg: cameraNode.description)
    }

    override public func willMove(from view: SKView) {
        #if os(macOS)
        // clear out old tracking areas
        for oldTrackingArea in view.trackingAreas {
            view.removeTrackingArea(oldTrackingArea)
        }
        #endif
    }

    /**
     Return tile nodes at the given point.

     - parameter coord: `CGPoint` event point.
     - returns: `[SKTile]` tile nodes.
     */
    func tilesAt(coord: CGPoint) -> [SKTile] {
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

    /**
     Return renderable nodes (tile & tile objects) at the given point.

     - parameter point: `CGPoint` event point.
     - returns: `[SKNode]` renderable nodes.
     */
    func renderableNodesAt(point: CGPoint) -> [SKNode] {
        var result: [SKNode] = []
        let nodes = self.nodes(at: point)
        for node in nodes {
            if (node is SKTileObject || node is SKTile) {
                result.append(node)
            }
        }
        return result
    }

    // MARK: - Demo

    /**
     Callback to the GameViewController to reload the current scene.
     */
    public func reloadScene() {
        // call back to the demo controller
        NotificationCenter.default.post(
            name: Notification.Name.Demo.ReloadScene,
            object: nil,
            userInfo: nil
        )
    }

    /**
     Callback to the GameViewController to load the next scene.
     */
    public func loadNextScene() {
        // call back to the demo controller
        NotificationCenter.default.post(
            name: Notification.Name.Demo.LoadNextScene,
            object: nil,
            userInfo: nil
        )
    }

    /**
     Callback to the GameViewController to reload the previous scene.
     */
    public func loadPreviousScene() {
        // call back to the demo controller
        NotificationCenter.default.post(
            name: Notification.Name.Demo.LoadPreviousScene,
            object: nil,
            userInfo: nil
        )
    }

    public func updateMapInfo(msg: String) {

        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil,
            userInfo: ["mapInfo": msg]
        )
    }

    public func updateTileInfo(msg: String) {
        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil,
            userInfo: ["tileInfo": msg]
        )
    }

    /**
     Update the tile properties debugging info.

     - parameter msg: `String` properties string.
     */
    public func updatePropertiesInfo(msg: String) {
        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil,
            userInfo: ["propertiesInfo": msg]
        )
    }

    public func updateCameraInfo(msg: String) {
        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil,
            userInfo: ["cameraInfo": msg]
        )
    }

    public func updatePauseInfo(msg: String) {
        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil, userInfo: ["pauseInfo": msg]
        )
    }

    public func updateScreenInfo(msg: String) {
        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil,
            userInfo: ["screenInfo": msg]
        )
    }

    /**
     Update the camera debugging info.

     - parameter sceneCamera:  `SKTiledSceneCamera?` scene camera.
     */
    public func updateCameraInfo(_ sceneCamera: SKTiledSceneCamera?) {
        var cameraInfo = "Camera:"
        if let sceneCamera = sceneCamera {
            cameraInfo = sceneCamera.description
        }

        NotificationCenter.default.post(
            name: Notification.Name.Camera.Updated,
            object: sceneCamera,
            userInfo: ["cameraInfo": cameraInfo]
        )
    }


    /**
     Send a command to the UI to update status.

     - parameter command:  `String` command string.
     - parameter duration: `TimeInterval` how long the message should be displayed (0 is indefinite).
     */
    public func updateCommandString(_ command: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {

            NotificationCenter.default.post(
                name: Notification.Name.Debug.CommandIssued,
                object: nil,
                userInfo: ["command": command, "duration": duration]
            )
        }
    }

    /**
     Update HUD elements when the view size changes.

     - parameter map: `SKTilemap?` tile map.
     */
    public func updateHud(_ map: SKTilemap?) {
        guard let map = map else { return }
        updateMapInfo(msg: map.description)
    }

    /**
     Plot a path between the last two points clicked.
     */
    func plotNavigationPath() {
        currentPath = []
        //guard (graphCoordinates.count == 2) else { return }
        guard let startCoord = graphStartCoordinate,
              let endCoord = graphEndCoordinate else { return }


        let startPoint = startCoord.toVec2
        let endPoint = endCoord.toVec2

        for (_, graph) in graphs {
            if let startNode = graph.node(atGridPosition: startPoint) {
                if let endNode = graph.node(atGridPosition: endPoint) {
                    currentPath = startNode.findPath(to: endNode) as! [GKGridGraphNode]
                }
            }
        }
    }

    /**
     Visualize the current grid graph path with a line.
     */
    func drawCurrentPath(withColor: SKColor = TiledObjectColors.lime) {
        guard let worldNode = worldNode,
              let tilemap = tilemap else { return }
        guard (currentPath.count > 2) else { return }

        worldNode.childNode(withName: "CURRENT_PATH")?.removeFromParent()

        // line dimensions
        let headWidth: CGFloat = tilemap.tileSize.height
        let lineWidth: CGFloat = tilemap.tileSize.halfWidth / 4

        let lastZPosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 4)
        var points: [CGPoint] = []

        for node in currentPath {
            let nodePosition = worldNode.convert(tilemap.pointForCoordinate(vec2: node.gridPosition), from: tilemap.defaultLayer)
            points.append(nodePosition)
        }

        // path shape
        let path = polygonPath(points, threshold: 16)
        let shape = SKShapeNode(path: path)
        shape.isAntialiased = false
        shape.lineWidth = lineWidth * 2
        shape.strokeColor = withColor
        shape.fillColor = .clear

        worldNode.addChild(shape)
        shape.zPosition = lastZPosition
        shape.name = "CURRENT_PATH"

        // arrowhead shape
        let arrow = arrowFromPoints(startPoint: points[points.count - 2], endPoint: points.last!, tailWidth: lineWidth, headWidth: headWidth, headLength: headWidth)
        let arrowShape = SKShapeNode(path: arrow)
        arrowShape.strokeColor = .clear
        arrowShape.fillColor = withColor
        shape.addChild(arrowShape)
        arrowShape.zPosition = lastZPosition
    }

    /**
     Cleanup all tile shapes representing the current path.
     */
    open func cleanupPathfindingShapes() {
        // cleanup pathfinding shapes
        guard let worldNode = worldNode else { return }
        worldNode.childNode(withName: "CURRENT_PATH")?.removeFromParent()
    }

    /**
     Called before each frame is rendered.

     - parameter currentTime: `TimeInterval` update interval.
     */
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)


        var coordinateMessage = ""
        if let graphStartCoordinate = graphStartCoordinate {
            coordinateMessage += "Start: \(graphStartCoordinate.shortDescription)"
            if (currentPath.isEmpty == false) {
                coordinateMessage += ", \(currentPath.count) nodes"
            }
        }
    }

    // MARK: - Delegate Callbacks

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

        // allow the cache to send notifications
        tilemap.dataStorage?.blockNotifications = false

        NotificationCenter.default.post(
            name: Notification.Name.Map.Updated,
            object: tilemap,
            userInfo: nil
        )
    }

    override open func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>) {
        super.didAddNavigationGraph(graph)
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


#if os(macOS)

// Mouse-based event handling
extension SKTiledDemoScene {

    override open func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
    }

    override open func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        guard let tilemap = tilemap,
            let cameraNode = cameraNode else { return }

        cameraNode.mouseDown(with: event)
        let defaultLayer = tilemap.defaultLayer
        _ = defaultLayer.coordinateAtMouseEvent(event: event)
    }

    /**
     Highlight and get properties for objects at the current mouse position.

     - parameter event: `NSEvent` mouse event.
     */
    override open func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)

        guard (view != nil), let tilemap = tilemap else {
            self.updateScreenInfo(msg: "--")
            return
        }

        DispatchQueue.main.async {
            
            let positionInScene = event.location(in: self)
            let positionInView = self.convertPoint(toView: positionInScene)

            // debug outputs
            var screenInfoString = "--"
            let viewPositionString = "view: \(positionInView.shortDescription)"
            let scenePositionString = "scene: \(positionInScene.shortDescription)"
            var layerPositionString = "layer: --"
            var coordInfoString = "coord: --"

            if let view = self.view {
                let viewSize = view.bounds.size

                let positionInWindow = event.locationInWindow
                let xpos = positionInWindow.x
                let ypos = positionInWindow.y

                _ = (xpos / viewSize.width) - 0.5
                _ = (ypos / viewSize.height) - 0.5
            }

            let defaultLayer = tilemap.defaultLayer

            // get the position relative as drawn by the
            _ = event.location(in: self)
            let positionInLayer = defaultLayer.mouseLocation(event: event)

            layerPositionString = "layer: \(positionInLayer.shortDescription)"

            let coord = defaultLayer.coordinateAtMouseEvent(event: event)
            let validCoord = defaultLayer.isValid(Int(coord.x), Int(coord.y))

            coordInfoString = "coord: \(coord.shortDescription)"
            self.graphEndCoordinate = (validCoord == true) ? coord : nil

            if (self.graphEndCoordinate != nil) {
                if (self.plotPathfindingPath == true) {
                    self.plotNavigationPath()
                    self.drawCurrentPath(withColor: tilemap.navigationColor)
                }
            }

            // query nodes under the cursor to update the properties label
            var propertiesInfoString = "--"

            self.currentTile = nil
            self.currentVectorObject = nil
            self.currentProxyObject = nil

            var currentLayerSet = false
            if (self.currentLayer != nil) {
                if (self.currentLayer!.isolated == true) {
                    currentLayerSet = true
                }
            }

            if currentLayerSet == false {
                self.currentLayer = nil
            }

            if let focusObject = self.focusObjects.first {
                
                if let firstTile = focusObject as? SKTile {
                    
                    propertiesInfoString = firstTile.description
                    self.currentTile = firstTile
                    if currentLayerSet == false {
                        self.currentLayer = firstTile.layer
                    }
                }

                if let firstObject = focusObject as? SKTileObject {
                    propertiesInfoString = firstObject.description
                    self.currentVectorObject = firstObject
                    if currentLayerSet == false {
                        self.currentLayer = firstObject.layer
                    }
                }

                if let firstProxy = focusObject as? TileObjectProxy {
                    self.currentProxyObject = firstProxy

                    if let proxyReference = firstProxy.reference {
                        self.currentVectorObject = proxyReference
                        propertiesInfoString = proxyReference.description
                    }
                }
            }


            // update the focused coordinate
            let coordDescription = "\(Int(coord.x)), \(Int(coord.y))"

            self.updateTileInfo(msg: "Coord: \(coordDescription), \(positionInLayer.roundTo())")
            self.updatePropertiesInfo(msg: propertiesInfoString)

            // debugging
            let outputArray = [viewPositionString, scenePositionString, layerPositionString, coordInfoString]
            screenInfoString = outputArray.joined(separator: ", ")

            // send the label data to the view controller
            self.updateScreenInfo(msg: screenInfoString)
        }
    }

    override open func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        guard let cameraNode = cameraNode else { return }
        cameraNode.scenePositionChanged(with: event)
    }

    override open func mouseEntered(with event: NSEvent) {
        mousePointer.isHidden = false
    }

    override open func mouseExited(with event: NSEvent) {
        mousePointer.isHidden = true
    }

    override open func keyDown(with event: NSEvent) {
        self.keyboardEvent(eventKey: event.keyCode)
    }

    override open func keyUp(with event: NSEvent) {
        super.keyUp(with: event)
    }

    /**
     Remove old tracking views and add the current.
    */
    open func updateTrackingViews() {
        if let view = self.view {

            let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .cursorUpdate]
            //let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]

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


extension SKTiledDemoScene {
    // MARK: - Delegate Methods

    /**
     Called when the camera positon changes.

     - parameter newPositon: `CGPoint` updated camera position.
     */
    override public func cameraPositionChanged(newPosition: CGPoint) {
        updateCameraInfo(cameraNode)
    }

    /**
     Called when the camera zoom changes.

     - parameter newZoom: `CGFloat` camera zoom amount.
     */
    override public func cameraZoomChanged(newZoom: CGFloat) {
        updateCameraInfo(cameraNode)
    }

    /**
     Called when the camera bounds updated.

     - parameter bounds:  `CGRect` camera view bounds.
     - parameter positon: `CGPoint` camera position.
     - parameter zoom:    `CGFloat` camera zoom amount.
     */
    override public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {
        // override in subclass
        log("camera bounds updated: \(bounds.roundTo()), pos: \(position.roundTo()), zoom: \(zoom.roundTo())", level: .debug)
        updateCameraInfo(cameraNode)
    }

    #if os(iOS)
    /**
     Called when the scene receives a double-tap event (iOS only).

     - parameter location: `CGPoint` touch event location.
     */
    override public func sceneDoubleTapped(location: CGPoint) {
        log("scene was double tapped.", level: .debug)
    }
    #endif

    #if os(macOS)
    /**
     Called when the scene is double-clicked (macOS only).

     - parameter event: `NSEvent` mouse click event.
     */
    override public func sceneDoubleClicked(event: NSEvent) {
        let location = event.location(in: self)
        log("mouse double-clicked at: \(location.shortDescription)", level: .debug)
    }

    /**
     Called when the mouse moves in the scene (macOS only).

     - parameter event: `NSEvent` mouse event.
     */
    override public func mousePositionChanged(event: NSEvent) {
        guard let tilemap = tilemap else { return }
        
        let locationInMap = event.location(in: tilemap)
        let nodesUnderCursor = tilemap.nodes(at: locationInMap)

        demoQueue.async {
            // populate the focus objects array
            self.focusObjects = nodesUnderCursor.filter { node in
                (node as? SKTiledGeometry != nil)
            }

            // call back to the view controller
            DispatchQueue.main.async {
                
                if !self.focusObjects.isEmpty {
            
                    NotificationCenter.default.post(
                        name: Notification.Name.Demo.FocusObjectsChanged,
                        object: self.focusObjects,
                        userInfo: ["tilemap": tilemap]
                    )
                

                    var currentTile: SKTile?
                    var currentObject: TileObjectProxy?


                    let doShowTileBounds = TiledGlobals.default.debug.mouseFilters.contains(.tilesUnderCursor)
                    let proxyIsFocused = (tilemap.showObjects == false) ? TiledGlobals.default.debug.mouseFilters.contains(.objectsUnderCursor) : false

                    
                    for object in self.focusObjects {

                        if let tile = object as? SKTile {
                            if (currentTile == nil) {
                                currentTile = tile
                                continue
                            }
                        }

                        if let obj = object as? SKTileObject {
                            if let proxy = obj.proxy {
                                if (currentObject == nil) {
                                    currentObject = proxy
                                    proxy.isFocused = proxyIsFocused
                                    continue
                                }
                            }
                        }


                        if let proxy = object as? TileObjectProxy {
                            currentObject = proxy
                            proxy.isFocused = proxyIsFocused
                            continue
                        }
                    }

                    if let currentTile = currentTile {

                        NotificationCenter.default.post(
                            name: Notification.Name.Demo.TileUnderCursor,
                            object: currentTile,
                            userInfo: nil
                        )
                    }


                    if let currentObject = currentObject {
                        if let object = currentObject.reference {
                            NotificationCenter.default.post(
                                name: Notification.Name.Demo.ObjectUnderCursor,
                                object: object,
                                userInfo: nil
                            )
                        }
                    }


                    currentTile?.frameColor = TiledGlobals.default.debug.tileHighlightColor
                    currentTile?.highlightColor = TiledGlobals.default.debug.tileHighlightColor
                    currentTile?.showBounds = doShowTileBounds
                }
            }
        }
    }


    // MARK: - Keyboard Events

    /**
     Run demo keyboard events (macOS).

     - parameter eventKey: `UInt16` event key.
     */
    public func keyboardEvent(eventKey: UInt16) {
        guard let view = view else {
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

        // '↑' raises the speed
        if eventKey == 0x7e {
            self.speed += 0.2
            updateCommandString("scene speed: \(speed.roundTo())", duration: 1.0)
        }

        // '↓' lowers the speed
        if eventKey == 0x7d {
            self.speed -= 0.2
            updateCommandString("scene speed: \(speed.roundTo())", duration: 1.0)
        }

        // 'h' shows/hides SpriteKit stats
        if eventKey == 0x04 {
            demoController?.toggleRenderStatistics()
        }

        // 'k' clears the scene
        if eventKey == 0x28 {
            updateCommandString("clearing scene...", duration: 3.0)
            
            NotificationCenter.default.post(
                name: Notification.Name.Demo.FlushScene,
                object: nil
            )
        }

        // 'p' pauses the scene
        if eventKey == 0x23 {
            self.isPaused = !self.isPaused
        }

        // 'r' reloads the scene
        if eventKey == 0xf {
            self.reloadScene()
        }

        guard let cameraNode = cameraNode else {
            return
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
            cameraNode.fitToView(newSize: view.bounds.size, transition: 0.25)
            updateCommandString("fitting map to view...", duration: 3.0)
        }

        // 'c' adjusts the camera zoom clamp value
        if eventKey == 0x8 {
            var newClampValue: CameraZoomClamping = .none
            switch cameraNode.zoomClamping {
            case .none:
                newClampValue = .tenth
            case .tenth:
                newClampValue = .quarter
            case .quarter:
                newClampValue = .half
            case .half:
                newClampValue = .third
            case .third:
                newClampValue = .none
            }
            self.cameraNode.zoomClamping = newClampValue
            updateCommandString("camera zoom clamping: \(newClampValue)", duration: 1.0)
        }

        guard let tilemap = tilemap,
            (worldNode != nil) else {
            return
        }

        // 'e' turns off effects rendering
        if eventKey == 0xe {
            NotificationCenter.default.post(
                name: Notification.Name.Debug.MapEffectsRenderingChanged,
                object: nil
            )
        }

        // 'g' shows the grid for the map default layer.
        if eventKey == 0x5 {
            NotificationCenter.default.post(
                name: Notification.Name.Debug.MapDebuggingChanged,
                object: nil
            )
        }

        // 'i' isolates current layer under the mouse (macOS)
        if eventKey == 0x22 {

            var command = "restoring all layers"

            if let currentLayer = currentLayer {
                let willIsolateLayer = (currentLayer.isolated == false)
                command = (willIsolateLayer == true) ? "isolating layer: \"\(currentLayer.layerName)\"" : "restoring all layers"
                log(command, level: .debug)

                // isolate the layer
                currentLayer.isolateLayer(duration: 0.25)

            // no layer selected
            } else {
                tilemap.getLayers().forEach { layer in
                    if (layer.isolated == true) {
                        layer.isolateLayer(duration: 0.25)
                    }
                }
            }

            updateCommandString(command, duration: 3.0)

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
        
        // 'o' shows/hides objects
        if eventKey == 0x1f {

            NotificationCenter.default.post(
                name: Notification.Name.Debug.MapObjectVisibilityChanged,
                object: nil
            )
        }


        // 't' toggles effects rasterization
        if eventKey == 0x11 {
            let currentValue = tilemap.shouldRasterize
            let commandString = (currentValue == false) ? "on" : "off"
            tilemap.shouldRasterize = !currentValue
            updateCommandString("rasterization: \(commandString)", duration: 1.0)

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }

        // 'u' cycles tile update mode
        if eventKey == 0x20 {
            demoController?.cycleTilemapUpdateMode()
        }

        // 'v' cycles time display for render stats
        if eventKey == 0x9 {
            let nextFormat: TiledGlobals.TimeDisplayMode = (TiledGlobals.default.timeDisplayMode == .seconds) ? .milliseconds : .seconds
            TiledGlobals.default.timeDisplayMode = nextFormat
            self.updateCommandString("setting render stats time format: \(TiledGlobals.default.timeDisplayMode)", duration: 2)

            // update controllers
            NotificationCenter.default.post(
                name: Notification.Name.Globals.Updated,
                object: nil,
                userInfo: nil
            )
        }
    }
    #endif
}


#if os(macOS)

/// Debugging HUD display that follows the macOS cursor
internal class MousePointer: SKNode {

    var fontName: String = "Courier"
    var fontSize: CGFloat = 12

    var color: SKColor = SKColor.white
    var receiveCameraUpdates: Bool = TiledGlobals.default.enableCameraCallbacks

    var currentTile: SKTile?
    var currentObject: SKTileObject?

    var sceneLabel: SKLabelNode?
    var coordLabel: SKLabelNode?
    var tileLabel:  SKLabelNode?


    var mouseFilters: TiledGlobals.DebugDisplayOptions.MouseFilters {
        return TiledGlobals.default.debug.mouseFilters
    }

    var lineCount: Int {
        var result = 0
        if (mouseFilters.contains(.tileCoordinates)) {
            result += 1
        }
        if (mouseFilters.contains(.sceneCoordinates)) {
            result += 1
        }

        if (mouseFilters.contains(.tileDataUnderCursor)) {
            result += 1
        }
        return result
    }

    var drawTileCoordinates: Bool {
        return mouseFilters.contains(.tileCoordinates)
    }

    var drawSceneCoordinates: Bool {
        return mouseFilters.contains(.sceneCoordinates)
    }

    var drawTileData: Bool {
        return mouseFilters.contains(.tileDataUnderCursor)
    }
    
    var drawLocalID: Bool {
        return mouseFilters.contains(.tileLocalID)
    }

    override init() {
        super.init()
        zPosition = 10000
        setupLabels()
        setupNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init()
        setupLabels()
        setupNotifications()
    }

    func setupLabels() {
        if (sceneLabel == nil) {
            sceneLabel = SKLabelNode(fontNamed: fontName)
            addChild(sceneLabel!)
        }
        if (coordLabel == nil) {
            coordLabel = SKLabelNode(fontNamed: fontName)
            addChild(coordLabel!)
        }
        if (tileLabel == nil) {
            tileLabel = SKLabelNode(fontNamed: fontName)
            addChild(tileLabel!)
        }
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderCursor), name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectUnderCursor), name: Notification.Name.Demo.ObjectUnderCursor, object: nil)
    }

    @objc func tileUnderCursor(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        currentTile = tile
    }

    @objc func objectUnderCursor(notification: Notification) {
        guard let object = notification.object as? SKTileObject else { return }
        currentObject = object
    }
    

    func draw(event: NSEvent, scene: SKScene) {
        
        if let tiledScene = scene as? SKTiledScene {
            if let tilemap = tiledScene.tilemap {

                let scenePosition = event.location(in: scene)

                self.position = scenePosition
                let coordinate = tilemap.coordinateAtMouseEvent(event: event)
                let coordColor = tilemap.isValid(coord: coordinate) ? color : TiledObjectColors.coral


                let labelStyle = NSMutableParagraphStyle()
                labelStyle.alignment = .center

                let defaultLabelAttributes = [
                    .font: NSFont(name: fontName, size: fontSize)!,
                    .foregroundColor: color,
                    .paragraphStyle: labelStyle
                    ] as [NSAttributedString.Key: Any]

                let coordAttributes = [
                    .font: NSFont(name: fontName, size: fontSize)!,
                    .foregroundColor: coordColor,
                    .paragraphStyle: labelStyle
                    ] as [NSAttributedString.Key: Any]


                var labelIndex = 0

                if (drawSceneCoordinates == true) {

                    let outputString = NSMutableAttributedString()

                    let labelText = "scene: "
                    let labelString = NSMutableAttributedString(string: labelText, attributes: defaultLabelAttributes)
                    let dataString = NSMutableAttributedString(string: scenePosition.shortDescription, attributes: defaultLabelAttributes)

                    outputString.append(labelString)
                    outputString.append(dataString)
                    if #available(OSX 10.13, *) {
                        sceneLabel?.attributedText = outputString
                    } else {
                        sceneLabel?.text = outputString.string
                    }
                    sceneLabel?.position.y = CGFloat(labelIndex - lineCount / 2) * self.fontSize + self.fontSize
                    labelIndex += 1
                }


                if (drawTileCoordinates == true) {

                    let outputString = NSMutableAttributedString()

                    let labelText = "coord: "
                    let labelString = NSMutableAttributedString(string: labelText, attributes: defaultLabelAttributes)
                    let dataString = NSMutableAttributedString(string: coordinate.shortDescription, attributes: coordAttributes)

                    outputString.append(labelString)
                    outputString.append(dataString)

                    if #available(OSX 10.13, *) {
                        coordLabel?.attributedText = outputString
                    } else {
                        coordLabel?.text = outputString.string
                    }
                    coordLabel?.position.y = CGFloat(labelIndex - lineCount / 2) * self.fontSize + self.fontSize
                    labelIndex += 1
                }

                tileLabel?.isHidden = true
                
                if (drawTileData == true) {
                    // tile id: 0, gid: 27
                    let outputString = NSMutableAttributedString()

                    if let currentTile = currentTile {
                        
                        let td = currentTile.tileData
                        let idsIdentical = (td.id == td.globalID)

                        var globalIDString = "\(td.globalID)"
                        var originalIDString: String? = nil
                        var idColor = color

                        switch currentTile.renderMode {
                        case .animated(let gid):
                            if (gid != nil) {
                                globalIDString = "\(gid!)"
                                originalIDString = "\(td.globalID)"
                                idColor = TiledObjectColors.dandelion
                            }

                        default:
                            break
                        }


                        let globalIDLabelAttributes = [
                            .font: NSFont(name: fontName, size: fontSize)!,
                            .foregroundColor: idColor,
                            .paragraphStyle: labelStyle
                            ] as [NSAttributedString.Key: Any]


                        // contruct the first part of the label
                        let tileDataString = (idsIdentical == true) ? "tile gid: " : (drawLocalID == true) ? "tile id: \(td.id), gid: " : "tile gid: "
                        let labelStringFirst = NSMutableAttributedString(string: tileDataString, attributes: defaultLabelAttributes)
                        outputString.append(labelStringFirst)

                        // tile id: 0, gid:
                        if let originalIDString = originalIDString {
                            // highlight the global id in yellow
                            let labelStringSecond = NSMutableAttributedString(string: globalIDString, attributes: globalIDLabelAttributes)
                            // after, in parenthesis, indicate the ORIGINAL gid
                            let labelStringThird = NSMutableAttributedString(string: " (\(originalIDString))", attributes: defaultLabelAttributes)
                            outputString.append(labelStringSecond)
                            outputString.append(labelStringThird)
                        
                        } else {
                            // just add the normal tile gid
                            let labelStringSecond = NSMutableAttributedString(string: globalIDString, attributes: defaultLabelAttributes)
                            outputString.append(labelStringSecond)
                        }
                        
                        tileLabel?.position.y = CGFloat(labelIndex - lineCount / 2) * self.fontSize + self.fontSize
                        tileLabel?.isHidden = false
                        if #available(OSX 10.13, *) {
                            tileLabel?.attributedText = outputString
                        } else {
                            tileLabel?.text = outputString.string
                        }
                        labelIndex += 1
                    }

                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.ObjectUnderCursor, object: nil)
    }
}


extension MousePointer: SKTiledSceneCameraDelegate {

    /**
     Called when the mouse moves in the scene.

     - parameter event: `NSEvent` mouse click event.
     */
    func mousePositionChanged(event: NSEvent) {
        guard let scene = scene else { return }
        self.draw(event: event, scene: scene)
    }

}
#endif
