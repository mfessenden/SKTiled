//
//  PropertiesTests.swift
//  SKTiledTests
//
//  Created by Michael Fessenden on 10/27/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import XCTest
@testable import SKTiled


class PropertiesTests: XCTestCase {
    
    var testBundle: Bundle!
    var tilemap: SKTilemap?
    
    override func setUp() {
        super.setUp()
        
        if (testBundle == nil) {
            TiledGlobals.default.loggingLevel = .none
            testBundle = Bundle(for: type(of: self))
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
}
