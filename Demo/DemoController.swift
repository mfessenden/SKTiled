//
//  DemoController.swift
//  SKTiled Demo
//
//  Created by Michael Fessenden on 8/4/17.
//  Copyright © 2017 Michael Fessenden. All rights reserved.
//

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


/// Controller & Asset manager for the demo app
public class DemoController: NSObject, Loggable {

    public var sceneCount: Int = 0
    private let fm = FileManager.default
    static let `default` = DemoController()

    var preferences: DemoPreferences!
    weak public var view: SKView?

    /// Logging verbosity.
    public var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    /// Debug visualization options.
    public var debugDrawOptions: DebugDrawOptions = []
    private let demoQueue = DispatchQueue.global(qos: .userInteractive)

    /// tiled resources
    public var demourls: [URL] = []
    public var currentURL: URL!
    private var roots: [URL] = []
    private var resources: [URL] = []
    public var resourceTypes: [String] = ["tmx", "tsx", "tx", "png"]

    /// convenience properties
    public var tilemaps: [URL] {
        return resources.filter { $0.pathExtension.lowercased() == "tmx" }
    }

    public var tilesets: [URL] {
        return resources.filter { $0.pathExtension.lowercased() == "tsx" }
    }

    public var templates: [URL] {
        return resources.filter { $0.pathExtension.lowercased() == "tx" }
    }

    public var images: [URL] {
        return resources.filter { ["png", "jpg", "gif"].contains($0.pathExtension.lowercased()) }
    }

    /// Returns the current demo file index.
    public var currentIndex: Int {
        guard let currentURL = currentURL else { return 0 }

        var currentMapIndex = demourls.count - 1
        if let mapIndex = demourls.index(of: currentURL) {
            currentMapIndex = Int(mapIndex) + 1
        }
        return currentMapIndex
    }


    // MARK: - Init
    override public init() {
        super.init()

        self.readPreferences()
        SKTiledGlobals()

        // scan for resources
        if let rpath = Bundle.main.resourceURL {
            self.addRoot(url: rpath)
        }

        if (self.tilemaps.isEmpty == false) && (self.preferences.demoFiles.isEmpty == false) {
            // stash user maps here
            var userMaps: [URL] = []
            // loop through the demo files in order to preserve order
            for demoFile in self.preferences.demoFiles {

                var fileMatched = false

                // add files included in the demo plist
                for tilemap in self.tilemaps {
                    let pathComponents = tilemap.relativePath.split(separator: "/")
                    if (pathComponents.count > 1) && (userMaps.contains(tilemap) == false) {
                        userMaps.append(tilemap)
                    }

                    // get the name of the file
                    let tilemapName = tilemap.lastPathComponent
                    let tilemapBase = tilemap.basename

                    if (demoFile == tilemapName) || (demoFile == tilemapBase) {
                        fileMatched = true
                        self.demourls.append(tilemap)
                    }
                }

                if (fileMatched == false) {
                    self.log("cannot find file: \"\(demoFile)\"", level: .error)
                }
            }

            // set the first url
            if let firstURL = self.demourls.first {
                self.currentURL = firstURL
            }

            // append user maps
            if (userMaps.isEmpty == false) && (self.preferences.allowUserMaps == true) {
                for userMap in userMaps {
                    guard self.demourls.contains(userMap) == false else {
                        continue
                    }

                    self.demourls.append(userMap)
                }
            }
        }

        self.setupNotifications()
    }



    public init(view: SKView) {
        self.view = view
        super.init()
    }

    // MARK: - Asset Management

    /**
     Add a new root path and scan.

     - parameter path: `String` resource root path.
     */
    public func addRoot(url: URL) {
        if !roots.contains(url) {
            roots.append(url)
            scanForResourceTypes()
        }
    }

    /**
     URL is relative.
     */
    public func addTilemap(url: URL, at index: Int) {
        demourls.insert(url, at: index)
        loadScene(url: url, usePreviousCamera: preferences.usePreviousCamera)
    }

