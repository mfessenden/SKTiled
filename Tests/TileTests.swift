//
//  TileTests.swift
//  SKTiledTests
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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
fileprivate let testTilemapname = "test-tilemap"


class TileTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        if (testTilemap == nil) {
            if let tilemapUrl = TestController.default.getResource(named: testTilemapname, withExtension: "tmx") {
                testTilemap = SKTilemap.load(tmxFile: tilemapUrl.path, loggingLevel: .none)
            }
        }
    }
    
    /// Test to ensure that changing the `globalId` property of the `SKTile` object results in tile data being replace properly.
    func testTileGlobalIdChange() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapname)'")
            return
        }
        
        
        // the global ids we're going to switch
        let sourceId: UInt32 = 25
        let destId: UInt32 = 13
        
        // expected counts before the switch
        let expectedSourceIdCount = 165
        let expectedDestIdCount = 3
        
        
        let sourceTiles = tilemap.getTiles(globalID: sourceId)
        let destTiles = tilemap.getTiles(globalID: destId)
        
        // switch tile ids
        for tile in sourceTiles {
            tile.globalId = destId
        }
        

        // expected counts after the switch
        let updatedSourceIdCount = 0
        let updatedDestIdCount = expectedSourceIdCount + expectedDestIdCount
        
        
        // re-query the two global ids
        let udpatedSourceTiles = tilemap.getTiles(globalID: sourceId)
        let updatedDestTiles = tilemap.getTiles(globalID: destId)
        

        XCTAssert(udpatedSourceTiles.count == 0, "⭑ tile count for gid \(sourceId) should be zero, got \(udpatedSourceTiles.count).")
        XCTAssert(updatedDestTiles.count == updatedDestIdCount, "⭑ tile count for gid \(sourceId) should be \(updatedDestIdCount), got \(updatedDestTiles.count).")
        
        
        // check that the tile data for the updated tiles is correct
        let expectedDataType = "door"

        for updatedTile in updatedDestTiles {
            if updatedTile.tileData.type != expectedDataType {
                XCTFail("⭑ updated tile data type should be '\(expectedDataType)'.")
                return
            }
        }
    }
    
    
    /// This is a dupe of the `TileTests.testTileGlobalIdChange` test, only using the `SKTile.renderMode` attribute to change tile data.
    func testTileRenderModeChange() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapname)'")
            return
        }
        
        // the global ids we're going to switch
        let sourceId: UInt32 = 25
        let destId: UInt32 = 13
        
        // expected counts before the switch
        let expectedSourceIdCount = 165
        let expectedDestIdCount = 3
        
        
        let sourceTiles = tilemap.getTiles(globalID: sourceId)
        let destTiles = tilemap.getTiles(globalID: destId)
        
        // switch tile ids
        for tile in sourceTiles {
            tile.renderMode = TileRenderMode.animated(gid: 13)
        }
        
        
        // expected counts after the switch
        let updatedSourceIdCount = 0
        let updatedDestIdCount = expectedSourceIdCount + expectedDestIdCount
        
        
        // re-query the two global ids
        let udpatedSourceTiles = tilemap.getTiles(globalID: sourceId)
        let updatedDestTiles = tilemap.getTiles(globalID: destId)
        
        
        XCTAssert(udpatedSourceTiles.count == 0, "⭑ tile count for gid \(sourceId) should be zero, got \(udpatedSourceTiles.count).")
        XCTAssert(updatedDestTiles.count == updatedDestIdCount, "⭑ tile count for gid \(sourceId) should be \(updatedDestIdCount), got \(updatedDestTiles.count).")
        
        
        // check that the tile data for the updated tiles is correct
        let expectedDataType = "door"
        
        for updatedTile in updatedDestTiles {
            if updatedTile.tileData.type != expectedDataType {
                XCTFail("⭑ updated tile data type should be '\(expectedDataType)'.")
                return
            }
        }
    }

    /// Tests the `SKTile.spriteCopy` and `SKTile.replaceWithSpriteCopy` methods.
    func testTileSpriteCopyFunctions() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapname)'")
            return
        }
    }

    /// Tests the `SKTileData.copy(with:)` method.
    func testTileDataCloneFunctions() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testTilemapname)'")
            return
        }
    }
}
