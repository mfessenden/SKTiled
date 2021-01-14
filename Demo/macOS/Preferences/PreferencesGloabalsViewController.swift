//
//  PreferencesGloabalsViewController.swift
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


/* Issues
 - globals `show objects` isn't useful
 - `render effects` is used on the tilemap node & demo prefs
 
 
 TiledGlobals.default.renderQuality.default = CGFloat(preferences.renderQuality)
 TiledGlobals.default.renderQuality.object = CGFloat(preferences.objectRenderQuality)
 TiledGlobals.default.renderQuality.text = CGFloat(preferences.textRenderQuality)
 TiledGlobals.default.enableRenderCallbacks = preferences.renderCallbacks
 TiledGlobals.default.enableCameraCallbacks = preferences.cameraCallbacks
 TiledGlobals.default.enableCameraContainedNodesCallbacks = preferences.cameraTrackContainedNodes
 
 
 */



class PreferencesGloabalsViewController: NSViewController {
    
    let demoController = TiledDemoController.default
    
    @IBOutlet var globalsView: NSView!
    
    var textFields:  [String: NSTextField] = [:]
    var checkBoxes:  [String: NSButton] = [:]
    var popupMenus:  [String: NSPopUpButton] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        setupInterface()
        populateInterface()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Camera.Updated, object: nil)
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.DefaultsRead, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cameraWasUpdated), name: Notification.Name.Camera.Updated, object: nil)
    }
    
    /// Initialize the attributes editor. This method parses values from the storyboard and allows easy recall of UI widgets.
    func setupInterface() {
        
        /// map the current ui elements
        for subview in NSView.getAllSubviews(from: globalsView) {
            let viewId: String? = (subview.identifier != nil) ? subview.identifier!.rawValue : nil
            
            /// is this a node type we want to save?
            var isAttributeType = false
            
            if let viewIdentifier = viewId {
                if (viewIdentifier.hasPrefix("_") == false) {
                    isAttributeType = true
                }
            }
            
            if (isAttributeType == true) {
                guard let itemIdentifier = viewId else {
                    continue
                }
                
                
                if let textField = subview as? NSTextField {
                    textField.delegate = self
                    textField.reset()
                    textFields[itemIdentifier] = textField
                }
                
                if let button = subview as? NSButton {
                    button.target = self
                    button.action = #selector(self.handleButtonEvent(_:))
                    checkBoxes[itemIdentifier] = button
                }
                
                if let popupMenu = subview as? NSPopUpButton {
                    popupMenus[itemIdentifier] = popupMenu
                }
            }
        }
        
        initializeLoggingLevelMenu()
    }
    
    func populateInterface() {
        //String(format: "%.2f", renderTime)
        textFields["glb-renderquality-field"]?.stringValue = String(format: "%.2f", TiledGlobals.default.renderQuality.default)
        textFields["glb-textrenderquality-field"]?.stringValue = String(format: "%.2f", TiledGlobals.default.renderQuality.text)
        textFields["glb-objrenderquality-field"]?.stringValue = String(format: "%.2f", TiledGlobals.default.renderQuality.object)
        textFields["glb-renderqualityoverride-field"]?.stringValue = String(format: "%.2f", TiledGlobals.default.renderQuality.override)
        textFields["glb-linewidth-field"]?.stringValue = String(format: "%.2f", TiledGlobals.default.debug.lineWidth)
        
               
        checkBoxes["gbl-rendercb-check"]?.state = (TiledGlobals.default.enableRenderCallbacks == true) ? .on : .off
        checkBoxes["gbl-cameracb-check"]?.state = (TiledGlobals.default.enableCameraCallbacks == true) ? .on : .off
        
        // user/demo maps
        checkBoxes["gbl-allowusermaps-check"]?.state = (TiledGlobals.default.allowUserMaps == true) ? .on : .off
        checkBoxes["gbl-mouseenvents-check"]?.state = (TiledGlobals.default.enableMouseEvents == true) ? .on : .off
        
        
        let loggingLevelMenu = popupMenus["glb-logging-menu"]
        
        
        // Tilemap
        var showObjectsValue = demoController.defaultPreferences.showObjects
        var drawGridValue = demoController.defaultPreferences.drawGrid
        var shouldEnableEffects = demoController.defaultPreferences.enableEffects
        var drawGraphsValue = false
        
        if let tilemap = demoController.currentTilemap {
            shouldEnableEffects = tilemap.shouldEnableEffects
            showObjectsValue = tilemap.isShowingObjectBounds
            drawGridValue = tilemap.isShowingTileGrid
            drawGraphsValue = tilemap.isShowingGridGraph
        }
        
        checkBoxes["gbl-effects-check"]?.state = (shouldEnableEffects == true) ? .on : .off
        checkBoxes["gbl-showobjects-check"]?.state = (showObjectsValue == true) ? .on : .off
        checkBoxes["gbl-showgrid-check"]?.state = (drawGridValue == true) ? .on : .off
        checkBoxes["gbl-showgraphs-check"]?.state = (drawGraphsValue == true) ? .on : .off
        
        // Camera
        var ignoreZoomConstraints = false
        var trackCameraContainedNodes = TiledGlobals.default.enableCameraContainedNodesCallbacks
        
        if let camera = demoController.camera {
            ignoreZoomConstraints = camera.ignoreZoomConstraints
            trackCameraContainedNodes = camera.notifyDelegatesOnContainedNodesChange
        }
        
        checkBoxes["gbl-ignorezoom-check"]?.state = (ignoreZoomConstraints == true) ? .on : .off
        checkBoxes["gbl-trackcameranodes-check"]?.state = (trackCameraContainedNodes == true) ? .on : .off
        checkBoxes["gbl-mouseevents-check"]?.state = (TiledGlobals.default.enableMouseEvents == true) ? .on : .off


        loggingLevelMenu?.removeAllItems()
        
        
        if let loggingMenu = loggingLevelMenu?.menu {
            loggingMenu.removeAllItems()
            
            let allLoggingLevels = LoggingLevel.all
            
            for loggingLevel in allLoggingLevels {
                guard (loggingLevel != LoggingLevel.none) && (loggingLevel != LoggingLevel.custom) else {
                    continue
                }
                
                let levelMenuItem = NSMenuItem(title: loggingLevel.description.uppercaseFirst, action: #selector(loggingLevelUpdated(_:)), keyEquivalent: "")
                levelMenuItem.setAccessibilityTitle("\(loggingLevel.rawValue)")
                levelMenuItem.state = (TiledGlobals.default.loggingLevel == loggingLevel) ? .on : .off
                
                if (levelMenuItem.state == .on) {
                    //print("⭑ [Preferences]: current logging level '\(loggingLevel)'")
                }
                
                loggingMenu.addItem(levelMenuItem)
            }
        }
    }
    
    // MARK: - Event Handlers
    
    /// Handler for button/checkbox events.
    ///
    /// - Parameter sender: invoking UI element.
    @objc func handleButtonEvent(_ sender: NSButton) {
        if let bid = sender.identifier {
            let textIdentifier = bid.rawValue
            let buttonVal = sender.state == .on
            print("⭑ [Preferences]: button changed: '\(textIdentifier)', value: \(buttonVal)")
            
            if (textIdentifier == "gbl-showobjects-check") {
                if (buttonVal == true) {
                    demoController.currentTilemap?.debugDrawOptions.update(with: .drawObjectFrames)
                } else {
                    demoController.currentTilemap?.debugDrawOptions.subtract(.drawObjectFrames)
                }
            }
            
            if (textIdentifier == "gbl-showgrid-check") {
                if (buttonVal == true) {
                    demoController.currentTilemap?.debugDrawOptions.update(with: .drawGrid)
                } else {
                    demoController.currentTilemap?.debugDrawOptions.subtract(.drawGrid)
                }
            }
            
            if (textIdentifier == "gbl-showgraphs-check") {
                if (buttonVal == true) {
                    demoController.currentTilemap?.debugDrawOptions.update(with: .drawGraph)
                } else {
                    demoController.currentTilemap?.debugDrawOptions.subtract(.drawGraph)
                }
                
                demoController.toggleMapGraphVisualization()
            }
            
            if (textIdentifier == "gbl-effects-check") {
                guard let tilemap = demoController.currentTilemap else {
                    return
                }
                
                tilemap.shouldEnableEffects = buttonVal
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Map.Updated,
                    object: tilemap
                )
            }
            
            if (textIdentifier == "gbl-rendercb-check") {
                TiledGlobals.default.enableRenderCallbacks = buttonVal
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
            
            if (textIdentifier == "gbl-cameracb-check") {
                TiledGlobals.default.enableCameraCallbacks = buttonVal
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
            
            
            if (textIdentifier == "gbl-resetglobals-button") {
                TiledGlobals.default.resetUserDefaults()
            }
            
            
            guard let camera = demoController.camera else {
                return
            }
            
            
            if (textIdentifier == "gbl-ignorezoom-check") {
                camera.ignoreZoomConstraints = buttonVal
                
                NotificationCenter.default.post(
                    name: Notification.Name.Camera.Updated,
                    object: camera
                )
            }
            
            if (textIdentifier == "gbl-trackcameranodes-check") {
                camera.notifyDelegatesOnContainedNodesChange = buttonVal
                
                NotificationCenter.default.post(
                    name: Notification.Name.Camera.Updated,
                    object: camera
                )
            }
            
            if (textIdentifier == "gbl-mouseenvents-check") {
                TiledGlobals.default.enableMouseEvents = buttonVal
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
            
            
            if (textIdentifier == "gbl-allowusermaps-check") {
                
                TiledGlobals.default.allowUserMaps = buttonVal
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
            
            
            if (textIdentifier == "gbl-allowdemomaps-check") {
                
                TiledGlobals.default.allowDemoMaps = buttonVal
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
        }
    }
    
    @objc func initializeLoggingLevelMenu() {
        guard let loggingLevelMenuButton = popupMenus["glb-logging-menu"] else {
            fatalError("cannot access menu with identifier 'glb-logging-menu'.")
        }
        
        loggingLevelMenuButton.isEnabled = false
        var indexToSelect = -1
        
        // update the logging menu
        if let loggingLevelMenu = loggingLevelMenuButton.menu {
            
            // nsmenu
            loggingLevelMenu.removeAllItems()
            
            
            let allLoggingLevels = LoggingLevel.all
            
            for (idx, loggingLevel) in allLoggingLevels.enumerated() {
                guard (loggingLevel != LoggingLevel.none) && (loggingLevel != LoggingLevel.custom) else { continue }
                
                let levelMenuItem = NSMenuItem(title: loggingLevel.description.uppercaseFirst, action: #selector(loggingLevelUpdated(_:)), keyEquivalent: "")
                levelMenuItem.setAccessibilityTitle("\(loggingLevel.rawValue)")
                
                let isCurrentIndex = TiledGlobals.default.loggingLevel == loggingLevel
                
                if (isCurrentIndex == true) {
                    indexToSelect = idx
                }
                
                levelMenuItem.state = (isCurrentIndex == true) ? .on : .off
                loggingLevelMenu.addItem(levelMenuItem)
                
                
                if (isCurrentIndex == true) {
                    //loggingLevelMenuButton.select(levelMenuItem)
                }
            }
        }
        
        if (indexToSelect > -1) {
            loggingLevelMenuButton.selectItem(at: indexToSelect)
        }
        
        //loggingLevelMenuButton.autoenablesItems = false
        loggingLevelMenuButton.isEnabled = true
        
        let selectedTitle = loggingLevelMenuButton.selectedItem?.title ?? "nil"
        print("⭑ [Preferences]: logging menu selected: '\(selectedTitle)'")
    }
    
    @IBAction func loggingLevelUpdated(_ sender: NSMenuItem) {
        guard let identifier = sender.accessibilityTitle(),
              let identifierIntValue = UInt8(identifier) else {
            Logger.default.log("invalid logging identifier: \(sender.accessibilityIdentifier())", level: .error, symbol: "Preferences")
            return
        }
        
        if let newLoggingLevel = LoggingLevel.init(rawValue: identifierIntValue) {
            if (TiledGlobals.default.loggingLevel != newLoggingLevel) {
                TiledGlobals.default.loggingLevel = newLoggingLevel
                Logger.default.log("global logging level changed: \(newLoggingLevel)", level: .info, symbol: "Preferences")
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil,
                    userInfo: nil
                )
            }
        }
    }
    
    // MARK: - Event Handlers
    
    @objc func globalsUpdatedAction(notification: Notification) {
        populateInterface()
    }
    
    @objc func tilemapWasUpdated(notification: Notification) {
        populateInterface()
    }
    
    @objc func cameraWasUpdated(notification: Notification) {
        populateInterface()
    }
}


// MARK: - Extensions


extension PreferencesGloabalsViewController: NSTextFieldDelegate {
    
    /// Called when the text field edititing is finished.
    ///
    /// - Parameter obj: event notification.
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              let textid = textField.identifier else {
            return
        }
        
        let textIdentifier = textid.rawValue
        let textFieldValue = textField.stringValue
        let formatter = textField.formatter as? NumberFormatter
        let hasFormatter = formatter != nil
        let textFieldDescription = (hasFormatter == true) ? "number field" : "text field"

        
        print("⭑ [PreferencesGloabalsViewController]: \(textFieldDescription) '\(textIdentifier)', value: '\(textFieldValue)'")
        
        if (textIdentifier == "glb-renderquality-field") {
            if let doubleValue = Double(textFieldValue) {
                TiledGlobals.default.renderQuality.default = CGFloat(doubleValue)
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
        }
        
        if (textIdentifier == "glb-objrenderquality-field") {
            if let doubleValue = Double(textFieldValue) {
                TiledGlobals.default.renderQuality.object = CGFloat(doubleValue)
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
        }
        
        if (textIdentifier == "glb-textrenderquality-field") {
            if let doubleValue = Double(textFieldValue) {
                TiledGlobals.default.renderQuality.text = CGFloat(doubleValue)
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
        }
        
        if (textIdentifier == "glb-renderqualityoverride-field") {
            if let doubleValue = Double(textFieldValue) {
                TiledGlobals.default.renderQuality.override = CGFloat(doubleValue)
                
                // update controllers
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
        }
        
        if (textIdentifier == "glb-linewidth-field") {
            if let doubleValue = Double(textFieldValue) {
                TiledGlobals.default.debug.lineWidth = CGFloat(doubleValue)
                
                // update controllers ->
                NotificationCenter.default.post(
                    name: Notification.Name.Globals.Updated,
                    object: nil
                )
            }
        }
        
    }
}
