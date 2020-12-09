//
//  PropertiesTests.swift
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


// Tile map instance used for this test.
var propertiesTestTilemap: SKTilemap?
let propertiesTestTilemapName = "test-tilemap"



/// Tests to deterine whether custom properties are being interpreted correctly.
class PropertiesTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        if (propertiesTestTilemap == nil) {
            if let tilemapUrl = TestController.default.getResource(named: propertiesTestTilemapName, withExtension: "tmx") {
                propertiesTestTilemap = SKTilemap.load(tmxFile: tilemapUrl.path, loggingLevel: .none)
            }
        }
    }

    /// Test the `TiledObjectType.stringArrayForKey` function.
    ///
    /// The actual property string is: `tom,dick , harry`, so we're also
    /// testing the parser's ability to strip out whitespaces correctly.
    func testStringArrayProperties() {
        guard let tilemap = propertiesTestTilemap else {
            XCTFail("⭑ failed to load tilemap '\(propertiesTestTilemapName)'")
            return
        }
        
        var stringArrayProperties: [String] = []
        stringArrayProperties = tilemap.stringArrayForKey("strings")
        XCTAssertEqual(stringArrayProperties, ["tom", "dick", "harry"], "⭑could not parse string array properties from map.")
    }

    ///  Test the `TiledObjectType.integerArrayForKey` function.
    ///
    ///  The actual property string is: " 0,1,2 ,3,4,5,6,7 ,8,9, 10", so we're
    ///  also testing the parser's ability to strip out whitespaces correctly.
    ///
    func testIntArrayProperties() {
        var intArrayProperties: [Int] = []
        if let tilemap = propertiesTestTilemap {
            intArrayProperties = tilemap.integerArrayForKey("integers")
        }

        XCTAssertEqual(intArrayProperties, [0,1,2,3,4,5,6,7,8,9,10], "⭑could not parse integer array properties from map.")
    }

    /// Test the `TiledObjectType.doubleArrayForKey` function.
    func testDoubleArrayProperties() {
        var doubleArrayProperties: [Double] = []
        if let tilemap = propertiesTestTilemap {
            doubleArrayProperties = tilemap.doubleArrayForKey("doubles")
        }
        XCTAssertEqual(doubleArrayProperties, [1.2, 5.4, 12, 18.25], "⭑could not parse double array properties from map.")
    }


    // MARK: Ignore Properties


    ///  Test the `ignoreProperties` argument in the tilemap load method.
    ///
    ///  The `properties` test map has a map boolean property of `allowZoom`
    ///  set to false. If the tilemap ignores the properties parsing phase,
    ///  the `SKTilemap.allowZoom` should remain true.
    func testPropertiesAreIgnored() {
        let testBundle = Bundle.init(for: PropertiesTests.self)
        guard let mapurl = testBundle.url(forResource: propertiesTestTilemapName, withExtension: "tmx") else {
            XCTFail("⭑ could not find tilemap file '\(propertiesTestTilemapName)'")
            return
        }
        
        guard let ignoredMap = SKTilemap.load(tmxFile: mapurl.path, ignoreProperties: true, loggingLevel: .none) else {
            XCTFail("⭑ failed to load tilemap '\(propertiesTestTilemapName)'")
            return
        }
        XCTAssertFalse(ignoredMap.allowZoom == false, "⭑tilemap `allowZoom` property should still be the default `true` value")
    }
    
    /// Test the `TiledObjectType.getValue(for:defaultValue:)` method.
    func testQueryWithDefaultValue() {
        guard let tilemap = propertiesTestTilemap else {
            XCTFail("⭑ failed to load tilemap '\(propertiesTestTilemapName)'")
            return
        }
        
        
        guard let wallsLayer = tilemap.tileLayers(named: "Walls").first else {
            XCTFail("⭑ no layer named 'Walls' found in map '\(propertiesTestTilemapName)'")
            return
        }
        
        
        
        _ = wallsLayer.getValue(for: "isStatic", defaultValue: "true")
        wallsLayer.parseProperties(completion: nil)
        
        XCTAssertTrue(wallsLayer.isStatic == true)
    }
    
    func testQueryPropertyWithSubscript() {
        guard let tilemap = propertiesTestTilemap else {
            XCTFail("⭑ failed to load tilemap '\(propertiesTestTilemapName)'")
            return
        }
        
        XCTAssertEqual(tilemap["isStatic"], "false", "⭑ could not query property via subscript.")
    }
    
    func testAddPropertyValueWithSubscript() {
        guard let tilemap = propertiesTestTilemap else {
            XCTFail("⭑ failed to load tilemap '\(propertiesTestTilemapName)'")
            return
        }
        
        tilemap["genre"] = "roguelike"
        XCTAssertEqual(tilemap["genre"], "roguelike", "⭑ could not add property via subscript.")
    }
    
    /// Test the `getTilesWithProperty` method. The `environment-8x8`
    ///
    /// tileset has several tiles with a property named `object`. Here we're looking for a value of `hole`.
    func testGetTilesWithProperty() {
        guard let tilemap = propertiesTestTilemap else {
            XCTFail("⭑ failed to load tilemap '\(propertiesTestTilemapName)'")
            return
        }

        let objectKey = "object"
        let objectValue = "hole"
        let expectedObjectCount = 2
        
        
        let doorKey = "isDoor"
        let doorVal = true
        let expectedDoorsCount = 3
        
        let holes = tilemap.getTilesWithProperty(objectKey, objectValue)
        let doors = tilemap.getTilesWithProperty(doorKey, doorVal)
        
        XCTAssertEqual(holes.count, expectedObjectCount, "⭑ expected \(expectedObjectCount) tiles with the value '\(objectKey): \(objectValue)', got \(holes.count)")
        
        XCTAssertEqual(doors.count, expectedDoorsCount, "⭑ expected \(expectedDoorsCount) tiles with the value '\(doorKey): \(doorVal)', got \(doors.count)")
        
    }
}
