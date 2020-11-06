//
//  SKObjectGroup.swift
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
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


/**
 Represents object group draw order:
 
 - topdown:  objects are rendered from top-down
 - manual:   objects are rendered manually
 */
internal enum SKObjectGroupDrawOrder: String {
    case topdown   // default
    case manual
}


/**
 ## Overview
 
 The `SKObjectGroup` class is a container for vector object types. Most object properties can be set on the parent `SKObjectGroup` which is then applied to all child objects.
 
 
 ### Properties
 
 | Property              | Description                                                      |
 |-----------------------|------------------------------------------------------------------|
 | count                 | Returns the number of objects in the layer.                      |
 | showObjects           | Toggle visibility for all of the objects in the layer.           |
 | lineWidth             | Governs object line width for each object.                       |
 | debugDrawOptions      | Debugging display flags.                                         |
 
 ### Methods ###
 
 | Method                | Description                                                      |
 |-----------------------|------------------------------------------------------------------|
 | addObject             | Returns the number of objects in the layer.                      |
 | removeObject          | Toggle visibility for all of the objects in the layer.           |
 | getObject(withID:)    | Returns an object with the given id, if it exists.               |
 
 ### Usage
 
 Adding a child object with optional color override:
 
 ```swift
 objectGroup.addObject(myObject, withColor: SKColor.red)
 ```
 
 Querying an object with a specific name:
 
 ```swift
 let doorObject = objectGroup.getObject(named: "Door")
 ```
 
 Returning objects of a certain type:
 
 ```swift
 let rockObjects = objectGroup.getObjects(ofType: "Rock")
 ```
 */
public class SKObjectGroup: SKTiledLayerObject {
    
    internal var drawOrder: SKObjectGroupDrawOrder = SKObjectGroupDrawOrder.topdown
    fileprivate var objects: Set<SKTileObject> = []
    
    /// Toggle visibility for all of the objects in the layer.
    public var showObjects: Bool = false {
        didSet {
            let proxies = self.getObjectProxies()
            
            NotificationCenter.default.post(
                name: Notification.Name.DataStorage.ProxyVisibilityChanged,
                object: proxies,
                userInfo: ["visibility": showObjects]
            )
        }
    }
    
    /// Returns the number of objects in this layer.
    public var count: Int { return objects.count }
    
