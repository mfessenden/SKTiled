//
//  TiledSceneDelegate.swift
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
import GameplayKit


/**
 ## Overview

 Methods for managing `SKTilemap` nodes in an SpriteKit [`SKScene`][skscene-url] scene.
 This protocol and the `SKTiledScene` objects are included as a suggested way to use the
 `SKTilemap` class, but are not required.

 In this configuration, the tile map is a child of the root node and reference the custom
 `SKTiledSceneCamera` camera.

 ![SKTiledSceneDelegate Overview][sktiledscenedelegate-image-url]

 ### Properties

 | Property             | Description                                                  |
 |:---------------------|:-------------------------------------------------------------|
 | worldNode            | Root container node. Tiled assets are parented to this node. |
 | cameraNode           | Custom scene camera.                                         |
 | tilemap              | Tile map node.                                               |


 ### Instance Methods ###

 | Method                              | Description               |
 |:------------------------------------|:--------------------------|
 | [load(tmxFile:)][delegate-load-url] | Load a tilemap from disk. |

 [delegate-load-url]:SKTiledSceneDelegate.html#load(tmxFile:inDirectory:withTilesets:ignoreProperties:loggingLevel:)
 [skscene-url]:https://developer.apple.com/reference/spritekit/skscene
 [sktiledscenedelegate-image-url]:https://mfessenden.github.io/SKTiled/images/scene-hierarchy.svg
 */
public protocol SKTiledSceneDelegate: AnyObject {

    /// Root container node. Tiled assets are parented to this node.
    var worldNode: SKNode! { get set }

    /// Custom scene camera.
    var cameraNode: SKTiledSceneCamera! { get set }

    /// Tile map node.
    var tilemap: SKTilemap! { get set }

    /// Load a tilemap from disk, with optional tilesets.
    func load(tmxFile: String, inDirectory: String?,
              withTilesets tilesets: [SKTileset],
              ignoreProperties: Bool, loggingLevel: LoggingLevel) -> SKTilemap?
}
