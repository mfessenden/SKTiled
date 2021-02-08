//
//  GameViewController.swift
//  SKTiled Demo - iOS
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

import UIKit
import SpriteKit


class GameViewController: UIViewController, Loggable {


    let demoController = TiledDemoController.default
    var uiColor: UIColor = UIColor(hexString: "#757B8D")
    var hideDeviceRotationIcon: Bool = false

    // debugging labels (top)
    @IBOutlet weak var rotateDeviceIcon: UIImageView!
    @IBOutlet weak var cameraInfoLabel: UILabel!
    @IBOutlet weak var demoStatusInfoLabel: UILabel!



    // debugging labels (bottom)
    @IBOutlet weak var mapInfoLabel: UILabel!
    @IBOutlet weak var tileInfoLabel: UILabel!
    @IBOutlet weak var propertiesInfoLabel: UILabel!
    @IBOutlet weak var debuggingMessageLabel: UILabel!


    // demo buttons
    @IBOutlet weak var fitButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var graphButton: UIButton!
    @IBOutlet weak var objectsButton: UIButton!
    @IBOutlet weak var effectsButton: UIButton!
    @IBOutlet weak var renderStatsButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!


    @IBOutlet weak var controlsView: UIStackView!

    // camera mode icons
    @IBOutlet weak var controlIconView: UIStackView!

    @IBOutlet var demoFileAttributes: NSObject!

    // render stats
    @IBOutlet weak var statsStackView: UIStackView!
    @IBOutlet weak var statsRenderModeLabel: UILabel!
    @IBOutlet weak var statsCPULabel: UILabel!
    @IBOutlet weak var statsVisibleLabel: UILabel!
    @IBOutlet weak var statsObjectsLabel: UILabel!
    @IBOutlet weak var statsActionsLabel: UILabel!
    @IBOutlet weak var statsEffectsLabel: UILabel!
    @IBOutlet weak var statsUpdatedLabel: UILabel!
    @IBOutlet weak var statsRenderLabel: UILabel!



    var landscapeInitialized: Bool = false
    var timer = Timer()
    var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = self.view as! SKView
        loggingLevel = TiledGlobals.default.loggingLevel

        // setup the controller
        demoController.loggingLevel = loggingLevel
        demoController.view = skView
        demoController.scanForResources()


        skView.showsFPS = true
        skView.isAsynchronous = true

        #if DEBUG
        skView.showsQuadCount = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.showsPhysics = false
        #endif

        /* SpriteKit optimizations */
        skView.shouldCullNonVisibleNodes = true
        skView.ignoresSiblingOrder = true
        skView.showsFields = true

        // initialize the demo interface
        setupMainInterface()
        setupButtonAttributes()
        setupNotifications()

        // Load the initial scene.
        demoController.loadNextScene()

