//
//  SKTiledDemoScene.swift
//  SKTiled Demo
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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
import Foundation
import GameplayKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


// special scene class used for the demo
public class SKTiledDemoScene: SKTiledScene {

    /// Reference to demo scene manager.
    internal weak var demoController: TiledDemoController?

    /// global information label font size.
    private let labelFontSize: CGFloat = 11

    /// Currently focused layer.
    internal weak var currentLayer: TiledLayerObject?

    /// Currently focused proxy object.
    internal weak var currentProxyObject: TileObjectProxy?

    /// Array of selected layers.
    internal var selected: [TiledLayerObject] = []

    /// Currently focused objects.
    internal var focusObjects: [SKNode] = []

    /// Flag indicating that pathfinding graphs should be calculated.
    internal var plotPathfindingPath: Bool = true

    /// Start coordinate of path.
    internal var graphStartCoordinate: simd_int2?

    /// End coordinate of path.
    internal var graphEndCoordinate: simd_int2?

    /// Array of nodes in the current path.
    internal var currentPath: [GKGridGraphNode] = []

    #if os(macOS)
    internal weak var mousePointer: MousePointer?
    #endif

    private let demoQueue = DispatchQueue(label: "org.sktiled.sktiledDemoScene.demoQueue", qos: .utility)

    
    public override var isPaused: Bool {
        willSet {
            let pauseMessage = (newValue == true) ? "Paused" : ""
            let hideStatus = (newValue == true) ? false : true
            
            NotificationCenter.default.post(
                name: Notification.Name.DemoController.DemoStatusUpdated,
                object: nil,
                userInfo: ["status": pauseMessage, "isHidden": hideStatus, "color": tilemap?.highlightColor ?? SKColor.white]
            )
        }
    }

    deinit {
        // demo attributes
        selected = []
        focusObjects = []
        currentPath = []
        demoController = nil

        // superclass
        graphs = [:]
        camera?.removeFromParent()
        camera = nil
        tilemap = nil

        // remove notification observers
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)


        setupNotifications()

        // game controllers
        setupControllerObservers()
        //connectControllers()

        #if os(macOS)
        cameraNode?.ignoreZoomClamping = false
        updateTrackingViews()

        #elseif os(iOS)
        cameraNode?.ignoreZoomClamping = false
        #else
        cameraNode?.ignoreZoomClamping = true
        #endif

        // allow gestures on iOS
        cameraNode?.allowGestures = true
        
        #if os(macOS)
        if (mousePointer == nil) {
            let pointer = MousePointer()
            mousePointer = pointer
            addChild(pointer)
            cameraNode?.addDelegate(pointer)
            cameraNode?.addDelegate(TiledDemoDelegate.default)
        }
        #endif
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        #if os(macOS)
        updateTrackingViews()
        #endif
        updateHud(tilemap)

