//
//  TilemapDelegate.swift
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
 
 Methods that allow interaction with an `SKTilemap` object as it is being created to customize its properties.
 
 ### Properties
 
 | Property           | Description                        |
 |:-------------------|:-----------------------------------|
 | zDeltaForLayers    | Default z-distance between layers. |
 
 ### Instance Methods ###
 
 Delegate callbacks are called asynchronously as the map is being read from disk and rendered:
 
 | Method                | Description                                                      |
 |:----------------------|:-----------------------------------------------------------------|
 | didBeginParsing       | Called when the tilemap is instantiated.                         |
 | didAddTileset         | Called when a tileset is added to a map.                         |
 | didAddLayer           | Called when a layer is added to a tilemap.                       |
 | didReadMap            | Called when the tilemap is finished parsing.                     |
 | didRenderMap          | Called when the tilemap layers are finished rendering.           |
 | didAddNavigationGraph | Called when the a navigation graph is built for a layer.         |
 | objectForTileType     | Specify a custom tile object for use in tile layers.             |
 | objectForVectorType   | Specify a custom object for use in object groups.                |
 | objectForGraphType    | Specify a custom graph node object for use in navigation graphs. |
 
 ### Custom Objects ###
 
 Custom object methods can be used to substitute your own objects for tiles:
 
 ```swift
 func objectForTileType(named: String? = nil) -> SKTile.Type {
     if (named == "MyTile") {
        return MyTile.self
     }
    return SKTile.self
 }
 ```
 */
public protocol SKTilemapDelegate: AnyObject {
    var zDeltaForLayers: CGFloat { get }
    func didBeginParsing(_ tilemap: SKTilemap)
    func didAddTileset(_ tileset: SKTileset)
    func didAddLayer(_ layer: SKTiledLayerObject)
    func didReadMap(_ tilemap: SKTilemap)
    func didRenderMap(_ tilemap: SKTilemap)
    func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>)
    func objectForTileType(named: String?) -> SKTile.Type
    func objectForVectorType(named: String?) -> SKTileObject.Type
    func objectForGraphType(named: String?) -> GKGridGraphNode.Type
}
