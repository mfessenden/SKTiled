//
//  SKTilemapCamera.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public class SKTilemapCamera: SKCameraNode {
    
    public let world: SKNode
    private var bounds: CGRect
    private var zoom: CGFloat = 0.0
    
    public init(scene: SKScene, view: SKView, worldNode node: SKNode) {
        world = node
        bounds = view.bounds
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
