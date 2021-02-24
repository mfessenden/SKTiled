//
//  TileEditorViewController.swift
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
 tile-fliph-check
 tile-flipv-check
 tile-flipd-check
 */

class TileEditorViewController: NSViewController {
    
    let demoController = TiledDemoController.default
    let demoDelegate = TiledDemoDelegate.default
    var receiveCameraUpdates: Bool = true
    
    
    @IBOutlet var editorView: NSView!
    @IBOutlet weak var tileEditorGrid: NSGridView!
    
    var textFields:  [String: NSTextField] = [:]
    var checkBoxes:  [String: NSButton] = [:]
    var popupMenus:  [String: NSPopUpButton] = [:]
    
    
    /// Reference to the demo delegate current nodes.
    var currentNodes: [SKNode] {
        return Array(demoDelegate.currentNodes)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.setFrameSize(NSSize(width: 480, height: 580))
        
        setupNotifications()
        setupInterface()
        resetInterface()
        
        if (demoDelegate.currentNodes.isEmpty == false) {
            resetInterface(enabled: true)
            populateInterface()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneLoaded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tile.TileIDChanged, object: nil)
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChangedAction), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneLoaded), name: Notification.Name.Demo.SceneLoaded, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(tileClickedAction), name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileChangedAction), name: Notification.Name.Tile.TileIDChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionClearedAction), name: Notification.Name.Demo.NodeSelectionCleared, object: nil)
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
        
        //let viewTitleLabel = textFields["selected-nodes-title-field"]
        //let titleString = (enabled == false) ? "Nodes: 0" : "Nodes: \(currentNodes.count)"
        //viewTitleLabel?.stringValue = titleString
    }
    
    /// Initialize the node editor. This method parses values from the storyboard and allows easy recall of UI widgets.
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
    }
    
    /// Redraw the interface to reflect the currently focused tile.
    func populateInterface() {
        
        // text fields
        let tileLobalIdField       = textFields["tile-globalid-field"]
        let tileMaskedIdField      = textFields["tile-maskedid-field"]
        
        
        // check boxes
        let tileFlipHorizontalCheck = checkBoxes["tile-fliph-check"]
        let tileFlipVerticalCheck   = checkBoxes["tile-flipv-check"]
        let tileFlipDiagonalCheck   = checkBoxes["tile-flipd-check"]
        
        // buttons
        let isolateTileLayerButton  = checkBoxes["tile-flipd-check"]
        
        
        // reset current nodes
        tileLobalIdField?.reset()
        tileMaskedIdField?.reset()
        
        tileFlipHorizontalCheck?.state = .off
        tileFlipVerticalCheck?.state   = .off
        tileFlipDiagonalCheck?.state   = .off
        
        
        guard let firstNode = currentNodes.first else {
            return
        }
        
        
        if let tile = firstNode as? SKTile {
            
            tileLobalIdField?.stringValue = "\(tile.globalId)"
            tileMaskedIdField?.stringValue = "\(tile.maskedTileId)"
            tileMaskedIdField?.isEnabled = false
            
            
            tileFlipHorizontalCheck?.state = tile.isFlippedHorizontally == true ? .on : .off
            tileFlipVerticalCheck?.state = tile.isFlippedVertically == true ? .on : .off
            tileFlipDiagonalCheck?.state = tile.isFlippedDiagonally == true ? .on : .off
        }
        
        
        if let object = firstNode as? SKTileObject {
            if let objtile = object.tile {
                tileLobalIdField?.stringValue = "\(objtile.globalId)"
                tileMaskedIdField?.stringValue = "\(objtile.maskedTileId)"
                tileMaskedIdField?.isEnabled = false
                
                
                tileFlipHorizontalCheck?.state = objtile.isFlippedHorizontally == true ? .on : .off
                tileFlipVerticalCheck?.state = objtile.isFlippedVertically == true ? .on : .off
                tileFlipDiagonalCheck?.state = objtile.isFlippedDiagonally == true ? .on : .off
            }
        }
    }
    
    /// Called when the node selection has changed.
    func handleNodeSelection() {
        let currentNodeCount = currentNodes.count
        resetInterface(enabled: currentNodeCount > 0)
        
        // draw the attribute editor
        populateInterface()
    }
    
    
    // MARK: - Event Handlers
    
    /// Called when the `Notification.Name.Demo.NodeSelectionChanged` event fires. Nodes are accessible via the `TiledDemoDelegate.currentNodes` property.
    ///
    ///   userInfo: ["nodes": `[SKNode]`]
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionChangedAction(notification: Notification) {
        notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let selectedNodes = userInfo["nodes"] as? [SKNode] else {
            return
        }
        
        handleNodeSelection()
    }
    
    /// Called when the `Notification.Name.Demo.NodeSelectionChanged` event fires. Nodes are accessible via the `TiledDemoDelegate.currentNodes` property.
    ///
    ///   userInfo: ["nodes": `[SKNode]`]
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionClearedAction(notification: Notification) {
        notification.dump(#fileID, function: #function)
        resetInterface(enabled: false)
    }
    
    /// Called when the `Notification.Name.Demo.TileClicked` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func tileClickedAction(notification: Notification) {
        notification.dump(#fileID, function: #function)
        guard let tile = notification.object as? SKTile else {
            return
        }
        
        handleNodeSelection()
    }
    
    /// Called when the `Notification.Name.Tile.TileIDChanged` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func tileChangedAction(notification: Notification) {
        notification.dump(#fileID, function: #function)
        guard let tile = notification.object as? SKTile else {
            return
        }
        
        handleNodeSelection()
    }
    
    /// Called when the `Notification.Name.Demo.ObjectClicked` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func objectClickedAction(notification: Notification) {
        notification.dump(#fileID, function: #function)
        guard let object = notification.object as? SKTileObject else {
            return
        }
        
        handleNodeSelection()
    }
    
    /// Called when the `Notification.Name.Demo.SceneWillUnload` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func sceneWillUnloadAction(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        resetInterface(enabled: false)
    }
    
    /// Called when the `Notification.Name.Demo.SceneLoaded` event fires.
    ///
    ///   userInfo: ["nodes": `[SKNode]`]
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneLoaded(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        resetInterface(enabled: false)
    }
    
    /// Handler for button/checkbox events.
    ///
    /// - Parameter sender: invoking ui element.
    @objc func handleButtonEvent(_ sender: NSButton) {
        if let buttonId = sender.identifier {
            let textIdentifier = buttonId.rawValue
            let buttonVal = sender.state == .on
            
            var tiles: [SKTile] = []
            for node in currentNodes {
                if let tile = node as? SKTile {
                    tiles.append(tile)
                }
                
                if let object = node as? SKTileObject {
                    if let objtile = object.tile {
                        tiles.append(objtile)
                    }
                }
            }
            
            
            #if DEBUG
            print("⭑ [TileEditor]: button changed: '\(textIdentifier)', value: \(buttonVal)")
            #endif
            
            
            if (tiles.isEmpty == true) {
                return
            }
            
            
            for tile in tiles {
                
                if (textIdentifier == "tile-fliph-check") {
                    tile.isFlippedHorizontally = buttonVal
                }
                
                if (textIdentifier == "tile-flipv-check") {
                    tile.isFlippedVertically = buttonVal
                }
                
                if (textIdentifier == "tile-flipd-check") {
                    tile.isFlippedDiagonally = buttonVal
                }
                
                if (textIdentifier == "tile-isolate-layer-button") {
                    let layerToIsolate = tile.layer
                    
                    NotificationCenter.default.post(
                        name: Notification.Name.Map.LayerIsolationChanged,
                        object: layerToIsolate
                    )
                    
                    return
                }
                
                NotificationCenter.default.post(
                    name: Notification.Name.Tile.TileIDChanged,
                    object: tile
                )
                
            }
        }
    }
}



// MARK: - Extensions



extension TileEditorViewController: NSTextFieldDelegate {
    
    
    //func textView(textView: NSTextView, shouldChangeTextInRange affectedCharRange: NSRange, replacementString: String) -> Bool
    
    func textField(_ textField: NSTextField, textView: NSTextView, shouldSelectCandidateAt index: Int) -> Bool {
        print("text field \(textField.identifierString ?? "nil"), select index \(index)")
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
                    print("⭑ [TileEditor]: invalid global id value '\(textFieldValue)'")
                    return
                }
                
                for node in currentNodes {
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
