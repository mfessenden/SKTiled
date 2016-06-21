//
//  SKTiledSceneDelegate.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/23/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


protocol SKTiledSceneDelegate {
    // world node container
    var worldNode: SKNode! { get set }
    // scene camera
    var cameraNode: SKTiledSceneCamera! { get set }
    var tilemap: SKTilemap! { get set }    
}
