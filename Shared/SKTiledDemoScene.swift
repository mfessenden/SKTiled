//
//  SKTiledDemoScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit


public class SKTiledDemoScene: SKTiledScene {
    
    public var uiScale: CGFloat = 1
    public var debugMode: Bool = false
    
    // hud buttons
    public var buttons: [ButtonNode] = []
    public var resetButton: ButtonNode!
    public var showGridButton: ButtonNode!
    public var showObjectsButton: ButtonNode!
    public var loadNextButton:  ButtonNode!
    
    // info labels
    public var mapInformationLabel: SKLabelNode!
    public var tileInformationLabel: SKLabelNode!
    public var propertiesInformationLabel: SKLabelNode!
    
    /// global information label font size.
    private let labelFontSize: CGFloat = 11
    
    override public func didMove(to view: SKView) {
        super.didMove(to: view)
        
        #if os(OSX)
        // add mouse tracking for OSX
        let options = [NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.activeAlways] as NSTrackingAreaOptions
        let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: self, userInfo: nil)
        view.addTrackingArea(trackingArea)
        #endif
        
        // setup demo UI
        setupDemoUI()
        setupDebuggingLabels()
        updateHud()
    }
    
    // MARK: - Setup
    /**
     Set up interface elements for this demo.
     */
    public func setupDemoUI() {
        guard let view = self.view else { return }

        // set up camera overlay UI
        let lastZPosition: CGFloat = (tilemap != nil) ? tilemap.lastZPosition * 10 : 5000

        if (resetButton == nil){
            resetButton = ButtonNode(defaultImage: "scale-button-norm", highlightImage: "scale-button-pressed", action: {
                if let cameraNode = self.cameraNode {
                    cameraNode.fitToView()
                }
            })
            cameraNode.addChild(resetButton)
            buttons.append(resetButton)
            
            // position towards the bottom of the scene
            resetButton.position.x -= (view.bounds.size.width / 7)
            resetButton.position.y -= (view.bounds.size.height / 2.25)
            resetButton.zPosition = lastZPosition
        }
        
        if (showGridButton == nil){
            showGridButton = ButtonNode(defaultImage: "grid-button-norm", highlightImage: "grid-button-pressed", action: {
                guard let tilemap = self.tilemap else { return }
                let debugState = !tilemap.baseLayer.showGrid
                tilemap.baseLayer.showGrid = debugState
                
                tilemap.baseLayer.drawBounds()
            })
            
            cameraNode.addChild(showGridButton)
            buttons.append(showGridButton)
            // position towards the bottom of the scene
            showGridButton.position.y -= (view.bounds.size.height / 2.25)
            showGridButton.zPosition = lastZPosition
        }
                
        if (showObjectsButton == nil){
            showObjectsButton = ButtonNode(defaultImage: "objects-button-norm", highlightImage: "objects-button-pressed", action: {
                guard let tilemap = self.tilemap else { return }
                let debugState = !tilemap.showObjects
                tilemap.showObjects = debugState
            })
            
            cameraNode.addChild(showObjectsButton)
            buttons.append(showObjectsButton)
            // position towards the bottom of the scene
            showObjectsButton.position.y -= (view.bounds.size.height / 2.25)
            showObjectsButton.zPosition = lastZPosition
            showObjectsButton.isUserInteractionEnabled = tilemap.objectGroups.count > 0 ? true : false
        }
        
        
        if (loadNextButton == nil){
            loadNextButton = ButtonNode(defaultImage: "next-button-norm", highlightImage: "next-button-pressed", action: {
                self.loadNextScene()
            })
            cameraNode.addChild(loadNextButton)
            buttons.append(loadNextButton)
            // position towards the bottom of the scene
            loadNextButton.position.x += (view.bounds.size.width / 7)
            loadNextButton.position.y -= (view.bounds.size.height / 2.25)
            loadNextButton.zPosition = lastZPosition
        }
    }
    
    /**
     Setup debugging labels.
     */
    public func setupDebuggingLabels() {
        guard let view = self.view else { return }
        guard let cameraNode = cameraNode else { return }
        
        var tilemapInfoY: CGFloat = 0.77
        var tileInfoY: CGFloat = 0.81
        var propertiesInfoY: CGFloat = 0.85
        
        #if os(iOS)
        tilemapInfoY = 1.0 - tilemapInfoY
        tileInfoY = 1.0 - tileInfoY
        propertiesInfoY = 1.0 - propertiesInfoY
        #endif
        
        if (mapInformationLabel == nil){
            // setup tilemap label
            mapInformationLabel = SKLabelNode(fontNamed: "Courier")
            mapInformationLabel.fontSize = labelFontSize
            mapInformationLabel.text = "Tilemap:"
            cameraNode.addChild(mapInformationLabel)
        }
        
        if (tileInformationLabel == nil){
            // setup tile information label
            tileInformationLabel = SKLabelNode(fontNamed: "Courier")
            tileInformationLabel.fontSize = labelFontSize
            tileInformationLabel.text = "Tile:"
            cameraNode.addChild(tileInformationLabel)
        }
        
        if (propertiesInformationLabel == nil){
            // setup tile information label
            propertiesInformationLabel = SKLabelNode(fontNamed: "Courier")
            propertiesInformationLabel.fontSize = labelFontSize
            propertiesInformationLabel.text = "ID:"
            cameraNode.addChild(propertiesInformationLabel)
        }
        
        mapInformationLabel.posByCanvas(x: 0.5, y: tilemapInfoY)
        tileInformationLabel.isHidden = true
        propertiesInformationLabel.isHidden = true
        tileInformationLabel.posByCanvas(x: 0.5, y: tileInfoY)
        propertiesInformationLabel.posByCanvas(x: 0.5, y: propertiesInfoY)
    }
    
    /**
     Add a tile shape to a layer at the given coordinate.
     
     - parameter layer:     `TiledLayerObject` layer object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    func addTileAt(layer: TiledLayerObject, _ x: Int, _ y: Int, duration: TimeInterval=0) -> DebugTileShape {
        // validate the coordinate
        let validCoord = layer.isValid(x, y)
        let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
        
        let lastZosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 2)
        
        // add debug tile shape
        let tile = DebugTileShape(layer: layer, tileColor: tileColor)
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
     Call back to the GameViewController to load the next scene.
     */
    public func loadNextScene() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadNextScene"), object: nil)
    }
    
    override public func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        uiScale = size.width / 400
        updateHud()
        
        #if os(OSX)
        if let view = self.view {
            let options = [NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.activeAlways] as NSTrackingAreaOptions
            // clear out old tracking areas
            for oldTrackingArea in view.trackingAreas {
                view.removeTrackingArea(oldTrackingArea)
            }
            
            let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: self, userInfo: nil)
            view.addTrackingArea(trackingArea)
        }
        #endif
    }
    
    /**
     Filters events to allow buttons to receive focus.
     
     - parameter point: `CGPoint` event position.
     - returns:  `Bool` point is valid scene point.
    */
    fileprivate func isValidPosition(point: CGPoint) -> Bool {
        let nodesUnderCursor = nodes(at: point)
        for node in nodesUnderCursor {
            if let _ = node as? ButtonNode {
                return false
            }
        }
        return true
    }


    /**
     Update HUD elements when the view size changes.
     */
    private func updateHud(){
        guard let view = self.view else { return }
        
        let activeButtons = buttons.filter( {$0.isHidden == false})
        guard activeButtons.count > 0 else { return }
        
        let lastZPosition: CGFloat = (tilemap != nil) ? tilemap.lastZPosition * 10 : 5000
        
        let viewSize = view.bounds.size
        let buttonYPos: CGFloat = -(size.height * 0.4)
        
        activeButtons.forEach {$0.setScale(uiScale)}
        activeButtons.forEach {$0.zPosition = lastZPosition * 2}
        
        
        var tilemapInfoY: CGFloat = 0.77
        var tileInfoY: CGFloat = 0.81
        var propertiesInfoY: CGFloat = 0.85
        
        #if os(iOS)
        tilemapInfoY = 1.0 - tilemapInfoY
        tileInfoY = 1.0 - tileInfoY
        propertiesInfoY = 1.0 - propertiesInfoY
        #endif
        
        let buttonWidths = activeButtons.map { $0.size.width }
        let maxWidth = buttonWidths.reduce(0, {$0 + $1})
        let spacing = (viewSize.width - maxWidth) / CGFloat(activeButtons.count + 1)
        
        var current = spacing + (buttonWidths[0] / 2)
        for button in activeButtons {
            let buttonScenePos = CGPoint(x: current - (viewSize.width / 2), y: buttonYPos)
            button.position = buttonScenePos
            button.zPosition = lastZPosition
            current += spacing + button.size.width
        }
        
        let dynamicFontSize = labelFontSize * (size.width / 600)

        // Update information labels
        if let mapInformationLabel = mapInformationLabel {
            mapInformationLabel.fontSize = dynamicFontSize
            mapInformationLabel.zPosition = lastZPosition
            mapInformationLabel.posByCanvas(x: 0.5, y: tilemapInfoY)
            mapInformationLabel.text = tilemap?.description
        }
        
        if let tileInformationLabel = tileInformationLabel {
            tileInformationLabel.fontSize = dynamicFontSize
            tileInformationLabel.zPosition = lastZPosition
            tileInformationLabel.posByCanvas(x: 0.5, y: tileInfoY)
        }
        
        if let propertiesInformationLabel = propertiesInformationLabel {
            propertiesInformationLabel.fontSize = dynamicFontSize
            propertiesInformationLabel.zPosition = lastZPosition
            propertiesInformationLabel.posByCanvas(x: 0.5, y: propertiesInfoY)
        }
    }
}


