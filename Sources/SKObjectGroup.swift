//
//  SKObjectGroup.swift
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


/// Represents object group draw order:
///
/// - topdown:  objects are rendered from top-down
/// - manual:   objects are rendered manually
internal enum SKObjectGroupDrawOrder: String {
    case topdown   // default
    case manual
}


/// ## Overview
///
/// The `SKObjectGroup` class is a container for vector object types. Most object properties can be set on the parent `SKObjectGroup` which is then applied to all child objects.
///
///
/// ### Properties
///
/// | Property              | Description                                                      |
/// |-----------------------|------------------------------------------------------------------|
/// | count                 | Returns the number of objects in the layer.                      |
/// | showObjects           | Toggle visibility for all of the objects in the layer.           |
/// | lineWidth             | Governs object line width for each object.                       |
/// | debugDrawOptions      | Debugging display flags.                                         |
///
/// ### Methods
///
/// | Method                | Description                                                      |
/// |-----------------------|------------------------------------------------------------------|
/// | addObject             | Add an object to the object group.                               |
/// | removeObject          | Remove an object from the object group.                          |
/// | getObject(withID:)    | Returns an object with the given id, if it exists.               |
///
/// ### Usage
///
/// Adding a child object with optional color override:
///
/// ```swift
/// objectGroup.addObject(myObject, withColor: SKColor.red)
/// ```
///
/// Querying an object with a specific name:
///
/// ```swift
/// let doorObject = objectGroup.getObject(named: "Door")
/// ```
///
/// Returning objects of a certain type:
///
/// ```swift
/// let rockObjects = objectGroup.getObjects(ofType: "Rock")
/// ```
public class SKObjectGroup: TiledLayerObject {

    /// Object drawing order.
    internal var drawOrder: SKObjectGroupDrawOrder = SKObjectGroupDrawOrder.topdown

    /// Array of child objects.
    fileprivate var objects: Set<SKTileObject> = []

    /// Returns the number of objects in this layer.
    public var count: Int { return objects.count }

    /// Controls antialiasing for each object
    public override var antialiased: Bool {
        didSet {
            objects.forEach { $0.isAntialiased = antialiased }
        }
    }

    internal var _lineWidth: CGFloat = 1.5

    /// Governs object line width for each object.
    public var lineWidth: CGFloat {
        get {
            let maxWidth = _lineWidth * 2.5
            let proposedWidth = (_lineWidth / tilemap.currentZoom)
            return proposedWidth < maxWidth ? (proposedWidth < _lineWidth) ? _lineWidth : proposedWidth : maxWidth
        } set {
            _lineWidth = newValue
        }
    }

    /// Returns a tuple of render stats used for debugging.
    override internal var renderInfo: RenderInfo {
        var current = super.renderInfo
        current.obj = count
        return current
    }

    override var layerRenderStatistics: LayerRenderStatistics {
        var current = super.layerRenderStatistics
        var oc: Int

        switch updateMode {
            case .full:
                oc = self.getObjects().count
            case .dynamic:
                oc = 0
            default:
                oc = 0
        }

        current.objects = oc
        return current
    }

    /// Render scaling property.
    public override var renderQuality: CGFloat {
        didSet {
            guard renderQuality != oldValue else { return }
            for object in objects where object.isRenderableType == true {
                object.renderQuality = renderQuality
            }
        }
    }

    /// Debug visualization options.
    @objc public override var debugDrawOptions: DebugDrawOptions {
        didSet {
            guard oldValue != debugDrawOptions else { return }
            let doShowObjects = debugDrawOptions.contains(.drawObjectFrames)
            objects.forEach { $0.showBounds = doShowObjects }
        }
    }

