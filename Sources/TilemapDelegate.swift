//
//  TilemapDelegate.swift
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



/// An interface to a tilemap object that allows the user to interact with it as it is being created as well as customizing its properties & behaviors.
///
/// ### Properties
///
/// - `zDeltaForLayers`:  Default z-distance between layers.
///
/// ### Instance Methods
///
/// Delegate callbacks are called asynchronously as the map is being read from disk and rendered:
///
/// - `didBeginParsing`:  called when the tilemap is instantiated.
/// - `didAddTileset`:  called when a tileset is added to a map.
/// - `didAddLayer`:  called when a layer is added to a tilemap.
/// - `didReadMap`:  called when the tilemap is finished parsing.
/// - `didRenderMap`:  called when the tilemap layers are finished rendering.
/// - `didAddNavigationGraph`:  called when the a navigation graph is built for a layer.
/// - `objectForTileType`:  specify a custom tile object for use in tile layers.
/// - `objectForVectorType`:  specify a custom object for use in object groups.
/// - `objectForGraphType`:  specify a custom graph node object for use in navigation graphs.
/// - `willAddTile`:  called when a tile is about to be built.
/// - `didAddTile`:  called when a tile has just been built.
/// - `attributesForNodes`:  Add custom attributes for Tiled nodes of the given type
///
/// ### Event Handlers
///
/// - `mouseOverTileHandler`:  custom tile mouse event handler **(macOS only)**.
/// - `mouseOverObjectHandler`:  custom object mouse event handler **(macOS only)**.
/// - `tileClickedHandler`:  custom tile mouse event handler **(macOS only)**.
/// - `objectClickedHandler`:  custom object mouse event handler **(macOS only)**.
/// - `tileTouchedHandler`:  custom tile touch event handler **(iOS only)**.
/// - `objectTouchedHandler`:  custom object touch event handler **(iOS only)**.
///
/// ### Usage
///
/// ### Custom Objects
///
/// Custom object methods can be used to substitute your own objects for tiles:
///
/// ```swift
/// func objectForTileType(named: String? = nil) -> SKTile.Type {
///     if (named == "MyTile") {
///        return MyTile.self
///     }
///     return SKTile.self
/// }
/// ```
///
/// ### Attribute Overrides
///
/// The delegate method [`attributesForNodes`][tilemapdelegate-attrs-url] allows custom attributes to be added to an object based on global id, node type or name:
///
/// ```swift
/// func attributesForNodes(ofType: String?, named: String?, globalIDs: [UInt32]) -> [String : String]? {
///     if (ofType == "barrel") {
///         if (globalIDs.contains(2)) {
///             return ["jumpBonus": "100", "hammerBonus": "300"]
///         } else {
///             return ["jumpBonus": "300", "hammerBonus": "800"]
///         }
///     }
///     return nil
/// }
/// ```
///
/// ### Mouse & Touch Handlers
///
/// The optional delegate method [`mouseOverTileHandler`][tilemapdelegate-mouseover-url] allows mouse and touch event handlers to be added to tiles and vector objects:
///
///
///
/// ```swift
/// @objc public func mouseOverTileHandler(globalID: UInt32, ofType: String?) -> ((SKTile) -> ())? {
///     guard let tileType = ofType else {
///         return nil
///     }
///
///     switch tileType {
///         case "floors":
///             return { (tile) in tile.tileData.setValue(for: "color", "#308CC6") }
///
///         case "walls":
///             return { (tile) in tile.tileData.setValue(for: "color", "#8E6214") }
///
///         default:
///             return nil
///     }
/// }
/// ```
///
/// This method allows a developer to filter tiles by global id or type, or simply return a closure for all objects globally (regardless of global ID or type).
///
///
///
/// The [`tileClickedHandler`][tilemapdelegate-tileclicked-url] allows you to set a custom click handler for tiles & objects:
///
/// ```swift
/// @objc func tileClickedHandler(globalID: UInt32, ofType: String?, button: UInt8) -> ((SKTile) -> ())? {
///     switch globalID {
///         case 24, 25:
///             return { (tile) in
///                 tile.tileData.setValue(for: "wasVisited", "true")
///         }
///         default:
///             return nil
///     }
/// }
/// ```
///
/// ### Global ID Overrides
///
/// The delegate method `willAddTile` allows the global ID of a tile to be modified *before* the tile is created:
///
/// ```swift
/// @objc func willAddTile(globalID: UInt32, coord: simd_int2, in: String?) -> UInt32 {
///     if (globalID == 217) {
///        return 320
///     }
///     return globalID
/// }
/// ```
///
/// [tilemapdelegate-willaddtile-url]:TilemapDelegate.html#willAddTile(globalID:coord:in:)
/// [tilemapdelegate-attrs-url]:TilemapDelegate.html#attributesForNodes(ofType:named:globalIDs:)
/// [sktilemap-url]:../Classes/SKTilemap.html
/// [tilemapdelegate-mouseover-url]:TilemapDelegate.html#/s:7SKTiled17TilemapDelegateP18attributesForNodes6ofType5named9globalIDsSDyS2SGSgSSSg_AJSays6UInt32VGtF
/// [tilemapdelegate-tileclicked-url]:TiledEventHandler.html#/c:@M@SKTiled@objc(pl)TiledEventHandler(im)tileClickedHandlerWithGlobalID:ofType:
@objc public protocol TilemapDelegate: TiledEventHandler {

