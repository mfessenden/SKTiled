//
//  CoordinateTests.swift
//  SKTiledTests
//
//  Created by Michael Fessenden on 10/27/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import XCTest
@testable import SKTiled

// globals
typealias Coordinate = (x: Int, y: Int)
let keyTiledType = "key"
let keyCoordinate: Coordinate = (20,3)
let keyLayerName = "Objects"


class CoordinateTests: XCTestCase {
    
    var testBundle: Bundle!
    var tilemap: SKTilemap?
    let tilemapName = "test-tilemap"
    
    override func setUp() {
        super.setUp()
        
        if (testBundle == nil) {
            TiledGlobals.default.loggingLevel = .none
            testBundle = Bundle(for: type(of: self))
        }
        
        if (tilemap == nil) {
            let mapurl = testBundle!.url(forResource: tilemapName, withExtension: "tmx")!
            tilemap = SKTilemap.load(tmxFile: mapurl.path, loggingLevel: .none)
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /**
     Test that coordinate conversion is working as expected.
     
     */
    func testTilemapCoordinateConversion() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        
        let coords: [Coordinate] = [(-2, -1), (20,3), (0,0), (29,0), (29, 15), (0,15)]

        
        for coord in coords {
            
            let coordinate = CGPoint(x: coord.x, y: coord.y)
            let pointAtCoordinate = tilemap.pointForCoordinate(coord: coordinate)
            let coordinateAtPoint = tilemap.coordinateForPoint(pointAtCoordinate)
            XCTAssert(coordinate == coordinateAtPoint, "❗️coordinates are not equal: \(coordinate.shortDescription) -> \(coordinateAtPoint.shortDescription)")
        }
    }
    
    /**
     Test that tile query at a location is working as expected.
     
     
     coord: 20,3 - top file is of type `key`
     
     */
    func testTilemapQueryAtCoordinate() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        
        let cx = keyCoordinate.x
        let cy = keyCoordinate.y
        
        let expectedTileType = keyTiledType
        var foundKeyTile = false
        let coordinate = CGPoint(x: cx, y: cy)
        let tiles = tilemap.tilesAt(coord: coordinate)
        
        for tile in tiles {
            guard let tt = tile.tileData.type else {
                continue
            }
            
            if (tt == expectedTileType) {
                foundKeyTile = true
            }
        }
        
        XCTAssert(foundKeyTile == true, "❗️expected tile of type \"\(expectedTileType)\" at coordinate: \(coordinate.shortDescription)")
    }
    
    
    /**
     Test that coordinate conversion is working as expected for the given layer.
     
     */
    func testLayerCoordinateConversion() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        guard let tileLayer = tilemap.tileLayers(named: keyLayerName).first else {
            XCTFail("❗️tilemap could not find layer: \"\(keyLayerName)\"")
            return
        }
        
        
        let coords: [Coordinate] = [(-2, -1), (20,3), (0,0), (29,0), (29, 15), (0,15)]
        
        
        for coord in coords {
            
            let coordinate = CGPoint(x: coord.x, y: coord.y)
            let pointAtCoordinate = tileLayer.pointForCoordinate(coord: coordinate)
            let coordinateAtPoint = tileLayer.coordinateForPoint(pointAtCoordinate)
            
            XCTAssert(coordinate == coordinateAtPoint, "❗️coordinates are not equal: \(coordinate.shortDescription) -> \(coordinateAtPoint.shortDescription)")
        }
    }
    
    
    /**
     Test that tile query at a location is working as expected.
     
     
     coord: 20,3 - top file is of type `key`
     
     */
    func testLayerQueryAtCoordinate() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        
        guard let tileLayer = tilemap.tileLayers(named: keyLayerName).first else {
            XCTFail("❗️tilemap could not find layer: \"\(keyLayerName)\"")
            return
        }
        
        
        let cx = keyCoordinate.x
        let cy = keyCoordinate.y
        
        let expectedTileType = keyTiledType
        let coordinate = CGPoint(x: cx, y: cy)
        
        guard let tile = tileLayer.tileAt(coord: coordinate) else {
            XCTFail("❗️tile layer \"\(tileLayer.layerName)\" has no tiles at coordinate: \(coordinate.shortDescription)")
            return
        }
        

        guard let tt = tile.tileData.type else {
            XCTFail("❗️tile data \(tile.tileData.globalID) has no type property")
            return
        }
        
        XCTAssert(tt == expectedTileType, "❗️expected tile of type \"\(expectedTileType)\" at coordinate: \(coordinate.shortDescription) in layer: \"\(tileLayer.layerName)\"")
    }
    
    /**
     Test that the coordinate conversion in for each coordinate in the layer is correct.
     
     */
    func testLayerQueryAllCoordinates() {
        guard let tilemap = tilemap else {
            XCTFail("❗️tilemap did not load.")
            return
        }
        
        guard let tileLayer = tilemap.tileLayers(named: keyLayerName).first else {
            XCTFail("❗️tilemap could not find layer: \"\(keyLayerName)\"")
            return
        }
        
        
        for col in 0 ..< Int(tileLayer.size.width) {
            for row in (0 ..< Int(tileLayer.size.height)) {

                let coordinate = CGPoint(x: col, y: row)
                let pointAtCoordinate = tileLayer.pointForCoordinate(coord: coordinate)
                let coordinateAtPoint = tileLayer.coordinateForPoint(pointAtCoordinate)
            
                XCTAssert(coordinate == coordinateAtPoint, "❗️coordinates are not equal: \(coordinate.shortDescription) -> \(coordinateAtPoint.shortDescription)")
            }
        }
    }
}

