//
//  TileCollisionShape.swift
//  SKTiled
//
//  Created by Michael Fessenden.
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
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


/**
 A structure representing a tile collision shape.

 - parameter points:  `[CGPoint]` frame duration.
 */
internal class TileCollisionShape: SKTiledObject {

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


extension TileCollisionShape {

    /// Parse the collision shape's properties.
    func parseProperties(completion: (() -> Void)?) {
        if (ignoreProperties == true) { return }
        if (self.type == nil) { self.type = properties.removeValue(forKey: "type") }
    }
}



/// :nodoc: Typealias for v1.3 compatibility.
typealias SKTileCollisionShape = TileCollisionShape