    /**
     Scan root directories and return any matching resource files.
     */
    private func scanForResourceTypes() {
        var resourcesAdded = 0
        for root in roots {
            let urls = fm.listFiles(path: root.path, withExtensions: resourceTypes)

            for url in urls {
                guard resources.contains(url) == false else {
                    continue
                }

                resources.append(url)
                resourcesAdded += 1
            }
        }

        let statusMsg = (resourcesAdded > 0) ? "\(resourcesAdded) resources added." : "WARNING: no resources found."
        let statusLevel = (resourcesAdded > 0) ? LoggingLevel.info : LoggingLevel.warning
        log(statusMsg, level: statusLevel)
    }

    /**
     Read demo preferences from property list.
     */
    private func readPreferences() {
        let configurationURL = URL(fileURLWithPath: "Demo.plist", isDirectory: false, relativeTo: Bundle.main.resourceURL!)
        let decoder = PropertyListDecoder()

        if let configData = loadDataFrom(url: configurationURL) {
            if let demoPreferences = try? decoder.decode(DemoPreferences.self, from: configData) {
                preferences = demoPreferences
                self.log("demo preferences loaded.", level: .info)
                self.updateGlobalsWithPreferences()
            } else {
                self.log("preferences could not be loaded.", level: .fatal)
                abort()
            }
        }
    }

    // MARK: - Globals

    /**
     Update globals with demo prefs.
     */
    private func updateGlobalsWithPreferences() {
        self.log("updating globals...", level: .info)

        TiledGlobals.default.renderQuality.default = CGFloat(preferences.renderQuality)
        TiledGlobals.default.renderQuality.object = CGFloat(preferences.objectRenderQuality)
        TiledGlobals.default.renderQuality.text = CGFloat(preferences.textRenderQuality)
        TiledGlobals.default.enableRenderCallbacks = preferences.renderCallbacks
        TiledGlobals.default.enableCameraCallbacks = preferences.cameraCallbacks

        // Tile animation mode
        guard let demoAnimationMode = TileUpdateMode.init(rawValue: preferences.updateMode) else {
            log("invalid update mode: \(preferences.updateMode)", level: .error)
            return
        }

        TiledGlobals.default.updateMode = demoAnimationMode

        // Logging level
        guard let demoLoggingLevel = LoggingLevel.init(rawValue: preferences.loggingLevel) else {
            log("invalid logging level: \(preferences.loggingLevel)", level: .error)
            return
        }

        self.loggingLevel = demoLoggingLevel
        Logger.default.loggingLevel = demoLoggingLevel
        TiledGlobals.default.loggingLevel = demoLoggingLevel
        TiledGlobals.default.debug.mouseFilters = TiledGlobals.DebugDisplayOptions.MouseFilters.init(rawValue: preferences.mouseFilters)
    }

