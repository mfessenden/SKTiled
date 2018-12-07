//
//  GameViewController.swift
//  SKTiled Demo - macOS
//
//  Created by Michael Fessenden on 9/19/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//
//  macOS Game View Controller

import Cocoa
import SpriteKit
import AppKit


class GameViewController: NSViewController, Loggable {

    let demoController = DemoController.default
    var uiColor: NSColor = NSColor(hexString: "#757B8D")

    // debugging labels (top)
    @IBOutlet weak var outputTopView: NSStackView!
    @IBOutlet weak var cameraInfoLabel: NSTextField!
    @IBOutlet weak var isolatedInfoLabel: NSTextField!    // macOS only
    @IBOutlet weak var pauseInfoLabel: NSTextField!


    // debugging labels (bottom)
    @IBOutlet weak var outputBottomView: NSStackView!
    @IBOutlet weak var mapInfoLabel: NSTextField!
    @IBOutlet weak var tileInfoLabel: NSTextField!
    @IBOutlet weak var propertiesInfoLabel: NSTextField!
    @IBOutlet weak var debugInfoLabel: NSTextField!

    // demo buttons
    @IBOutlet weak var fitButton: NSButton!
    @IBOutlet weak var gridButton: NSButton!
    @IBOutlet weak var graphButton: NSButton!
    @IBOutlet weak var objectsButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!

    @IBOutlet var demoFileAttributes: NSArrayController!
    @IBOutlet weak var screenInfoLabel: NSTextField!


    // render stats
    @IBOutlet weak var statsStackView: NSStackView!
    @IBOutlet weak var statsHeaderLabel: NSTextField!
    @IBOutlet weak var statsRenderModeLabel: NSTextField!
    @IBOutlet weak var statsCPULabel: NSTextField!
    @IBOutlet weak var statsVisibleLabel: NSTextField!
    @IBOutlet weak var statsObjectsLabel: NSTextField!
    @IBOutlet weak var statsActionsLabel: NSTextField!
    @IBOutlet weak var statsEffectsLabel: NSTextField!
    @IBOutlet weak var statsUpdatedLabel: NSTextField!
    @IBOutlet weak var statsRenderLabel: NSTextField!

    var timer = Timer()
    var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel
    var commandBackgroundColor: NSColor = NSColor(calibratedWhite: 0.2, alpha: 0.25)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = self.view as! SKView

        // setup the controller
        loggingLevel = TiledGlobals.default.loggingLevel
        demoController.loggingLevel = loggingLevel
        demoController.view = skView

        guard let currentURL = demoController.currentURL else {
            log("no tilemap to load.", level: .warning)
            return
        }

        #if DEBUG
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.showsPhysics = false
        #endif

        // SpriteKit optimizations
        skView.shouldCullNonVisibleNodes = true
        skView.ignoresSiblingOrder = true

        // intialize the demo interface
        setupDemoInterface()
        setupButtonAttributes()

        // notifications
        
