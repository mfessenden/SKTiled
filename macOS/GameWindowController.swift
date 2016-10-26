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
        if let scene = view.scene as? SKTiledScene {
            if let tilemap = scene.tilemap {
                tilemap.isPaused = true
            }
        }
    }
    
    func windowDidResize(_ notification: Notification) {
        if let scene = view.scene as? SKTiledScene {
            scene.size = view.bounds.size
        }
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        // Un-pause the scene when the window stops resizing if the game is active.
        if let scene = view.scene as? SKTiledScene {
            if let tilemap = scene.tilemap {
                tilemap.isPaused = false
                
                // if the tilemap is set to autosize, fit the map in the view
                if (tilemap.autoResize == true) {
                    if let camera = scene.cameraNode {
                        camera.fitToView()
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

