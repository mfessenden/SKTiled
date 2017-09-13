//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 10/18/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Cocoa
import SpriteKit


class GameWindowController: NSWindowController, NSWindowDelegate {

    // tilemap pause state before any window size change
    var isManuallyPaused: Bool = false
    
    var view: SKView {
        let gameViewController = window!.contentViewController as! GameViewController
        return gameViewController.view as! SKView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        window?.delegate = self
    }

    // MARK: - Resizing

    func windowWillStartLiveResize(_ notification: Notification) {
        // Pause the scene while the window resizes if the game is active.

        if let scene = view.scene {
            // record the scene pause state
            isManuallyPaused = scene.isPaused

            // pause the scene for the resize
            scene.isPaused = true

            /*
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.bounds = view.bounds
                }
            }*/
        }
    }

    /**
     Tweak the window title bar when the window is resized.
     */
    func windowDidResize(_ notification: Notification) {
        var wintitle = ""
        if let scene = view.scene {
            scene.size = view.bounds.size

            if let sceneDelegate = scene as? SKTiledSceneDelegate {

                // update tracking view?
                if let tilemap = sceneDelegate.tilemap {
                    var renderSize = tilemap.sizeInPoints
                    renderSize.width *= sceneDelegate.cameraNode.zoom
                    renderSize.height *= sceneDelegate.cameraNode.zoom


                    wintitle += "\(tilemap.url.lastPathComponent) - \(view.bounds.size.shortDescription)"
                }

                // update the camera bounds
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.bounds = view.bounds
                }
            }
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateWindowTitle"), object: nil, userInfo: ["wintitle": wintitle])
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        // Un-pause the scene when the window stops resizing if the game is active.
        if let scene = view.scene {
            if (scene as? SKTiledSceneDelegate != nil) {
                scene.isPaused = isManuallyPaused
            }
        }
    }

    // OS X games that use a single window for the entire game should quit when that window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}
