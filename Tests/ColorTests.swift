//
//  ColorTests.swift
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


let testHexValues = ["#2FD62A", "#FFA5A5", "#A5CCFF", "#AF722A", "#5FBFD4"]


/// This module tests the color functions included in the framework.
class ColorTests: XCTestCase {
    
    /// Test to ensure that hex colors are parsed correctly.
    func testColorParsingExtensions() {
        let validHexValueStrings = [
            "#E7624F",
            "E7624F",
            "#333",
            "333",
            "#06a49b",
            "#06a49b99",
            "06a49b99",
            "#458",
            "#854",
            "#6573"
        ]
        
        let expectedHexValues = [
            "#e7624f",
            "#e7624f",
            "#333333",
            "#333333",
            "#06a49b",
            "#06a49b99",
            "#06a49b99",
            "#445588",
            "#885544",
            "#66557733"
        ]
        
        
        for (idx,hexstr) in validHexValueStrings.enumerated() {
            if hexstr.isValidHexColor {
                
                let parsedColor = SKColor(hexString: hexstr)
                let parsedColorHex = parsedColor.hexString()
                let expectedHexValue = expectedHexValues[idx]
                
                if (parsedColorHex != expectedHexValue) {
                    XCTFail("❗️ incorrect hex color parsing '\(hexstr)' -> '\(parsedColorHex)', expected: '\(expectedHexValue)'")
                    continue
                }
                
            } else {
                XCTFail("❗️ invalid color hex string '\(hexstr)'")
            }
        }
    }
    
    /// Test to determine if rgba == hex values.
    func testColorHexEquality() {
        // 80, 130, 60, 100 -> #50823C
        
        let expectedHexValue = "#50823c"
        
        let rgbIntColor = SKColor(red: 80, green: 130, blue: 60, alpha: 255)
        let hexIntString = rgbIntColor.hexString()
        
        let rgbFloatColor = SKColor(red: 0.3137254901960784, green: 0.5098039215686274, blue: 0.23529411764705882, alpha: 1)
        let hexFloatString = rgbFloatColor.hexString()
        
        XCTAssert(hexIntString == expectedHexValue,  "❗️ unexpected hex string value: \(hexIntString) (expected \(expectedHexValue))")
        XCTAssert(hexFloatString == expectedHexValue, "❗️ unexpected hex string value: \(hexFloatString) (expected \(expectedHexValue))")
    }
    
    
    func testColorMatchingHelpers() {
        let allExpectedFloatValues: [[CGFloat]] = [
            [0.18, 0.84, 0.16, 1.00],
            [1.00, 0.65, 0.65, 1.00],
            [0.65, 0.80, 1.00, 1.00],
            [0.69, 0.45, 0.16, 1.00],
            [0.37, 0.75, 0.83, 1.00]
        ]
        
        let allExpectedIntegerValues: [[UInt8]] = [
            [47, 214, 42, 255],
            [255, 165, 165, 255],
            [165, 204, 255, 255],
            [175, 114, 42, 255],
            [95, 191, 212, 255]
        ]
        
        for (index, hex) in testHexValues.enumerated() {
            let parsedHexColor = SKColor(hexString: hex)
            
            // get the parsed color's float & integer components.
            let parsedFloatComponents = parsedHexColor.components
            let parsedFloatValues: [CGFloat] = [parsedFloatComponents.r, parsedFloatComponents.g, parsedFloatComponents.b, parsedFloatComponents.a].map {
                return $0.precised(2)
            }
            
            let parsedIntegerComponents = parsedHexColor.integerCompoments
            let parsedIntegerValues: [UInt8] = [UInt8(parsedIntegerComponents.r), UInt8(parsedIntegerComponents.g), UInt8(parsedIntegerComponents.b), UInt8(parsedIntegerComponents.a)]
            
            // compare with expected.
            let expectedFloatValues = allExpectedFloatValues[index]
            let expectedIntegerValues = allExpectedIntegerValues[index]
            
            
            let floatValuesMatch = (expectedFloatValues == parsedFloatValues)
            let integerValuesMatch = (expectedIntegerValues == parsedIntegerValues)
            
            
            XCTAssert(floatValuesMatch == true,  "❗️ color '\(hex)' float value mismatch: \(parsedFloatValues), expected: \(expectedFloatValues)")
            XCTAssert(integerValuesMatch == true,  "❗️ color '\(hex)' float value mismatch: \(parsedIntegerValues), expected: \(expectedIntegerValues)")
        }
    }

    
    /// Test to determine if hex alpha values are translated correctly
    func testColorHexAlphaEquality() {
        let expectedAlphaValue: CGFloat = 0.28
        let hexColor = SKColor(hexString: "#80e3b447")
        let alphaValue = hexColor.components.a
        // round resulting float values
        XCTAssert(alphaValue.precised(2) == expectedAlphaValue.precised(2),  "❗️ unexpected alpha value: \(alphaValue) (expected \(expectedAlphaValue))")
    }
    
    /// Test to ensure that hex color strings with 3/4 digits are translated correctly.
    ///
    ///   hex `#854` should equate to `#885544`
    func testShortHexStringColorEquality() {
        // first value (3 characters)
        let firstShortHexString = "#854"
        let firstExpectedHexValue = "#885544"
        let firstTestColor = SKColor(hexString: firstShortHexString)
        let firstTextColorHexValue = firstTestColor.hexString()
        
        // second value (4 characters)
        let secondShortHexString = "#5ba"
        let secondExpectedHexValue = "#55bbaa"
        let secondTestColor = SKColor(hexString: secondShortHexString)
        let secondTextColorHexValue = secondTestColor.hexString()
        
        XCTAssertEqual(firstTextColorHexValue, firstExpectedHexValue, "❗️ incorrect hex to color conversion, `\(firstShortHexString)` does not equal `\(firstExpectedHexValue)`")
        XCTAssertEqual(secondTextColorHexValue, secondExpectedHexValue, "❗️ incorrect hex to color conversion, `\(secondShortHexString)` does not equal `\(secondExpectedHexValue)`")
    }
}