        guard let cameraNode = self.cameraNode else { return }
        updateCameraInfo(msg: cameraNode.description)
    }

    public override func willMove(from view: SKView) {
        #if os(macOS)
        // clear out old tracking areas
        for oldTrackingArea in view.trackingAreas {
            view.removeTrackingArea(oldTrackingArea)
        }
        #endif
    }

    // MARK: - Setup

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChanged), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
    }

    // MARK: - Event Handlers


    /// Called when the `Notification.Name.Demo.NodeSelectionChanged` notification is sent.
    ///
    ///  - expects a userInfo of `["nodes": [`SKNode`]]`
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let _ = userInfo["nodes"] as? [SKNode] else {
            return
        }

        // TODO: moved to `TiledDemoDelegate`
    }

    // TODO: test these

    /// Return tile nodes at the given point.
    ///
    /// - Parameter coord: event point.
    /// - Returns: tile nodes.
    func tilesAt(coord: simd_int2) -> [SKTile] {
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

    /// Return renderable nodes (tile & tile objects) at the given point.
    ///
    /// - Parameter point: event point.
    /// - Returns: renderable nodes.
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


    /// Callback to the `TiledDemoController` to reload the current scene.
    public func reloadScene() {
        demoController?.reloadScene()
    }

    /// Callback to the `TiledDemoController` to load the next scene.
    public func loadNextScene() {
        demoController?.loadNextScene()
    }

    /// Callback to the `TiledDemoController` to reload the previous scene.
    public func loadPreviousScene() {
        demoController?.loadPreviousScene()
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

    /// Update the tile properties debugging info.
    ///
    /// - Parameter msg: properties string.
    public func focusedObjectsChanged(msg: String) {
        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil,
            userInfo: ["focusedObjectData": msg]
        )
    }

    public func updateCameraInfo(msg: String) {
        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil,
            userInfo: ["cameraInfo": msg]
        )
    }

    public func updateScreenInfo(msg: String) {
        NotificationCenter.default.post(
            name: Notification.Name.Demo.UpdateDebugging,
            object: nil,
            userInfo: ["screenInfo": msg]
        )
    }

    /// Update the camera debugging info.
    ///
    /// - Parameter sceneCamera: scene camera.
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

    /// Update HUD elements when the view size changes.
    ///
    /// - Parameter map: tile map.
    public func updateHud(_ map: SKTilemap?) {
        guard let map = map else { return }
        updateMapInfo(msg: map.description)
    }

    /// Plot a path between the last two points clicked.
    func plotNavigationPath() {
        currentPath = []
        //guard (graphCoordinates.count == 2) else { return }
        guard let startCoord = graphStartCoordinate,
              let endCoord = graphEndCoordinate else { return }


        for (_, graph) in graphs {
            if let startNode = graph.node(atGridPosition: startCoord) {
                if let endNode = graph.node(atGridPosition: endCoord) {
                    currentPath = startNode.findPath(to: endNode) as! [GKGridGraphNode]
                }
            }
        }
    }

    /// Visualize the current grid graph path with a line.
    ///
    /// - Parameter withColor: path color.
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
            let nodePosition = worldNode.convert(tilemap.pointForCoordinate(coord: node.gridPosition), from: tilemap.defaultLayer)
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

    /// Cleanup all tile shapes representing the current path.
    open func cleanupPathfindingShapes() {
        // cleanup pathfinding shapes
        guard let worldNode = worldNode else { return }
        worldNode.childNode(withName: "CURRENT_PATH")?.removeFromParent()
    }

    /// Called before each frame is rendered.
    ///
    /// - Parameter currentTime: update interval.
    open override func update(_ currentTime: TimeInterval) {
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

    open override func didReadMap(_ tilemap: SKTilemap) {
        self.physicsWorld.speed = 1
    }

    open override func didAddTileset(_ tileset: SKTileset) {
        let imageCount = (tileset.isImageCollection == true) ? tileset.dataCount : 0
        let statusMessage = (imageCount > 0) ? "images: \(imageCount)" : "rendered: \(tileset.isRendered)"
        log("tileset added: '\(tileset.name)', \(statusMessage)", level: .debug)
    }

    open override func didRenderMap(_ tilemap: SKTilemap) {
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

    open override func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>) {
        super.didAddNavigationGraph(graph)
    }
}


#if os(iOS) || os(tvOS)
// Touch-based event handling
extension SKTiledDemoScene {


    /// Detect touch events.
    ///
    /// - Parameters:
    ///   - touches: touch events.
    ///   - event: gesture event.
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        let defaultLayer = tilemap.defaultLayer

        for touch in touches {

            // get the position in the defaultLayer
            let positionInLayer = defaultLayer.touchLocation(touch)

            // get the current coordinate for the touch event
            let touchCoordinate = defaultLayer.coordinateAtTouchLocation(touch: touch)


            // update the tile information label
            let coordStr = "Coord: \(touchCoordinate.shortDescription), \(positionInLayer.stringRoundedTo())"


            // call back to the controller via `UpdateDebugging` callback (DEMO ONLY)
            updateTileInfo(msg: coordStr)

            // tile properties output
            var propertiesInfoString = ""
            if let tile = tilemap.firstTileAt(coord: touchCoordinate) {
                propertiesInfoString = tile.tileData.description
            }

            focusedObjectsChanged(msg: propertiesInfoString)
        }
    }
}
#endif


#if os(macOS)

// Mouse-based event handling.
extension SKTiledDemoScene {

    /// Get properties for objects at the current mouse position.
    ///
    /// - Parameter event: mouse move event.
    open override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        // update the mouse pointer
        let location = event.location(in: self)
        mousePointer?.position = location
    }

    open override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        mousePointer?.isHidden = !TiledGlobals.default.debugDisplayOptions.mouseFilters.enableMousePointer
    }

    open override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        mousePointer?.isHidden = true
    }

    open override func keyDown(with event: NSEvent) {
        self.handleKeyboardEvent(event: event)
    }

    open override func keyUp(with event: NSEvent) {
        super.keyUp(with: event)
    }

    /// Update tracking views for macOS mouse events.
    public func updateTrackingViews() {
        if let view = self.view {
            let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .cursorUpdate]

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

    /// Remove tracking views.
    public func cleanTrackingViews() {
        if let view = self.view {
            for oldTrackingArea in view.trackingAreas {
                view.removeTrackingArea(oldTrackingArea)
            }
        }
    }
}

#endif


extension SKTiledDemoScene {
    
    // MARK: - Delegate Methods

    /// Called when the camera position changes.
    ///
    /// - Parameter newPosition: updated camera position.
    public override func cameraPositionChanged(newPosition: CGPoint) {
        updateCameraInfo(cameraNode)
    }

