//
//  TilesetTests.swift
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

fileprivate let testTilemapName = "test-tilemap"
fileprivate var testTilemap: SKTilemap?

fileprivate let testTilesetName = "environment-8x8"
fileprivate var testTileset: SKTileset?


/// Test tileset objects.
class TilesetTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        if (testTilemap == nil) {
            if let tilemapUrl = TestController.default.getResource(named: testTilemapName, withExtension: "tmx") {
                testTilemap = SKTilemap.load(tmxFile: tilemapUrl.path, loggingLevel: .none)

                if (testTileset == nil) {
                    testTileset = testTilemap?.getTileset(named: testTilesetName)
                }
            }
        }
    }

    /// Test to see if a named tileset can be properly queried.
    func testTilesetExists() {
        XCTAssertNotNil(testTileset, "⭑ cannot access tileset: '\(testTilesetName)'")
    }

    /// Test to see if a named tileset has the correct basic Tiled properties:
    ///
    ///    name="environment-8x8"
    ///    tilewidth="8"
    ///    tileheight="8"
    ///    spacing="0"
    ///    tilecount="45"
    ///    columns="15"
    ///
    func testTilesetProperties() {
        guard let tileset = testTileset else {
            XCTFail("⭑ could not load test tileset.")
            return
        }

        XCTAssert(tileset.name == "environment-8x8", "⭑ tileset name incorrect: \(tileset.name)")
        XCTAssert(tileset.tileSize == CGSize(width: 8, height: 8), "⭑ tileset tile size is incorrect.")
        XCTAssert(tileset.spacing == 0, "⭑ tileset spacing is incorrect: \(tileset.spacing)")
        XCTAssert(tileset.tilecount == 45, "⭑ tileset tile count is incorrect: \(tileset.tilecount)")
        XCTAssert(tileset.columns == 15, "⭑ tileset column count is incorrect: \(tileset.columns)")
        XCTAssert(tileset.firstGID == 1, "⭑ tileset first gid is incorrect.")
    }

    /// Test to see if a tileset will return the proper tile from a global id.
    /// We're looking at the `key` tile contained in the `items-8x8` tileset.
    ///
    ///  Tile Data GID: 79
    ///    - Local ID: 5 (tileset first gid is 74)
    ///    - has `color` property of `#ffa07daa`
    ///
    func testGlobalIDQuery() {
        guard let tilemap = testTilemap,
            (testTileset != nil) else {
            XCTFail("⭑ could not load test assets.")
            return
        }

        // gid 79 is the key
        let keyid: UInt32 = 79
        let expectedLocalID: UInt32  = 5
        let expectedKeyCount = 5
        let keyTiles = tilemap.getTiles(globalID: keyid)
        XCTAssert(keyTiles.count == expectedKeyCount, "⭑ tile count for gid \(keyid) should be \(expectedKeyCount), got \(keyTiles.count)")

        var keyPropertyIsCorrect = true
        var keyIDsAreCorrect = true
        for tile in keyTiles {
            let tileColorHex = tile.tileData.stringForKey("color")
            keyPropertyIsCorrect = (tileColorHex != nil) && (tileColorHex == "#ffa07daa")
            keyIDsAreCorrect = (tile.tileData.id == expectedLocalID) && (tile.tileData.globalID == keyid)
        }

        XCTAssert(keyPropertyIsCorrect == true, "⭑ tiles with gid \(keyid) should have a `color` property")
        XCTAssert(keyIDsAreCorrect == true, "⭑ tiles with gid \(keyid) should have a local id of \(expectedLocalID)")
    }


    /// Tests the ability of the tileset class to query data based on property values.
    ///   `SKTileset.getTileData(withProperty:_)`
    ///
    func testGetTileDataWithProperty() {
        guard let tileset = testTileset else {
            XCTFail("⭑ could not load test tileset '\(testTilesetName)'")
            return
        }
        
        
        let objectDataTypes = tileset.getTileData(withProperty: "object")
    }

    /// Tests the ability of the tileset class to query data based on property values.
    ///   `SKTileset.getTileData(withProperty:)`
    ///
    func testGetTileDataWithPropertyAnValue() {
        guard let tileset = testTileset else {
            XCTFail("⭑ could not load test tileset '\(testTilesetName)'")
            return
        }
    }

    /// Tests whether tilesets can test a range of global ids.
    ///   `SKTileset.contains(globalID:)`
    ///
    func testTilesetGlobalIDRange() {
        guard let tileset = testTileset else {
            XCTFail("⭑ could not load test tileset '\(testTilesetName)'")
            return
        }
    }

    /// Tests whether tilesets can test a range of global ids.
    ///   `SKTilemap.getTileset(forTile:)`
    ///
    func testGetTilesetForGlobalId() {
        guard let tileset = testTileset else {
            XCTFail("⭑ could not load test tileset '\(testTilesetName)'")
            return
        }
    }

    /// Tests the `SKTileset.localRange` & `SKTileset.globalRange` properties.
    func testTilesetRangeValues() {
        guard let tileset = testTileset else {
            XCTFail("⭑ could not load test tileset '\(testTilesetName)'")
            return
        }


        let firstGid = tileset.firstGID
        let localRange = tileset.localRange
        let globalRange = tileset.globalRange


        var localTileIds: [UInt32] = []
        var tileDataStash: [SKTilesetData] = []

        for localid in localRange {
            guard let tiledata = tileset.getTileData(localID: localid) else {
                XCTFail("⭑ invalid tileset local id \(localid)")
                return
            }

            localTileIds.append(localid)
            tileDataStash.append(tiledata)
        }

        for (localid, globalid) in globalRange.enumerated() {
            guard let tiledata = tileset.getTileData(globalID: globalid) else {
                XCTFail("⭑ invalid tileset global id \(globalid)")
                return
            }

            let localId = localTileIds[localid]
            let thisGlobalId = firstGid + UInt32(localid)
            let stashedTileData = tileDataStash[localid]

            XCTAssert(stashedTileData == tiledata, "⭑ tile data doesn't match ( id: \(localid), gid: \(globalid) )")
            XCTAssert(thisGlobalId == globalid, "⭑ invalid global id value '\(thisGlobalId)' ( \(firstGid) + \(localid) )")
        }
    }

    /// Test to check that tileset ids are correctly parsed.
    func testTilesetGlobalIDQueries() {
        guard let tileset = testTileset else {
            XCTFail("⭑ could not load test tileset.")
            return
        }

        // get the first gid value
        let firstGid = tileset.firstGID

        for localid in tileset.localRange {
            guard let tileData = tileset.getTileData(localID: localid) else {
                XCTFail("⭑ failed to find tile data with id '\(localid)'")
                return
            }

            let localID = tileData.id
            let thisGlobalID = tileData.globalID
            let expectedGlobalID = localID + firstGid

            XCTAssert(thisGlobalID == expectedGlobalID, "⭑ error resolving tile id '\(localid)': local id '\(localID)', expected '\(expectedGlobalID)' (first gid: '\(firstGid)')")
        }
    }

    /// Test to check if the tileset range & `contains` methods are working as expected.
    func testContainsMethods() {

        /**
        <tileset firstgid="1" source="environment-8x8.tsx"/>  - 0-44
        <tileset firstgid="46" source="characters-8x8.tsx"/>  - 0-27
        <tileset firstgid="104" source="monsters-16x16.tsx"/> - 0-6
        */

        guard let tilemap = testTilemap,
              let firstTileset = tilemap.getTileset(named: "environment-8x8"),
              let secondTileset = tilemap.getTileset(named: "characters-8x8"),
              let thirdTileset = tilemap.getTileset(named: "monsters-16x16") else {
            XCTFail("⭑ could not load test tilemap.")
            return
        }


        let testTilesets = [firstTileset, secondTileset, thirdTileset]
        let firstGidValues: [UInt32] = [1, 46, 104]
        let localRangeUpperBounds: [UInt32] = [44, 27, 6]
        let globalRangeBounds: [ClosedRange<UInt32>] = [1...45, 46...73, 104...110]
        let validLocalIdValues: [UInt32] = [36, 27, 4]
        let validGlobalIdValues: [UInt32] = [45, 73, 107]
        let expectedTileCounts: [Int] = [45, 28, 7]


        for (idx, tileset) in testTilesets.enumerated() {

            // values that we should expect
            let expectedFirstGid = firstGidValues[idx]
            let expectedLocalRangeUpperBound = localRangeUpperBounds[idx]
            let expectedGlobalRange = globalRangeBounds[idx]
            let expectedValidLocalId = validLocalIdValues[idx]
            let expectedValidGlobalId = validGlobalIdValues[idx]
            let expectedTileCount = expectedTileCounts[idx]

            XCTAssert(expectedFirstGid == tileset.firstGID, "⭑ tileset '\(tileset.name)' has an incorrect `firstGID` value; got \(tileset.firstGID), expected \(expectedFirstGid)")
            XCTAssert(tileset.localRange.upperBound == expectedLocalRangeUpperBound, "⭑ tileset '\(tileset.name)' has an incorrect `localRange.upperBound` value; got \(tileset.localRange.upperBound), expected \(expectedLocalRangeUpperBound)")
            XCTAssert(tileset.globalRange == expectedGlobalRange, "⭑ tileset '\(tileset.name)' has an incorrect `localRange.globalRange` value; got \(tileset.globalRange), expected [\(expectedGlobalRange.lowerBound)...\(expectedGlobalRange.upperBound)]")
            XCTAssertTrue(tileset.contains(localID: expectedValidLocalId), "⭑ tileset '\(tileset.name)' does not contain local id \(expectedValidLocalId)")
            XCTAssertTrue(tileset.contains(globalID: expectedValidGlobalId), "⭑ tileset '\(tileset.name)' does not contain global id \(expectedValidGlobalId)")
            XCTAssert(tileset.dataCount == expectedTileCount, "⭑ tileset '\(tileset.name)' has an incorrect tile data count \(tileset.dataCount), expected \(expectedTileCount)")
        }
    }


    /// Test to check that tileset ids are correctly parsed.
    func testTilesetGlobalIDComparison() {
        guard let tileset = testTileset else {
            XCTFail("⭑ could not load test tileset.")
            return
        }
    }
}
