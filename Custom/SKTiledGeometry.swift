//
//  SKTiledGeometry.swift
//  SKTiled
//
//  Created by Michael Fessenden on 9/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit


// can't have this as hashable because of associated type error
public protocol SKTiledGeometry {
    /// Reference to the parent layer.
    weak var layer: TiledLayerObject! { get set }
    /// Node position
    var position: CGPoint { get set }
    /// Node depth
    var zPosition: CGFloat { get set }
    // Node object vertices.
    var points: [CGPoint] { get set }
    /// Return the vertices for the objects' bounding shape.
    func getVertices() -> [CGPoint]
    /// Draw the object's bounding shape
    func drawBounds()
    
    var visible: Bool { get set }
    var opacity: CGFloat { get set }
}
