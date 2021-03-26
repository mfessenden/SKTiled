//
//  InspectorAttributesViewController.swift
//  Demo-macOS
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


/// This controller governs the main attributes panel.
class InspectorAttributesViewController: NSViewController {

    let demoController = TiledDemoController.default
    let demoDelegate = TiledDemoDelegate.default

    @IBOutlet weak var attributesBox: NSBox!             // the top-level box group
    @IBOutlet weak var attributesEditorView: NSView!     // the parent view of all attribute widgets (Note: this has a scrollView just below it)
    @IBOutlet weak var rootStackView: NSStackView!

    @IBOutlet weak var attributesBoxScrollView: NSScrollView!


    var rootUIViews: [String: NSStackView] = [:]
    var textFields:  [String: NSTextField] = [:]
    var checkBoxes:  [String: NSButton] = [:]
    var imageViews:  [String: NSImageView] = [:]
    var popupMenus:  [String: NSPopUpButton] = [:]
    var colorWells:  [String: NSColorWell] = [:]
    
    
    var attributeStorage: AttributeStorage?
    
    
    /// The selected node; additionally, if there is more than one node selected, this is the first.
    var selectedNode: SKNode? {
        return focusedNodes.first
    }

    /// Reference to the demo delegate current nodes.
    var focusedNodes: [SKNode] {
        return Array(demoDelegate.focusedNodes)
    }

    /// Returns an array of demo delegate current node types.
    var currentNodeTypes: [String] {
        guard (focusedNodes.isEmpty == false) else {
            return [String]()
        }

        var result: Set<String> = ["node"]
        for node in focusedNodes {
            if let tiledNode = node as? TiledCustomReflectableType {
                
                
                var nodeElementName: String?
                var nodeElementType: String?
                
                if let elementtype = tiledNode.tiledElementName {
                    nodeElementName = elementtype
                }
                
                if let nodetype = tiledNode.tiledNodeType {
                    
                    nodeElementType = nodetype
                }
                
                
                let resultString = (nodeElementName == nil) ? (nodeElementType == nil) ? "node" : nodeElementType! : nodeElementName!
                
                result.insert(resultString)
                
            }
        }
        return Array(result)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        resetInterface()
        setupNotifications()

        // initialize the attributes editor
        initializeAttributesEditor()
        setAttributesEditorStatus(enabled: false)
        //iconViewController = storyboard!.instantiateController(withIdentifier: "IconViewController") as? IconViewController
    }

    func resetInterface() {
        attributesBox.title = "Attributes"
        for (_, item) in rootUIViews.enumerated() {
            item.value.isHidden = true
        }
    }

    func setupNotifications() {
        //NotificationCenter.default.addObserver(self, selector: #selector(mousePositionChanged), name: Notification.Name.Demo.MousePositionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetInterfaceAction), name: Notification.Name.Demo.NodesAboutToBeSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChanged), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mouseRightClickAction), name: Notification.Name.Camera.MouseRightClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dumpAttributeEditorWidgets), name: Notification.Name.Debug.DumpAttributeEditor, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(dumpAttributeStorage), name: Notification.Name.Debug.DumpAttributeStorage, object: nil)
    }


    deinit {
        // NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.MousePositionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodesAboutToBeSelected, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Camera.MouseRightClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Debug.DumpAttributeEditor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Debug.DumpAttributeStorage, object: nil)
    }

    /// Initialize the attributes editor. This method parses values from the storyboard and allows easy recall of UI widgets.
    func initializeAttributesEditor() {
        /// map the current ui elements

        let textFieldShadow = NSShadow()
        textFieldShadow.shadowOffset = NSSize(width: 1, height: 2)
        textFieldShadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 1)
        textFieldShadow.shadowBlurRadius = 0.1

        attributesBox.layer?.shadowColor = NSColor.black.cgColor
        attributesBox.layer?.shadowOffset = CGSize(width: 1, height: 2)


