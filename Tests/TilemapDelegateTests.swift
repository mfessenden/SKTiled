//
//  TilemapDelegateTests.swift
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



// Tile map instance used for this test.
fileprivate var testDelegateTilemap: SKTilemap?
fileprivate let testDelegateTilemapName = "test-tilemapdelegate"
fileprivate let testTilemapDelegate = TestMapDelegate()


class TilemapDelegateTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        if (testDelegateTilemap == nil) {
            TiledGlobals.default.loggingLevel = .none
            if let tilemapUrl = TestController.default.getResource(named: testDelegateTilemapName, withExtension: "tmx") {
                print("\n\n▹ loading tilemap '\(testDelegateTilemapName)' with delegate:  '\(testTilemapDelegate)'...\n")
                testDelegateTilemap = SKTilemap.load(tmxFile: tilemapUrl.path, delegate: testTilemapDelegate)
            }
        }
    }

    /// Test that the tilemap has the correct attributes compared to the source Tiled file.
    ///
    ///    Uses the `TilemapDelegate.attributesForNodes` method.
    ///
    func testAttributesForType() {
        guard let tilemap = testDelegateTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testDelegateTilemapName)'")
            return
        }

        let globalIdToTest: UInt32 = 39             // '38' works
        let expectedAttributeName = "metal"
        // count should be 154
        let floorTiles = tilemap.getTiles(globalID: globalIdToTest)

        var customAttributeFound = true

        for floorTile in floorTiles {
            if floorTile.tileData.hasKey("metal") == false {
                customAttributeFound = false
            }
        }

        XCTAssert(customAttributeFound == true, "⭑ custom attribute `\(expectedAttributeName)` not found.")
    }

    /// Test the `TilemapDelegate.willAddTile` method above.
    ///
    ///   the delegate is substituting the test global id (here 25) as the tilemap is being created.
    ///   If successful, the tile count for this global ID *should* be zero.
    func testOverrideGlobalID() {
        guard let tilemap = testDelegateTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testDelegateTilemapName)'")
            return
        }

        let globalIdToTest: UInt32 = 25
        let floorTiles = tilemap.getTiles(globalID: globalIdToTest)

        // replaced tile count should be 165
        XCTAssert(floorTiles.count == 0, "⭑ error overriding global id \(globalIdToTest) in map '\(testDelegateTilemapName)', tile count: \(floorTiles.count)")
    }
    
    /// Test the `TilemapDelegate.customNodeForPointObject` method.
    ///
    ///   in the test scene, the point object becomes a light node.
    func testCustomPointObjects() {
        guard let tilemap = testDelegateTilemap else {
            XCTFail("⭑ failed to load tilemap '\(testDelegateTilemapName)'")
            return
        }
        
        let testLayerName = "Objects"
        let expectedLightColorHexString = "#ffedce9a"
        guard let objectLayer = tilemap.objectGroups(named: testLayerName).first else {
            XCTFail("⭑ invalid layer '\(testLayerName)'")
            return
        }
        
        var lightNode: SKLightNode?
        objectLayer.enumerateChildNodes(withName: ".//*") { node, stop in
            if let light = node as? SKLightNode {
                lightNode = light
                stop.initialize(to: true)
            }
        }
        
        guard let customLight = lightNode else {
            XCTFail("⭑ failed to create light node.")
            return
        }
        
        /// test to see if the light color has been properly parsed
        let customLightColorHexString = customLight.lightColor.hexString()
        XCTAssert(customLightColorHexString == expectedLightColorHexString, "⭑ invalid light color: \(customLightColorHexString), expected \(expectedLightColorHexString)")
        
    }
}
