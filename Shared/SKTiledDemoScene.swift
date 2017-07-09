//
//  SKTiledDemoScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit
import Foundation

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
    
    internal var editMode: Bool = false
    internal var liveMode: Bool = true                     // highlight tiles under the mouse
    
    internal var blocked: Bool = true                      // lock the scene for cleanup
    internal let cleanupQueue = DispatchQueue(label: "com.sktiled.cleanup", qos: .userInteractive)
    
    internal var coordinate: CGPoint = .zero {
        didSet {
            guard oldValue != coordinate else { return }
            
            
            self.enumerateChildNodes(withName: "//*") {
                node, stop in
                
                if let tile = node as? TileShape {
                    if (tile.coord == self.coordinate) && (tile.useLabel == true) {
                        tile.detonate()
                    }
                }
            }
            
        }
    }
    
    override public func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // setup demo UI
        updateHud()
        
        #if os(macOS)
        updateTrackingViews()
        addChild(mouseTracker)
        mouseTracker.zPosition = 10000
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
    func addTileAt(layer: TiledLayerObject, _ x: Int, _ y: Int, useLabel: Bool=true)  {
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

        if coord != coordinate {
            let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
            let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)
            
            // add debug tile shape

            let tile = TileShape(layer: layer, coord: coord, tileColor: tileColor, withLabel: useLabel)
            tile.zPosition = lastZosition
            let tilePosition = layer.pointForCoordinate(x, y)
            tile.position = worldNode.convert(tilePosition, from: layer)
            worldNode.addChild(tile)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCoordinate"), object: nil, userInfo: ["x": x, "y": y])
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

    /**
     Callback to remove coordinates.
     */
    public func updateCoordinate(notification: Notification) {
        let tempCoord = CGPoint(x: notification.userInfo!["x"] as! Int,
                                y: notification.userInfo!["y"] as! Int)
        
        guard tempCoord != coordinate else { return }
        // get the current coordinate
        coordinate = tempCoord
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
    }
    
    override open func update(_ currentTime: TimeInterval) {
        guard self.blocked == false else { return }

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
        // TODO: turn this on for master
        self.physicsWorld.speed = 0
    }
    
    override open func didRenderMap(_ tilemap: SKTilemap) {
        // update the HUD to reflect the number of tiles created
        updateHud()
        tilemap.layerStatistics()
        self.blocked = false
    }
}



#if os(iOS) || os(tvOS)
// Touch-based event handling
extension SKTiledDemoScene {
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        
        for touch in touches {
            
            // make sure there are no UI objects under the mouse
            let scenePosition = touch.location(in: self)
            
            // get the position in the baseLayer
            let positionInLayer = baseLayer.touchLocation(touch)
            
            let coord = baseLayer.coordinateAtTouchLocation(touch)
            // add a tile shape to the base layer where the user has clicked
            
            // highlight the current coordinate
            addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y))
            
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
        let currentClicked = nodesUnderCursor.filter( { $0.useLabel == true } )

        if (tilemap.isPaused == false) {
            // highlight the current coordinate
            if currentClicked.count == 0 {
                addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y))
            } else {
                for tile in currentClicked {
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

        let baseLayer = tilemap.baseLayer

        // get the position relative as drawn by the
        let positionInScene = event.location(in: self)
        let positionInLayer = baseLayer.mouseLocation(event: event)
        let coord = baseLayer.coordinateAtMouseEvent(event: event)
        let validCoord = baseLayer.isValid(Int(coord.x), Int(coord.y))
        
        
        // query nodes under the cursor
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
        
        if liveMode == true {
            self.addTileToWorld(Int(coord.x), Int(coord.y))
        }
        
        let coordDescription = "\(Int(coord.x)), \(Int(coord.y))"
        updateTileInfo(msg: "Coord: \(coordDescription), \(positionInLayer.roundTo())")
        updatePropertiesInfo(msg: propertiesInfoString)
        
        
        let nodesUnderCursor = nodes(at: positionInScene).filter( { $0 as? TileShape != nil }) as! [TileShape]
        let currentClicked = nodesUnderCursor.filter( { $0.clickCount == 0 } )
        //print(currentClicked)
        //currentClicked.forEach{ $0.clickCount += 1}
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
}
#endif


open class MouseTracker: SKNode {
    private var label = SKLabelNode(fontNamed: "Courier")
    private var circle = SKShapeNode()
    private let scaleAction = SKAction.scale(by: 1.55, duration: 0.025)
    private let scaleSequence: SKAction
    
    public var coord: CGPoint = .zero {
        didSet {
            label.text = "\(Int(coord.x)), \(Int(coord.y))"
        }
    }
    
    public var fontSize: CGFloat = 12 {
        didSet {
            label.fontSize = fontSize
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
        circle.strokeColor = .clear
        label.fontSize = fontSize
        label.position.y -= radius
        label.position.x -= (radius * 8)
    }
}
