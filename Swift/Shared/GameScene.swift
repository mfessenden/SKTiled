//
//  GameScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public class GameScene: SKScene, SKTiledSceneDelegate {
    
    // SKTiledSceneDelegate
    public var worldNode: SKNode!
    public var cameraNode: SKTiledSceneCamera!
    public var tilemap: SKTilemap!
    public var tmxFilename: String!
    
    public var debugMode: Bool = false
    
    // ui controls    
    public var drawButton: ButtonNode!
    public var nextButton: ButtonNode!
    
    // debugging labels
    public var cameraInformation: SKLabelNode!
    public var tilemapInformation: SKLabelNode!
    public var tileInformation: SKLabelNode!
    
    /// global information label font size.
    public var labelFontSize: CGFloat = 10 {
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
    
    // MARK: - Init
    override public init(size: CGSize) {
        super.init(size: size)
        
        // set up world node
        worldNode = SKNode()
        worldNode.name = "World"
        addChild(worldNode)
    }
    
    /**
     Initialize with a tiled file name.
     
     - parameter size:    `CGSize` scene size.
     - parameter tmxFile: `String` tiled file name.
     */
    public init(size: CGSize, tmxFile: String) {
        super.init(size: size)
        
        // set up world node
        worldNode = SKNode()
        worldNode.name = "World"
        addChild(worldNode)
        tmxFilename = tmxFile
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func didMoveToView(view: SKView) {
        setupCamera()
        // ortho:  ortho4-16x16
        guard let tmxFilename = tmxFilename else { return }
        
        if let tilemapNode = loadTMX(tmxFilename) {
            self.tilemap = tilemapNode
            cameraInformation?.zPosition = self.tilemap.lastZPosition + self.tilemap.zDeltaForLayers
            self.tilemap.debugDraw = self.debugMode
        }
        
        // get the zposition for the UI
        var lastZPosition: CGFloat = 100
        if let tilemap = tilemap {
            lastZPosition = tilemap.lastZPosition
        }
        
        
        if (drawButton == nil){
            drawButton = ButtonNode(defaultImage: "draw-button-norm", highlightImage: "draw-button-pressed", action: {
                if let firstLayer = self.tilemap.tileLayers.first {
                    let debugState = !firstLayer.visualizeGrid
                    firstLayer.visualizeGrid = debugState
                    self.tilemap.debugDraw = debugState
                    self.tilemap.showObjects = debugState
                }
            })
            cameraNode.addChild(drawButton)
            // position towards the bottom of the scene
            drawButton.position.x -= (view.bounds.size.width / 12)
            drawButton.position.y -= (view.bounds.size.height / 2.25)
            drawButton.zPosition = lastZPosition * 3.0
            
            
            if let tilemap = tilemap {
                if tilemap.orientation == .Isometric {
                    drawButton.disabled = true
                }
            }
        }
        
        if (nextButton == nil){
            nextButton = ButtonNode(defaultImage: "next-button-norm", highlightImage: "next-button-pressed", action: {
                self.loadNextScene()
            })
            cameraNode.addChild(nextButton)
            // position towards the bottom of the scene
            nextButton.position.x += (view.bounds.size.width / 12)
            nextButton.position.y -= (view.bounds.size.height / 2.25)
            nextButton.zPosition = lastZPosition * 3.0
        }
        
        
        setupDebuggingLabels()
    }
    
    // MARK: - Setup
    
    /**
     Load a named tmx file.
     
     - parameter fileNamed: `String` tmx file name.
     
     - returns: `SKTilemap?` tile map node.
     */
    public func loadTMX(filename: String) -> SKTilemap? {
        if let tilemapNode = SKTilemap.load(fromFile: filename) {
            worldNode.addChild(tilemapNode)
            
            if (tilemapNode.backgroundColor != nil) {
                self.backgroundColor = tilemapNode.backgroundColor!
            }
            return tilemapNode
        }
        return nil
    }

    /**
     Setup scene camera.
     */
    public func setupCamera(){
        guard let view = self.view else { return }
        cameraNode = SKTiledSceneCamera(view: view, world: worldNode)
        addChild(cameraNode)
        camera = cameraNode
        
        // setup camera label
        cameraInformation = SKLabelNode(fontNamed: "Courier")
        cameraInformation.fontSize = labelFontSize
        cameraInformation.text = "Camera: "
        cameraNode.addChild(cameraInformation)
        // position towards the bottom of the scene
        cameraInformation.position.y -= (view.bounds.size.height / 2.85)
    }
    
    /**
     Setup debugging labels.
     */
    public func setupDebuggingLabels() {
        guard let view = self.view else { return }
        guard let cameraNode = cameraNode else { return }
        
        if (tilemapInformation == nil){
            // setup tilemap label
            tilemapInformation = SKLabelNode(fontNamed: "Courier")
            tilemapInformation.fontSize = labelFontSize
            tilemapInformation.text = "Tilemap: "
            cameraNode.addChild(tilemapInformation)
        }
        
        // position towards the bottom of the scene
        tilemapInformation.position.y -= (view.bounds.size.height / 3.2)
        
        
        if (tileInformation == nil){
            // setup tile information label
            tileInformation = SKLabelNode(fontNamed: "Courier")
            tileInformation.fontSize = labelFontSize
            tileInformation.text = "Tile: "
            cameraNode.addChild(tileInformation)
        }
        
        // position towards the bottom of the scene
        tileInformation.position.y -= (view.bounds.size.height / 2.6)  // lowest
        tileInformation.hidden = true
    }
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        
        guard let tilemap = tilemap else { return }
        let firstLayer = tilemap.tileLayers[1]
        let layerpos = touch.locationInNode(tilemap)
        let coord = firstLayer.coordinateForPoint(layerpos)
        
        var coordStr = " ~ "
        if (firstLayer.isValid(coord) == true) {
            coordStr = coord.description
        }
        
        tileInformation.hidden = false
        tileInformation.text = "Tile: (\(coordStr)) ~ \(layerpos.displayRounded())"
    }
        
    /**
     Print tile information when the scene is double-tapped.
     
     - parameter point: `CGPoint` point in scene.
     */
    public func printTileInformation(atPoint point: CGPoint) {
        guard let tilemap = tilemap else { return }
        let firstLayer = tilemap.tileLayers[1]        
        let tilemapPosition = convertPoint(point, toNode: tilemap)
        
        let coord = firstLayer.coordinateForPoint(tilemapPosition)
        // display some information about tiles at the touched location
        let tiles = tilemap.tilesAt(coord)
        if tiles.count > 0 {
            print("\n# Tiles: \(tiles.count) @ \(coord):")
            for tile in tiles {
                tile.highlightWithColor(SKColor.whiteColor())
                print("  -\(tile)")
            }
        }
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
        cameraInfo = "Camera: x: \(xpos), y: \(ypos), zoom:  \(cameraNode.zoom.displayRounded())"
        
        
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
