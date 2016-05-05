//
//  GameScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public class GameScene: SKScene {
    
    public let worldNode = SKNode()
    public var tilemap: SKTilemap!
    public var debugLabel: SKLabelNode!
    public let cameraNode = SKCameraNode()
    
    override public func didMoveToView(view: SKView) {
        // setup the world container
        worldNode.position = self.center
        addChild(worldNode)
        
        // camera
        addChild(cameraNode)
        cameraNode.position = self.center
        camera = cameraNode
        
        debugLabel = SKLabelNode(fontNamed: "Courier")
        debugLabel.text = "Camera: "
        debugLabel.fontSize = 14.0
        cameraNode.addChild(debugLabel)
        debugLabel.position.y -= (view.bounds.size.height / 2.25)
        
        let tmxfileName = "sample-map"
        
        if let tilemapNode = SKTilemap.loadTMX(tmxfileName) {
            tilemap = tilemapNode
            worldNode.addChild(tilemap)
            // set the camera position to the tilemap center point
            //cameraNode.position = convertPoint(tilemap.centerPoint, fromNode: tilemap)
            tilemap.debugDraw = true
            
            let debugShape = SKShapeNode(rectOfSize: tilemap.size)
            tilemap.addChild(debugShape)
            debugShape.position = CGPointZero
            debugShape.zPosition = tilemap.zPosition + 100
            debugShape.antialiased = false
            
            debugShape.strokeColor = SKColor(red: 0, green: 1.0, blue: 0, alpha: 0.75)
            debugShape.lineWidth = 1
            
            debugLabel.zPosition = tilemap.zPosition + 150
        }
    }
    
    /**
     Update the debug label to reflect the current camera position.
     
     - parameter floatLength: `Int` number of decimel points to round float values.
     */
    public func updateLabels(floatLength: Int=2) {
        var debugString = "Camera: x: 0, y: 0, zoom: 1.0"
        if let camera = camera {
            let xpos = String(format: "%.\(String(floatLength))f", camera.position.x)
            let ypos = String(format: "%.\(String(floatLength))f", camera.position.y)
            debugString = "Camera: x: \(xpos), y: \(ypos), zoom: 1.0"
        }
        
        if let debugLabel = debugLabel {
            debugLabel.text = debugString
        }
    }
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        let touch = touches.first!
        let viewTouchLocation = touch.locationInNode(self)
        if let camera = camera {
            camera.position = viewTouchLocation
        }
        
    }
    
    override public func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        updateLabels()
    }
}
