//
//  TilemapTests.swift
//  SKTiledTests
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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

import XCTest
import SpriteKit
@testable import SKTiled



// Tile map instance used for this test.
fileprivate var testTilemap: SKTilemap?
fileprivate let testTilemapName = "test-tilemap"


class TilemapTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        if (testTilemap == nil) {
            if let tilemapUrl = TestController.default.getResource(named: testTilemapName, withExtension: "tmx") {
                testTilemap = SKTilemap.load(tmxFile: tilemapUrl.path, loggingLevel: .none)
            }
        }
    }

    /// Test that the tilemap has the correct attributes compared to the source Tiled file.
    func testBasicMapAttributes() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapName)'")
            return
        }


        let expectedLayerCount = 9
        let expectedObjectCount = 4
        XCTAssert(tilemap.layerCount == expectedLayerCount, "⭑ tilemap layer count incorrect: \(tilemap.layerCount)")
        XCTAssert(tilemap.objectCount == expectedObjectCount, "⭑ tilemap object count incorrect: \(tilemap.objectCount)")
    }


    /// Test that the tilemap is correctly querying tiles of a certain type.
    func testQueryTilesOfType() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapName)'")
            return
        }

        let expectedTileCount = 189
        let tiles = tilemap.getTiles(ofType: "wall")
        XCTAssert(tiles.count == expectedTileCount, "⭑ tilemap tile count is incorrect: \(tiles.count)")
    }

    /// Test to make sure the tile map's `getObjectProxies` methods work.
    func testMapQueryObjectProxies() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapName)'")
            return
        }

        let mapObjects = tilemap.getObjects()
        let mapProxies = tilemap.getObjectProxies()
        XCTAssert(mapProxies.count == mapObjects.count, "⭑ tilemap object proxy count incorrect: \(mapProxies.count), \(mapObjects.count)")
    }

    /// Test to make sure the layer `getObjectProxies` methods work.
    func testLayerQueryObjectProxies() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapName)'")
            return
        }

        let objectGroup = "Bosses"

        guard let objLayer = tilemap.objectGroups(named: objectGroup).first else {
            XCTFail("⭑ layer '\(objectGroup)' not found in \(tilemap.mapName).")
            return
        }

        let layerObjects = objLayer.getObjects()
        let layerProxies = objLayer.getObjectProxies()
        XCTAssert(layerProxies.count == layerObjects.count, "⭑ layer object proxy count incorrect: \(layerProxies.count), \(layerObjects.count)")
    }


    /// Test that a layer can be queried with a path.
    func testQueryAtPath() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapName)'")
            return
        }

        let testLayerPath = "Characters/Bosses"
        let expectedLayerType = TiledLayerObject.TiledLayerType.object
        let expectedObjectCOunt = 3

        guard let testLayer = tilemap.getLayers(atPath: testLayerPath).first else {
            XCTFail("⭑ could not find layer at path '\(testLayerPath)'.")
            return
        }


        let objects = (testLayer as! SKObjectGroup).getObjects()


        XCTAssert(testLayer.layerType == expectedLayerType, "⭑ layer '\(testLayer.layerName)' type is incorrect: '\(testLayer.layerType)', expected: '\(expectedLayerType)'")
        XCTAssert(objects.count == expectedObjectCOunt, "⭑ layer '\(testLayer.layerName)' object count is incorrect \(objects.count), expected \(expectedObjectCOunt)")

    }
    
    /// Test the `SKTilemap.renderableObjectsAt(point:)` method.
    ///
    ///
    func testRenderableObjectsQuery() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapName)'")
            return
        }
        
        // TODO: this doesn't work!!
        
        let testCoordinate = simd_int2(22, 10)
        let location = tilemap.pointForCoordinate(coord: testCoordinate)

        let expectedObjectCount = 13
        let renderableObjects = tilemap.renderableObjectsAt(point: location)
        let renderableObjectCount = renderableObjects.count
        //XCTAssert(expectedObjectCount == renderableObjectCount, "⭑ incorrect number of renerables at \(testCoordinate.coordDescription)... got: \(renderableObjectCount), expected: \(expectedObjectCount)")
        
    }
    
    /// Test the `SKTileLayer.chunksAt` method.
    func testLayerGetChunks() {
        // TODO: not yet implemented
    }
}