        for subview in NSView.getAllSubviews(from: attributesBox) {
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

                /// map stack types
                if let stackView = subview as? NSStackView {
                    rootUIViews[itemIdentifier] = stackView
                    stackView.delegate = self
                }

                if let textField = subview as? NSTextField {
                    textField.delegate = self
                    textFields[itemIdentifier] = textField
                    textField.isEnabled = textField.userEditable
                }

                if let button = subview as? NSButton {
                    button.target = self
                    button.action = #selector(self.handleButtonEvent(_:))
                    checkBoxes[itemIdentifier] = button
                }

                if let popupMenu = subview as? NSPopUpButton {
                    popupMenus[itemIdentifier] = popupMenu
                }

                if let imageView = subview as? NSImageView {
                    imageViews[itemIdentifier] = imageView
                }

                if let colorWell = subview as? NSColorWell {
                    colorWells[itemIdentifier] = colorWell
                }
            }
        }
    }


    /// Hide/Unhide the editor based on node selection. If nothing is currently selected, hide the UI.
    ///
    /// - Parameter enabled: indicates that nodes have been selected.
    func setAttributesEditorStatus(enabled: Bool = true) {
        attributesBoxScrollView.isHidden = (enabled == false)
    }

    /// Setup the interface for the given node types.
    ///
    ///  ie: ["tile", "object", "layer"]
    ///
    /// - Parameter nodetypes: array of node type strings.
    func setupAttributeEditor(for nodetypes: [String] = []) {
        var actions = ""
        let stackNames = nodetypes.map { "\($0)-stack-root" }

        // print("⭑ [AttributeEditor]: selected node types: \(nodetypes)")

        for (idx, (name, stack)) in rootUIViews.enumerated() {
            let stackIdHidden = !stackNames.contains(name)
            stack.isHidden = stackIdHidden

            if !(stackIdHidden) {
                let comma = (idx == 0) ? "" : ", "
                actions += "\(comma)'\(name)'"
            }
        }
    }

    func resetAttributeEditor() {
        for (identifier, textfield) in textFields {
            textfield.reset()

            if (identifier == "tile-frames-field") {

            }
        }

        for (_, checkbox) in checkBoxes {
            checkbox.state = .off
        }

        for (_, imageview) in imageViews {
            imageview.reset()
        }
    }

    /// Called when the node selection has changed.
    func handleNodeSelection() {
        let currentNodeCount = focusedNodes.count
        setAttributesEditorStatus(enabled: currentNodeCount > 0)

        // set the current editor
        setupAttributeEditor(for: currentNodeTypes)

        // draw the attribute editor
        populateAttributeEditor()
    }

    /// Populate the attributes editor with the current selection.
    func populateAttributeEditor() {

        // get the relevant widgets & reset them
        let nodeNameLabel = textFields["node-name-label"]           // Sprite Node:
        let nodeTypeLabel = textFields["node-type-label"]          // "GRID_DISPLAY"
        let nodeDescLabel = textFields["node-desc-field"]          // Grid visualization node.

        let nodeHiddenCheck = checkBoxes["node-hidden-check"]
        let nodePausedCheck = checkBoxes["node-paused-check"]

        let nodeNameField = textFields["node-name-field"]          // "GRID_DISPLAY" (editable)
        let nodePosXField = textFields["node-xpos-field"]
        let nodePosYField = textFields["node-ypos-field"]
        let nodeScaleXField = textFields["node-xscale-field"]
        let nodeScaleYField = textFields["node-yscale-field"]
        let nodePosZField = textFields["node-zpos-field"]
        let nodeRotZField = textFields["node-zrot-field"]
        let nodeAlphaField = textFields["node-alpha-field"]
        
        /// Sprite Types
        let spritePreview = imageViews["sprite-preview-image"]
        let spriteSizeWidthField = textFields["sprite-sizew-field"]
        let spriteSizeHeightField = textFields["sprite-sizeh-field"]
        

        /// Tile Types
        let tileSizeWidthField = textFields["tile-tilesizew-field"]
        let tileSizeHeightField = textFields["tile-tilesizeh-field"]
        let tileGIDField = textFields["tile-gid-field"]
        let tileLocalIDField = textFields["tile-localid-field"]
        let tileRealGIDField = textFields["tile-rawgid-field"]
        let tileTilesetField = textFields["tile-tileset-field"]
        let tileTilesetFirstField = textFields["tile-tileset-first-field"]
        let tileHFlipCheck = checkBoxes["tile-fliph-check"]
        let tileVFlipCheck = checkBoxes["tile-flipv-check"]
        let tileDFlipCheck = checkBoxes["tile-flipd-check"]
        let tileFramesField = textFields["tile-frames-field"]
        let tilePreview = imageViews["tile-preview-image"]


        /// Object types
        let objectIDField = textFields["object-id-field"]
        let objectSizeWField = textFields["object-sizew-field"]
        let objectSizeHField = textFields["object-sizeh-field"]
        let objectGIDField = textFields["object-gid-field"]
        let objectProxyField = textFields["object-proxy-field"]
        let objectVisisbleToCameraCheck = checkBoxes["object-camvis-check"]



        /// Camera types
        let cameraZoomField = textFields["camera-zoom-field"]
        let cameraAllowsZoomCheck = checkBoxes["camera-allowzoom-check"]



        // reset current values
        nodeNameLabel?.reset()
        nodeTypeLabel?.reset()
        nodeDescLabel?.reset()
        nodeNameField?.reset()
        nodePosXField?.reset()
        nodePosYField?.reset()
        nodeScaleXField?.reset()
        nodeScaleYField?.reset()
        nodePosZField?.reset()
        nodeRotZField?.reset()
        nodeAlphaField?.reset()


        nodeHiddenCheck?.state = .off
        nodePausedCheck?.state = .off
        
        spriteSizeWidthField?.reset()
        spriteSizeHeightField?.reset()
        spritePreview?.reset()

        tileSizeWidthField?.reset()
        tileSizeHeightField?.reset()
        tileGIDField?.reset()
        tileLocalIDField?.reset()
        tileRealGIDField?.reset()
        tileTilesetField?.reset()
        tileFramesField?.reset()
        tileTilesetFirstField?.reset()
        tileHFlipCheck?.state = .off
        tileVFlipCheck?.state = .off
        tileDFlipCheck?.state = .off
        tilePreview?.reset()


        objectIDField?.reset()
        objectSizeWField?.reset()
        objectSizeHField?.reset()
        objectGIDField?.reset()
        objectProxyField?.reset()
        objectVisisbleToCameraCheck?.state = .off


        cameraZoomField?.reset()
        cameraAllowsZoomCheck?.state = .off



        // these fields can't be edited
        tileSizeWidthField?.isEnabled = false
        tileSizeHeightField?.isEnabled = false
        tileTilesetField?.isEnabled = false
        objectProxyField?.isEnabled = false
        objectIDField?.isEnabled = false
        tileFramesField?.isEnabled = false
        tileRealGIDField?.isEnabled = false

        guard let selected = selectedNode else {
            return
        }


        var nodeAttributeStorage = AttributeStorage()
        

        // filter current nodes
        for node in focusedNodes {
            // "sk-node-type", "sk-node-posx", "sk-node-posy", "sk-node-posz", "sk-node-hidden", "sk-node-paused", "sk-node-speed"
            nodeAttributeStorage.add(values: node.getAttrs())

            // "tiled-element-name", "tiled-node-nicename", "tiled-node-icon", "tiled-node-listdesc", "tiled-help-desc"
            // "tile-node-gid"
            if let tiledNode = node as? TiledCustomReflectableType {
                let tiledAttrs = tiledNode.tiledAttributes()
                nodeAttributeStorage.add(values: tiledAttrs)
            }
        }



        nodeTypeLabel?.setStringValue(keys: ["sk-node-type", "tiled-element-name", "tiled-node-nicename", "tiled-node-role"], attribute: nodeAttributeStorage, fallback: "Node")

        let nodeNameAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: NSColor(named: NSColor.Name("AttributeName"))
        ]

        // node name
        var nodeNameString: String?
        if let nodeName = nodeAttributeStorage.firstValue(key: "sk-node-name") as? String {
            nodeNameString = "'\(nodeName)'"
        }

        if let nodeNameString = nodeNameString {
            let attributedString = NSAttributedString(string: nodeNameString, attributes: nodeNameAttributes)
            nodeNameLabel?.attributedStringValue = attributedString
        }

        // node description
        var nodeDescString: String?
        if let nodeDesc = nodeAttributeStorage.firstValue(key: "tiled-help-desc") as? String {
            nodeDescString = nodeDesc
        }

        if let nodeDescString = nodeDescString {
            let attributedString = NSAttributedString(string: nodeDescString, attributes: nodeNameAttributes)
            nodeDescLabel?.attributedStringValue = attributedString
        }


        nodeNameField?.setStringValue(for: "sk-node-name", attribute: nodeAttributeStorage)
        nodePosXField?.setStringValue(for: "sk-node-posx", attribute: nodeAttributeStorage)
        nodePosYField?.setStringValue(for: "sk-node-posy", attribute: nodeAttributeStorage)
        nodePosZField?.setStringValue(for: "sk-node-posz", attribute: nodeAttributeStorage)

        nodeScaleXField?.setStringValue(for: "sk-node-scalex", attribute: nodeAttributeStorage)
        nodeScaleYField?.setStringValue(for: "sk-node-scaley", attribute: nodeAttributeStorage)


        nodeRotZField?.setStringValue(for: "sk-node-rotz", attribute: nodeAttributeStorage)
        nodeAlphaField?.setStringValue(for: "sk-node-alpha", attribute: nodeAttributeStorage)

        nodeHiddenCheck?.setCheckState(for: "sk-node-hidden", attribute: nodeAttributeStorage)
        nodePausedCheck?.setCheckState(for: "sk-node-paused", attribute: nodeAttributeStorage)
        
        
        spriteSizeWidthField?.setStringValue(for: "sk-sprite-sizew", attribute: nodeAttributeStorage)
        spriteSizeHeightField?.setStringValue(for: "sk-sprite-sizeh", attribute: nodeAttributeStorage)


        tileSizeWidthField?.setStringValue(for: "tile-node-tilesizew", attribute: nodeAttributeStorage)
        tileSizeHeightField?.setStringValue(for: "tile-node-tilesizeh", attribute: nodeAttributeStorage)

        tileHFlipCheck?.setCheckState(for: "tile-node-fliph", attribute: nodeAttributeStorage)
        tileVFlipCheck?.setCheckState(for: "tile-node-flipv", attribute: nodeAttributeStorage)
        tileDFlipCheck?.setCheckState(for: "tile-node-flipd", attribute: nodeAttributeStorage)

        tileGIDField?.setStringValue(for: "tile-node-gid", attribute: nodeAttributeStorage)
        tileLocalIDField?.setStringValue(for: "tile-node-localid", attribute: nodeAttributeStorage)
        tileRealGIDField?.setStringValue(for: "tile-node-realgid", attribute: nodeAttributeStorage)
        tileTilesetField?.setStringValue(for: "tile-node-tileset", attribute: nodeAttributeStorage)
        tileTilesetFirstField?.setStringValue(for: "tile-node-tileset-first", attribute: nodeAttributeStorage)

        
        if let spriteTexture = nodeAttributeStorage.firstValue(for: "sk-sprite-texture") as? SKTexture {
            spriteTexture.filteringMode = .nearest
            spritePreview?.layer?.backgroundColor = NSColor(hexString: "#222222").cgColor
            spritePreview?.wantsLayer = true
            spritePreview?.layer?.magnificationFilter = .nearest
            let textureNsImage = NSImage(cgImage: spriteTexture.cgImage(), size: spriteTexture.size())
            spritePreview?.image = textureNsImage
        }
        
        
        if let tileTexture = nodeAttributeStorage.firstValue(for: "tile-node-texture") as? SKTexture {
            tileTexture.filteringMode = .nearest
            tilePreview?.layer?.backgroundColor = NSColor(hexString: "#222222").cgColor
            tilePreview?.wantsLayer = true
            tilePreview?.layer?.magnificationFilter = .nearest
            let textureNsImage = NSImage(cgImage: tileTexture.cgImage(), size: tileTexture.size())
            tilePreview?.image = textureNsImage
        }

        objectIDField?.setStringValue(for: "obj-node-id", attribute: nodeAttributeStorage)
        objectSizeWField?.setStringValue(for: "obj-node-sizew", attribute: nodeAttributeStorage)
        objectSizeHField?.setStringValue(for: "obj-node-sizeh", attribute: nodeAttributeStorage)
        objectGIDField?.setStringValue(for: "obj-node-gid", attribute: nodeAttributeStorage)
        objectProxyField?.setStringValue(for: "obj-node-proxy", attribute: nodeAttributeStorage)
        objectVisisbleToCameraCheck?.setCheckState(for: "obj-node-camvis", attribute: nodeAttributeStorage)
        
        
        attributeStorage = nodeAttributeStorage
    }


    // MARK: Event Handlers

    /// Called when the current scene has been cleared.
    @objc func resetInterfaceAction(notification: Notification) {
        resetInterface()
    }

    /// Called when the current scene has been cleared.
    @objc func sceneWillUnloadAction(notification: Notification) {
        resetInterface()
    }


    /// Called when the user right-clicks the mouse.
    ///
    /// - Parameter notification: event notification.
    @objc func mouseRightClickAction(notification: Notification) {
        setupAttributeEditor()
    }

    /// Called when the current scene has been cleared.
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionChanged(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
              let selectedNodes = userInfo["nodes"] as? [SKNode] else {
            return
        }

        selectedNodes.forEach( { node in
            node.updateAttributes()
        })
        

        let nodeCount = selectedNodes.count
        let selectedString = (nodeCount > 0) ? (nodeCount > 1) ? ": (\(nodeCount) nodes selected)" : ": (\(nodeCount) node selected)" : ""

        attributesBox.title = "Attributes\(selectedString)"
        handleNodeSelection()
    }

    @objc func dumpAttributeEditorWidgets(notification: Notification) {
        let headerString = " Attribute Editor ".padEven(toLength: 40, withPad: "-")
        print("\n\(headerString)\n")

        print(" ▿ Stack Views:")
        for (uikey, stack) in rootUIViews {
            print("   ‣ \(uikey)")
        }


        if (textFields.isEmpty == false) {
            print("\n ▿ Text Views:")
            for (uikey, tfield) in textFields {
                print("   ‣ \(uikey)")
            }
        }

        if (checkBoxes.isEmpty == false) {
            print("\n ▿ Check Boxes:")
            for (uikey, tfield) in checkBoxes {
                print("   ‣ \(uikey)")
            }
        }
        
        if (imageViews.isEmpty == false) {
            print("\n ▿ Image views:")
            for (uikey, tfield) in imageViews {
                print("   ‣ \(uikey)")
            }
        }
        
        if (popupMenus.isEmpty == false) {
            print("\n ▿ Menus:")
            for (uikey, tfield) in popupMenus {
                print("   ‣ \(uikey)")
            }
        }
        
        if (colorWells.isEmpty == false) {
            print("\n ▿ Color Pickers:")
            for (uikey, tfield) in colorWells {
                print("   ‣ \(uikey)")
            }
        }
    }
    
    @objc func dumpAttributeStorage(notification: Notification) {
        guard let attributes = attributeStorage else {
            return
        }
        attributes.dump()
    }

    /// Handler for button/checkbox events.
    ///
    /// - Parameter sender: invoking UI element.
    @objc func handleButtonEvent(_ sender: NSButton) {
        if let bid = sender.identifier {
            let textIdentifier = bid.rawValue
            let isChecked = sender.state == .on
            print("⭑ [\(classNiceName)]: button changed: '\(textIdentifier)', value: \(isChecked)")


            if (textIdentifier == "node-hidden-check") {
                for node in focusedNodes {
                    node.isHidden = isChecked
                    node.updateAttributes()
                }
            }

            if (textIdentifier == "node-paused-check") {
                for node in focusedNodes {
                    node.isPaused = isChecked
                    node.updateAttributes()
                }
            }

            if (textIdentifier == "tile-fliph-check") {
                for node in focusedNodes {
                    if let tile = node as? SKTile {
                        tile.isFlippedHorizontally = isChecked
                        node.setAttr(key: "tile-node-fliph", value: isChecked)
                    }
                }
            }

            if (textIdentifier == "tile-flipv-check") {
                for node in focusedNodes {
                    if let tile = node as? SKTile {
                        tile.isFlippedVertically = isChecked
                        node.setAttr(key: "tile-node-flipv", value: isChecked)
                    }
                }
            }

            if (textIdentifier == "tile-flipd-check") {
                for node in focusedNodes {
                    if let tile = node as? SKTile {
                        tile.isFlippedDiagonally = isChecked
                        node.setAttr(key: "tile-node-flipd", value: isChecked)
                    }
                }
            }
            
            if (textIdentifier == "object-camvis-check") {
                for node in focusedNodes {
                    if let object = node as? SKTileObject {
                        object.visibleToCamera = isChecked
                        object.setAttr(key: "obj-node-camvis", value: isChecked)
                    }
                }
            }
        }

        let updatedNodeData: [String: [SKNode]] = ["updated": Array(demoDelegate.focusedNodes)]
        
        
        NotificationCenter.default.post(
            name: Notification.Name.Demo.NodeAttributesChanged,
            object: nil,
            userInfo: updatedNodeData
        )
        
        handleNodeSelection()
    }

}