public extension SKNode {
    
    /**
     Position the node by a percentage of the view size.
    */
    public func posByCanvas(x: CGFloat, y: CGFloat) {
        guard let scene = scene else { return }
        guard let view = scene.view else { return }
        self.position = scene.convertPoint(fromView: (CGPoint(x: CGFloat(view.bounds.size.width * x), y: CGFloat(view.bounds.size.height * (1.0 - y)))))
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
            if !isValidPosition(point: scenePosition) { return }
            
            // get the position in the baseLayer
            let positionInLayer = baseLayer.touchLocation(touch)
            let coord = baseLayer.coordinateAtTouchLocation(touch)
            // add a tile shape to the base layer where the user has clicked
            
            // highlight the current coordinate
            let _ = addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y), duration: 5)
            
            // update the tile information label
            var coordStr = "Tile: \(coord.coordDescription), \(positionInLayer.roundTo())"
            tileInformationLabel.isHidden = false
            tileInformationLabel.text = coordStr
            
            // tile properties output
            var propertiesInfoString = "ID: ~"
            if let tile = tilemap.firstTileAt(coord) {
                propertiesInfoString = "ID: \(tile.tileData.id)"
                if tile.tileData.propertiesString != "" {
                    propertiesInfoString += "; \(tile.tileData.propertiesString)"
                }
            }
            propertiesInformationLabel.isHidden = false
            propertiesInformationLabel.text = propertiesInfoString
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // do something here
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // do something here
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // do something here
        }
    }
}
#endif


