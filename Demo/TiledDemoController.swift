//
//  TiledDemoController.swift
//  SKTiled Demo
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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

import Foundation
import SpriteKit
#if os(iOS) || os(tvOS)
import UIKit
typealias Color = UIColor
typealias Font = UIFont
#else
import Cocoa
typealias Color = NSColor
typealias Font = NSFont
#endif


/// ## Overview
///
/// Class that manages file-based assets & preferences for the demo application. Also
public class TiledDemoController: NSObject, Loggable {

    /// Demo preferences, stored on disk.
    internal var defaultPreferences: DemoPreferences = DemoPreferences()

    /// Default singleton instance.
    static public var `default`: TiledDemoController {
        return tiledDemoControllerInstance
    }

    /// Logging verbosity.
    public var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    /// Dispatch queue for demo.
    private let demoQueue = DispatchQueue.global(qos: .userInteractive)

    // MARK: - File Management

    /// The app's resource path.
    private let resourceUrl: URL? = TiledGlobals.default.resourceUrl

    /// Array of paths to search for Tiled assets.
    private var assetSearchPaths: [URL] = []

    /// Stored asset urls.
    private var tiledResourceFiles: [TiledDemoAsset] = []

    /// The current tilemap url.
    internal var currentTilemapUrl: URL? {
        didSet {
            guard (oldValue != currentTilemapUrl) else { return }
            guard let newUrl = currentTilemapUrl else {
                NotificationCenter.default.post(
                    name: Notification.Name.DemoController.CurrentMapRemoved,
                    object: nil,
                    userInfo: nil
                )
                return
            }

            NotificationCenter.default.post(
                name: Notification.Name.DemoController.CurrentMapSet,
                object: nil,
                userInfo: ["url": newUrl]
            )
        }
    }


    /// The current view.
    public weak var view: SKView?

    /// Debug visualization options. This is default, and applied to the *first* tilemap loaded.
    public var debugDrawOptions: DebugDrawOptions = []

    /// The current tilemap.
    public weak var currentTilemap: SKTilemap?

    /// The currently loaded index.
    public internal(set) var currentTilemapIndex = -1

    /// indicates the index of the user maps.
    public internal(set) var userIndexStart = -1

    // MARK: - Init

    /// Initialize with the current view.
    ///
    /// - Parameter view: SpriteKit view.
    public init(view: SKView) {
        self.view = view
        super.init()
    }

    /// Default initializer.
    public override init() {

        print("◆ [TiledDemoController]: initializing demo controller...")

        super.init()

        // setup notifications...must do this before loading defaults
        setupNotifications()

        // set the bundle path as the root path
        guard let defaultSearchPath = resourceUrl else {
            fatalError("cannot access bundle's resource path.")
        }

        // set the bundle resource path as the first path
        assetSearchPaths = [defaultSearchPath]

        // load demo defaults from plist
        loadApplicationDefaults()

        // load user prefs from defaults
        loadStoredUserDefaults()

        // dump defaults
        SKTiledGlobals()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.AssetSearchPathsAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.AssetSearchPathsRemoved, object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.DefaultsRead, object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.ResetDemoInterface, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Debug.MapDebugDrawingChanged, object: nil)

