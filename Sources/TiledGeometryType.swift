//
//  TiledGeometryType.swift
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


/// The `TiledGeometryType` protocol describes a drawable type used to manage and render **Tiled** geometry objects.
///
/// ### Properties
///
///  - `objectPath`: the node's bounding shape
///  - `boundingRect`:  the node's bounding rect
///  - `boundsShape`:  the node's rect shape
///  - `renderQuality`: render scaling quality
///  - `visibleToCamera`: node is visible to camera
///
/// ### Methods
///
///  - `contains(touch: CGPoint)`: returns true if a point is contained in this shape's frame.
///  - `getVertices(offset: CGPoint)`: return's the node's shape points.
///  - `draw()`: draw the object's contents.
///
@objc public protocol TiledGeometryType: TiledSelectableType, TiledRasterizableType, TiledObjectType, DebugDrawableType {
    
    // TODO: implement this
    
    /// The object's parent container.
    @objc optional var container: TiledMappableGeometryType? { get }
    
    /// This object's `CGPath` defining the shape of geometry. Used to draw the bounding shape.
    @objc var objectPath: CGPath { get }
    
    /// Object bounding box shape.
    @objc var boundsShape: SKShapeNode? { get set }
    
    /// Object bounding rectangle, in local space.
    @objc var boundingRect: CGRect { get }
    
    /// Object anchor node visualization node.
    @objc var anchorShape: SKShapeNode { get set }
    
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
    
    /// Refresh the node's content.
    @objc optional func draw()
}



// MARK: - Extensions

/// :nodoc:
extension TiledGeometryType {
    
    
    /// Generic highlight method.
    ///
    /// - Parameters:
    ///   - color: highlight color.
    ///   - duration: highlight duration.
    public func highlightNode(with color: SKColor, duration: TimeInterval = 0) {
        print("⭑ [TiledGeometryType]: highlighing node...")
        boundsShape?.isHidden = false
        boundsShape?.strokeColor = color
        boundsShape?.fillColor = color.withAlphaComponent(0.2)
        
        anchorShape.isHidden = false
        anchorShape.fillColor = color
    }
    
    /// Generic highlight removal.
    public func removeHighlight() {
        // TODO: hide these nodes?
        boundsShape?.isHidden = true
        anchorShape.isHidden = true
    }
    
    
    /// Returns the `SKTiled` geometry object class name.
    public var className: String {
        let objtype = String(describing: Swift.type(of: self))
        if let suffix = objtype.components(separatedBy: ".").last {
            return suffix
        }
        return objtype
    }
    
    // MARK: - Indentifiers
    
    /// Unique identifier used to access bounding box shape nodes.
    internal var boundsKey: String {
        return "\(uuid)_BOUNDS"
    }
    
    /// Unique identifier used to access animation actions.
    internal var animationKey: String {
        return "\(uuid)_ANIMATION"
    }
    
    /// Unique identifier used to access anchor point shape nodes.
    internal var anchorKey: String {
        return "\(uuid)_ANIMATION"
    }
}


extension TiledGeometryType {

    /// Returns an array of shader unforms based on the current attributes.
    public var shaderUniforms: [SKUniform] {
        let uniforms: [SKUniform] = [
            SKUniform(name: "u_tint_color", color: SKColor.clear),
            SKUniform(name: "u_tint_strength", float: 1)
        ]
        return uniforms
    }
}



#if os(macOS)

/// :nodoc:
///
extension TiledGeometryType where Self: SKNode {
    
    // TODO: add `anchorShape` here?
    
    /// Addm this node's frame to the SpriteKit view's tracking views.
    public func addTrackingView() {
        guard let scene = scene,
              let view = scene.view else {
            return
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .cursorUpdate]
        let userInfo: [String: Any] = ["className": className]
        let trackingArea = NSTrackingArea(rect: boundingRect, options: options, owner: self, userInfo: userInfo)
        view.addTrackingArea(trackingArea)
    }
}

#endif




/// :nodoc:
extension SKNode {
    
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
    
    /// Returns an array of all visible **Tiled** geometry nodes (tiles, objects) that intersect a given point.
    ///
    /// - Parameter location: A point in the node’s coordinate system.
    /// - Returns: array of **Tiled** nodes at the given location.
    public func tiledNodes(at location: CGPoint) -> [TiledGeometryType] {
        return nodes(at: location).filter({ $0 as? TiledGeometryType != nil && $0.isHighlightable == true && $0.isHidden == false }) as! [TiledGeometryType]
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
    
    /// Returns an array of all visible **Tiled** nodes that intersect the given mouse event.
    ///
    /// - Parameter event: mouse event.
    /// - Returns: array of **Tiled** nodes at the event location.
    public func tiledNodes(with event: NSEvent) -> [TiledGeometryType] {
        return tiledNodes(at: event.location(in: self))
    }
    
    #elseif os(iOS) || os(tvOS)
    
    /// Returns the object class name.
    public var className: String {
        let objtype = String(describing: type(of: self))
        if let suffix = objtype.components(separatedBy: ".").last {
            return suffix
        }
        return objtype
    }
    
    /// Returns an array of all visible **Tiled** nodes that intersect the given mouse event.
    ///
    /// - Parameter event: mouse event.
    /// - Returns: array of **Tiled** nodes at the event location.
    public func tiledNodes(touch: UITouch) -> [TiledGeometryType] {
        return tiledNodes(at: touch.location(in: self))
    }
    
    #endif
    
    /// Returns true if the object is a tile or object.
    public var isHighlightable: Bool {
        return (self as? SKTileObject != nil) || (self as? SKTile != nil)
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
        print("⭑ [SKNode]: highlighing node...")
        
        /// highlight sprite types by setting colorblendfactor
        
        
        /// highlight shape types by adding a shape overlay
        
        let boundingBox = SKShapeNode(rectOf: calculateAccumulatedFrame().size)
        boundingBox.lineWidth = 1
        boundingBox.strokeColor = .black
        boundingBox.fillColor = .clear
        boundingBox.zPosition = zPosition + 1
        boundingBox.path = boundingBox.path?.copy(dashingWithPhase: 0, lengths: [10,10])
        addChild(boundingBox)
    }
    
    /// Remove the current object's highlight color.
    @objc public func removeHighlight() {}
}




// TODO: remove this if no longer used
/*
/// :nodoc:
extension SKNode {
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
                    shape.strokeColor = SKColor.clear
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
    
    public func removeNodeBounds() {
        if let tiledNode = self as? TiledGeometryType {
            guard let shape = tiledNode.boundsShape else {
                return
            }
            
            shape.isHidden = true
            shape.strokeColor = SKColor.clear
        }
    }
}
*/


/// :nodoc:
extension SKTilemap: TiledGeometryType {}
/// :nodoc:
extension TiledLayerObject: TiledGeometryType {}
/// :nodoc:
extension SKTileObject: TiledGeometryType {}
/// :nodoc:
extension SKTile: TiledGeometryType {}
