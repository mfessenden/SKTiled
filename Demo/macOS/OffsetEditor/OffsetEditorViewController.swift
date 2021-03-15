//
//  OffsetEditorViewController.swift
//  SKTiled Demo - macOS
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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

/*
 offset-layertype-menu
 layer-offsetx-field
 layer-offsety-field
 */


let layerTypes = ["none", "all", "tile", "object", "group", "image"]


class OffsetEditorViewController: NSViewController {
    
    let demoController = TiledDemoController.default
    let demoDelegate = TiledDemoDelegate.default
    
    @IBOutlet var editorView: NSView!
    @IBOutlet weak var layerTypeMenu: NSPopUpButton!
    @IBOutlet weak var confirmButton: NSButton!
    
    var textFields:  [String: NSTextField] = [:]
    var checkBoxes:  [String: NSButton] = [:]
    var popupMenus:  [String: NSPopUpButton] = [:]
    
    var selectedLayerType: String = "none"
    
    /// Reference to the demo delegate current nodes.
    var focusedNodes: [SKNode] {
        return Array(demoDelegate.focusedNodes)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.setFrameSize(NSSize(width: 350, height: 250))
        
        setupNotifications()
        setupInterface()
        resetInterface(enabled: true)
        
        // load prefs from defaults
        let defaults = UserDefaults.shared
        if (defaults.value(forKey: "tiled-demo-offsets-lastlayertype") != nil) {
            selectedLayerType = defaults.string(forKey: "tiled-demo-offsets-lastlayertype")!
        }
        
        if (demoDelegate.focusedNodes.isEmpty == false) {
            populateInterface()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneLoaded, object: nil)
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneLoaded), name: Notification.Name.Demo.SceneLoaded, object: nil)
    }
    
    /// Resets the main interface.
    ///
    /// - Parameter enabled: enable/disable the widgets.
    func resetInterface(enabled: Bool = false) {
        for (_, textfield) in textFields.enumerated() {
            textfield.value.isEnabled = enabled
            
            if (enabled == false) {
                textfield.value.reset()
                textfield.value.focusRingType = .none
            }
        }
        
        for (_, checkbox) in checkBoxes.enumerated() {
            checkbox.value.isEnabled = enabled
            checkbox.value.state = .off
        }
        
        for (_, menu) in popupMenus.enumerated() {
            menu.value.isEnabled = enabled
        }
    }
    
    /// Initialize the editor UI. This method parses values from the storyboard and allows easy recall of UI widgets.
    func setupInterface() {
        
        /// map the current ui elements
        for subview in NSView.getAllSubviews(from: editorView) {
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
                    textField.focusRingType = .none
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
        
        
        let layerTypesMenu = popupMenus["offset-layertype-menu"]
        layerTypesMenu?.addItems(withTitles: layerTypes)
        let lastMenuItem = layerTypesMenu?.item(withTitle: selectedLayerType)
        layerTypesMenu?.select(lastMenuItem)
    }
    
    /// Redraw the interface to reflect the currently focused node(s).
    func populateInterface() {
        
        let defaults = UserDefaults.shared
        
        var lastUserSelectedLayerType = selectedLayerType
        if (defaults.value(forKey: "tiled-demo-offsets-lastlayertype") != nil) {
            lastUserSelectedLayerType = defaults.string(forKey: "tiled-demo-offsets-lastlayertype")!
        }
        
        let layerTypesMenu = popupMenus["offset-layertype-menu"]
        let lastMenuItem = layerTypesMenu?.item(withTitle: lastUserSelectedLayerType)
        layerTypesMenu?.select(lastMenuItem)
        
        
        let offsetXTextField = textFields["layer-offsetx-field"]
        let offsetYTextField = textFields["layer-offsety-field"]
        
        
        layerTypesMenu?.isEnabled = true
        offsetXTextField?.isEnabled = true
        offsetYTextField?.isEnabled = true
        
        
        offsetXTextField?.stringValue = "0"
        offsetYTextField?.stringValue = "0"
    }
    
    /// Called when the node selection has changed.
    func handleNodeSelection() {
        populateInterface()
    }
    
    func getLayers() -> [TiledLayerObject]? {
        guard let tilemap = demoController.currentTilemap else {
            return nil
        }
        
        return tilemap.getLayers(of: selectedLayerType)
    }
    
    // MARK: - Event Handlers

    
    /// Handles the `Notification.Name.Demo.SceneWillUnload` callback.
    ///
    ///  userInfo: `["url": URL]`
    ///
    /// - Parameter notification: event notification.
    @objc func sceneWillUnloadAction(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        resetInterface(enabled: false)
    }
    
    /// Called when the `Notification.Name.Demo.SceneLoaded` event fires.
    ///
    ///  object is `SKTiledScene`, userInfo: `["tilemapName": String, "relativePath": String, "currentMapIndex": Int]`
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneLoaded(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        resetInterface(enabled: true)
    }
    
    
    /// Called when the `Apply Offsets` button is pressed.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func applyOffsetsButtonPressedAction(_ sender: Any) {
        guard let tilemap = demoController.currentTilemap else {
            print("⭑ [Offset Editor]: cannot access tilemap.")
            return
        }
        
        
        let layerTypesMenu = popupMenus["offset-layertype-menu"]
        let offsetXTextField = textFields["layer-offsetx-field"]
        let offsetYTextField = textFields["layer-offsety-field"]
        
        guard let currentLayerTypeItem = layerTypesMenu?.selectedItem else {
            print("⭑ [Offset Editor]: nothing is selected.")
            return
        }
        
        
        let currentLayerType = currentLayerTypeItem.title
        selectedLayerType = currentLayerType
        
        guard let layersToUpdate = getLayers() else {
            print("⭑ [Offset Editor]: no layers match '\(currentLayerType)' type.")
            return
        }
        
        
        let offsetX = offsetXTextField?.floatValue ?? 0
        let offsetY = offsetYTextField?.floatValue ?? 0
        
        let layersOffset = CGPoint(x: CGFloat(offsetX), y: CGFloat(offsetY))
        
        for layer in layersToUpdate {
            layer.debugOffset = layersOffset
        }
        
        
        print("⭑ [Offset Editor]: setting offset: \(layersOffset.shortDescription)")
        
        tilemap.repositionLayers()
        
        
        // set user defaults
        let defaults = UserDefaults.shared
        defaults.set(selectedLayerType, forKey: "tiled-demo-offsets-lastlayertype")
        defaults.synchronize()
    }
    
    /// Handler for button/checkbox events.
    ///
    /// - Parameter sender: invoking ui element.
    @objc func handleButtonEvent(_ sender: NSButton) {
        if let buttonId = sender.identifier {
            let textIdentifier = buttonId.rawValue
            let buttonVal = sender.state == .on
            
            
        }
    }
}



