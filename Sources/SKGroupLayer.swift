//
//  SKGroupLayer.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
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
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


/// ## Overview
///
/// Subclass of `TiledLayerObject`, the group layer is a container for managing groups of layers.
///
/// ### Usage
///
/// Query child layers:
///
/// ```swift
/// for child in group.layers {
///     child.opacity = 0.5
/// }
/// ```
///
/// Add layers to the group with:
///
/// ```swift
/// groupLayer.addLayer(playerLayer)
/// ```
///
/// Remove with:
///
/// ```swift
/// groupLayer.removeLayer(playerLayer)
/// ```
public class SKGroupLayer: TiledLayerObject {

    private var _layers: Set<TiledLayerObject> = []

    /// Returns the last index for all layers.
    public var lastIndex: UInt32 {
        return (layers.isEmpty == false) ? layers.map { $0.index }.max()! : 0
    }

    /// Returns the last (highest) z-position in the map.
    public var lastZPosition: CGFloat {
        return layers.isEmpty == false ? layers.map {$0.zPosition}.max()! : 0
    }

    /// Returns a flattened array of child layers.
    public override var layers: [TiledLayerObject] {
        var result: [TiledLayerObject] = [self]
        for layer in _layers.sorted(by: { $0.index > $1.index }) {
            result += layer.layers
        }
        return result
    }

    /// Speed modifier applied to all actions executed by the layer and its descendants.
    public override var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.layers.forEach { $0.speed = speed }
        }
    }

    // MARK: - Init

    /// Initialize with a layer name, and parent `SKTilemap` node.
    ///
    /// - Parameters:
    ///   - layerName: image layer name.
    ///   - tilemap: parent map.
    public override init(layerName: String, tilemap: SKTilemap) {
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .group
    }

    /// Initialize with parent `SKTilemap` and layer attributes.
    ///
    ///  **Do not use this intializer directly**
    ///
    /// - Parameters:
    ///   - tilemap: parent map.
    ///   - attributes: layer attributes.
    public init?(tilemap: SKTilemap, attributes: [String: String]) {
        let layerName = attributes["name"] ?? "null"
        super.init(layerName: layerName, tilemap: tilemap, attributes: attributes)
        self.layerType = .group
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layers

    /// Returns all layers, sorted by index (first is lowest, last is highest).
    ///
    /// - Returns: array of layers.
    public func allLayers() -> [TiledLayerObject] {
        return layers.sorted(by: {$0.index < $1.index})
    }

    /// Returns an array of layer names.
    ///
    /// - Returns: layer names.
    public func layerNames() -> [String] {
        return layers.compactMap { $0.name }
    }

    /// Add a layer to the layers set. Automatically sets zPosition based on the tilemap zDeltaForLayers attributes.
    ///
    /// - Parameters:
    ///   - layer: layer object.
    ///   - clamped: clamp position to nearest pixel.
    /// - Returns: add was successful, layer added.
    @discardableResult
    public func addLayer(_ layer: TiledLayerObject, clamped: Bool = true) -> (success: Bool, layer: TiledLayerObject) {

        // set the zPosition relative to the layer index ** adding multiplier - layers with difference of 1 seem to have z-fighting issues **.
        let zMultiplier: CGFloat = 5
        let nextZPosition = (_layers.isEmpty == false) ? CGFloat(_layers.count + 1) * zMultiplier : 1

        // set the layer index
        layer.index = lastIndex + 1

        let (success, inserted) = _layers.insert(layer)
        if (success == false) {
            Logger.default.log("could not add layer: '\(inserted.layerName)'", level: .error)
        }


        // layer offset
        layer.position.x += layer.offset.x
        layer.position.y -= layer.offset.y


        addChild(layer)

        layer.zPosition = nextZPosition

        // override debugging colors
        layer.gridColor = gridColor
        layer.frameColor = frameColor
        layer.highlightColor = highlightColor
        layer.loggingLevel = loggingLevel
        layer.ignoreProperties = ignoreProperties

        return (success, inserted)
    }

    /// Remove a layer from the current layers set.
    ///
    /// - Parameter layer: layer object.
    /// - Returns: removed layer.
    public func removeLayer(_ layer: TiledLayerObject) -> TiledLayerObject? {
        return _layers.remove(layer)
    }

    // MARK: - Updating

    /// Update the group layer before each frame is rendered.
    ///
    /// - Parameter currentTime: update interval.
    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
    }

    /// Returns the internal **Tiled** node type.
    @objc public override var tiledNodeName: String {
        return "group layer"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return "Group Layer"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public override var tiledIconName: String {
        return "group-icon"
    }

    /// A description of the node.
    @objc public override var tiledListDescription: String {
        let childCount = (children.count == 0) ? ": (no children)" : ": (\(children.count) children)"
        let layerNameString = (name != nil) ? " '\(name!)'" : ""
        return "\(tiledNodeNiceName)\(layerNameString)\(childCount)"
    }

    /// A description of the node.
    @objc public override var tiledDescription: String {
        return "Container node for Tiled layer types."
    }
}
