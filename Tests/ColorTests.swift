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


class ColorTests: XCTestCase {
    
    /// Test to determine if rgba -> hex values
    func testColorHexEquality() {
        // 80, 130, 60, 100 -> #50823C
        
        let expectedHexValue = "#50823C"
        
        let rgbIntColor = SKColor(red: 80, green: 130, blue: 60, alpha: 255)
        let hexIntString = rgbIntColor.hexString()
        
        let rgbFloatColor = SKColor(red: 0.3137254901960784, green: 0.5098039215686274, blue: 0.23529411764705882, alpha: 1)
        let hexFloatString = rgbFloatColor.hexString()
        
        XCTAssert(hexIntString == expectedHexValue,  "❗️unexpected hex string value: \(hexIntString) (expected \(expectedHexValue))")
        XCTAssert(hexFloatString == expectedHexValue, "❗️unexpected hex string value: \(hexFloatString) (expected \(expectedHexValue))")
    }

    /// Test to determine if hex alpha values are translated correctly
    func testColorHexAlphaEquality() {
        let expectedAlphaValue: CGFloat = 0.5
        let hexColor = SKColor(hexString: "#80e3b447")
        let alphaValue = hexColor.components[3]
        // round resulting float values
        XCTAssert(alphaValue.precised(2) == expectedAlphaValue.precised(2),  "❗️unexpected alpha value: \(alphaValue) (expected \(expectedAlphaValue))")
    }
}



extension FloatingPoint {
    typealias T = Self
    func precised(_ value: Int = 1) -> Self {
        let offset = Self(Int(pow(10.0, Double(value))))
        return (self * offset).rounded() / offset
    }
}
