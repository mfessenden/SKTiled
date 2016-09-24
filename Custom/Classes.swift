//
//  Classes.swift
//  SKTiled
//
//  Created by Michael Fessenden on 10/5/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


open class Dot: SKSpriteNode {
    open var pointValue: Int = 10
    
    public init(){
        super.init(texture: SKTexture(), color: SKColor.clear, size: CGSize.zero)
        colorBlendFactor = 0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


open class Pellet: Dot {
    
}
