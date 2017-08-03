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
            let splitController = window.contentViewController as! NSSplitViewController
            return splitController.splitViewItems.last!.viewController as! GameViewController
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
                
                let baseURLString = (relativeURL.baseURL == nil) ? "~" : relativeURL.baseURL!.path
                print(" ❗️app: loading: \(relativeURL.relativePath), \(baseURLString)")
                
                var currentMapIndex = gameController.demourls.count - 1
                if let mapIndex = gameController.demourls.index(of: gameController.currentURL!) {
                    currentMapIndex = Int(mapIndex) + 1
                }

                
                gameController.demourls.insert(relativeURL, at: currentMapIndex)
                gameController.loadScene(url: relativeURL, usePreviousCamera: true)
            }
            
        } else {
            print("[AppDelegate]: Load cancelled.")
        }
    }
    
}