        reset()
    }

    // MARK: - Setup

    /// Setup notification callbacks.
    func setupNotifications() {

        // asset search path events
        NotificationCenter.default.addObserver(self, selector: #selector(assetSearchPathsAdded), name: Notification.Name.DemoController.AssetSearchPathsAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(assetSearchPathsRemoved), name: Notification.Name.DemoController.AssetSearchPathsRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadFileManually), name: Notification.Name.DemoController.LoadFileManually, object: nil)

        // globals stuff
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(globalsReadAction), name: Notification.Name.Globals.DefaultsRead, object: nil)

        // assets
        NotificationCenter.default.addObserver(self, selector: #selector(resetMainInterface), name: Notification.Name.DemoController.ResetDemoInterface, object: nil)

        // debugging
        NotificationCenter.default.addObserver(self, selector: #selector(toggleMapObjectDrawing), name: Notification.Name.Debug.MapObjectVisibilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleMapDemoDrawGridAndBounds), name: Notification.Name.Debug.MapDebugDrawingChanged, object: nil)
    }

    func reset() {
        userIndexStart = -1
        tiledResourceFiles = []
        currentTilemapUrl = nil
        currentTilemap = nil
        //createEmptyScene()
    }

    // MARK: - Defaults


    /// Load default preferences from the `Defaults.plist` file.
    public func loadApplicationDefaults() {
        TiledGlobals.default.loadApplicationDefaults()
    }

    /// Load globals and search paths from user defaults.
    public func loadStoredUserDefaults() {
        log("loading user defaults.", level: .info)
        TiledGlobals.default.loadFromUserDefaults()

        // add asset search paths
        let defaults = UserDefaults.shared

        if let userSearchPaths = defaults.array(forKey: "TiledAssetSearchPaths") as? [String] {
            for assetSearchPath in userSearchPaths {
                let url = URL(fileURLWithPath: assetSearchPath)
                if (assetSearchPaths.contains(url) == false) {
                    assetSearchPaths.append(url)
                }
            }
        }
    }

    /// Save to the user defaults..
    public func saveToUserDefaults() {
        TiledGlobals.default.saveToUserDefaults()
    }

    /// Reset the demo application defaults.
    public func resetApplicationDefaults() {
        TiledGlobals.default.loadApplicationDefaults()
    }

    // MARK: - Scanning

    public func scanForResources() {

        // call back to the AppDelegate/GameViewController and clear the UIs.
        NotificationCenter.default.post(
            name: Notification.Name.DemoController.WillBeginScanForAssets,
            object: nil
        )
        
        print("⭑ current map url: '\(currentTilemapUrl?.relativePath ?? "nil")'")

        let canUseDemoMaps = TiledGlobals.default.allowDemoMaps
        let canUseUserMaps = TiledGlobals.default.allowUserMaps

        var validFileTypes: [String] = TiledGlobals.default.validFileTypes
        validFileTypes.append(contentsOf: TiledGlobals.default.validImageTypes)

        // reset the resource array
        tiledResourceFiles = []

        // get a list of demo file names we can use
        let demoFilenames = (canUseDemoMaps == true) ? defaultPreferences.demoFiles : []

        var scannedDemoAssets: [TiledDemoAsset] = []
        var tilemapUrls: [TiledDemoAsset] = []
        var alreadyAdded: [URL] = []


        for assetSearchPath in assetSearchPaths {

            // is this a user path?
            let isUserAssetPath = assetSearchPath != resourceUrl

            // skip if we aren't using user maps
            if (isUserAssetPath == true) && (canUseUserMaps == false) {

                // call back to the AppDelegate, creates the `File > Current maps` menu.
                NotificationCenter.default.post(
                    name: Notification.Name.DemoController.AssetsFinishedScanning,
                    object: nil
                )

                return
            }


            let scannedAssetUrls = self.scanPathForResources(url: assetSearchPath, types: ["tmx"])

            // filter out tilemaps...
            for assetUrl in scannedAssetUrls {

                let isDemoURL = (demoFilenames.contains(assetUrl.filename) || demoFilenames.contains(assetUrl.basename))
                let demoasset = TiledDemoAsset(assetUrl, isUser: !isDemoURL)

                scannedDemoAssets.append(demoasset)

                if (demoasset.isTilemap == true) {
                    tilemapUrls.append(demoasset)
                }
            }
        }

        // build the demo files list.
        for demoFilename in demoFilenames {

            var fileMatched = false

            for tilemapAsset in tilemapUrls {

                let url = tilemapAsset.url
                let tilemapName = url.lastPathComponent
                let tilemapBase = url.basename

                if (tilemapName == demoFilename) || (tilemapBase == demoFilename) {
                    tiledResourceFiles.append(tilemapAsset)
                    alreadyAdded.append(tilemapAsset.url)
                    fileMatched = true
                }
            }

            if (fileMatched == false) {
                self.log("expected demo file '\(demoFilename)' can't be found.", level: .warning)
            }
        }


        for asset in scannedDemoAssets {
            guard alreadyAdded.contains(asset.url) == false else {
                continue
            }

            tiledResourceFiles.append(asset)
        }

        userIndexStart = 0
        for tilemapAsset in tilemapUrls {
            if (tilemapAsset.isUserAsset == false) {
                userIndexStart += 1
            }
        }


        log("found \(tilemapUrls.count) tilemaps...", level: .debug)

        // call back to the AppDelegate, creates the `File > Current maps` menu.
        NotificationCenter.default.post(
            name: Notification.Name.DemoController.AssetsFinishedScanning,
            object: nil,
            userInfo: ["tilemapAssets": tilemapUrls]
        )
    }

    /// Scan the given url for assets.
    ///
    /// - Parameters:
    ///   - url: asset search path.
    ///   - types: valid file extensions.
    /// - Returns: file urls.
    internal func scanPathForResources(url: URL, types: [String]) -> [URL] {
        let resourcesFound = FileManager.default.listFiles(path: url.path, withExtensions: types)
        return resourcesFound
    }

    public func addTilemap(url: URL, at index: Int) {

        let newAsset = TiledDemoAsset(url, isUser: true)
        var actualIndex = 0
        var indexToInsert = 0
        for (idx, resource) in tiledResourceFiles.enumerated() {
            if (resource.isTilemap == true) {
                actualIndex += 1
            }

            if (actualIndex == index) {
                indexToInsert = idx
            }
        }
        tiledResourceFiles.insert(newAsset, at: indexToInsert)

    }

    // MARK: - Scene Management

    /// Clear the current scene.
    @objc public func createEmptyScene() {
        guard let view = view else {
            log("cannot access view.", level: .warning)
            return
        }


        // calls back to AppDelegate to clear the UI
        NotificationCenter.default.post(
            name: Notification.Name.Demo.SceneWillUnload,
            object: nil
        )


        // create an empty scene
        let nextScene = SKTiledDemoScene(size: view.bounds.size)
        nextScene.scaleMode = .aspectFill
        nextScene.demoController = self

        // create the transition
        let interval: TimeInterval = 0.5
        let transition = SKTransition.fade(withDuration: interval)
        view.presentScene(nextScene, transition: transition)


        // create an error label
        let errorLabel = SKLabelNode()

        #if os(macOS)
        let errorString = "please select a file to open"
        #else
        let errorString = ""
        #endif
        errorLabel.alpha = 0

        // create the font attributes
        let fontAttributes: [NSAttributedString.Key : Any] = [.font: Font.systemFont(ofSize: 24), .foregroundColor: Color.white]
        errorLabel.attributedText = NSAttributedString(string: errorString, attributes: fontAttributes)
        nextScene.worldNode.addChild(errorLabel)

        let fadeInAction = SKAction.fadeIn(withDuration: interval)
        let groupAction = SKAction.group(
            [
                fadeInAction,
                SKAction.wait(forDuration: 0.2),
                SKAction.scale(by: 1.2, duration: 0.5)
            ]
        )


        errorLabel.run(groupAction)

        // disasble the camera
        nextScene.cameraNode?.allowMovement = false
        nextScene.cameraNode?.allowZoom = false


        // calls back to AppDelegate
        NotificationCenter.default.post(
            name: Notification.Name.Demo.SceneLoaded,
            object: nextScene
        )
    }


    /// Clear the current scene.
    @objc public func flushScene() {
        guard let view = self.view else {
            log("view is not set.", level: .error)
            return
        }


        guard let demoScene = view.scene as? SKTiledDemoScene else {
            log("cannot access demo scene.", level: .error)
            return
        }

        // release tileap resources
        demoScene.camera = nil
        demoScene.cameraNode?.removeFromParent()
        demoScene.cameraNode = nil
        demoScene.tilemap?.removeAllActions()
        demoScene.tilemap?.removeAllChildren()
        demoScene.tilemap?.removeFromParent()
        demoScene.tilemap = nil
        demoScene.removeFromParent()



        currentTilemapIndex = 0
        currentTilemapUrl = nil

        demoScene.cameraNode?.setCameraZoom(1)

        // create and move to a new scene.
        createEmptyScene()
    }


    /// Reload the current scene.
    ///
    /// - Parameter interval: transition duration.
    @objc public func reloadScene(_ interval: TimeInterval = 0.3) {
        guard let currentURL = currentTilemapUrl else { return }
        loadScene(url: currentURL, usePreviousCamera: true, interval: interval, reload: true)
    }

    /// Load the next scene with the next tilemap.
    ///
    /// - Parameter interval: transition time.
    @objc public func loadNextScene(_ interval: TimeInterval = 0.3) {

        // if there's no current map, load the first in the stack
        if (currentTilemapUrl == nil) {
            if let demoUrl = tiledDemoUrls.first {
                currentTilemapUrl = demoUrl
                loadScene(url: demoUrl, usePreviousCamera: false, interval: interval, reload: false)
            } else {

                // create an empty scene
                NotificationCenter.default.post(
                    name: Notification.Name.Debug.DebuggingCommandSent,
                    object: nil,
                    userInfo: ["command": "cannot find any tiled assets.", "duration": 5]
                )

                // if there's nothing to load, just create an empty scene
                createEmptyScene()
            }
            return
        }


        guard (tiledDemoUrls.isEmpty == false) else {
            return
        }

        // figure out the file to load...
        var fileUrlToLoad = tiledDemoUrls.first!
        if let currentTilemapUrl = currentTilemapUrl {
            if let index = tiledDemoUrls.firstIndex(of: currentTilemapUrl), index + 1 < tiledDemoUrls.count {
                fileUrlToLoad = tiledDemoUrls[index + 1]
            }
        }
        loadScene(url: fileUrlToLoad, usePreviousCamera: defaultPreferences.usePreviousCamera, interval: interval, reload: false)
    }

    /// Load the previous tilemap scene.
    ///
    /// - Parameter interval: transition duration.
    @objc public func loadPreviousScene(_ interval: TimeInterval = 0.3) {
        guard let currentURL = currentTilemapUrl else {
            return
        }
        var nextFilename = tiledDemoUrls.last!
        if let index = tiledDemoUrls.firstIndex(of: currentURL), index > 0, index - 1 < tiledDemoUrls.count {
            nextFilename = tiledDemoUrls[index - 1]
        }
        loadScene(url: nextFilename, usePreviousCamera: defaultPreferences.usePreviousCamera, interval: interval, reload: false)
    }

    /// User has made a call to load a file manually. Called when the `Notification.Name.DemoController.LoadFileManually` event fires.
    /// - Parameter notification: event notification.
    @objc func loadFileManually(notification: Notification) {
        // TODO: implement this
    }

    // MARK: - Loading

    /// Loads a new demo scene with a named tilemap.
    ///
    /// - Parameters:
    ///   - url: tilemap file url
    ///   - usePreviousCamera: transfer camera information
    ///   - interval: transition duration.
    ///   - reload: current scene is reloaded.
    ///   - completion: optional completion handler.
    internal func loadScene(url: URL,
                            usePreviousCamera: Bool,
                            interval: TimeInterval = 0.3,
                            reload: Bool = false,
                            _ completion: (() -> Void)? = nil) {

        guard let view = self.view else {
            return
        }


        currentTilemap = nil

        NotificationCenter.default.post(
            name: Notification.Name.Demo.SceneWillUnload,
            object: nil,
            userInfo: ["url": url]
        )


        // loaded from preferences
        var showObjects: Bool = defaultPreferences.showObjects
        var enableEffects: Bool = defaultPreferences.enableEffects
        var shouldRasterize: Bool = false
        var tileUpdateMode: TileUpdateMode?


        if (tileUpdateMode == nil) {
            if let prefsUpdateMode = TileUpdateMode(rawValue: defaultPreferences.updateMode) {
                tileUpdateMode = prefsUpdateMode
            }
        }

        // grid visualization
        let drawGrid: Bool = defaultPreferences.drawGrid
        if (drawGrid == true) {
            debugDrawOptions.insert([.drawGrid, .drawFrame])
        }

        let drawSceneAnchor: Bool = defaultPreferences.drawAnchor
        if (drawSceneAnchor == true) {
            debugDrawOptions.insert(.drawAnchor)
        }

        var hasCurrent = false
        var showOverlay = true
        var cameraZoom: CGFloat = 1
        var isPaused: Bool = false

        var currentSpeed: CGFloat = 1
        var ignoreZoomClamping: Bool = false
        var notifyDelegatesOnContainedNodesChange: Bool = TiledGlobals.default.enableCameraContainedNodesCallbacks
        var zoomClamping: CameraZoomClamping = CameraZoomClamping.none
        var ignoreZoomConstraints: Bool = defaultPreferences.ignoreZoomConstraints

        var sceneInfo: [String: Any] = [:]


        // get current scene info
        if let currentScene = view.scene as? SKTiledDemoScene {
            hasCurrent = true
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                cameraZoom = cameraNode.zoom
                ignoreZoomClamping = cameraNode.ignoreZoomClamping
                notifyDelegatesOnContainedNodesChange = cameraNode.notifyDelegatesOnContainedNodesChange
                zoomClamping = cameraNode.zoomClamping
                ignoreZoomConstraints = cameraNode.ignoreZoomConstraints
            }

            // pass current values to next tilemap
            if let tilemap = currentScene.tilemap {
                tilemap.dataStorage?.blockNotifications = true
                debugDrawOptions = tilemap.debugDrawOptions
                currentTilemapUrl = url
                showObjects = tilemap.isShowingObjectBounds
                enableEffects = tilemap.shouldEnableEffects
                shouldRasterize = tilemap.shouldRasterize
                tileUpdateMode = tilemap.updateMode

                // remove tilemap
                tilemap.removeAllActions()
                tilemap.removeAllChildren()
                tilemap.dataStorage = nil
                tilemap.removeFromParent()
            }

            currentScene.tilemap = nil
            isPaused = currentScene.isPaused
            currentSpeed = currentScene.speed
            currentScene.demoController = nil

            // remove scene from memory
            currentScene.removeAllActions()
            currentScene.removeAllChildren()
            currentScene.removeFromParent()
            view.presentScene(nil)
        }

        // update the console
        let commandString = (reload == false) ? "loading map: '\(url.filename)'..." : "reloading map: '\(url.filename)'..."
        updateCommandString(commandString, duration: 3.0)



        // load the next scene on the main queue
        DispatchQueue.main.async { [unowned self] in

            let nextScene = SKTiledDemoScene(size: view.bounds.size)

            nextScene.scaleMode = .aspectFill
            nextScene.demoController = self
            nextScene.receiveCameraUpdates = TiledGlobals.default.enableCameraCallbacks


            // create the transition
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            nextScene.isPaused = isPaused

            // setup a new scene with the next tilemap filename
            nextScene.setup(tmxFile: url.relativePath,
                            inDirectory: (url.baseURL == nil) ? nil : url.baseURL!.path,
                            withTilesets: [],
                            ignoreProperties: false,
                            loggingLevel: self.loggingLevel) { tilemap in

                nextScene.cameraNode?.ignoreZoomClamping = ignoreZoomClamping
                nextScene.cameraNode?.notifyDelegatesOnContainedNodesChange = notifyDelegatesOnContainedNodesChange
                nextScene.cameraNode?.zoomClamping = zoomClamping
                nextScene.cameraNode?.ignoreZoomConstraints = ignoreZoomConstraints

                // previous camera settings
                if (usePreviousCamera == true) {
                    nextScene.cameraNode?.showOverlay = showOverlay
                    nextScene.cameraNode?.setCameraZoom(cameraZoom, interval: interval)
                }

                self.currentTilemap = tilemap

                // if tilemap has a property override to show objects, use it...else use demo prefs
                tilemap.isShowingObjectBounds = (tilemap.boolForKey("showObjects") == true) ? true : showObjects

                sceneInfo["hasGraphs"] = (nextScene.graphs.isEmpty == false)
                sceneInfo["hasObjects"] = nextScene.tilemap?.getObjects().isEmpty == false
                sceneInfo["focusedObjectData"] = ""


                if (hasCurrent == false) {
                    self.log("auto-resizing the view.", level: .debug)
                    nextScene.cameraNode?.fitToView(newSize: view.bounds.size)
                }

                // don't turn on effects for large tilemaps
                if (tilemap.pixelCount > SKTILED_MAX_TILEMAP_PIXEL_SIZE) {
                    enableEffects = false
                }

                tilemap.shouldEnableEffects = (tilemap.boolForKey("shouldEnableEffects") == true) ? true : enableEffects
                tilemap.shouldRasterize = shouldRasterize
                tilemap.updateMode = tileUpdateMode ?? TiledGlobals.default.updateMode


                self.demoQueue.async { [unowned self] in
                    for option in self.debugDrawOptions.elements() {
                        tilemap.debugDrawOptions.insert(option)
                    }
                }


                // set the previous scene's speed
                nextScene.speed = currentSpeed

                #if os(iOS)
                // for some reason properties label not updating properly
                NotificationCenter.default.post(
                    name: Notification.Name.Demo.UpdateDebugging,
                    object: tilemap,
                    userInfo: sceneInfo
                )
                #endif

                // setup the demo level scene
                nextScene.setupDemoLevel(fileNamed: url.relativePath, verbose: false)

                self.demoQueue.sync {

                    NotificationCenter.default.post(
                        name: Notification.Name.Map.Updated,
                        object: tilemap,
                        userInfo: nil
                    )

                    // calls back to AppDelegate
                    NotificationCenter.default.post(
                        name: Notification.Name.Demo.SceneLoaded,
                        object: nextScene,
                        userInfo: ["tilemapName": tilemap.mapName, "relativePath": url.relativePath]
                    )

                    NotificationCenter.default.post(
                        name: Notification.Name.Camera.Updated,
                        object: nextScene.cameraNode,
                        userInfo: nil
                    )
                }

            } // end of completion handler
        }

        // run completion
        completion?()
    }


    /// Dump the tilemap statistics to the console.
    public func dumpMapStatistics() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else {
            return
        }

        if let tilemap = scene.tilemap {
            updateCommandString("showing tilemap statistics...", duration: 3)
            tilemap.dumpStatistics()
        } else {
            log("no tilemap loaded.", level: .warning)
        }
    }
    
    /// Dump the tilemap cache statistics to the console.
    public func dumpMapCacheStatistics() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else {
            return
        }
        
        if let tilemap = scene.tilemap {
            if let cache = tilemap.dataStorage {
                updateCommandString("showing tilemap cache statistics...", duration: 3)
                cache.dumpStatistics()
            }

        } else {
            log("no tilemap loaded.", level: .warning)
        }
    }

    public func updateTileUpdateMode(value: UInt8) {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }


        let nextUpdateMode: TileUpdateMode = TileUpdateMode.init(rawValue: value) ?? TiledGlobals.default.updateMode.next()

        if (nextUpdateMode != TiledGlobals.default.updateMode) {
            TiledGlobals.default.updateMode = nextUpdateMode
            updateCommandString("tile update mode: \(nextUpdateMode.name)", duration: 1)
            if let tilemap = scene.tilemap {
                NotificationCenter.default.post(
                    name: Notification.Name.Map.Updated,
                    object: tilemap,
                    userInfo: nil
                )
            }
        }
    }


    // MARK: - Event Handlers

    /// Resets the main interface to its original state.
    @objc func resetMainInterface(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)
        reset()
        createEmptyScene()
    }

    /// Called when the user adds an asset search path. Called when the `Notification.Name.DemoController.AssetSearchPathsAdded` event fires.
    ///   userInfo: ["urls": `[URL]`] - urls to add to search paths.
    ///
    /// - Parameter notification: event notification.
    @objc public func assetSearchPathsAdded(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: [URL]],
              let searchPaths = userInfo["urls"] else { return }

        var searchPathsUpdated = false
        for searchPath in searchPaths {
            if (assetSearchPaths.contains(searchPath) == false) {
                assetSearchPaths.append(searchPath)
                searchPathsUpdated = true
            }
        }

        if (searchPathsUpdated == true) {
            saveToUserDefaults()
            scanForResources()
        }
    }

    /// Called when the user removes asset search paths. Called when the `Notification.Name.DemoController.AssetSearchPathsRemoved` event fires.
    ///
    ///   userInfo: ["urls": `[URL]`] - urls to remove from search paths.
    ///
    /// - Parameter notification: event notification.
    @objc public func assetSearchPathsRemoved(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: [URL]],
              let searchPathsToRemove = userInfo["urls"] else { return }


        // re-scan assets
        assetSearchPaths = searchPathsToRemove.filter({ assetSearchPaths.contains($0) == false })
        scanForResources()
        saveToUserDefaults()
    }

    /// Called when the `TiledGlobals` defaults are read from disk. Called when the `Notification.Name.Globals.DefaultsRead` event fires. Object is `DemoPreferences` instance.
    ///
    /// - Parameter notification: event notification.
    @objc public func globalsReadAction(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let demoPreferences = notification.object as? DemoPreferences else {
            fatalError("demo preferences not included.")
        }
        // set the current prefs
        self.defaultPreferences = demoPreferences
    }

    /// Called when the `TiledGlobals` are updated. Called when the `Notification.Name.Globals.Updated` event fires.
    ///
    ///   userInfo: ["tileColor": `SKColor`, "objectColor": `SKColor`]
    ///
    /// - Parameter notification: event notification.
    @objc public func globalsUpdatedAction(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)

        let globals = TiledGlobals.default
        globals.saveToUserDefaults()

        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }

        // stub here, we're not using..
        let searchPaths = userInfo["assetSearchPaths"]




        if (globals.allowUserMaps == true) || (globals.allowDemoMaps == true) {
            if (searchPaths != nil) {
                scanForResources()
            }
        }
    }
}



