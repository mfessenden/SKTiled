//
//  Tests+Extensions.swift
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
import Foundation
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
