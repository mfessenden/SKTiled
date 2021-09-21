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


class PropertiesTests: XCTestCase {
    
    var testBundle: Bundle!
    var tilemap: SKTilemap?
    
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
            let mapurl = testBundle!.url(forResource: "test-tilemap", withExtension: "tmx")!
            tilemap = SKTilemap.load(tmxFile: mapurl.path, loggingLevel: .none)
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /**
     Test the `SKTiledObject.stringArrayForKey` function.
     
     The actual property string is: "tom,dick , harry", so we're also
     testing the parser's ability to strip out whitespaces correctly.
     
     */
    func testStringArrayProperties() {
        var stringArrayProperties: [String] = []
        if let tilemap = tilemap {
            stringArrayProperties = tilemap.stringArrayForKey("strings")
        }
        
        XCTAssertEqual(stringArrayProperties, ["tom", "dick", "harry"])
    }
    
    /**
     Test the `SKTiledObject.integerArrayForKey` function.
     
     The actual property string is: " 0,1,2 ,3,4,5,6,7 ,8,9, 10", so we're
     also testing the parser's ability to strip out whitespaces correctly.
     
     */
    func testIntArrayProperties() {
        var intArrayProperties: [Int] = []
        if let tilemap = tilemap {
            intArrayProperties = tilemap.integerArrayForKey("integers")
        }
        
        XCTAssertEqual(intArrayProperties, [0,1,2,3,4,5,6,7,8,9,10])
    }
    
    /**
     Test the `SKTiledObject.doubleArrayForKey` function.
     
     */
    func testDoubleArrayProperties() {
        var doubleArrayProperties: [Double] = []
        if let tilemap = tilemap {
            doubleArrayProperties = tilemap.doubleArrayForKey("doubles")
        }
        XCTAssertEqual(doubleArrayProperties, [1.2, 5.4, 12, 18.25])
    }
    
    // MARK: Ignore Properties
    
    /**
     Test the `ignoreProperties` argument in the tilemap load method.
     
     The `properties` test map has a map boolean property of `allowZoom`
     set to false. If the tilemap ignores the properties parsing phase,
     the `SKTilemap.allowZoom` should remain true.
     */
    func testPropertiesAreIgnored() {
        let mapurl = testBundle!.url(forResource: "test-tilemap", withExtension: "tmx")!
        let ignoredMap = SKTilemap.load(tmxFile: mapurl.path, ignoreProperties: true)!
        XCTAssertFalse(ignoredMap.allowZoom == false, "❗️tilemap `allowZoom` property should still be the default `true` value")
    }
    
    /**
     Test the `getTilesWithProperty` method. The `environment-8x8` tileset has several tiles with a property named `object`.
     */
    func testGetTilesWithProperty() {
        let expectedPropertyValue = "hole"
        let expectedTileCount = 2
        if let tilemap = tilemap {
            let holes = tilemap.getTilesWithProperty("object", "hole")
            XCTAssertEqual(holes.count, expectedTileCount, "❗️ expected \(expectedTileCount) tiles with the value '\(expectedPropertyValue)', got \(holes.count)")
        }
    }
    
}
