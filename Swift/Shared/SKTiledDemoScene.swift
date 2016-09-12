//
//  SKTiledDemoScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit


public class SKTiledDemoScene: SKTiledScene {
    
    open var uiScale: CGFloat = 1
    public var debugMode: Bool = false
    
    // ui controls
    public var resetButton: ButtonNode!
    public var drawButton:  ButtonNode!
    public var nextButton:  ButtonNode!
    
    // debugging labels
    public var cameraInformation: SKLabelNode!
    public var tilemapInformation: SKLabelNode!
    public var tileInformation: SKLabelNode!
    
    open var selectedTiles: [SKTile] = []
    
    
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
    open func setupDemoUI() {
        guard let view = self.view else { return }
        
        // set up camera overlay UI
        var lastZPosition: CGFloat = 100
        if let tilemap = tilemap {
            lastZPosition = tilemap.lastZPosition
        }
        
        if (resetButton == nil){
            resetButton = ButtonNode(defaultImage: "reset-button-norm", highlightImage: "reset-button-pressed", action: {
                if let cameraNode = self.cameraNode {
                    cameraNode.resetCamera()
                }
            })
            cameraNode.addChild(resetButton)
            // position towards the bottom of the scene
            resetButton.position.x -= (view.bounds.size.width / 7)
            resetButton.position.y -= (view.bounds.size.height / 2.25)
            resetButton.zPosition = lastZPosition * 3.0
        }
        
        if (drawButton == nil){
            drawButton = ButtonNode(defaultImage: "draw-button-norm", highlightImage: "draw-button-pressed", action: {
                guard let tilemap = self.tilemap else { return }
                let debugState = !tilemap.debugDraw
                tilemap.debugDraw = debugState
                
                if (debugState == true){
                    tilemap.debugLayers()
                }
            })
            
            cameraNode.addChild(drawButton)
            // position towards the bottom of the scene
            drawButton.position.y -= (view.bounds.size.height / 2.25)
            drawButton.zPosition = lastZPosition * 3.0
        }
        
        if (nextButton == nil){
            nextButton = ButtonNode(defaultImage: "next-button-norm", highlightImage: "next-button-pressed", action: {
                self.loadNextScene()
            })
            cameraNode.addChild(nextButton)
            // position towards the bottom of the scene
            nextButton.position.x += (view.bounds.size.width / 7)
            nextButton.position.y -= (view.bounds.size.height / 2.25)
            nextButton.zPosition = lastZPosition * 3.0
        }
    }
    
    /**
     Setup debugging labels.
     */
    public func setupDebuggingLabels() {
        guard let view = self.view else { return }
        guard let cameraNode = cameraNode else { return }
        
        let labelYPos = view.bounds.size.height / 3.2
        
        if (tilemapInformation == nil){
            // setup tilemap label
            tilemapInformation = SKLabelNode(fontNamed: "Courier")
            tilemapInformation.fontSize = labelFontSize
            tilemapInformation.text = "Tilemap:"
            cameraNode.addChild(tilemapInformation)
        }
        
        tilemapInformation.position.y -= labelYPos
        
        
        if (cameraInformation == nil) {
            cameraInformation = SKLabelNode(fontNamed: "Courier")
            cameraInformation.fontSize = labelFontSize
            cameraInformation.text = "Camera:"
            cameraNode.addChild(cameraInformation)
            cameraInformation.position.y -= labelYPos + 16
        }
        
        if (tileInformation == nil){
            // setup tile information label
            tileInformation = SKLabelNode(fontNamed: "Courier")
            tileInformation.fontSize = labelFontSize
            tileInformation.text = "Tile:"
            cameraNode.addChild(tileInformation)
        }
        
        // position towards the bottom of the scene
        tileInformation.position.y -= labelYPos + 32
        tileInformation.isHidden = true
        cameraInformation.isHidden = true
    }
    
    /**
     Add a tile shape to a layer at the given coordinate.
     
     - parameter layer:     `TiledLayerObject` layer object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    open func addTileAt(layer: TiledLayerObject, _ x: Int, _ y: Int, duration: TimeInterval=0) -> DebugTileShape {
        // validate the coordinate
        let coord = TileCoord(x, y)
        let validCoord = layer.isValid(coord)
        let tileColor: SKColor = (validCoord == true) ? tilemap.highlightColor : TiledColors.red.color
        
        // add debug tile shape
        let tile = DebugTileShape(layer: layer, tileColor: tileColor)
        tile.zPosition = zPosition
        tile.position = layer.pointForCoordinate(TileCoord(x, y))
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
    open func loadNextScene() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadNextScene"), object: nil)
    }
    

    override open func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        var dynamicScale = size.width / 400
        let remainder = dynamicScale.truncatingRemainder(dividingBy: 2)
        dynamicScale = dynamicScale - remainder
        uiScale = dynamicScale >= 1 ? dynamicScale : 1
    
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

    override public func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        updateLabels()
    }
    
    private func buttonNodes() -> [ButtonNode] {
        var buttons: [ButtonNode] = []
        enumerateChildNodes(withName: "//*", using: {node, _ in
            if let button = node as? ButtonNode {
                if button.isHidden == false {
                    buttons.append(button)
                }
            }
        })
        return buttons
    }

    /**
     Update the debug label to reflect the current camera position.
     */
    open func updateLabels() {
        guard let tilemap = tilemap else { return }
        guard let cameraNode = cameraNode else { return }
        
        let highestZPos = tilemap.lastZPosition + tilemap.zDeltaForLayers
        
        // camera information
        var cameraInfo = "Camera: x: 0, y: 0, zoom: 1.0"
        let xpos = String(format: "%.\(String(2))f", cameraNode.position.x)
        let ypos = String(format: "%.\(String(2))f", cameraNode.position.y)
        cameraInfo = "Camera: x: \(xpos), y: \(ypos) \(cameraNode.allowMovement == true ? "" : "🔒"), zoom: \(cameraNode.zoom.roundTo()) \(cameraNode.allowZoom == true ? "" : "🔒")"
        
        
        if let cameraInformation = cameraInformation {
            cameraInformation.text = cameraInfo
            cameraInformation.zPosition = highestZPos
        }
        
        
        if let tilemapInformation = tilemapInformation {
            tilemapInformation.text = tilemap.description
            tilemapInformation.zPosition = highestZPos
        }
        
        if let tileInformation = tileInformation {
            //tileInformation.text = "Tile: "
            tileInformation.zPosition = highestZPos
        }
    }

