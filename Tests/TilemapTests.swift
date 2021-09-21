//
//  TilemapTests.swift
//  SKTiledTests
//
//  Created by Michael Fessenden.
//
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
@testable import SKTiled


class TilemapTests: XCTestCase {
    
    var testBundle: Bundle!
    var tilemap: SKTilemap?
    let tilemapName = "test-tilemap"
    
    override func setUp() {
        super.setUp()
        
        if (testBundle == nil) {
            TiledGlobals.default.loggingLevel = .none
            #if SWIFT_PACKAGE
            testBundle = Bundle.module
            #else
            testBundle = Bundle(for: type(of: self))
            #endif
        }
        
        if (tilemap == nil) {
            let mapurl = testBundle!.url(forResource: tilemapName, withExtension: "tmx")!
            tilemap = SKTilemap.load(tmxFile: mapurl.path, loggingLevel: .none)
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /**
     Test that the tilemap has the correct attributes compared to the source
     Tiled file.
     
     */
    func testBasicMapAttributes() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        
        let expectedLayerCount = 7
        let expectedObjectCount = 3
        XCTAssert(tilemap.layerCount == expectedLayerCount, "❗️tilemap layer count incorrect: \(tilemap.layerCount)")
        XCTAssert(tilemap.objectCount == expectedObjectCount, "❗️tilemap object count incorrect: \(tilemap.objectCount)")
    }
    
    /**
     Test that the tilemap is correctly querying tiles of a certain type.
     
     */
    func testQueryTilesOfType() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        let expectedTileCount = 191
        let tiles = tilemap.getTiles(ofType: "wall")
        XCTAssert(tiles.count == expectedTileCount, "❗️tilemap tile count is incorrect: \(tiles.count)")
    }
    
    /**
     Test to make sure the `getObjectProxies` methods work.
     */
    func testMapQueryObjectProxies() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        let mapObjects = tilemap.getObjects()
        let mapProxies = tilemap.getObjectProxies()
        XCTAssert(mapProxies.count == mapObjects.count, "❗️tilemap object proxy count incorrect: \(mapProxies.count), \(mapObjects.count)")
    }
    
    /**
     Test to make sure the `getObjectProxies` methods work.
     */
    func testLayerQueryObjectProxies() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        let objectGroup = "Collision"
        
        guard let objLayer = tilemap.objectGroups(named: objectGroup).first else {
            XCTFail("❗️layer '\(objectGroup)' not found in \(tilemap.mapName).")
            return
        }
        
        let layerObjects = objLayer.getObjects()
        let layerProxies = objLayer.getObjectProxies()
        XCTAssert(layerProxies.count == layerObjects.count, "❗️layer object proxy count incorrect: \(layerProxies.count), \(layerObjects.count)")
    }
}
