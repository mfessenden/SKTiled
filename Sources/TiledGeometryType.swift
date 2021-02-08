//
//  SKTiledGeometry.swift
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


/// ## Overview
///
/// The `TiledGeometryType` protocol describes a drawable type used to manage & render **Tiled** objects.
///
/// ### Properties
///
///  - `objectPath`: the node's bounding shape
///  - `bounds`:  the node's bounding rect
///  - `renderQuality`: render scaling quality
///  - `visibleToCamera`: node is visible to camera
///
/// ### Methods
///
///  - `getVertices(offset: CGPoint)`: return's the node's shape points
///  - `contains(touch: CGPoint)`: returns true if a point is contained in this shape's frame
///
@objc public protocol TiledGeometryType: TiledSelectableType, TiledRasterizableType, TiledObjectType, DebugDrawableType {

    /// The object's parent container.
    @objc optional var container: TiledMappableGeometryType? { get }

    /// A path defining the shape of geometry. Used to draw the bounding shape.
    @objc var objectPath: CGPath { get }

    /// Object bounding box shape.
    @objc var boundsShape: SKShapeNode? { get set }

    /// Object bounding rectangle, in local space.
    @objc var boundingRect: CGRect { get }

    /// Render scaling property.
    @objc var renderQuality: CGFloat { get set }

    /// The object is visible to scene cameras.
    @objc var visibleToCamera: Bool { get set }

    /// Indicates the node has been touched, either by mouse or touch event.
    ///
    /// - Parameter touch: point in **this** node.
    /// - Returns: node was touched.
    @objc func contains(touch: CGPoint) -> Bool

    /// Returns the points representing the object's bounding shape - translated with the current map orientation.
    ///
    /// - Parameter offset: offset to be applied to each point.
    /// - Returns: array of points.
    @objc func getVertices(offset: CGPoint) -> [CGPoint]

    /// Refresh the object's content.
    @objc optional func draw()
}



// MARK: - Extensions

/// :nodoc:
extension TiledGeometryType {

    /// Returns the `SKTiled` geometry object class name.
    public var className: String {
        let objtype = String(describing: Swift.type(of: self))
        if let suffix = objtype.components(separatedBy: ".").last {
            return suffix
        }
        return objtype
    }

    /// Key used to access bounding box shapes.
    internal var boundsKey: String {
        return "\(uuid)_BOUNDS"
    }
}


/// :nodoc:
extension SKNode {

    /// Node he rotation value (in degrees).
    @objc public var rotation: CGFloat {
        get {
            return zRotation.degrees()
        }
        set {
            zRotation = -newValue.radians()
        }
    }

    /// Returns true if an event (mouse or touch) contacts this node.
    ///
    /// - Parameter touch: event point in this node's coordinate space.
    /// - Returns: node shape was intersected.
    @objc public func contains(touch: CGPoint) -> Bool {
        var touchPoint = touch
        guard let scene = scene else {
            return false
        }
        touchPoint = convert(touch, to: scene)
        let touchedNode = scene.atPoint(touchPoint)
        return touchedNode === self || touchedNode.inParentHierarchy(self)
    }

    /// Returns **Tiled** nodes at the given **scene** location.
    ///
    /// - Parameter location: event location.
    /// - Returns: array of **Tiled** nodes at the given location.
    public func tiledNodes(at location: CGPoint) -> [TiledGeometryType] {
        return nodes(at: location).filter({ $0 as? TiledGeometryType != nil && $0.isHighlightable == true }) as! [TiledGeometryType]
    }

    #if os(macOS)

    // FIXME: this is overiding derivative classes

    /// Returns the object class name.
    public override var className: String {
        let objtype = String(describing: type(of: self))
        if let suffix = objtype.components(separatedBy: ".").last {
            return suffix
        }
        return objtype
    }
    #endif

    /// Returns true if the object is a tile or object.
    public var isHighlightable: Bool {
        return (self as? SKTileObject != nil) || (self as? SKTile != nil)
    }

    /// Returns true if the object is a tiled layer object.
    public var isLayerType: Bool {
        return (self as? TiledLayerObject != nil)
    }


    /// Returns the frame rectangle of the layer (used to draw bounds).
    @objc public var boundingRect: CGRect {
        guard let tilednode = self as? TiledMappableGeometryType else {
            return CGRect.zero
        }

        // FIXME: offset is off with infinite maps
        let nodesize = tilednode.sizeInPoints
        return CGRect(x: 0, y: 0, width: nodesize.width, height: -nodesize.height)
    }

