//
//  CompressionTests.swift
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


class CompressionTests: XCTestCase {


    /// Test that our **zlib** deflating functions are working correctly.
    ///
    /// String data is taken from the **dungeon-16x16.tmx** file, layer **Lower/Level1**.
    func testZlibCompressedString() {

        let zlibCompressedData = "eJztk79KA0EQxmc9xVYtRI2EQwQthPgHEowgB2KnPoD451JY2p0m2IqVRd7BIvgKkkIfwELfQtAXsPMbboYb1zs9Ebt88GOT3dlvZ2b3iAYaqLz2HdHIP/hOgSYYAgE4cH/zGwV1MO0xA4ZBJWfPHej/4BuCXXAIjkEMlgX2XzWxXALXswHWPB9e4zq1l6GMO+LfBi/ip6iewDN4cxS3zHwXvMJ43pwX0lfNmfXA9PlczuU9HRPfA2dSs55X5Dv7zbo/15MxMecV+aLWB77PhsxxrXWh4cVzngF97m+NKOL/fB+XlL6DdcmX+70ncbeU9oHV9nwT8bb95XfL974EruR3xeSr3Ev8SU591lv7u4B7OcW4BbbBOJgw+VpY1QJf1oWg+a6ATTAJFsEjZfd2DWKX0S35HdbEV72RcxQZ3xtK35C+sU6OR564J0eUfWvvMraKt5RS4uUz5n6X1wdgVjQZ"


        typealias Array2DElement = (index: UInt32, value: UInt32)


        // the expected size of the compressed array.
        let expectedArraySize = 462

        /*
        [239]: 1610613228
        [298]: 3221225964
        [314]: 1073741871
        [342]: 3221225964
        [406]: 1073741893
        */

        let testElements: [Array2DElement] = [
            (239, 1610613228),
            (298, 3221225964),
            (314, 1073741871),
            (298, 3221225964),
            (406, 1073741893),
            (388, 139),
            (392, 399)
        ]

        guard let decodedData = Data(base64Encoded: zlibCompressedData, options: .ignoreUnknownCharacters) else {
            XCTFail("⭑ Error decoding zlib compressed string.")
            return
        }


        guard let decompressed = try? decodedData.gunzipped() else {
            XCTFail("⭑ Error decoding base64 decoded data.")
            return
        }

        // deflate the data into an array
        let arrayResult = decompressed.toArray(type: UInt32.self)

        XCTAssertEqual(arrayResult.count, expectedArraySize, "⭑ expected array size: \(expectedArraySize), got \(arrayResult.count)")

        for testElement in testElements {
            let resultValue = arrayResult[Int(testElement.index)]
            XCTAssertEqual(resultValue, testElement.value, "⭑ expected array value: \(testElement.value), got \(resultValue)")
        }
    }

    /// Test that our **gzip** deflating functions are working correctly.
    ///
    /// String data is taken from the **dungeon-16x16.tmx** file, layer **Lower/Level1**.
    func testGZipCompressedString() {
        let gzipCompressedData = "H4sIAAAAAAAAE+2Tv0oDQRDGZz3FVi1EjYRDBC2E+AcSjCAHYqc+gPjnUljanSbYipVF3sEi+AqSQh/AQt9C0Bew8xtuhhvXOz0Ru3zwY5Pd2W9nZveIBhqovPYd0cg/+E6BJhgCAThwf/MbBXUw7TEDhkElZ88d6P/gG4JdcAiOQQyWBfZfNbFcAtezAdY8H17jOrWXoYw74t8GL+KnqJ7AM3hzFLfMfBe8wnjenBfSV82Z9cD0+VzO5T0dE98DZ1KznlfkO/vNuj/XkzEx5xX5otYHvs+GzHGtdaHhxXOeAX3ub40o4v98H5eUvoN1yZf7vSdxt5T2gdX2fBPxtv3ld8v3vgSu5HfF5KvcS/xJTn3WW/u7gHs5xbgFtsE4mDD5WljVAl/WhaD5roBNMAkWwSNl93YNYpfRLfkd1sRXvZFzFBnfG0rfkL6xTo5HnrgnR5R9a+8ytoq3lFLi5TPmfpfXB32uIZM4BwAA"

        typealias Array2DElement = (index: UInt32, value: UInt32)


        // the expected size of the compressed array.
        let expectedArraySize = 462

        /*
        [239]: 1610613228
        [298]: 3221225964
        [314]: 1073741871
        [342]: 3221225964
        [406]: 1073741893
        */

        let testElements: [Array2DElement] = [
            (239, 1610613228),
            (298, 3221225964),
            (314, 1073741871),
            (298, 3221225964),
            (406, 1073741893),
            (388, 139),
            (392, 399)
        ]

        guard let decodedData = Data(base64Encoded: gzipCompressedData, options: .ignoreUnknownCharacters) else {
            XCTFail("⭑ Error decoding zlib compressed string.")
            return
        }


        guard let decompressed = try? decodedData.gunzipped() else {
            XCTFail("⭑ Error decoding base64 decoded data.")
            return
        }

        // deflate the data into an array
        let arrayResult = decompressed.toArray(type: UInt32.self)

        XCTAssertEqual(arrayResult.count, expectedArraySize, "⭑ expected array size: \(expectedArraySize), got \(arrayResult.count)")

        for testElement in testElements {
            let resultValue = arrayResult[Int(testElement.index)]
            XCTAssertEqual(resultValue, testElement.value, "⭑ expected array value: \(testElement.value), got \(resultValue)")
        }
    }
}
