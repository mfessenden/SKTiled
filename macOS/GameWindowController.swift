//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 10/18/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//  **Adapted from Apple DemoBots

import Cocoa
import SpriteKit


class GameWindowController: NSWindowController, NSWindowDelegate {
    // MARK: Properties
    
    // if this value is true, the tilemap was already paused when the window resize began
    var isManuallyPaused: Bool = false
    
    var gameViewController: GameViewController {
        let splitController = window!.contentViewController as! NSSplitViewController
        return splitController.splitViewItems.last!.viewController as! GameViewController
    }
    
    var fileListController: NSViewController {
        let splitController = window!.contentViewController as! NSSplitViewController
        return splitController.splitViewItems.first!.viewController as! NSViewController
    }
    
    var view: SKView {
        return gameViewController.view as! SKView
    }
    
    
    func populateList() {
        let fileListView = fileListController.view  // NSView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        window?.delegate = self
    }
    
    // MARK: NSWindowDelegate
    
    func windowWillStartLiveResize(_ notification: Notification) {
        // Pause the scene while the window resizes if the game is active.
        if let scene = view.scene {
            
            isManuallyPaused = scene.isPaused
            scene.isPaused = true
            
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let cameraNode = sceneDelegate.cameraNode {
                    ///cameraNode.bounds = view.bounds
                }
            }
        }
    }
    
    /**
     Tweak the window title bar when the window is resized.
     */
    func windowDidResize(_ notification: Notification) {
        if let scene = view.scene {
            scene.size = view.bounds.size
            
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                
                // update tracking view?
                
                
                if let tilemap = sceneDelegate.tilemap {

                    var renderSize = tilemap.renderSize
                    renderSize.width = renderSize.width * sceneDelegate.cameraNode.zoom
                    renderSize.height = renderSize.height * sceneDelegate.cameraNode.zoom
                    //sceneDelegate.cameraNode.fitToView(newSize: view.bounds.size)
                    
                    
                    if let controller = window!.contentViewController as? GameViewController {
                        
                        if let infoDictionary = Bundle.main.infoDictionary {
                            if let bundleName = infoDictionary[kCFBundleNameKey as String] as? String {
                                
                                let mapURL = tilemap.url ?? URL(fileURLWithPath: "")
                                let wintitle = "\(mapURL.fullPath) "
                                
                                
                                
                                controller.updateWindowTitle(withString: wintitle)
                            }
                        }
                    }
                    
                }
            }

        }
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        // Un-pause the scene when the window stops resizing if the game is active.
        if let scene = view.scene {
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                scene.isPaused = isManuallyPaused
                
                if (sceneDelegate.tilemap != nil) {
                    // if the tilemap is set to autosize, fit the map in the view
                    if let camera = sceneDelegate.cameraNode {
                        //camera.fitToView(newSize: scene.size)
                    }
                }
            }
        }
    }
    
    
    // OS X games that use a single window for the entire game should quit when that window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}