/// Singleton instance
let tiledDemoControllerInstance = TiledDemoController()



// MARK: - Extensions


extension TiledDemoController {

    /// Returns a reference to the current scene.
    public var scene: SKTiledScene? {
        guard let view = self.view,
              let tiledScene = view.scene as? SKTiledScene else {
            return nil
        }

        return tiledScene
    }

    /// Returns a reference to the current scene camera.
    public var camera: SKTiledSceneCamera? {
        return scene?.cameraNode
    }
}


/// :nodoc:
extension TiledDemoController: TiledCustomReflectableType {

    public func dumpStatistics() {
        var headerString = " Demo Controller ".padEven(toLength: 40, withPad: "-")
        headerString = "\n\(headerString)\n"

        var currentMapName = "nil"
        if let currentMap = currentTilemap {
            currentMapName = "'\(currentMap.mapName)'"
        }


        headerString += " ▸ User map index:               \(userIndexStart)\n"
        headerString += " ▸ Current map:                  \(currentMapName)\n"

        var currentUrlPath = "nil"

        if (currentTilemapUrl != nil) {
            currentUrlPath = "'\(currentTilemapUrl!.relativePath)'"
        }

        headerString += " ▸ Current map url:              \(currentUrlPath)\n\n"

        let resourcesCount = tiledResourceFiles.count
        let tilemapsCount  = tilemaps.count
        let tilesetsCount  = tilesets.count
        let templatesCount = templates.count
        let imagesCount    = images.count

        if resourcesCount > 0 {
            headerString += " ▸ Scanned assets:               \(resourcesCount)\n"

            if tilemapsCount > 0 {
                headerString += "   ∙ Tilemaps:                   \(tilemaps.count)\n"
            }

            if tilesetsCount > 0 {
                headerString += "   ∙ Tilesets:                   \(tilesets.count)\n"
            }

            if templatesCount > 0 {
                headerString += "   ∙ Templates:                  \(templates.count)\n"
            }
            if imagesCount > 0 {
                headerString += "   ∙ Images:                     \(images.count)\n"
            }

            headerString += "\n"
        }


        var userPathsString: String?
        if (assetSearchPaths.isEmpty == false) {
            var assetPathString = "\n ▸ Asset Search Paths:"
            for assetSearchPath in assetSearchPaths {

                let pathString = (assetSearchPath == TiledGlobals.default.resourceUrl) ? "<Bundle.main>" : assetSearchPath.path
                assetPathString += "\n   ∙ \(pathString)"
            }

            userPathsString = assetPathString
        }

        if let userPathsString = userPathsString {
            headerString += "\(userPathsString)\n"
        }


        print("\(headerString)\n\n")
    }
}


