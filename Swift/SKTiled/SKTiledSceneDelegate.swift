//
//  SKTiledSceneDelegate.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/23/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


protocol SKTiledSceneDelegate {
    var worldNode: SKNode! { get set }
    // TODO: replace this with a custom camera
    var cameraNode: SKCameraNode! { get set }
    var tilemap: SKTilemap! { get set }    
}
