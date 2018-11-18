//
//  PerformanceTests.swift
//  SKTiledTests
//
//  Created by Michael Fessenden on 10/27/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import XCTest
@testable import SKTiled


class PerformanceTests: XCTestCase {
    
    var testBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        

        if (testBundle == nil) {
            TiledDefaults.shared.loggingLevel = .none
            testBundle = Bundle(for: type(of: self))
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSmallMapLoadTime() {
        self.measure {
            if let mapURL = testBundle!.url(forResource: "test-small", withExtension: "tmx") {
                if let map = SKTilemap.load(tmxFile: mapURL.path, loggingLevel: .none) {
                    map.debugDrawOptions = [.drawGrid, .drawBounds]
                }
            }
            self.stopMeasuring()
        }
        
    }
    
    func testLargeMapLoadTime() {
        self.measure {
            if let mapURL = testBundle!.url(forResource: "test-large", withExtension: "tmx") {
                if let map = SKTilemap.load(tmxFile: mapURL.path, loggingLevel: .none) {
                    map.debugDrawOptions = [.drawGrid, .drawBounds]
                }
            }
            self.stopMeasuring()
        }
    }
}
