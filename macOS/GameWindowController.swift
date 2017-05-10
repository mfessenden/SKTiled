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
        print("# [GameWindowController]: willStartLiveResize...")
        if let scene = view.scene {
            isManuallyPaused = scene.isPaused
            scene.isPaused = true
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let tilemap = sceneDelegate.tilemap {
                    tilemap.autoResize = true
                }
            }
        }
    }
    
    func windowDidResize(_ notification: Notification) {
        let viewSize = view.bounds.size
        if let scene = view.scene {
            scene.size = viewSize
        }
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        // Un-pause the scene when the window stops resizing if the game is active.
        print("# [GameWindowController]: windowDidEndLiveResize...")
        if let scene = view.scene  {
            //scene.size = view.bounds.size
            scene.isPaused = isManuallyPaused
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let tilemap = sceneDelegate.tilemap {
                    //tilemap.isPaused = false
                    tilemap.autoResize = false
                }
            }
        }
    }
    
    // OS X games that use a single window for the entire game should quit when that window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}

