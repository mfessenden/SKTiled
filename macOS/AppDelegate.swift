//
//  AppDelegate.swift
//  SKTiled
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
    @IBOutlet weak var liveModeMenuItem: NSMenuItem!

    @IBOutlet weak var mapBoundsMenuItem: NSMenuItem!
    @IBOutlet weak var mapGridMenuItem: NSMenuItem!
    @IBOutlet weak var navigationGraphMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NotificationCenter.default.addObserver(self, selector: #selector(updateDelegateMenuItems), name: NSNotification.Name(rawValue: "updateDelegateMenuItems"), object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    var viewController: GameViewController? {
        if let window = NSApplication.shared().mainWindow {
            if let controller = window.contentViewController as? GameViewController {
                return controller
            }
        }
        return nil
    }

    var tilemap: SKTilemap? {
        guard let gameController = viewController else { return nil }
        guard let view = gameController.view as? SKView else { return nil }
        guard let scene = view.scene as? SKTiledScene else { return nil }
        return scene.tilemap
    }

    // MARK: - Loading & Saving
    /**
     Action to launch a file dialog and load map.
     */
    @IBAction func loadTilemap(_ sender: Any) {
        guard let gameController = viewController else { return }

        // open a file dialog
        let dialog = NSOpenPanel()
        dialog.title = "Choose a Tiled resource."
        dialog.allowedFileTypes = ["tmx"]

        if (dialog.runModal() == NSModalResponseOK) {

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
    @IBAction func reloadScene(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.reloadScene()
    }

    @IBAction func currentFilesPressed(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.dumpCurrentResources()
    }

    @IBAction func dumpCurrentTilemapAction(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.dumpCurrentTilemap()
    }

    // MARK: - Logging

    @IBAction func loggingLevelDebug(_ sender: NSMenuItem) {
        Logger.default.loggingLevel = .debug
    }

    @IBAction func loggingLevelInfo(_ sender: NSMenuItem) {
        Logger.default.loggingLevel = .info
    }

    @IBAction func loggingLevelWarning(_ sender: NSMenuItem) {
        Logger.default.loggingLevel = .warning
    }

    @IBAction func loggingLevelError(_ sender: NSMenuItem) {
        Logger.default.loggingLevel = .error
    }

    @IBAction func loggingLevelCustom(_ sender: NSMenuItem) {
        Logger.default.loggingLevel = .custom
    }

    @IBAction func loggingLevelSuccess(_ sender: NSMenuItem) {
        Logger.default.loggingLevel = .success
    }

    @IBAction func mapStatisticsPressed(_ sender: Any) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.printMapStatistics()
    }

    @IBAction func liveModeToggled(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        guard let view = gameController.view as? SKView else { return }
        guard let scene = view.scene as? SKTiledDemoScene else { return }
        let demoController = gameController.demoController
        let currentLiveMode = scene.liveMode
        let commandString = (currentLiveMode == true) ? "disabling live mode..." : "enabling live mode..."
        scene.liveMode = !scene.liveMode
        demoController.updateCommandString(commandString)

        sender.title = (currentLiveMode == true) ? "Live Mode: Off" : "Live Mode: On"
    }

    @IBAction func drawMapBoundsAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleMapDemoDrawBounds()

        var currentBoundsMode = false
        if let tilemap = self.tilemap {
            currentBoundsMode = tilemap.debugDrawOptions.contains(.drawBounds)
        }

        sender.title = (currentBoundsMode == true) ? "Map Bounds: Off" : "Map Bounds: On"
    }

    @IBAction func drawMapGridAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleMapDemoDrawGrid()

        var currentGridMode = false
        if let tilemap = self.tilemap {
            currentGridMode = tilemap.debugDrawOptions.contains(.drawGrid)
        }

        sender.title = (currentGridMode == true) ? "Map Grid: Off" : "Map Grid: On"
    }

    @IBAction func drawSceneGraphsAction(_ sender: NSMenuItem) {
        guard let gameController = viewController else { return }
        let demoController = gameController.demoController
        demoController.toggleMapGraphVisualization()

        var currentGraphMode = false
        if let tilemap = self.tilemap {
            currentGraphMode = tilemap.debugDrawOptions.contains(.drawGraph)
        }

        sender.title = (currentGraphMode == true) ? "Navigation Graph: Off" : "Navigation Graph: On"
    }


    func updateDelegateMenuItems(notification: Notification) {
        if let liveMode = notification.userInfo!["liveMode"] {
            liveModeMenuItem.title = (liveMode as? Bool) == true ? "Live Mode: On" : "Live Mode: Off"
        }

        if let mapBounds = notification.userInfo!["mapBounds"] {
            mapBoundsMenuItem.title = (mapBounds as? Bool) == true ? "Map Bounds: On" : "Map Bounds: Off"
        }

        if let mapGrid = notification.userInfo!["mapGrid"] {
            mapGridMenuItem.title = (mapGrid as? Bool) == true ? "Map Grid: On" : "Map Grid: Off"
        }

        if let navGraph = notification.userInfo!["navGraph"] {
            navigationGraphMenuItem.title = (navGraph as? Bool) == true ? "Navigation Graph: On" : "Navigation Graph: Off"
        }
    }
}
