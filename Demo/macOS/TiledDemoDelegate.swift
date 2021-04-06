//
//  TiledDemoDelegate.swift
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


typealias NodeList = ThreadSafeArray<SKNode>


/// Manages demo scene geometry for macOS demo.
public class TiledDemoDelegate: NSObject, Loggable {
        
    /// Currently focused nodes.
    var focusedNodes = NodeList()
    
    /// The current tilemap.
    weak var currentTilemap: SKTilemap?
    
    /// The currently selected node.
    public weak var selectedNode: SKNode?
    
    /// Receive camera updates from camera.
    @objc public var receiveCameraUpdates: Bool = true
    
    /// The current demo camera zoom level.
    public var currentCameraZoom: CGFloat = 1
    
    /// Default singleton instance.
    static var `default`: TiledDemoDelegate {
        return defaultDemoDelegate
    }
    
    // MARK: - Initialization
    
    /// Default initializer.
    public override init() {
        super.init()
        setupNotifications()
    }
    
    deinit {
        // remove notification observers
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.FocusCoordinateChanged, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.FlushScene, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.DumpSelectedNodes, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.HighlightSelectedNodes, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.ObjectClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.IsolateSelectedEnabled, object: nil)
        reset()
    }
    
    /// Reset the delegate.
    func reset() {
        // reset focused nodes
        defer {
            focusedNodes.unfocusAll()
            focusedNodes.removeAll()
            selectedNode = nil
        }
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(focusedCoordinateChanged), name: Notification.Name.Map.FocusCoordinateChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.FlushScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChanged), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionCleared), name: Notification.Name.Demo.NodeSelectionCleared, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(nodeHighlightingCleared), name: Notification.Name.Demo.NodeHighlightingCleared, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(dumpSelectedNodes), name: Notification.Name.Demo.DumpSelectedNodes, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(highlightSelectedNodes), name: Notification.Name.Demo.HighlightSelectedNodes, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileClickedAction), name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectClickedAction), name: Notification.Name.Demo.ObjectClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(isolatedSelectedAction), name: Notification.Name.Demo.IsolateSelectedEnabled, object: nil)
    }
       
    // MARK: - Handlers
        
    /// Handles the `Notification.Name.Map.FocusCoordinateChanged` callback.
    ///
    ///   userInfo: `["old": simd_int2, "new": simd_int2, "isValid": Bool]`
    ///
    /// - Parameter notification: event notification.
    @objc func focusedCoordinateChanged(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
              let oldCoordinate = userInfo["old"] as? simd_int2,
              let newCoordinate = userInfo["new"] as? simd_int2,
              let isValidCoord = userInfo["isValid"] as? Bool else {
            return
        }
        
        let delta = oldCoordinate.delta(to: newCoordinate)
        //self.log("map focus coordinate changed, \(newCoordinate.coordDescription) -> \(oldCoordinate.coordDescription) ( \(delta))", level: .debug)
    }
    
    /// Handles the `Notification.Name.Demo.SceneWillUnload` callback.
    ///
    ///  userInfo: `["url": URL]`
    ///
    /// - Parameter notification: event notification.
    @objc func sceneWillUnloadAction(notification: Notification) {
        self.log("resetting demo delegate...", level: .debug)
        self.reset()
    }
    
    /// Handles the `Notification.Name.Demo.NodeSelectionChanged` callback.
    ///
    ///   userInfo: ["nodes": `[SKNode]`, "focusLocation": `CGPoint`]
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let selectedNodes = userInfo["nodes"] as? [SKNode] else {
            return
        }
        
        focusedNodes.unfocusAll()
        focusedNodes.removeAll()
        
        for node in selectedNodes {
            focusedNodes.append(node)
            if let tiledNode = node as? TiledGeometryType {
                tiledNode.isFocused = true
                //node.highlightNode(with: highlightColor)
            }
        }
    }
    
    /// Handles the `Notification.Name.Demo.NodeSelectionCleared` callback.
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionCleared(notification: Notification) {
        notification.dump(#fileID, function: #function)
        self.reset()
    }
    
    /// Handles the `Notification.Name.Demo.TileClicked` event.
    ///
    ///  object: `SKTile`
    ///
    /// - Parameter notification: event notification.
    @objc func tileClickedAction(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let tile = notification.object as? SKTile else {
            return
        }
        
        focusedNodes.unfocusAll()
        focusedNodes.removeAll()
        focusedNodes.append(tile)
        
        
        print("⭑ tile is focused: \(tile.isFocused)")
        
        /// event: `Notification.Name.Demo.NodeSelectionChanged`
        NotificationCenter.default.post(
            name: Notification.Name.Demo.NodeSelectionChanged,
            object: nil,
            userInfo: ["nodes": [tile]]
        )
    }
    
    /// Handles the `Notification.Name.Demo.NodeHighlightingCleared` callback.
    ///
    /// - Parameter notification: event notification.
    @objc func nodeHighlightingCleared(notification: Notification) {
        currentTilemap?.enumerateChildNodes(withName: ".//*") { node, _ in
            if let tiledGeo = node as? TiledGeometryType {
                tiledGeo.isFocused = false
            }
        }
    }

    /// Handles the `Notification.Name.Demo.ObjectClicked` event.
    ///
    ///  object: `SKTileObject`
    ///
    /// - Parameter notification: event notification.
    @objc func objectClickedAction(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let object = notification.object as? SKTileObject else {
            return
        }
        
        focusedNodes.unfocusAll()
        focusedNodes.removeAll()
        focusedNodes.append(object)
        
        print("⭑ object is focused: \(object.isFocused)")
        
        /// event: `Notification.Name.Demo.NodeSelectionChanged`
        NotificationCenter.default.post(
            name: Notification.Name.Demo.NodeSelectionChanged,
            object: nil,
            userInfo: ["nodes": [object]]
        )
    }
    
    
    /// Called when the scene sends a key event for 'i'. Called when the `Notification.Name.Demo.IsolateSelectedEnabled` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func isolatedSelectedAction(notification: Notification) {
        guard (focusedNodes.isEmpty == false) else {
            updateCommandString("turning isolation off...", duration: 5)
            currentTilemap?.isolatedLayers = nil
            return
        }

        
        var selectedLayers: [TiledLayerObject]? = nil
        for node in focusedNodes {
            
            if let layer = node as? TiledLayerObject {
                if (selectedLayers == nil) {
                    selectedLayers = []
                }
                
                selectedLayers?.append(layer)
            }
            
            if let tile = node as? SKTile {
                selectedLayers?.append(tile.layer)
            }
            
            if let object = node as? SKTileObject {
               selectedLayers?.append(object.layer)
            }
        }
        
        
        guard let currentMap = currentTilemap else {
            log("tilemap not found.", level: .error)
            return
        }
        
        
        // toggle isolation
        if (currentMap.isolatedLayers != nil) {
            currentMap.isolatedLayers = nil
        } else {
            currentMap.isolatedLayers = selectedLayers
        }
        
        
        let currentlyIsolated = currentMap.isolatedLayers
        let logString = (currentlyIsolated == nil) ? "turning isolation off." : "isolating \(currentlyIsolated!.count) layers"
        updateCommandString(logString, duration: 5)
    }
    
    /// Called when the `Notification.Name.Globals.Updated` event fires. Changes selected nodes' highlight color.
    ///
    ///   userInfo: `["tileColor": SKColor, "objectColor": SKColor, "layerColor": SKColor]`
    ///
    /// - Parameter notification: event notification.
    @objc func globalsUpdatedAction(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }
        
        if let objectColor = userInfo["objectColor"] as? SKColor {
            focusedNodes.forEach { node in
                node.highlightNode(with: objectColor)
            }
        }
        
        
        if let tileColor = userInfo["tileColor"] as? SKColor {
            focusedNodes.forEach { node in
                node.highlightNode(with: tileColor)
            }
        }
        
        if let layerColor = userInfo["layerColor"] as? SKColor {
            focusedNodes.forEach { node in
                node.highlightNode(with: layerColor)
            }
        }
    }
    
    // MARK: - Debugging
    
    /// Handles the `Notification.Name.Demo.DumpSelectedNodes` callback. Changes selected nodes' highlight color.
    ///
    /// - Parameter notification: event notification.
    @objc func dumpSelectedNodes(notification: Notification) {
        guard (focusedNodes.isEmpty == false) else {
            updateCommandString("Error: nothing is selected.")
            return
        }
        
        let nodecount = focusedNodes.count
        let countdesc = (nodecount == 1) ? "node" : "nodes"
        let logmsg = "dumping \(nodecount) \(countdesc):"

        let logevent = log(logmsg, level: .info)
        let asciiLine = String(repeating: "-", count: logevent.rawString?.count ?? 40)
        
        
        for node in focusedNodes {
            print("\(asciiLine)\n")
            dump(node)
        }
    }

    
    /// Handles the `Notification.Name.Demo.HighlightSelectedNodes` callback. Changes selected nodes' highlight color.
    ///
    /// - Parameter notification: event notification.
    @objc func highlightSelectedNodes(notification: Notification) {
        guard (focusedNodes.isEmpty == false) else {
            updateCommandString("Error: nothing is selected.")
            return
        }

        for node in focusedNodes {
            if let tiledNode = node as? TiledGeometryType {
                tiledNode.highlightNode(with: SKColor.blue)
            }
        }
        updateCommandString("Highlighting selected nodes...", duration: 3.0)
    }
}