// MARK: - Extensions

// TODO: need to implement this
extension InspectorAttributesViewController: NSStackViewDelegate {
    
    func stackView(_ stackView: NSStackView, willDetach views: [NSView]) {
        
    }
    
    func stackView(_ stackView: NSStackView, didReattach views: [NSView]) {
        
    }
}



// MARK: Text Field Methods


extension InspectorAttributesViewController: NSTextFieldDelegate {

    /// Invoked when users press keys with predefined bindings in a cell of the specified control.
    ///
    /// - Parameters:
    ///   - control: The control whose cell initiated the message. If the control contains multiple cells, the one that initiated the message is usually the selected cell.
    ///   - textView: The field editor of the control.
    ///   - commandSelector: The selector that was associated with the binding.
    /// - Returns: true if the delegate object handles the key binding; otherwise, false.
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let textField = control as? NSTextField else {
            return false
        }
        
        
        print("selector: \(commandSelector.description)")
        
        let doubleValue = textField.doubleValue
        let incrementValue: Double = 0.5

        if commandSelector == #selector(moveUp(_:)) {
            let newValue = doubleValue + incrementValue
            textField.doubleValue = newValue
            return false

        } else if commandSelector == #selector(moveDown(_:)) {
            let newValue = doubleValue - incrementValue
            textField.doubleValue = newValue
            return false
        
        // if the user presses tab or return, handle the
        } else if commandSelector == #selector(insertNewline(_:)) {
            return true
            
        } else if commandSelector == #selector(insertTab(_:)) {
            return true
        }

        return false
    }
    
    
    /// Called when the text field edititing is finished.
    ///
    /// - Parameter obj: event notification.
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              let textIdentifier = textField.identifierString else {
            return
        }
        
        let textFieldValue = textField.stringValue
        
        var floatValue: CGFloat?
        if let doubleValue = Double(textFieldValue) {
            floatValue = CGFloat(doubleValue)
        }

        if (demoDelegate.focusedNodes.isEmpty) {
            return
        }
        
        /*
        let textFieldDescription = (textField.isNumericTextField == true) ? "number field" : "text field"
        print("⭑ [AttributeEditor]: \(textFieldDescription) '\(textIdentifier)', value: '\(textFieldValue)'")
        */
        
        
        if (textIdentifier == "node-name-field") {
            for node in focusedNodes {
                node.name = textFieldValue
            }
        }
        
        if let floatValue = floatValue {
            if (textIdentifier == "node-xpos-field") {
                for node in focusedNodes {
                    node.position.x = floatValue
                }
            }
            
            if (textIdentifier == "node-ypos-field") {
                for node in focusedNodes {
                    node.position.y = floatValue
                }
            }
            
            if (textIdentifier == "node-zpos-field") {
                for node in focusedNodes {
                    node.zPosition = floatValue
                }
            }
            
            if (textIdentifier == "node-xscale-field") {
                for node in focusedNodes {
                    node.xScale = floatValue
                }
            }
            
            if (textIdentifier == "node-yscale-field") {
                for node in focusedNodes {
                    node.yScale = floatValue
                }
            }
            
            
            if (textIdentifier == "node-zrot-field") {
                for node in focusedNodes {
                    node.zRotation = floatValue.radians()
                }
            }
            
            
            if (textIdentifier == "node-alpha-field") {
                for node in focusedNodes {
                    node.alpha = floatValue
                }
            }
            
            if (textIdentifier == "object-sizew-field") {
                for node in focusedNodes {
                    if let objNode = node as? SKTileObject {
                        objNode.size.width = floatValue
                        print("setting object width \(floatValue)")
                    }
                }
            }
            
            if (textIdentifier == "object-sizeh-field") {
                for node in focusedNodes {
                    if let objNode = node as? SKTileObject {
                        objNode.size.height = floatValue
                        print("setting object height \(floatValue)")
                    }
                }
            }
        }
        
        /// update all of the node attributes
        focusedNodes.forEach({ node in
            node.updateAttributes()
        })
        
        NotificationCenter.default.post(
            name: Notification.Name.Demo.RefreshInspectorInterface,
            object: nil
        )
        
        // repopulate the UI
        handleNodeSelection()
    }
}



extension NSTextField {
    
    /// Returns the editable state of this control.
    @IBInspectable public var userEditable: Bool {
        set (newValue) {
            self.isEnabled = newValue
        } get {
            return self.isEnabled
        }
    }
    
    /// Returns the editable state.
    @IBInspectable public var incrementValue: Double {
        set (newValue) {
            //setValue(newValue, forKey: "incrementValue")
        } get {
            guard let incval = value(forKey: "incrementValue") as? Double else {
                return 0.5
            }
            
            return incval
        }
    }
}
