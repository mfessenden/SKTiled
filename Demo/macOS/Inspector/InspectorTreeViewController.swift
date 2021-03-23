//
//  InspectorTreeViewController.swift
//  SKTiled Demo - macOS
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//    Web: https://github.com/mfessenden
//    Email: michael.fessenden@gmail.com
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.
//
//  Reference: https://stackoverflow.com/questions/1234245/filtering-a-tree-controller

import Cocoa
import SpriteKit


class InspectorTreeViewController: NSViewController {
    
    let demoController = TiledDemoController.default
    let demoDelegate = TiledDemoDelegate.default
    
    /// The scroll view.
    @IBOutlet weak var scrollView: NSScrollView!
    
    /// The scene graph tree view.
    @IBOutlet weak var outlineView: NSOutlineView!
    
    /// The search field.
    @IBOutlet weak var searchField: NSSearchField!
    
    /// Search predicate.
    @objc dynamic var filterPredicate: NSPredicate? = nil
    
    /// The search field refresh button.
    @IBOutlet weak var refreshNodeTreeButton: NSButton!
    
    /// Node tree items.
    weak var rootNode: SKNode?
    
    /// The current search text.
    var searchText: String? {
        didSet {
            outlineView.reloadData()
        }
    }
    
    /// Setup the interface when the inspector first launches.
    override func viewDidLoad() {
        super.viewDidLoad()
        resetInterface()
        setupNotifications()
        
        outlineView.dataSource = self
        outlineView.delegate = self
        searchField.delegate = self
        
        scrollView.verticalScroller?.layer?.backgroundColor = CGColor.clear
        //preferredContentSize = NSSize(width: 225, height: 700)
        //view.setFrameSize(NSSize(width: 225, height: 700))
    }
    
    // MARK: - Setup
    
    func setupNotifications() {
        
        /// Loading/Scene
        NotificationCenter.default.addObserver(self, selector: #selector(currentSceneChanged), name: Notification.Name.Demo.SceneLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mouseRightClickAction), name: Notification.Name.Camera.MouseRightClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChanged), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshinterface), name: Notification.Name.Demo.RefreshInspectorInterface, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneLoaded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Camera.MouseRightClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.RefreshInspectorInterface, object: nil)
    }
    
    /// Reset the interface.
    func resetInterface() {
        rootNode = nil
        demoDelegate.reset()
        
        // set the current root node
        if let currentView = demoController.view  {
            if let currentScene = currentView.scene as? SKTiledScene {
                rootNode = currentScene
            }
        }
        
        outlineView.reloadData()
    }
    
    // MARK: - Node Selection
    
    /// Handle the currently selected nodes.
    func handleNodeSelection() {
        
    }
    
    // MARK:- Notification Handlers
    
    
    /// Called when the `Notification.Name.Demo.RefreshInspectorInterface` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func refreshinterface(notification: Notification) {
        print("⭑ [\(classNiceName)]: refreshing Inspector UI...")
        outlineView.reloadData()
    }
    
    /// Called when the `Notification.Name.Demo.NodeSelectionChanged` notification is sent.
    ///
    ///  - expects a userInfo of `["nodes": [SKNode]]`
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionChanged(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
              let selectedNodes = userInfo["nodes"] as? [SKNode] else {
            return
        }
        
        var firstRow: Int?
        let isSingleSelection = selectedNodes.count == 1
        
        //outlineView.deselectAll(nil)
        for node in selectedNodes {
            if let tiledNode = node as? TiledGeometryType {
                // expand parent items
                let nodeParents: [SKNode] = Array(node.allParents().reversed())
                for parent in nodeParents {
                    /*
                     if (outlineView.row(forItem: parent) < 0) {
                     outlineView.expandItem(parent)
                     }
                     */
                    
                    if (isSingleSelection == true) {
                        outlineView.expandItem(parent)
                    }
                }
                
                outlineView.selectItem(item: node)
                if (firstRow == nil) {
                    firstRow = outlineView.row(forItem: node)
                }
            }
        }
        
        if let rowToSelect = firstRow {
            outlineView.scrollRowToVisible(rowToSelect)
        }
    }
    
    
    /// Called when the `Refresh` button is pressed in the list interface.
    ///
    /// - Parameter sender: invoking UI element.
    @IBAction func refreshNodeTreeButtonPressed(_ sender: Any) {
        guard let _ = sender as? NSButton else {
            return
        }
        
        let selectedRows = outlineView.selectedRowIndexes
        let selectedColumns = outlineView.selectedColumnIndexes
        //outlineView.reloadData(forRowIndexes: selectedRows, columnIndexes: selectedColumns)
        outlineView.reloadData()
    }
    
