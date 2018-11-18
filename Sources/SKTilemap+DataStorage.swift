//
//  SKTilemap+DataStorage.swift
//  SKTiled
//
//  Created by Michael Fessenden on 8/12/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit


typealias TileList      = StorageArray<SKTile>
typealias ObjectsList   = StorageArray<SKTileObject>

typealias DataCache     = [SKTilesetData: TileList]
typealias ActionsCache  = [SKTilesetData: SKAction]


internal enum CacheIsolationMode: Int {
    case none
    case `default`
    case ignored
    case `static`
    case animated
}



/// Data structure for storing and recalling tile data efficiently.
internal class TileDataStorage: Loggable {
    weak var tilemap: SKTilemap?
    // queues
    fileprivate let storageQueue = DispatchQueue(label: "com.sktiled.tileDataStorage.storageQueue", qos: .userInteractive, attributes: .concurrent)
    // update queue, for tile texture changes
    fileprivate let updateQueue  = DispatchQueue(label: "com.sktiled.tileDataStorage.updateQueue", qos: .userInteractive)

    var staticTileCache:   DataCache = [:]
    var animatedTileCache: DataCache = [:]
    var actionsCache:      ActionsCache = [:]
    
    var objectsList: ObjectsList
    var blockNotifications: Bool = true

    var isolationMode: CacheIsolationMode = CacheIsolationMode.none {
        didSet {
            guard oldValue != isolationMode else { return }
            self.isolateTilesAction()
        }
    }

    init(map: SKTilemap) {
        tilemap = map
        objectsList  = ObjectsList(queue: self.storageQueue)
        setupNotifications()
    }

