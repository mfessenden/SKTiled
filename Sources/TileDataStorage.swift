//
//  TileDataStorage.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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

import Foundation
import SpriteKit


typealias TileList          = ThreadSafeArray<SKTile>
typealias ObjectsList       = ThreadSafeArray<SKTileObject>
typealias GeometryList      = ThreadSafeArray<TiledGeometryType>


typealias DataCache         = [SKTilesetData: TileList]
typealias GlobalIDCache     = [UInt32: TileList]
typealias ActionsCache      = [SKTilesetData: SKAction]


internal enum CacheIsolationMode: UInt8 {
    case none
    case `default`
    case ignored
    case `static`
    case animated
}


/// :nodoc:
internal struct MemorySize {

    /// Raw size (in bytes).
    let bytes: Int64

    /// Instantiate with a bytes value.
    ///
    /// - Parameter bytes: size in bytes.
    init(bytes: Int64) {
        self.bytes = bytes
    }
}




/// Data structure for storing and recalling tile data efficiently.
internal class TileDataStorage: Loggable {

    /// Queues
    fileprivate let updateQueue = DispatchQueue(label: "org.sktiled.tileDataStorage.updateQueue", qos: .userInitiated)
    fileprivate let storageQueue = DispatchQueue(label: "org.sktiled.tileDataStorage.storageQueue", qos: .userInitiated, attributes: .concurrent)

    /// The parent tilemap.
    weak var tilemap: SKTilemap?
    
    /// Cache for fast global ID lookup.
    var globalIdCache: GlobalIDCache = [:]

    /// Cache for static tile data.
    var staticTileCache: DataCache = [:]

    /// Cache for animated tile data.
    var animatedTileCache: DataCache = [:]

    /// Cache for Spritekit actions.
    var actionsCache: ActionsCache = [:]

    /// List of objects in the current tilemap.
    var objectsList: ObjectsList?

    /// Indicates the cache should ignore notifications.
    var blockNotifications: Bool = true

    var sizeString: String {
        let memsize = MemorySize(bytes: self.bytes)
        return memsize.description
    }

    /// Returns the size (in bytes) of the cache.
    var bytes: Int {
        /*
        var result = MemoryLayout.size(ofValue: globalIdCache.self)
        result += MemoryLayout.size(ofValue: staticTileCache.self)
        result += MemoryLayout.size(ofValue: animatedTileCache.self)
        result += MemoryLayout.size(ofValue: actionsCache.self)
        result += MemoryLayout.size(ofValue: objectsList.self)
        return result
        */
        return malloc_size(Unmanaged.passRetained(self).toOpaque())
    }

    /// Returns the size of the cache (in kilobytes).
    var kilobytes: Float {
        return Float(bytes) * 0.001
    }

    /// Returns the size of the cache (in megabytes).
    var megabytes: Float {
        return kilobytes * 0.001
    }

    /// Returns the current tile isolation mode.
    var cacheIsolationMode: CacheIsolationMode = CacheIsolationMode.none {
        didSet {
            guard oldValue != cacheIsolationMode else { return }
            self.isolateTilesAction()
        }
    }

    /// Returns the current tilemap tile update mode, or the global modes.
    var updateMode: TileUpdateMode {
        guard let tilemap = tilemap else {
            return TiledGlobals.default.updateMode
        }
        return tilemap.updateMode
    }

    // MARK: - Initialization

    /// Initialize with a tilemap instance.
    ///
    /// - Parameter map: tilemap node.
    init(map: SKTilemap) {
        tilemap = map
        objectsList = ObjectsList(queue: self.storageQueue)
        setupNotifications()
    }

    // MARK: - Notifications