        // rotate device icon
        addWiggleAnimationToView(viewToAnimate: rotateDeviceIcon)
    }

    /// Adds a `wiggle` animation to the device icon.
    ///
    /// - Parameter viewToAnimate: `UIView` to animate.
    func addWiggleAnimationToView(viewToAnimate: UIView) {
        let easeInOutTiming = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        let wiggle = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        wiggle.duration = 1.000
        wiggle.values = [0.000, 1.571, 1.571, 0.000] as [Float]
        wiggle.keyTimes = [0.000, 0.275, 0.625, 1.000] as [NSNumber]
        wiggle.timingFunctions = [easeInOutTiming, easeInOutTiming, easeInOutTiming]
        wiggle.repeatCount = HUGE
        viewToAnimate.layer.add(wiggle, forKey:"wiggle")
    }

    /// Allow correct rotating.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        (self.view as? SKView)?.scene?.size = size
        self.statsStackView.isHidden = !(self.isLandScape && TiledGlobals.default.enableRenderCallbacks)
        self.renderStatsButton.isHidden = !self.isLandScape
    }

    override func viewDidLayoutSubviews() {
        self.rotateDeviceIcon.isHidden = self.isLandScape || hideDeviceRotationIcon
        if (self.isLandScape == true) {
            hideDeviceRotationIcon = true
        }

        let skView = self.view as! SKView
        if let scene = skView.scene {
            if let sceneDelegate = scene as? TiledSceneDelegate {
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.setCameraBounds(bounds: skView.bounds)
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Debug.DebuggingMessageSent, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.UpdateModeChanged, object: nil)
    }

    // MARK: - Interface & Setup

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(debuggingInfoReceived), name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(debuggingMessageReceived), name: Notification.Name.Debug.DebuggingMessageSent, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneCameraUpdated), name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatsUpdated), name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatisticsVisibilityChanged), name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapUpdateModeChanged), name: Notification.Name.Map.UpdateModeChanged, object: nil)
    }

    /// Initialize the debugging labels.
    func setupMainInterface() {
        mapInfoLabel.text = "Map: "
        tileInfoLabel.text = "Tile: "
        propertiesInfoLabel.text = "--"
        cameraInfoLabel.text = "Camera:"
        demoStatusInfoLabel.text = "-"
        debuggingMessageLabel.text = "-"

        let shadowColor = SKColor(white: 0.1, alpha: 0.65)
        let shadowOffset = CGSize(width: 1, height: 1)

        mapInfoLabel.shadowColor = shadowColor
        mapInfoLabel.shadowOffset = shadowOffset

        tileInfoLabel.shadowColor = shadowColor
        tileInfoLabel.shadowOffset = shadowOffset

        propertiesInfoLabel.shadowColor = shadowColor
        propertiesInfoLabel.shadowOffset = shadowOffset

        cameraInfoLabel.shadowColor = shadowColor
        cameraInfoLabel.shadowOffset = shadowOffset

        demoStatusInfoLabel.shadowColor = shadowColor
        demoStatusInfoLabel.shadowOffset = shadowOffset
        debuggingMessageLabel.shadowOffset = shadowOffset

        statsEffectsLabel.shadowColor = shadowColor
        controlsView?.alpha = 0.9
        statsUpdatedLabel.isHidden = true

        // stats view
        statsRenderModeLabel.shadowColor = shadowColor
        statsRenderModeLabel.shadowOffset = shadowOffset
        statsCPULabel.shadowColor = shadowColor
        statsCPULabel.shadowOffset = shadowOffset
        statsVisibleLabel.shadowColor = shadowColor
        statsVisibleLabel.shadowOffset = shadowOffset
        statsObjectsLabel.shadowColor = shadowColor
        statsObjectsLabel.shadowOffset = shadowOffset
        statsActionsLabel.shadowColor = shadowColor
        statsActionsLabel.shadowOffset = shadowOffset
        statsEffectsLabel.shadowColor = shadowColor
        statsEffectsLabel.shadowOffset = shadowOffset
        statsUpdatedLabel.shadowColor = shadowColor
        statsUpdatedLabel.shadowOffset = shadowOffset
        statsRenderLabel.shadowColor = shadowColor
        statsRenderLabel.shadowOffset = shadowOffset


        let deviceIsInLandscapeMode = self.isLandScape
        let renderStatsAreVisible = (self.isLandScape && TiledGlobals.default.enableRenderCallbacks)

        rotateDeviceIcon.isHidden = (deviceIsInLandscapeMode == true)
        statsStackView.isHidden = !renderStatsAreVisible
        renderStatsButton.isHidden = !renderStatsAreVisible
    }

    /// Resets the main interface to its original state.
    func resetMainInterface() {}

    /// Set up the control buttons.
    func setupButtonAttributes() {

        let allButtons = [fitButton, gridButton, graphButton, objectsButton, effectsButton, renderStatsButton, nextButton]

        // set the button attributes
        allButtons.forEach { button in
            if let button = button {
                button.setTitleColor(UIColor.white, for: .normal)
                button.backgroundColor = uiColor
                button.layer.cornerRadius = 5
            }
        }
    }

    // MARK: - Button Events


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
    /// - Parameter sender: invoking ui element.
    @IBAction func objectsButtonPressed(_ sender: Any) {
        self.demoController.toggleMapObjectDrawing()
    }

    /// Action called when `stats` button is pressed.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func statsButtonPressed(_ sender: Any) {
        self.demoController.toggleRenderStatistics()
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

    /// Action called when `clamp` button is pressed.
    ///
    /// - Parameter sender: invoking ui element.
    @IBAction func clampButtonPressed(_ sender: Any) {
        let skView = self.view as! SKView
        guard let tiledScene = skView.scene as? SKTiledScene,
            let cameraNode = tiledScene.cameraNode else {
                return
        }
        var newClampValue: CameraZoomClamping = .none
        switch cameraNode.zoomClamping {
            case .none:
                newClampValue = .tenth
            case .tenth:
                newClampValue = .quarter
            case .quarter:
                newClampValue = .half
            case .half:
                newClampValue = .third
            case .third:
                newClampValue = .none
        }
        cameraNode.zoomClamping = newClampValue
    }

    @IBAction func tilemapUpdateModeAction(_ sender: Any) {
        demoController.cycleTilemapUpdateMode()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            //return .landscape
            return .all
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }


    /// Update the debugging labels with scene information.
    ///
    /// - Parameter notification: event notification.
    @objc func debuggingInfoReceived(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.text = mapInfo as? String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.text = tileInfo as? String
        }

        if let propertiesInfo = notification.userInfo!["focusedObjectData"] {
            if let pinfo = propertiesInfo as? String {
                if (pinfo.isEmpty == false) {
                    propertiesInfoLabel.text = pinfo
                } else {
                    propertiesInfoLabel.text = "--"
                }
            }
        }
        
        // TODO: this is part of the demo status callback
        /*
        if let pauseInfo = notification.userInfo!["pauseInfo"] {
            demoStatusInfoLabel.text = pauseInfo as? String
        }*/
    }


    /// Update the camera debug information.
    ///
    /// - Parameter notification: event notification.
    @objc func sceneCameraUpdated(notification: Notification) {
        guard let camera = notification.object as? SKTiledSceneCamera else {
            return
        }

        cameraInfoLabel.text = camera.description

        if (self.isLandScape == false) {
            cameraInfoLabel.lineBreakMode = .byWordWrapping
            cameraInfoLabel.numberOfLines = 2
        } else {
            cameraInfoLabel.lineBreakMode = .byTruncatingTail
            cameraInfoLabel.numberOfLines = 1
        }
    }

    /// Update the the command string label.
    ///
    /// - Parameter notification: event notification.
    @objc func debuggingMessageReceived(notification: Notification) {
        var duration: TimeInterval = 3.0

        if let commandDuration = notification.userInfo!["duration"] {
            if let durationValue = commandDuration as? TimeInterval {
                duration = durationValue
            }
        }


        if let commandString = notification.userInfo!["command"] {
            let commandFormatted = commandString as! String
            debuggingMessageLabel.setTextValue(commandFormatted, animated: true, interval: duration)
        }
    }

    /// Reset the command string label.
    func resetCommandLabel() {
        timer.invalidate()
        debuggingMessageLabel.setTextValue(" ", animated: true, interval: 0.5)
    }

    /// Enables/disable button controls based on the current map attributes.
    ///
    /// - Parameter notification: event notification.
    @objc func tilemapWasUpdated(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else { return }

        if (tilemap.hasKey("uiColor")) {
            if let hexString = tilemap.stringForKey("uiColor") {
                self.uiColor = UIColor(hexString: hexString)
            }
        }

        let effectsEnabled = (tilemap.shouldEnableEffects == true)
        let effectsMessage = (effectsEnabled == true) ? (tilemap.shouldRasterize == true) ? "Effects: on (raster)" : "Effects: on" : "Effects: off"

        statsRenderModeLabel.text = "Mode: \(tilemap.updateMode.name)"
        statsEffectsLabel.text = "\(effectsMessage)"
        statsEffectsLabel.isHidden = (effectsEnabled == false)
        statsVisibleLabel.text = "Visible: \(tilemap.nodesInView.count)"
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

        graphButton.isHidden = !hasGraphs
        objectsButton.isEnabled = hasObjects

        let gridButtonTitle = (tilemap.debugDrawOptions.contains(.drawGrid)) ? "hide grid" : "show grid"
        let objectsButtonTitle = (hasObjects == true) ? (tilemap.isShowingObjectBounds == true) ? "hide objects" : "show objects" : "show objects"

        graphButton.setTitle(graphButtonTitle, for: UIControl.State.normal)
        gridButton.setTitle(gridButtonTitle, for: UIControl.State.normal)
        objectsButton.setTitle(objectsButtonTitle, for: UIControl.State.normal)
        setupButtonAttributes()

        // clean up render stats
        statsCPULabel.isHidden = false
        statsActionsLabel.isHidden = (tilemap.updateMode != .actions)
        statsObjectsLabel.isHidden = false
    }

    // MARK: - Debugging


    /// Updates the render stats debugging info.
    ///
    /// - Parameter notification: event notification.
    @objc func renderStatsUpdated(notification: Notification) {
        guard let renderStats = notification.object as? SKTilemap.RenderStatistics else {
            return
        }

        self.statsRenderModeLabel.text = "Mode: \(renderStats.updateMode.name)"
        self.statsCPULabel.attributedText = renderStats.processorAttributedString
        self.statsVisibleLabel.text = "Visible: \(renderStats.visibleCount)"
        self.statsVisibleLabel.isHidden = (TiledGlobals.default.enableCameraCallbacks == false)
        self.statsObjectsLabel.isHidden = (renderStats.objectsVisible == false)
        self.statsObjectsLabel.text = "Objects: \(renderStats.objectCount)"
        let renderString = (TiledGlobals.default.timeDisplayMode == .seconds) ? String(format: "%.\(String(6))f", renderStats.renderTime) : String(format: "%.\(String(2))f", renderStats.renderTime.milleseconds)
        let timeFormatString = (TiledGlobals.default.timeDisplayMode == .seconds) ? "s" : "ms"
        self.statsRenderLabel.text = "Render time: \(renderString)\(timeFormatString)"

        self.statsUpdatedLabel.isHidden = (renderStats.updateMode == .actions)
        self.statsUpdatedLabel.text = "Updated: \(renderStats.updatedThisFrame)"

        let actionCountString = (renderStats.actionsCount > 0) ? "\(renderStats.actionsCount)" : "--"
        self.statsActionsLabel.text = "Actions: \(actionCountString)"
    }

    /// Show/Hide the render stats data.
    ///
    /// - Parameter notification: event notification.
    @objc func renderStatisticsVisibilityChanged(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
            let showRenderStats = userInfo["showRenderStats"] as? Bool else { return }

        if let view = self.view as? SKView {
            view.showsFPS = showRenderStats
            view.showsQuadCount = showRenderStats
            view.showsNodeCount = showRenderStats
            view.showsDrawCount = showRenderStats
            view.showsPhysics = showRenderStats
            view.showsFields = showRenderStats
        }

        let titleText = (showRenderStats == true) ? "stats: on" : "stats: off"
        self.renderStatsButton.setTitle(titleText, for: .normal)
        self.statsStackView.isHidden = !(self.isLandScape && showRenderStats)
    }

    /// Callback when cache is updated.
    ///
    /// - Parameter notification: event notification.
    @objc func tilemapUpdateModeChanged(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else { return }
        self.statsRenderModeLabel.text = "Mode: \(tilemap.updateMode.name)"
    }
}




extension UIViewController {

    /// Returns true if the device is in landscape mode.
    var isLandScape: Bool {
        return UIDevice.current.orientation.isLandscape
    }
}