    /**
     Setup notifications.
     */
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(objectProxyVisibilityChanged), name: Notification.Name.DataStorage.ProxyVisibilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdated), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectAddedToLayer), name: Notification.Name.Layer.ObjectAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectWasRemovedFromLayer), name: Notification.Name.Layer.ObjectRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileAddedToLayer), name: Notification.Name.Layer.TileAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileDataChanged), name: Notification.Name.Tile.DataChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileRenderModeChanged), name: Notification.Name.Tile.RenderModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileDataActionAdded), name: Notification.Name.TileData.ActionAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileDataFrameAdded), name: Notification.Name.TileData.FrameAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileDataTextureChanged), name: Notification.Name.TileData.TextureChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilesetSpriteSheetUpdated), name: Notification.Name.Tileset.SpriteSheetUpdated, object: nil)
    }

    deinit {
        tilemap = nil
        blockNotifications = true

        // reset caches
        staticTileCache    = [:]
        animatedTileCache  = [:]
        actionsCache       = [:]

        NotificationCenter.default.removeObserver(self, name: Notification.Name.DataStorage.ProxyVisibilityChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Layer.ObjectAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Layer.ObjectRemoved, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Layer.TileAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tile.DataChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tile.RenderModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.TileData.ActionAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.TileData.FrameAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.TileData.TextureChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tileset.SpriteSheetUpdated, object: nil)
    }

    /// Returns an array of all stored tiles.
    var allTiles: [SKTile] {
        var result: [SKTile] = []
        for items in staticTileCache.enumerated() {
            result.append(contentsOf: items.element.value.array)
        }

        for items in animatedTileCache.enumerated() {
            result.append(contentsOf: items.element.value.array)
        }

        return result
    }

    // MARK: - Notifications

    @objc func tileAddedToLayer(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        addTileToCache(tile: tile)
    }

    @objc func objectAddedToLayer(notification: Notification) {
        guard let object = notification.object as? SKTileObject else {
            return
        }
        guard (objectsList.filter { $0 == object }.isEmpty == true) else {
            return
        }
        
        objectsList.append(object)
        storageQueue.sync {}
    }

    /**
     Called when a map or layer node `showObjects` attribute is changed.

     - parameter notification: `Notification` notification.
     */
    @objc func objectProxyVisibilityChanged(notification: Notification) {
        guard let proxies = notification.object as? [TileObjectProxy],
            let userInfo = notification.userInfo as? [String: Bool] else { return }

        let proxiesVisible: Bool = userInfo["visibility"] ?? false

        var proxiesUpdated = 0
        for proxy in proxies {
            proxy.showObjects = proxiesVisible
            proxy.draw()
            proxiesUpdated += 1
        }
    }


    /**
     Called when tile data is changed via the tile `renderMode` flag.

     - parameter notification: `Notification` notification.
     */
    @objc func tileDataChanged(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        guard let userInfo = notification.userInfo as? [String: Any],
            let oldTileData = userInfo["oldData"] as? SKTilesetData else {
                return
        }

        // add the tile to the appropriate dictionary, and remove from the previous
        let newTileData = tile.tileData

        // old data is animated and new data is (and vice versa)
        _ = (oldTileData.isAnimated) == (newTileData.isAnimated)

        let oldTileList: TileList = (oldTileData.isAnimated == true) ? animatedCacheForTileData(oldTileData) : cacheForTileData(oldTileData)
        let newTileList: TileList = (newTileData.isAnimated == true) ? animatedCacheForTileData(newTileData) : cacheForTileData(newTileData)

        oldTileList.remove(where: {$0 == tile})
        newTileList.append(tile)

        // transfer attributes
        newTileData.frameIndex = oldTileData.frameIndex
        newTileData.currentTime = oldTileData.currentTime

        // update the tile render mode after we've changed
        tile.renderMode = TileRenderMode.default
    }

    /**
     Called when a tileset's spritesheet is updated.

     - parameter notification: `Notification` notification.
     */
    @objc func tilesetSpriteSheetUpdated(notification: Notification) {
        guard let tileset = notification.object as? SKTileset,
            let userInfo = notification.userInfo as? [String: Any],
            let animatedTiles = userInfo["animatedTiles"] as? [SKTilesetData] else { return }

        updateQueue.async {
            for data in animatedTiles {
                data.removeAnimation()
                data._frames.forEach { frame in
                    if let frameData = tileset.getTileData(localID: frame.id) {
                        frame.texture = frameData.texture
                    }
                }
                data.runAnimation()
            }
        }
    }

    /**
     Called when a tile's render mode is changed.

     - parameter notification: `Notification` notification.
     */
    // Tile.RenderModeChanged
    @objc func tileRenderModeChanged(notification: Notification) {
        guard let tile = notification.object as? SKTile,
            let userInfo = notification.userInfo as? [String: Any],
            let oldMode = userInfo["old"] as? TileRenderMode else { return }
        
        guard let tilemap = tilemap else {
            return
        }


        let tileData = tile.tileData
        tile.drawBounds(withColor: nil, zpos: nil, duration: 0)

        // indicates the tile has an animation override
        let tileHadOverridenAnimation = (oldMode.rawValue > 2) || (oldMode.rawValue < 0)
        // indicates we need to update the tile (ie pop from one list to another)
        var needToUpdateTile = false
        if (tileHadOverridenAnimation == true) {
            moveTileFrom(tile: tile, globalID: oldMode.rawValue)
        }

        
        switch tile.renderMode {

        // tile should not animate
        case .static:
            tile.removeAnimationActions(restore: false)
            needToUpdateTile = true
    
            
        // tile will ignore it's tile data
        case .ignore:
            let existingList: TileList = (tileData.isAnimated == true) ? animatedCacheForTileData(tileData) : cacheForTileData(tileData)
            // remove the tile from the current list
            existingList.remove(where: { $0 == tile })

        // tile has requested new tile data
        case .animated(let gid):
            guard let globalID = gid else {
                break
            }

            var newDataIsAnimated = false

            if let newTileData = tilemap.getTileData(globalID: globalID) {
                let existingList: TileList = (tileData.isAnimated == true) ? animatedCacheForTileData(tileData) : cacheForTileData(tileData)

                // remove the tile from the current list
                existingList.remove(where: { $0 == tile })

                newDataIsAnimated = newTileData.isAnimated
                let nextList: TileList = (newDataIsAnimated == true) ? animatedCacheForTileData(newTileData) : cacheForTileData(newTileData)

                nextList.append(tile)
            }

        default:
            needToUpdateTile = true
        }
        
        
        // refresh the tile's texture
        if (needToUpdateTile == true) {
            
            // turn off notifications for the tile while it is updated
            tile.blockNotifications = true
            
            // update the tile with the current texture
            if let currentTexture = tile.tileData.texture {
                tile.texture = currentTexture
                tile.size = currentTexture.size()
                
                // turn notifications back on
                DispatchQueue.main.async {
                    tile.blockNotifications = false
                }
            }
        }
    }

    /**
     Called when tile data frames are updated.

     - parameter notification: `Notification` notification.
     */
    @objc func tileDataFrameAdded(notification: Notification) {
        guard let tileData = notification.object as? SKTilesetData else { return }
        tileData.dataChanged = true
    }

    /**
     Called when a tile data's animation `SKAction` is created.

     - parameter notification: `Notification` notification.
     */
    @objc func tileDataActionAdded(notification: Notification) {
        guard let tileData = notification.object as? SKTilesetData,
            let userInfo = notification.userInfo as? [String: Any],
            let action = userInfo["action"] as? SKAction else { return }

        //typealias ActionsCache  = [SKTilesetData: SKAction]
        self.actionsCache[tileData] = action
    }

    /**
     Called when a tile data's texture is updated. Previous texture is passed in `userInfo`.

     - parameter notification: `Notification` notification.
     */
    @objc func tileDataTextureChanged(notification: Notification) {
        guard let tileData = notification.object as? SKTilesetData,
            (notification.userInfo as? [String: Any] != nil) else { return }

        // if we're in dynamic mode, all of the textures need to be updated in static...
        guard let newTexture = tileData.texture else {
            self.log("invalid texture for data: \(tileData.globalID)", level: .warning)
            return
        }

        let currentTiles = (tileData.isAnimated == true) ? animatedCacheForTileData(tileData) : cacheForTileData(tileData)

        // update every tile that uses this texture
        updateQueue.async {
            currentTiles.forEach { tile in

                switch tile.renderMode {
                case .ignore: break
                default:
                    // turn off notifications for the tile
                    tile.blockNotifications = true
                    tile.texture = newTexture
                    tile.size = newTexture.size()

                    // turn notifications back on
                    DispatchQueue.main.async {
                        tile.blockNotifications = false
                    }
                }
            }
        }
    }

    @objc func objectWasRemovedFromLayer(notification: Notification) {
        guard let object = notification.object as? SKTileObject else { return }

        _ = objectsList.remove(where: { $0 == object}) { obj in
            self.log("object removed: \(obj)", level: .debug)
            self.tilemap?.objectsOverlay.initialized = false
        }
    }

    @objc func globalsUpdated(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        if let newTileColor = userInfo["tileColor"] as? SKColor {
            updateQueue.async {
                for tile in self.allTiles {
                    tile.frameColor = newTileColor
                    tile.highlightColor = newTileColor
                }
            }
        }

        if let newObjectColor = userInfo["objectColor"] as? SKColor {
            updateQueue.async {
                for object in self.objectsList {
                    if let proxy = object.proxy {
                        proxy.objectColor = newObjectColor
                    }
                }
            }
        }
    }

    // MARK: - Caching

    func addTileToCache(tile: SKTile, data: SKTilesetData? = nil, cache: TileList? = nil) {
        let tileData = data ?? tile.tileData
        let currentCache: TileList = (cache != nil) ? cache! : (tileData.isAnimated == true) ? animatedCacheForTileData(tileData) : cacheForTileData(tileData)
        currentCache.append(tile)
    }

    /**
     Return or create a tile list for the changed data.

     - parameter data: `SKTilesetData` tile data.
     - returns `TileList` tile list.
     */
    func tileAnimationAction(for data: SKTilesetData) -> SKAction? {
        guard let savedAction = actionsCache[data] else {
            return nil
        }
        return savedAction
    }

    // MARK: - Helpers

    /**
     Return or create a tile list for the static data.

     - parameter data: `SKTilesetData` tile data.
     - returns `TileList` tile list.
     */
    private func cacheForTileData(_ data: SKTilesetData) -> TileList {
        guard let existingCache = staticTileCache[data] else {
            let newCache = TileList(queue: self.storageQueue)
            staticTileCache[data] = newCache
            return newCache
        }
        return existingCache
    }

    /**
     Return or create a tile list for the animated data.

     - parameter data: `SKTilesetData` tile data.
     - returns `TileList` tile list.
     */
    private func animatedCacheForTileData(_ data: SKTilesetData) -> TileList {
        guard let existingCache = animatedTileCache[data] else {
            let newCache = TileList(queue: self.storageQueue)
            animatedTileCache[data] = newCache
            return newCache
        }
        return existingCache
    }

    /**
     Move tile from one data list to another.
     
     - parameter tile: `SKTile` tile.
     - parameter from: `DataCache` source cache.
     - parameter to:   `DataCache` destination cache.
     - returns `(sucess: Bool, cache: DataCache, removed: DataCache?)` data was succesfully moved.
     */
    private func moveTileFrom(tile: SKTile, globalID: Int) {
        guard let tilemap = tilemap else {
            return
        }

        if let oldTileData = tilemap.getTileData(globalID: globalID) {
            let nextTileData = tile.tileData
            
            // move tile out of an animated data list
            // put it into another
            let existingList: TileList = (oldTileData.isAnimated == true) ? animatedCacheForTileData(oldTileData) : cacheForTileData(oldTileData)
            
            // remove the tile from the current list
            existingList.remove(where: { $0 == tile })
            let nextDataIsAnimated = nextTileData.isAnimated
            let nextList: TileList = (nextDataIsAnimated == true) ? animatedCacheForTileData(nextTileData) : cacheForTileData(nextTileData)
            nextList.append(tile)
        }
    }
    
    
    /**
     Move tile data from one cache to another.

      - parameter data: `SKTilesetData` tile data removed.
      - parameter from: `DataCache` source cache.
      - parameter to:   `DataCache` destination cache.
      - returns `(sucess: Bool, cache: DataCache, removed: DataCache?)` data was succesfully moved.
     */
    private func moveDataFrom(data: SKTilesetData, from sourceCache: inout DataCache, to destCache: inout DataCache) -> (sucess: Bool, cache: DataCache, removed: DataCache?) {
        guard let sourceIndex = sourceCache.index(forKey: data),
            (sourceCache != destCache) else {
            return (false, sourceCache, nil)
        }

        // get the list of associated tiles
        let removedList = sourceCache.remove(at: sourceIndex).value
        if let destIndex = destCache.index(forKey: data) {
            let existingList = destCache.remove(at: destIndex).value
            for tile in existingList {
                removedList.append(tile)
            }
        }
        destCache[data] = removedList
        return (true, destCache, sourceCache)
    }

    /**
     Build animation frames for the data.

     - parameter data: `SKTilesetData` tile data.
     */
    func buildAnimationForData(data: SKTilesetData) {
        updateQueue.async {
            data.removeAnimation()
            data._frames.forEach { frame in
                if let frameData = data.tileset.getTileData(localID: frame.id) {
                    frame.texture = frameData.texture
                }
            }
            data.runAnimation()
        }
    }

    func sync() {
        storageQueue.sync {}
        updateQueue.sync {}
    }

    /**
     Isolation mode updated.
     */
    func isolateTilesAction() {

        for tile in allTiles {

            // true if mode is anything but 'none'
            var doHideTile = (isolationMode != .none)

            switch tile.renderMode {

            case .animated(gid: _):
                doHideTile = (doHideTile == true) && (isolationMode != .animated)

            case .ignore:
                doHideTile = (doHideTile == true) && (isolationMode != .ignored)

            case .static:
                doHideTile = (doHideTile == true) && (isolationMode != .static)

            default:
                doHideTile = (doHideTile == true) && (isolationMode != .default)
            }

            tile.isHidden = doHideTile
        }

        NotificationCenter.default.post(
            name: Notification.Name.DataStorage.IsolationModeChanged,
            object: nil,
            userInfo: nil
        )
    }
}