    /// Called when the camera zoom changes.
    ///
    /// - Parameter newZoom: camera zoom amount.
    public override func cameraZoomChanged(newZoom: CGFloat) {
        updateCameraInfo(cameraNode)
    }

    /// Called when the camera bounds updated.
    /// - Parameters:
    ///   - bounds: camera view bounds.
    ///   - position: camera position.
    ///   - zoom: camera zoom amount.
    public override func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {
        updateCameraInfo(cameraNode)
    }

    #if os(iOS)

    /// Called when the scene receives a double-tap event (iOS only).
    ///
    /// - Parameter location: touch event location.
    public override func sceneDoubleTapped(location: CGPoint) {
        log("scene was double tapped.", level: .debug)
    }
    #endif

    #if os(macOS)

    /// Called when the scene is clicked (macOS only).
    ///
    /// - Parameter event: mouse click event.
    public func sceneClicked(event: NSEvent) {
        let location = event.location(in: self)
        var logMessage = "mouse clicked at: \(location.coordDescription)"

        if let tilemap = tilemap {
            let positionInMap = event.location(in: tilemap)
            let mapCoordinate = tilemap.coordinateAtMouse(event: event)
            logMessage += ", map pos: \(positionInMap.coordDescription), coord: \(mapCoordinate.coordDescription)"
        }

        //log(logMessage, level: .debug)
    }


    /// Called when the scene is double-clicked (macOS only).
    ///
    /// - Parameter event: mouse click event.
    public override func sceneDoubleClicked(event: NSEvent) {
        let location = event.location(in: self)
        log("mouse double-clicked at: \(location.shortDescription)", level: .debug)
    }

    /// Mouse right-click event handler.
    ///
    /// - Parameter event: mouse event.
    open override func rightMouseDown(with event: NSEvent) {
        cameraNode?.rightMouseDown(with: event)
    }


    // MARK: - Keyboard Events

