//
//  TiledSceneDelegate.swift
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
import GameplayKit


/// The `TiledSceneDelegate` Methods for managing `SKTilemap` nodes in an SpriteKit [`SKScene`][skscene-url] scene.
/// This protocol and the `SKTiledScene` objects are included as a suggested way to use the
/// `SKTilemap` class, but are not required.
///
/// In this configuration, the tile map is a child of the root node and reference the custom
/// `SKTiledSceneCamera` camera.
///
/// ![TiledSceneDelegate Overview][tiledscenedelegate-image-url]
///
/// ### Properties
///
/// - `worldNode`: Root container node. Tiled assets are parented to this node.
/// - `cameraNode`: Custom scene camera.
/// - `tilemap`: Tile map node.
///
/// ### Instance Methods
///
/// - [`load(tmxFile:)`][delegate-load-url]: Load a tilemap from disk.
///
/// [delegate-load-url]:TiledSceneDelegate.html#load(tmxFile:inDirectory:withTilesets:ignoreProperties:loggingLevel:)
/// [skscene-url]:https://developer.apple.com/reference/spritekit/skscene
/// [tiledscenedelegate-image-url]:../images/scene-hierarchy.svg
///
public protocol TiledSceneDelegate: class {

    /// Root container node. Tiled assets are parented to this node.
    var worldNode: SKNode! { get set }

    /// Custom scene camera.
    var cameraNode: SKTiledSceneCamera? { get set }

    /// Tile map node.
    var tilemap: SKTilemap? { get set }
}



/// Enables all `SKScene` types conforming to `TiledSceneDelegate` to load tilemaps.
extension TiledSceneDelegate where Self: SKScene {

    /// ## Overview
    ///
    /// This method loads a named tilemap **tmx** file, with optional tilesets. Camera properties are added from the tilemap automatically.
    ///
    ///   `extension TiledSceneDelegate where Self: SKScene {}`
    ///
    /// - Parameters:
    ///   - tmxFile: tilemap file name.
    ///   - inDirectory: search path for assets.
    ///   - tilesets: optional pre-loaded tilesets.
    ///   - ignoreProperties: don't parse custom properties.
    ///   - loggingLevel: logging verbosity.
    ///   - completion: optional completion handler.
    /// - Returns: tilemap instance.
    public func load(tmxFile: String,
                     inDirectory: String? = nil,
                     withTilesets tilesets: [SKTileset] = [],
                     ignoreProperties: Bool = false,
                     loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                     completion: ((SKTilemap) -> ())? = nil) -> SKTilemap? {


        if let tilemap = SKTilemap.load(tmxFile: tmxFile,
                                        inDirectory: inDirectory,
                                        delegate: self as? TilemapDelegate,
                                        tilesetDataSource: self as? TilesetDataSource,
                                        withTilesets: tilesets,
                                        ignoreProperties: ignoreProperties,
                                        loggingLevel: loggingLevel) {

            if let cameraNode = cameraNode {
                // camera properties inherited from tilemap
                cameraNode.allowMovement = tilemap.allowMovement
                cameraNode.allowZoom = tilemap.allowZoom
                cameraNode.allowRotation = tilemap.allowRotation
                cameraNode.setCameraZoom(tilemap.worldScale)
                cameraNode.maxZoom = tilemap.zoomConstraints.max
            }

            completion?(tilemap)
            return tilemap
        }
        return nil
    }
}



/// :nodoc: Typealias for v1.2 compatibility.
public typealias SKTiledSceneDelegate = TiledSceneDelegate