extension TileDataStorage: CustomStringConvertible, CustomDebugStringConvertible, CustomDebugReflectable {
    
    var description: String {
        let staticCount = staticTileCache.count
        let animatedCount = animatedTileCache.count
        return "Tile Data Storage: static: \(staticCount), animated: \(animatedCount)"
    }
    
    var debugDescription: String {
        return description
    }
    
    
    func dumpStatistics() {
        let output = "\n----------- Tile Data Storage -----------"
        var staticOutput = underlined(for: "Static")
        var animatedOutput = underlined(for: "Animated")
        
        for item in staticTileCache.enumerated() {
            let tileData = item.element.key
            let tileList = item.element.value.array
            let tileDataHeader = "\n   - tile data: \(tileData.globalID) (\(tileList.count) tiles):"
            staticOutput += tileDataHeader
            
        }
        
        for item in animatedTileCache.enumerated() {
            let tileData = item.element.key
            let tileList = item.element.value.array
            let tileDataHeader = "\n   - tile data: \(tileData.globalID) (\(tileList.count) tiles):"
            animatedOutput += tileDataHeader
        }
        
        print("\n\(output)\n\(staticOutput)\n\(animatedOutput)")
    }
}


extension TileDataStorage: CustomReflectable {
    
    public var customMirror: Mirror {
        var staticDataCount = 0
        var animatedDataCount = 0
        var staticTileCount = 0
        var animatedTileCount = 0
        
        for (_, item) in staticTileCache.enumerated() {
            staticDataCount += 1
            staticTileCount += item.value.count
        }
        
        for (_, item) in animatedTileCache.enumerated() {
            animatedDataCount += 1
            animatedTileCount += item.value.count
        }
        
        let staticData: [String: Any] = ["data": staticDataCount, "tiles": staticTileCount]
        let animatedData: [String: Any] = ["data": animatedDataCount, "tiles": animatedTileCount]
        
        return Mirror(TileDataStorage.self, children:
                    ["static": staticData,
                     "animated": animatedData,
                     "objects": objectsList.count]
        )
    }
}



