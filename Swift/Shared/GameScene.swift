//
//  GameScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


class GameScene: SKScene {
    
    var tilemap: SKTilemap!
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        let tmxfileName = "sample-map"
        if let tilemap = SKTilemap.loadTMX(tmxfileName) {
            addChild(tilemap)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
