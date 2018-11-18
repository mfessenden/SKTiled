//
//  TilemapTests.swift
//  SKTiledTests
//
//  Created by Michael Fessenden on 10/27/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

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
            testBundle = Bundle(for: type(of: self))
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