    /**
     Setup notification callbacks.
     */
    func setupNotifications() {
        //set up notification for scene to load the next file
        NotificationCenter.default.addObserver(self, selector: #selector(reloadScene), name: Notification.Name.Demo.ReloadScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: Notification.Name.Demo.LoadNextScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadPreviousScene), name: Notification.Name.Demo.LoadPreviousScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleMapDemoDrawGridAndBounds), name: Notification.Name.Debug.MapDebuggingChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleTilemapEffectsRendering), name: Notification.Name.Debug.MapEffectsRenderingChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleMapObjectDrawing), name: Notification.Name.Debug.MapObjectVisibilityChanged, object: nil)

    }

    // MARK: - Helpers

    /**
     Load data from a URL.
     */
    func loadDataFrom(url: URL) -> Data? {
        #if os(macOS)
        if let xmlString = try? String(contentsOf: url, encoding: .utf8) {
            let xmlData = xmlString.data(using: .utf8)!
            self.log("reading: \"\(url.relativePath)\"...", level: .debug)
            return xmlData
        }
        #else
        if let xmlData = try? Data(contentsOf: url) {
            self.log("reading: \"\(url.relativePath)\"...", level: .debug)
            return xmlData
        }
        #endif
        return nil
    }

    // MARK: - Scene Management

    /**
     Clear the current scene.
     */
    @objc public func flushScene() {
        guard let view = self.view else {
            log("view is not set.", level: .error)
            return
        }

        view.presentScene(nil)
        let nextScene = SKTiledDemoScene(size: view.bounds.size)
        view.presentScene(nextScene)
    }

    /**
     Reload the current scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    @objc public func reloadScene(_ interval: TimeInterval = 0.3) {
        guard let currentURL = currentURL else { return }
        loadScene(url: currentURL, usePreviousCamera: preferences.usePreviousCamera, interval: interval, reload: true)
    }

    /**
     Load the next tilemap scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    @objc public func loadNextScene(_ interval: TimeInterval = 0.3) {
        guard let currentURL = currentURL else {
            log("current url does not exist.", level: .error)
            return
        }


        var nextFilename = demourls.first!
        if let index = demourls.index(of: currentURL), index + 1 < demourls.count {
            nextFilename = demourls[index + 1]
        }
        loadScene(url: nextFilename, usePreviousCamera: preferences.usePreviousCamera, interval: interval, reload: false)
    }

    /**
     Load the previous tilemap scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    @objc public func loadPreviousScene(_ interval: TimeInterval = 0.3) {
        guard let currentURL = currentURL else { return }
        var nextFilename = demourls.last!
        if let index = demourls.index(of: currentURL), index > 0, index - 1 < demourls.count {
            nextFilename = demourls[index - 1]
        }
        loadScene(url: nextFilename, usePreviousCamera: preferences.usePreviousCamera, interval: interval, reload: false)
    }

    // MARK: - Loading

    /**
     Loads a new demo scene with a named tilemap.

     - parameter url:               `URL` tilemap file url.
     - parameter usePreviousCamera: `Bool` transfer camera information.
     - parameter interval:          `TimeInterval` transition duration.
     */
    internal func loadScene(url: URL, usePreviousCamera: Bool, interval: TimeInterval = 0.3, reload: Bool = false, _ completion: (() -> Void)? = nil) {
        guard let view = self.view,
            let preferences = self.preferences else {
            return
        }

        // loaded from preferences
        var showObjects: Bool = preferences.showObjects
        var enableEffects: Bool = preferences.enableEffects
        var shouldRasterize: Bool = false
        var tileUpdateMode: TileUpdateMode?


        if (tileUpdateMode == nil) {
            if let prefsUpdateMode = TileUpdateMode(rawValue: preferences.updateMode) {
                tileUpdateMode = prefsUpdateMode
            }
        }

        // grid visualization
        let drawGrid: Bool = preferences.drawGrid
        if (drawGrid == true) {
            debugDrawOptions.insert([.drawGrid, .drawBounds])
        }

        let drawSceneAnchor: Bool = preferences.drawAnchor
        if (drawSceneAnchor == true) {
            debugDrawOptions.insert(.drawAnchor)
        }

        var hasCurrent = false
        var showOverlay = true
        var cameraPosition = CGPoint.zero
        var cameraZoom: CGFloat = 1
        var isPaused: Bool = false

        var currentSpeed: CGFloat = 1
        var ignoreZoomClamping: Bool = false
        var zoomClamping: CameraZoomClamping = CameraZoomClamping.none
        var ignoreZoomConstraints: Bool = preferences.ignoreZoomConstraints

        var sceneInfo: [String: Any] = [:]


        // get current scene info
        if let currentScene = view.scene as? SKTiledDemoScene {
            hasCurrent = true
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                cameraPosition = cameraNode.position
                cameraZoom = cameraNode.zoom
                ignoreZoomClamping = cameraNode.ignoreZoomClamping
                zoomClamping = cameraNode.zoomClamping
                ignoreZoomConstraints = cameraNode.ignoreZoomConstraints
            }

            // pass current values to next tilemap
            if let tilemap = currentScene.tilemap {
                tilemap.dataStorage?.blockNotifications = true
                debugDrawOptions = tilemap.debugDrawOptions
                currentURL = url
                showObjects = tilemap.showObjects
                enableEffects = tilemap.shouldEnableEffects
                shouldRasterize = tilemap.shouldRasterize
                tileUpdateMode = tilemap.updateMode
            }

            isPaused = currentScene.isPaused
            currentSpeed = currentScene.speed
            currentScene.demoController = nil
        }

        // update the console
        let commandString = (reload == false) ? "loading map: \"\(url.filename)\"..." : "reloading map: \"\(url.filename)\"..."
        updateCommandString(commandString, duration: 3.0)


        // load the next scene on the main queue
        DispatchQueue.main.async { [unowned self] in

            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            nextScene.demoController = self
            nextScene.receiveCameraUpdates = TiledGlobals.default.enableCameraCallbacks

            // flushing old scene from memory
            view.presentScene(nil)

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

                            // completion handler
                            if (usePreviousCamera == true) {
                                nextScene.cameraNode?.showOverlay = showOverlay
                                nextScene.cameraNode?.position = cameraPosition
                                nextScene.cameraNode?.setCameraZoom(cameraZoom, interval: interval)
                            }

                            nextScene.cameraNode?.ignoreZoomClamping = ignoreZoomClamping
                            nextScene.cameraNode?.zoomClamping = zoomClamping
                            nextScene.cameraNode?.ignoreZoomConstraints = ignoreZoomConstraints

                            // if tilemap has a property override to show objects, use it...else use demo prefs
                            tilemap.showObjects = (tilemap.boolForKey("showObjects") == true) ? true : showObjects

                            sceneInfo["hasGraphs"] = (nextScene.graphs.isEmpty == false)
                            sceneInfo["hasObjects"] = nextScene.tilemap.getObjects().isEmpty == false
                            sceneInfo["propertiesInfo"] = "--"


                            if (hasCurrent == false) {
                                self.log("auto-resizing the view.", level: .debug)
                                nextScene.cameraNode.fitToView(newSize: view.bounds.size)
                            }

                            // add caching here
                            tilemap.shouldEnableEffects = (tilemap.boolForKey("shouldEnableEffects") == true) ? true : enableEffects
                            tilemap.shouldRasterize = shouldRasterize
                            tilemap.updateMode = tileUpdateMode ?? TiledGlobals.default.updateMode


                            self.demoQueue.async { [unowned self] in
                                tilemap.debugDrawOptions = self.debugDrawOptions
                            }

                            self.sceneCount += 1
                                
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
                            nextScene.setupDemoLevel(fileNamed: url.relativePath)

                            self.demoQueue.sync {

                                NotificationCenter.default.post(
                                    name: Notification.Name.Map.Updated,
                                    object: tilemap,
                                    userInfo: nil
                                )

                                NotificationCenter.default.post(
                                    name: Notification.Name.Demo.SceneLoaded,
                                    object: nextScene,
                                    userInfo: nil
                                )

                                NotificationCenter.default.post(
                                    name: Notification.Name.Camera.Updated,
                                    object: nextScene.cameraNode,
                                    userInfo: nil
                                )
                            }

            } // end of completion handler
        }
    }

    // MARK: - Demo Control

    /**
     Fit the current scene to the view.
     */
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

    /**
     Show/hide the map bounds.
     */
    public func toggleMapDemoDrawBounds() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            updateCommandString("visualizing map bounds...", duration: 3)
            
            if (tilemap.debugDrawOptions.contains(.drawBounds)) {
                tilemap.debugDrawOptions = tilemap.debugDrawOptions.subtracting(.drawBounds)
            } else {
                tilemap.debugDrawOptions.insert(.drawBounds)
            }
            
            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }

    /**
     Show/hide the map grid.
     */
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

    /**
     Show/hide navigation graph visualizations.
     */
    public func toggleMapGraphVisualization() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {

            var graphsCount = 0
            var graphsDrawn = 0

            for tileLayer in tilemap.tileLayers() where tileLayer.graph != nil {

                if (tileLayer.debugDrawOptions.contains(.drawGraph) == false) {
                    graphsDrawn += 1
                }
                
                if (tileLayer.debugDrawOptions.contains(.drawGraph)) {
                    tileLayer.debugDrawOptions = tileLayer.debugDrawOptions.subtracting([.drawGraph])
                } else {
                    tileLayer.debugDrawOptions.insert([.drawGraph])
                }

                graphsCount += 1
            }

            if (graphsCount > 0) && (graphsDrawn > 0) {
                updateCommandString("visualizing \(graphsCount) navigation graphs...", duration: 3)
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }

    /**
     Show/hide the grid & map bounds. This is meant to be used with the interface buttons/keys to quickly turn grid & bounds drawing on.
     */
    @objc public func toggleMapDemoDrawGridAndBounds() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            updateCommandString("visualizing map grid & bounds...", duration: 3)
            
            if (tilemap.debugDrawOptions.contains(.drawGrid) || tilemap.debugDrawOptions.contains(.drawBounds) ) {
                tilemap.debugDrawOptions = tilemap.debugDrawOptions.subtracting([.drawGrid, .drawBounds])
            } else {
                tilemap.debugDrawOptions.insert([.drawGrid, .drawBounds])
            }
            
            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }

    /**
     Show/hide current scene objects.
     */
    @objc public func toggleMapObjectDrawing() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            let command = (tilemap.showObjects == true) ? "hiding all objects..." : "showing all objects..."
            updateCommandString(command, duration: 0.75)
            let doShowObjects = !tilemap.showObjects
            tilemap.showObjects = doShowObjects

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }

    /**
     Show/hide current scene objects.
     */
    @objc public func toggleObjectBoundaryDrawing() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {

            let currentObjectBoundsMode = tilemap.debugDrawOptions.contains(.drawObjectBounds)
            let command = (currentObjectBoundsMode == true) ? "hiding object boundaries..." : "hiding object boundaries..."
            updateCommandString(command, duration: 0.75)

            if (currentObjectBoundsMode == false) {
                tilemap.debugDrawOptions.insert(.drawObjectBounds)
            } else {
                tilemap.debugDrawOptions.remove(.drawObjectBounds)
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }


    // Debug.MapEffectsRenderingChanged
    @objc public func toggleTilemapEffectsRendering() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }


        if let tilemap = scene.tilemap {

            let effectsMode = tilemap.shouldEnableEffects
            tilemap.shouldEnableEffects = !effectsMode
            let effectsStatusString = (effectsMode == true) ? "off" : "on"

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

    @objc public func toggleRenderStatistics() {
        let statsCurrentState = TiledGlobals.default.enableRenderCallbacks
        let statsNextState = !statsCurrentState
        
        updateCommandString("displaying render stats: \(statsNextState)", duration: 2.0)
        TiledGlobals.default.enableRenderCallbacks = statsNextState

        //renderStatisticsMenuItem.state = (TiledGlobals.default.enableRenderCallbacks == true) ? .on : .off
        NotificationCenter.default.post(
            name: Notification.Name.RenderStats.VisibilityChanged,
            object: nil,
            userInfo: ["showRenderStats": statsNextState]
        )
    }

    // MARK: - Debugging Output

    /**
     Dump the current map list to the console.
     */
    public func getCurrentlyLoadedTilemaps() {
        updateCommandString("showing registered maps...", duration: 3)

        let headerString = "# Currently loaded files: \(self.demourls.count)"
        let titleUnderline = String(repeating: "-", count: headerString.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        for (fileIndex, filename) in self.demourls.enumerated() {
            let symbol = (fileIndex == (currentIndex - 1)) ? "[x]" : "[ ]"
            outputString += "\n\(symbol)  \"\(filename.filename)\""
        }
        print(outputString)
    }

    /**
     Dump the current external map list to the console.
     */
    public func getExternallyLoadedAssets() {
        updateCommandString("showing external maps...", duration: 3)

        let externalMaps = self.tilemaps.filter({ $0.isBundled == false })
        let headerString = "# External Maps: \(externalMaps.count)"
        let titleUnderline = String(repeating: "-", count: headerString.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        for (_, url) in externalMaps.enumerated() {
            outputString += "\n - \"\(url.relativePath)\""
        }
        print("\(outputString)\n\n")
    }

    /**
     Dump the current asset list to the console.
     */
    public func getCurrentlyLoadedAssets() {
        updateCommandString("showing loaded assets...", duration: 3)

        let headerString = "# Currently loaded assets: \(self.resources.count)"
        let titleUnderline = String(repeating: "-", count: headerString.count)
        var outputString = "\n\(headerString)\n\(titleUnderline)"

        let headerSymbol = "✎"

        if !tilemaps.isEmpty {
            let mapHeaderString = "\n\(headerSymbol) Tilemaps: \(tilemaps.count)"
            let mapTitleUnderline = String(repeating: "-", count: mapHeaderString.count)
            outputString += "\n\(mapHeaderString)\n\(mapTitleUnderline)"
            for (_, url) in tilemaps.enumerated() {
                let isDemoURL = (preferences.demoFiles.contains(url.filename) || preferences.demoFiles.contains(url.basename))
                let symbol = (isDemoURL == true) ? "[x]" : "[ ]"
                outputString += "\n - \(symbol) \"\(url.filename)\""
            }
        }

        if !tilesets.isEmpty {
            let tilesetHeaderString = "\n\(headerSymbol) Tilesets: \(tilesets.count)"
            let tilesetTitleUnderline = String(repeating: "-", count: tilesetHeaderString.count)
            outputString += "\n\(tilesetHeaderString)\n\(tilesetTitleUnderline)"
            for (_, filename) in tilesets.enumerated() {
                outputString += "\n - \"\(filename.filename)\""
            }
        }

        if !templates.isEmpty {
            let templateHeaderString = "\n\(headerSymbol) Templates: \(templates.count)"
            let templateTitleUnderline = String(repeating: "-", count: templateHeaderString.count)
            outputString += "\n\(templateHeaderString)\n\(templateTitleUnderline)"
            for (_, filename) in templates.enumerated() {
                outputString += "\n - \"\(filename.filename)\""
            }
        }

        if !images.isEmpty {
            let imageHeaderString = "\n\(headerSymbol) Images: \(images.count)"
            let imageTitleUnderline = String(repeating: "-", count: imageHeaderString.count)
            outputString += "\n\(imageHeaderString)\n\(imageTitleUnderline)"
            for (_, filename) in images.enumerated() {
                outputString += "\n - \"\(filename.filename)\""
            }
        }

        print(outputString)
    }

    /**
     Dump the map statistics to the console.
     */
    public func dumpMapStatistics() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            updateCommandString("showing map statistics...", duration: 3)
            tilemap.dumpStatistics()
        }
    }


    public func updateTileUpdateMode(value: Int = -1) {
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

    // MARK: - Layer Isolation/Visibility
    /**
     Toggle layer isolation.

     - parameter layerID:  `String` layer uuid.
     - parameter isolated: `Bool` isolated on/off.
     */
    public func toggleLayerVisibility(layerID: String, visible isVisible: Bool) {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }


        if let tilemap = scene.tilemap {
            if let selectedLayer = tilemap.getLayer(withID: layerID) {
                let valueString = (isVisible == true) ? "on" : "off"
                updateCommandString("setting visibility \(valueString) for layer: \"\(selectedLayer.layerName)\"...", duration: 3)
                selectedLayer.isHidden = !isVisible
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }

    /**
     Toggle layer visibility.

     - parameter layerID:  `String` layer uuid.
     - parameter isolated: `Bool` isolated on/off.
     */
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

    /**
     Toggle layer isolation.

     - parameter layerID:  `String` layer uuid.
     - parameter isolated: `Bool` isolated on/off.
     */
    public func toggleLayerIsolated(layerID: String, isolated isIsolated: Bool) {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            if let selectedLayer = tilemap.getLayer(withID: layerID) {
                selectedLayer.isolateLayer(duration: 0.25)
                updateCommandString("isolating layer: \"\(selectedLayer.layerName)\"...", duration: 3)
            }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
        printLayerIsolatedInfo()
    }

    /**
     Disable all layer isolation.
     */
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

    public func printLayerIsolatedInfo() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            updateCommandString("show isolated layers...", duration: 3)

            var headerString = "# Tilemap \"\(tilemap.url.filename)\", isolated:"
            let headerUnderline = String(repeating: "-", count: headerString.count )
            headerString = "\n\(headerString)\n\(headerUnderline)\n"

            tilemap.getLayers().forEach { layer in

                let isGroupNode: Bool = (layer as? SKGroupLayer != nil)
                let hasChildren: Bool = (layer.childLayers.isEmpty == false)

                let layerSymbol = (isGroupNode == true) ? (hasChildren == true) ? "▿" : "▹" : ""

                let parentCount = layer.parents.count - 1
                let padding = String(repeating: "  ", count: parentCount)
                let isolatedSymbol = (layer.isolated == true) ? "[x]" : "[ ]"
                headerString += "\n \(isolatedSymbol) \(padding) \(layerSymbol) \"\(layer.layerName)\""
            }

            print("\(headerString)\n\n")
        }
    }

    public func cycleTilemapUpdateMode(mode: String) {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let updateMode = Int(mode) {
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

    /**
     Send a command to the UI to update status.

     - parameter command:  `String` command string.
     - parameter duration: `TimeInterval` how long the message should be displayed (0 is indefinite).
     */
    public func updateCommandString(_ command: String, duration: TimeInterval = 3.0) {
        NotificationCenter.default.post(
            name: Notification.Name.Debug.CommandIssued,
            object: nil,
            userInfo: ["command": command, "duration": duration]
        )
    }

    // MARK: - Debugging

    // this is received as a command from AppDelegate (main menu action)
    public func toggleRenderStatistics(value nextState: Bool) {
        updateCommandString("displaying render stats: \(nextState)", duration: 2.0)

        NotificationCenter.default.post(
            name: Notification.Name.RenderStats.VisibilityChanged,
            object: nil,
            userInfo: ["showRenderStats": nextState]
        )
    }
}


/// Class to manage preferences loaded from a property list.
class DemoPreferences: Codable {

    var renderQuality: Double = 0
    var objectRenderQuality: Double = 0
    var textRenderQuality: Double = 0
    var maxRenderQuality: Double = 0

    var showObjects: Bool = false
    var drawGrid: Bool = false
    var drawAnchor: Bool = false
    var enableEffects: Bool = false
    var updateMode: Int = 0
    var allowUserMaps: Bool = true
    var loggingLevel: Int = 0
    var renderCallbacks: Bool = true
    var cameraCallbacks: Bool = true
    var mouseFilters: Int = 0
    var ignoreZoomConstraints: Bool = false
    var usePreviousCamera: Bool = false
    var demoFiles: [String] = []

    enum ConfigKeys: String, CodingKey {
        case renderQuality
        case objectRenderQuality
        case textRenderQuality
        case maxRenderQuality
        case showObjects
        case drawGrid
        case drawAnchor
        case enableEffects
        case updateMode
        case allowUserMaps
        case loggingLevel
        case renderCallbacks
        case cameraCallbacks
        case mouseFilters
        case ignoreZoomConstraints
        case usePreviousCamera
        case demoFiles
    }

    required init?(coder aDecoder: NSCoder) {}

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: ConfigKeys.self)
        renderQuality = try values.decode(Double.self, forKey: .renderQuality)
        objectRenderQuality = try values.decode(Double.self, forKey: .objectRenderQuality)
        textRenderQuality = try values.decode(Double.self, forKey: .textRenderQuality)
        maxRenderQuality = try values.decode(Double.self, forKey: .maxRenderQuality)
        showObjects = try values.decode(Bool.self, forKey: .showObjects)
        drawGrid = try values.decode(Bool.self, forKey: .drawGrid)
        drawAnchor = try values.decode(Bool.self, forKey: .drawAnchor)
        enableEffects = try values.decode(Bool.self, forKey: .enableEffects)
        updateMode = try values.decode(Int.self, forKey: .updateMode)
        allowUserMaps = try values.decode(Bool.self, forKey: .allowUserMaps)
        loggingLevel = try values.decode(Int.self, forKey: .loggingLevel)
        renderCallbacks = try values.decode(Bool.self, forKey: .renderCallbacks)
        cameraCallbacks = try values.decode(Bool.self, forKey: .cameraCallbacks)
        mouseFilters = try values.decode(Int.self, forKey: .mouseFilters)
        ignoreZoomConstraints = try values.decode(Bool.self, forKey: .ignoreZoomConstraints)
        usePreviousCamera = try values.decode(Bool.self, forKey: .usePreviousCamera)
        demoFiles = try values.decode(Array.self, forKey: .demoFiles)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ConfigKeys.self)
        try container.encode(renderQuality, forKey: .renderQuality)
        try container.encode(objectRenderQuality, forKey: .objectRenderQuality)
        try container.encode(textRenderQuality, forKey: .textRenderQuality)
        try container.encode(maxRenderQuality, forKey: .maxRenderQuality)
        try container.encode(showObjects, forKey: .showObjects)
        try container.encode(drawGrid, forKey: .drawGrid)
        try container.encode(drawAnchor, forKey: .drawAnchor)
        try container.encode(enableEffects, forKey: .enableEffects)
        try container.encode(updateMode, forKey: .updateMode)
        try container.encode(allowUserMaps, forKey: .allowUserMaps)
        try container.encode(loggingLevel, forKey: .loggingLevel)
        try container.encode(renderCallbacks, forKey: .renderCallbacks)
        try container.encode(cameraCallbacks, forKey: .cameraCallbacks)
        try container.encode(mouseFilters, forKey: .mouseFilters)
        try container.encode(ignoreZoomConstraints, forKey: .ignoreZoomConstraints)
        try container.encode(usePreviousCamera, forKey: .usePreviousCamera)
        try container.encode(demoFiles, forKey: .demoFiles)
    }
}