    /// Run demo keyboard events (macOS).
    ///
    /// - Parameter eventKey: event key.
    public func handleKeyboardEvent(event: NSEvent) {
        guard let view = view else {
            return
        }


        let eventKey = event.keyCode
        var eventChars = event.characters ?? "⋯"
        print("key pressed '\(eventChars)'")

        // '→' advances to the next scene
        if eventKey == 0x7c {
            self.loadNextScene()
            eventChars = "→"
        }

        // '←' loads the previous scene
        if eventKey == 0x7B {
            eventChars = "←"
            self.loadPreviousScene()
        }

        // '↑' raises the speed
        if eventKey == 0x7e {
            eventChars = "↑"
            self.speed += 0.2
            updateCommandString("scene speed: \(speed.stringRoundedTo())", duration: 1.0)
        }

        // '↓' lowers the speed
        if eventKey == 0x7d {
            eventChars = "↓"
            self.speed -= 0.2
            updateCommandString("scene speed: \(speed.stringRoundedTo())", duration: 1.0)
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


        // '+' and '-' zoom
        if [0x45, 0x4e, 0x1b, 0x18].contains(eventKey) {
            // decrease zoom...
            if [0x4e, 0x1b].contains(eventKey) {
                let newZoom = cameraNode.zoom - 0.5
                cameraNode.setCameraZoom(newZoom)
            } else {
                let newZoom = cameraNode.zoom + 0.5
                cameraNode.setCameraZoom(newZoom)
            }

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
            self.cameraNode?.zoomClamping = newClampValue
            updateCommandString("camera zoom clamping: \(newClampValue)", duration: 1.0)
        }


        guard let tilemap = tilemap,
              (worldNode != nil) else {
            return
        }
        
        // 'd' dumps the selected node(s)
        if eventKey == 0x02 {
            NotificationCenter.default.post(
                name: Notification.Name.Demo.DumpSelectedNodes,
                object: nil
            )
            updateCommandString("dumping selected nodes...", duration: 3.0)
        }
        


        // 'e' toggles effects rendering
        if eventKey == 0xe {
            NotificationCenter.default.post(
                name: Notification.Name.Debug.MapEffectsRenderingChanged,
                object: nil
            )


            let currentValue = tilemap.shouldEnableEffects
            let nextValueString: String = (!currentValue == true) ? "off" : "on"
            tilemap.shouldEnableEffects = !currentValue
            updateCommandString("toggling effects rendering: \(nextValueString)", duration: 3.0)
        }

        // 'g' shows the grid for the map default layer. Calls `DemoController.toggleMapDemoDrawGridAndBounds`.
        if eventKey == 0x5 {
            NotificationCenter.default.post(
                name: Notification.Name.Debug.MapDebugDrawingChanged,
                object: nil
            )
        }
        
        // 'i' isolates the selected object(s).
        if eventKey == 0x22 {
            
            NotificationCenter.default.post(
                name: Notification.Name.Demo.IsolateSelectedEnabled,
                object: nil
            )
            
            updateCommandString("isolating selected objects...", duration: 3.0)
        }


        /// 'l' tests the `DebugDrawableType.drawFrame` method.
        if eventKey == 0x25 {
            tilemap.getObjects().forEach { object in
                object.drawNodeBounds(with: object.frameColor, lineWidth: 1, fillOpacity: 0, duration: 2)
            }

            tilemap.drawNodeBounds(with: tilemap.frameColor, lineWidth: 1, fillOpacity: 0, duration: 2)
            updateCommandString("drawing object bounds...", duration: 3.0)
        }

        // 'o' shows/hides objects
        if eventKey == 0x1f {

            NotificationCenter.default.post(
                name: Notification.Name.Debug.MapObjectVisibilityChanged,
                object: nil
            )
        }
        
        // 's' clears the cache
        if eventKey == 0x01 {
            let layerName = "Floor"
            var interval: TimeInterval = 0.5
            if let layer = tilemap.getLayers(named: layerName).first as? SKTileLayer {
                updateCommandString("cannot find a layer named '\(layerName)'")
                for chunk in layer.chunks {
                    chunk.highlightNode(with: TiledObjectColors.random, duration: interval)
                    interval += 0.5
                }
            } else {
                updateCommandString("cannot find a layer named '\(layerName)'")
            }
        }

        // 't' toggles effects rasterization
        if eventKey == 0x11 {
            tilemap.shouldRasterize.toggle()
            updateCommandString("Tilemap rasterization: \(tilemap.shouldRasterize.valueAsOnOff)", duration: 1.0)

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap
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
            updateCommandString("setting render stats time format: \(TiledGlobals.default.timeDisplayMode)", duration: 2)

            // update controllers
            NotificationCenter.default.post(
                name: Notification.Name.Globals.Updated,
                object: nil
            )
        }
        
        // 'q' dumps the selected objects
        if eventKey == 0x0C {
            
            NotificationCenter.default.post(
                name: Notification.Name.Demo.DumpSelectedNodes,
                object: nil
            )
            
            //updateCommandString("No command set for '\(eventChars)'.", duration: 3.0)
            updateCommandString("dumping selected node properties", duration: 3.0)
        }
        
        
        
        
        // 'w' clears the cache
        if eventKey == 0xd {
            
            
            
            tilemap.dataStorage = nil
            updateCommandString("Clearing tilemap cache...", duration: 3.0)
            tilemap.dataStorage = TileDataStorage(map: tilemap)
        }
        
        // 'x' runs a debugging command
        if eventKey == 0x7 {
            tilemap.enumerateChildNodes(withName: ".//*") { node, _ in
                if (node as? TiledGeometryType != nil) {
                    let currentValue = node.isUserInteractionEnabled
                    node.isUserInteractionEnabled = !currentValue
                    print(" - node '\(node.className)' user interaction: \(node.isUserInteractionEnabled.valueAsOnOff)")
                }

                //stop.pointee = true
            }
            let currentMapValue = tilemap.isUserInteractionEnabled
            tilemap.isUserInteractionEnabled = !currentMapValue
            
            
            updateCommandString("Setting user iteraction \(tilemap.isUserInteractionEnabled.valueAsOnOff)", duration: 3.0)
            
        }
        
        // 'y' runs a debugging command
        if eventKey == 0x10 {
            /*
            NotificationCenter.default.post(
                name: Notification.Name.DemoController.ResetDemoInterface,
                object: nil
            )
            
            updateCommandString("Forcing interface reset", duration: 3.0)
            */
            
            var tilecount = 0
            let tileId: UInt32 = 25
            for tile in tilemap.getTiles(globalID: tileId) {
                tilecount += 1
                let sprite = tile.replaceWithSpriteCopy()
                sprite.alpha = 0.25
            }
            
            updateCommandString("replaced \(tilecount) tiles.", duration: 3.0)
            
        }
        
        // 'z' runs a debugging command
        if eventKey == 0x6 {
            for layer in tilemap.getLayers() {
                let parentCount = layer.parents.count
                let buffer = String(repeating: " ", count: parentCount)
                print("\(buffer) - '\(layer.tiledListDescription)'")
            }
            
            updateCommandString("dumping tilemap layers", duration: 3.0)
        }
        
        // 'clear' clears the current selection
        if eventKey == 0x47 {
            
            NotificationCenter.default.post(
                name: Notification.Name.Demo.NodeSelectionCleared,
                object: nil
            )
            
            updateCommandString("clearing selection...", duration: 3.0)
        }
    }

    #endif
}