extension TiledDemoController {
    // MARK: - Demo Control

    /// Fit the current scene to the view.
    public func fitSceneToView() {
        guard let view = self.view else { return }
        guard let scene = view.scene as? SKTiledScene else { return }

        if let cameraNode = scene.cameraNode {
            updateCommandString("fitting to view...", duration: 4)
            cameraNode.fitToView(newSize: view.bounds.size, transition: 0.25)
        } else {
            updateCommandString("camera not found", duration: 4)
        }
    }

    /// Show/hide the map bounds.
    public func toggleMapDemoDrawBounds() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else {
            
            print("error accessing scene.")
            return
        }

        if let tilemap = scene.tilemap {
            updateCommandString("visualizing map bounds...", duration: 3)

            if (tilemap.debugDrawOptions.contains(.drawFrame)) {
                tilemap.debugDrawOptions = tilemap.debugDrawOptions.subtracting(.drawFrame)
            } else {
                tilemap.debugDrawOptions.insert(.drawFrame)
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        } else {
            print("error accessing tilemap.")
        }
    }

    /// Show/hide the map grid.
    public func toggleMapDemoDrawGrid() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            updateCommandString("visualizing map grid...", duration: 3)

            if (tilemap.debugDrawOptions.contains(.drawGrid)) {
                tilemap.debugDrawOptions = tilemap.debugDrawOptions.subtracting(.drawGrid)
            } else {
                tilemap.debugDrawOptions.insert(.drawGrid)
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }

