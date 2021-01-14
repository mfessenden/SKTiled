//
//  CoordinateTests.swift
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
import SpriteKit
@testable import SKTiled

// Globals
fileprivate let keyTiledType = "key"
fileprivate let keyCoordinate: simd_int2 = simd_int2(20,3)
fileprivate let keyLayerName = "Objects"

// Tile map instance used for this test.
fileprivate var testTilemap: SKTilemap?
fileprivate let testTilemapName = "test-tilemap"



class CoordinateTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        if (testTilemap == nil) {
            if let tilemapUrl = TestController.default.getResource(named: testTilemapName, withExtension: "tmx") {
                testTilemap = SKTilemap.load(tmxFile: tilemapUrl.path, loggingLevel: LoggingLevel.none)
            }
        }
    }

    /// Test that coordinate conversion is working as expected.
    func testTilemapCoordinateConversion() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑  tilemap did not load.")
            return
        }


        let coordinates: [simd_int2] = [simd_int2(-2, -1), simd_int2(20,3), simd_int2(0,0), simd_int2(29,0), simd_int2(29, 15), simd_int2(0,15)]


        for coordinate in coordinates {
            let pointAtCoordinate = tilemap.pointForCoordinate(coord: coordinate)
            let coordinateAtPoint = tilemap.coordinateForPoint(point: pointAtCoordinate)
            XCTAssert(coordinate == coordinateAtPoint, "⭑coordinates are not equal: \(coordinate.shortDescription) -> \(coordinateAtPoint.shortDescription)")
        }
    }

    /// Test that a tile query at a location is working as expected. Tests the `SKTilemap.tilesAt` method, and in particular the ability to return the **top tile first**.
    ///
    ///   coord: 20,3 - top tile is of type `key`
    func testTilemapQueryAtCoordinate() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ tilemap '\(testTilemapName)' did not load.")
            return
        }

        let expectedTileType = keyTiledType
        var foundKeyTile = false
        let foundTiles = tilemap.tilesAt(coord: keyCoordinate)

        if let firstTile = foundTiles.first {
            foundKeyTile = firstTile.tileData.type == expectedTileType
        }

        XCTAssert(foundKeyTile == true, "⭑expected tile of type '\(expectedTileType)' at coordinate: \(keyCoordinate.coordDescription)")
    }

    /// Test that coordinate conversion is working as expected for the given layer.
    func testLayerCoordinateConversion() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ tilemap '\(testTilemapName)' did not load.")
            return
        }

        guard let tileLayer = tilemap.tileLayers(named: keyLayerName).first else {
            XCTFail("⭑ tilemap could not find layer: '\(keyLayerName)'.")
            return
        }
        
        // test coordinates
        let coordinates: [simd_int2] = [simd_int2(-2, -1), simd_int2(20,3), simd_int2(0,0), simd_int2(29,0), simd_int2(29, 15), simd_int2(0,15), simd_int2(13,1)]
        
        // loop through coordinates
        for coordinate in coordinates {
            
            // get the point in the layer & then check that the coordinate is the same
            let pointAtCoordinate = tileLayer.pointForCoordinate(coord: coordinate)
            let coordinateAtPoint = tileLayer.coordinateForPoint(point: pointAtCoordinate)
            
            // get the point in the map & then check that the coordinate is the same
            let mapPointAtCoordinate = tilemap.pointForCoordinate(coord: coordinate)
            let mapCoordinateAtPoint = tilemap.coordinateForPoint(point: mapPointAtCoordinate)
            
            XCTAssert(coordinate == coordinateAtPoint, "⭑ layer coordinates are not equal: \(coordinate.shortDescription) -> \(coordinateAtPoint.shortDescription)")
            XCTAssert(coordinate == coordinateAtPoint, "⭑ map coordinates are not equal:   \(coordinate.shortDescription) -> \(mapCoordinateAtPoint.shortDescription)")
        }
    }

    /// Test that tile query at a location is working as expected.
    ///
    /// coord: 20,3 - top file is of type `key`
    func testLayerQueryAtCoordinate() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ tilemap '\(testTilemapName)' did not load.")
            return
        }


        guard let tileLayer = tilemap.tileLayers(named: keyLayerName).first else {
            XCTFail("⭑ tilemap could not find layer: '\(keyLayerName)'.")
            return
        }


        let cx = keyCoordinate.x
        let cy = keyCoordinate.y

        let expectedTileType = keyTiledType
        let coordinate = simd_int2(cx, cy)


        XCTAssert(tileLayer.isValid(coord: coordinate), "⭑invalid tile coordinate: \(coordinate.coordDescription)")


        guard let tile = tileLayer.tileAt(coord: coordinate) else {
            XCTFail("⭑ map '\(tilemap.mapName)' tile layer '\(tileLayer.layerName)' has no tiles at coordinate: \(coordinate.shortDescription)")
            return
        }



        guard let tt = tile.tileData.type else {
            XCTFail("⭑ tile data \(tile.tileData.globalID) has no type property")
            return
        }

        XCTAssert(tt == expectedTileType, "⭑expected tile of type '\(expectedTileType)' at coordinate: \(coordinate.shortDescription) in layer: '\(tileLayer.layerName)'")
    }

    /// Test that the coordinate conversion in for each coordinate in the layer is correct.
    func testLayerQueryAllCoordinates() {
        guard let tilemap = testTilemap else {
            XCTFail("⭑ tilemap '\(testTilemapName)' did not load.")
            return
        }

        guard let tileLayer = tilemap.tileLayers(named: keyLayerName).first else {
            XCTFail("⭑ tilemap could not find layer: '\(keyLayerName)'")
            return
        }


        for col in 0 ..< Int(tileLayer.size.width) {
            for row in (0 ..< Int(tileLayer.size.height)) {

                let coordinate = CGPoint(x: col, y: row)
                let pointAtCoordinate = tileLayer.pointForCoordinate(coord: coordinate.toVec2)
                let coordinateAtPoint = tileLayer.coordinateForPoint(point: pointAtCoordinate)

                XCTAssert(coordinate == coordinateAtPoint, "⭑coordinates are not equal: \(coordinate.shortDescription) -> \(coordinateAtPoint)")
            }
        }
    }
}
