//
//  PerformanceTests.swift
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
@testable import SKTiled


class PerformanceTests: XCTestCase {


    /// Test parsing of the test map saved as `CSV`.
    ///
    ///   - average time: 0s ( 0.000015s best )
    ///   - relative standard deviation: 189.808%
    func testCSVCompressedMap() {

        let testBundle = Bundle.init(for: PerformanceTests.self)
        self.measure {
            if let mapURL = testBundle.url(forResource: "test-compression-csv", withExtension: "tmx") {
                if let _ = SKTilemap.load(tmxFile: mapURL.path, loggingLevel: .none) {
                    self.stopMeasuring()
                }
            }
        }
    }

    /// Test parsing of the test map (using `gzip` compression).
    ///
    ///   - average time: 0s ( 0.000020s best )
    ///   - relative standard deviation: 58.966%
    func testGzipCompressedMap() {
        let testBundle = Bundle.init(for: PerformanceTests.self)
        self.measure {
            if let mapURL = testBundle.url(forResource: "test-compression-gzip", withExtension: "tmx") {
                if let _ = SKTilemap.load(tmxFile: mapURL.path, loggingLevel: .none) {
                    self.stopMeasuring()
                }
            }
        }
    }

    /// Test parsing of a 300x300/8x8 tile infinite map.
    ///
    ///   - average time: 14.163s
    ///   - relative standard deviation: 30%
    func testLargeInfiniteMapLoadTime() {
        let testBundle = Bundle.init(for: PerformanceTests.self)
        self.measure {
            if let mapURL = testBundle.url(forResource: "test-large-infinite-zlib", withExtension: "tmx") {
                if let _ = SKTilemap.load(tmxFile: mapURL.path, loggingLevel: .none) {
                    self.stopMeasuring()
                }
            }
        }
    }


    /// Test parsing of a 300x300/8x8 tile map.
    ///
    ///   - average time: 11.448s
    ///   - relative standard deviation: 13.941%
    func testLargeMapLoadTime() {
        let testBundle = Bundle.init(for: PerformanceTests.self)
        self.measure {
            if let mapURL = testBundle.url(forResource: "test-large-zlib", withExtension: "tmx") {
                if let _ = SKTilemap.load(tmxFile: mapURL.path, loggingLevel: .none) {
                    self.stopMeasuring()
                }
            }
        }
    }

    /// Test parsing of a 10x10/8x8 tile map.
    ///
    ///   - average time: 0.034s
    ///   - relative standard deviation: 10.876%
    func testSmallMapLoadTime() {
        let testBundle = Bundle.init(for: PerformanceTests.self)
        self.measure {
            if let mapURL = testBundle.url(forResource: "test-small-zlib", withExtension: "tmx") {
                if let _ = SKTilemap.load(tmxFile: mapURL.path, loggingLevel: .none) {
                    self.stopMeasuring()
                }
            }
        }
    }

    /// Test parsing of the test map (using `zlib` compression).
    ///
    ///   - average time: 5.324s ( 3.491s best )
    ///   - relative standard deviation: 61.232%
    func testZlibCompressedMap() {
        let testBundle = Bundle.init(for: PerformanceTests.self)
        self.measure {
            if let mapURL = testBundle.url(forResource: "test-compression-zlib", withExtension: "tmx") {
                if let _ = SKTilemap.load(tmxFile: mapURL.path, loggingLevel: .none) {
                    self.stopMeasuring()
                }
            }
        }
    }
}