    /// Determines the z-position difference between layers.
    @objc optional var zDeltaForLayers: CGFloat { get }

    /// Called when the tilemap is instantiated.
    ///
    /// - Parameter tilemap: tilemap instance.
    @objc optional func didBeginParsing(_ tilemap: SKTilemap)

    /// Called when a tileset is added to a map.
    ///
    /// - Parameter tileset: tileset instance.
    @objc optional func didAddTileset(_ tileset: SKTileset)

    /// Called when a layer is added to a tilemap.
    ///
    /// - Parameter layer: tilemap instance.
    @objc optional func didAddLayer(_ layer: TiledLayerObject)

    /// Called when the tilemap is finished parsing.
    ///
    /// - Parameter tilemap: tilemap instance.
    @objc optional func didReadMap(_ tilemap: SKTilemap)

    /// Called when the tilemap layers are finished rendering.
    ///
    /// - Parameter tilemap: tilemap instance.
    @objc optional func didRenderMap(_ tilemap: SKTilemap)

    /// Called when the a navigation graph is built for a layer.
    ///
    /// - Parameter graph: `GKGridGraph<GKGridGraphNode>` graph node instance.
    @objc optional func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>)

    /// Specify a custom tile object for use in tile layers.
    ///
    /// - Parameter named: optional class name.
    /// - Returns: tile object type.
    @objc optional func objectForTileType(named: String?) -> SKTile.Type

    /// Specify a custom object for use in object groups.
    ///
    /// - Parameter named: optional class name
    /// - Returns: vector object type.
    @objc optional func objectForVectorType(named: String?) -> SKTileObject.Type

    /// Specify a custom graph node object for use in navigation graphs.
    ///
    /// - Parameter named: optional class name.
    /// - Returns: pathfinding graph node type.
    @objc optional func objectForGraphType(named: String?) -> GKGridGraphNode.Type

    /// Called whem a tile is about to be built in a layer at a given coordinate. Allows a global ID value to be substituted before the tile is created.
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - coord: tile coordinate (optional).
    ///   - in: layer name (optional).
    /// - Returns: tile global id.
    @objc optional func willAddTile(globalID: UInt32, coord: simd_int2, in: String?) -> UInt32

    /// Called whem a tile is about to be built in a layer. Allows a global ID value to be substituted before the tile is created.
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - in: layer name (optional).
    /// - Returns: tile global id.
    @objc optional func willAddTile(globalID: UInt32, in: String?) -> UInt32

    /// Called whem a tile has just been built in a layer.
    ///
    /// - Parameters:
    ///   - tile: tile instance.
    ///   - coord: tile coordinate.
    ///   - in: layer name.
    @objc optional func didAddTile(_ tile: SKTile, coord: simd_int2, in: String?)

    /// Called whem a tile has just been built in a layer.
    ///
    /// - Parameters:
    ///   - tile: tile instance.
    ///   - in: layer name.
    @objc optional func didAddTile(_ tile: SKTile, in: String?)

    /// Provides custom attributes for objects of a certain *Tiled type*.
    ///
    /// - Parameters:
    ///   - type: type value.
    ///   - named: optional node name.
    /// - Returns: custom attributes dictionary.
    @objc optional func attributesForNodes(ofType: String?, named: String?, globalIDs: [UInt32]) -> [String : String]?



    @objc optional func didChangeTiledGID(for tile: SKTile)
}



/// :nodoc: Typealias for v1.2 compatibility.
public typealias SKTilemapDelegate = TilemapDelegate
