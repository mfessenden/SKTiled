//
//  SKTiledDemoScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//


import SpriteKit


public class SKTiledDemoScene: SKTiledScene {
    
    public var debugMode: Bool = false
    
    // ui controls
    public var resetButton: ButtonNode!
    public var drawButton:  ButtonNode!
    public var nextButton:  ButtonNode!
    
    // debugging labels
    public var cameraInformation: SKLabelNode!
    public var tilemapInformation: SKLabelNode!
    public var tileInformation: SKLabelNode!
    
    public var selectedTiles: [SKTile] = []
    
    
    /// global information label font size.
    public var labelFontSize: CGFloat = 12 {
        didSet {
            guard oldValue != labelFontSize else { return }
            
            if let cameraInformation = cameraInformation {
                cameraInformation.fontSize = labelFontSize
            }
            if let tilemapInformation = tilemapInformation {
                tilemapInformation.fontSize = labelFontSize
            }
            if let tileInformation = tileInformation {
                tileInformation.fontSize = labelFontSize
            }
        }
    }
    
    override public func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        
        // setup demo UI
        setupDemoUI()
        setupDebuggingLabels()
    }
    
    // MARK: - Setup
    /**
     Set up interface elements for this demo.
     */
    public func setupDemoUI() {
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
        tileInformation.hidden = true
        cameraInformation.hidden = true
    }
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        
        cameraInformation.hidden = false
        
        for touch in touches {
            
            let positionInLayer = tilemap.baseLayer.convertPoint(touch.locationInNode(tilemap.baseLayer))
            let positionInMap = tilemap.baseLayer.screenToPixelCoords(positionInLayer)
            let coord = tilemap.baseLayer.screenToTileCoords(positionInLayer)
            
            // add a tile shape to the base layer where the user has clicked
            let validCoord = tilemap.baseLayer.isValid(coord)
            let tileColor: SKColor = (validCoord == true) ? TiledColors.Green.color : TiledColors.Red.color
            addTileAt(tilemap.baseLayer, Int(coord.x), Int(coord.y), duration: 5, tileColor: tileColor)
            
            // display tile information on the screen
            var coordStr = "Tile: \(coord.description), \(positionInMap.roundTo())"
            if (validCoord == false) {
                coordStr += " (invalid)"
            }
            
            tileInformation.hidden = false
            tileInformation.text = coordStr
        }
    }
    
    /**
     Add a tile shape to a layer at the given coordinate.
     
     - parameter layer:     `TiledLayerObject` layer object.
     - parameter x:         `Int` x-coordinate.
     - parameter y:         `Int` y-coordinate.
     - parameter duration:  `TimeInterval` tile life.
     */
    public func addTileAt(layer: TiledLayerObject, _ x: Int, _ y: Int, duration: NSTimeInterval=0, tileColor: SKColor) -> DebugTileShape {
        let tile = DebugTileShape(layer: layer, tileColor: tileColor)
        tile.zPosition = zPosition
        tile.position = layer.pointForCoordinate(TileCoord(x, y))
        layer.addChild(tile)
        if (duration > 0) {
            let fadeAction = SKAction.fadeAlphaTo(0, duration: duration)
            tile.runAction(fadeAction, completion: {
                tile.removeFromParent()
            })
        }
        return tile
    }
    
    /**
     Call back to the GameViewController to load the next scene.
     */
    public func loadNextScene() {
        NSNotificationCenter.defaultCenter().postNotificationName("loadNextScene", object: nil)
    }
    
    override public func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        updateLabels()
    }
    
    /**
     Update the debug label to reflect the current camera position.
     */
    public func updateLabels() {
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
}