    /// Show/hide the grid & map bounds. This is meant to be used with the interface buttons/keys to quickly turn grid & bounds drawing on. Called when the `Notification.Name.Demo.MapDebugDrawingChanged` notification is sent.
    @objc public func toggleMapDemoDrawGridAndBounds() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            updateCommandString("visualizing map grid & bounds...", duration: 3)

            let mapIsShowingTileGridAndBounds = tilemap.isShowingTileGridAndBounds
            tilemap.isShowingTileGridAndBounds = !mapIsShowingTileGridAndBounds


            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }

    /// Show/hide navigation graph visualizations.
    public func toggleMapGraphVisualization() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else {
            return
        }

        if let tilemap = scene.tilemap {

            //let mapIsShowingGraphs = tilemap.isShowingGridGraph

            var graphsCount = 0
            var graphsDrawn = 0

            for tileLayer in tilemap.tileLayers() where tileLayer.graph != nil {

                let layerIsShowingGraphs = tileLayer.isShowingGridGraph

                if (layerIsShowingGraphs == false) {
                    graphsDrawn += 1
                }

                tileLayer.isShowingGridGraph = !layerIsShowingGraphs
                graphsCount += 1
            }

            if (graphsCount > 0) && (graphsDrawn > 0) {
                updateCommandString("visualizing \(graphsCount) navigation graphs...", duration: 3)
            }


            // call back to the
            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }


    /// Show/hide current scene vector object debug visualization. Called when the `Notification.Name.Demo.MapObjectVisibilityChanged` notification is sent.
    @objc public func toggleMapObjectDrawing() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else {
            return
        }

        if let tilemap = scene.tilemap {
            let command = (tilemap.isShowingObjectBounds == true) ? "hiding all objects..." : "showing all objects..."
            updateCommandString(command, duration: 1)

            // toggle the existing value
            let doShowObjects = !tilemap.isShowingObjectBounds
            tilemap.isShowingObjectBounds = doShowObjects

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        } else {
            updateCommandString("error: cannot access tilemap.", duration: 1)
        }
    }

    /// Toggles the tilemap's effects rendering flag. Called when the `Notification.Name.Debug.MapEffectsRenderingChanged` notification is sent.
    @objc public func toggleTilemapEffectsRendering() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else {
            return
        }


        if let tilemap = scene.tilemap {
            let currentValue = tilemap.shouldEnableEffects
            tilemap.shouldEnableEffects.toggle()

            let effectsStatusString = (!currentValue == true) ? "on" : "off"

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )

            updateCommandString("effects rendering: \(effectsStatusString)...", duration: 3)
        }
    }

    @objc public func cycleTilemapUpdateMode() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene,
              let tilemap = scene.tilemap else { return }


        let currentValue = tilemap.updateMode
        let nextValue = currentValue.next()
        tilemap.updateMode = nextValue

        NotificationCenter.default.post(
            name: Notification.Name.Map.Updated,
            object: tilemap,
            userInfo: nil
        )

        NotificationCenter.default.post(
            name: Notification.Name.Map.UpdateModeChanged,
            object: tilemap,
            userInfo: nil
        )

        tilemap.postRenderStatistics(Date()) {
            self.updateCommandString("tile update mode: \(nextValue.name)", duration: 3.0)
        }
    }

    public func cycleTilemapUpdateMode(mode: String) {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }

        if let updateMode = UInt8(mode) {
            if let newUpdateMode = TileUpdateMode.init(rawValue: updateMode) {
                if let tilemap = scene.tilemap {
                    tilemap.updateMode = newUpdateMode
                    updateCommandString("setting update mode: \(newUpdateMode.name)", duration: 3)
                    NotificationCenter.default.post(
                        name: Notification.Name.Map.Updated,
                        object: tilemap,
                        userInfo: nil
                    )
                }
            }
        }
    }


    /// Toggle layer isolation.
    ///
    /// - Parameters:
    ///   - layerID: layer uuid.
    ///   - isVisible: isolated on/off.
    public func toggleLayerVisibility(layerID: String, visible isVisible: Bool) {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }


        if let tilemap = scene.tilemap {
            if let selectedLayer = tilemap.getLayer(withID: layerID) {
                let valueString = (isVisible == true) ? "on" : "off"
                updateCommandString("setting visibility \(valueString) for layer: '\(selectedLayer.layerName)'...", duration: 3)
                selectedLayer.isHidden = !isVisible
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }


    /// Toggle layer visibility.
    ///
    /// - Parameter isVisible: isolated on/off.
    public func toggleAllLayerVisibility(visible isVisible: Bool) {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }

        let actionName = (isVisible == true) ? "visible" : "hidden"
        updateCommandString("setting all layers \(actionName)...", duration: 3)

        if let tilemap = scene.tilemap {
            tilemap.layers.forEach { layer in
                layer.isHidden = !isVisible
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }

    /// Toggle layer isolation.
    ///
    /// - Parameters:
    ///   - layerID: layer uuid.
    ///   - isIsolated: isolated on/off.
    public func toggleLayerIsolated(layerID: String, isolated isIsolated: Bool) {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            if let selectedLayer = tilemap.getLayer(withID: layerID) {
                selectedLayer.isolateLayer(duration: 0.25)
                updateCommandString("isolating layer: '\(selectedLayer.layerName)'...", duration: 3)
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
        printLayerIsolatedInfo()
    }

    /// Disable all layer isolation.
    public func turnIsolationOff() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            updateCommandString("disabling layer isolation...", duration: 3)
            tilemap.getLayers().forEach { layer in
                if (layer.isolated == true) {
                    layer.isolateLayer(duration: 0.25)
                }
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
        printLayerIsolatedInfo()
    }

    /// Dump isloation info to the console.
    public func printLayerIsolatedInfo() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            updateCommandString("show isolated layers...", duration: 3)

            var headerString = "# Tilemap '\(tilemap.url.filename)', isolated:"
            let headerUnderline = String(repeating: "-", count: headerString.count )
            headerString = "\n\(headerString)\n\(headerUnderline)\n"

            tilemap.getLayers().forEach { layer in

                let isGroupNode: Bool = (layer as? SKGroupLayer != nil)
                let hasChildren: Bool = (layer.childLayers.isEmpty == false)

                let layerSymbol = (isGroupNode == true) ? (hasChildren == true) ? "▿" : "▹" : ""

                let parentCount = layer.parents.count - 1
                let padding = String(repeating: "  ", count: parentCount)
                let isolatedSymbol = layer.isolated.valueAsCheckbox
                headerString += "\n \(isolatedSymbol) \(padding) \(layerSymbol) '\(layer.layerName)'"
            }

            print("\(headerString)\n\n")
        }
    }

    public func toggleRenderStatsTimeFormat() {
        updateCommandString("setting update mode: ", duration: 3)

        NotificationCenter.default.post(
            name: Notification.Name.Map.Updated,
            object: nil,
            userInfo: nil
        )
    }

    // MARK: - Render Statistics

    public func updateRenderStatistics() {}

    // MARK: - Debug Output

    /// Send a command to the UI to update status.
    ///
    /// - Parameters:
    ///   - command: command string.
    ///   - duration: how long the message should be displayed (0 is indefinite).
    public func updateCommandString(_ command: String, duration: TimeInterval = 3.0) {
        NotificationCenter.default.post(
            name: Notification.Name.Debug.DebuggingCommandSent,
            object: nil,
            userInfo: ["command": command, "duration": duration]
        )
    }

    // MARK: - Debugging

    // this is received as a command from AppDelegate (main menu action)
    public func toggleRenderStatistics(value nextState: Bool) {
        updateCommandString("render statistics are \(nextState.valueAsOnOff)", duration: 2.0)
        NotificationCenter.default.post(
            name: Notification.Name.RenderStats.VisibilityChanged,
            object: nil,
            userInfo: ["showRenderStats": nextState]
        )
    }

    @objc public func toggleRenderStatistics() {
        let statsCurrentState = TiledGlobals.default.enableRenderCallbacks
        let statsNextState = !statsCurrentState

        #if DEBUG
        updateCommandString("render statistics are \(statsNextState.valueAsOnOff)", duration: 2.0)
        TiledGlobals.default.enableRenderCallbacks = statsNextState


        NotificationCenter.default.post(
            name: Notification.Name.RenderStats.VisibilityChanged,
            object: nil,
            userInfo: ["showRenderStats": statsNextState]
        )
        #endif
    }

    @objc public func dumpTileLayersDataAction() {
        guard let view = self.view,
              let scene = view.scene as? SKTiledScene,
              let tilemap = scene.tilemap else { return }

        tilemap.tileLayers().forEach { layer in
            layer.dumpLayerData()
        }
    }
}




