//
//  AttributeEditorViewController.swift
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


class AttributeEditorViewController: NSViewController {

    let demoController = TiledDemoController.default
    let demoDelegate = TiledDemoDelegate.default
    var receiveCameraUpdates: Bool = true


    @IBOutlet var editorView: NSView!
    @IBOutlet weak var attributesGrid: NSGridView!

    var textFields:  [String: NSTextField] = [:]
    var checkBoxes:  [String: NSButton] = [:]
    var popupMenus:  [String: NSPopUpButton] = [:]


    /// Reference to the demo delegate current nodes.
    var currentNodes: [SKNode] {
        return Array(demoDelegate.focusedNodes)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.setFrameSize(NSSize(width: 480, height: 580))
        
        let nodeIsCurrentlySelected = demoDelegate.focusedNodes.isEmpty == false
        
        setupNotifications()
        setupInterface()
        resetInterface(enabled: nodeIsCurrentlySelected)

        if (nodeIsCurrentlySelected == true) {
            populateInterface()
        }

        demoController.camera?.addDelegate(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneLoaded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.ObjectClicked, object: nil)
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChangedAction), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneLoaded), name: Notification.Name.Demo.SceneLoaded, object: nil)


        NotificationCenter.default.addObserver(self, selector: #selector(tileClickedAction), name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileClickedAction), name: Notification.Name.Demo.ObjectClicked, object: nil)

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

        if let tilemap = demoController.currentTilemap {
            var mapNameString = tilemap.mapName
            if let mapurl = tilemap.url {
                mapNameString = mapurl.relativePath
            }



            if let window = view.window {
                window.title = "Attribute Editor: '\(mapNameString)'"
            }
        }

        let viewTitleLabel = textFields["selected-nodes-title-field"]
        let titleString = (enabled == false) ? "Nodes: 0" : "Nodes: \(currentNodes.count)"
        viewTitleLabel?.stringValue = titleString
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

    func populateInterface() {

        // window title
        let viewTitleLabel = textFields["selected-nodes-title-field"]

        // text fields
        let nodeNameField = textFields["node-name-field"]
        let nodePosXField = textFields["node-xpos-field"]
        let nodePosYField = textFields["node-ypos-field"]
        let nodePosZField = textFields["node-zpos-field"]
        let nodeRotZField = textFields["node-zrot-field"]
        let nodeAlphaField = textFields["node-alpha-field"]
        let nodeOffsetXField = textFields["node-xoffset-field"]
        let nodeOffsetYField = textFields["node-yoffset-field"]


        // check boxes
        let nodeHiddenCheck = checkBoxes["node-hidden-check"]
        let nodePausedCheck = checkBoxes["node-paused-check"]


        // reset current nodes
        viewTitleLabel?.reset()
        nodeNameField?.reset()
        nodePosXField?.reset()
        nodePosYField?.reset()
        nodePosZField?.reset()
        nodeRotZField?.reset()
        nodeAlphaField?.reset()
        nodeOffsetXField?.reset()
        nodeOffsetYField?.reset()

        nodeHiddenCheck?.state = .off
        nodePausedCheck?.state = .off


        let selectedCount = currentNodes.count

        if (selectedCount == 0) {
            viewTitleLabel?.stringValue = "Nodes: 0"
            resetInterface(enabled: false)
            return
        }

        var nodeTypeValues: Set<String> = []
        var nodeNameValues: Set<String> = []
        var nodePosXValues: Set<String> = []
        var nodePosYValues: Set<String> = []
        var nodePosZValues: Set<String> = []
        var nodeRotZValues: Set<String> = []
        var nodeAlphaValues: Set<String> = []
        var nodeOffsetXValues: Set<String> = []
        var nodeOffsetYValues: Set<String> = []

        var nodeHiddenValues: Set<Bool> = []
        var nodePausedValues: Set<Bool> = []


        // filter current nodes
        for node in currentNodes {

            nodeTypeValues.insert(node.className)

            if let nodeName = node.name {
                nodeNameValues.insert(nodeName)
            }

            nodePosXValues.insert("\(node.position.x)")
            nodePosYValues.insert("\(node.position.y)")
            nodePosZValues.insert("\(node.zPosition)")
            nodeRotZValues.insert("\(node.rotation)")
            nodePausedValues.insert(node.isPaused)
            nodeHiddenValues.insert(node.isHidden)
            nodeAlphaValues.insert("\(node.alpha)")



            if let layer = node as? TiledLayerObject {
                nodeOffsetXValues.insert("\(layer.offset.x)")
                nodeOffsetYValues.insert("\(layer.offset.y)")
            }
        }


        // set the title
        var nodeDesc = (selectedCount > 1) ? "Nodes" : "Node"
        nodeDesc += ": \(selectedCount)"
        if (selectedCount == 1) {
            if let firstNode = currentNodes.first {
                if let tiledNode = firstNode as? TiledCustomReflectableType {
                    nodeDesc = "Node: \(tiledNode.tiledDisplayItemDescription ?? "nil")"

                } else {
                    if (nodeTypeValues.count == 1) {
                        nodeDesc = "Node: \(nodeTypeValues.first!)"
                    } else {
                        nodeDesc = "Nodes: (multiple)"
                    }
                }
            }
        }

        viewTitleLabel?.stringValue = nodeDesc

        // set the values from the node types
        var nodeNameString = (nodeNameValues.count > 1) ? "(multiple)" : ""
        if (nodeNameValues.count == 1) {
            nodeNameString = nodeNameValues.first!
            nodeNameField?.stringValue = nodeNameString
        } else {
            nodeNameField?.placeholderString = nodeNameString
        }


        var nodePosXString = "(multiple)"
        if (nodePosXValues.count == 1) {
            nodePosXString = nodePosXValues.first!
            nodePosXField?.stringValue = nodePosXString
        } else {
            nodePosXField?.placeholderString = nodePosXString
        }

        var nodePosYString = "(multiple)"
        if (nodePosYValues.count == 1) {
            nodePosYString = nodePosYValues.first!
            nodePosYField?.stringValue = nodePosYString
        } else {
            nodePosYField?.placeholderString = nodePosYString
        }

        var nodePosZString = "(multiple)"
        if (nodePosZValues.count == 1) {
            nodePosZString = nodePosZValues.first!
            nodePosZField?.stringValue = nodePosZString
        } else {
            nodePosZField?.placeholderString = nodePosZString
        }

        var nodeRotZString = "(multiple)"
        if (nodeRotZValues.count == 1) {
            nodeRotZString = nodeRotZValues.first!
            nodeRotZField?.stringValue = nodeRotZString
        } else {
            nodeRotZField?.placeholderString = nodeRotZString
        }


        var nodeOffsetXString = (nodeOffsetXValues.count > 1) ? "(multiple)" : "0"
        if (nodeOffsetXValues.count == 1) {
            nodeOffsetXString = nodeOffsetXValues.first!
            nodeOffsetXField?.stringValue = nodeOffsetXString
        } else {
            nodeOffsetXField?.placeholderString = nodeOffsetXString
        }

        var nodeOffsetYString = (nodeOffsetYValues.count > 1) ? "(multiple)" : "0"
        if (nodeOffsetYValues.count == 1) {
            nodeOffsetYString = nodeOffsetYValues.first!
            nodeOffsetYField?.stringValue = nodeOffsetYString
        } else {
            nodeOffsetYField?.placeholderString = nodeOffsetYString
        }

        var nodeAlphaString = "(multiple)"
        if (nodeAlphaValues.count == 1) {
            nodeAlphaString = nodeAlphaValues.first!
            nodeAlphaField?.stringValue = nodeAlphaString
        } else {
            nodeAlphaField?.placeholderString = nodeAlphaString
        }

        var hiddenCheckState = NSControl.StateValue.mixed
        if (nodeHiddenValues.count == 1) {
            let hiddenValue = nodeHiddenValues.first!
            hiddenCheckState = (hiddenValue == true) ? .on : .off
        }

        nodeHiddenCheck?.state = hiddenCheckState

        var pausedCheckState = NSControl.StateValue.mixed
        if (nodePausedValues.count == 1) {
            let pausedValue = nodePausedValues.first!
            pausedCheckState = (pausedValue == true) ? .on : .off
        }

        nodePausedCheck?.state = pausedCheckState
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
        //notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let selectedNodes = userInfo["nodes"] as? [SKNode] else {
            return
        }

        handleNodeSelection()
    }

    /// Called when the `Notification.Name.Demo.TileClicked` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func tileClickedAction(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let tile = notification.object as? SKTile else {
            return
        }

        handleNodeSelection()
    }

    /// Called when the `Notification.Name.Demo.ObjectClicked` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func objectClickedAction(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let object = notification.object as? SKTileObject else {
            return
        }

        handleNodeSelection()
    }

    /// Called when the `Notification.Name.Map.Updated` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func tilemapWasUpdated(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        populateInterface()
    }


    /// Called when the `Notification.Name.Demo.SceneWillUnload` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func sceneWillUnloadAction(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let nextUrl = userInfo["url"] as? URL else {
            return
        }

        let wintitle = "Attribute Editor: nil"
        view.window?.title = wintitle
        resetInterface(enabled: false)
    }

    /// Called when the `Notification.Name.Demo.SceneLoaded` event fires.
    ///
    ///   userInfo: ["nodes": `[SKNode]`]
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneLoaded(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let demoScene = notification.object as? SKTiledScene,
              let userInfo = notification.userInfo as? [String: Any],
              let mapName = userInfo["tilemapName"],
              let relativePath = userInfo["relativePath"] else {
            return
        }

        let wintitle = "Attribute Editor: '\(mapName)'"
        view.window?.title = wintitle
        resetInterface(enabled: false)

        demoScene.cameraNode?.addDelegate(self)
    }

    /// Handler for button/checkbox events.
    ///
    /// - Parameter sender: invoking ui element.
    @objc func handleButtonEvent(_ sender: NSButton) {
        if let buttonId = sender.identifier {
            let textIdentifier = buttonId.rawValue
            let buttonVal = sender.state == .on

            #if DEBUG
            print("⭑ [AttributeEditor]: button changed: '\(textIdentifier)', value: \(buttonVal)")
            #endif

            if (textIdentifier == "node-paused-check") {
                for node in currentNodes {
                    node.isPaused = buttonVal
                }
            }

            if (textIdentifier == "node-hidden-check") {
                for node in currentNodes {
                    node.isHidden = buttonVal
                }
            }


            if let tilemap = demoController.currentTilemap {
                NotificationCenter.default.post(
                    name: Notification.Name.Map.Updated,
                    object: tilemap
                )
            }
        }
    }
}



