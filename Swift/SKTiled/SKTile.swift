//
//  SKTile.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/// represents a single tile object.
public class SKTile: SKSpriteNode {
    
    public var tileData: SKTilesetData
    weak public var layer: SKTileLayer!         // layer parent, assigned on add
    
    public var highlight: Bool = false {
        didSet {
            guard oldValue != highlight else { return }
            
            color = (highlight == true) ? SKColor.whiteColor() : SKColor.clearColor()
            colorBlendFactor = (highlight == true) ? 0.8 : 0
            if (highlight == true) {
                let fadeAction = SKAction.colorizeWithColor(SKColor.clearColor(), colorBlendFactor: 0, duration: 4)
                runAction(fadeAction)
            }
        }
    }
    
    
    public init(data: SKTilesetData){
        self.tileData = data
        super.init(texture: data.texture, color: SKColor.clearColor(), size: data.texture.size())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension SKTile {
    
    override public var description: String {
        var descString = "\(tileData.description)"
        if let layer = layer {
            descString += ", Layer: \"\(layer.name!)\""
        }
        return descString
    }
    
    override public var debugDescription: String {
        return description
    }
}