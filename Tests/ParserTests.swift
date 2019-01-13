//
//  ParserTests.swift
//  SKTiledTests
//
//  Created by Michael Fessenden on 10/27/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import XCTest
import SpriteKit
@testable import SKTiled


class TestMapDelegate: SKTilemapDelegate {
    var zDeltaForLayers: CGFloat = 129
    var mapRenderedSuccessfully: Bool = false
    init() {}
    func didRenderMap(_ tilemap: SKTilemap) {
        mapRenderedSuccessfully = true
    }
}

class TestTilesetDelegate: SKTilesetDataSource {
    init() {}
    func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String {
        
        let fileURL = fileNamed.url
        var parentURL = fileNamed.parentURL
        let filename = FileManager.default.displayName(atPath: fileURL.path)
        var result = fileNamed
        
        if (filename == "items-8x8.png") {
            parentURL.appendPathComponent("items-alt-8x8.png")
            result = parentURL.path
        }
        return result
    }
}

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
            testBundle = Bundle(for: type(of: self))
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