// MARK: - Extensions

/// :nodoc:
extension AttributeEditorViewController: TiledSceneCameraDelegate {


    /// Called when the scene is right-clicked.
    ///
    /// - Parameter event: mouse click event.
    @objc func sceneRightClicked(event: NSEvent) {
        print("[AttibutEditorViewController]: \(event.description)")
        resetInterface()
    }
}


extension AttributeEditorViewController: NSTextFieldDelegate {


    //func textView(textView: NSTextView, shouldChangeTextInRange affectedCharRange: NSRange, replacementString: String) -> Bool

    func textField(_ textField: NSTextField, textView: NSTextView, shouldSelectCandidateAt index: Int) -> Bool {
        print("text field \(textField.identifierString ?? "nil"), select index \(index)")
        return true
    }



    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let textField = control as? NSTextField else {
            return false
        }

        let isExpectingNumericValue = textField.isNumericTextField
        var floatValue = textField.floatValue

        guard (isExpectingNumericValue == true) else {
            return false
        }


        if (commandSelector == #selector(moveUp(_:))) {
            floatValue += 0.5
            textField.stringValue = "\(floatValue)"
            return true

        } else if (commandSelector == #selector(moveDown(_:))) {
            floatValue -= 0.5
            return true

        } else if (commandSelector == #selector(insertNewline(_:))) {
            textField.stringValue = "\(floatValue)"
            return false

        } else if (commandSelector == #selector(insertTab(_:))) {
            textField.stringValue = "\(floatValue)"
            return false
        } else if (commandSelector == #selector(insertBacktab(_:))) {
            textField.stringValue = "\(floatValue)"
            return false
        }


