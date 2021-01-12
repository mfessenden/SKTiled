//
//  FileParsingTests.swift
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
@testable import SKTiled


// Tile map instance used for this test.
fileprivate var tempalateTestsTilemap: SKTilemap?
fileprivate let tempalateTestsTilemapName = "test-templates"



class TemplateTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        if (tempalateTestsTilemap == nil) {
            if let tilemapUrl = TestController.default.getResource(named: tempalateTestsTilemapName, withExtension: "tmx") {
                tempalateTestsTilemap = SKTilemap.load(tmxFile: tilemapUrl.path, loggingLevel: .none)
            }
        }
    }

    /// Test to determine that template objects have the correct overrides.
    ///
    ///  template file data: gid: 4, width: 16, height: 16
    func testTemplateOverrides() {
        guard let tilemap = tempalateTestsTilemap else {
            XCTFail("⭑ failed to load tilemap '\(tempalateTestsTilemapName)'")
            return
        }
        
        /// Check template names
        let templateFiles: [String: String] = [
            "green": "Templates/dragon-green.tx",
            "yellow": "Templates/dragon-yellow.tx",
            "blue": "Templates/dragon-blue.tx",
        ]
        
        
        /*
         Name:      'parent-dragon1'
         Template:  'dragon-green.tx'
         Flipped:   none
         Properties:
            'o_point_value*' = 500 (set in tmx file)
            't_color*' = 'purple'  (overrides tile data property 'green')
            't_strength' = 4.0
            'to_strength' = 2.15
        */
        let node1Name = "parent-dragon1"
        let node1Id: UInt32 = 6
        let node1Height: CGFloat = 22.7273

        /*
         Name:      'baby-dragon1'
         Template:  'dragon-yellow.tx'
         Flipped:   none
         Properties:
            't_color' = 'yellow'
            't_strength' = 5.0
            'to_strength' = 8.67
        */
        let node2Name = "baby-dragon1"
        let node2Id: UInt32 = 7


        /*
         Name:      'baby-dragon2'
         Template:  'dragon-green.tx'
         Flipped:   [h]
         Properties:
            'o_strength*' = 1.0 (set in tmx file)
            't_color*' = 'green'
            't_strength' = 4.0
            'to_strength' = 2.15
        */
        let node3Name = "baby-dragon2"
        let node3Id: UInt32 = 8


        guard let node1Object = tilemap.getObject(withID: node1Id),
            let node1ObjectName = node1Object.name else {
            XCTFail("⭑ cannot load object with an id of: \(node1Id).")
            return
        }

        guard let node2Object = tilemap.getObject(withID: node2Id),
              let node2ObjectName = node2Object.name else {
            XCTFail("⭑ cannot load object with an id of: \(node2Id).")
            return
        }

        // object id: 8, template: "dragon-green.tx", name: "baby-dragon2"
        guard let node3Object = tilemap.getObject(withID: node3Id),
              let node3ObjectName = node3Object.name else {
            XCTFail("⭑ cannot load object with an id of: \(node3Id).")
            return
        }


        
        
        let param1 = "t_color"
        let param2 = "t_strength"
        let param3 = "o_strength"
        let param4 = "to_strength"
        
        

        print(node1Object.properties)
        print(node2Object.properties)
        print(node3Object.properties)

        
        

        // NODE 1: 'parent-dragon1'
        let expectedParam1Value1 = "purple"
        let expectedParam2Value1 = "4.0"
        let expectedParam3Value1 = "2.15"
        
        
        
        
        
        
        XCTAssertEqual(node1ObjectName, node1Name, "⭑ expected name: '\(node1ObjectName)', got '\(node1Name)'")
        XCTAssertEqual(node1Object.template, templateFiles["green"], "⭑ object id \(node1Id) has an invalid template; expected '\(templateFiles["green"]!)'")
        XCTAssertEqual(node1Object.size.height, node1Height, "⭑ expected object id: \(node1Id) height to be '\(node1Height)', got '\(node1Object.size.height)'")

        
        /*
        XCTAssertEqual(node1Object.stringForKey(param1), expectedParam1Value1, "⭑ expected object id: \(node1Id) value for '\(param1)' to be '\(expectedParam1Value1)', got '\(node1Object.stringForKey(param1))'")
        XCTAssertEqual(node1Object.stringForKey(param2), expectedParam2Value1, "⭑ expected object id: \(node1Id) value for '\(param2)' to be '\(expectedParam2Value1)', got '\(node1Object.stringForKey(param2))'")
        XCTAssertEqual(node1Object.stringForKey(param3), expectedParam3Value1, "⭑ expected object id: \(node1Id) value for '\(param3)' to be '\(expectedParam3Value1)', got '\(node1Object.stringForKey(param3))'")
        
        
        // NODE 2: 'baby-dragon1'
        
        let expectedParam1Value2 = "yellow"
        let expectedParam2Value2 = "5.0"
        let expectedParam3Value2 = "8.67"
        
        XCTAssertEqual(node2ObjectName, node2Name, "⭑ expected name: '\(node2ObjectName)', got '\(node2Name)'")
        XCTAssertEqual(node2Object.template, templateFiles["yellow"], "⭑ object id \(node2Id) has an invalid template; expected '\(templateFiles["yellow"]!)'")
        
        XCTAssertEqual(node2Object.stringForKey(param1), expectedParam1Value2, "⭑ expected object id: \(node2Id) value for '\(param1)' to be '\(expectedParam1Value2)', got '\(node2Object.stringForKey(param1))'")
        XCTAssertEqual(node2Object.stringForKey(param2), expectedParam2Value2, "⭑ expected object id: \(node2Id) value for '\(param2)' to be '\(expectedParam2Value2)', got '\(node2Object.stringForKey(param2))'")
        XCTAssertEqual(node2Object.stringForKey(param3), expectedParam3Value2, "⭑ expected object id: \(node2Id) value for '\(param3)' to be '\(expectedParam3Value2)', got '\(node2Object.stringForKey(param3))'")
        
        
        // NODE 2: 'baby-dragon2'
        
        let expectedParam1Value3 = "green"
        let expectedParam2Value3 = "4.0"
        let expectedParam3Value3 = "2.15"
        
        XCTAssertEqual(node3ObjectName, node3Name, "⭑ expected name: '\(node3ObjectName)', got '\(node3Name)'")
        XCTAssertEqual(node3Object.template, templateFiles["green"], "⭑ object id \(node3Id) has an invalid template; expected '\(templateFiles["green"]!)'")
        
        XCTAssertEqual(node3Object.stringForKey(param1), expectedParam1Value3, "⭑ expected object id: \(node3Id) value for '\(param1)' to be '\(expectedParam1Value3)', got '\(node3Object.stringForKey(param1))'")
        XCTAssertEqual(node3Object.stringForKey(param2), expectedParam2Value3, "⭑ expected object id: \(node3Id) value for '\(param2)' to be '\(expectedParam2Value3)', got '\(node3Object.stringForKey(param2))'")
        XCTAssertEqual(node3Object.stringForKey(param3), expectedParam3Value3, "⭑ expected object id: \(node3Id) value for '\(param3)' to be '\(expectedParam3Value3)', got '\(node3Object.stringForKey(param3))'")
        */

    }
}
