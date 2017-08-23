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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
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
     Write all tile layers to images on disk.
     */
    @IBAction func writeMapLayers(_ sender: Any) {
        guard let gameController = viewController else { return }
        guard let view = gameController.view as? SKView else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        guard let tilemap = scene.tilemap else { return }


        let dialog = NSOpenPanel()
        dialog.title = "Choose a location to save."
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.canCreateDirectories = true

        if (dialog.runModal() == NSModalResponseOK) {
            if let url = dialog.url {
                writeMapToFiles(tilemap: tilemap, url: url)
            }
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

    // MARK: - Logging

    func loggingLevelUpdated() {
        
    }

    @IBAction func loggingLevelDebug(_ sender: Any) {
        Logger.default.loggingLevel = .debug
    }

    @IBAction func loggingLevelInfo(_ sender: Any) {
        Logger.default.loggingLevel = .info
    }

    @IBAction func loggingLevelWarning(_ sender: Any) {
        Logger.default.loggingLevel = .warning
    }

    @IBAction func loggingLevelError(_ sender: Any) {
        Logger.default.loggingLevel = .error
    }

    @IBAction func loggingLevelCustom(_ sender: Any) {
        Logger.default.loggingLevel = .custom
    }

    @IBAction func loggingLevelSuccess(_ sender: Any) {
        Logger.default.loggingLevel = .success
    }

    @IBAction func loggingLevelDispatch(_ sender: Any) {
        Logger.default.loggingLevel = .gcd
    }

    @IBAction func mapStatisticsPressed(_ sender: Any) {
        guard let gameController = viewController else { return }

        let demoController = gameController.demoController
        demoController.printMapStatistics()
    }
}