    /// Speed modifier applied to all actions executed by the layer and its descendants.
    public override var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.getObjects().forEach {$0.speed = speed}
        }
    }

    // MARK: - Initialization

    /// Initialize with layer name and parent `SKTilemap` instance.
    /// - Parameters:
    ///   - layerName: layer name.
    ///   - tilemap: parent map.
    public override init(layerName: String, tilemap: SKTilemap) {
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .object
        self.color = tilemap.objectColor
    }

    /// Initialize with parent `SKTilemap` and layer attributes.
    ///  **Do not use this intializer directly**
    ///
    /// - Parameters:
    ///   - tilemap: parent map.
    ///   - attributes: layer attributes.
    public init?(tilemap: SKTilemap, attributes: [String: String]) {
        let layerName = attributes["name"] ?? "null"
        super.init(layerName: layerName, tilemap: tilemap, attributes: attributes)
        self.color = tilemap.objectColor

        // set objects color
        if let hexColor = attributes["color"] {
            self.color = SKColor(hexString: hexColor)
        }

        self.layerType = .object
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Objects

    /// Add an `SKTileObject` vector object to the objects set.
    ///
    /// - Parameters:
    ///   - object: object instance.
    ///   - withColor: optional override color (otherwise defaults to parent layer color).
    /// - Returns: added object.
    public func addObject(_ object: SKTileObject, withColor: SKColor? = nil) -> SKTileObject? {
        if objects.contains(where: { $0.hashValue == object.hashValue }) {
            return nil
        }

        // if the object has a color property override, use that instead
        if object.hasKey("color") {
            if let hexColor = object.stringForKey("color") {
                object.setColor(color: SKColor(hexString: hexColor))
            }
        }

        // position the object
        let pixelPosition = object.position
        let screenPosition = pixelToScreenCoords(point: pixelPosition)

        object.position = screenPosition.invertedY
        object.isAntialiased = antialiased
        object.lineWidth = lineWidth
        objects.insert(object)
        object.layer = self
        object.ignoreProperties = ignoreProperties
        addChild(object)

        object.zPosition = (objects.isEmpty == false) ? CGFloat(objects.count) : 0

        // add to object cache
        NotificationCenter.default.post(
            name: Notification.Name.Layer.ObjectAdded,
            object: object,
            userInfo: nil
        )
        return object
    }

    /// Remove an `SKTileObject` object from the object set.
    ///
    /// - Parameter object: object instance.
    /// - Returns: removed object.
    public func removeObject(_ object: SKTileObject) -> SKTileObject? {
        NotificationCenter.default.post(
            name: Notification.Name.Layer.ObjectRemoved,
            object: object,
            userInfo: nil
        )
        return objects.remove(object)
    }

    /// Render all of the objects in the group.
    public func draw() {
        objects.forEach { $0.draw() }
    }

    /// Set the color for all objects.
    ///
    /// - Parameter color: object color.
    public override func setColor(color: SKColor) {
        super.setColor(color: color)
        objects.forEach { object in
            if !object.hasKey("color") {
                object.setColor(color: color)
            }
        }
    }

    /// Set the color for all objects.
    ///
    /// - Parameter hexString: color hex vale.
    public override func setColor(hexString: String) {
        super.setColor(hexString: hexString)
        objects.forEach { object in
            if !object.hasKey("color") {
                object.setColor(hexString: hexString)
            }
        }
    }

    /// Returns an array of object names.
    ///
    /// - Returns: object names in the layer.
    public func objectNames() -> [String] {
        return objects.compactMap { $0.name }
    }

    /// Returns an object with the given id.
    ///
    /// - Parameter id: Object id.
    /// - Returns: vector object.
    public func getObject(withID id: UInt32) -> SKTileObject? {
        if let index = objects.firstIndex(where: { $0.id == id }) {
            return objects[index]
        }
        return nil
    }

    /// Returns text objects with matching text.
    ///
    /// - Parameter text: text string to match.
    /// - Returns: array of matching objects.
    public func getObjects(withText text: String) -> [SKTileObject] {
        return getObjects().filter { $0.text != nil }.filter { $0.text! == text }
    }

    /// Returns objects with the given name.
    ///
    /// - Parameter named: Object name.
    /// - Returns: array of matching objects.
    public func getObjects(named: String) -> [SKTileObject] {
        return getObjects().filter { $0.name != nil }.filter { $0.name! == named }
    }

    /// Returns all child objects contained in the layer.
    ///
    /// - Returns: array of child objects.
    public func getObjects() -> [SKTileObject] {
        return Array(objects)
    }

    /// Returns objects of a given type.
    ///
    /// - Parameter ofType: object type.
    /// - Returns: array of matching objects.
    public func getObjects(ofType: String) -> [SKTileObject] {
        return getObjects().filter { $0.type != nil }.filter { $0.type! == ofType }
    }

    /// Returns object proxies.
    ///
    /// - Returns: array of object proxies.
    internal func getObjectProxies() -> [TileObjectProxy] {
        return objects.compactMap { $0.proxy }
    }

    /// Returns objects at the given screen position.
    ///
    /// - Parameter point: screen point.
    /// - Returns: objects at the given point.
    public func objectsAt(point:  CGPoint) -> [SKTileObject] {
        let result: [SKTileObject] = []
        //let coord = coordinateForPoint(point: point)

        // TODO: implement this
        return result
    }

    /// Returns objects at the given coordinate.
    ///
    /// - Parameter point: map coordinate.
    /// - Returns: objects at the given point.
    public func objectsAt(coord:  simd_int2) -> [SKTileObject] {
        let result: [SKTileObject] = []
        // TODO: implement this
        return result
    }

    // MARK: - Tile Objects

    /// Returns an array of objects representing tile objects.
    ///
    /// - Returns: objects with a tile gid.
    public func tileObjects() -> [SKTileObject] {
        return objects.filter { $0.globalID != nil }
    }

    /// Return tile object(s) matching the given global id.
    ///
    /// - Parameter globalID: global id to query.
    /// - Returns: array of matching tile objects.
    public func tileObjects(globalID: UInt32) -> [SKTileObject] {
        return objects.filter { $0.globalID == globalID }
    }

    /// Create and add a tile object with the given tile data.
    ///
    /// - Parameter data: tile data.
    /// - Returns: created tile object.
    public func newTileObject(data: SKTilesetData) -> SKTileObject {
        var objectSize = tilemap.tileSize
        if let texture = data.texture {
            objectSize = texture.size()
        }
        let object = SKTileObject(width: objectSize.width, height: objectSize.height)
        object.globalID = data.globalID
        _ = addObject(object)
        object.draw()
        return object
    }

    // MARK: - Text Objects

    /// Returns an array of textual objects.
    ///
    /// - Returns: text objects.
    public func textObjects() -> [SKTileObject] {
        return objects.filter { $0.textAttributes != nil }
    }

    // MARK: - Physics

    /// Setup tile collisions for each object.
    public override func setupTileCollisions() {
        objects.forEach { object in
            object.tile?.setupTileCollisions(offset: CGSize.zero)
        }
    }

    // MARK: - Callbacks

    /// Called when the layer is finished rendering.
    ///
    /// - Parameter duration: transition duration.
    public override func didFinishRendering(duration: TimeInterval = 0) {
        super.didFinishRendering(duration: duration)

        // setup dynamics for objects.
        objects.forEach {
            if ($0.boolForKey("isDynamic") == true) || ($0.boolForKey("isCollider") == true) {
                $0.setupPhysics()
            }
        }
    }

    // MARK: - Updating: Object Group

    /// Run animation actions on all of the tile objects in this layer.
    public override func runAnimationAsActions() {
        super.runAnimationAsActions()
        let animatedObjects = getObjects().filter { $0.isAnimated == true }
        animatedObjects.forEach { $0.tile?.runAnimationAsActions() }
    }

    /// Remove tile object animation.
    ///
    /// - Parameter restore: restore tile/object texture.
    public override func removeAnimationActions(restore: Bool = false) {
        super.removeAnimationActions(restore: restore)

        let animatedTiles = getObjects().filter { object in
            if let tile = object.tile {
                return tile.tileData.isAnimated == true
            }
            return false
        }

        animatedTiles.forEach { object in
            object.tile!.removeAnimationActions(restore: restore)
        }
    }

    // MARK: - Updating

    /// Update the object group before each frame is rendered.
    ///
    /// - Parameter currentTime: update interval.
    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard (self.updateMode != TileUpdateMode.actions) else { return }
    }
    
    
    // MARK: - Reflection
    
    
    /// Returns a custom mirror for this layer.
    public override var customMirror: Mirror {
        var attributes: [(label: String?, value: Any)] = [
            (label: "name", value: layerName),
            (label: "uuid", uuid),
            (label: "xPath", value: xPath),
            (label: "path", value: path),
            (label: "layerType", value: layerType),
            (label: "size", value: mapSize),
            (label: "offset", value: offset),
            (label: "properties", value: mirrorChildren()),
            (label: "objects", value: objects)
        ]

        
        /// internal debugging attrs
        attributes.append(("tiled element name", tiledElementName))
        attributes.append(("tiled node nice name", tiledNodeNiceName))
        attributes.append(("tiled list description", #"\#(tiledListDescription)"#))
        attributes.append(("tiled description", tiledDescription))
        
        return Mirror(self, children: attributes, ancestorRepresentation: .suppressed)
    }
}


// MARK: - Extensions


/// :nodoc:
extension SKObjectGroupDrawOrder: CustomStringConvertible, CustomDebugStringConvertible {
    
    var description: String {
        switch self {
            case .manual: return "manual"
            case .topdown: return "topdown"
        }
    }

    var debugDescription: String {
        return description
    }
}



// :nodoc:
extension SKObjectGroup {
    
    /// Returns the internal **Tiled** node type.
    @objc public var tiledElementName: String {
        return "objectgroup"
    }
    
    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return "Object Group"
    }
    
    /// Returns the internal **Tiled** node type icon.
    @objc public override var tiledIconName: String {
        return "objectgroup-icon"
    }
    
    /// A description of the node.
    @objc public override var tiledListDescription: String {
        let nameString = "'\(layerName)'"
        let ccstring = (children.count == 0) ? ": (no children)" : ": (\(children.count) children)"
        return "\(tiledNodeNiceName) \(nameString)\(ccstring)"
    }
    
    /// A description of the node.
    @objc public override var tiledDescription: String {
        return "Layer container for vector objects."
    }
}


// MARK: - Deprecations


extension SKObjectGroup {

    /// Returns an object with the given name.
    ///
    /// - Parameter named: Object name.
    /// - Returns: object matching the given name.
    @available(*, deprecated, message: "use `getObjects(named:recursive:)` instead")
    public func getObject(named: String) -> SKTileObject? {
        if let objIndex = objects.index(where: { $0.name == named }) {
            let object = objects[objIndex]
            return object
        }
        return nil
    }

    /// Render all of the objects in the group.
    @available(*, deprecated, renamed: "draw()")
    public func drawObjects() {
        self.draw()
    }

    /// Return tile object(s) matching the given global id.
    ///
    /// - Parameter globalID: global id to query.
    /// - Returns: array of matching tile objects.
    @available(*, deprecated, renamed: "tileObjects(globalID:)")
    public func tileObjects(globalID: Int) -> [SKTileObject] {
        return tileObjects(globalID: UInt32(globalID))
    }

    /// Returns an object with the given id.
    ///
    /// - Parameter id: Object id.
    /// - Returns: vector object.
    @available(*, deprecated, renamed: "getObject(withID:)")
    public func getObject(withID id: Int) -> SKTileObject? {
        return getObject(withID: UInt32(id))
    }
}
