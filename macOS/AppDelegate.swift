//
//  AppDelegate.swift
//  SKTiled Demo - macOS
//
//  Created by Michael Fessenden on 9/19/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Cocoa
import SpriteKit


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var currentLoggingLevel: NSMenuItem!
    @IBOutlet weak var recentFilesMenu: NSMenuItem!
    @IBOutlet weak var recentFilesSubmenu: NSMenu!

    @IBOutlet weak var updateModeMenuItem: NSMenuItem!
    @IBOutlet weak var renderEffectsMenuItem: NSMenuItem!
    @IBOutlet weak var loggingLevelMenuItem: NSMenuItem!
    @IBOutlet weak var timeDisplayMenuItem: NSMenuItem!


    // map top menu
    @IBOutlet weak var mapMenuItem: NSMenuItem!
    @IBOutlet weak var mapDebugDrawMenu: NSMenuItem!
    @IBOutlet weak var layerVisibilityMenu: NSMenuItem!
    @IBOutlet weak var layerIsolationMenu: NSMenuItem!

    // debug menu
    @IBOutlet weak var renderStatisticsMenuItem: NSMenuItem!
    @IBOutlet weak var mouseFiltersMenuItem: NSMenuItem!
    @IBOutlet weak var tileColorsMenuItem: NSMenuItem!
    @IBOutlet weak var objectColorsMenuItem: NSMenuItem!


    // caching
    @IBOutlet weak var isolateTilesMenuItem: NSMenuItem!

    // camera menu
    @IBOutlet weak var cameraIgnoreMaxZoomMenuItem: NSMenuItem!
    @IBOutlet weak var cameraUserPreviousMenuItem: NSMenuItem!
    @IBOutlet weak var cameraCallbacksMenuItem: NSMenuItem!
    @IBOutlet weak var cameraCallbacksContainedMenuItem: NSMenuItem!
    @IBOutlet weak var cameraZoomClampingMenuItem: NSMenuItem!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupNotifications()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    var viewController: GameViewController? {
        if let window = NSApplication.shared.mainWindow {
            if let controller = window.contentViewController as? GameViewController {
                return controller
            }
        }
        return nil
    }

    /// Reference to the current scene's tilemap.
    var tilemap: SKTilemap? {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else {
                return nil
        }
        return scene.tilemap
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneLoaded), name: Notification.Name.Demo.SceneLoaded, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapUpdateModeChanged), name: Notification.Name.Map.UpdateModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapCacheUpdated), name: Notification.Name.Map.CacheUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(initializeTilemapInterface), name: Notification.Name.Map.FinishedRendering, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatisticsVisibilityChanged), name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdated), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoCameraUpdated), name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(initializeIsolateTilesMenu), name: Notification.Name.DataStorage.IsolationModeChanged, object: nil)
    }

    // MARK: - Interface

    /**
     Update the current demo interface when the tilemap has finished rendering.

     - parameter notification: `Notification` tilemap name.
     */
    @objc func initializeTilemapInterface(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else {
            return
        }

        // initialize menus for layer functions
        self.initializeTilemapMenus(tilemap: tilemap)


        // tilemap menu
        renderEffectsMenuItem.state = (tilemap.shouldEnableEffects == true) ? .on : .off

        // debug menu
        renderStatisticsMenuItem.state = (TiledGlobals.default.enableRenderCallbacks == true) ? .on : .off

        // create the logging level menu
        self.initializeLoggingLevelMenu()

        // create the mouse filter menu
        self.initializeMouseFilterMenu()

        // create the debugging colors menu
        self.initializeDebugColorsMenu()

        // update the time display menu
        self.updateRenderStatsTimeFormatMenu()

        // initialize the tile isolation menu
        self.initializeIsolateTilesMenu()

        guard let window = NSApplication.shared.mainWindow else {
            return
        }

        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String {
            window.title = "\(appName): \(tilemap.url.filename)"
        }

    }

    // MARK: - Menu Initialization

    /**
     Initialize debug menus.

     - parameter tilemap: `SKTilemap` tile map object.
     */
    @objc func initializeDemoMenus(tilemap: SKTilemap) {

    }



    /**
     Initialize debug menus.

     - parameter tilemap: `SKTilemap` tile map object.
     */
    @objc func initializeDebugMenus(tilemap: SKTilemap) {

    }


    /**
     Callback to update the UI whenever the tilemap is updated in the demo.

     - parameter notification: `Notification` event notification.
     */
    @objc func tilemapWasUpdated(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else {
            return
        }

        guard (tilemap.isRendered == true) else { return }
        let renderState = (tilemap.shouldEnableEffects == true) ? NSControl.StateValue.on : NSControl.StateValue.off
        renderEffectsMenuItem.state = renderState

        // update the tilemap menus
        updateTilemapMenus(tilemap: tilemap)
    }

    // MARK: - Notification Callbacks

    @objc func tilemapCacheUpdated(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else {
            return
        }

        Logger.default.log("tilemap cache updated: \(tilemap.updateMode.description)", level: .info, symbol: "AppDelegate")
    }

    @objc func tilemapUpdateModeChanged(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else {
            return
        }
        Logger.default.log("tilemap update mode changed: \(tilemap.updateMode.description)", level: .info, symbol: "AppDelegate")
    }

    @objc func demoSceneLoaded(notification: Notification) {
        guard (notification.object as? SKTiledScene != nil) else {
            return
        }
        Logger.default.log("new scene loaded", level: .info, symbol: "AppDelegate")
    }


    // MARK: - Loading & Saving
    /**
     Action to launch a file dialog and load map.
     */
    @IBAction func loadTilemapAction(_ sender: Any) {
        guard let gameController = viewController else { return }

        // open a file dialog
        let dialog = NSOpenPanel()
        dialog.title = "Choose a Tiled resource."
        dialog.allowedFileTypes = ["tmx"]

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {

            // tmx file path
            let result = dialog.url

            if let tmxURL = result {

                let dirname = tmxURL.deletingLastPathComponent()
                let filename = tmxURL.lastPathComponent

                let relativeURL = URL(fileURLWithPath: filename, relativeTo: dirname)
                let demoController = gameController.demoController
                let currentMapIndex = demoController.currentIndex
                demoController.addTilemap(url: relativeURL, at: currentMapIndex)
            }

        } else {
            Logger.default.log("load cancelled", level: .info)
        }
    }

    /**
     Action to reload the current scene.
     */
    @IBAction func reloadTilemapAction(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.reloadScene()
    }


    @IBAction func timeDisplayUpdated(_ sender: NSMenuItem) {
        guard let identifier = Int(sender.accessibilityTitle()!) else {
            Logger.default.log("invalid identifier: \(sender.accessibilityTitle()!)", level: .error)
            return
        }

        if let newTimeDisplay = TiledGlobals.TimeDisplayMode.init(rawValue: identifier) {
            TiledGlobals.default.timeDisplayMode = newTimeDisplay
        }

        self.updateRenderStatsTimeFormatMenu()
    }

    @IBAction func mouseFiltersUpdatedAction(_ sender: NSMenuItem) {
        guard let idstring = sender.accessibilityTitle() else { return }

        if let identifier = Int(idstring) {
            let sentFlag = TiledGlobals.DebugDisplayOptions.MouseFilters.init(rawValue: identifier)

            if TiledGlobals.default.debug.mouseFilters.contains(sentFlag) {
                TiledGlobals.default.debug.mouseFilters = TiledGlobals.default.debug.mouseFilters.subtracting(sentFlag)
            } else {
                TiledGlobals.default.debug.mouseFilters.insert(sentFlag)
            }

            // rebuild the mouse filter menu
            self.initializeMouseFilterMenu()
        }
    }

    @IBAction func tileColorsUpdatedAction(_ sender: NSMenuItem) {
        guard let colorString = sender.accessibilityTitle() else { return }

        let newColor = SKColor(hexString: colorString)
        TiledGlobals.default.debug.tileHighlightColor = newColor
        Logger.default.log("setting new tile highlight color: \(colorString)", level: .info, symbol: "AppDelegate")

        NotificationCenter.default.post(
            name: Notification.Name.Globals.Updated,
            object: nil,
            userInfo: ["tileColor": newColor]
        )

        self.initializeDebugColorsMenu()
    }

    @IBAction func objectColorsUpdatedAction(_ sender: NSMenuItem) {
        guard let colorString = sender.accessibilityTitle() else { return }

        let newColor = SKColor(hexString: colorString)
        TiledGlobals.default.debug.objectHighlightColor = newColor
        Logger.default.log("setting new object highlight color: \(colorString)", level: .info, symbol: "AppDelegate")

        NotificationCenter.default.post(
            name: Notification.Name.Globals.Updated,
            object: nil,
            userInfo: ["objectColor": newColor]
        )

        self.initializeDebugColorsMenu()
    }

    @IBAction func cameraZoomClampingUpdated(_ sender: NSMenuItem) {
        guard let idstring = sender.accessibilityTitle() else { return }

        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }


        if let identifier = Float(idstring) {
            guard let newZoomClampingMode = CameraZoomClamping.init(rawValue: CGFloat(identifier)) else {
                return
            }

            Logger.default.log("zoom clamping: \(newZoomClampingMode)", level: .info, symbol: "AppDelegate")
            scene.cameraNode.zoomClamping = newZoomClampingMode
        }
    }

    @IBAction func cameraFitToViewAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        gameController.demoController.fitSceneToView()
    }

    @IBAction func cameraIgnoreZoomConstraintsAction(_ sender: NSMenuItem) {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }


        let newIgnoreValue = (sender.state == .off)
        scene.cameraNode.ignoreZoomConstraints = newIgnoreValue
        Logger.default.log("ignoring camera constraints: \(scene.cameraNode.ignoreZoomConstraints)", level: .info, symbol: "AppDelegate")
        self.initializeSceneCameraMenu(camera: scene.cameraNode)
        gameController.demoController.preferences.ignoreZoomConstraints = newIgnoreValue
        gameController.demoController.updateCommandString("using camera zoom constraints: \(newIgnoreValue)")

    }

    @IBAction func cameraUsePreviousCameraAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }

        if let preferences = gameController.demoController.preferences {
            preferences.usePreviousCamera = (sender.state == .off)
            Logger.default.log("setting use previous camera: \(preferences.usePreviousCamera)", level: .info, symbol: "AppDelegate")
            gameController.demoController.updateCommandString("setting use previous camera: \(preferences.usePreviousCamera)")
        }
    }

    @IBAction func cameraCallbacksAction(_ sender: NSMenuItem) {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }

        let currentState = (sender.state == .on)
        let nextState = !currentState

        TiledGlobals.default.enableCameraCallbacks = nextState
        gameController.demoController.updateCommandString("enable camera callbacks: \(nextState == true ? "on" : "off")")


        NotificationCenter.default.post(
            name: Notification.Name.Globals.Updated,
            object: nil,
            userInfo: nil
        )

        scene.cameraNode.enableDelegateCallbacks(nextState)
    }

    @IBAction func cameraVisibleNodesCallbacksAction(_ sender: NSMenuItem) {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }

        let currentState = (sender.state == .on)
        let nextState = !currentState

        scene.cameraNode.notifyDelegatesOnContainedNodesChange = nextState
        gameController.demoController.updateCommandString("enable camera callbacks: \(nextState == true ? "on" : "off")")
    }

    @IBAction func cameraStatistics(_ sender: NSMenuItem) {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }

        scene.cameraNode.dumpStatistics()
    }

    // MARK: - Demo Menu

    @IBAction func showCurrentMapsAction(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.getCurrentlyLoadedTilemaps()
    }

    @IBAction func showAllAssetsAction(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.getCurrentlyLoadedAssets()
    }

    @IBAction func getExternallyLoadedAssetsAction(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.getExternallyLoadedAssets()
    }

    @IBAction func showDemoPreferencesAction(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.preferences.dumpStatistics()
    }


    @IBAction func loggingLevelUpdated(_ sender: NSMenuItem) {
        guard let identifier = sender.accessibilityTitle(),
            let identifierIntValue = Int(identifier) else {
                Logger.default.log("invalid logging identifier: \(sender.accessibilityIdentifier())", level: .error, symbol: "AppDelegate")
                return
        }

        if let newLoggingLevel = LoggingLevel.init(rawValue: identifierIntValue) {
            if (TiledGlobals.default.loggingLevel != newLoggingLevel) {
                TiledGlobals.default.loggingLevel = newLoggingLevel
                Logger.default.log("global logging level changed: \(newLoggingLevel)", level: .info, symbol: "AppDelegate")

                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil,
                    userInfo: nil
                )
            }
        }
    }


    @IBAction func drawObjectBoundariesAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleObjectBoundaryDrawing()


        var currentObjectBoundsMode = false
        if let tilemap = self.tilemap {
            currentObjectBoundsMode = tilemap.debugDrawOptions.contains(.drawObjectBounds)
        }
        sender.state = (currentObjectBoundsMode == true) ? .on : .off
    }



    // MARK: - Map Menu

    @IBAction func mapStatisticsPressed(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.dumpMapStatistics()
    }

    @IBAction func mapRenderQualityPressed(_ sender: Any) {
        guard let tilemap = self.tilemap else { return }

        var headerString = "# Tilemap \"\(tilemap.url.filename)\", render quality: \(tilemap.renderQuality) ( max: \(tilemap.maxRenderQuality) ):"
        let headerUnderline = String(repeating: "-", count: headerString.count )
        headerString = "\n\(headerString)\n\(headerUnderline)\n"

        //var layerData: [String] = []

        var longestName = 0
        tilemap.getLayers().forEach { layer in
            let layerNameCount = layer.layerName.count + 3
            if layerNameCount > longestName {
                longestName = layerNameCount
            }
        }

        tilemap.getLayers().forEach { layer in

            var layerNameString = "\"\(layer.layerName)\""
            let layerPadding = longestName - layerNameString.count

            if layerPadding > 0 {
                let padString = String(repeating: " ", count: layerPadding)
                layerNameString = "\(layerNameString)\(padString)"
            }

            headerString += "\n - \(layerNameString) → quality: \(layer.renderQuality)"
        }
        print("\(headerString)\n\n")
    }

    @IBAction func toggleRenderTilemapEffects(_ sender: NSMenuItem) {
        if let tilemap = self.tilemap {
            let currentState = tilemap.shouldEnableEffects
            tilemap.shouldEnableEffects = !currentState
            Logger.default.log("setting tilemap effects rendering: \(tilemap.shouldEnableEffects)", level: .info)

            let nextState = (tilemap.shouldEnableEffects == true) ? NSControl.StateValue.on : NSControl.StateValue.off
            sender.state = nextState

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap,
                userInfo: nil
            )
        }
    }
    
    
    // MARK: - Map Debug Drawing
    
    @IBAction func debugDrawOptionsUpdated(_ sender: NSMenuItem) {
        guard let identifier = Int(sender.accessibilityIdentifier()),
            let tilemap = tilemap else {
            Logger.default.log("invalid identifier: \(sender.accessibilityIdentifier())", level: .error)
            return
        }
        
        let willRemoveOption = sender.state == .on
        let drawOption = DebugDrawOptions.init(rawValue: identifier)
        if (willRemoveOption == true) {
            tilemap.debugDrawOptions = tilemap.debugDrawOptions.subtracting(drawOption)
        } else {
            tilemap.debugDrawOptions.insert(drawOption)
        }
        
        
        NotificationCenter.default.post(
            name: Notification.Name.Map.Updated,
            object: tilemap
        )
    }

    @IBAction func drawMapBoundsAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleMapDemoDrawBounds()

        var currentBoundsMode = false
        if let tilemap = self.tilemap {
            currentBoundsMode = tilemap.debugDrawOptions.contains(.drawBounds)
        }

        sender.state = (currentBoundsMode == true) ? .on : .off
    }

    @IBAction func drawMapGridAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleMapDemoDrawGrid()

        var currentGridMode = false
        if let tilemap = self.tilemap {
            currentGridMode = tilemap.debugDrawOptions.contains(.drawGrid)
        }

        sender.state = (currentGridMode == true) ? .on : .off
    }

    @IBAction func drawSceneGraphsAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleMapGraphVisualization()

        var currentGraphMode = false
        if let tilemap = self.tilemap {
            currentGraphMode = tilemap.isShowingGraphs
        }

        sender.state = (currentGraphMode == true) ? .on : .off
    }

    // MARK: - Debug Menu

    @IBAction func showGlobalsAction(_ sender: Any) {
        TiledGlobals.default.dumpStatistics()
    }

    @IBAction func renderStatisticsVisibilityAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        let doShowStatistics = (sender.state == .off)
        demoController.toggleRenderStatistics(value: doShowStatistics)
    }

    @IBAction func isloateCachedTilesAction(_ sender: NSMenuItem) {
        guard let identifier = Int(sender.accessibilityIdentifier()) else {
            Logger.default.log("invalid identifier: \(sender.accessibilityIdentifier())", level: .error)
            return
        }


        let removeIsolation = (sender.state == .on)

        guard let tilemap = self.tilemap,
            let dataStorage = tilemap.dataStorage else { return }

        guard let newIsolationMode = CacheIsolationMode(rawValue: identifier) else {
            Logger.default.log("invalid isolation mode value: \(identifier)", level: .error)
            return
        }


        dataStorage.isolationMode = (removeIsolation == true) ? .none : newIsolationMode
    }


    // MARK: - Callbacks & Helpers

    @IBAction func tilemapUpdateGlobalChanged(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController


        guard let identifier = Int(sender.accessibilityIdentifier()) else {
            Logger.default.log("invalid identifier: \(sender.accessibilityIdentifier())", level: .error)
            return
        }

        if (TileUpdateMode.init(rawValue: identifier) != nil) {
            demoController.updateTileUpdateMode(value: identifier)
        }
    }

    /**
     Callback to update the UI whenever the tilemap update mode changes.

     - parameter sender: `NSMenuItem` sender menu item.
     */
    @IBAction func cycleTilemapUpdateMode(_ sender: NSMenuItem) {
        guard let updateMode = sender.accessibilityTitle() else { return }
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController

        demoController.cycleTilemapUpdateMode(mode: updateMode)
    }

    // MARK: - Layer Toggles

    @IBAction func toggleLayerVisibility(_ sender: NSMenuItem) {
        guard let layerID = sender.accessibilityTitle() else { return }
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController

        let layerIsVisible = (sender.state == .on)
        demoController.toggleLayerVisibility(layerID: layerID, visible: !layerIsVisible)
    }
    

    @IBAction func toggleAllLayerVisibility(_ sender: NSMenuItem) {
        guard let identifier = Int(sender.accessibilityIdentifier()) else {
            Logger.default.log("invalid identifier: \(sender.accessibilityIdentifier())", level: .error)
            return
        }

        let allLayersVisible = (identifier == 1)

        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleAllLayerVisibility(visible: allLayersVisible)
    }


    @IBAction func isolateLayer(_ sender: NSMenuItem) {
        guard let layerID = sender.accessibilityTitle() else { return }
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController

        let doIsolateLayer = (sender.state == .off)
        demoController.toggleLayerIsolated(layerID: layerID, isolated: doIsolateLayer)
    }

    @IBAction func turnIsolationOff(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.turnIsolationOff()
    }

    // MARK: - Debugging

    /**
     Update the render stats menu when the controller's  time format changes.
     */
    @objc func updateRenderStatsTimeFormatMenu() {

        if let timeDisplaySubMenu = timeDisplayMenuItem.submenu {
            timeDisplaySubMenu.removeAllItems()

            for mode in TiledGlobals.default.timeDisplayMode.allModes {
                let timeMenuItem = NSMenuItem(title: mode.uiControlString, action: #selector(timeDisplayUpdated), keyEquivalent: "")
                timeMenuItem.setAccessibilityTitle("\(mode.rawValue)")
                timeMenuItem.state = (TiledGlobals.default.timeDisplayMode.rawValue == mode.rawValue) ? NSControl.StateValue.on : NSControl.StateValue.off
                timeDisplaySubMenu.addItem(timeMenuItem)
            }
        }
    }

    // MARK: Show/Hide Render Stats

    @objc func renderStatisticsVisibilityChanged(notification: Notification) {
        if let nextState = notification.userInfo!["showRenderStats"] as? Bool {
            renderStatisticsMenuItem.state = (nextState == false) ? .off : .on
        }
    }

    // MARK: - Globals
    @objc func globalsUpdated(notification: Notification) {
        self.initializeLoggingLevelMenu()
        self.updateRenderStatsTimeFormatMenu()
        self.cameraCallbacksMenuItem.state = (TiledGlobals.default.enableCameraCallbacks == true) ? .on : .off
    }

    @objc func demoCameraUpdated(notification: Notification) {
        guard let camera = notification.object as? SKTiledSceneCamera else {
            return
        }

        self.cameraCallbacksContainedMenuItem.state = (camera.notifyDelegatesOnContainedNodesChange == true) ? .on : .off
        self.initializeSceneCameraMenu(camera: camera)
    }
}



