//
//  ColorTests.swift
//  SKTiled
//
//  Created by Michael Fessenden on 1/4/19.
//  Copyright © 2019 Michael Fessenden. All rights reserved.
//

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
