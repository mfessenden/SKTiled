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
fileprivate var testBasicTilemap: SKTilemap?
fileprivate let testBasicTilemapName = "test-tilemap"


class TileTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        if (testBasicTilemap == nil) {
            if let tilemapUrl = TestController.default.getResource(named: testBasicTilemapName, withExtension: "tmx") {
                testBasicTilemap = SKTilemap.load(tmxFile: tilemapUrl.path, loggingLevel: .none)
            }
        }
    }

    /// Tests the `SKTile.spriteCopy` and `SKTile.replaceWithSpriteCopy` methods.
    func testTileSpriteCopyFunctions() {
        guard let tilemap = testBasicTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testBasicTilemapName)'")
            return
        }
    }

    /// Tests the `SKTileData.clone` functionality.
    func testTileDataCloneFunctions() {
        guard let tilemap = testBasicTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testBasicTilemapName)'")
            return
        }
    }
}