    /// Called when the scene is flushed via the demo controller.
    ///
    /// - Parameter notification: event notification.
    @objc func sceneWillUnloadAction(notification: Notification) {
        resetInterface()
    }
    
    /// Called when the tilemap `currentCoordinate` changes.
    ///
    /// - Parameter notification: event notification.
    @objc func currentSceneChanged(notification: Notification) {
        guard let scene = notification.object as? SKScene else {
            return
        }
        
        rootNode = nil
        
        // set the root node
        if let _ = scene as? SKTiledScene {
            rootNode = scene
        }
        
        outlineView.reloadData()
    }
    
    /// Called when the user right-clicks the mouse.
    ///
    /// - Parameter notification: event notification.
    @objc func mouseRightClickAction(notification: Notification) {
        outlineView.deselectAll(nil)
    }
}


// MARK: - Extensions


extension InspectorTreeViewController: NSOutlineViewDelegate {
    
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
        guard let cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView else {
            return nil
        }
        
        if let node = item as? SKNode {
            
            var textValue = node.getAttr(key: "tiled-node-listdesc") as? String ?? "SpriteKit node."
            var imageName = node.getAttr(key: "tiled-node-icon") as? String ?? "nil-icon"

            if let tiledNode = node as? TiledCustomReflectableType {
                textValue = tiledNode.tiledListDescription ?? textValue
                imageName = tiledNode.tiledIconName ?? "\(textValue)-icon"
            }
            
            
            let isHiddenNode = node.isHidden
            let nodeTextColorName = (isHiddenNode == true) ? "outlineViewHidden" : "outlineViewDefault"
            let nodeTextColor = NSColor(named: NSColor.Name(nodeTextColorName))
            
            let outlineViewAttributes: [NSAttributedString.Key : Any] = [
                //NSAttributedString.Key.font: textAttributes.font,
                NSAttributedString.Key.foregroundColor: nodeTextColor
                
            ]
            
            
            // [NSAttributedString.Key : Any]?
            let attributedString = NSMutableAttributedString(string: textValue, attributes: outlineViewAttributes)
            cell.textField?.attributedStringValue = attributedString
            cell.imageView?.image = NSImage(named: NSImage.Name(imageName))
        }
        
        return cell
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        /*
         for node in demoDelegate.focusedNodes {
            node.highlightNode(with: SKColor.clear)
        }
        */
        
        
        demoDelegate.focusedNodes.unfocusAll()
        demoDelegate.focusedNodes.removeAll()
        
        // clear the current selection
        NotificationCenter.default.post(
            name: Notification.Name.Demo.NodesAboutToBeSelected,
            object: nil
        )
        
        let selectedIndices = outlineView.selectedRowIndexes
        
        if (selectedIndices.isEmpty == true) {
            return
        }
        
        var nodeTypes: Set<String> = []
        
        for row in selectedIndices {
            
            if let skNode = outlineView.item(atRow: row) as? SKNode {
                demoDelegate.focusedNodes.insert(skNode, at: 0)
                //print(skNode.getAttrs())
                if let tiledNode = skNode as? TiledCustomReflectableType {
                    if let tiledElementName = tiledNode.tiledElementName {
                        nodeTypes.insert(tiledElementName)
                    }
                    
                    //tiledNode.outputProtocols()
                }
            }
        }
        
        if (nodeTypes.isEmpty == false) {
            //print("⭑ [InspectorTreeViewController]: selected types: \(nodeTypes.map{ "\"\($0)\"" }.joined(separator: ","))")
        }
        
        
        let isSingleSelection = demoDelegate.focusedNodes.count == 1
        let currentNodesArray = Array(demoDelegate.focusedNodes)
        
