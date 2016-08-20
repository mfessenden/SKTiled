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
            return baseLayer.debugDraw
        } set {
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
        guard (layerCount > 0) else { return }
        let largestName = layerNames().maxElement() { (a, b) -> Bool in a.characters.count < b.characters.count }
        let nameStr = "# Tilemap \"\(name!)\": \(layerCount) Layers:"
        let filled = String(repeating: "-", count: nameStr.characters.count)
        print("\n\(nameStr)\n\(filled!)")
        for layer in allLayers() {
            if (layer != baseLayer) {
                let layerName = layer.name != nil ? layer.name! : "(None)"
                let nameString = "\"\(layerName)\""
                print("\(layer.index): \(layer.layerType.stringValue.capitalizedString.zfill(6, pattern: " ", padLeft: false)) \(nameString.zfill(largestName!.characters.count + 2, pattern: " ", padLeft: false))   pos: \(layer.position.roundTo(1)), size: \(layer.sizeInPoints.roundTo(1)),  offset: \(layer.offset.roundTo(1)), anc: \(layer.anchorPoint.roundTo())")
            
            }
        }
        print("\n")
    }
}