extension TiledDemoController {

    // MARK: - Debugging

    /// Returns all of the tilemap urls.
    public var tilemaps: [TiledDemoAsset] {
        return tiledResourceFiles.filter { $0.isTilemap }
    }

    /// Returns all of the tilemap urls.
    public var tiledDemoUrls: [URL] {
        return tilemaps.map { $0.url }
    }

    /// Returns all of the tileste urls.
    public var tilesets: [TiledDemoAsset] {
        return tiledResourceFiles.filter { $0.isTileset }
    }

    /// Returns all of the template urls.
    public var templates: [TiledDemoAsset] {
        return tiledResourceFiles.filter { $0.isTemplate }
    }

    /// Returns all of the image asset urls.
    public var images: [TiledDemoAsset] {
        return tiledResourceFiles.filter { $0.isImageType }
    }

    /// Dump the current map list to the console.
    public func getCurrentlyLoadedTilemaps() {
        updateCommandString("showing registered maps...", duration: 3)

        let headerSymbol = "✎"
        let headerString = "\n\(headerSymbol) Tilemaps: \(tilemaps.count)"

        let titleUnderline = String(repeating: "-", count: headerString.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        if (tilemaps.isEmpty == false) {
            for (_, asset) in tilemaps.enumerated() {
                //let isDemoURL = (defaultPreferences.demoFiles.contains(asset.filename) || defaultPreferences.demoFiles.contains(asset.basename))
                //outputString += "\n - \(isDemoURL.checkedString) '\(asset.filename)'"
                let isDemoAsset = asset.isUserAsset == false
                outputString += "\n ∙ \(isDemoAsset.valueAsCheckbox) '\(asset.filename)'"
            }
        }

        print(outputString)
    }


    /// Dump the current asset list to the console. **
    public func getCurrentlyLoadedAssets() {
        updateCommandString("showing loaded assets...", duration: 3)

        let headerString = "# Currently loaded assets: \(self.tiledResourceFiles.count)"
        let titleUnderline = String(repeating: "-", count: headerString.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        let headerSymbol = "✎"

        if (tilemaps.isEmpty == false) {
            let mapHeaderString = "\n\(headerSymbol) Tilemaps: \(tilemaps.count)"
            let mapTitleUnderline = String(repeating: "-", count: mapHeaderString.count)
            outputString += "\n\(mapHeaderString)\n\(mapTitleUnderline)"

            for (_, map) in tilemaps.enumerated() {
                outputString += "\n ∙ \(map.isBundled.valueAsCheckbox) '\(map.filename)'"
            }
        }

        if (tilesets.isEmpty == false) {
            let tilesetHeaderString = "\n\(headerSymbol) Tilesets: \(tilesets.count)"
            let tilesetTitleUnderline = String(repeating: "-", count: tilesetHeaderString.count)
            outputString += "\n\(tilesetHeaderString)\n\(tilesetTitleUnderline)"
            for (_, tileset) in tilesets.enumerated() {
                //outputString += "\n - '\(tileset.filename)'"
                outputString += "\n ∙ \(tileset.isBundled.valueAsCheckbox) '\(tileset.filename)'"
            }
        }

        if (templates.isEmpty == false) {
            let templateHeaderString = "\n\(headerSymbol) Templates: \(templates.count)"
            let templateTitleUnderline = String(repeating: "-", count: templateHeaderString.count)
            outputString += "\n\(templateHeaderString)\n\(templateTitleUnderline)"

            for (_, template) in templates.enumerated() {
                //outputString += "\n - '\(template.filename)'"
                outputString += "\n ∙ \(template.isBundled.valueAsCheckbox) '\(template.filename)'"
            }
        }

        if (images.isEmpty == false) {
            let imageHeaderString = "\n\(headerSymbol) Images: \(images.count)"
            let imageTitleUnderline = String(repeating: "-", count: imageHeaderString.count)
            outputString += "\n\(imageHeaderString)\n\(imageTitleUnderline)"

            for (_, image) in images.enumerated() {
                //outputString += "\n - '\(filename.filename)'"
                outputString += "\n ∙ \(image.isBundled.valueAsCheckbox) '\(image.filename)'"
            }
        }

        print(outputString)
    }

    /// Dump the current **external** map list to the console.
    public func getExternallyLoadedAssets() {
        updateCommandString("showing external maps...", duration: 3)

        let externalMaps = self.tilemaps.filter({ $0.isBundled == false })
        let headerString = "# External Maps: \(externalMaps.count)"
        let titleUnderline = String(repeating: "-", count: headerString.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        for (_, url) in externalMaps.enumerated() {
            outputString += "\n ∙ '\(url.relativePath)'"
        }
        print("\(outputString)\n\n")
    }

}




extension FileManager {

    /// Returns an array of files in the given directory matching the given file extensions.
    ///
    /// - Parameters:
    ///   - path: search directory.
    ///   - withExtensions: file extensions to search for.
    func listFiles(path: String, withExtensions: [String] = []) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls: [URL] = []
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }

            let url = URL(fileURLWithPath: s, relativeTo: baseurl)
            let pathExtension = url.pathExtension.lowercased()

            if withExtensions.contains(pathExtension) || (withExtensions.isEmpty) {
                urls.append(url)
            }
        })
        return urls
    }
}




