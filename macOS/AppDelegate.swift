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
        guard let window = NSApplication.shared().mainWindow else { return }
        guard let gameController = window.contentViewController as? GameViewController else { return }
        
        let dialog = NSOpenPanel()
        dialog.title = "Choose a Tiled resource."
        dialog.allowedFileTypes = ["tmx"]
        
        if (dialog.runModal() == NSModalResponseOK) {
            let result = dialog.url
            
            if (result != nil) {
                // scan the root directory
                if let parent = result!.parent {
                    gameController.assetManager.addRoot(parent)
                }
                
                let path = result!.path
                gameController.demoFiles.append(path)
                
                let skView = gameController.view as! SKView
                let scene = SKTiledDemoScene(size: skView.bounds.size, tmxFile: path)
                scene.scaleMode = .aspectFill
                skView.presentScene(scene)
            }
        } else {
            print("Load cancelled.")
        }
    }
    
}
