//
//  InspectorMainWindowController.swift
//  SKTiled Demo - macOS
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import Cocoa


class InspectorMainWindowController: NSWindowController, NSWindowDelegate {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        setupNotifications()
        resetInterface()
        
        window?.level = NSWindow.Level.normal // (rawValue: NSWindow.Level.normal.rawValue - 1)
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneCleared), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneLoaded), name: Notification.Name.Demo.SceneLoaded, object: nil)
    }
    
    /// Reset the main interface.
    func resetInterface() {
        var wintitle = " (no scene)"
        if let currentUrl = TiledDemoController.default.currentTilemapUrl {
            wintitle = ": \(currentUrl.relativePath)"
        }
        window?.title = "Scene Inspector\(wintitle)"
    }

    /// Called when the current scene has been cleared. Called when the `Notification.Name.Demo.SceneWillUnload` event fires.
    ///
    ///  userInfo: ["tilemapName", "relativePath", "currentMapIndex"]
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneCleared(notification: Notification) {
        window?.title = "Scene Inspector (no scene)"
    }
    
    /// Called when a new scene has been loaded. Called when the `Notification.Name.Demo.SceneLoaded` event fires.
    ///
    ///  object: `SKTiledScene`
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneLoaded(notification: Notification) {
        guard let _ = notification.object as? SKTiledScene else {
            return
        }
        resetInterface()
    }
    
    func windowDidResize(_ notification: Notification) {
        guard let panel = notification.object as? NSPanel else {
            return
        }
        
        
        if let mainViewController = contentViewController as? InspectorMainSplitViewController {
            mainViewController.resizeInterface(for: panel.frame.size)
        }
    }
}



// MARK: - Extensions


extension InspectorMainWindowController {
    
    /// Handler for key press events.
    ///
    /// - Parameter event: <#event description#>
    override func keyDown(with event: NSEvent) {
        let eventKey = event.keyCode
        
        guard let keysPressed = event.characters else {
            return
        }
        
        
        print("⭑ [\(classNiceName)]: key pressed '\(keysPressed)'")
        
        // 'p' dumps the attr editor ui
        if (eventKey == 0x23) {
            // call back to the demo controller
            NotificationCenter.default.post(
                name: Notification.Name.Debug.DumpAttributeEditor,
                object: nil
            )
            return
        }
        
        // 'q' selects a custom value from the outline view
        if (eventKey == 0xc) {

        }
        
        
        // '→' advances to the next scene
        if eventKey == 0x7c {
            // call back to the demo controller
            NotificationCenter.default.post(
                name: Notification.Name.DemoController.LoadNextScene,
                object: nil
            )
            return
        }
        
        // '←' loads the previous scene
        if eventKey == 0x7B {
            // call back to the demo controller
            NotificationCenter.default.post(
                name: Notification.Name.DemoController.LoadPreviousScene,
                object: nil
            )
            return
        }
    }
}



extension InspectorMainWindowController {
    
    /// Select an index from the scene graph view.
    ///
    /// - Parameter index: node index.
    func selectFromOutlineView(index: Int) {
        guard let mainViewController = window?.contentViewController as? InspectorMainSplitViewController else {
            fatalError("cannot access main vie controller.")
        }
        
        guard let outlineViewController = mainViewController.splitViewItems.first?.viewController as? InspectorTreeViewController,
              let outlineView = outlineViewController.outlineView else {
            fatalError("no outline view")
        }
        
        let node = outlineView.item(atRow: index)
        print("✻ node \(node) at index \(index)")
    }
}