#if os(OSX)
// Mouse-based event handling
extension SKTiledDemoScene {
        
    override open func mouseDown(with event: NSEvent) {
        guard let tilemap = tilemap else { return }
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseDown(with: event)
        
        let baseLayer = tilemap.baseLayer
        
        // make sure there are no UI objects under the mouse
        let scenePosition = event.location(in: self)
        if !isValidPosition(point: scenePosition) { return }
        
        // get the position in the baseLayer
        let positionInLayer = baseLayer.mouseLocation(event: event)
        let coord = baseLayer.coordinateAtMouseEvent(event: event)
        
        if (tilemap.isPaused == false){
            // highlight the current coordinate
            let _ = addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y), duration: 5)
        }

        // update the tile information label
        let coordStr = "Tile: \(coord.coordDescription), \(positionInLayer.roundTo())"
        tileInformationLabel.isHidden = false
        tileInformationLabel.text = coordStr
        
        // tile properties output
        var propertiesInfoString = "ID: ~"
        if let tile = tilemap.firstTileAt(coord) {
            propertiesInfoString = "ID: \(tile.tileData.id)"
            if tile.tileData.propertiesString != "" {
                propertiesInfoString += "; \(tile.tileData.propertiesString)"
            }
        }
        propertiesInformationLabel.isHidden = false
        propertiesInformationLabel.text = propertiesInfoString
    }
    
    override open func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        updateTrackingViews()
        
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        
        // make sure there are no UI objects under the mouse
        let scenePosition = event.location(in: self)
        if !isValidPosition(point: scenePosition) { return }
        
        // get the position in the baseLayer (inverted)
        let positionInLayer = baseLayer.mouseLocation(event: event)
        let coord = baseLayer.screenToTileCoords(positionInLayer)
        
        tileInformationLabel?.isHidden = false
        tileInformationLabel?.text = "Tile: \(coord.coordDescription), \(positionInLayer.roundTo())"
        
        if (tilemap.isPaused == false){
            // highlight the current coordinate
            let _ = addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y), duration: 0.05)
        }
        
        // tile properties output
        var propertiesInfoString = "ID: ~"
        if let tile = tilemap.firstTileAt(coord) {
            propertiesInfoString = "ID: \(tile.tileData.id)"
            if tile.tileData.propertiesString != "" {
                propertiesInfoString += "; \(tile.tileData.propertiesString)"
            }
        }
        propertiesInformationLabel.isHidden = false
        propertiesInformationLabel.text = propertiesInfoString
    }
    
    override open func mouseDragged(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scenePositionChanged(event)
    }
    
    override open func mouseUp(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseUp(with: event)
    }
    
    override open func scrollWheel(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scrollWheel(with: event)
    }
    
    override open func keyDown(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        
        // 'F' key fits the map to the view
        if event.keyCode == 0x03 {
            if let tilemap = tilemap {
                cameraNode.fitToView()
            }
        }
        
        // 'D' shows debug view
        if event.keyCode == 0x02 {
            if let tilemap = tilemap {
                tilemap.debugDraw = !tilemap.debugDraw
            }
        }
        
        // 'O' shows objects
        if event.keyCode == 0x1F {
            if let tilemap = tilemap {
                tilemap.showObjects = !tilemap.showObjects
            }
        }
        
        // 'P' pauses the map
        if event.keyCode == 0x23 {
            if let tilemap = tilemap {
                tilemap.isPaused = !tilemap.isPaused
            }
        }
        
        
        // 'G' shows the grid
        if event.keyCode == 0x05 {
            if let tilemap = tilemap {
                tilemap.baseLayer.showGrid = !tilemap.baseLayer.showGrid
            }
        }
        
        // 'H' hides the HUD
        if event.keyCode == 0x04 {
            for button in buttons{
                if (button.isHidden == false) {
                    button.alpha = button.alpha != 0 ? 0 : 1.0
                }
            }
        }
        
        // 'A', '0' reset the camera
        if event.keyCode == 0x00 || event.keyCode == 0x52 || event.keyCode == 0x1D {
            if let tilemap = tilemap {
                cameraNode.resetCamera(toScale: tilemap.worldScale)
            } else {
                cameraNode.resetCamera()
            }
        }
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

