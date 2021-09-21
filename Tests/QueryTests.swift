//
//  TilesetTests.swift
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


/// Test global id matching & parsing.
class QueryTests: XCTestCase {
    
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
}
