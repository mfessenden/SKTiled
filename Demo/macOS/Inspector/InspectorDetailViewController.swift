//
//  InspectorDetailViewController.swift
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
import SpriteKit


/// Governs the right panel (coordinates & attributes editor)
class InspectorDetailViewController: NSViewController {

    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var consoleOutputTextField: NSTextField!
    
    @IBOutlet weak var coordinateValue: NSTextField!
    @IBOutlet weak var scenePointValue: NSTextField!
    @IBOutlet weak var viewPointValue: NSTextField!
    @IBOutlet weak var mapPointValue: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
        resetInterface()
    }
    
    func resetInterface() {
        coordinateValue.stringValue = "--"
        scenePointValue.stringValue = "--"
        viewPointValue.stringValue = "--"
        mapPointValue.stringValue = "--"
        
        sendMessageToConsole(value: "Ready.", duration: 0)
        progressBar.isHidden = true
        
        
        // text shadow
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 1.2, height: 1.2)
        shadow.shadowColor = NSColor(calibratedWhite: 0.2, alpha: 0.6)
        shadow.shadowBlurRadius = 0.3
        consoleOutputTextField.shadow = shadow
    }
    // DebuggingMessageSent
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(mousePositionChanged), name: Notification.Name.Demo.MousePositionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneCleared), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneLoaded), name: Notification.Name.Demo.SceneLoaded, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCommandString), name: Notification.Name.Debug.DebuggingMessageSent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: NSApplication.willResignActiveNotification, object: nil)
    }
    
    // MARK: Event Handlers
    
    /// Called when the application is about to enter the background. Called when the `NSApplication.willResignActiveNotification` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func applicationWillResignActive(notification: Notification) {
        resetInterface()
    }
    
    /// Called when the mouse position changes. Called when the `Notification.Name.Demo.MousePositionChanged` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func mousePositionChanged(notification: Notification) {
        guard let locationData = notification.userInfo as? [String: Any] else {
            return
        }
        
        
        // keys: `viewPosition`,`screenPosition`, `worldPosition`, `mapPosition`
        if let mapPosition = locationData["mapPosition"] as? CGPoint {
            mapPointValue.stringValue = mapPosition.shortDescription
        }
        
        if let viewPosition = locationData["viewPosition"] as? CGPoint {
            viewPointValue.stringValue = viewPosition.shortDescription
        }
        
        if let screenPosition = locationData["screenPosition"] as? CGPoint {
            scenePointValue.stringValue = screenPosition.shortDescription
        }
        
        
        if let mapCoordinate = locationData["coordinate"] as? simd_int2 {
            let coordStringValue = mapCoordinate.shortDescription
            
            var fontColor = SKColor.white
            if let isValidCoord = locationData["coordIsValid"] as? Bool {
                fontColor = (isValidCoord == true) ? SKColor.green : SKColor.red
            }
            
            var colorAttributes = [.foregroundColor: fontColor] as [NSAttributedString.Key: Any]
            let attributedString = NSAttributedString(string: coordStringValue, attributes: colorAttributes)
            coordinateValue.attributedStringValue = attributedString
        }
    }
    
    /// Called when a new scene has been loaded. Called when the `Notification.Name.Demo.SceneLoaded` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneLoaded(notification: Notification) {
        notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any] else {
            fatalError("no user info!")
        }

        // `tilemapName`, `relativePath`, `currentMapIndex`
        if let mapRelativePath = userInfo["relativePath"] as? String {
            sendMessageToConsole(value: "Map loaded from '\(mapRelativePath)'.", duration: 3)
        }
        
        
        //resetInterface()
        progressBar.isHidden = true
    }
    
    /// Called when the current scene has been cleared. Called when the `Notification.Name.Demo.SceneWillUnload` event fires.
    ///
    ///  userInfo: ["tilemapName", "relativePath", "currentMapIndex"]
    ///  
    /// - Parameter notification: event notification.
    @objc func demoSceneCleared(notification: Notification) {
        resetInterface()
        progressBar.isHidden = false
        progressBar.startAnimation(nil)
        sendMessageToConsole(value: "Clearing scene...")
    }
    
    /// Called when the current scene has been cleared. Called when the `Notification.Name.Demo.SceneWillUnload` event fires.
    ///
    ///  userInfo: ["command", "duration""]
    ///
    /// - Parameter notification: event notification.
    @objc func updateCommandString(notification: Notification) {
        var duration: TimeInterval = 0
        if let commandDuration = notification.userInfo!["duration"] {
            if let durationValue = commandDuration as? TimeInterval {
                duration = durationValue
            }
        }
        
        
        if let commandString = notification.userInfo!["command"] {
            let commandFormatted = commandString as! String
            sendMessageToConsole(value: commandFormatted, duration: duration)
        }
    }
    
    // MARK: - Overrides
    override func keyDown(with event: NSEvent) {
        handleKeyboardEvent(eventKey: event.keyCode)
    }
    

    
    // MARK: - Helpers
    
    func sendMessageToConsole(value: String, duration: TimeInterval = 0, defaultValue: String = "Ready.") {
        let isAnimated = duration > 0
        //consoleOutputTextField.setStringValue(value, animated: isAnimated, interval: duration)
        consoleOutputTextField.stringValue = "➤ \(value)"
        
        if (duration > 0) {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
                self.consoleOutputTextField.stringValue = "➤ \(defaultValue)"
            })
        }
    }
    
    func updateEditorForNodeTypes(_ types: [String]) {
        //iconViewController = storyboard!.instantiateController(withIdentifier: "IconViewController") as? IconViewController
    }
    
    func handleKeyboardEvent(eventKey: UInt16) {
        
        // '→' advances to the next scene
        if eventKey == 0x7c {
            sendMessageToConsole(value: "Loading next scene...")
        }
    }
}