/// Thread-safe storage container.
internal class StorageArray<Element>: Equatable {

    fileprivate let uuid = UUID().uuidString
    fileprivate let queue: DispatchQueue
    fileprivate var array: [Element] = []

    init(queue: DispatchQueue? = nil) {
        self.queue = (queue == nil) ? DispatchQueue(label: "com.sktiled.storageQueue", attributes: .concurrent) : queue!
    }

    /// Number of elements in the array.
    var count: Int {
        var result = 0
        queue.sync { result = self.array.count }
        return result
    }

    /// A Boolean value indicating whether the collection is empty.
    var isEmpty: Bool {
        var result = false
        queue.sync { result = self.array.isEmpty }
        return result
    }
    
    /**
     
     Returns a boolean indicating the array contains the given element.
     
     - Parameters:
       - predicate: `(Element) -> Bool` conditional expression.
       - returns: `Bool` array contains the given element.
     */
    func contains(where predicate: (Element) -> Bool) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(where: predicate) }
        return result
    }

    /**
     
     Append a new element to the end of the array.
     
     - Parameters:
       - element: `Element` element to append.
     */
    func append( _ element: Element) {
        queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }
    
    /**

     Adds new elements to the array.

     - Parameters:
       - elements: `[Element]` array of elements to append.
    */
    func append(contentsOf elements: [Element]) {
        queue.async(flags: .barrier) {
            self.array += elements
        }
    }

    /**
     
     Insert a new element at the specified position.
     
     - Parameters:
       - element: `Element` array of elements to append.
       - index:   `Int` index to insert at.
     */
    func insert( _ element: Element, at index: Int) {
        queue.async(flags: .barrier) {
            self.array.insert(element, at: index)
        }
    }

    /// Removes and returns the element at the specified position.
    func remove(at index: Int, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let element = self.array.remove(at: index)

            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }

    /**
     
     Removes and returns the element at the specified position.
     
     - Parameters:
       - predicate:  `(Element) -> Bool` conditional expression.
       - completion: `([Element]) -> Void)?` optional completion closure.
     */
    func remove(where predicate: @escaping (Element) -> Bool, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            guard let index = self.array.index(where: predicate) else { return }
            let element = self.array.remove(at: index)

            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }

    /**
     
     Removes all elements from the array.
     
     - Parameters:
       - completion: `([Element]) -> Void)?` optional completion closure.
     */
    func removeAll(completion: (([Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let elements = self.array
            self.array.removeAll()

            DispatchQueue.main.async {
                completion?(elements)
            }
        }
    }


    /// Accesses the element at the specified position if it exists.
    subscript(index: Int) -> Element? {
        get {
            var result: Element?
            queue.sync {
                guard self.array.startIndex..<self.array.endIndex ~= index else { return }
                result = self.array[index]
            }
            return result
        }
        set {
            guard let newValue = newValue else { return }
            queue.async(flags: .barrier) {
                self.array[index] = newValue
            }
        }
    }
}


// MARK: - Extensions


extension CacheIsolationMode {
    static var all: [CacheIsolationMode] = [.default, .ignored, .static, .animated]
}


extension StorageArray: Hashable {
    
    /// Identifier hash.
    var hashValue: Int {
        return uuid.hashValue
    }
    
    static func == (lhs: StorageArray<Element>, rhs: StorageArray<Element>) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}



// Allows the cache array to act as a collection.
extension StorageArray: Sequence {

    internal func makeIterator() -> AnyIterator<Element> {
        var arrayIndex = 0
        return AnyIterator {
            if arrayIndex < self.count {
                let element = self[arrayIndex]
                arrayIndex+=1
                return element
            } else {
                arrayIndex = 0
                return nil
            }
        }
    }
}


extension StorageArray where Element: Equatable {
    /**
     
     Returns a boolean indicating the array contains the given element.
     
     - Parameters:
     - element: `Element -> Bool` element to query.
     - returns: `Bool` array contains the given element.
     */
    func contains(_ element: Element) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(element) }
        return result
    }
}