extension DemoPreferences: CustomDebugReflectable {

    func dumpStatistics() {
        let spacing = "     "
        var headerString = "\(spacing)Demo Preferences\(spacing)"
        let headerUnderline = String(repeating: "-", count: headerString.count )

        var animModeString = "**invalid**"
        if let demoAnimationMode = TileUpdateMode.init(rawValue: updateMode) {
            animModeString = demoAnimationMode.name
        }

        //var mouseFilterStrings = mouseFilters

        var loggingLevelString = "**invalid**"
        if let demoLoggingLevel = LoggingLevel.init(rawValue: loggingLevel) {
            loggingLevelString = demoLoggingLevel.description
        }

        headerString = "\n\(headerString)\n\(headerUnderline)\n"
        headerString += " - render quality:              \(renderQuality)\n"
        headerString += " - object quality:              \(objectRenderQuality)\n"
        headerString += " - text quality:                \(textRenderQuality)\n"
        headerString += " - max render quality:          \(maxRenderQuality)\n"
        headerString += " - show objects:                \(showObjects)\n"
        headerString += " - draw grid:                   \(drawGrid)\n"
        headerString += " - draw anchor:                 \(drawAnchor)\n"
        headerString += " - effects rendering:           \(enableEffects)\n"
        headerString += " - update mode:                 \(updateMode)\n"
        headerString += " - animation mode:              \(animModeString)\n"
        headerString += " - allow user maps:             \(allowUserMaps)\n"
        headerString += " - logging level:               \(loggingLevelString)\n"
        headerString += " - render callbacks:            \(renderCallbacks)\n"
        headerString += " - camera callbacks:            \(cameraCallbacks)\n"
        headerString += " - ignore camera contstraints:  \(ignoreZoomConstraints)\n"
        headerString += " - user previous camera:        \(usePreviousCamera)\n"
        headerString += " - mouse filters:\n"

        print("\(headerString)\n\n")
    }
}




extension FileManager {

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


extension TileUpdateMode {

    /// Control string to be used with the render stats menu.
    public var uiControlString: String {
        switch self {
        case .dynamic: return "Cached"
        case .full: return "Full"
        case .actions: return "SpriteKit Actions"
        }
    }
}



extension SKTilemap.RenderStatistics {

    /// Returns an attributed string with the current CPU usage percentage.
    var processorAttributedString: NSAttributedString {
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
            .font: Font(name: "Courier", size: fontSize)!,
            .foregroundColor: fontColor,
            .paragraphStyle: labelStyle
            ] as [NSAttributedString.Key: Any]

        return NSMutableAttributedString(string: labelText, attributes: cpuStatsAttributes)
    }
}
