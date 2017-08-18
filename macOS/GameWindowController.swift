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
            
            isManuallyPaused = scene.isPaused
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
        if let scene = view.scene {
            scene.size = view.bounds.size
            
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                
                // update tracking view?
                if let tilemap = sceneDelegate.tilemap {
                    var renderSize = tilemap.sizeInPoints
                    renderSize.width = renderSize.width * sceneDelegate.cameraNode.zoom
                    renderSize.height = renderSize.height * sceneDelegate.cameraNode.zoom
                }
                
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.bounds = view.bounds
                }
            }
        }
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        // Un-pause the scene when the window stops resizing if the game is active.
        if let scene = view.scene {
            if let _ = scene as? SKTiledSceneDelegate {
                scene.isPaused = isManuallyPaused
            }
        }
    }
    
    // OS X games that use a single window for the entire game should quit when that window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    override func mouseMoved(with event: NSEvent) {
        Logger.default.log("mouse moved", level: .info, symbol: "Window")
    }
    
    override func mouseDragged(with event: NSEvent) {
        Logger.default.log("mouse dragged", level: .info, symbol: "Window")
    }
    
    override func mouseEntered(with event: NSEvent) {
        Logger.default.log("mouse entered", level: .info, symbol: "Window")
    }
}

