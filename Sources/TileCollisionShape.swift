//
//  TileCollisionShape.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SpriteKit


/// ## Overview
///
/// A structure representing a tile collision shape.
///
/// ### Properties
///
/// | Property   | Description             |
/// |:-----------|:------------------------|
/// | `id`       | object id.              |
/// | `points`   | frame points.           |
///
internal class TileCollisionShape: TiledAttributedType {

    /// Object id.
    public var id: Int = 0

    /// Object points.
    public var points: [CGPoint] = []

    /// Unique node id.
    var uuid: String = UUID().uuidString

    /// Shape type.
    var type: String!

    /// Custom properties.
    var properties: [String: String] = [:]

    /// Ignore custom properties.
    var ignoreProperties: Bool = false

    /// Shape render quality.
    var renderQuality: CGFloat = 1
}


// MARK: - Extensions


extension TileCollisionShape: NSCopying {

    /// Create a copy of this node.
    ///
    /// - Parameter zone: copying zone.
    /// - Returns: node copy.
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TileCollisionShape()
        //copy.uuid = uuid
        copy.type = type
        copy.properties = properties
        copy.ignoreProperties = ignoreProperties
        copy.renderQuality = renderQuality
        copy.id = id
        //copy.position = position
        copy.points = points
        return copy
    }
}


extension TileCollisionShape {

    /// Parse the collision shape's properties.
    ///
    /// - Parameter completion: optional completion closure.
    func parseProperties(completion: (() -> Void)?) {
        if (ignoreProperties == true) { return }
        if (self.type == nil) { self.type = properties.removeValue(forKey: "type") }
    }
}


/// :nodoc: typealias for v1.2 compatibility.
typealias SKTileCollisionShape = TileCollisionShape