extension Array where Element == TiledDemoAsset {

    func contains(_ element: URL) -> Bool {
        return self.filter { $0.url == element }.isEmpty == false
    }
}


extension SKTilemap.RenderStatistics {


    /// Returns an attributed string with the current CPU usage percentage.
    public var processorAttributedString: NSAttributedString {
        let fontSize: CGFloat
        #if os(iOS)
        fontSize = 9
        #elseif os(tvOS)
        fontSize = 14
        #else
        fontSize = 12
        #endif

        let labelText = "CPU Usage: \(cpuPercentage)%"
        let labelStyle = NSMutableParagraphStyle()
        labelStyle.alignment = .left
        labelStyle.firstLineHeadIndent = 0

        let systemFont = Font(name: "Courier New", size: fontSize)!
        /*
         if #available(OSX 10.15, *) {
         systemFont = Font.monospacedSystemFont(ofSize: fontSize, weight: .regular)
         } else {
         systemFont = Font(name: "Courier New", size: fontSize)!
         }*/

        let fontColor: Color
        switch cpuPercentage {
            case 0...18:
                fontColor = Color(hexString: "#7ED321")
            case 19...30:
                fontColor = Color(hexString: "#FFFFFF")
            case 31...49:
                fontColor = Color(hexString: "#F8E71C")
            case 50...74:
                fontColor = Color(hexString: "#F5A623")
            default:
                fontColor = Color(hexString: "#FD4444")
        }

        let cpuStatsAttributes = [
            .font: systemFont,
            .foregroundColor: fontColor,
            .paragraphStyle: labelStyle
        ] as [NSAttributedString.Key: Any]

        return NSMutableAttributedString(string: labelText, attributes: cpuStatsAttributes)
    }
}




