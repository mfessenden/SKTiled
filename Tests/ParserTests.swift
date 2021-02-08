//
//  ParserTests.swift
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



let testXmlStringSimple = """
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


/// this is the string data from `test-tilemap.tmx`
let testXmlStringComplex = """
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.4" tiledversion="1.4.3" orientation="orthogonal" renderorder="right-down" compressionlevel="0" width="30" height="16" tilewidth="8" tileheight="8" infinite="0" nextlayerid="13" nextobjectid="5">
 <properties>
  <property name="allowZoom" type="bool" value="false"/>
  <property name="doubles" value="1.2, 5.4, 12, 18.25"/>
  <property name="gridColor" type="color" value="#e2f58823"/>
  <property name="integers" value=" 0,1,2 ,3,4,5,6,7 ,8,9, 10"/>
  <property name="isStatic" type="bool" value="false"/>
  <property name="strings" value="tom,dick , harry"/>
 </properties>
 <tileset firstgid="1" source="environment-8x8.tsx"/>
 <tileset firstgid="46" source="characters-8x8.tsx"/>
 <tileset firstgid="74" source="items-8x8.tsx"/>
 <tileset firstgid="90" source="portraits-8x8.tsx"/>
 <tileset firstgid="104" source="monsters-16x16.tsx"/>
 <layer id="1" name="Floor" width="30" height="16">
  <data encoding="base64" compression="zlib">
   eAFt0klqA0EQRNE+hgTW2ve/oRXgB5+iFkVkxpSN0Pt5nt/ve33f+38edqfjhrh5+6rNo2u8vOwn3Nkhx6t3fHubk3GHl3+oj8Zb3NznxjhdbkF5Xre2d26vrv0OPHqK1Ta3g8/dn+j65WXxzW6uTx+Olw/Od9PwbtnPXro7cD7a+t3QY6fxDnHtcLeoQwby2IfmZvBDmen4cZ3PXa7f23z5Zbe3Q55mh82P62vPrXecnqEunL239ZS73cEN93/V35w7vO2eJmO289uX6+yG76fzVDefnfPyQ33bm9vc3b123jLt29weHct5vcGrd6jDrJ+3uxnK6HNrOo5H33bazb8s75C32H4eufo2703z6M3Rxm2W2e6N78wD6fqHXns7Vz+7/wBx2Da+
  </data>
 </layer>
 <layer id="3" name="Walls" width="30" height="16">
  <data encoding="base64" compression="zlib">
   eAGV00tSAzEMBNAs+RwgK7acM0fHD9JUM8gMUZViWVK32vbkerlcnpc/Lb8uf7+vL/dVTf51uVrqWVPPPjz64cKpnjmrdpOfDD7WMewjNvXT0JzNR+9kMGfWsyYeM6c8XvxvgmU9a9f/1fn122dpDenB0ZzJW+XVcTRWXq59bX/s++18J0eD3c3tWY3b5bun53Y+sZm7ubs8rWd21oN73eUtPO7EeThs3iG59N/Xz77Wp89ZrbBWdTlzokfcuFX+NrjJcLUd92r/uedoaK6O1Y/e9Ulfn2Xip+tMW2ZMeLWeMfVO9wEz6YVvPf3u+qMXvj3a1MVq4vyXaLBPfoW/LBzHwqT/0R7ad/w0TXace9zDONNfBrPjP8OGd9K942yMHvPzHuLoUev3TG3lbonhxHTm/uS4HA+fGCf/APQRENI=
  </data>
 </layer>
 <layer id="6" name="Objects" width="30" height="16">
  <data encoding="base64" compression="zlib">
   eAFjYBh8wJ+BoYEarvKmhiGD1AxgGNEN8NLNJupaBAyjA9QyUZlaBg2gOaT4IXgA3TkQVofhsNQHhzithKmd13CZx4ejjKVnuUJqGJKSfkk1e6DUAwDVVQTb
  </data>
 </layer>
 <group id="9" name="Characters">
  <objectgroup id="7" name="Bosses">
   <object id="1" template="Templates/dragon-yellow.tx" x="56" y="56"/>
   <object id="2" template="Templates/dragon-blue.tx" x="176" y="88"/>
   <object id="3" template="Templates/dragon-green.tx" gid="2147483755" x="216" y="120"/>
  </objectgroup>
  <layer id="4" name="Monsters" width="30" height="16">
   <data encoding="base64" compression="zlib">
   eAFjYBh5QG/keXnUx2SEgDUDQwM+bfYE5PHppZec+xBwI73CYtSekRMChkMg3R82YGYAANwwBBc=
  </data>
  </layer>
 </group>
 <group id="11" name="HUD">
  <layer id="2" name="Portraits" width="30" height="16">
   <data encoding="base64" compression="zlib">
   eAFjYBgFoyEwGgKjITAaAqMhMDhCIGpwOIPmrtjqx84AAF5EAWU=
  </data>
  </layer>
  <objectgroup id="12" name="Text">
   <object id="4" x="18" y="112" width="38" height="9">
    <text fontfamily=".AppleSystemUIFontMonospaced" pixelsize="7" wrap="1" color="#ffffff">Level 1</text>
   </object>
  </objectgroup>
 </group>
</map>
"""

/// Testing for the `SKTiled` parser.
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

    /// Test the that the map can be successfull loaded.
    func testMapExists() {
        XCTAssertNotNil(self.tilemap, "⭑ test tilemap failed to load.")
    }

    /// Test that the map received the custom values from test delegates.
    func testMapHasCorrectFlagsSet() {
        guard let tilemap = tilemap else {
            XCTFail("⭑ test tilemap failed to load.")
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
            XCTFail("⭑ test tilemap failed to load.")
            return
        }
        XCTAssertTrue(tilemapDelegate.mapRenderedSuccessfully, "⭑tilemap did not call back to delegate.")
    }


    /// Test that the parser can correctly parse an xml string.
    func testTilemapParsingFromStringData() {
        if let resourcePath = Bundle(for: ParserTests.self).path(forResource: tilemapName, ofType: "png") {
            guard let testTilemap = SKTilemap.load(string: testXmlStringComplex, documentRoot: resourcePath) else {
                XCTFail("⭑ Failed to load tilemap from string data.")
                return
            }


            let expectedMapVersion = "1.4.3"
            let parsedMapVersion = testTilemap.tiledversion

            let parsedTilesetCount = testTilemap.tilesets.count
            let expectedTilesetCount = 5



            XCTAssert(parsedMapVersion == expectedMapVersion, "⭑ incorrect tilemap version '\(parsedMapVersion)', expected '\(expectedMapVersion)'")
            XCTAssert(parsedTilesetCount == expectedTilesetCount, "⭑ incorrect tileset count '\(parsedTilesetCount)', expected '\(expectedTilesetCount)'")

            
            
            /// Query objects
            
            let textObjectText = "Level 1"
            let expectedObjectId = 4
            
            guard let textObject = testTilemap.getObjects(withText: textObjectText).first else {
                XCTFail("⭑ Cannot find text object with text '\(textObjectText)'.")
                return
            }
            
            let textObjectId = textObject.id
            
            XCTAssert(textObjectId == expectedObjectId, "⭑ incorrect object id '\(textObjectId)', expected '\(expectedObjectId)'")
        }
    }
}