    /// Object bounding vertices in **Tiled space**.
    ///
    /// - Parameter offset: point offset.
    /// - Returns: array of shape points.
    @objc public func getVertices(offset: CGPoint = CGPoint.zero) -> [CGPoint] {
        guard let tiledGeo = self as? TiledGeometryType else {
            return [CGPoint]()
        }

        // FIXME: offset is off with infinite maps
        var offset = CGPoint.zero
        if let tiledLayer = self as? TiledLayerObject {
            offset = tiledLayer.layerInfiniteOffset
        }

        let vertices = tiledGeo.boundingRect.points
        return vertices.map { $0 - offset }
    }

    /// Generic highlight method that works for all `SpriteKit` types.
    ///
    /// - Parameters:
    ///   - color: highlight color.
    ///   - duration: duration of highlight effect.
    @objc public func highlightNode(with color: SKColor, duration: TimeInterval = 0) {

        // FIXME: this is a mess
        let removeHighlight: Bool = (color == SKColor.clear)
        let highlightFillColor = (removeHighlight == false) ? color.withAlphaComponent(0.2) : color

        if let sprite = self as? SKSpriteNode {

            var spritecolor = color
            var colorblendfactor: CGFloat = (removeHighlight == false) ? 1 : 0
            if let tiledSprite = sprite as? SKTile {

                if tiledSprite.tintColor != nil {
                    colorblendfactor = 1

                    if removeHighlight == true {
                        spritecolor = tiledSprite.tintColor!
                    }
                }
            }

            sprite.color = spritecolor
            sprite.colorBlendFactor = colorblendfactor

            if let tiledGeo = sprite as? TiledGeometryType {
                if (removeHighlight == false) {
                    tiledGeo.boundsShape?.strokeColor = color
                    tiledGeo.boundsShape?.lineWidth = 1
                    tiledGeo.boundsShape?.zPosition = zPosition + 1
                } else {
                    tiledGeo.boundsShape?.strokeColor = SKColor.clear
                }
            }

            if (duration > 0) {
                let fadeInAction = SKAction.colorize(withColorBlendFactor: 1, duration: duration)
                let groupAction = SKAction.group(
                    [
                        fadeInAction,
                        SKAction.wait(forDuration: duration),
                        fadeInAction.reversed()
                    ]
                )

                sprite.run(groupAction, completion: {
                    if let tiledSprite = sprite as? TiledGeometryType {
                        tiledSprite.boundsShape?.isHidden = true
                    }
                })
            }
            return
        }

        if let shape = self as? SKShapeNode {
            if let tiledObejct = shape as? SKTileObject {
                tiledObejct.proxy?.highlightNode(with: color, duration: duration)
            } else {
                shape.strokeColor = color
                shape.lineWidth = 1
                shape.fillColor = highlightFillColor
                shape.isAntialiased = false
                if (duration > 0) {
                    shape.run(SKAction.colorFadeAction(after: duration))
                }
                return
            }
        }
    }

    /// Remove the current object's highlight color.
    public func removeHighlight() {
        highlightNode(with: SKColor.clear)
    }

    /// Remove the current node's anchor point.
    public func removeAnchor() {
        childNode(withName: "ANCHOR")?.removeFromParent()
    }

    /// Draw the bounds of the object type.
    ///
    /// - Parameters:
    ///   - color: fill & stroke color.
    ///   - fillOpacity: fill opacity.
    ///   - duration: bounds shape lifetime.
    public func drawNodeBounds(with color: SKColor,
                               lineWidth: CGFloat = 1,
                               fillOpacity: CGFloat = 0,
                               duration: TimeInterval = 0) {


        if let tiledNode = self as? TiledGeometryType {
            guard let shape = tiledNode.boundsShape else {
                return
            }

            shape.isHidden = false
            shape.strokeColor = color
            if fillOpacity > 0 {
                shape.fillColor = color.withAlphaComponent(fillOpacity)
            }

            if (duration > 0) {
                shape.run(SKAction.run {
                    shape.isHidden = true
                })
            }
        }
    }

    /// Draw the bounds of the object type.
    public func drawNodeBounds() {
        if let _ = self as? TiledGeometryType {
            let fColor = TiledGlobals.default.debugDisplayOptions.frameColor
            let duration = TiledGlobals.default.debugDisplayOptions.highlightDuration
            drawNodeBounds(with: fColor, lineWidth: 1, fillOpacity: 0, duration: duration)
        }
    }
}


extension SKTilemap: TiledGeometryType {}
extension TiledLayerObject: TiledGeometryType {}
extension SKTileObject: TiledGeometryType {}
extension SKTile: TiledGeometryType {}
