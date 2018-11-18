//
//  Tests+Extensions.swift
//  SKTiledTests
//
//  Created by Michael Fessenden on 10/30/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import Foundation
import XCTest
@testable import SKTiled


extension SKTilemap {
    
    public class func load(tmxFile: String, ignoreProperties: Bool) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: nil, tilesetDataSource: nil,
                              updateMode: TiledGlobals.default.updateMode,
                              withTilesets: nil, ignoreProperties: ignoreProperties,
                              loggingLevel: TiledGlobals.default.loggingLevel)
    }
    
    public class func load(tmxFile: String, delegate: SKTilemapDelegate, tilesetDataSource: SKTilesetDataSource, loggingLevel: LoggingLevel) -> SKTilemap? {
        return SKTilemap.load(tmxFile: tmxFile, inDirectory: nil,
                              delegate: delegate, tilesetDataSource: tilesetDataSource,
                              updateMode: TiledGlobals.default.updateMode,
                              withTilesets: nil, ignoreProperties: false,
                              loggingLevel: loggingLevel)
    }
}
