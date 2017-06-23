//
//  SKTiledDemoScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit
import Foundation

#if os(iOS)
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
    internal var coordinates: [CGPoint] = []
    internal var editMode: Bool = false
    internal var liveMode: Bool = false                     // highlight tiles under the mouse
    
    override public func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // setup demo UI
        updateHud()
        
        #if os(macOS)
        updateTrackingViews()
        addChild(mouseTracker)
        mouseTracker.zPosition = 10000
        #endif
        
        NotificationCenter.default.addObserver(self, selector: #selector(removeCoordinate), name: NSNotification.Name(rawValue: "removeCoordinate"), object: nil)
    }

    /**
     Add a tile shape to a layer at the given coordinate.
     
     - parameter layer:     `TiledLayerObject` layer object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    func addTileAt(layer: TiledLayerObject, _ x: Int, _ y: Int, duration: TimeInterval=0, useLabel: Bool=false) -> TileShape? {
        guard let tilemap = tilemap else { return nil }
        // validate the coordinate
        let validCoord = layer.isValid(x, y)
        let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
        
        let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)
        
        // add debug tile shape
        let tile = TileShape(layer: layer, coord: CGPoint(x: x, y: y), tileColor: tileColor, withLabel: useLabel)
        tile.zPosition = lastZosition
        tile.position = layer.pointForCoordinate(x, y)
        layer.addChild(tile)
        if (duration > 0) {
            let fadeAction = SKAction.fadeAlpha(to: 0, duration: duration)
            tile.run(fadeAction, completion: {
                tile.removeFromParent()
            })
        }
        return tile
    }
    
    /**
     Add a tile shape to the world at the given coordinate.
     
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    func addTileToWorld(_ x: Int, _ y: Int, duration: TimeInterval=0, useLabel: Bool=false) -> TileShape? {
        guard let tilemap = tilemap,
                let worldNode = worldNode else { return nil }
        
        // validate the coordinate
        let layer = tilemap.baseLayer
        let validCoord = layer.isValid(x, y)
        
        let coord = CGPoint(x: x, y: y)
        
        
        if !coordinates.contains(coord) {
            coordinates.append(coord)
            
            let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
            let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)
            
            // add debug tile shape
            let tile = TileShape(layer: layer, coord: CGPoint(x: x, y: y), tileColor: tileColor, withLabel: useLabel)
            tile.zPosition = lastZosition
            let tilePosition = layer.pointForCoordinate(x, y)
            tile.position = worldNode.convert(tilePosition, from: layer)
            worldNode.addChild(tile)
            if (duration > 0) {
                let fadeAction = SKAction.fadeAlpha(to: 0, duration: duration)
                tile.run(fadeAction, completion: {
                    tile.removeFromParent()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "removeCoordinate"), object: nil, userInfo: ["x": x, "y": y])
                })
            }
            return tile
        }
        return nil
    }
    
    // MARK: - Deinitialization
    deinit {
        // Deregister for scene updates
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "loadPreviousScene"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "updateDebugLabels"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "removeCoordinate"), object: nil)
        removeAllActions()
        removeAllChildren()
    }
    
    /**
     Call back to the GameViewController to load the next scene.
     */
    public func loadNextScene() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadNextScene"), object: nil)
    }
    
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

    /**
     Call back to remove coordinates.
     */
    public func removeCoordinate(notification: Notification) {
        let coord = CGPoint(x: notification.userInfo!["x"] as! Int,
                            y: notification.userInfo!["y"] as! Int)
        
        guard coordinates.contains(coord) else { return }
        coordinates.remove(at: coordinates.index(of: coord)!)
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
    
    // MARK: - Callbacks
    override open func didRenderMap(_ tilemap: SKTilemap) {
        // update the HUD to reflect the number of tiles created
        updateHud()
        tilemap.layerStatistics()
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
            let _ = addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y), duration: 6)
            
            // update the tile information label
            let coordStr = "Coord: \(coord.shortDescription), \(positionInLayer.roundTo())"
            
            updateTileInfo(msg: coordStr)
            
            // tile properties output
            var propertiesInfoString = ""
            if let tile = tilemap.firstTileAt(coord: coord) {
                propertiesInfoString = "Tile ID: \(tile.tileData.id)"
                if tile.tileData.propertiesString != "" {
                    propertiesInfoString += "; \(tile.tileData.propertiesString)"
                }
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
    
        let baseLayer = tilemap.baseLayer
        
        // get the position in the baseLayer
        let positionInLayer = baseLayer.mouseLocation(event: event)
        // get the coordinate at that position
        let coord = baseLayer.coordinateAtMouseEvent(event: event)

        if (tilemap.isPaused == false) {
            // highlight the current coordinate
            let _ = addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y), duration: 6)
        }

        // update the tile information label
        let coordDescription = "\(Int(coord.x)), \(Int(coord.y))"
        let coordStr = "Coord: \(coordDescription), \(positionInLayer.roundTo())"
        updateTileInfo(msg: coordStr)
        
        // tile properties output
        var propertiesInfoString = ""
        if let tile = tilemap.firstTileAt(coord: coord) {
            propertiesInfoString = "Tile ID: \(tile.tileData.id)"
            if tile.tileData.propertiesString != "" {
                propertiesInfoString += "; \(tile.tileData.propertiesString)"
            }
            
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
        
        // CLEANME: Here
        //let positionInWindow = event.locationInWindow
        //let positionInView = convertPoint(toView: positionInScene)
        //let worldPosition = convert(positionInScene, to: worldNode!)
        

        
        // get the position relative as drawn by the
        let positionInScene = event.location(in: self)
        let positionInLayer = baseLayer.mouseLocation(event: event)
        let coord = baseLayer.coordinateAtMouseEvent(event: event)
        let validCoord = baseLayer.isValid(Int(coord.x), Int(coord.y))

        
        // update the mouse tracking node
        mouseTracker.position = positionInScene
        mouseTracker.zPosition = tilemap.lastZPosition * 10
        mouseTracker.coord = coord
        mouseTracker.isValid = validCoord
        
        if liveMode == true {
            let _ = self.addTileToWorld(Int(coord.x), Int(coord.y), duration: 0.7)
        }
        
        let coordDescription = "\(Int(coord.x)), \(Int(coord.y))"
        updateTileInfo(msg: "Coord: \(coordDescription), \(positionInLayer.roundTo())")
        
        // tile properties output
        var propertiesInfoString = ""
        if let tile = tilemap.firstTileAt(coord: coord) {
            //tile.highlightWithColor(tilemap.highlightColor)
            propertiesInfoString = "Tile ID: \(tile.tileData.id)"
            if tile.tileData.propertiesString != "" {
                propertiesInfoString += "; \(tile.tileData.propertiesString)"
            }
        }
        updatePropertiesInfo(msg: propertiesInfoString)
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