        // demo
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebuggingOutput), name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(focusObjectsChanged), name: Notification.Name.Demo.FocusObjectsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCommandString), name: Notification.Name.Debug.CommandIssued, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateWindowTitle), name: Notification.Name.Demo.WindowTitleUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(flushScene), name: Notification.Name.Demo.FlushScene, object: nil)
        
        // tilemap callbacks
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatsUpdated), name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapUpdateModeChanged), name: Notification.Name.Map.UpdateModeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneCameraUpdated), name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatisticsVisibilityChanged), name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilePropertiesChanged), name: Notification.Name.Tile.RenderModeChanged, object: nil)

        // resolution/content scale change
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidChangeBackingProperties), name: NSWindow.didChangeBackingPropertiesNotification, object: nil)
        
        // create the game scene
        demoController.loadScene(url: currentURL, usePreviousCamera: demoController.preferences.usePreviousCamera)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupButtonAttributes()
    }

    override func viewWillTransition(to newSize: NSSize) {
        super.viewWillTransition(to: newSize)
        (self.view as? SKView)?.scene?.size = newSize
    }

    /**
     Set up the debugging labels. (Mimics the text style in iOS controller).
     */
    func setupDemoInterface() {
        mapInfoLabel.stringValue = ""
        tileInfoLabel.stringValue = ""
        propertiesInfoLabel.stringValue = ""
        cameraInfoLabel.stringValue = "--"
        debugInfoLabel.stringValue = ""
        isolatedInfoLabel.stringValue = ""

        // text shadow
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 1, height: 2)
        shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.6)
        shadow.shadowBlurRadius = 0.1

        mapInfoLabel.shadow = shadow
        tileInfoLabel.shadow = shadow
        propertiesInfoLabel.shadow = shadow
        debugInfoLabel.shadow = shadow
        cameraInfoLabel.shadow = shadow
        pauseInfoLabel.shadow = shadow
        isolatedInfoLabel.shadow = shadow

        statsHeaderLabel.shadow = shadow
        statsRenderModeLabel.shadow = shadow
        statsCPULabel.shadow = shadow
        statsVisibleLabel.shadow = shadow
        statsObjectsLabel.shadow = shadow
        statsActionsLabel.shadow = shadow
        statsEffectsLabel.shadow = shadow
        statsUpdatedLabel.shadow = shadow
        statsRenderLabel.shadow = shadow
        statsUpdatedLabel.isHidden = true
    }

    /**
     Set up the control buttons.
     */
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

    /**
     Action called when `fit to view` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func fitButtonPressed(_ sender: Any) {
        self.demoController.fitSceneToView()
    }

    /**
     Action called when `show grid` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func gridButtonPressed(_ sender: Any) {
        self.demoController.toggleMapDemoDrawGridAndBounds()
    }

    /**
     Action called when `show graph` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func graphButtonPressed(_ sender: Any) {
        self.demoController.toggleMapGraphVisualization()
    }

    /**
     Action called when `show objects` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func objectsButtonPressed(_ sender: Any) {
        self.demoController.toggleMapObjectDrawing()
    }

    /**
     Action called when `next` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func nextButtonPressed(_ sender: Any) {
        self.demoController.loadNextScene()
    }

    // MARK: - Mouse Events

    /**
     Mouse scroll wheel event handler.

     - parameter event: `NSEvent` mouse event.
     */
    override func scrollWheel(with event: NSEvent) {
        guard let view = self.view as? SKView else { return }

        if let currentScene = view.scene as? SKTiledScene {
            currentScene.scrollWheel(with: event)
        }
    }

    /**
     Update the window when resolution/dpi changes.

     - parameter notification: `Notification` callback.
     */
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

    /**
     Update the window's title bar with the current scene name.

     - parameter notification: `Notification` callback.
     */
    @objc func updateWindowTitle(notification: Notification) {
        if let wintitle = notification.userInfo!["wintitle"] {
            if let infoDictionary = Bundle.main.infoDictionary {
                if let bundleName = infoDictionary[kCFBundleNameKey as String] as? String {
                    self.view.window?.title = "\(bundleName): \(wintitle as! String)"
                }
            }
        }
    }

    /**
     Show/hide the current SpriteKit render stats.

     - parameter notification: `Notification` callback.
     */
    @objc func renderStatisticsVisibilityChanged(notification: Notification) {
        guard let view = self.view as? SKView else { return }
        if let showRenderStats = notification.userInfo!["showRenderStats"] as? Bool {
            view.showsFPS = showRenderStats
            view.showsNodeCount = showRenderStats
            view.showsDrawCount = showRenderStats
            view.showsPhysics = showRenderStats
            view.showsFields = showRenderStats

            statsStackView.isHidden = !showRenderStats
        }
    }

    /**
     Update the debugging labels with scene information.

     - parameter notification: `Notification` notification.
     */
    @objc func updateDebuggingOutput(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.stringValue = mapInfo as! String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.stringValue = tileInfo as! String
        }

        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            propertiesInfoLabel.stringValue = propertiesInfo as! String
        }

        if let pauseInfo = notification.userInfo!["pauseInfo"] {
            pauseInfoLabel.stringValue = pauseInfo as! String
        }

        if let isolatedInfo = notification.userInfo!["isolatedInfo"] {
            isolatedInfoLabel.stringValue = isolatedInfo as! String
        }
    }

    /**
     Called when the focus objects in the demo scene have changed.

     - parameter notification: `Notification` notification.
     */
    @objc func focusObjectsChanged(notification: Notification) {
        guard let focusObjects = notification.object as? [SKTiledGeometry],
            let userInfo = notification.userInfo as? [String: Any],
            let tilemap = userInfo["tilemap"] as? SKTilemap else { return }


        if let tileDataStorage = tilemap.dataStorage {
            for object in tileDataStorage.objectsList {
                if let proxy = object.proxy {
                    let isFocused = focusObjects.contains(where: { $0 as? TileObjectProxy == proxy })
                    proxy.isFocused = isFocused
                }
            }
        }
    }

    /**
     Update the tile property label.

     - parameter notification: `Notification` notification.
     */
    @objc func tilePropertiesChanged(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        propertiesInfoLabel.stringValue = tile.description
    }

    /**
     Callback when cache is updated.

     - parameter notification: `Notification` notification.
     */
    @objc func tilemapUpdateModeChanged(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else { return }
        self.statsRenderModeLabel.stringValue = "Mode: \(tilemap.updateMode.name)"
    }

    /**
     Update the camera debug information.

     - parameter notification: `Notification` notification.
     */
    @objc func sceneCameraUpdated(notification: Notification) {
        guard let camera = notification.object as? SKTiledSceneCamera else {
            fatalError("no camera!!")
        }
        cameraInfoLabel.stringValue = camera.description
    }

    /**
     Update the the command string label.

     - parameter notification: `Notification` notification.
     */
    @objc func updateCommandString(notification: Notification) {
        timer.invalidate()
        var duration: TimeInterval = 3.0
        if let commandString = notification.userInfo!["command"] {
            let commandFormatted = commandString as! String
            debugInfoLabel.stringValue = "\(commandFormatted)"
            debugInfoLabel.backgroundColor = commandBackgroundColor
            //debugInfoLabel.drawsBackground = true
        }

        if let commandDuration = notification.userInfo!["duration"] {
            duration = commandDuration as! TimeInterval
        }

        guard (duration > 0) else { return }
        timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(GameViewController.resetCommandLabel), userInfo: nil, repeats: true)
    }


    /**
     Reset the command string label.
     */
    @objc func resetCommandLabel() {
        timer.invalidate()
        debugInfoLabel.setStringValue("", animated: true, interval: 0.75)
        debugInfoLabel.backgroundColor = NSColor(calibratedWhite: 0.0, alpha: 0.0)
    }

    /**
     Enables/disable button controls based on the current map attributes.

     - parameter notification: `Notification` notification.
     */
     @objc func tilemapWasUpdated(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else { return }

        if (tilemap.hasKey("uiColor")) {
            if let hexString = tilemap.stringForKey("uiColor") {
                self.uiColor = NSColor(hexString: hexString)
            }
        }

        let effectsEnabled = (tilemap.shouldEnableEffects == true)
        let effectsMessage = (effectsEnabled == true) ? (tilemap.shouldRasterize == true) ? "Effects: on (raster)" : "Effects: on" : "Effects: off"
        statsHeaderLabel.stringValue = "Rendering: \(TiledGlobals.default.renderer.name)"
        statsRenderModeLabel.stringValue = "Mode: \(tilemap.updateMode.name)"
        statsEffectsLabel.stringValue = "\(effectsMessage)"
        statsEffectsLabel.isHidden = (effectsEnabled == false)
        statsVisibleLabel.stringValue = "Visible: \(tilemap.nodesInView.count)"
        statsVisibleLabel.isHidden = (TiledGlobals.default.enableCameraCallbacks == false)

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
            let isolatedLayerNames: [String] = isolatedLayers.map { "\"\($0.layerName)\"" }
            isolatedInfoString += isolatedLayerNames.joined(separator: ", ")
        }

        isolatedInfoLabel.stringValue = isolatedInfoString
        graphButton.isHidden = !hasGraphs
        //graphButton.isEnabled = (graphsCount > 0)
        objectsButton.isEnabled = hasObjects


        gridButton.title = (tilemap.debugDrawOptions.contains(.drawGrid)) ? "hide grid" : "show grid"
        objectsButton.title = (hasObjects == true) ? (tilemap.showObjects == true) ? "hide objects" : "show objects" : "show objects"
        graphButton.title = graphButtonTitle
        setupButtonAttributes()


        // clean up render stats
        statsCPULabel.isHidden = false
        statsActionsLabel.isHidden = (tilemap.updateMode != .actions)
        statsObjectsLabel.isHidden = false
     }

    /**
     Clear the current scene.
     */
    @objc func flushScene() {
        demoController.flushScene()
        setupDemoInterface()
    }

    // MARK: - Debugging


    /**
     Updates the render stats debugging info.

     - parameter notification: `Notification` notification.
     */
    @objc func renderStatsUpdated(notification: Notification) {
        guard let renderStats = notification.object as? SKTilemap.RenderStatistics else { return }

        self.statsHeaderLabel.stringValue = "Rendering: \(TiledGlobals.default.renderer.name)"
        self.statsRenderModeLabel.stringValue = "Mode: \(renderStats.updateMode.name)"
        self.statsVisibleLabel.stringValue = "Visible: \(renderStats.visibleCount)"
        self.statsVisibleLabel.isHidden = (TiledGlobals.default.enableCameraCallbacks == false)
        self.statsObjectsLabel.isHidden = (renderStats.objectsVisible == false)
        self.statsObjectsLabel.stringValue = "Objects: \(renderStats.objectCount)"
        self.statsCPULabel.attributedStringValue  = renderStats.processorAttributedString
        let renderString = (TiledGlobals.default.timeDisplayMode == .seconds) ? String(format: "%.\(String(6))f", renderStats.renderTime) : String(format: "%.\(String(2))f", renderStats.renderTime.milleseconds)
        let timeFormatString = (TiledGlobals.default.timeDisplayMode == .seconds) ? "s" : "ms"
        self.statsRenderLabel.stringValue = "Render time: \(renderString)\(timeFormatString)"


        self.statsUpdatedLabel.isHidden = (renderStats.updateMode == .actions)
        self.statsUpdatedLabel.stringValue = "Updated: \(renderStats.updatedThisFrame)"
    }
}


