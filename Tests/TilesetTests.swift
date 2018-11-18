//
//  TilesetTests.swift
//  SKTiledTests
//
//  Created by Michael Fessenden on 10/27/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import XCTest
@testable import SKTiled


/// Test tileset objects.
class TilesetTests: XCTestCase {
    
    var testBundle: Bundle!
    var tilemap: SKTilemap?
    var tileset: SKTileset?
    
    let tilesetName = "environment-8x8"
    
    override func setUp() {
        super.setUp()
        
        if (testBundle == nil) {
            TiledGlobals.default.loggingLevel = .none
            testBundle = Bundle(for: type(of: self))
        }
        
        if (tilemap == nil) {
            let mapurl = testBundle!.url(forResource: "test-tilemap", withExtension: "tmx")!
            tilemap = SKTilemap.load(tmxFile: mapurl.path, loggingLevel: .none)
            tileset = tilemap?.getTileset(named: tilesetName)
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /**
     Test to see if a named tileset can be properly queried.
     */
    func testTilesetExists() {
        XCTAssertNotNil(tileset, "❗️cannot access tileset: \"\(tilesetName)\"")
    }
    
    /**
     Test to see if a named tileset has the correct Tiled properties:
     
         name="environment-8x8"
         tilewidth="8"
         tileheight="8"
         spacing="0"
         tilecount="45"
         columns="15"
     
     */
    func testTilesetProperties() {
        guard let tileset = tileset else {
            XCTFail("❗️could not load test tileset.")
            return
        }
        
        XCTAssert(tileset.name == "environment-8x8", "❗️tileset name incorrect: \(tileset.name)")
        XCTAssert(tileset.tileSize == CGSize(width: 8, height: 8), "❗️tileset tile size is incorrect.")
        XCTAssert(tileset.spacing == 0, "❗️tileset spacing is incorrect: \(tileset.spacing)")
        XCTAssert(tileset.tilecount == 45, "❗️tileset tile count is incorrect: \(tileset.tilecount)")
        XCTAssert(tileset.columns == 15, "❗️tileset column count is incorrect: \(tileset.columns)")
        XCTAssert(tileset.firstGID == 1, "❗️tileset first gid is incorrect.")
    }
    
    /**
     Test to see if a tileset will return the proper tile from a global id.
     Tileset has been given an incorrect firstGID value of: 91
     
     Tile Data GID: 79
      - Local ID: 5
      - has `color` property of `#ffa07daa`
     */
    func testGlobalIDQuery() {
        guard let tilemap = tilemap,
            (tileset != nil) else {
            XCTFail("❗️could not load test assets.")
            return
        }
        
        // gid 79 is the key
        let keyid = 79
        let expectedLocalID = 5
        let expectedKeyCount = 3
        let keyTiles = tilemap.getTiles(globalID: keyid)
        XCTAssert(keyTiles.count == 3, "❗️tile count for gid \(keyid) should be \(expectedKeyCount): \(keyTiles.count)")
        
        var keyPropertyIsCorrect = true
        var keyIDsAreCorrect = true
        for tile in keyTiles {
            let tileColorHex = tile.tileData.stringForKey("color")
            keyPropertyIsCorrect = (tileColorHex != nil) && (tileColorHex == "#ffa07daa")
            keyIDsAreCorrect = (tile.tileData.localID == expectedLocalID) && (tile.tileData.globalID == keyid)
        }
        
        XCTAssert(keyPropertyIsCorrect == true, "❗️tiles with gid \(keyid) should have a `color` property")
        XCTAssert(keyIDsAreCorrect == true, "❗️tiles with gid \(keyid) should have a local id of \(expectedLocalID)")
    }
}