    /// Setup notifications.
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectAddedToLayer), name: Notification.Name.Layer.ObjectAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectWasRemovedFromLayer), name: Notification.Name.Layer.ObjectRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileAddedToLayer), name: Notification.Name.Layer.TileAdded, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(tileTileIDChanged), name: Notification.Name.Tile.TileIDChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileTileDataChanged), name: Notification.Name.Tile.TileDataChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileRenderModeChanged), name: Notification.Name.Tile.RenderModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileCreatedAction), name: Notification.Name.Tile.TileCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileDestroyedAction), name: Notification.Name.Tile.TileDestroyed, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(objectCreatedAction), name: Notification.Name.Object.ObjectCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectDestroyedAction), name: Notification.Name.Object.ObjectDestroyed, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(tileDataActionAdded), name: Notification.Name.TileData.ActionAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileDataFrameAdded), name: Notification.Name.TileData.FrameAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileDataTextureChanged), name: Notification.Name.TileData.TextureChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilesetSpriteSheetUpdated), name: Notification.Name.Tileset.SpriteSheetUpdated, object: nil)
    }

    deinit {
        // turn off notifications
        blockNotifications = true

        // remove notifications
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Layer.ObjectAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Layer.ObjectRemoved, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Layer.TileAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tile.TileDataChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tile.RenderModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Object.ObjectCreated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Object.ObjectDestroyed, object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name.TileData.ActionAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.TileData.FrameAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.TileData.TextureChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tileset.SpriteSheetUpdated, object: nil)


        // reset caches
        staticTileCache    = [:]
        globalIdCache      = [:]
        animatedTileCache  = [:]
        actionsCache       = [:]
        objectsList        = nil

    }

    // MARK: - Tiles


    /// Returns an array of all stored tiles.
    var allTiles: [SKTile] {
        var result: [SKTile] = []
        for item in staticTileCache {
            result.append(contentsOf: item.value)
        }

        for item in animatedTileCache {
            result.append(contentsOf: item.value)
        }

        return result
    }

    /// Returns an array of tiles matching a given global id.
    ///
    /// - Returns: array of tiles.
    subscript(gid: UInt32) -> [SKTile]? {
        return globalIdCache[gid]?.toArray()
    }

    /// Add a tile to storage. Called when the `Notification.Name.Tile.TileCreated` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func tileCreatedAction(notification: Notification) {
        guard let tile = notification.object as? SKTile else {
            log("no tile sent", level: .warning)
            return
        }
        addTileToCache(tile: tile)
    }

    /// Add a tile to storage. Called when the `Notification.Name.Tile.TileDestroyed` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func tileDestroyedAction(notification: Notification) {
        guard let tile = notification.object as? SKTile else {
            log("no tile sent", level: .warning)
            return
        }

        let listToRemoveFrom: TileList = (tile.tileData.isAnimated == true) ? animatedCacheForTileData(tile.tileData) : cacheForTileData(tile.tileData)
        listToRemoveFrom.remove(where: {$0 == tile})

        #if SKTILED_DEMO
        NotificationCenter.default.post(
            name: Notification.Name.Demo.NodeSelectionCleared,
            object: nil
        )
        #endif

    }

    /// Add a tile to storage. Called when the `Notification.Name.Layer.TileAdded` notification is received.
    ///
    ///  userInfo: ["layer": `SKTileLayer`, "object": `SKTileObject`, "coord": `simd_int2`]
    ///  userInfo: ["chunk``": `SKTileLayerChunk`]
    ///
    /// - Parameter notification: event notification.
    @objc func tileAddedToLayer(notification: Notification) {
        guard let tile = notification.object as? SKTile else {
            return
        }
        addTileToCache(tile: tile)
    }

    /// Called when a tile id changes. Called when the `Notification.Name.Tile.TileIDChanged` notification is received.
    ///
    /// - userInfo: `["old": UInt32]`
    ///
    /// - Parameter notification: event notification.
    @objc func tileTileIDChanged(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        guard let userInfo = notification.userInfo as? [String: Any],
            let _ = userInfo["old"] as? UInt32 else {
                return
        }

        guard let tilemap = tilemap else {
            return
        }

        if let newTileData = tilemap.getTileData(globalID: tile.globalId) {

            // turn off notifications for the tile while it is updated
            tile.blockNotifications = true
            tile.tileData = newTileData

            // update the tile with the current texture
            if let currentTexture = tile.tileData.texture {
                tile.texture = currentTexture

                if (tile.isTileObject == false) {
                    tile.size = currentTexture.size()
                    tile.orientTile()
                }

                // turn notifications back on
                DispatchQueue.main.async {
                    tile.blockNotifications = false
                }
            }
        }
    }

    /// Called when tile data is changed via the tile `renderMode` flag, or the `SKTile.setTileData` method.
    ///
    /// - Parameter notification: event notification.
    @objc func tileTileDataChanged(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        guard let userInfo = notification.userInfo as? [String: Any],
            let oldTileData = userInfo["old"] as? SKTilesetData else {
                return
        }


        // add the tile to the appropriate dictionary, and remove from the previous
        let newTileData = tile.tileData

        // old data is animated and new data is (and vice versa)
        _ = (oldTileData.isAnimated) == (newTileData.isAnimated)

        // kill any animation actions
        tile.removeAnimationActions()

        let listToRemoveFrom: TileList = (oldTileData.isAnimated == true) ? animatedCacheForTileData(oldTileData) : cacheForTileData(oldTileData)
        let listToAppendTo:   TileList = (newTileData.isAnimated == true) ? animatedCacheForTileData(newTileData) : cacheForTileData(newTileData)

        listToRemoveFrom.remove(where: {$0 == tile})
        listToAppendTo.append(tile)

        // transfer animation attributes
        newTileData.frameIndex = oldTileData.frameIndex
        newTileData.currentTime = oldTileData.currentTime

        // update the tile render mode after we've changed
        tile.renderMode = TileRenderMode.default

        // cache the tile
        addTileToCache(tile: tile)
    }


    /// Called when a tileset's spritesheet is updated.
    ///
    /// - Parameter notification: event notification.
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

    /// Called when a tile's render mode is changed.
    ///
    /// - Parameter notification: event notification.
    @objc func tileRenderModeChanged(notification: Notification) {
        guard let tile = notification.object as? SKTile,
            let userInfo = notification.userInfo as? [String: Any],
            let oldMode = userInfo["old"] as? TileRenderMode else { return }

        guard let tilemap = tilemap else {
            return
        }

        let tileData = tile.tileData

        // indicates the tile has an animation override
        let tileHadOverridenAnimation = (oldMode.rawValue > 2) || (oldMode.rawValue < 0)

        // indicates we need to update the tile (ie pop from one list to another)
        var needToUpdateTile = false


        if (tileHadOverridenAnimation == true) {
            moveTileFrom(tile: tile, globalID: UInt32(oldMode.rawValue))
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

                if let newTileData = tilemap.getTileData(globalID: UInt32(globalID)) {
                    let existingList: TileList = (tileData.isAnimated == true) ? animatedCacheForTileData(tileData) : cacheForTileData(tileData)

                    // remove the tile from the current list
                    existingList.remove(where: { $0 == tile })

                    newDataIsAnimated = newTileData.isAnimated
                    let nextList: TileList = (newDataIsAnimated == true) ? animatedCacheForTileData(newTileData) : cacheForTileData(newTileData)

                    nextList.append(tile)

                    // see if this forces update
                    needToUpdateTile = (newTileData.isAnimated == false)


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

    /// Called when tile data frames are updated.
    ///
    /// - Parameter notification: event notification.
    @objc func tileDataFrameAdded(notification: Notification) {
        guard let tileData = notification.object as? SKTilesetData else { return }
        tileData.dataChanged = true
    }

    /// Called when a tile data's animation `SKAction` is created.
    ///
    /// - Parameter notification: event notification.
    @objc func tileDataActionAdded(notification: Notification) {
        guard let tileData = notification.object as? SKTilesetData,
            let userInfo = notification.userInfo as? [String: Any],
            let action = userInfo["action"] as? SKAction else { return }

        self.actionsCache[tileData] = action
    }

    /// Called when a tile data's texture is updated. Previous texture is passed in `userInfo`.
    ///
    /// - Parameter notification: event notification.
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

    // MARK: Objects


    /// Called when a new object is created (outside of parsing). Called when the `Notification.Name.Object.ObjectCreated` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func objectCreatedAction(notification: Notification) {
        guard let object = notification.object as? SKTileObject else {
            log("no object sent", level: .warning)
            return
        }

        guard (objectsList?.filter { $0 == object }.isEmpty == true) else {
            return
        }

        objectsList?.append(object)
    }

    /// Called when a vector object type is destroyed. Called when the `Notification.Name.Object.ObjectDestroyed` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func objectDestroyedAction(notification: Notification) {
        guard let object = notification.object as? SKTileObject else {
            log("no object sent", level: .warning)
            return
        }

        objectsList?.remove(where: { $0 == object}) { obj in
            self.log("object removed '\(obj.debugDescription)'", level: .debug)
            self.tilemap?.objectsOverlay.initialized = false
            obj.destroy()



            #if SKTILED_DEMO
            NotificationCenter.default.post(
                name: Notification.Name.Demo.NodeSelectionCleared,
                object: nil
            )
            #endif
        }
    }


    /// Called when an object is added to the storage.
    ///
    /// - Parameter notification: event notification.
    @objc func objectAddedToLayer(notification: Notification) {
        guard let object = notification.object as? SKTileObject else {
            return
        }

        guard (objectsList?.filter { $0 == object }.isEmpty == true) else {
            return
        }

        objectsList?.append(object)
    }


    /// Called when a vector object type is removed from its parent layer.
    ///
    /// - Parameter notification: event notification.
    @objc func objectWasRemovedFromLayer(notification: Notification) {
        guard let object = notification.object as? SKTileObject,
            let objectsList = objectsList else { return }

        objectsList.remove(where: { $0 == object}) { obj in
            self.log("object removed '\(obj.debugDescription)'", level: .debug)
            self.tilemap?.objectsOverlay.initialized = false
            obj.destroy()
        }
    }

    /// Called when global values have changed.
    ///
    /// - Parameter notification: event notification.
    @objc func globalsUpdatedAction(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let objectsList = objectsList else { return }


        if let newObjectColor = userInfo["objectColor"] as? SKColor {
            updateQueue.async {
                for object in objectsList {
                    if let proxy = object.proxy {
                        proxy.objectColor = newObjectColor
                    }
                }
            }
        }
    }

    // MARK: - Caching

    /// Add a tile to storage.
    ///
    /// - Parameters:
    ///   - tile: tile being added.
    ///   - data: tile data.
    ///   - cache: optional tile list.
    func addTileToCache(tile: SKTile, data: SKTilesetData? = nil, cache: TileList? = nil) {
        let tileData = data ?? tile.tileData
        let currentCache: TileList = (cache != nil) ? cache! : (tileData.isAnimated == true) ? animatedCacheForTileData(tileData) : cacheForTileData(tileData)


        let globalId = tileData.globalID
        currentCache.append(tile)
        globalIdCache[globalId]?.append(tile)

        if (updateMode == TileUpdateMode.actions) {
            if (tileData.isAnimated == true) {
                tile.runAnimationAsActions()
            } else {

                // set the tile data from the texture
                tile.texture = tileData.texture

                // reset tile size (if not a tile object)
                if (tile.isTileObject == false) {
                    tile.size = tileData.texture.size()
                }

                // redraw the tile
                //tile.draw()
            }
        }
    }

    /// Returns a tile animation action for the given data.
    ///
    /// - Parameter data: tile data.
    /// - Returns: tile animation action.
    func tileAnimationAction(for data: SKTilesetData) -> SKAction? {
        guard let savedAction = actionsCache[data] else {
            return nil
        }
        return savedAction
    }

    // MARK: - Queries

    /// Returns the tile data corresponding to the given global id.
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: tile data.
    func tileDataFor(globalID: UInt32) -> SKTilesetData? {
        for item in staticTileCache {
            if item.key.globalID == globalID {
                return item.key
            }
        }

        for item in animatedTileCache {
            if item.key.globalID == globalID {
                return item.key
            }
        }
        return nil
    }

    /// Returns tiles matching the given global id.
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: tiles with the given global id.
    func allTiles(globalID: UInt32) -> [SKTile]? {
        var result: [SKTile] = []
        for item in staticTileCache {
            if item.key.globalID == globalID {
                result.append(contentsOf: item.value)
            }
        }

        for item in animatedTileCache {
            if item.key.globalID == globalID {
                result.append(contentsOf: item.value)
            }
        }

        return (result.isEmpty == false) ? result : nil
    }

    /// Returns an array of tiles matching the given type.
    ///
    /// - Parameter ofType: tile type.
    /// - Returns: array of tiles with the given type.
    func allTiles(ofType: String) -> [SKTile]? {
        var result: [SKTile] = []
        for item in staticTileCache {
            if item.key.type == ofType {
                result.append(contentsOf: item.value)
            }
        }

        for item in animatedTileCache {
            if item.key.type == ofType {
                result.append(contentsOf: item.value)
            }
        }

        return (result.isEmpty == false) ? result : nil
    }

    /// Returns a tile animation action for the given data.
    ///
    /// - Parameter globalID: tile global id.
    /// - Returns: tile animation action.
    func tileAnimationAction(globalID: UInt32) -> SKAction? {
        for item in actionsCache {
            if item.key.globalID == globalID {
                return item.value
            }
        }
        return nil
    }

    // MARK: - Helpers

    /// Return or create a tile list for the static data.
    ///
    /// - Parameter data: tile data.
    /// - Returns: tile list.
    private func cacheForTileData(_ data: SKTilesetData) -> TileList {
        guard let existingCache = staticTileCache[data] else {
            let newCache = TileList(queue: self.storageQueue)
            staticTileCache[data] = newCache
            return newCache
        }
        return existingCache
    }

    /// Return or create a tile list for the animated data.
    ///
    /// - Parameter data: tile data.
    /// - Returns: tile list.
    private func animatedCacheForTileData(_ data: SKTilesetData) -> TileList {
        guard let existingCache = animatedTileCache[data] else {
            let newCache = TileList(queue: self.storageQueue)
            animatedTileCache[data] = newCache
            return newCache
        }
        return existingCache
    }

    /// Move tile from one data list to another.
    ///
    /// - Parameters:
    ///   - tile: tile instance.
    ///   - globalID: tile global id.
    private func moveTileFrom(tile: SKTile, globalID: UInt32) {
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

    /// Move tile data from one cache to another.
    ///
    /// - Parameters:
    ///   - data: tile data removed.
    ///   - sourceCache: source cache.
    ///   - destCache: destination cache.
    /// - Returns: data was succesfully moved.
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

    /// Build animation frames for the data.
    ///
    /// - Parameter data: tile data.
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

    /// Manually sync all queues.
    func sync() {
        storageQueue.sync {}
        updateQueue.sync {}
    }

    /// Tilemap isolation mode updated.
    func isolateTilesAction() {

        for tile in allTiles {

            // true if mode is anything but 'none'
            var doHideTile = (cacheIsolationMode != .none)

            switch tile.renderMode {

                case .animated(gid: _):
                    doHideTile = (doHideTile == true) && (cacheIsolationMode != .animated)

                case .ignore:
                    doHideTile = (doHideTile == true) && (cacheIsolationMode != .ignored)

                case .static:
                    doHideTile = (doHideTile == true) && (cacheIsolationMode != .static)

                default:
                    doHideTile = (doHideTile == true) && (cacheIsolationMode != .default)
            }

            tile.isHidden = doHideTile
        }
    }
}


// MARK: - Extensions


extension CacheIsolationMode {
    static var all: [CacheIsolationMode] = [.default, .ignored, .static, .animated]
}


/// :nodoc:
extension MemorySize {

    /// Instantiate with a bytes value.
    ///
    /// - Parameter bytes: size in bytes.
    init(bytes bytesInt: Int) {
        self.bytes = Int64(bytesInt)
    }

    /// Size in kb.
    var kilobytes: Double {
        return Double(bytes) / 1_024
    }

    /// Size in kb.
    var megabytes: Double {
        return kilobytes / 1_024
    }

    /// Size in gb.
    var gigabytes: Double {
        return megabytes / 1_024
    }
}


/// :nodoc:
extension MemorySize: CustomStringConvertible {

    /// Provides a string representation of the memory size.
    var description: String {
        switch bytes {
            case 0..<1_024:
                return "\(bytes) bytes"
            case 1_024..<(1_024 * 1_024):
                return "\(String(format: "%.2f", kilobytes)) kb"
            case 1_024..<(1_024 * 1_024 * 1_024):
                return "\(String(format: "%.2f", megabytes)) mb"
            case (1_024 * 1_024 * 1_024)...Int64.max:
                return "\(String(format: "%.2f", gigabytes)) gb"
            default:
                return "\(bytes) bytes"
        }
    }
}


/// :nodoc:
extension TileDataStorage: CustomReflectable, TiledCustomReflectableType {

    /// Returns a custom mirror for this object.
    public var customMirror: Mirror {
        var staticDataCount = 0
        var animatedDataCount = 0
        var staticTileCount = 0
        var animatedTileCount = 0

        //var staticTileData:   [String: String] = [:]
        //var animatedTileData: [String: String] = [:]
        //var actionsTileData:  [String: String] = [:]

        for (_, sitem) in staticTileCache.enumerated() {
            let data = sitem.key
            staticTileCount += sitem.value.count
            staticDataCount += 1
        }

        for (_, aitem) in animatedTileCache.enumerated() {
            animatedTileCount += aitem.value.count
            animatedDataCount += 1
        }

        let staticData:   [String: Any] = ["data": staticDataCount, "tiles": staticTileCount]
        let animatedData: [String: Any] = ["data": animatedDataCount, "tiles": animatedTileCount]
        let actionData:   [String: Any] = ["data": animatedDataCount, "tiles": animatedTileCount]
        let objectData:   [String: Any] = ["id": "0"]

        return Mirror(self, children:
                        ["static": staticData,
                         "animated": animatedData,
                         "objects": objectData,
                         "actions": actionData],
                      displayStyle: .class
        )
    }

    public func dumpStatistics() {
        let headerString = " Tile Data Storage ".padEven(toLength: 40, withPad: "-")
        var output = "\n\(headerString)\n"

        output += "\n ▸ Size: \(sizeString) \n"


        /// Static tiles
        output += "\n ▾ Static Tiles:\n"
        for item in staticTileCache.enumerated() {
            let tileData = item.element.key
            let tileList = item.element.value.array
            let gidString = "\(tileData.globalID)".padRight(toLength: 4, withPad: " ")

            let tileDataHeader = "\n   ▸ gid: \(gidString) → (\(tileList.count) tiles)"
            output += tileDataHeader
        }

        /// Animated tiles
        output += "\n\n ▾ Animated Tiles:\n"
        for item in animatedTileCache.enumerated() {
            let tileData = item.element.key
            let tileList = item.element.value.array
            let gidString = "\(tileData.globalID)".padRight(toLength: 4, withPad: " ")
            let tileDataHeader = "\n   ▸ gid: \(gidString) → (\(tileList.count) tiles)"
            output += tileDataHeader
        }

        print(output)
        print("\n---------------------------------------\n")
        print(customMirror)
    }
}


/// :nodoc:
extension TileDataStorage: CustomStringConvertible, CustomDebugStringConvertible  {

    var description: String {
        let mapName = tilemap?.mapName ?? "null"
        let staticCount = staticTileCache.count
        let animatedCount = animatedTileCache.count
        return "Tile Data Storage: '\(mapName)' static: \(staticCount), animated: \(animatedCount)"
    }

    var debugDescription: String {
        return description
    }
}
