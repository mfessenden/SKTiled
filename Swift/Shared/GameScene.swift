//
//  GameScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public class GameScene: SKScene {
    
    public var worldNode: SKNode!
    public var cameraNode: SKCameraNode!
    public var tilemap: SKTilemap!
    public var debugLabel: SKLabelNode!
    
    // MARK: - Init
    override public init(size: CGSize) {
        super.init(size: size)
        
        // set up world node
        worldNode = SKNode()
        worldNode.name = "World"
        addChild(worldNode)
        worldNode.position = self.center
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func didMoveToView(view: SKView) {
        
        // set up camera
        cameraNode = SKCameraNode()
        addChild(cameraNode)
        cameraNode.position = self.center
        camera = cameraNode
        
        // setup camera label
        debugLabel = SKLabelNode(fontNamed: "Courier")
        debugLabel.text = "Camera: "
        debugLabel.fontSize = 14.0
        cameraNode.addChild(debugLabel)
        debugLabel.position.y -= (view.bounds.size.height / 2.25)
        
        if let tilemapNode = SKTilemap.loadTMX("sample-map") {
            tilemap = tilemapNode
            worldNode.addChild(tilemap)
            
            // set the camera position to the tilemap center point
            //cameraNode.position = convertPoint(tilemap.centerPoint, fromNode: tilemap)
            tilemap.debugDraw = true
            tilemap.position = CGPointZero
            
            let debugShape = SKShapeNode(rectOfSize: tilemap.size)
            tilemap.addChild(debugShape)
            debugShape.position = CGPointZero
            debugShape.zPosition = CGFloat(tilemap.lastIndex + 2) * tilemap.zDeltaForLayers
            debugLabel.zPosition = debugShape.zPosition
            debugShape.antialiased = false
            
            debugShape.strokeColor = SKColor(red: 0, green: 1.0, blue: 0, alpha: 0.75)
            debugShape.lineWidth = 1
        }
    }
    
    /**
     Update the debug label to reflect the current camera position.
     */
    public func updateCameraLabel() {
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
        let viewTouchLocation = touch.locationInNode(self)
        if let camera = camera {
            camera.position = viewTouchLocation
            updateCameraLabel()
        }
    }
    
    override public func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
