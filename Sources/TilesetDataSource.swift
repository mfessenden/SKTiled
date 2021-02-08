//
//  TilesetDataSource.swift
//  SKTiled
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


/// The `TilesetDataSource` protocol outlines methods which allow the user to dynamically alter the properties of a tileset as it is being created.
///
/// ### Instance Methods
///
/// Delegate callbacks are called asynchronously as the tileset is being rendered.
///
/// - `willAddSpriteSheet`: Provide an image name for the tileset before textures are generated.
/// - `willAddImage`: Provide an alernate image name for an image in a collection.
///
/// ### Usage
///
/// Implementing the `TilesetDataSource.willAddSpriteSheet` method allows the user to specify different spritesheet images. Take care
/// that these images have the same dimensions & layout.
///
/// ```swift
/// extension MyScene: TilesetDataSource {
///     func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String {
///         if (currentSeason == .winter) {
///             return "winter-tiles-16x16.png"
///         }
///         if (currentSeason == .summer) {
///             return "summer-tiles-16x16.png"
///         }
///         return fileNamed
///     }
/// }
/// ```
public protocol TilesetDataSource: class {

    /// Provide an image name for the tileset *before* textures are generated. Implement this method to allow custom sprite sheet images to be loaded.
    ///
    /// - Parameters:
    ///   - tileset: Tileset instance.
    ///   - fileNamed: Spritesheet name.
    /// - Returns:  Spritesheet name.
    func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String

    /// Provide an alernate image name for an image in a collection tileset. Implement this method to allow remapping of images *before* the tileset is created.
    ///
    /// - Parameters:
    ///   - tileset: Tileset instance.
    ///   - forId: Tile id.
    ///   - fileNamed: Image name.
    /// - Returns:  Image name.
    func willAddImage(to tileset: SKTileset, forId: UInt32, fileNamed: String) -> String
}



// MARK: - Extensions


/// Default methods for `TilesetDataSource` protocol.
extension TilesetDataSource {

    /// Called when a tileset is about to process a spritesheet image. This method allows you to substitute a new filename *before* the tileset is built.
    ///
    /// - Parameters:
    ///   - tileset: tileset instance.
    ///   - fileNamed: spritesheet filename.
    /// - Returns: spritesheet filename.
    public func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String {
        return fileNamed
    }

    /// Called when a tileset is about to add an image from a collection. This method allows you to substitute a new filename *before* the tileset is built.
    ///
    /// - Parameters:
    ///   - tileset: tileset instance.
    ///   - forId: tile id.
    ///   - fileNamed: image file name.
    /// - Returns: image file name.
    public func willAddImage(to tileset: SKTileset, forId: UInt32, fileNamed: String) -> String {
        return fileNamed
    }
}



/// :nodoc: Typealias for v1.2 compatibility.
public typealias SKTilesetDataSource = TilesetDataSource


// MARK: - Deprecations

extension TilesetDataSource {

        /// Called when a tileset is about to add an image from a collection. This method allows you to substitute a new filename *before* the tileset is built.
        ///
        /// - Parameters:
        ///   - tileset: tileset instance.
        ///   - forId: tile id.
        ///   - fileNamed: image file name.
        /// - Returns: image file name.
        @available(*, unavailable, renamed: "willAddImage(to:forId:fileNamed:)")
        public func willAddImage(to tileset: SKTileset, forId: Int, fileNamed: String) -> String {
            return fileNamed
        }
}
