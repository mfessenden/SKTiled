//
//  ParserTests.swift
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
import SpriteKit
@testable import SKTiled


/// Test the tiled parser
class ParserTests: XCTestCase {
    
    var tilemap: SKTilemap?
    let tilemapDelegate = TestMapDelegate()
    let tilesetDelegate = TestTilesetDelegate()
    var testBundle: Bundle!
    let tilemapName = "test-tilemap"
    
    override func setUp() {
        super.setUp()
        
        if (testBundle == nil) {
            #if SWIFT_PACKAGE
            testBundle = Bundle.module
            #else
            testBundle = Bundle(for: type(of: self))
            #endif
        }
        
        if (tilemap == nil) {
            print("➜ loading test tilemap: \"\(tilemapName)\"...")
            let mapurl = testBundle!.url(forResource: tilemapName, withExtension: "tmx")!
            tilemap = SKTilemap.load(tmxFile: mapurl.path, delegate: tilemapDelegate,
                                     tilesetDataSource: tilesetDelegate, loggingLevel: .none)
        }
    }

    override func tearDown() {
        super.tearDown()
    }

    /**
     Test the that the map can be successfull loaded.
     
     */
    func testMapExists() {
        XCTAssertNotNil(self.tilemap, "❗️tilemap should not be nil.")
    }
    
    /**
     Test that the map received the custom values from test delegates.
     
     */
    func testMapHasCorrectFlagsSet() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        let monstersTileset = tilemap.getTileset(named: "monsters-16x16")!
        XCTAssert(tilemap.zDeltaForLayers == 129, "❗️test delegate has a z-delta value of `129`")
        XCTAssert(monstersTileset.source.filename == "monsters-16x16.png", "❗️tileset source is incorrect: \"\(monstersTileset.source.filename)\"")
        XCTAssert(monstersTileset.tileSize.width == 16, "❗️tileset tile width is incorrect: \"\(monstersTileset.tileSize.width)\"")
    }
    
    /**
     Test that the map is calling back to delegates correctly.
     
     */
    func testMapIsUsingDelegates() {
        guard (tilemap != nil) else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        XCTAssertTrue(tilemapDelegate.mapRenderedSuccessfully, "❗️tilemap did not call back to delegate.")
    }
}
