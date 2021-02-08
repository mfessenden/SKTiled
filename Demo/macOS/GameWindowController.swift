//
//  GameWindowController.swift
//  SKTiled Demo - macOS
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
        window?.acceptsMouseMovedEvents = true

        // set the default window title
        let wintitle = "\(TiledGlobals.default.windowTitle) : ~"
        window?.title = wintitle
    }

    // MARK: - Resizing

    func windowWillStartLiveResize(_ notification: Notification) {
        // Pause the scene while the window resizes if the game is active.

        if let scene = view.scene {
            // record the scene pause state
            isManuallyPaused = scene.isPaused

            // pause the scene for the resize
            scene.isPaused = true
        }
    }

    /// Tweak the window title bar when the window is resized.
    ///
    /// - Parameter notification: event notification.
    func windowDidResize(_ notification: Notification) {
        var wintitle = TiledGlobals.default.windowTitle
        if let scene = view.scene {
            scene.size = view.bounds.size

            if let sceneDelegate = scene as? TiledSceneDelegate {

                // update tracking view?
                if let tilemap = sceneDelegate.tilemap {
                    var renderSize = tilemap.sizeInPoints
                    renderSize.width *= sceneDelegate.cameraNode?.zoom ?? 1
                    renderSize.height *= sceneDelegate.cameraNode?.zoom ?? 1

                    var titleSuffix = ""
                    if let mapurl = tilemap.url {
                        titleSuffix = ": \(mapurl.lastPathComponent) - \(view.bounds.size.shortDescription)"
                    }
                    wintitle += titleSuffix
                }

                // update the camera bounds
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.setCameraBounds(bounds: view.bounds)
                }
            }
        }

        // set the window title
        window?.title = "\(wintitle)"
    }

    func windowDidEndLiveResize(_ notification: Notification) {

        var wintitle = TiledGlobals.default.windowTitle

        // Un-pause the scene when the window stops resizing if the game is active.
        if let scene = view.scene {

            if let sceneDelegate = scene as? TiledSceneDelegate {
                scene.isPaused = isManuallyPaused
                // update tracking view?
                if let tilemap = sceneDelegate.tilemap {
                    if let mapurl = tilemap.url {
                        wintitle += ": \(mapurl.lastPathComponent)"
                    }
                }
            }
        }

        // set the window title
        window?.title = "\(wintitle)"
    }

    // OS X games that use a single window for the entire game should quit when that window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}