        /**
     Update HUD elements.
     */
    private func updateHud(){
        guard let view = self.view else { return }
        let lastZPosition: CGFloat = (tilemap != nil) ? tilemap.lastZPosition : 200
        
        let viewSize = view.bounds.size
        let buttonYPos: CGFloat = -(size.height * 0.4)
        
        let buttons = buttonNodes()
        guard buttons.count > 0 else { return }
        
        buttons.forEach {$0.setScale(uiScale)}
        
        let buttonWidths = buttons.map { $0.size.width }
        let maxWidth = buttonWidths.reduce(0, {$0 + $1})
        let spacing = (viewSize.width - maxWidth) / CGFloat(buttons.count + 1)
        
        var current = spacing + (buttonWidths[0] / 2)
        for button in buttons {
            let buttonScenePos = CGPoint(x: current - (viewSize.width / 2), y: buttonYPos)
            button.position = buttonScenePos
            button.zPosition = lastZPosition
            current += spacing + button.size.width
        }
        
        let dynamicFontSize = labelFontSize * (size.width / 600)
        
        // Update information labels
        if let tilemapInformation = tilemapInformation {
            let ypos = -(size.height * (uiScale / 8.5))    // approx 0.25
            tilemapInformation.position.y = abs(ypos) < 100 ? -80 : ypos
            tilemapInformation.fontSize = dynamicFontSize
        }
        
        if let cameraInformation = cameraInformation {
            let ypos = -(size.height * (uiScale / 7.4))    // approx 0.3
            cameraInformation.position.y = abs(ypos) < 100 ? -100 : ypos
            cameraInformation.fontSize = dynamicFontSize
        }
        
        if let tileInformation = tileInformation {
            let ypos = -(size.height * (uiScale / 6.5))    // approx 0.35
            tileInformation.position.y = abs(ypos) < 100 ? -120 : ypos
            tileInformation.fontSize = dynamicFontSize
        }
    }
}


public extension SKNode {
    
    public func posByCanvas(x: CGFloat, y: CGFloat) {
        guard let scene = scene else { return }
        self.position = CGPoint(x: CGFloat(scene.size.width * x), y: CGFloat(scene.size.height * y))
    }
}


#if os(iOS) || os(tvOS)
// Touch-based event handling
public extension SKTiledDemoScene {
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        //cameraInformation.hidden = false
        
        for touch in touches {
            // get the position in the baseLayer
            let positionInLayer = baseLayer.touchLocation(touch)
            let positionInMap = baseLayer.screenToPixelCoords(positionInLayer)            // this needs to take into consideration the adjustments for hex -> square grid
            let coord = baseLayer.screenToTileCoords(positionInLayer)
            // add a tile shape to the base layer where the user has clicked

            addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y), duration: 5)
            
            // update the tile information label
            var coordStr = "Tile: \(coord.description), \(positionInMap.roundTo())"
            tileInformation.isHidden = false
            tileInformation.text = coordStr
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
public extension SKTiledDemoScene {
        
    override open func mouseDown(with event: NSEvent) {
        guard let tilemap = tilemap else { return }
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseDown(with: event)
        
        let baseLayer = tilemap.baseLayer
        
        // get the position in the baseLayer
        let positionInLayer = baseLayer.mouseLocation(event: event)
        let positionInMap = baseLayer.screenToPixelCoords(positionInLayer)
        let coord = baseLayer.screenToTileCoords(positionInLayer)
        
        // add a tile shape to the base layer where the user has clicked
        addTileAt(layer: baseLayer, Int(coord.x), Int(coord.y), duration: 5)
        
        // update the tile information label
        var coordStr = "Tile: \(coord.description), \(positionInMap.roundTo())"
        tileInformation.isHidden = false
        tileInformation.text = coordStr
    }
    
    override open func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard let tilemap = tilemap else { return }
        let baseLayer = tilemap.baseLayer
        
        // get the position in the baseLayer (inverted)
        let positionInLayer = baseLayer.mouseLocation(event: event)
        let positionInMap = baseLayer.screenToPixelCoords(positionInLayer)
        let coord = baseLayer.screenToTileCoords(positionInLayer)

        tileInformation?.isHidden = false
        tileInformation?.text = "Tile: ---, \(positionInMap.roundTo())"
        
        if let firstTile = tilemap.firstTileAt(coord) {
            firstTile.drawBounds(antialiasing: true, duration: 0.5)
            
            // update the tile information label
            var coordStr = "\(firstTile.description), \(positionInMap.roundTo())"
            tileInformation?.isHidden = false
            tileInformation?.text = coordStr
        }
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
        if event.keyCode == 0x00 || event.keyCode == 0x52 || event.keyCode == 0x1D {
            if let tilemap = tilemap {
                cameraNode.resetCamera(toScale: tilemap.worldScale)
            } else {
                cameraNode.resetCamera()
            }
        }
    }
}
#endif