// MARK: - Outtakes

/*
/// Scan root directories and return any matching resource files.
private func scanForResourceTypes() {

    // call back to the AppDelegate, creates the `File > Current maps` menu.
    NotificationCenter.default.post(
        name: Notification.Name.Demo.DidBeginAssetScan,
        object: nil,
        userInfo: nil
    )

    var resourcesAdded = 0
    for root in assetSearchPaths {
        let urls = FileManager.default.listFiles(path: root.path, withExtensions: resourceTypes)
        for url in urls {
            guard tiledResourceFiles.contains(url) == false else {
                continue
            }

            tiledResourceFiles.append(url)
            resourcesAdded += 1
        }
    }

    /*
    /// Add resources from user search paths
    for userPath in userPaths {
        let urls = FileManager.default.listFiles(path: userPath.path, withExtensions: resourceTypes)
        for url in urls {
            guard resources.contains(url) == false else {
                continue
            }

            // add user maps to the end of the
            if (url.pathExtension == "tmx") {
                addTilemap(url: url, at: userIndexStart)
            }

            resources.append(url)
            resourcesAdded += 1
        }
    }*/


    let statusMsg = (resourcesAdded > 0) ? "\(resourcesAdded) resources added." : "no resources found."
    let statusLevel = (resourcesAdded > 0) ? LoggingLevel.info : LoggingLevel.warning
    log(statusMsg, level: statusLevel)

    // increment the internal scan counter.
    scanCount += 1

    // call back to the AppDelegate, creates the `File > Current maps` menu.
    NotificationCenter.default.post(
        name: Notification.Name.Demo.DemoAssetsLoaded,
        object: nil,
        userInfo: nil
    )
}
*/