        textField.selectText(textField.stringValue)

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
        print("⭑ [AttributeEditorViewController]: \(textFieldDescription) '\(textIdentifier)', value: '\(textFieldValue)'")
        #endif

        switch textIdentifier {
            case "node-name-field":
                for node in currentNodes {
                    node.name = textFieldValue
                }

            case "node-xpos-field":
                for node in currentNodes {
                    node.position.x = floatValue
                }

            case "node-ypos-field":
                for node in currentNodes {
                    node.position.y = floatValue
                }

            case "node-zpos-field":
                for node in currentNodes {
                    node.zPosition = floatValue
                }

            case "node-zrot-field":
                for node in currentNodes {
                    node.rotation = floatValue
                }

            case "node-alpha-field":
                for node in currentNodes {
                    node.alpha = floatValue
                }

            case "node-xoffset-field":
                for node in currentNodes {
                    if let layer = node as? TiledLayerObject {
                        layer.offset.x = floatValue
                    }
                }

            case "node-yoffset-field":
                for node in currentNodes {
                    if let layer = node as? TiledLayerObject {
                        layer.offset.y = floatValue
                    }
                }
            default:
                return
        }

        if let tilemap = demoController.currentTilemap {
            //tilemap.layers.forEach { tilemap.positionLayer($0) }

            NotificationCenter.default.post(
                name: Notification.Name.Map.Updated,
                object: tilemap
            )
        }
    }
}