    /// Controls antialiasing for each object
    override public var antialiased: Bool {
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
    override public var renderQuality: CGFloat {
        didSet {
            guard renderQuality != oldValue else { return }
            for object in objects where object.isRenderableType == true {
                object.renderQuality = renderQuality
            }
        }
    }
    
    /// Debug visualization options.
    override public var debugDrawOptions: DebugDrawOptions {
        didSet {
            guard oldValue != debugDrawOptions else { return }
            let doShowObjects = debugDrawOptions.contains(.drawObjectBounds)
            objects.forEach { $0.showBounds = doShowObjects }
        }
    }
    
    override public var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            self.getObjects().forEach {$0.speed = speed}
        }
    }
    
    // MARK: - Init
    /**
     Initialize with layer name and parent `SKTilemap`.
     
     - parameter layerName:    `String` layer name.
     - parameter tilemap:      `SKTilemap` parent map.
     */
    override public init(layerName: String, tilemap: SKTilemap) {
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .object
        self.color = tilemap.objectColor
    }
    
    /**
     Initialize with parent `SKTilemap` and layer attributes.
     
     **Do not use this intializer directly**
     
     - parameter tilemap:      `SKTilemap` parent map.
     - parameter attributes:   `[String: String]` layer attributes.
     */
    public init?(tilemap: SKTilemap, attributes: [String: String]) {
        guard let layerName = attributes["name"] else { return nil }
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
    
    /**
     Add an `SKTileObject` object to the objects set.
     
     - parameter object:    `SKTileObject` object.
     - parameter withColor: `SKColor?` optional override color (otherwise defaults to parent layer color).
     - returns: `SKTileObject?` added object.
     */
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
        let screenPosition = pixelToScreenCoords(pixelPosition)
        
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
    
    /**
     Remove an `SKTileObject` object from the object set.
     
     - parameter object:    `SKTileObject` object.
     - returns: `SKTileObject?` removed object.
     */
    public func removeObject(_ object: SKTileObject) -> SKTileObject? {
        NotificationCenter.default.post(
            name: Notification.Name.Layer.ObjectRemoved,
            object: object,
            userInfo: nil
        )
        return objects.remove(object)
    }
    
    /**
     Render all of the objects in the group.
     */
    public func draw() {
        objects.forEach { $0.draw() }
    }
    
    /**
     Set the color for all objects.
     
     - parameter color: `SKColor` object color.
     - parameter force: `Bool` force color on objects that have an override.
     */
    override public func setColor(color: SKColor) {
        super.setColor(color: color)
        objects.forEach { object in
            if !object.hasKey("color") {
                object.setColor(color: color)
            }
        }
    }
    
    /**
     Set the color for all objects.
     
     - parameter color: `SKColor` object color.
     - parameter force: `Bool` force color on objects that have an override.
     */
    override public func setColor(hexString: String) {
        super.setColor(hexString: hexString)
        objects.forEach { object in
            if !object.hasKey("color") {
                object.setColor(hexString: hexString)
            }
        }
    }
    
    /**
     Returns an array of object names.
     
     - returns: `[String]` object names in the layer.
     */
    public func objectNames() -> [String] {
        return objects.compactMap { $0.name }
    }
    
    /**
     Returns an object with the given id.
     
     - parameter id: `Int` Object id.
     - returns: `SKTileObject?`
     */
    public func getObject(withID id: Int) -> SKTileObject? {
        if let index = objects.firstIndex(where: { $0.id == id }) {
            return objects[index]
        }
        return nil
    }
    
    /**
     Return text objects with matching text.
     
     - parameter withText: `String` text string to match.
     - returns: `[SKTileObject]` array of matching objects.
     */
    public func getObjects(withText text: String) -> [SKTileObject] {
        return getObjects().filter { $0.text != nil }.filter { $0.text! == text }
    }
    
    /**
     Return objects with the given name.
     
     - parameter named: `String` Object name.
     - returns: `[SKTileObject]` array of matching objects.
     */
    public func getObjects(named: String) -> [SKTileObject] {
        return getObjects().filter { $0.name != nil }.filter { $0.name! == named }
    }
    
    /**
     Return all child objects.
     
     - returns: `[SKTileObject]` array of matching objects.
     */
    public func getObjects() -> [SKTileObject] {
        return Array(objects)
    }
    
    /**
     Return objects of a given type.
     
     - parameter type: `String` object type.
     - returns: `[SKTileObject]` array of matching objects.
     */
    public func getObjects(ofType: String) -> [SKTileObject] {
        return getObjects().filter { $0.type != nil }.filter { $0.type! == ofType }
    }
    
    /**
     Return object proxies.
     
     - returns: `[TileObjectProxy]` array of object proxies.
     */
    internal func getObjectProxies() -> [TileObjectProxy] {
        return objects.compactMap { $0.proxy }
    }
    
    // MARK: - Tile Objects
    
    /**
     Return tile objects.
     
     - returns: `[SKTileObject]` objects with a tile gid.
     */
    public func tileObjects() -> [SKTileObject] {
        return objects.filter { $0.gid != nil }
    }
    
    /**
     Return tile object(s) matching the given global id.
     
     - parameter globalID:    `Int` global id to query.
     - returns: `SKTileObject?` removed object.
     */
    public func tileObjects(globalID: Int) -> [SKTileObject] {
        return objects.filter { $0.gid == globalID }
    }
    
    /**
     Create and add a tile object with the given tile data.
     
     - parameter data: SKTilesetData` tile data.
     - returns: `SKTileObject` created tile object.
     */
    public func newTileObject(data: SKTilesetData) -> SKTileObject {
        var objectSize = tilemap.tileSize
        if let texture = data.texture {
            objectSize = texture.size()
        }
        let object = SKTileObject(width: objectSize.width, height: objectSize.height)
        object.gid = data.globalID
        _ = addObject(object)
        object.draw()
        return object
    }
    
    // MARK: - Text Objects
    
    /**
     Return text objects.
     
     - returns: `[SKTileObject]` text objects.
     */
    public func textObjects() -> [SKTileObject] {
        return objects.filter { $0.textAttributes != nil }
    }
    
    // MARK: - Callbacks
    
    /**
     Called when the layer is finished rendering.
     
     - parameter duration: `TimeInterval` fade-in duration.
     */
    override public func didFinishRendering(duration: TimeInterval = 0) {
        super.didFinishRendering(duration: duration)
        
        // setup dynamics for objects.
        objects.forEach {
            if ($0.boolForKey("isDynamic") == true) || ($0.boolForKey("isCollider") == true) {
                $0.setupPhysics()
            }
        }
    }
    
    // MARK: - Updating: Object Group
    
    /**
     Run animation actions on all tile objects.
     */
    override public func runAnimationAsActions() {
        super.runAnimationAsActions()
        let animatedObjects = getObjects().filter { $0.isAnimated == true }
        animatedObjects.forEach { $0.tile?.runAnimationAsActions() }
    }
    
    /**
     Remove tile object animation.
     
     - parameter restore: `Bool` restore tile/obejct texture.
     */
    override public func removeAnimationActions(restore: Bool = false) {
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
    /**
     Update the object group before each frame is rendered.
     
     - parameter currentTime: `TimeInterval` update interval.
     */
    override public func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard (self.updateMode != TileUpdateMode.actions) else { return }
    }
}



// MARK: - Extensions



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


// MARK: - Deprecated


extension SKObjectGroup {
    /**
     Returns an object with the given name.
     
     - parameter named: `String` Object name.
     - returns: `SKTileObject?`
     */
    @available(*, deprecated, message: "use `getObjects(named:,recursive:)` instead")
    public func getObject(named: String) -> SKTileObject? {
        if let objIndex = objects.firstIndex(where: { $0.name == named }) {
            let object = objects[objIndex]
            return object
        }
        return nil
    }
    
    /// Render all of the objects in the group.
    @available(*, deprecated, renamed: "SKObjectGroup.draw()")
    public func drawObjects() {
        self.draw()
    }
}