extension StorageArray {

    func filter(_ isIncluded: (Element) -> Bool) -> [Element] {
        var result: [Element] = []
        queue.sync { result = self.array.filter(isIncluded) }
        return result
    }

    /// Returns the first index in which an element of the collection satisfies the given predicate.
    func index(where predicate: (Element) -> Bool) -> Int? {
        var result: Int?
        queue.sync { result = self.array.index(where: predicate) }
        return result
    }

    /// Returns the elements of the collection, sorted using the given predicate as the comparison between elements.
    func sorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        var result: [Element] = []
        queue.sync { result = self.array.sorted(by: areInIncreasingOrder) }
        return result
    }

    /// Returns an array containing the non-nil results of calling the given transformation with each element of this sequence.
    func compactMap<Elements>(_ transform: (Element) -> Elements?) -> [Elements] {
        var result: [Elements] = []
        queue.sync { result = self.array.compactMap(transform) }
        return result
    }

    /// Calls the given closure on each element in the sequence in the same order as a for-in loop.
    func forEach(_ body: (Element) -> Void) {
        queue.sync { self.array.forEach(body) }
    }
}


extension StorageArray: CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of the array and its elements.
    var description: String {
        var result = ""
        queue.sync { result = self.array.description }
        return result
    }

    var debugDescription: String {
        return description
    }
}