extension AppDelegate {

    // MARK: - Logging Level Menu

    @objc func initializeLoggingLevelMenu() {

        // update the logging menu
        if let loggingLevelSubMenu = loggingLevelMenuItem.submenu {
            loggingLevelSubMenu.removeAllItems()

            let allLoggingLevels = LoggingLevel.all

            for loggingLevel in allLoggingLevels {
                guard (loggingLevel != LoggingLevel.none) && (loggingLevel != LoggingLevel.custom) else { continue }

                let levelMenuItem = NSMenuItem(title: loggingLevel.description.uppercaseFirst, action: #selector(loggingLevelUpdated(_:)), keyEquivalent: "")
                levelMenuItem.setAccessibilityTitle("\(loggingLevel.rawValue)")
                levelMenuItem.state = (TiledGlobals.default.loggingLevel == loggingLevel) ? .on : .off
                loggingLevelSubMenu.addItem(levelMenuItem)
            }
        }
    }

    @objc func updateLoggingLevelMenu() {
        if let loggingLevelSubMenu = loggingLevelMenuItem.submenu {
            for menuitem in loggingLevelSubMenu.items {
                guard let accessibilityTitle = menuitem.accessibilityTitle() else { continue }
                if let identifier = Int(accessibilityTitle) {
                    menuitem.state = (identifier == TiledGlobals.default.loggingLevel.rawValue) ? .on : .off
                }
            }
        }
    }

    // MARK: - Mouse Filter Menu
    @objc func initializeMouseFilterMenu() {
        // create the mouse filter menu
        if let coordinateDisplaySubMenu = mouseFiltersMenuItem.submenu {
            coordinateDisplaySubMenu.removeAllItems()

            let allOptions = Array(TiledGlobals.DebugDisplayOptions.MouseFilters.all.elements())
            let optionStrings = TiledGlobals.DebugDisplayOptions.MouseFilters.all.strings

            for (index, option) in allOptions.enumerated() {
                guard (index <= optionStrings.count - 1) else {
                    return
                }

                let featureMenuItem = NSMenuItem(title: optionStrings[index], action: #selector(mouseFiltersUpdatedAction), keyEquivalent: "")
                let thisOption = TiledGlobals.DebugDisplayOptions.MouseFilters.init(rawValue: option.rawValue)
                featureMenuItem.setAccessibilityTitle("\(option.rawValue)")
                featureMenuItem.state = TiledGlobals.default.debug.mouseFilters.contains(thisOption) ? NSControl.StateValue.on : NSControl.StateValue.off
                coordinateDisplaySubMenu.addItem(featureMenuItem)
            }
        }
    }

    @objc func initializeDebugColorsMenu() {

        let allColors = TiledObjectColors.all
        let colorNames = TiledObjectColors.names

        let currentTileColor = TiledGlobals.default.debug.tileHighlightColor
        let currentObjectColor = TiledGlobals.default.debug.objectHighlightColor

        // create the tile colors menu
        if let tileColorsSubMenu = tileColorsMenuItem.submenu {
            tileColorsSubMenu.removeAllItems()

            for (idx, color) in allColors.enumerated() {

                let colorName = colorNames[idx]

                let tileColorMenuItem = NSMenuItem(title: "\(colorName.uppercaseFirst)", action: #selector(tileColorsUpdatedAction), keyEquivalent: "")
                tileColorMenuItem.setAccessibilityTitle("\(color.hexString())")

                tileColorMenuItem.state = (color == currentTileColor) ? NSControl.StateValue.on : NSControl.StateValue.off
                tileColorsSubMenu.addItem(tileColorMenuItem)
            }
        }

        if let objectColorsSubMenu = objectColorsMenuItem.submenu {
            objectColorsSubMenu.removeAllItems()

            for (idx, color) in allColors.enumerated() {

                let colorName = colorNames[idx]
                let objectColorMenuItem = NSMenuItem(title: "\(colorName.uppercaseFirst)", action: #selector(objectColorsUpdatedAction), keyEquivalent: "")
                objectColorMenuItem.setAccessibilityTitle("\(color.hexString())")

                objectColorMenuItem.state = (color == currentObjectColor) ? NSControl.StateValue.on : NSControl.StateValue.off
                objectColorsSubMenu.addItem(objectColorMenuItem)
            }
        }
    }

    @objc func initializeSceneCameraMenu(camera: SKTiledSceneCamera) {

        cameraIgnoreMaxZoomMenuItem.isEnabled = true
        cameraIgnoreMaxZoomMenuItem.state = (camera.ignoreZoomConstraints == true) ? .on : .off
        cameraUserPreviousMenuItem.isEnabled = true
        cameraZoomClampingMenuItem.isEnabled = true
        cameraCallbacksContainedMenuItem.state = (camera.notifyDelegatesOnContainedNodesChange == true) ? .on : .off

        // build/rebuild the camera zoom menu
        if let sceneCameraSubMenu = cameraZoomClampingMenuItem.submenu {
            sceneCameraSubMenu.removeAllItems()

            for cameraMode in CameraZoomClamping.allModes() {

                let featureMenuItem = NSMenuItem(title: "\(cameraMode.name)", action: #selector(cameraZoomClampingUpdated), keyEquivalent: "")
                featureMenuItem.setAccessibilityTitle("\(cameraMode.rawValue)")

                featureMenuItem.state = (cameraMode == camera.zoomClamping) ? NSControl.StateValue.on : NSControl.StateValue.off
                sceneCameraSubMenu.addItem(featureMenuItem)
            }
        }

        if let gameController = viewController {
            let preferences = gameController.demoController.preferences
            cameraUserPreviousMenuItem.state = (preferences?.usePreviousCamera == true) ? .on : .off
        }
    }

    // MARK: - Tilemap Menus

    /**
     Initialize tilemap menus.

     - parameter tilemap: `SKTilemap` tile map object.
     */
    @objc func initializeTilemapMenus(tilemap: SKTilemap) {
        
        // map debug draw options
        if let debugDrawSubmenu = mapDebugDrawMenu.submenu {
            debugDrawSubmenu.removeAllItems()
            
            let allOptions = Array(DebugDrawOptions.all.elements())
            let optionStrings = DebugDrawOptions.all.strings

            
            for (index, option) in allOptions.enumerated() {
                guard (index <= optionStrings.count - 1) else {
                    return
                }
                
                
                
                let layerMenuItem = NSMenuItem(title: optionStrings[index], action: #selector(debugDrawOptionsUpdated), keyEquivalent: "")
                layerMenuItem.setAccessibilityIdentifier("\(option.rawValue)")
                layerMenuItem.state = (tilemap.debugDrawOptions.contains(option)) ? NSControl.StateValue.on : NSControl.StateValue.off
                debugDrawSubmenu.addItem(layerMenuItem)
            }
        }
        
        

        if let visibilitySubMenu = layerVisibilityMenu.submenu {
            visibilitySubMenu.removeAllItems()

            // add all hidden/all visible
            let showAllMenuItem = NSMenuItem(title: "Show all", action: #selector(toggleAllLayerVisibility), keyEquivalent: "")
            showAllMenuItem.setAccessibilityIdentifier("\(1)")

            let hideAllMenuItem = NSMenuItem(title: "Hide all", action: #selector(toggleAllLayerVisibility), keyEquivalent: "")
            hideAllMenuItem.setAccessibilityIdentifier("\(0)")

            let divider = NSMenuItem.separator()
            visibilitySubMenu.addItem(showAllMenuItem)
            visibilitySubMenu.addItem(hideAllMenuItem)
            visibilitySubMenu.addItem(divider)


            for layer in tilemap.getLayers() {
                let layerMenuItem = NSMenuItem(title: layer.menuDescription, action: #selector(toggleLayerVisibility), keyEquivalent: "")
                layerMenuItem.setAccessibilityTitle(layer.uuid)
                layerMenuItem.state = (layer.visible == true) ? NSControl.StateValue.on : NSControl.StateValue.off
                visibilitySubMenu.addItem(layerMenuItem)
            }
        }

        if let isolationSubMenu = layerIsolationMenu.submenu {
            isolationSubMenu.removeAllItems()

            isolationSubMenu.addItem(NSMenuItem(title: "Isolate: Off", action: #selector(turnIsolationOff), keyEquivalent: ""))
            isolationSubMenu.addItem(NSMenuItem.separator())

            for layer in tilemap.getLayers() {
                let layerMenuItem = NSMenuItem(title: layer.menuDescription, action: #selector(isolateLayer), keyEquivalent: "")
                layerMenuItem.setAccessibilityTitle(layer.uuid)
                layerMenuItem.state = (layer.isolated == true) ? NSControl.StateValue.on : NSControl.StateValue.off
                isolationSubMenu.addItem(layerMenuItem)
            }
        }


        if let updateModeSubMenu = updateModeMenuItem.submenu {
            updateModeSubMenu.removeAllItems()

            for mode in TileUpdateMode.allModes() {
                let modeMenuItem = NSMenuItem(title: mode.uiControlString, action: #selector(cycleTilemapUpdateMode), keyEquivalent: "")
                modeMenuItem.setAccessibilityTitle("\(mode.rawValue)")
                modeMenuItem.state = (tilemap.updateMode.rawValue == mode.rawValue) ? NSControl.StateValue.on : NSControl.StateValue.off
                updateModeSubMenu.addItem(modeMenuItem)
            }
        }
    }

    @objc func updateTilemapMenus(tilemap: SKTilemap) {

        let allLayersHidden = tilemap.allLayersHidden
        let allLayersVisible = tilemap.allLayersVisible
        
        // debug draw options menu
        if let debugDrawSubmenu = mapDebugDrawMenu.submenu {
            
            for menuitem in debugDrawSubmenu.items {
                let accessibilityIdentifier = menuitem.accessibilityIdentifier()
                
                if let identifier = Int(accessibilityIdentifier) {
                    let menuOption = DebugDrawOptions.init(rawValue: identifier)
                    menuitem.state = (tilemap.debugDrawOptions.contains(menuOption)) ? .on : .off
                    //let contains = menuitem.state == .on
                }
            }
        }
        
        
        
        // update the tilemap update mode menu
        if let updateModeSubMenu = self.updateModeMenuItem.submenu {
            for menuitem in updateModeSubMenu.items {
                if let identifier = Int(menuitem.accessibilityIdentifier()) {
                    menuitem.state = (identifier == tilemap.updateMode.rawValue) ? .on : .off
                }
            }
        }

        if let visibilitySubMenu = layerVisibilityMenu.submenu {


            visibilitySubMenu.items.forEach { menuItem in
                if let layerID = menuItem.accessibilityTitle() {

                    if let layer = tilemap.getLayer(withID: layerID) {
                        menuItem.state = (layer.visible == true) ? .on : .off
                    }
                }

                // update the show/hide all menu
                if let identifier = Int(menuItem.accessibilityIdentifier()) {
                    if (identifier == 0) {
                        //menuItem.state = (allLayersHidden == true) ? .on : .off
                        menuItem.isEnabled = (allLayersHidden == true) ? false : true
                    }

                    if (identifier == 1) {
                        //menuItem.state = (allLayersVisible == true) ? .on : .off
                        menuItem.isEnabled = (allLayersVisible == true) ? false : true
                    }
                }
            }
        }

        if let isolationSubMenu = layerIsolationMenu.submenu {
            isolationSubMenu.items.forEach { menuItem in
                if let layerID = menuItem.accessibilityTitle() {
                    if let layer = tilemap.getLayer(withID: layerID) {
                        menuItem.state = (layer.isolated == true) ? .on : .off
                    }
                }
            }
        }

        if let updateModeSubMenu = updateModeMenuItem.submenu {
            updateModeSubMenu.items.forEach { menuItem in
                if let modeRawValue = menuItem.accessibilityTitle() {
                    if let modeIntValue = Int(modeRawValue) {
                        menuItem.state = (modeIntValue == tilemap.updateMode.rawValue) ? .on : .off
                    }
                }
            }
        }
    }


    @objc func initializeIsolateTilesMenu() {

        // create the mouse filter menu
        if let isolateTilesSubMenu = isolateTilesMenuItem.submenu {
            isolateTilesSubMenu.removeAllItems()

            // add an off toggle and divider
            let isolateOffMenuItem = NSMenuItem(title: "Isolation off", action: #selector(isloateCachedTilesAction), keyEquivalent: "")
            isolateOffMenuItem.setAccessibilityIdentifier("\(0)")
            let divider = NSMenuItem.separator()
            isolateTilesSubMenu.addItem(isolateOffMenuItem)
            isolateTilesSubMenu.addItem(divider)


            let allIsolationModes = CacheIsolationMode.all
            var currentIsolationMode = CacheIsolationMode.none

            if let tilemap = tilemap {
                if let dataStorage = tilemap.dataStorage {
                    currentIsolationMode = dataStorage.isolationMode
                }
            }

            for (_, mode) in allIsolationModes.enumerated() {

                let isolateMenuItem = NSMenuItem(title: "\(mode)", action: #selector(isloateCachedTilesAction), keyEquivalent: "")
                isolateMenuItem.setAccessibilityIdentifier("\(mode.rawValue)")

                isolateMenuItem.state = (mode == currentIsolationMode) ? NSControl.StateValue.on : NSControl.StateValue.off
                isolateTilesSubMenu.addItem(isolateMenuItem)
            }
        }
    }
}


extension SKTilemap {

    /// Returns true if all layers are hidden.
    var allLayersHidden: Bool {
        return getLayers(recursive: true).reduce(0, { result, layer -> Int in
            let hidden: Int = layer.isHidden == true ? 0 : 1
            return result + hidden
        }) == 0
    }

    /// Returns true if all layers are visible.
    var allLayersVisible: Bool {
        return getLayers(recursive: true).reduce(0, { result, layer -> Int in
            let visible: Int = layer.isHidden == true ? 1 : 0
            return result + visible
        }) == 0
    }
}