        if (isSingleSelection == true) {
            let nodeToFocusOn = currentNodesArray.first!
            var focusLocation = nodeToFocusOn.position
            
            if let scene = nodeToFocusOn.scene {
                focusLocation = scene.convert(focusLocation, to: scene)
            }
            
            /// event: `Notification.Name.Demo.NodeSelectionChanged`
            NotificationCenter.default.post(
                name: Notification.Name.Demo.NodeSelectionChanged,
                object: nil,
                userInfo: ["nodes": currentNodesArray, "focusLocation": focusLocation]
            )
        } else {
            /// event: `Notification.Name.Demo.NodeSelectionChanged`
            NotificationCenter.default.post(
                name: Notification.Name.Demo.NodeSelectionChanged,
                object: nil,
                userInfo: ["nodes": currentNodesArray]
            )
        }
        
        
        
        handleNodeSelection()
    }
}




extension InspectorTreeViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let sknode = item as? SKNode else {
            return rootNode?.children.count ?? 1
        }
        return sknode.children.count
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return (item == nil) ? rootNode?.children[index] : (item as? SKNode)?.children[index] ?? item!
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let element = item as? SKNode else {
            return false
        }
        
        return element.children.count != 0
    }
}


extension InspectorTreeViewController: NSSearchFieldDelegate {
    
    /// Called when the user enters non-textual values (arrow, newline, etc).
    ///
    /// - Parameters:
    ///   - control: control whose cell was issued a command.
    ///   - textView: control text field.
    ///   - commandSelector: description of command typed.
    /// - Returns: the delegate has handled the command.
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        var fieldId = ""
        if let id = textView.identifier?.rawValue {
            fieldId = "\(id): "
        }
        print("\(fieldId)\(commandSelector)")
        return false
    }
    
    
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              let textIdentifier = textField.identifier else {
            return
        }
        
        let stringIdentifier = textIdentifier.rawValue
    }
    
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
              let textIdentifier = textField.identifier else {
            fatalError("uh oh, bad textfield")
        }
        
        
        
        let stringIdentifier = textIdentifier.rawValue
        
        let textFieldValue = textField.stringValue
        let numberFormatter = textField.formatter as? NumberFormatter
        let hasFormatter = numberFormatter != nil
        let textFieldDescription = (hasFormatter == true) ? "numeric text field" : "text field"
        
        if (demoDelegate.focusedNodes.isEmpty) {
            print("⭑ WARNING: nothing selected!")
            return
        }
        
        print("⭑ \(textFieldDescription) '\(stringIdentifier)', value: '\(textFieldValue)', formatter: \(hasFormatter)")
        
        if (stringIdentifier == "NodeNameField") {
            let newNodeName = textFieldValue
            print("⭑ setting name: \(newNodeName)")
            for node in demoDelegate.focusedNodes {
                node.name = newNodeName
            }
        }
        
        
        if (stringIdentifier == "TreeFilter") {
            print("⭑ filtering: '\(textFieldValue)'")
            searchText = textField.stringValue
        }
        
        if (stringIdentifier == "XPosition") {
            if let positionValue = Float(textFieldValue) {
                print("⭑ setting x-position: \(positionValue)")
                for node in demoDelegate.focusedNodes {
                    node.position.x = CGFloat(positionValue)
                }
            }
        }
        
        if (stringIdentifier == "YPosition") {
            if let positionValue = Float(textFieldValue) {
                print("⭑ setting y-position: \(positionValue)")
                for node in demoDelegate.focusedNodes {
                    node.position.y = CGFloat(positionValue)
                }
            }
            
        }
        
        if (stringIdentifier == "ZPosition") {
            if let positionValue = Float(textFieldValue) {
                print("⭑ setting z-position: \(positionValue)")
                for node in demoDelegate.focusedNodes {
                    node.zPosition = CGFloat(positionValue)
                }
            } else {
                print("⭑ ERROR: invalid zPosition '\(textFieldValue)'")
            }
        }
        
        outlineView.reloadData()
        
        let updatedNodeData: [String: [SKNode]] = ["updated": Array(demoDelegate.focusedNodes)]
        
        NotificationCenter.default.post(
            name: Notification.Name.Demo.NodeAttributesChanged,
            object: nil,
            userInfo: updatedNodeData
        )
        
    }
}
