//
//  SKTileObject.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public enum ObjectType {
    case Rectangle
    case Ellipse
    case Polygon
}

/// simple object class
public class SKTileObject: SKShapeNode {
    
    public var objectType: ObjectType = ObjectType.Rectangle
    
    override public init(){
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
