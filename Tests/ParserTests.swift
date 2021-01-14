//
//  ParserTests.swift
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



let testXmlString = """
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.4" tiledversion="1.4.3" orientation="orthogonal" renderorder="right-down" width="4" height="4" tilewidth="8" tileheight="8" infinite="0" nextlayerid="3" nextobjectid="1">
 <tileset firstgid="1" name="environment-8x8" tilewidth="8" tileheight="8" tilecount="45" columns="15">
  <image source="environment-8x8.png" width="120" height="24"/>
 </tileset>
 <layer id="1" name="Floor" width="4" height="4">
  <data encoding="base64" compression="zlib">
   eJyTZGBgkABidSgtiUQjs9XRxGEYADjwAag=
  </data>
 </layer>
 <layer id="2" name="Walls" width="4" height="4">
  <data encoding="base64" compression="zlib">
   eJzjYmBg4ABiTijmZkAAEFsNic8FxOJAzAsVB7EBFSgAzA==
  </data>
 </layer>
</map>
"""



/// Test the tiled parser
class ParserTests: XCTestCase {

    var tilemap: SKTilemap?
    let tilemapDelegate = TestMapDelegate()
    let tilesetDelegate = TestTilesetDelegate()
    let tilemapName = "test-tilemap"

    
    override func setUp() {
        super.setUp()
        
        if let mappath = Bundle(for: ParserTests.self).path(forResource: tilemapName, ofType: "tmx") {
            tilemap = SKTilemap.load(tmxFile: mappath, delegate: tilemapDelegate, tilesetDataSource: tilesetDelegate, loggingLevel: .none)
        } else {
            XCTFail("⭑ Cannot find test tilemap.")
        }
    }

    override func tearDown() {
        super.tearDown()
    }

    /// Test the that the map can be successfull loaded.
    func testMapExists() {
        XCTAssertNotNil(self.tilemap, "⭑ tilemap should not be nil.")
    }
    
    /// Test that the map received the custom values from test delegates.
    func testMapHasCorrectFlagsSet() {
        guard let tilemap = tilemap else {
            XCTFail("⭑ tilemap did not load.")
            return
        }

        let monstersTileset = tilemap.getTileset(named: "monsters-16x16")!
        XCTAssert(tilemap.zDeltaForLayers == 129, "⭑ test delegate has a z-delta value of `129`")
        XCTAssert(monstersTileset.source.filename == "monsters-16x16.png", "⭑ tileset source is incorrect: '\(monstersTileset.source.filename)'")
        XCTAssert(monstersTileset.tileSize.width == 16, "⭑tileset tile width is incorrect: '\(monstersTileset.tileSize.width)'")
    }

    /// Test that the map is calling back to delegates correctly.
    func testMapIsUsingDelegates() {
        guard (tilemap != nil) else {
            XCTFail("⭑ tilemap did not load.")
            return
        }
        XCTAssertTrue(tilemapDelegate.mapRenderedSuccessfully, "⭑tilemap did not call back to delegate.")
    }


    /// Test that the parser can correctly parse an xml string.
    func testStringParsing() {

    }
}
