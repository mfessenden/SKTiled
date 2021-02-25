//
//  Demo+Setup.swift
//  SKTiled Demo
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

import SpriteKit


extension SKTiledDemoScene {

    /// Special setup functions for various included demo content.
    ///
    /// - Parameters:
    ///   - fileNamed: tiled filename.
    ///   - verbose: logging verbosity.
    func setupDemoLevel(fileNamed: String, verbose: Bool = false) {
        guard let tilemap = tilemap else {
            return
        }

        let baseFilename = fileNamed.components(separatedBy: "/").last!

        let walkableTiles = tilemap.getTilesWithProperty("walkable", true)
        let walkableTilesString = (walkableTiles.isEmpty == true) ? "" : ", \(walkableTiles.count) walkable tiles."
        log("setting up level: '\(baseFilename)'\(walkableTilesString)", level: .debug)

        switch baseFilename {

            case "dungeon-16x16.tmx":
                if let upperGraphLayer = tilemap.tileLayers(named: "Graph-Upper").first {
                    _ = upperGraphLayer.initializeGraph(walkable: walkableTiles)
                }

                if let lowerGraphLayer = tilemap.tileLayers(named: "Graph-Lower").first {
                    _ = lowerGraphLayer.initializeGraph(walkable: walkableTiles)
                }
                
                guard let tileset = tilemap.getTileset(named: "dungeon-32x32"),
                      let tiledata = tileset.getTileData(localID: 0),
                      let tile = SKTile(data: tiledata) else {
                    self.log("can't create a new tile", level: .error)
                    return
                }
                
                
                tilemap.getLayers(named: "Characters-Upper").first?.addChild(tile, coord: simd_int2(9,13), offset: CGPoint(x: -4, y: -4))
                
                if let dwarf = tilemap.getObjects(named: "dwarf1").first {
                    dwarf.setScale(2)
                }
                
                

            case "roguelike-16x16.tmx":
                if let graphLayer = tilemap.tileLayers(named: "Graph").first {
                    _ = graphLayer.initializeGraph(walkable: walkableTiles)
                }

            case "staggered-64x33.tmx":
                if let graphLayer = tilemap.tileLayers(named: "Graph").first {
                    _ = graphLayer.initializeGraph(walkable: walkableTiles)
                }

            default:
                return
        }
    }
}


// MARK: - Demo Event Methods

extension SKTiledDemoScene {

    #if os(macOS)

    /// Mouse over handler for the demo project.
    ///
    /// - Parameters:
    ///   - globalID: e global id.
    ///   - ofType: tile type.
    /// - Returns: mouse handler.
    @objc public func mouseOverTileHandler(globalID: UInt32, ofType: String? = nil) -> ((SKTile) -> ())? {
        return { (tile) in
            NotificationCenter.default.post(
                name: Notification.Name.Demo.TileUnderCursor,
                object: tile
            )
        }
    }

    /// Mouse click handler for the demo project.
    ///
    /// - Parameters:
    ///   - clicks: number of mouse clicks required.
    ///   - globalID: tile global id.
    ///   - ofType: tile type.
    /// - Returns: mouse handler.
    @objc public func tileClickedHandler(globalID: UInt32, ofType: String? = nil, button: UInt8 = 0) -> ((SKTile) -> ())? {
        return { (tile) in
            NotificationCenter.default.post(
                name: Notification.Name.Demo.TileClicked,
                object: tile
            )
        }
    }

    /// Mouse over handler for the demo project.
    ///
    /// - Parameters:
    ///   - withID: object id.
    ///   - ofType: object type.
    @objc public func mouseOverObjectHandler(withID: UInt32, ofType: String?) -> ((SKTileObject) -> ())? {
        return { (object) in
            NotificationCenter.default.post(
                name: Notification.Name.Demo.ObjectUnderCursor,
                object: object
            )
        }
    }

    /// Mouse click handler for the demo project.
    ///
    /// - Parameters:
    ///   - clicks: number of mouse clicks required.
    ///   - withID: object id.
    ///   - ofType: object type.
    @objc public func objectClickedHandler(withID: UInt32, ofType: String?, button: UInt8 = 0) -> ((SKTileObject) -> ())? {
        return { (object) in
            NotificationCenter.default.post(
                name: Notification.Name.Demo.ObjectClicked,
                object: object
            )
        }
    }



    #elseif os(iOS)

    /// Custom touch handler for tiles matching the given properties.
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - ofType: tile type
    ///   - block: closure.
    ///   - userData: dictionary of attributes.
    @objc public func tileTouchedHandler(globalID: UInt32, ofType: String?, userData: [String: Any]?) -> ((SKTile) -> ())? {
        return { (tile) in

            NotificationCenter.default.post(
                name: Notification.Name.Demo.TileTouched,
                object: tile
            )
        }
    }

    /// Custom touch handler for objects matching the given properties.
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - ofType: tile type
    ///   - block: closure.
    ///   - userData: dictionary of attributes.
    @objc public func objectTouchedHandler(withID: UInt32, ofType: String?, userData: [String: Any]?) -> ((SKTileObject) -> ())? {
        return { (object) in

            NotificationCenter.default.post(
                name: Notification.Name.Demo.ObjectTouched,
                object: object
            )
        }
    }

    #endif
}
