//
//  GameScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public class GameScene: SKScene, SKTiledSceneDelegate {
    
    public var worldNode: SKNode!
    public var cameraNode: SKTiledSceneCamera!
    public var tilemap: SKTilemap!
    
    // debugging labels
    public var debugLabel: SKLabelNode!
    public var tileDataLabel: SKLabelNode!
    
    // MARK: - Init
    override public init(size: CGSize) {
        super.init(size: size)
        
        // set up world node
        worldNode = SKNode()
        worldNode.name = "World"
        addChild(worldNode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func didMoveToView(view: SKView) {        
        // set up camera
        cameraNode = SKTiledSceneCamera(view: self.view!, world: worldNode)
        addChild(cameraNode)
        camera = cameraNode
        
        // setup camera label
        debugLabel = SKLabelNode(fontNamed: "Courier")
        debugLabel.text = "Camera: "
        debugLabel.fontSize = 12.0
        cameraNode.addChild(debugLabel)
        debugLabel.position.y -= (view.bounds.size.height / 2.25)
        
        
        if let tilemapNode = SKTilemap.loadFromFile("roguelike-16x16") {
            tilemap = tilemapNode
            worldNode.addChild(tilemap)
            debugLabel.zPosition = tilemap.lastZPosition + 1.0
        }
    }
    
    /**
     Update the debug label to reflect the current camera position.
     */
    public func updateLabels() {
        var debugString = "Camera: x: 0, y: 0, zoom: 1.0"
        if let camera = camera {
            let xpos = String(format: "%.\(String(2))f", camera.position.x)
            let ypos = String(format: "%.\(String(2))f", camera.position.y)
            debugString = "Camera: x: \(xpos), y: \(ypos), zoom: 1.0"
        }
        
        if let debugLabel = debugLabel {
            debugLabel.text = debugString
        }
    }
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        let touch = touches.first!
        let sceneLocation = touch.locationInNode(self)
        let touchDelta = distanceFromOrigin(sceneLocation)
        debugTouchPoint(sceneLocation)
        if let camera = camera {
            camera.position = sceneLocation
            debugLabel.zPosition = tilemap.lastZPosition + 1.0
        }
    }
    
    /**
     Return debugging data when a tile is touched.
     
     - parameter scenePoint: input scene `CGPoint` point.
     */
    public func debugTouchPoint(scenePoint: CGPoint){
        let firstLayer = tilemap.layers.first!
        let layerPoint = convertPoint(scenePoint, toNode: firstLayer)
        let coordinate = firstLayer.coordinateForPoint(layerPoint)
        print("\n# Tile coord: x: \(coordinate.x), y: \(coordinate.y)")
        let nodes = nodesAtPoint(scenePoint)
        for node in nodes {
            if let tile = node as? SKTile {
                print(node)
                tile.highlight = !tile.highlight
            }
            
            if let object = node as? SKTileObject {
                print(object)
            }
        }
    }
   
    override public func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        updateLabels()
    }
}
