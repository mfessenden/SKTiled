//
//  SKTilemap+Debug.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


public extension SKTilemap {
    
    /// Visualize the current grid & bounds.
    public var debugDraw: Bool {
        get {
            return (baseLayer != nil) ? baseLayer!.debugDraw : false
        } set {
            guard let baseLayer = baseLayer else { return }
            guard newValue != baseLayer.debugDraw else { return }
            baseLayer.debugDraw = newValue
            baseLayer.showGrid = newValue
            showObjects = newValue
        }
    }
    
    /**
     Prints out all the data it has on the tilemap's layers.
     */
    public func debugLayers() {

    }
}