// MARK: - Extensions



extension OffsetEditorViewController: NSTextFieldDelegate {
    
    
    //func textView(textView: NSTextView, shouldChangeTextInRange affectedCharRange: NSRange, replacementString: String) -> Bool
    
    func textField(_ textField: NSTextField, textView: NSTextView, shouldSelectCandidateAt index: Int) -> Bool {
        print("text field '\(textField.identifierString ?? "nil")', select index \(index)")
        return true
    }
    
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
        
        let floatValue: CGFloat = CGFloat(textField.floatValue)
        let textFieldDescription = (hasFormatter == true) ? "number field" : "text field"
        
        #if DEBUG
        print("⭑ [TileEditor]: \(textFieldDescription) '\(textIdentifier)', value: '\(textFieldValue)'")
        #endif
        
        switch textIdentifier {
            case "tile-globalid-field":
                guard let globalId = UInt32(textFieldValue) else {
                    print("⭑ [Offset Editor]: invalid global id value '\(textFieldValue)'")
                    return
                }
                
                for node in focusedNodes {
                    if let tile = node as? SKTile {
                        tile.globalId = globalId
                        
                        
                        NotificationCenter.default.post(
                            name: Notification.Name.Tile.TileIDChanged,
                            object: tile
                        )
                    }
                    
                    if let object = node as? SKTileObject {
                        if let tileobj = object.tile {
                            tileobj.globalId = globalId
                            
                            
                            NotificationCenter.default.post(
                                name: Notification.Name.Tile.TileIDChanged,
                                object: tileobj
                            )
                        }
                    }
                }
                
            default:
                return
        }
        
        
    }
}