extension NSTextField {
    /**
     Set the string value of the text field, with optional animated fade.

     - parameter newValue: `String` new text value.
     - parameter animated: `Bool` enable fade out effect.
     - parameter interval: `TimeInterval` effect length.
     */
    func setStringValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard stringValue != newValue else { return }
        if animated {
            animate(change: { self.stringValue = newValue }, interval: interval)
        } else {
            stringValue = newValue
        }
    }

    /**
     Set the attributed string value of the text field, with optional animated fade.

     - parameter newValue: `NSAttributedString` new attributed string value.
     - parameter animated: `Bool` enable fade out effect.
     - parameter interval: `TimeInterval` effect length.
     */
    func setAttributedStringValue(_ newValue: NSAttributedString, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard attributedStringValue != newValue else { return }
        if animated {
            animate(change: { self.attributedStringValue = newValue }, interval: interval)
        }
        else {
            attributedStringValue = newValue
        }
    }

    /**
     Highlight the label with the given color.

     - parameter color: `NSColor` label color.
     - parameter interval: `TimeInterval` effect length.
     */
    func highlighWith(color: NSColor, interval: TimeInterval = 3.0) {
        animate(change: {
            self.textColor = color
        }, interval: interval)
    }

    /**
     Private function to animate a fade effect.

     - parameter change: `() -> Void` closure.
     - parameter interval: `TimeInterval` effect length.
     */
    fileprivate func animate(change: @escaping () -> Void, interval: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = interval / 2.0
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animator().alphaValue = 0.0
        }, completionHandler: {
            change()
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = interval / 2.0
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                self.animator().alphaValue = 1.0
            }, completionHandler: {})
        })
    }
}
