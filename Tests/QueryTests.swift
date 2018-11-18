//
//  TilesetTests.swift
//  SKTiledTests
//
//  Created by Michael Fessenden on 10/27/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import XCTest
@testable import SKTiled


/// Test global id matching & parsing.
class QueryTests: XCTestCase {
    
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
     Test gid/id matching, etc.
     
     */
    func testQueryFunctions() {
        
        let testTilesetName = "items-8x8"
        let testLayerName = "Objects"
        let testGID: Int = 79
        
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        // <tileset firstgid="74" source="items-8x8.tsx"/>
        guard let tileset = tilemap.getTileset(named: testTilesetName) else {
            XCTFail("❗️tileset \"\(testTilesetName)\" cannot be loaded.")
            return
        }
        
        XCTAssert(tileset.tileSize == CGSize(width: 8, height: 8), "❗️tileset tile size is incorrect.")
        XCTAssert(tileset.firstGID == 74, "❗️tileset first gid is incorrect: \(tileset.firstGID)")
        
        guard let testLayer = tilemap.tileLayers(named: testLayerName).first else {
            XCTFail("❗️layer \"\(testLayerName)\" cannot be loaded.")
            return
        }
        
        
        let testTiles = testLayer.getTiles(globalID: testGID)
        XCTAssert(testTiles.count == 3, "❗️tile count for gid \(testGID) is incorrect: \(testTiles.count)")
    }
    
    /**
     Test to see if a tileset will return the proper tile from a global id.
     Tileset has been given an incorrect firstGID value of: 91
     
     Tile Data GID: 130
     - Local ID: 39
     - has `color` property of `#ffa07daa`
     */
    func testGlobalIDQuery() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        //let orangeTiles = tilemap.getTiles(globalID: 130)

    }
}