/// Singleton instance
let defaultDemoDelegate = TiledDemoDelegate()



// MARK: - Extensions


/// :nodoc:
extension TiledDemoDelegate: TiledCustomReflectableType {
    
    public func dumpStatistics() {
        var outputString = " Demo Delegate ".padEven(toLength: 40, withPad: "-")
        outputString = "\n\(outputString)\n"
        
        
        outputString += "  ▾ Camera:\n"
        outputString += "     ▸ Receive Camera Updates:      \(receiveCameraUpdates)\n"
        outputString += "     ▸ Camera Zoom:                 \(currentCameraZoom.stringRoundedTo(2))\n\n"
        
        if (focusedNodes.isEmpty == false) {
            
            outputString += "  ▾ Selected Nodes:\n"
            
            for node in focusedNodes {
                outputString += "     ▸  \(node.debugDescription) \n"
            }
        } else {
            outputString += "  ▸ Selected Nodes:         : none\n"
        }
        
        print("\(outputString)\n\n")
    }
}


extension TiledDemoDelegate: TiledSceneCameraDelegate {
    
    @objc public func cameraZoomChanged(newZoom: CGFloat) {
        //let oldZoom = currentCameraZoom
        currentCameraZoom = newZoom
    }
    
    @objc public func rightMouseDown(event: NSEvent) {}
}

