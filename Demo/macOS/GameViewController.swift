//
//  GameViewController.swift
//  SKTiled Demo - macOS
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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
import AppKit



/*
 fonts:
 SF Mono-12pt

 */
class GameViewController: NSViewController, Loggable {


    let demoController = TiledDemoController.default
    let demoDelegate = TiledDemoDelegate.default

    var uiColor: NSColor = NSColor(hexString: "#757B8D")
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    // debugging labels (top)
    @IBOutlet weak var outputTopView: NSStackView!
    @IBOutlet weak var mapDescriptionLabel: NSTextField!     // debug
    @IBOutlet weak var cameraInfoLabel: NSTextField!
    @IBOutlet weak var selectedInfoLabel: NSTextField!
    @IBOutlet weak var pauseInfoLabel: NSTextField!
    @IBOutlet weak var isolatedInfoLabel: NSTextField!


    // debugging labels (bottom)
    @IBOutlet weak var outputBottomView: NSStackView!
    @IBOutlet weak var mapInfoLabel: NSTextField!
    @IBOutlet weak var tileInfoLabel: NSTextField!
    @IBOutlet weak var propertiesInfoLabel: NSTextField!
    @IBOutlet weak var commandOutputLabel: NSTextField!

    // demo buttons
    @IBOutlet weak var fitButton: NSButton!
    @IBOutlet weak var gridButton: NSButton!
    @IBOutlet weak var graphButton: NSButton!
    @IBOutlet weak var objectsButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!

    @IBOutlet var demoFileAttributes: NSArrayController!


    // render stats
    @IBOutlet weak var statsStackView: NSStackView!
    @IBOutlet weak var statsRenderModeLabel: NSTextField!
    @IBOutlet weak var statsCPULabel: NSTextField!
    @IBOutlet weak var statsCacheSizeLabel: NSTextField!
    @IBOutlet weak var statsVisibleLabel: NSTextField!
    @IBOutlet weak var statsObjectsLabel: NSTextField!
    @IBOutlet weak var statsActionsLabel: NSTextField!
    @IBOutlet weak var statsEffectsLabel: NSTextField!
    @IBOutlet weak var statsUpdatedLabel: NSTextField!
    @IBOutlet weak var statsRenderLabel: NSTextField!


    var timer = Timer()
    var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    var commandBackgroundColor: NSColor = NSColor(calibratedWhite: 0.2, alpha: 0.25)

    // MARK: - Init

    override init(nibName: NSNib.Name?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }

    required init?(coder: NSCoder) {
        print("◆ [GameViewController]: initializing view controller...")
        super.init(coder: coder)
        setupNotifications()
    }

    // MARK: - Window & View

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = self.view as! SKView

        // setup the controller
        loggingLevel = TiledGlobals.default.loggingLevel
        demoController.loggingLevel = loggingLevel
        demoController.view = skView
        demoController.scanForResources()


        let hideRenderStats = TiledGlobals.default.enableRenderCallbacks == false
        var hideMapDescription = true

        skView.showsFPS = true
        skView.showsNodeCount = true

        #if DEBUG
        hideMapDescription = false
        skView.showsQuadCount = true
        skView.showsDrawCount = true
        #endif

        // SpriteKit optimizations
        skView.shouldCullNonVisibleNodes = true     // default is true
        skView.ignoresSiblingOrder = true           // default is false
        skView.isAsynchronous = true                // default is true
        skView.showsFields = true


        mapDescriptionLabel.isHidden = hideMapDescription
        selectedInfoLabel.isHidden = true


        // intialize the demo interface
        setupMainInterface()
        setupButtonAttributes()


        // render stats display
        statsStackView.isHidden = hideRenderStats

