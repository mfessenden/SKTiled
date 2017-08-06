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
            print("[AppDelegate]: Load cancelled.")
        }
    }
}
