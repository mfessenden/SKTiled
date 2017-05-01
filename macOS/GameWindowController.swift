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
    
    // if this value is true, the tilemap was already paused when the window resize began
    var pauseManuallySet: Bool = false
    
    var view: SKView {
        let gameViewController = window!.contentViewController as! GameViewController
        return gameViewController.view as! SKView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        window?.delegate = self
    }
    
    // MARK: NSWindowDelegate
    
    func windowWillStartLiveResize(_ notification: Notification) {
        // Pause the scene while the window resizes if the game is active.
        if let scene = view.scene {
            
            pauseManuallySet = scene.isPaused
            scene.isPaused = true
            
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.bounds = view.bounds
                }
            }
        }
    }
    
    /**
     Tweak the window title bar when the window is resized.
     */
    func windowDidResize(_ notification: Notification) {
        var wintitle = "Donkey Kong"
        if let scene = view.scene {
            scene.size = view.bounds.size
            wintitle += ": view: \(Int(view.bounds.size.width)) x \(Int(view.bounds.size.height))"
            
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let tilemap = sceneDelegate.tilemap {
                    
                    //print(tilemap.calculateAccumulatedFrame().size)
                    
                    var renderSize = tilemap.renderSize
                    renderSize.width = renderSize.width * sceneDelegate.cameraNode.zoom
                    renderSize.height = renderSize.height * sceneDelegate.cameraNode.zoom
                    wintitle += " ~ map: \(Int(renderSize.width)) x \(Int(renderSize.height))"
                    
                    sceneDelegate.cameraNode.fitToView(newSize: view.bounds.size)
                }
            }
            
            if let controller = window!.contentViewController as? GameViewController {
                controller.updateWindowTitle(withString: wintitle)
            }
        }
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        // Un-pause the scene when the window stops resizing if the game is active.
        if let scene = view.scene {
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                scene.isPaused = pauseManuallySet
                
                if let tilemap = sceneDelegate.tilemap {
                    // if the tilemap is set to autosize, fit the map in the view
                    if let camera = sceneDelegate.cameraNode {
                        camera.fitToView(newSize: scene.size)
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

