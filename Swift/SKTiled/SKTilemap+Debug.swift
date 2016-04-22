//
//  SKTilemap+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
import GameplayKit



public extension SKTilemap {
    
    public func debugLayers() {        
        for layer in tileLayers {
            if let name = layer.name {
                print("Layer: \"\(name)\"")
            }
        }
    }
}