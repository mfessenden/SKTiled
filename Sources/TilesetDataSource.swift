//
//  TilesetDataSource.swift
//  SKTiled
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

import SpriteKit


/**

 ## Overview

 Methods which allow the user to dynamically alter the properties of a tileset as it is being created.


 ### Instance Methods ###

 Delegate callbacks are called asynchronously as the tileset is being rendered.

 | Method             | Description                                                          |
 |--------------------|----------------------------------------------------------------------|
 | willAddSpriteSheet | Provide an image name for the tileset before textures are generated. |
 | willAddImage       | Provide an alernate image name for an image in a collection.         |

 ### Usage

 Implementing the `SKTilesetDataSource.willAddSpriteSheet` method allows the user to specify different spritesheet images. Take care
 that these images have the same dimensions & layout.

 ```swift
 extension MyScene: SKTilesetDataSource {
     func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String {
         if (currentSeason == .winter) {
             return "winter-tiles-16x16.png"
         }
         if (currentSeason == .summer) {
             return "summer-tiles-16x16.png"
         }
         return fileNamed
     }
 }
 ```
 */
public protocol SKTilesetDataSource: AnyObject {

    /**
     Provide an image name for the tileset before textures are generated.

     - parameter to:        `SKTileset` tileset instance.
     - parameter fileNamed: `String` spritesheet name.
     - returns: `String` spritesheet name.
     */
    func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String

    /**
     Provide an alernate image name for an image in a collection.

     - parameter to:        `SKTileset` tileset instance.
     - parameter forId:     `Int` tile id.
     - parameter fileNamed: `String` image name.
     - returns: `String` image name.
     */
    func willAddImage(to tileset: SKTileset, forId: Int, fileNamed: String) -> String
}



// MARK: - Extensions



/// Default methods
extension SKTilesetDataSource {
    /**
     Called when a tileset is about to render a spritesheet.

     - parameter tileset:   `SKTileset` tileset instance.
     - parameter fileNamed: `String` tileset instance.
     - returns: `String` spritesheet name.
     */
    public func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String {
        return fileNamed
    }

    /**
     Called when a tileset is about to add an image from a collection.

     - parameter to:        `SKTileset` tileset instance.
     - parameter forId:     `Int` tile id.
     - parameter fileNamed: `String` tileset instance.
     - returns: `String` spritesheet name.
     */
    public func willAddImage(to tileset: SKTileset, forId: Int, fileNamed: String) -> String {
        return fileNamed
    }
}
