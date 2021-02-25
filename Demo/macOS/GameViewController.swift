//
//  GameViewController.swift
//  SKTiled Demo - macOS
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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

    var receiveCameraUpdates: Bool = true

    var uiColor: NSColor = NSColor(hexString: "#dddddd")
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var demoStatusInfoLabel: NSTextField!

    // debugging labels (top)
    @IBOutlet weak var outputTopView: NSStackView!
    @IBOutlet weak var mapDescriptionLabel: NSTextField!     // debug
    @IBOutlet weak var cameraInfoLabel: NSTextField!
    @IBOutlet weak var selectedInfoLabel: NSTextField!
    @IBOutlet weak var isolatedInfoLabel: NSTextField!


    // debugging labels (bottom)
    @IBOutlet weak var outputBottomView: NSStackView!
    @IBOutlet weak var mapInfoLabel: NSTextField!
    @IBOutlet weak var tileInfoLabel: NSTextField!
    @IBOutlet weak var propertiesInfoLabel: NSTextField!
    @IBOutlet weak var debuggingMessageLabel: NSTextField!

    
    // demo buttons
    @IBOutlet weak var controlButtonView: NSStackView!
    @IBOutlet weak var fitButton: NSButton!
    @IBOutlet weak var gridButton: NSButton!
    @IBOutlet weak var graphButton: NSButton!
    @IBOutlet weak var objectsButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!


    // render stats
    @IBOutlet weak var statsStackView: NSStackView!
    @IBOutlet weak var statsRenderModeLabel: NSTextField!
    @IBOutlet weak var statsCPULabel: NSTextField!
    @IBOutlet weak var statsCacheSizeLabel: NSTextField!
    @IBOutlet weak var statsVisibleLabel: NSTextField!
    @IBOutlet weak var statsTrackingViewsLabel: NSTextField!
    @IBOutlet weak var statsObjectsLabel: NSTextField!
    @IBOutlet weak var statsActionsLabel: NSTextField!
    @IBOutlet weak var statsEffectsLabel: NSTextField!
    @IBOutlet weak var statsUpdatedLabel: NSTextField!
    @IBOutlet weak var statsRenderLabel: NSTextField!

    @IBOutlet var demoFileAttributes: NSArrayController!
    
    var timer = Timer()
    var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    var commandBackgroundColor: NSColor = NSColor(calibratedWhite: 0.2, alpha: 0.25)

    // MARK: - Initialization

    override init(nibName: NSNib.Name?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNotifications()
    }

    deinit {

        NotificationCenter.default.removeObserver(self, name: Notification.Name.Debug.DebuggingMessageSent, object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.UpdateModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.RenderStats.VisibilityChanged, object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name.Tile.RenderModeChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.FlushScene, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileTouched, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.ObjectUnderCursor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.ObjectClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionCleared, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeAttributesChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodesRightClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.SceneLoaded, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.NodeSelectionCleared, object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.ResetDemoInterface, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.WillBeginScanForAssets, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.AssetsFinishedScanning, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.DemoController.DemoStatusUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeBackingPropertiesNotification, object: nil)
    }

    // MARK: - Demo Start

    /// Called when the demo controller has loaded the current assets. Called when the `Notification.Name.DemoController.AssetsFinishedScanning` notification is received.
    ///
    ///  userInfo: ["tilemapAssets": `[TiledDemoAsset]`]
    ///
    /// - Parameter notification: event notification.
    @objc func demoControllerFinishedScanningAssets(_ notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: [TiledDemoAsset]],
              let tilemapUrls = userInfo["tilemapAssets"] else {
            return
        }

        //let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        progressIndicator.isHidden = true


        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.setupNotifications()

        /// start the demo here
        demoController.loadNextScene()
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

        // start the demo here
        demoController.scanForResources()

        skView.showsFPS = true
        skView.showsNodeCount = true

        #if DEBUG
        skView.showsQuadCount = true
        skView.showsDrawCount = true
        #endif

        // SpriteKit optimizations
        skView.shouldCullNonVisibleNodes = true     // default is true
        skView.ignoresSiblingOrder = true           // default is false
        skView.isAsynchronous = true                // default is true
        skView.showsFields = true


        mapDescriptionLabel.isHidden = true
        selectedInfoLabel.isHidden = true


        // intialize the demo interface
        setupMainInterface()
        setupButtonAttributes()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupButtonAttributes()
        //presentFullScreen()
    }

    override func viewWillTransition(to newSize: NSSize) {
        super.viewWillTransition(to: newSize)
        (self.view as? SKView)?.scene?.size = newSize
    }
    
    /// Enter full-screen mode.
    func presentFullScreen() {
        guard let mainScreen = NSScreen.main else {
            return
        }
        
        var presentingOptions = NSApplication.PresentationOptions()
        presentingOptions.insert(.hideDock)
        presentingOptions.insert(.hideMenuBar)
        //presentingOptions.insert(.disableAppleMenu)
        presentingOptions.insert(.disableProcessSwitching)
        presentingOptions.insert(.disableSessionTermination)
        presentingOptions.insert(.disableHideApplication)
        presentingOptions.insert(.autoHideToolbar)
        
        let optionsDictionary = [NSView.FullScreenModeOptionKey.fullScreenModeApplicationPresentationOptions: presentingOptions.rawValue]
        
        self.view.enterFullScreenMode(mainScreen, withOptions: optionsDictionary)
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

    // MARK: - Interface & Setup

    /// Set up the debugging labels. (Mimics the text style in iOS controller).
    @objc func setupMainInterface() {
        mapInfoLabel.reset()
        tileInfoLabel.reset()
        propertiesInfoLabel.reset()
        cameraInfoLabel.reset()
        debuggingMessageLabel.reset()
        isolatedInfoLabel.reset()
        
        demoStatusInfoLabel.textColor = uiColor
        demoStatusInfoLabel.stringValue = "please select a file to load"

        // text shadow
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 1, height: 2)
        shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.6)
        shadow.shadowBlurRadius = 0.1

        mapInfoLabel.shadow = shadow
        selectedInfoLabel.shadow = shadow
        tileInfoLabel.shadow = shadow
        propertiesInfoLabel.shadow = shadow
        debuggingMessageLabel.shadow = shadow
        cameraInfoLabel.shadow = shadow
        demoStatusInfoLabel.shadow = shadow
        isolatedInfoLabel.shadow = shadow

        statsRenderModeLabel.shadow = shadow
        statsCPULabel.shadow = shadow
        statsCacheSizeLabel.shadow = shadow
        statsVisibleLabel.shadow = shadow
        statsObjectsLabel.shadow = shadow
        statsTrackingViewsLabel.shadow = shadow
        statsActionsLabel.shadow = shadow
        statsEffectsLabel.shadow = shadow
        statsUpdatedLabel.shadow = shadow
        statsRenderLabel.shadow = shadow
        statsUpdatedLabel.isHidden = true

        // hide the data views until we need them
        setDebuggingViewsActive(visible: false)
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
        statsStackView.isHidden = true
        controlButtonView.isHidden = true

        setDebuggingViewsActive(visible: false)

        view.layer?.backgroundColor = SKColor(hexString: "#3D5761").cgColor  // 😈
        view.wantsLayer = true
    }

    /// Global toggle for debug view visibility.
    ///
    /// - Parameter visible: views are visible.
    func setDebuggingViewsActive(visible: Bool = true) {
        let viewIsHidden = !visible

        /// if render callbacks are disabled, we shouldn't see the render stats view.
        let canReceiveRenderStats = TiledGlobals.default.enableRenderPerformanceCallbacks == true

        // hide all of the labels to allow the debug message label to stay visible
        //mapInfoLabel.isHidden = viewIsHidden
        //tileInfoLabel.isHidden = viewIsHidden
        //propertiesInfoLabel.isHidden = viewIsHidden


        // toggle stack visiblity
        outputTopView.isHidden = viewIsHidden
        statsStackView.isHidden = canReceiveRenderStats == false || viewIsHidden == true

        // toggle control buttons
        controlButtonView.isHidden = viewIsHidden
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
        NotificationCenter.default.addObserver(self, selector: #selector(demoSceneLoaded), name: Notification.Name.Demo.SceneLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mapUpdatedAction), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(debuggingInfoReceived), name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(debuggingMessageReceived), name: Notification.Name.Debug.DebuggingMessageSent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneFlushedAction), name: Notification.Name.Demo.FlushScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillUnloadAction), name: Notification.Name.Demo.SceneWillUnload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoControllerAboutToScanForAssets), name: Notification.Name.DemoController.WillBeginScanForAssets, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionCleared), name: Notification.Name.Demo.NodeSelectionCleared, object: nil)

        // mouse events
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderMouseChanged), name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderMouseClicked), name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderMouseClicked), name: Notification.Name.Demo.TileTouched, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectUnderMouseChanged), name: Notification.Name.Demo.ObjectUnderCursor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectUnderMouseClicked), name: Notification.Name.Demo.ObjectClicked, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(nodesRightClickedAction), name: Notification.Name.Demo.NodesRightClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionChanged), name: Notification.Name.Demo.NodeSelectionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nodeSelectionCleared), name: Notification.Name.Demo.NodeSelectionCleared, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nothingUnderCursor), name: Notification.Name.Demo.NothingUnderCursor, object: nil)


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
        NotificationCenter.default.addObserver(self, selector: #selector(resetMainInterfaceAction), name: Notification.Name.DemoController.ResetDemoInterface, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoControllerFinishedScanningAssets), name: Notification.Name.DemoController.AssetsFinishedScanning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(demoControllerResetAction), name: Notification.Name.DemoController.WillBeginScanForAssets, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(demoStatusWasUpdated), name: Notification.Name.DemoController.DemoStatusUpdated, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
    }

    // MARK: - Command Strings

    /// Update the the command string label. Called when the `Notification.Name.Debug.DebuggingMessageSent` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func debuggingMessageReceived(notification: Notification) {
        guard (debuggingMessageLabel.isHidden == false) else {
            return
        }

        var duration: TimeInterval = 3.0
        var commandString: String?
        if let commandValue = notification.userInfo!["message"] {
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

        debuggingMessageLabel.stringValue = "\(commandString)"
        debuggingMessageLabel.backgroundColor = commandBackgroundColor

        guard (duration > 0) else { return }
        timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(GameViewController.resetCommandLabel), userInfo: nil, repeats: true)
    }

    /// Reset the command string label.
    @objc func resetCommandLabel() {
        timer.invalidate()
        debuggingMessageLabel.setStringValue("", animated: true, interval: 0.75)
        debuggingMessageLabel.backgroundColor = NSColor(calibratedWhite: 0.0, alpha: 0.0)
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

    /// Called when a new scene has been loaded. Called when the `Notification.Name.Demo.SceneLoaded` event fires.
    ///
    ///  object is `SKTiledScene`, userInfo: ["tilemapName": `String`, "relativePath": `String`, "currentMapIndex": `Int`]
    ///
    /// - Parameter notification: event notification.
    @objc func demoSceneLoaded(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let demoScene = notification.object as? SKTiledScene else {
            fatalError("cannot access scene.")
        }

        demoScene.cameraNode?.addDelegate(self)
    }
    
    
    /// Indicates the `TiledGlobals` have been updated. Called when the `Notification.Name.Globals.Updated` notification is received.
    ///
    /// - Parameter notification: notification event.
    @objc func globalsUpdatedAction(notification: Notification) {
        notification.dump(#fileID, function: #function)

        let hideRenderStatsUI = TiledGlobals.default.enableRenderPerformanceCallbacks == false
        statsStackView.isHidden = hideRenderStatsUI
        
        guard let view = self.view as? SKView else { return }
        view.showsFPS = !hideRenderStatsUI
        view.showsQuadCount = !hideRenderStatsUI
        view.showsNodeCount = !hideRenderStatsUI
        view.showsDrawCount = !hideRenderStatsUI
        view.showsPhysics = !hideRenderStatsUI
        view.showsFields = !hideRenderStatsUI
    }
    
    /// Update the interface when a map has been parsed & loaded. Called when the `Notification.Name.Map.Updated` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func mapUpdatedAction(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        var wintitle = TiledGlobals.default.windowTitle
        guard let tilemap = notification.object as? SKTilemap else {
            log("invalid or nil map sent.", level: .error)
            return
        }

        /// hide the progress indicator
        progressIndicator.stopAnimation(nil)
        progressIndicator.isHidden = true

        /// unhide the data views
        setDebuggingViewsActive(visible: true)

        // set the window title
        wintitle += ": \(tilemap.url.filename)"
        self.view.window?.title = wintitle


        // get the background color for the view
        let skView = view as! SKView
        if let mapBackgroundColor = tilemap.backgroundColor {
            skView.layer?.backgroundColor = mapBackgroundColor.cgColor
            skView.wantsLayer = true
        }

        // set the map description label
        var showMapDescriptionLabel = false
        if let mapDescriptionString = tilemap.tiledNodeDescription {
            showMapDescriptionLabel = true
            self.mapDescriptionLabel.stringValue = mapDescriptionString
        }

        self.mapDescriptionLabel.isHidden = !showMapDescriptionLabel
        self.mapDescriptionLabel.textColor = NSColor(hexString: "#CCCCCC")

        /// update the selected node label
        if let selected = Array(demoDelegate.focusedNodes).first {
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

    /// Show/hide the current SpriteKit render stats. Called when the `Notification.Name.RenderStats.VisibilityChanged` notification is received.
    ///
    ///  - expects a userInfo of `["isHidden": Bool]`
    ///
    /// - Parameter notification: notification event.
    @objc func renderStatisticsVisibilityChanged(notification: Notification) {
        notification.dump(#fileID, function: #function)
        guard let view = self.view as? SKView else { return }

        if let showRenderStats = notification.userInfo!["isHidden"] as? Bool {
            
            view.showsFPS = !showRenderStats
            view.showsQuadCount = !showRenderStats
            view.showsNodeCount = !showRenderStats
            view.showsDrawCount = !showRenderStats
            view.showsPhysics = !showRenderStats
            view.showsFields = !showRenderStats

            statsStackView.isHidden = showRenderStats

        }
    }

    /// Update the debugging labels with various scene information. Called when node values are changed via the demo inspector. Called when the `Notification.Name.Demo.UpdateDebugging` notification is received.
    ///
    ///  userInfo: `["mapInfo": String, "mapInfo": String, "focusedObjectData": String, "cameraInfo": String, "screenInfo": String, "isolatedInfo": String]`
    ///
    /// - Parameter notification: notification event.
    @objc func debuggingInfoReceived(notification: Notification) {
        notification.dump(#fileID, function: #function)

        tileInfoLabel.reset()
        propertiesInfoLabel.reset()
        tileInfoLabel.reset()
        
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.stringValue = mapInfo as! String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.stringValue = tileInfo as! String
        }

        if let propertiesInfo = notification.userInfo!["focusedObjectData"] {
            if let propertiesString = propertiesInfo as? String {
                if (propertiesString != "") {
                    propertiesInfoLabel.stringValue = propertiesString
                }
            }
        }

        if let isolatedInfo = notification.userInfo!["isolatedInfo"] {
            isolatedInfoLabel.stringValue = isolatedInfo as! String
        }
    }

    /// Called when node values are changed via the demo inspector. Called when the `Notification.Name.Demo.NodeAttributesChanged` notification is received.
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

    /// Builds a right-click menu to select nodes at the click event location. Called when the `Notification.Name.Demo.NodesRightClicked` notification is sent (via the `SKTiledSceneCamera` node).
    ///
    ///  - expects a user dictionary value of `["nodes": [SKNode], "locationInWindow": CGPoint]`
    ///
    /// - Parameter notification: event notification.
    @objc func nodesRightClickedAction(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }

        /// clear the demo delegate's selected nodes...
        if (demoDelegate.focusedNodes.isEmpty == false) {
            demoDelegate.reset()
            return
        }


        var layerNodes: [TiledLayerObject] = []
        var filteredNodes: [SKNode] = []
        var mapNode: SKTilemap?
        
        if let nodesUnderMouse = userInfo["nodes"] as? [SKNode] {

            for node in nodesUnderMouse {
                if let map = node as? SKTilemap {
                    mapNode = map
                    continue
                }

                if node.isHighlightable == true {
                    filteredNodes.append(node)
                    continue
                }
                
                if let layer = node as? TiledLayerObject {
                    guard layer as? TiledBackgroundLayer == nil else {
                        continue
                    }
                    layerNodes.append(layer)
                    continue
                }
            }
        
        } else {
            log("no nodes were sent!", level: .error)
        }
        
        
        var resultLayers: [SKNode] = layerNodes.sorted(by: { $0.realIndex < $1.realIndex }) as [SKNode]
        
        if let map = mapNode {
            resultLayers.insert(map, at: 0)
        }


        let index = filteredNodes.count
        filteredNodes.append(contentsOf: resultLayers)

        var positionInWindow = NSPoint.zero
        if let pointInCamera = userInfo["positionInWindow"] as? NSPoint {
            positionInWindow = pointInCamera
        }

        // build the menu
        buildNodesRightClickMenu(nodes: filteredNodes, highlightableIndex: index, at: positionInWindow)
    }

    /// Builds a popup menu with a list of included nodes.
    ///
    /// - Parameters:
    ///   - nodes: selectable nodes.
    ///   - highlightableIndex: renderable objects index.
    ///   - positionInWindow: the point in the main window where the menu will be drawn.
    func buildNodesRightClickMenu(nodes: [SKNode],
                                  highlightableIndex: Int,
                                  at positionInWindow: NSPoint = NSPoint.zero) {
        
        guard let skView = self.view as? SKView else {
            log("cannot access SpriteKit view.", level: .warning)
            return
        }

        guard (nodes.isEmpty == false) else {
            return
        }


        /// build a right-click menu
        let nodesMenu = NSMenu()
        let titleMenuItem = NSMenuItem(title: "Select a node (\(nodes.count) nodes)", action: nil, keyEquivalent: "")
        titleMenuItem.image = NSImage(named: "selection-icon")
        titleMenuItem.isEnabled = false
        nodesMenu.addItem(titleMenuItem)
        nodesMenu.addItem(NSMenuItem.separator())


        var firstNode: SKNode!
        var previousIndentationLevel = 0

        // loop through the nodes...
        for (index, node) in nodes.enumerated() {

            if index == highlightableIndex {
                nodesMenu.addItem(NSMenuItem.separator())
            }


            // filter out the first node...
            if (firstNode == nil) {
                firstNode = node
            }

            var currentIndenationLevel = 0

            var nodeImageName = "node-icon"
            var nodeNameString = node.className
            if let tiledNode = node as? TiledCustomReflectableType {

                nodeNameString = tiledNode.tiledMenuItemDescription ?? "tiled node"
                nodeImageName = tiledNode.tiledIconName ?? "node-icon"

                if let mappableNode = tiledNode as? TiledMappableGeometryType {
                    nodeNameString = mappableNode.tiledMenuItemDescription ?? "tiled node"

                    // add indentation for layers
                    if let layerNode = tiledNode as? TiledLayerObject {
                        let parentCount = layerNode.parents.count
                        currentIndenationLevel = (parentCount > 0) ? parentCount - 1 : 0
                    }
                }
            }

            let thisNodeMenuItem = NSMenuItem(title: nodeNameString, action: #selector(handleSceneRightClickAction(_:)), keyEquivalent: "")
            thisNodeMenuItem.image = NSImage(named: nodeImageName)
            thisNodeMenuItem.representedObject = node
            thisNodeMenuItem.indentationLevel = currentIndenationLevel
            nodesMenu.addItem(thisNodeMenuItem)
            previousIndentationLevel = currentIndenationLevel
        }

        // build the menu
        skView.menu = nodesMenu
        nodesMenu.popUp(positioning: nil, at: positionInWindow, in: skView)
    }

    // MARK: - Mouse Event Handlers

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.ObjectUnderCursor` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func objectUnderMouseChanged(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let focusedObject = notification.object as? SKTileObject else {
            return
        }
        
        // set debug attribute labels
        tileInfoLabel.isHidden = false
        tileInfoLabel.stringValue = focusedObject.description
        
        propertiesInfoLabel.isHidden = false
        propertiesInfoLabel.attributedStringValue = focusedObject.propertiesAttributedString(delineator: nil)
        
        // highlight the object
        let highlightDuration = TiledGlobals.default.debugDisplayOptions.highlightDuration
        focusedObject.drawNodeBounds(with: focusedObject.frameColor, lineWidth: 0.25, fillOpacity: 0, duration: highlightDuration)
        focusedObject.isFocused = true
    }

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.ObjectClicked` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func objectUnderMouseClicked(notification: Notification) {
        notification.dump(#fileID, function: #function)
        guard let focusedObject = notification.object as? SKTileObject else {
            return
        }
        
        // set debug attribute labels
        tileInfoLabel.isHidden = false
        tileInfoLabel.stringValue = focusedObject.description
        
        propertiesInfoLabel.isHidden = false
        propertiesInfoLabel.attributedStringValue = focusedObject.propertiesAttributedString(delineator: nil)
        
        // highlight the object
        focusedObject.drawNodeBounds(with: focusedObject.frameColor, lineWidth: 0.25, fillOpacity: 0, duration: 0)
        focusedObject.isFocused = true
        // perform(#selector(clearCurrentObject), with: nil, afterDelay: 5)
    }
    

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.TileUnderCursor` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func tileUnderMouseChanged(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let focusedTile = notification.object as? SKTile else {
            return
        }
        
        // set debug attribute labels
        tileInfoLabel.isHidden = false
        tileInfoLabel.stringValue = focusedTile.description

        propertiesInfoLabel.isHidden = false
        propertiesInfoLabel.attributedStringValue = focusedTile.tileData.propertiesAttributedString(delineator: nil)
        
        // highlight the tile
        let highlightDuration = TiledGlobals.default.debugDisplayOptions.highlightDuration
        focusedTile.highlightNode(with: focusedTile.highlightColor, duration: highlightDuration)
        focusedTile.isFocused = true
    }

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.TileClicked` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func tileUnderMouseClicked(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        guard let focusedTile = notification.object as? SKTile else {
            return
        }
        
        // set debug attribute labels
        tileInfoLabel.isHidden = false
        tileInfoLabel.stringValue = focusedTile.description
        
        propertiesInfoLabel.isHidden = false
        propertiesInfoLabel.attributedStringValue = focusedTile.tileData.propertiesAttributedString(delineator: nil)
        
        // highlight the tile
        focusedTile.highlightNode(with: focusedTile.highlightColor, duration: 0)
        focusedTile.isFocused = true
    }
    
    /// Called when the mouse is hovering over nothing. Called when the `Notification.Name.Demo.NothingUnderCursor` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func nothingUnderCursor(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        tileInfoLabel.reset()
        propertiesInfoLabel.reset()
    }

    // MARK: - Right-Click Handlers

    /// Handler for the view's right-click menu items. The `NSMenuItem.representedObject` is the node's hash value.
    ///
    /// - Parameter sender: menu item.
    @objc private func handleSceneRightClickAction(_ sender: AnyObject) {
        propertiesInfoLabel.reset()
        selectedInfoLabel.reset()
        guard let menuItem = sender as? NSMenuItem,
              let node = menuItem.representedObject as? SKNode else {
            return
        }

        guard let skView = view as? SKView,
              let scene = skView.scene as? SKTiledDemoScene else {
            return
        }

        /// calls back to the AppDelegate to build the `Selected Node` menu.
        /// calls back to the demo delegate and highlights the selected nodes
        /// calls back to this object to set the selection label
        NotificationCenter.default.post(
            name: Notification.Name.Demo.NodeSelectionChanged,
            object: nil,
            userInfo: ["nodes": [node], "focusLocation": scene.convert(node.position, to: scene)]
        )
    }

    // MARK: - Reset

    /// Called when the inspector tree selection changes. Called when the `Notification.Name.DemoController.ResetDemoInterface` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func resetMainInterfaceAction(notification: Notification) {
        // notification.dump(#fileID, function: #function)
        resetMainInterface()
    }

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.NodeSelectionChanged` notification is received.
    ///
    ///  - expects a userInfo of `["nodes": [SKNode], "focusLocation": CGPoint]`
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionChanged(notification: Notification) {
        notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let selectedNodes = userInfo["nodes"] as? [SKNode] else {
            return
        }

        // represents the position in the current scene to move to
        var focusLocation: CGPoint?


        if let nodePosition = userInfo["focusLocation"] as? CGPoint {
            focusLocation = nodePosition
        }

        
        
        tileInfoLabel.reset()
        selectedInfoLabel.reset()
        propertiesInfoLabel.reset()

        let selectedCount = selectedNodes.count

        if (selectedCount == 0) {
            return
        }

        let isSingleSelection = (selectedCount == 1)
        if (isSingleSelection == true) {

            // show only th first node....
            if let selected = selectedNodes.first {
                
                var anchorColor = TiledGlobals.default.debugDisplayOptions.tileHighlightColor
                var anchorRadius: CGFloat = TiledGlobals.default.debugDisplayOptions.anchorRadius
                
                if let tilemap = demoController.currentTilemap {
                    anchorRadius = tilemap.tileSize.width / 6
                }

                
                if let tiledSprite = selected as? SKTile {
                    anchorColor = tiledSprite.highlightColor
                }

                var zoomScale: CGFloat = 0.25
                if let scene = selected.scene as? SKTiledScene {
                    zoomScale = scene.cameraNode?.zoom ?? 0.25
                }

                drawAnchor(selected, radius: anchorRadius, anchorColor: anchorColor, zoomScale: zoomScale)
                
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

    /// Called when the focus objects in the demo scene have changed. Called when the `Notification.Name.Demo.NodeSelectionCleared` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func nodeSelectionCleared(notification: Notification) {
        selectedInfoLabel.reset()
        tileInfoLabel.reset()
        propertiesInfoLabel.reset()
    }

    /// Update the tile property label. Called when the `Notification.Name.Tile.RenderModeChanged` notification is received.
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

    /// Update the camera debug information. Called when the `Notification.Name.Debug.Camera.Updated` notification is received.
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


    /// Enables/disable button controls based on the current map attributes. Called when the `Notification.Name.Map.Updated` notification is received.
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

    /// Called when the current scene is about to unload. Called when the `Notification.Name.Demo.SceneWillUnload` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func sceneWillUnloadAction(_ notification: Notification) {
        notification.dump(#fileID, function: #function)

        setupMainInterface()
        let wintitle = TiledGlobals.default.windowTitle
        self.view.window?.title = wintitle

        selectedInfoLabel.stringValue = ""
        selectedInfoLabel.isHidden = true

        demoStatusInfoLabel.stringValue = "please select a file to load"
        demoStatusInfoLabel.isHidden = false


        progressIndicator.startAnimation(nil)
        progressIndicator.isHidden = false
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
        notification.dump(#fileID, function: #function)
        resetMainInterface()

        progressIndicator.startAnimation(nil)
        progressIndicator.isHidden = false
    }

    /// Called when the demo controller has loaded the current assets. Called when the `Notification.Name.DemoController.AssetsFinishedScanning` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func demoControllerResetAction(_ notification: Notification) {
        demoController.reset()
    }

    /// Called when any of the demo helpers updates. Called when the `Notification.Name.DemoController.DemoStatusUpdated` notification is received.
    ///
    ///  - looks for userInfo of `["status": String, "isHidden": Bool, "color": SKColor]`
    ///
    /// - Parameter notification: event notification.
    @objc func demoStatusWasUpdated(_ notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let userInfo = notification.userInfo as? [String: Any],
              let statusMessage = userInfo["status"] as? String,
              let statusIsHidden = userInfo["isHidden"] as? Bool else {
            return
        }

        demoStatusInfoLabel.stringValue = statusMessage
        demoStatusInfoLabel.isHidden = statusIsHidden

        var statusColor = uiColor
        if let newColor = userInfo["color"] as? SKColor {
            statusColor = newColor
        }

        demoStatusInfoLabel.textColor = statusColor
    }

    // MARK: - Debugging

    /// Updates the render stats debugging info. Called when the `Notification.Name.Map.RenderStatsUpdated` notification is received.
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
        self.statsTrackingViewsLabel.isHidden = (renderStats.trackingViews == 0)
        self.statsTrackingViewsLabel.stringValue = "Tracking Views: \(renderStats.trackingViews)"
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



// MARK: - Extensions

extension GameViewController: TiledSceneCameraDelegate {

    /// Called when the scene is right-clicked **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc func sceneRightClicked(event: NSEvent) {
        selectedInfoLabel.isHidden = true
        selectedInfoLabel.stringValue = "Nothing Selected"
    }
}
