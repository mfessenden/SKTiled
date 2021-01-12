//
//  AppDelegate.swift
//  SKTiled Demo - macOS
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

import Cocoa
import SpriteKit


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    /// Window controller for inspector panel.
    var inspectorController: NSWindowController?
    var preferencesController: PreferencesWindowController?

    // file menu
    @IBOutlet weak var openMapMenuitem: NSMenuItem!
    @IBOutlet weak var reloadMapMenuitem: NSMenuItem!
    @IBOutlet weak var demoFilesMenu: NSMenuItem!
    @IBOutlet weak var demoFilesSubmenu: NSMenu!

    // map menu
    @IBOutlet weak var mapMenuItem: NSMenuItem!             // 'Map' top-level menu item
    @IBOutlet weak var updateModeMenuItem: NSMenuItem!      // 'Map > Update Mode' sub menu
    @IBOutlet weak var renderEffectsMenuItem: NSMenuItem!   // 'Map > Render Effects' menu item (check)
    @IBOutlet weak var mapDebugDrawMenu: NSMenuItem!        // 'Map > Debug Draw Options' sub menu
    @IBOutlet weak var mapGridColorMenu: NSMenuItem!
    @IBOutlet weak var layerVisibilityMenu: NSMenuItem!     // 'Map' update mode sub menu
    @IBOutlet weak var timeDisplayMenuItem: NSMenuItem!
    @IBOutlet weak var layerIsolationMenu: NSMenuItem!
    @IBOutlet weak var isolationModeMenuItem: NSMenuItem!
    @IBOutlet weak var isolateTilesMenuItem: NSMenuItem!    // deprecated, use `isolationModeMenuItem`

    // camera menu
    @IBOutlet weak var cameraMainMenu: NSMenuItem!
    @IBOutlet weak var cameraCallbacksMenuItem: NSMenuItem!
    @IBOutlet weak var cameraTrackVisibleNodesItem: NSMenuItem!
    @IBOutlet weak var cameraIgnoreMaxZoomMenuItem: NSMenuItem!
    @IBOutlet weak var cameraUserPreviousMenuItem: NSMenuItem!
    @IBOutlet weak var cameraZoomClampingMenuItem: NSMenuItem!

    // debug menu
    @IBOutlet weak var debugMainMenu: NSMenuItem!
    @IBOutlet weak var loggingLevelMenuItem: NSMenuItem!
    @IBOutlet weak var mouseFiltersMenuItem: NSMenuItem!
    @IBOutlet weak var selectedNodesMenuItem: NSMenuItem!
    @IBOutlet weak var tileColorsMenuItem: NSMenuItem!
    @IBOutlet weak var objectColorsMenuItem: NSMenuItem!

    // development menu
    @IBOutlet weak var developmentMainMenu: NSMenuItem!
    @IBOutlet weak var renderStatisticsMenuItem: NSMenuItem!
    @IBOutlet weak var tilemapStatisticsMenuItem: NSMenuItem!
    @IBOutlet weak var layerStatisticsMenuItem: NSMenuItem!
    @IBOutlet weak var currentMapsMenuItem: NSMenuItem!
    @IBOutlet weak var allAssetsMapsMenuItem: NSMenuItem!
    @IBOutlet weak var externalAssetsMenuItem: NSMenuItem!

    // MARK: - Application Methods

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMainInterface()
        setupNotifications()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    /// Called when a file is selected from the `Recent files` menu.
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        guard let controller = viewController else {
            return false
        }

        Logger.default.log("opening file: '\(filename)'", level: .info, symbol: "AppDelegate")
        let demoController = controller.demoController
        demoController.loadScene(url: URL(fileURLWithPath: filename), usePreviousCamera: false)
        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.LaunchPreferences, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneLoaded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.UpdateModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.FinishedRendering, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.TileIsolationModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DataStorage.IsolationModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.ResetDemoInterface, object: nil)
    }


    // MARK: - Interface & Setup


    func setupNotifications() {


        // demo notifications
        NotificationCenter.default.addObserver(self, selector: #selector(demoControllerAssetScanFinished), name: Notification.Name.DemoController.AssetsFinishedScanning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(launchApplicationPreferences), name: Notification.Name.Demo.LaunchPreferences, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneLoaded), name: Notification.Name.Demo.SceneLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoControllerAboutToScanForAssets), name: Notification.Name.DemoController.WillBeginScanForAssets, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetMainInterfaceAction), name: Notification.Name.DemoController.ResetDemoInterface, object: nil)

        // tilemap notifications
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapUpdateModeChanged), name: Notification.Name.Map.UpdateModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(initializeInterfaceForTilemap), name: Notification.Name.Map.FinishedRendering, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(initializeInterfaceForTilemap), name: Notification.Name.Map.TileIsolationModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatisticsVisibilityChanged), name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneCameraUpdated), name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(initializeIsolateTilesMenu), name: Notification.Name.DataStorage.IsolationModeChanged, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChanged), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionClearedAction), name: Notification.Name.Demo.MouseRightClicked, object: nil)
    }


    /// This is a once-only function that runs when the app launches.
    @objc func setupMainInterface() {
        renderStatisticsMenuItem.state = (TiledGlobals.default.enableRenderCallbacks == true) ? .on : .off
        cameraCallbacksMenuItem.toolTip = "toggles the `TiledGlobals.enableCameraCallbacks` property"
        cameraTrackVisibleNodesItem.toolTip = "toggles the `SKTiledSceneCamera.notifyDelegatesOnContainedNodesChange` property"

    }

    /// Reset the interace. Called when the `Notification.Name.DemoController.ResetDemoInterface` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func resetMainInterfaceAction(_ notification: Notification) {
        //notification.dump(#fileID, function: #function)
        resetMainInterface()
    }

    /// Resets the main interface to its original state.
    @objc func resetMainInterface() {
        Logger.default.log("resetting main interface...", level: .info, symbol: "AppDelegate")

        mapMenuItem.isEnabled = false
        cameraMainMenu.isEnabled = false
        debugMainMenu.isEnabled = false


        // items in the 'Development' menu
        //developmentMainMenu.isEnabled = false
        renderStatisticsMenuItem.isEnabled = false
        tilemapStatisticsMenuItem.isEnabled = false
        layerStatisticsMenuItem.isEnabled = false
        currentMapsMenuItem.isEnabled = false
        allAssetsMapsMenuItem.isEnabled = false
        externalAssetsMenuItem.isEnabled = false

        demoFilesMenu.isEnabled = false
        debugMainMenu.isEnabled = false

        tilemapStatisticsMenuItem.title = "Tilemap Statistics (reset)"

        // selected nodes menu
        selectedNodesMenuItem.submenu?.removeAllItems()
        selectedNodesMenuItem.isEnabled = false
    }

    /// Update the current demo interface when the tilemap has finished rendering.
    ///
    /// - Parameter notification: event notification.
    @objc func initializeInterfaceForTilemap(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let tilemap = notification.object as? SKTilemap else {
            Logger.default.log("tilemap not accessible.", level: .error, symbol: "AppDelegate")
            return
        }

        debugMainMenu.isEnabled = true

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

        // initialize the map isolation mode menu
        self.initializeIsolationModeMenu(tilemap: tilemap)

        // initialize the tile isolation menu
        self.initializeIsolateTilesMenu()


        // set the window title
        guard let window = NSApplication.shared.mainWindow else {
            return
        }

        let wintitle = TiledGlobals.default.windowTitle
        window.title = "\(wintitle): \(tilemap.url.filename)"
        Logger.default.log("tilemap rendered: \(tilemap.description)", level: .info, symbol: "AppDelegate")

        // update the main menu...
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenu = mainMenu.item(at: 0)?.submenu else {
            return
        }

        let applicationName = TiledGlobals.default.executableName
        appMenu.title = applicationName
        if let firstItem = appMenu.items.first {
            firstItem.title = "About \(applicationName)..."
        }
    }

    // MARK: - Notification Callbacks

    /// Callback to update the UI whenever the tilemap is updated in the demo. Called when the `Notification.Name.Map.Updated` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func tilemapWasUpdated(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let tilemap = notification.object as? SKTilemap else {
            return
        }

        guard (tilemap.isRendered == true) else { return }
        let renderState = (tilemap.shouldEnableEffects == true) ? NSControl.StateValue.on : NSControl.StateValue.off
        renderEffectsMenuItem.state = renderState

        // update the tilemap menus
        updateTilemapMenus(tilemap: tilemap)
    }

    @objc func tilemapUpdateModeChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let tilemap = notification.object as? SKTilemap else {
            return
        }
        Logger.default.log("tilemap update mode changed: \(tilemap.updateMode.description)", level: .info, symbol: "AppDelegate")
    }

    /// Called when the current scene has been cleared. Called when the `Notification.Name.Demo.SceneWillUnload` event fires.
    ///
    ///  userInfo: ["tilemapName", "relativePath", "currentMapIndex"]
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneCleared(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        resetMainInterface()
    }

    /// Called when a new scene has been loaded. Called when the `Notification.Name.Demo.SceneLoaded` event fires.
    ///
    ///  userInfo: ["tilemapName": `String`, "relativePath": `String`, "currentMapIndex": `Int`]
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneLoaded(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let demoScene = notification.object as? SKTiledScene else {
            fatalError("cannot access scene.")
        }

        Logger.default.log("demo scene loaded '\(demoScene.description)'", level: .success, symbol: "AppDelegate")

        initializeDemoFilesMenu()

        mapMenuItem.isEnabled = true
        cameraMainMenu.isEnabled = true
        debugMainMenu.isEnabled = true
        developmentMainMenu.isEnabled = true
    }


    // MARK: - Button & Menu Handlers

    /// Open the demo preferences controller.
    ///
    /// - Parameter sender: Menu item.
    @IBAction func launchApplicationPreferences(_ sender: Any) {
        Logger.default.log("launching application preferences...", level: .info, symbol: "AppDelegate")
        //let prefsWindowController = PreferencesWindowController.newPreferencesWindow()
        //prefsWindowController.showWindow(sender)

        if (preferencesController == nil) {
            let storyboard = NSStoryboard(name: NSStoryboard.Name("Preferences"), bundle: nil)
            let identifier = NSStoryboard.SceneIdentifier("PreferencesWindowController")
            preferencesController = storyboard.instantiateController(withIdentifier: identifier) as? PreferencesWindowController
        }

        if (preferencesController != nil) {
            preferencesController!.showWindow(sender)
            preferencesController?.window?.title = "SKTiled Demo Preferences"
        }
    }

    /// Dismiss the SKTiled app preferences.
    @IBAction func dismissApplicationPreferences(_ sender: NSButton) {
        let application = NSApplication.shared
        application.stopModal()
    }

    /// Called when the `DemoController` is about to scan for assets.
    ///
    /// Triggered when the `Notification.Name.DemoController.WillBeginScanForAssets` event fires.
    ///
    /// - Parameter notification: event notification.
    @IBAction func demoControllerAboutToScanForAssets(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        resetMainInterface()
    }

    /// Called when the `DemoController` finishes loading resources.
    /// Triggered when the `Notification.Name.DemoController.AssetsFinishedScanning` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func demoControllerAssetScanFinished(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        initializeDemoFilesMenu()
    }

    // MARK: - Loading & Saving

    /// Action to launch a file dialog and load map. Called when the `File > Load tile map` menu item is selected.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func openAndLoadExternalTilemapAction(_ sender: Any) {
        guard let gameController = viewController else { return }

        // open a file dialog
        let dialog = NSOpenPanel()
        dialog.title = "Choose a Tiled resource."
        dialog.allowedFileTypes = ["tmx"]

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {

            // tmx file path
            let result = dialog.url

            if let tmxURL = result {
                // add this file to the recent files array.
                NSDocumentController.shared.noteNewRecentDocumentURL(tmxURL)

                let dirname = tmxURL.deletingLastPathComponent()
                let filename = tmxURL.lastPathComponent

                let relativeURL = URL(fileURLWithPath: filename, relativeTo: dirname)
                let demoController = gameController.demoController
                var currentMapIndex = demoController.currentTilemapIndex

                if (currentMapIndex < 0) {
                    Logger.default.log("invalid index map index \(currentMapIndex)", level: .error)
                    currentMapIndex = 0
                }

                // add the tilemap to the demo controller stack...
                demoController.addTilemap(url: relativeURL, at: currentMapIndex)
            }

        } else {
            Logger.default.log("load cancelled", level: .info)
        }
    }

    /// Action to reload the current scene.
    ///
    /// - Parameter sender: invoking ui element.
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

        if let identifier = UInt8(idstring) {
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

        // TODO: SpriteKit Inspector
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

        // NYI: This is for the Inspector
        NotificationCenter.default.post(
            name: Notification.Name.Globals.Updated,
            object: nil,
            userInfo: ["objectColor": newColor]
        )

        self.initializeDebugColorsMenu()
    }

    @IBAction func tilemapGridColorUpdatedAction(_ sender: NSMenuItem) {
        guard let colorString = sender.accessibilityTitle(),
              let tilemap = self.tilemap else { return }

        let newColor = SKColor(hexString: colorString)
        tilemap.gridColor = newColor
        // TODO: setting the `debugDrawOptions` value should redraw
        // tilemap.debugNode.drawGrid()
        tilemap.debugNode.draw()
        self.initializeTilemapGridColorsMenu(tilemap: tilemap)
    }

    // MARK: - Camera Handlers


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
            scene.cameraNode?.zoomClamping = newZoomClampingMode
        }
    }

    @IBAction func cameraFitToViewAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        gameController.demoController.fitSceneToView()
    }


    @IBAction func cameraResetAction(_ sender: Any) {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }

        scene.cameraNode?.panToPoint(CGPoint.zero, duration: 0.25)
    }

    /// Called when the `Use camera zoom constraints` menu item is called.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func cameraIgnoreZoomConstraintsAction(_ sender: NSMenuItem) {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene,
            let cameraNode = scene.cameraNode else { return }

        let useCameraZoomConstraints = (sender.state == .on)
        cameraNode.ignoreZoomConstraints = !useCameraZoomConstraints
        let zoomOutputString = (cameraNode.ignoreZoomConstraints == true) ? "unlocking camera zoom" : "locking camera zoom"

        Logger.default.log(zoomOutputString, level: .info, symbol: "AppDelegate")
        self.initializeSceneCameraMenu(camera: cameraNode)

        // update the demo controller global
        gameController.demoController.defaultPreferences.ignoreZoomConstraints = !useCameraZoomConstraints
        gameController.demoController.updateCommandString(zoomOutputString)
    }

    @IBAction func cameraUsePreviousCameraAction(_ sender: NSMenuItem) {
        let currentState = sender.state
        guard let gameController = viewController else { return }

        var preferences = gameController.demoController.defaultPreferences
        preferences.usePreviousCamera = (currentState == .off) ? true : false
        Logger.default.log("setting use previous camera: \(preferences.usePreviousCamera)", level: .info, symbol: "AppDelegate")
        gameController.demoController.updateCommandString("setting use previous camera: \(preferences.usePreviousCamera)")
        sender.state = (currentState == .off) ? .on : .off

    }

    /// Called when the `Camera callbacks...` menu item is called.
    ///
    /// - Parameter sender: invoking ui element.
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
            object: nil
        )

        scene.cameraNode?.enableDelegateCallbacks(nextState)
    }

    /// Called when the `Track visible nodes` menu item is called.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func cameraVisibleNodesCallbacksAction(_ sender: NSMenuItem) {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }

        let currentState: Bool = sender.state == .on
        let nextState = !currentState

        scene.cameraNode?.notifyDelegatesOnContainedNodesChange = nextState
        gameController.demoController.updateCommandString("enable camera visible node tracking: \(nextState == true ? "on" : "off")")
    }

    @IBAction func cameraStatistics(_ sender: NSMenuItem) {
        guard let gameController = viewController,
            let view = gameController.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }

        scene.cameraNode?.dumpStatistics()
    }

    // MARK: - Demo Menu

    @IBAction func showCurrentMapsAction(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.getCurrentlyLoadedTilemaps()
    }

    @IBAction func showAllAssetsAction(_ sender: Any) {
        guard let demoController = demoController else { return }
        demoController.getCurrentlyLoadedAssets()
    }

    @IBAction func getExternallyLoadedAssetsAction(_ sender: Any) {
        guard let demoController = demoController else { return }
        demoController.getExternallyLoadedAssets()
    }

    /// Called when the `Development > Demo Preferences...` menu item is selected.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func showDemoPreferencesAction(_ sender: Any) {
        guard let demoController = demoController else { return }
        demoController.defaultPreferences.dumpStatistics()
    }

    /// Called when the `Development > Demo Controller...` menu item is selected.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func showDemoControllerAttributesAction(_ sender: Any) {
        guard let gameController = viewController else {
            return
        }
        let demoController = gameController.demoController
        demoController.dumpStatistics()
    }

    /// Action for the appplication's demo maps menu items.
    ///
    /// - Parameter sender: menu item with tilemap url.
    @IBAction func demoFileSelected(_ sender: NSMenuItem) {

        /*
         demoFileMenuItem.setAccessibilityTitle("\(idx)")
         demoFileMenuItem.setAccessibilityIndex(currentFileIndex)
         demoFileMenuItem.setAccessibilityFilename(asset.relativePath)
         demoFileMenuItem.setAccessibilityValue(asset.url.path)
         demoFileMenuItem.toolTip = asset.url.path
         */

        guard let identifier = sender.accessibilityTitle(),
              let filePath = sender.accessibilityValue() as? String,
              let identifierIntValue = Int(identifier) else {
            Logger.default.log("invalid identifier: \(sender.accessibilityIdentifier())", level: .error, symbol: "AppDelegate")
            return
        }


        guard let controller = viewController else {
            return
        }

        let demoController = controller.demoController
        let demoURLs = demoController.tiledDemoUrls
        // FIXME: crash here
        let selectedURL = demoURLs[identifierIntValue]
        controller.demoController.loadScene(url: selectedURL, usePreviousCamera: false)
        controller.demoController.currentTilemapUrl = selectedURL
        Logger.default.log("loading file '\(selectedURL.relativePath)'...", level: .info, symbol: "AppDelegate")
    }


    @IBAction func loggingLevelUpdated(_ sender: NSMenuItem) {
        guard let identifier = sender.accessibilityTitle(),
            let identifierIntValue = UInt8(identifier) else {
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

    // MARK: - Map Menu

    @IBAction func mapStatisticsPressed(_ sender: Any) {
        guard let gameController = viewController else {
            return
        }
        let demoController = gameController.demoController
        demoController.dumpMapStatistics()
    }

    @IBAction func mapRenderQualityPressed(_ sender: Any) {
        guard let tilemap = self.tilemap else { return }

        var headerString = "# Tilemap '\(tilemap.url.filename)', render quality: \(tilemap.renderQuality) ( max: \(tilemap.maxRenderQuality) ):"
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

            var layerNameString = "'\(layer.layerName)'"
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
            currentBoundsMode = tilemap.debugDrawOptions.contains(.drawFrame)
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
        print("⭑ [AppDelegate]: drawing graphs action...")
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleMapGraphVisualization()

        var currentGraphMode = false
        if let tilemap = self.tilemap {
            currentGraphMode = tilemap.isShowingGridGraph
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

    @IBAction func dumpTileLayersDataAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.dumpTileLayersDataAction()
    }

    /// Called when the map isolation mode is changed.
    ///
    /// - Parameter sender: invoking UI element.
    @IBAction func islolationModeChangedAction(_ sender: NSMenuItem) {
        guard let identifier = UInt8(sender.accessibilityIdentifier()) else {
            Logger.default.log("invalid identifier: \(sender.accessibilityIdentifier())", level: .error)
            return
        }

        guard let tilemap = self.tilemap else { return }

        let newIsolationMode = TileIsolationMode(rawValue: identifier)
        Logger.default.log("new isolation mode: '\(newIsolationMode.strings)'", level: .info)
        tilemap.isolationMode = newIsolationMode


        if let gameController = viewController {
            gameController.demoController.updateCommandString("updating map isolation mode \(newIsolationMode.strings)", duration: 4)
        }
    }

    /// Called when the cache isolation mode is changed.
    ///
    /// - Parameter sender: invoking UI element.
    @IBAction func isloateCachedTilesAction(_ sender: NSMenuItem) {
        guard let identifier = UInt8(sender.accessibilityIdentifier()) else {
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

    /// Called when the user adds an asset search path. Called when the `Notification.Name.Demo.NodeSelectionChanged` event fires. Nodes are accessible via the `TiledDemoDelegate.currentNodes` property.
    ///
    ///   userInfo: ["nodes": `[SKNode]`]
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionChanged(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let selectedNodes = userInfo["nodes"] as? [SKNode] else {
            return
        }

        selectedNodesMenuItem.title = (selectedNodes.count > 1) ? "Selected Nodes" : "Selected Node"
        selectedNodesMenuItem.isEnabled = true
        selectedNodesMenuItem.submenu?.removeAllItems()
        for node in selectedNodes {

            if let tiledNode = node as? TiledCustomReflectableType {
                if let tiledDescription = tiledNode.tiledListDescription {
                    let nodeMenuItem = NSMenuItem(title: "\(tiledDescription)", action: #selector(selectedNodeAction), keyEquivalent: "")
                    selectedNodesMenuItem.submenu?.addItem(nodeMenuItem)
                } else {
                    Logger.default.log("cannot get tiled description for '\(node.description)'", level: .error, symbol: "AppDelegate")
                }
            }
        }
    }


    /// Called when the user has cleared the demo scene selected nodes. Called when the `Notification.Name.Demo.NodesAboutToBeSelected` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionClearedAction(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)
        selectedNodesMenuItem.submenu?.removeAllItems()
        selectedNodesMenuItem.isEnabled = false
        selectedNodesMenuItem.title = "Selected Nodes"
    }

    @IBAction func selectedNodeAction(_ sender: NSMenuItem) {
        print("[AppDelegate]: node selected: '\(sender.title)'")
    }

    // MARK: - Callbacks & Helpers

    @IBAction func tilemapUpdateGlobalChanged(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController


        guard let identifier = UInt8(sender.accessibilityIdentifier()) else {
            Logger.default.log("invalid identifier: \(sender.accessibilityIdentifier())", level: .error)
            return
        }

        if (TileUpdateMode.init(rawValue: identifier) != nil) {
            demoController.updateTileUpdateMode(value: identifier)
        }
    }

    /// Callback to update the UI whenever the tilemap update mode changes.
    ///
    /// - Parameter sender: invoking ui element.
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

    /// Update the render stats menu when the controller's  time format changes.
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

    /// Send a command to the UI to update status.
    ///
    /// - Parameters:
    ///   - command: command string.
    ///   - duration: how long the message should be displayed (0 is indefinite).
    public func updateCommandString(_ command: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {

            NotificationCenter.default.post(
                name: Notification.Name.Debug.DebuggingCommandSent,
                object: nil,
                userInfo: ["command": command, "duration": duration]
            )
        }
    }

    // MARK: Show/Hide Render Stats

    @objc func renderStatisticsVisibilityChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        if let nextState = notification.userInfo!["showRenderStats"] as? Bool {
            renderStatisticsMenuItem.state = (nextState == false) ? .off : .on
        }
    }


    // MARK: - Globals

    /// Called when the Tiled globals are updated. Called when the `Notification.Name.Globals.Updated` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func globalsUpdatedAction(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        self.initializeLoggingLevelMenu()
        self.updateRenderStatsTimeFormatMenu()

        self.cameraCallbacksMenuItem.state = (TiledGlobals.default.enableCameraCallbacks == true) ? .on : .off
        self.cameraTrackVisibleNodesItem.state = (TiledGlobals.default.enableCameraContainedNodesCallbacks == true) ? .on : .off
    }

    @objc func sceneCameraUpdated(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let camera = notification.object as? SKTiledSceneCamera else {
            return
        }
        self.initializeSceneCameraMenu(camera: camera)
    }
}


// MARK: Submenu Initialization


extension AppDelegate {

    // MARK: - Demo Properties

    /// Reference to the current view controller.
    var viewController: GameViewController? {
        if let window = NSApplication.shared.mainWindow {
            if let controller = window.contentViewController as? GameViewController {
                return controller
            }
        }
        return nil
    }

    /// Reference to the current demo controller.
    var demoController: TiledDemoController? {
        return viewController?.demoController
    }

    /// Reference to the current demo delegate.
    var demoDelegate: TiledDemoDelegate? {
        return viewController?.demoDelegate
    }

    /// Reference to the current scene (if it exists).
    var scene: SKTiledDemoScene? {
        guard let gameController = viewController,
              let view = gameController.view as? SKView,
              let scene = view.scene as? SKTiledDemoScene else {
            return nil
        }
        return scene
    }

    /// Reference to the current scene's tilemap.
    var tilemap: SKTilemap? {
        guard let gameController = viewController,
              let view = gameController.view as? SKView,
              let viewScene = view.scene as? SKTiledScene else {
            return nil
        }
        return viewScene.tilemap
    }


    // MARK: - File Menu

    /// Dynamically build the `File > Current maps` submenu.
    @objc func initializeDemoFilesMenu() {
        guard let demoController = demoController else {
            Logger.default.log("cannot access demo controller.", level: .warning, symbol: "AppDelegate")
            return
        }

        // update the loaded demo files menu
        var currentFileIndex = 0

        if let demoFilesSubmenu = demoFilesMenu.submenu {
            demoFilesSubmenu.removeAllItems()


            let currentlyLoadedTilemaps = demoController.tilemaps

            var userIndexStart = 0
            for asset in currentlyLoadedTilemaps {
                if (asset.isUserAsset == false) {
                    userIndexStart += 1
                }
            }


            let enableFilesMenu = currentlyLoadedTilemaps.count > 0

            demoFilesMenu.isEnabled = enableFilesMenu


            for (idx, asset) in currentlyLoadedTilemaps.enumerated() {

                if (userIndexStart == idx) {
                    demoFilesSubmenu.addItem(NSMenuItem.separator())
                }

                let demoFileMenuItem = NSMenuItem(title: asset.filename, action: #selector(demoFileSelected(_:)), keyEquivalent: "")
                demoFileMenuItem.setAccessibilityTitle("\(idx)")
                demoFileMenuItem.setAccessibilityIndex(currentFileIndex)
                demoFileMenuItem.setAccessibilityFilename(asset.relativePath)
                demoFileMenuItem.setAccessibilityValue(asset.url.path)
                demoFileMenuItem.toolTip = asset.url.path

                demoFileMenuItem.state = (asset.url == demoController.currentTilemapUrl) ? .on : .off
                demoFilesSubmenu.addItem(demoFileMenuItem)

                currentFileIndex += 1
            }
        }
    }

    // MARK: - Logging Level Menu

    @objc func initializeLoggingLevelMenu() {
        loggingLevelMenuItem.isEnabled = true
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
        mouseFiltersMenuItem.isEnabled = true
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
        objectColorsMenuItem.isEnabled = true
        tileColorsMenuItem.isEnabled = true
        let allColors = TiledObjectColors.all
        let colorNames = TiledObjectColors.names

        let currentTileColor = TiledGlobals.default.debug.tileHighlightColor
        let currentObjectColor = TiledGlobals.default.debug.objectHighlightColor

        // create the tile colors menu
        if let tileColorsSubMenu = tileColorsMenuItem.submenu {
            tileColorsSubMenu.removeAllItems()

            for (idx, color) in allColors.enumerated() {

                let colorName = colorNames[idx]

                // create the menu item
                let tileColorMenuItem = NSMenuItem(title: "\(colorName.uppercaseFirst)", action: #selector(tileColorsUpdatedAction), keyEquivalent: "")
                let tileColorSwatch = NSImage(size: NSSize(width: 16, height: 16), flipped: false, drawingHandler: { rect in
                    let insetRect = NSInsetRect(rect, 0.5, 0.5)
                    let path = NSBezierPath(ovalIn: insetRect)
                    let fillColor = NSColor(hexString: color.hexString())
                    let strokeColor = fillColor.shadow(withLevel: 0.5)
                    fillColor.setFill()
                    path.fill()

                    strokeColor?.setStroke()
                    path.stroke()
                    return true
                })

                tileColorMenuItem.image = tileColorSwatch

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

                let objectColorSwatch = NSImage(size: NSSize(width: 16, height: 16), flipped: false, drawingHandler: { rect in
                    let insetRect = NSInsetRect(rect, 0.5, 0.5)
                    let path = NSBezierPath(ovalIn: insetRect)
                    let fillColor = NSColor(hexString: color.hexString())
                    let strokeColor = fillColor.shadow(withLevel: 0.5)
                    fillColor.setFill()
                    path.fill()

                    strokeColor?.setStroke()
                    path.stroke()
                    return true
                })

                objectColorMenuItem.image = objectColorSwatch
                objectColorMenuItem.setAccessibilityTitle("\(color.hexString())")

                objectColorMenuItem.state = (color == currentObjectColor) ? NSControl.StateValue.on : NSControl.StateValue.off
                objectColorsSubMenu.addItem(objectColorMenuItem)
            }
        }
    }

    @objc func initializeTilemapGridColorsMenu(tilemap: SKTilemap) {

        let currentGridColor = tilemap.gridColor

        if let mapGridColorSubmenu = mapGridColorMenu.submenu {
            mapGridColorSubmenu.removeAllItems()


            let allColors = TiledObjectColors.all
            let colorNames = TiledObjectColors.names

            for (idx, color) in allColors.enumerated() {
                let colorName = colorNames[idx]

                // create the menu item
                let tileColorMenuItem = NSMenuItem(title: "\(colorName.uppercaseFirst)", action: #selector(tilemapGridColorUpdatedAction), keyEquivalent: "")


                let objectColorSwatch = NSImage(size: NSSize(width: 16, height: 16), flipped: false, drawingHandler: { rect in
                    let insetRect = NSInsetRect(rect, 0.5, 0.5)
                    let path = NSBezierPath(ovalIn: insetRect)
                    let fillColor = NSColor(hexString: color.hexString())
                    let strokeColor = fillColor.shadow(withLevel: 0.5)
                    fillColor.setFill()
                    path.fill()

                    strokeColor?.setStroke()
                    path.stroke()
                    return true
                })

                tileColorMenuItem.image = objectColorSwatch
                tileColorMenuItem.setAccessibilityTitle("\(color.hexString())")

                tileColorMenuItem.state = (color == currentGridColor) ? NSControl.StateValue.on : NSControl.StateValue.off
                mapGridColorSubmenu.addItem(tileColorMenuItem)
            }
        }
    }

    @objc func initializeSceneCameraMenu(camera: SKTiledSceneCamera) {

        cameraMainMenu.isEnabled = true
        cameraCallbacksMenuItem.isEnabled = true
        cameraTrackVisibleNodesItem.isEnabled = true
        cameraIgnoreMaxZoomMenuItem.isEnabled = true
        cameraUserPreviousMenuItem.isEnabled = true
        cameraZoomClampingMenuItem.isEnabled = true

        cameraIgnoreMaxZoomMenuItem.state = (camera.ignoreZoomConstraints == true) ? .on : .off


        // cameraCallbacksContainedMenuItem.state = (TiledGlobals.default.enableCameraContainedNodesCallbacks == true) ? .on : .off
        cameraTrackVisibleNodesItem.state = (camera.notifyDelegatesOnContainedNodesChange == true) ? .on : .off
        cameraCallbacksMenuItem.state = (TiledGlobals.default.enableCameraCallbacks == true) ? .on : .off
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
            let preferences = gameController.demoController.defaultPreferences
            cameraUserPreviousMenuItem.state = (preferences.usePreviousCamera == true) ? .on : .off
        }
    }

    // MARK: - Selected Nodes Menu

    @objc func initializeSelectedNodesMenu(tilemap: SKTilemap) {

    }


    // MARK: - Tilemap Menus

    /// Initialize tilemap menus.
    ///
    /// - Parameter tilemap: tile map object.
    @objc func initializeTilemapMenus(tilemap: SKTilemap) {

        mapMenuItem.isEnabled = true
        updateModeMenuItem.isEnabled = true
        renderEffectsMenuItem.isEnabled = true
        mapDebugDrawMenu.isEnabled = true
        mapGridColorMenu.isEnabled = true
        layerVisibilityMenu.isEnabled = true
        timeDisplayMenuItem.isEnabled = true
        layerIsolationMenu.isEnabled = true

        isolationModeMenuItem.isEnabled = true
        isolateTilesMenuItem.isEnabled = true

        // development menu items
        tilemapStatisticsMenuItem.isEnabled = true
        layerStatisticsMenuItem.isEnabled = true
        currentMapsMenuItem.isEnabled = true
        allAssetsMapsMenuItem.isEnabled = true
        externalAssetsMenuItem.isEnabled = true



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


        // map grid color menu
        initializeTilemapGridColorsMenu(tilemap: tilemap)


        if let visibilitySubmenu = layerVisibilityMenu.submenu {
            visibilitySubmenu.removeAllItems()

            // add all hidden/all visible
            let showAllMenuItem = NSMenuItem(title: "Show all", action: #selector(toggleAllLayerVisibility), keyEquivalent: "")
            showAllMenuItem.setAccessibilityIdentifier("\(1)")

            let hideAllMenuItem = NSMenuItem(title: "Hide all", action: #selector(toggleAllLayerVisibility), keyEquivalent: "")
            hideAllMenuItem.setAccessibilityIdentifier("\(0)")

            let divider = NSMenuItem.separator()
            visibilitySubmenu.addItem(showAllMenuItem)
            visibilitySubmenu.addItem(hideAllMenuItem)
            visibilitySubmenu.addItem(divider)


            for layer in tilemap.getLayers() {
                let layerMenuItem = NSMenuItem(title: layer.menuDescription, action: #selector(toggleLayerVisibility), keyEquivalent: "")
                layerMenuItem.setAccessibilityTitle(layer.uuid)
                layerMenuItem.state = (layer.visible == true) ? NSControl.StateValue.on : NSControl.StateValue.off
                visibilitySubmenu.addItem(layerMenuItem)
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


    /// Update various submenus when the tilemap has been sent via notification.
    ///
    /// - Parameter tilemap: tilemap instance.
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

    /// Creates the tilemap isolation mode menu.
    @objc func initializeIsolationModeMenu(tilemap: SKTilemap) {

        // create the mouse filter menu
        if let isolationModeSubMenu = isolationModeMenuItem.submenu {
            isolationModeSubMenu.removeAllItems()

            let allIsolationModes = Array(TileIsolationMode.all.elements())
            let allModeStrings = TileIsolationMode.all.strings

            // get the current isolation mode
            let currentIsolationMode = tilemap.isolationMode

            let isolationOffMenuItem = NSMenuItem(title: "All tile types", action: #selector(islolationModeChangedAction), keyEquivalent: "")
            isolationOffMenuItem.setAccessibilityIdentifier("\(10)")


            let isolationObjectsMenuItem = NSMenuItem(title: "All objects types", action: #selector(islolationModeChangedAction), keyEquivalent: "")
            isolationObjectsMenuItem.setAccessibilityIdentifier("\(60)")


            let divider = NSMenuItem.separator()
            isolationModeSubMenu.addItem(isolationOffMenuItem)
            isolationModeSubMenu.addItem(isolationObjectsMenuItem)
            isolationModeSubMenu.addItem(divider)



            for (index, mode) in allIsolationModes.enumerated() {
                guard (index <= allModeStrings.count - 1) else {
                    return
                }

                let isolationModeMenuItem = NSMenuItem(title: allModeStrings[index], action: #selector(islolationModeChangedAction), keyEquivalent: "")
                isolationModeMenuItem.setAccessibilityIdentifier("\(mode.rawValue)")


                isolationModeMenuItem.state = currentIsolationMode.contains(mode) ? NSControl.StateValue.on : NSControl.StateValue.off
                isolationModeSubMenu.addItem(isolationModeMenuItem)
            }
        }
    }

    /// Creates the tile data storabge isolation mode menu.
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


    // MARK: - Help Menu

    @IBAction func openWebDocumentation(_ sender: Any) {
        if let helpUrl = URL(string: "https://mfessenden.github.io/SKTiled") {
            NSWorkspace.shared.open(helpUrl)
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
