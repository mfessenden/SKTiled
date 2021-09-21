//
//  TestMapDelegate.swift
//  SKTiledTests
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import XCTest
import SpriteKit
import GameplayKit
@testable import SKTiled


/// Class to act as a delegate to test the `TilemapDelegate` protocol.
class TestMapDelegate: TilemapDelegate {

    func didBeginParsing(_ tilemap: SKTilemap) {}

    func didAddTileset(_ tileset: SKTileset) {}

    func didAddLayer(_ layer: TiledLayerObject) {}

    func didReadMap(_ tilemap: SKTilemap) {}

    func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>) {}

    func objectForTileType(named: String?) -> SKTile.Type {
        return SKTile.self
    }

    func objectForVectorType(named: String?) -> SKTileObject.Type {
        return SKTileObject.self
    }

    func objectForGraphType(named: String?) -> GKGridGraphNode.Type {
        return SKTiledGraphNode.self
    }


    var zDeltaForLayers: CGFloat = 129
    var mapRenderedSuccessfully: Bool = false

    init() {}

    /// Called when the map is finished rendering.
    ///
    /// - Parameter tilemap: tilemap instance.
    func didRenderMap(_ tilemap: SKTilemap) {
        mapRenderedSuccessfully = true
    }

    /// Called whem a tile is about to be built.
    ///
    /// - Parameters:
    ///   - tile: tile object.
    ///   - globalID: tile global id.
    ///   - coord: tile coordinate.
    ///   - in: optional parent layer name.
    func willAddTile(globalID: UInt32, coord: simd_int2, in: String?) -> UInt32 {
        if (globalID == 25) {
            return 20
        }
        return globalID
    }

    /// Called whem a tile is about to be built.
    ///
    /// - Parameters:
    ///   - tile: tile object.
    ///   - globalID: tile global id.
    ///   - in: optional parent layer name.
    func willAddTile(globalID: UInt32, in: String?) -> UInt32 {
        if (globalID == 25) {
            return 20
        }
        return globalID
    }

    /// Provides custom attributes for objects of a certain *Tiled type*.
    ///
    /// - Parameters:
    ///   - type: type value.
    ///   - named: optional node name.
    /// - Returns: custom attributes dictionary.
    func attributesForNodes(ofType: String?,
                            named: String? = nil,
                            globalIDs: [UInt32] = []) -> [String : String]? {

        if (ofType == "key") {
            return ["metal": "gold", "pointValue": "2100"]
        }

        if (ofType == "floor") {
            if (globalIDs.contains(24)) {
                return ["metal": "gold", "pointValue": "450"]
            }

            if (globalIDs.contains(39)) {
                return ["metal": "silver", "pointValue": "100"]
            }
        }
        return nil
    }

    @objc public func mouseOverTileHandler(globalID: UInt32, ofType: String? = nil) -> ((SKTile) -> ())? {
        switch globalID {
            case 24, 25:
                return { (tile) in
                    tile.tileData.setValue(for: "mouseHandler", "1")
            }
            default:
                return nil
        }
    }
    
    /// Provides a mechanism for substitute custom SpriteKit node types in place of **Tiled** point objects.
    ///
    /// - Parameters:
    ///   - ofType: point object type.
    ///   - attributes: attributes parsed from **Tiled** reference.
    ///   - inLayer: optional parent layer name.
    @objc public func customNodeForPointObject(ofType: String, attributes: [String : String], inLayer: String?) -> SKNode? {
        if (ofType == "light") {
            let light = SKLightNode()
            if let lightColor = attributes["lightColor"] {
                light.lightColor = SKColor(hexString: lightColor)
                return light
            }
        }
        return nil
    }

}