        // Load the initial scene.
        //demoController.loadNextScene()
        demoController.createEmptyScene()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupButtonAttributes()
    }

    override func viewWillTransition(to newSize: NSSize) {
        super.viewWillTransition(to: newSize)
        (self.view as? SKView)?.scene?.size = newSize
    }

    /// Update the window when resolution/dpi changes.
    ///
    /// - Parameter notification: event notification.
    @objc func windowDidChangeBackingProperties(notification: Notification) {
        guard (notification.object as? NSWindow != nil) else { return }
        let skView = self.view as! SKView
        if let tiledScene = skView.scene as? SKTiledDemoScene {
            if let tilemap = tiledScene.tilemap {

                NotificationCenter.default.post(
                    name: Notification.Name.Map.Updated,
                    object: tilemap,
                    userInfo: nil
                )
            }
        }
    }


    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Debug.DebuggingCommandSent, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.FlushScene, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileTouched, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.ObjectUnderCursor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.ObjectClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.MouseRightClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.UpdateModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tile.RenderModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeBackingPropertiesNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeAttributesChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodesRightClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodesAboutToBeSelected, object: nil)


        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.ResetDemoInterface, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.WillBeginScanForAssets, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.AssetsFinishedScanning, object: nil)

    }

    // MARK: - Interface & Setup

    /// Set up the debugging labels. (Mimics the text style in iOS controller).
    @objc func setupMainInterface() {
        mapInfoLabel.stringValue = ""
        tileInfoLabel.stringValue = ""
        propertiesInfoLabel.stringValue = ""
        cameraInfoLabel.stringValue = ""
        commandOutputLabel.stringValue = ""
        isolatedInfoLabel.stringValue = ""

        // text shadow
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 1, height: 2)
        shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.6)
        shadow.shadowBlurRadius = 0.1

        mapInfoLabel.shadow = shadow
        selectedInfoLabel.shadow = shadow
        tileInfoLabel.shadow = shadow
        propertiesInfoLabel.shadow = shadow
        commandOutputLabel.shadow = shadow
        cameraInfoLabel.shadow = shadow
        pauseInfoLabel.shadow = shadow
        isolatedInfoLabel.shadow = shadow

        statsRenderModeLabel.shadow = shadow
        statsCPULabel.shadow = shadow
        statsCacheSizeLabel.shadow = shadow
        statsVisibleLabel.shadow = shadow
        statsObjectsLabel.shadow = shadow
        statsActionsLabel.shadow = shadow
        statsEffectsLabel.shadow = shadow
        statsUpdatedLabel.shadow = shadow
        statsRenderLabel.shadow = shadow
        statsUpdatedLabel.isHidden = true

        // hide the data views until we need them
        setDebuggingViewsActive(visible: false)
        view.layer?.backgroundColor = SKColor(hexString: "#222").cgColor
    }

    /// Resets the main interface to its original state.
    @objc func resetMainInterface() {

        let defaultValue = ""

        mapInfoLabel.stringValue = defaultValue
        tileInfoLabel.stringValue = defaultValue
        propertiesInfoLabel.stringValue = defaultValue
        cameraInfoLabel.stringValue = defaultValue
        isolatedInfoLabel.stringValue = defaultValue


        /// debugging
        outputBottomView.isHidden = false
        mapInfoLabel.isHidden = false
        tileInfoLabel.isHidden = false
        propertiesInfoLabel.isHidden = false
        cameraInfoLabel.isHidden = false
        isolatedInfoLabel.isHidden = false

        // stacks
        outputTopView.isHidden = false
        statsStackView.isHidden = false
        statsStackView.isHidden = true
    }

    /// Global toggle for debug view visibility.
    ///
    /// - Parameter visible: views are visible.
    func setDebuggingViewsActive(visible: Bool = true) {
        let viewIsHidden = !visible

        /// if camera callbacks are disabled, we shouldn't see the render stats view.
        let canReceiveRenderStats = TiledGlobals.default.enableRenderCallbacks == false

        outputTopView.isHidden = viewIsHidden

        //outputBottomView.isHidden = viewIsHidden
        mapInfoLabel.isHidden = viewIsHidden
        tileInfoLabel.isHidden = viewIsHidden
        propertiesInfoLabel.isHidden = viewIsHidden
        statsStackView.isHidden = canReceiveRenderStats && visible == true
    }

    /// Set up the control buttons.
    func setupButtonAttributes() {

        let normalBevel: CGFloat = 4
        let allButtons = [fitButton, gridButton, graphButton, objectsButton, nextButton]

        // set the button attributes
        allButtons.forEach { button in
            if let button = button {
                button.wantsLayer = true
                if #available(OSX 10.12.2, *) {
                    button.bezelColor = uiColor
                }
                button.layer?.shadowColor = uiColor.darken(by: 1.0).cgColor
                button.layer?.cornerRadius = normalBevel
                button.layer?.backgroundColor = uiColor.cgColor
            }
        }
    }

    private func setupNotifications() {
        // demo
        NotificationCenter.default.addObserver(self, selector: #selector(mapUpdatedAction), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(debuggingInfoReceived), name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCommandString), name: Notification.Name.Debug.DebuggingCommandSent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneFlushedAction), name: Notification.Name.Demo.FlushScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoControllerAboutToScanForAssets), name: Notification.Name.DemoController.WillBeginScanForAssets, object: nil)

        // mouse events
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderMouseChanged), name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderMouseClicked), name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderMouseClicked), name: Notification.Name.Demo.TileTouched, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectUnderMouseChanged), name: Notification.Name.Demo.ObjectUnderCursor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectUnderMouseClicked), name: Notification.Name.Demo.ObjectClicked, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(mouseRightClickAction), name: Notification.Name.Demo.MouseRightClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChanged), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)


        // tilemap callbacks
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatsUpdated), name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapUpdateModeChanged), name: Notification.Name.Map.UpdateModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneCameraUpdated), name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatisticsVisibilityChanged), name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileRenderModeChanged), name: Notification.Name.Tile.RenderModeChanged, object: nil)

        // resolution/content scale change
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidChangeBackingProperties), name: NSWindow.didChangeBackingPropertiesNotification, object: nil)

        // testing
        NotificationCenter.default.addObserver(self, selector: #selector(nodeAttributesChanged), name: Notification.Name.Demo.NodeAttributesChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodesRightClicked), name: Notification.Name.Demo.NodesRightClicked, object: nil)

        // new!!
        NotificationCenter.default.addObserver(self, selector: #selector(resetMainInterfaceAction), name: Notification.Name.DemoController.ResetDemoInterface, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoControllerFinishedScanningAssets), name: Notification.Name.DemoController.AssetsFinishedScanning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoControllerResetAction), name: Notification.Name.DemoController.WillBeginScanForAssets, object: nil)

        // inspector
        NotificationCenter.default.addObserver(self, selector: #selector(nodesAboutToBeSelected), name: Notification.Name.Demo.NodesAboutToBeSelected, object: nil)
    }

    // MARK: - Command Strings

    /// Update the the command string label. Called when the `Notification.Name.Debug.DebuggingCommandSent` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func updateCommandString(notification: Notification) {
        guard (commandOutputLabel.isHidden == false) else {
            return
        }


        var duration: TimeInterval = 3.0
        var commandString: String?
        if let commandValue = notification.userInfo!["command"] {
            commandString = commandValue as? String
        }

        if let commandDuration = notification.userInfo!["duration"] {
            if let durationValue = commandDuration as? TimeInterval {
                duration = durationValue
            }
        }

        setCommandString(commandString, duration: duration)
    }

    /// Set the current command.
    ///
    /// - Parameters:
    ///   - value: string command.
    ///   - duration: length of effect.
    @objc func setCommandString(_ value: String?, duration: TimeInterval) {
        guard let commandString = value else {
            return
        }
        timer.invalidate()

        commandOutputLabel.stringValue = "\(commandString)"
        commandOutputLabel.backgroundColor = commandBackgroundColor

        guard (duration > 0) else { return }
        timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(GameViewController.resetCommandLabel), userInfo: nil, repeats: true)
    }

    /// Reset the command string label.
    @objc func resetCommandLabel() {
        timer.invalidate()
        commandOutputLabel.setStringValue("", animated: true, interval: 0.75)
        commandOutputLabel.backgroundColor = NSColor(calibratedWhite: 0.0, alpha: 0.0)
    }


    // MARK: - Bottom Control Button Actions

    /// Action called when `fit to view` button is pressed.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func fitButtonPressed(_ sender: Any) {
        self.demoController.fitSceneToView()
    }

    /// Action called when `show grid` button is pressed.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func gridButtonPressed(_ sender: Any) {
        self.demoController.toggleMapDemoDrawGridAndBounds()
    }

    /// Action called when `show graph` button is pressed.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func graphButtonPressed(_ sender: Any) {
        self.demoController.toggleMapGraphVisualization()
    }

    /// Action called when `show objects` button is pressed.
    ///
    /// - Parameter sender:  invoking ui element.
    @IBAction func objectsButtonPressed(_ sender: Any) {
        self.demoController.toggleMapObjectDrawing()
    }

    /// Action called when `next` button is pressed.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func nextButtonPressed(_ sender: Any) {
        self.demoController.loadNextScene()
    }

    /// Action called when `effects` button is pressed.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func effectsButtonPressed(_ sender: Any) {
        self.demoController.toggleTilemapEffectsRendering()
    }

    // MARK: - Mouse & Keyboard Events

    override var acceptsFirstResponder: Bool {
        return true
    }

    /// Mouse scroll wheel event handler.
    ///
    /// - Parameter event: mouse event.
    override func scrollWheel(with event: NSEvent) {
        guard let view = self.view as? SKView else {
            return
        }

        if let currentScene = view.scene {
            currentScene.scrollWheel(with: event)
        }
    }

    // MARK: - Notification Handlers

    /// Update the interface when a map has been parsed & loaded. Called when the `Notification.Name.Map.Updated` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func mapUpdatedAction(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        var wintitle = TiledGlobals.default.windowTitle
        guard let tilemap = notification.object as? SKTilemap else {
            log("invalid or nil map sent.", level: .error)
            return
        }

        /// unhide the data views
        setDebuggingViewsActive(visible: true)

        // set the window title
        wintitle += ": \(tilemap.url.filename)"
        self.view.window?.title = wintitle


        // set the map description label
        let mapDescription = tilemap.tiledNodeDescription
        let mapDescriptionString = (mapDescription != nil) ? "description: \(mapDescription!)" : "description: none"
        let showMapDescriptionLabel = (mapDescription != nil) && (TiledGlobals.default.isDemo == true)

        self.mapDescriptionLabel.isHidden = !showMapDescriptionLabel
        self.mapDescriptionLabel.stringValue = mapDescriptionString
        self.mapDescriptionLabel.textColor = NSColor(hexString: "#CCCCCC")
    }

    /// Show/hide the current SpriteKit render stats.
    ///
    /// - Parameter notification: notification event.
    @objc func renderStatisticsVisibilityChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let view = self.view as? SKView else { return }

        if let showRenderStats = notification.userInfo!["showRenderStats"] as? Bool {
            view.showsFPS = showRenderStats
            view.showsQuadCount = showRenderStats
            view.showsNodeCount = showRenderStats
            view.showsDrawCount = showRenderStats
            view.showsPhysics = showRenderStats
            view.showsFields = showRenderStats

            statsStackView.isHidden = !showRenderStats

        }
    }

    /// Update the debugging labels with various scene information.
    ///
    /// - Parameter notification: notification event.
    @objc func debuggingInfoReceived(notification: Notification) {
        // notification.dump(#fileID, function: #function)

        tileInfoLabel.stringValue = ""
        propertiesInfoLabel.stringValue = ""


        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.stringValue = mapInfo as! String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.stringValue = tileInfo as! String
        }

        if let propertiesInfo = notification.userInfo!["focusedObjectData"] {
            if let propertiesString = propertiesInfo as? String {
                if propertiesString != "" {
                    propertiesInfoLabel.stringValue = propertiesString
                }
            }
        }

        if let pauseInfo = notification.userInfo!["pauseInfo"] {
            pauseInfoLabel.stringValue = pauseInfo as! String
        }

        if let isolatedInfo = notification.userInfo!["isolatedInfo"] {
            isolatedInfoLabel.stringValue = isolatedInfo as! String
        }
    }

    /// Called when node values are changed via the demo inspector. Called when the `Notification.Name.Demo.NodeAttributesChanged` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func nodeAttributesChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: [SKNode]] else {
            return
        }


        if let changedNodes = userInfo["updated"] {
            for node in changedNodes {
                if let tilemap = node as? SKTilemap {

                    NotificationCenter.default.post(
                        name: Notification.Name.Map.Updated,
                        object: tilemap,
                        userInfo: nil
                    )
                }
            }
        }
    }

    /// Build a right-click menu to select nodes at the click event location. Called when the `Notification.Name.Demo.NodesRightClicked` notification is sent.
    ///
    ///  - expects a user dictionary value of ["nodes": [`SKNode`], "locationInWindow": `CGPoint`]
    ///
    /// - Parameter notification: event notification.
    @objc func nodesRightClicked(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let skView = self.view as? SKView else {

            log("cannot access SpriteKit view.", level: .warning)
            return
        }


        if (demoDelegate.currentNodes.isEmpty == false) {
            demoDelegate.reset()
            return
        }

        if let nodesUnderMouse = userInfo["nodes"] as? [SKNode] {

            /// build a right-click menu
            let nodesMenu = NSMenu()
            let titleMenuItem = NSMenuItem(title: "Select a node (\(nodesUnderMouse.count) nodes)", action: nil, keyEquivalent: "")
            titleMenuItem.image = NSImage(named: "selection-icon")
            titleMenuItem.isEnabled = false
            nodesMenu.addItem(titleMenuItem)
            nodesMenu.addItem(NSMenuItem.separator())

            var firstNode: SKNode!

            for node in nodesUnderMouse {
                if (firstNode == nil) {
                    firstNode = node
                }

                var nodeImageName = "node-icon"
                var nodeNameString = node.className
                if let tiledNode = node as? TiledCustomReflectableType {
                    nodeNameString = tiledNode.tiledListDescription ?? "tiled node"
                    nodeImageName = tiledNode.tiledIconName ?? "node-icon"
                }

                if let nodeName = node.name {
                    nodeNameString += ": '\(nodeName)'"
                }

                let thisNodeMenuItem = NSMenuItem(title: nodeNameString, action: #selector(handleSceneRightClickAction(_:)), keyEquivalent: "")
                thisNodeMenuItem.image = NSImage(named: nodeImageName)
                thisNodeMenuItem.identifier = NSUserInterfaceItemIdentifier(rawValue: "\(node.hash)")
                nodesMenu.addItem(thisNodeMenuItem)

                //let parentCount = (node.allParents().count - 1 < 0) ? 0 : node.allParents().count - 1
                //thisNodeMenuItem.indentationLevel = parentCount
            }

            skView.menu = nodesMenu

            if let positionInWindow = userInfo["positionInWindow"] as? NSPoint {
                nodesMenu.popUp(positioning: nil, at: positionInWindow, in: skView)
            }
        }
    }

    // MARK: - Mouse Event Handlers

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.ObjectUnderCursor` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func objectUnderMouseChanged(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let object = notification.object as? SKTileObject else {
            return
        }

        // check for
        object.highlightNode(with: TiledGlobals.default.debug.objectHighlightColor, duration: TiledGlobals.default.debug.highlightDuration)
        tileInfoLabel.stringValue = object.description

        propertiesInfoLabel.isHidden = false
        propertiesInfoLabel.attributedStringValue = object.propertiesAttributedString(delineator: nil)

        print("⭑ object highlighted!")
    }

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.ObjectClicked` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func objectUnderMouseClicked(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        if let object = notification.object as? SKTileObject {

            object.drawNodeBounds(with: object.frameColor, lineWidth: 0.25, fillOpacity: 0, duration: 5)
            tileInfoLabel.stringValue = object.description

            propertiesInfoLabel.isHidden = false
            propertiesInfoLabel.attributedStringValue = object.propertiesAttributedString(delineator: nil)

            //perform(#selector(clearCurrentObject), with: nil, afterDelay: 5)
        }
    }

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.TileUnderCursor` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func tileUnderMouseChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let clickedTile = notification.object as? SKTile else {
            return
        }

        clickedTile.drawNodeBounds(with: clickedTile.frameColor, lineWidth: 0.25, fillOpacity: 0.2, duration: TiledGlobals.default.debug.highlightDuration)
        tileInfoLabel.stringValue = clickedTile.description

        propertiesInfoLabel.isHidden = false
        propertiesInfoLabel.attributedStringValue = clickedTile.tileData.propertiesAttributedString(delineator: nil)

        clickedTile.highlightNode(with: clickedTile.highlightColor, duration: 1)
    }

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.TileClicked` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func tileUnderMouseClicked(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        if let focusedTile = notification.object as? SKTile {
            propertiesInfoLabel.isHidden = false
            propertiesInfoLabel.stringValue = focusedTile.description
            focusedTile.highlightNode(with: focusedTile.highlightColor, duration: 2)
            // TODO: properties string should include tile data (id, etc).
            propertiesInfoLabel.attributedStringValue = focusedTile.tileData.propertiesAttributedString(delineator: nil)
        }
    }

    // MARK: - Right-Click Handlers

    /// Handler for the view's right-click menu action.
    ///
    /// - Parameter sender: menu item.
    @objc private func handleSceneRightClickAction(_ sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem,
              let identifier = menuItem.identifier else {
            return
        }


        guard let view = demoController.view,
              let scene = view.scene as? SKTiledDemoScene else {
            return
        }

        // identifier is the node's hash value
        let stringIdentifier = identifier.rawValue
        scene.enumerateChildNodes(withName: ".//*") { node, stop in
            let hashString = "\(node.hash)"
            if (hashString == stringIdentifier) {

                /// event: `Notification.Name.Demo.NodeSelectionChanged`
                NotificationCenter.default.post(
                    name: Notification.Name.Demo.NodeSelectionChanged,
                    object: nil,
                    userInfo: ["nodes": [node], "focusLocation": scene.convert(node.position, to: scene)]
                )
                stop.pointee = true
            }
        }
    }

    // MARK: - Reset

    /// Called when the inspector tree selection changes. Called when the `Notification.Name.DemoController.ResetDemoInterface` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func resetMainInterfaceAction(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        resetMainInterface()
        //demoController.flushScene()
    }

    /// Called when the user begins a new selection. Called when the `Notification.Name.Demo.NodesAboutToBeSelected` notification is sent.
    ///
    ///  - expects a userInfo of `["nodes": [SKNode]]`
    ///
    /// - Parameter notification: event notification.
    @objc func nodesAboutToBeSelected(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)
        selectedInfoLabel.isHidden = true
    }


    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.NodeSelectionChanged` notification is sent.
    ///
    ///  - expects a userInfo of `["nodes": [SKNode]]`
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let selectedNodes = userInfo["nodes"] as? [SKNode] else {
            return
        }

        // represents the position in the current scene to move to
        var focusLocation: CGPoint?


        if let nodePosition = userInfo["focusLocation"] as? CGPoint {
            focusLocation = nodePosition
        }

        selectedInfoLabel.isHidden = true

        let selectedCount = selectedNodes.count

        if (selectedCount == 0) {
            return
        }

        let isSingleSelection = (selectedCount == 1)
        if (isSingleSelection == true) {
            if let selected = selectedNodes.first {
                if let tiledNode = selected as? TiledCustomReflectableType {

                    selectedInfoLabel.isHidden = false

                    let attributedString = NSMutableAttributedString()
                    let selectedColor = NSColor(hexString: "#6DD400")
                    let selectedStyle = NSMutableParagraphStyle()
                    selectedStyle.alignment = .left


                    let selectedAttributes = [
                        .foregroundColor: selectedColor,
                        .paragraphStyle: selectedStyle
                    ] as [NSAttributedString.Key: Any]

                    let selectedLabelString = NSMutableAttributedString(string: "Selected: ", attributes: selectedAttributes)
                    attributedString.append(selectedLabelString)
                    attributedString.append(NSAttributedString(string: selected.description))

                    selectedInfoLabel.attributedStringValue = attributedString
                }
            }
        } else {
            //selectedNode = nil
            selectedInfoLabel.isHidden = false


            let selectedColor = NSColor(hexString: "#6DD400")
            let selectedStyle = NSMutableParagraphStyle()
            selectedStyle.alignment = .left


            let selectedAttributes = [
                .foregroundColor: selectedColor,
                .paragraphStyle: selectedStyle
            ] as [NSAttributedString.Key: Any]

            selectedInfoLabel.attributedStringValue = NSMutableAttributedString(string: "\(selectedCount) nodes selected", attributes: selectedAttributes)

        }
    }

    /// Handles the `Notification.Name.Demo.MouseRightClicked` callback.
    ///
    /// - Parameter notification: event notification.
    @objc func mouseRightClickAction(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        selectedInfoLabel.isHidden = true
        selectedInfoLabel.stringValue = ""
    }

    /// Update the tile property label. Called when the `Notification.Name.Tile.RenderModeChanged` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func tileRenderModeChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let tile = notification.object as? SKTile else { return }
        propertiesInfoLabel.stringValue = tile.description
    }


    /// Callback when cache is updated.
    ///
    /// - Parameter notification: event notification.
    @objc func tilemapUpdateModeChanged(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let tilemap = notification.object as? SKTilemap else { return }
        self.statsRenderModeLabel.stringValue = "Mode: \(tilemap.updateMode.name)"
    }

    /// Update the camera debug information. Called when the `Notification.Name.Debug.Camera.Updated` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func sceneCameraUpdated(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let camera = notification.object as? SKTiledSceneCamera else {
            return
        }
        cameraInfoLabel.stringValue = camera.description
        statsVisibleLabel.isHidden = (camera.notifyDelegatesOnContainedNodesChange == false)
    }


    /// Enables/disable button controls based on the current map attributes. Called when the `Notification.Name.Map.Updated` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func tilemapWasUpdated(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let tilemap = notification.object as? SKTilemap else { return }

        if (tilemap.hasKey("uiColor")) {
            if let hexString = tilemap.stringForKey("uiColor") {
                self.uiColor = NSColor(hexString: hexString)
            }
        }

        let effectsEnabled = (tilemap.shouldEnableEffects == true)
        let effectsMessage = (effectsEnabled == true) ? (tilemap.shouldRasterize == true) ? "Effects: on (raster)" : "Effects: on" : "Effects: off"
        statsRenderModeLabel.stringValue = "Mode: \(tilemap.updateMode.name)"
        statsEffectsLabel.stringValue = "\(effectsMessage)"
        statsEffectsLabel.isHidden = (effectsEnabled == false)
        statsVisibleLabel.stringValue = "Visible: \(tilemap.nodesInView.count)"
        //statsVisibleLabel.isHidden = (TiledGlobals.default.enableCameraCallbacks == false)

        let graphsCount = tilemap.graphs.count
        let hasGraphs = (graphsCount > 0)

        var graphAction = "show"
        for layer in tilemap.tileLayers() {
            if layer.debugDrawOptions.contains(.drawGraph) {
                graphAction = "hide"
            }
        }

        let graphButtonTitle = (graphsCount > 0) ? (graphsCount > 1) ? "\(graphAction) graphs" : "\(graphAction) graph" : "no graphs"
        let hasObjects: Bool = (tilemap.getObjects().isEmpty == false)

        /// ISOLATED LAYERS
        let isolatedLayers = tilemap.getLayers().filter({ $0.isolated == true})
        var isolatedInfoString = ""

        if (isolatedLayers.isEmpty == false) {
            isolatedInfoString = "Isolated: "
            let isolatedLayerNames: [String] = isolatedLayers.map { "'\($0.layerName)'" }
            isolatedInfoString += isolatedLayerNames.joined(separator: ", ")
        }

        isolatedInfoLabel.stringValue = isolatedInfoString
        graphButton.isHidden = !hasGraphs
        //graphButton.isEnabled = (graphsCount > 0)
        objectsButton.isEnabled = hasObjects


        gridButton.title = (tilemap.debugDrawOptions.contains(.drawGrid)) ? "hide grid" : "show grid"
        objectsButton.title = (hasObjects == true) ? (tilemap.isShowingObjectBounds == true) ? "hide objects" : "show objects" : "show objects"
        graphButton.title = graphButtonTitle
        setupButtonAttributes()


        // clean up render stats
        statsCPULabel.isHidden = false
        statsActionsLabel.isHidden = (tilemap.updateMode != .actions)
        statsObjectsLabel.isHidden = false
    }


    /// Clear the current scene ('k' key pressed).


    /// Called when the current scene is about to unload. Called when the `Notification.Name.Demo.SceneWillUnload` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func sceneWillUnloadAction(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)

        setupMainInterface()
        let wintitle = TiledGlobals.default.windowTitle
        self.view.window?.title = wintitle
        selectedInfoLabel.stringValue = ""
        selectedInfoLabel.isHidden = true
    }

    /// Clear the current scene ('k' key pressed)..
    ///
    /// Triggered when the `Notification.Name.Demo.FlushScene` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func sceneFlushedAction() {
        demoController.flushScene()
        setupMainInterface()

        self.view.window?.title = "\(TiledGlobals.default.windowTitle) : ~"

        resetMainInterface()
    }

    /// Called when the `DemoController` is about to scan for assets.
    ///
    /// Triggered when the `Notification.Name.DemoController.WillBeginScanForAssets` event fires.
    ///
    /// - Parameter notification: event notification.
    @IBAction func demoControllerAboutToScanForAssets(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        resetMainInterface()
        progressIndicator.startAnimation(nil)
        progressIndicator.isHidden = false
    }

    /// Called when the demo controller has loaded the current assets. Called when the `Notification.Name.DemoController.AssetsFinishedScanning` notification is sent.
    ///  userInfo: ["tilemapAssets": `[TiledDemoAsset]`]
    ///
    /// - Parameter notification: event notification.
    @objc func demoControllerFinishedScanningAssets(_ notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: [TiledDemoAsset]],
              let tilemapUrls = userInfo["tilemapAssets"] else {
            fatalError("cannot access asset urls")
        }

        progressIndicator.isHidden = true

        /// start the demo here
        demoController.loadNextScene()
    }

    /// Called when the demo controller has loaded the current assets. Called when the `Notification.Name.DemoController.AssetsFinishedScanning` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func demoControllerResetAction(_ notification: Notification) {
        demoController.reset()
    }


    // MARK: - Debugging

    /// Updates the render stats debugging info. Called when the `Notification.Name.Map.RenderStatsUpdated` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func renderStatsUpdated(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let renderStats = notification.object as? SKTilemap.RenderStatistics else {
            self.statsStackView.isHidden = true
            return
        }

        self.statsRenderModeLabel.stringValue = "Mode: \(renderStats.updateMode.name)"
        self.statsVisibleLabel.stringValue = "Visible: \(renderStats.visibleCount)"
        //self.statsVisibleLabel.isHidden = (TiledGlobals.default.enableCameraCallbacks == false)
        self.statsObjectsLabel.isHidden = (renderStats.objectsVisible == false)
        self.statsObjectsLabel.stringValue = "Objects: \(renderStats.objectCount)"
        self.statsCPULabel.attributedStringValue  = renderStats.processorAttributedString
        self.statsCacheSizeLabel.stringValue = "Cache Size: \(renderStats.cacheSize.description)"


        let renderString = (TiledGlobals.default.timeDisplayMode == .seconds) ? String(format: "%.\(String(6))f", renderStats.renderTime) : String(format: "%.\(String(2))f", renderStats.renderTime.milleseconds)
        let timeFormatString = (TiledGlobals.default.timeDisplayMode == .seconds) ? "s" : "ms"
        self.statsRenderLabel.stringValue = "Render time: \(renderString)\(timeFormatString)"

        self.statsUpdatedLabel.isHidden = (renderStats.updateMode == .actions)
        self.statsUpdatedLabel.stringValue = "Updated: \(renderStats.updatedThisFrame)"

        let actionCountString = (renderStats.actionsCount > 0) ? "\(renderStats.actionsCount)" : "--"
        self.statsActionsLabel.stringValue = "Actions: \(actionCountString)"


    }
}
