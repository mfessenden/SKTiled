//
//  GameViewController.swift
//  SKTiled Demo - iOS
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//
//  iOS Game View Controller

import UIKit
import SpriteKit


class GameViewController: UIViewController, Loggable {

    let demoController = DemoController.default
    var uiColor: UIColor = UIColor(hexString: "#757B8D")

    // debugging labels (top)
    @IBOutlet weak var rotateDeviceIcon: UIImageView!
    @IBOutlet weak var cameraInfoLabel: UILabel!
    @IBOutlet weak var pauseInfoLabel: UILabel!


    // debugging labels (bottom)
    @IBOutlet weak var mapInfoLabel: UILabel!
    @IBOutlet weak var tileInfoLabel: UILabel!
    @IBOutlet weak var propertiesInfoLabel: UILabel!
    @IBOutlet weak var debugInfoLabel: UILabel!


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
    @IBOutlet weak var statsHeaderLabel: UILabel!
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

        guard let currentURL = demoController.currentURL else {
            log("no tilemap to load.", level: .warning)
            return
        }

        #if DEBUG
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.showsPhysics = false
        #endif

        /* SpriteKit optimizations */
        skView.shouldCullNonVisibleNodes = true
        skView.ignoresSiblingOrder = true

        // initialize the demo interface
        setupDemoInterface()
        setupButtonAttributes()


        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebuggingOutput), name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCommandString), name: Notification.Name.Debug.CommandIssued, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneCameraUpdated), name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatsUpdated), name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatisticsVisibilityChanged), name: Notification.Name.RenderStats.VisibilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapUpdateModeChanged), name: Notification.Name.Map.UpdateModeChanged, object: nil)

        demoController.loadScene(url: currentURL, usePreviousCamera: demoController.preferences.usePreviousCamera)

        // rotate device icon
        addWiggleAnimationToView(viewToAnimate: rotateDeviceIcon)
    }

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

    /// allow correct rotating
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        (self.view as? SKView)?.scene?.size = size
        self.rotateDeviceIcon.isHidden = self.isLandScape
        self.statsStackView.isHidden = !(self.isLandScape && TiledGlobals.default.enableRenderCallbacks)
        self.renderStatsButton.isHidden = !self.isLandScape
    }

    override func viewDidLayoutSubviews() {
        let skView = self.view as! SKView
        if let scene = skView.scene {
            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.setCameraBounds(bounds: skView.bounds)
                }
            }
        }
    }
    
    // MARK: - Setup
    
    
    /**
     Initialize the debugging labels.
     */
    func setupDemoInterface() {
        mapInfoLabel.text = "Map: "
        tileInfoLabel.text = "Tile: "
        propertiesInfoLabel.text = "--"
        cameraInfoLabel.text = "Camera:"
        pauseInfoLabel.text = "-"
        debugInfoLabel.text = "-"

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

        pauseInfoLabel.shadowColor = shadowColor
        pauseInfoLabel.shadowOffset = shadowOffset
        debugInfoLabel.shadowOffset = shadowOffset

        statsEffectsLabel.shadowColor = shadowColor
        controlsView?.alpha = 0.9
        statsUpdatedLabel.isHidden = true

        // stats view
        statsHeaderLabel.shadowColor = shadowColor
        statsHeaderLabel.shadowOffset = shadowOffset
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

    /**
     Set up the control buttons.
     */
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
     Action called when `stats` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func statsButtonPressed(_ sender: Any) {
        self.demoController.toggleRenderStatistics()
    }

    /**
     Action called when `next` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func nextButtonPressed(_ sender: Any) {
        self.demoController.loadNextScene()
    }

    /**
     Action called when `effects` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func effectsButtonPressed(_ sender: Any) {
        self.demoController.toggleTilemapEffectsRendering()
    }

    @IBAction func clampButtonPressed(_ sender: Any) {
        let skView = self.view as! SKView
        if let tiledScene = skView.scene as? SKTiledScene {
            var newClampValue: CameraZoomClamping = .none
            switch tiledScene.cameraNode.zoomClamping {
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

            tiledScene.cameraNode.zoomClamping = newClampValue
        }
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

    /**
     Update the debugging labels with scene information.

     - parameter notification: `Notification` notification.
     */
    @objc func updateDebuggingOutput(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.text = mapInfo as? String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.text = tileInfo as? String
        }

        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            if let pinfo = propertiesInfo as? String {
                if (pinfo.isEmpty == false) {
                    propertiesInfoLabel.text = pinfo
                } else {
                    propertiesInfoLabel.text = "--"
                }
            }
                }

        if let pauseInfo = notification.userInfo!["pauseInfo"] {
            pauseInfoLabel.text = pauseInfo as? String
            }
        }

    /**
     Update the camera debug information.

     - parameter notification: `Notification` notification.
     */
    @objc func sceneCameraUpdated(notification: Notification) {
        guard let camera = notification.object as? SKTiledSceneCamera else {
            fatalError("no camera!!")
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

    /**
     Update the the command string label.

     - parameter notification: `Notification` notification.
     */
    @objc func updateCommandString(notification: Notification) {
        var duration: TimeInterval = 3.0

        if let commandDuration = notification.userInfo!["duration"] {
            duration = commandDuration as! TimeInterval
        }


        if let commandString = notification.userInfo!["command"] {
            let commandFormatted = commandString as! String
            debugInfoLabel.setTextValue(commandFormatted, animated: true, interval: duration)
        }
    }

    /**
     Reset the command string label.
     */
    func resetCommandLabel() {
        timer.invalidate()
        debugInfoLabel.setTextValue(" ", animated: true, interval: 0.5)
    }

    /**
     Enables/disable button controls based on the current map attributes.

     - parameter notification: `Notification` notification.
     */
    @objc func tilemapWasUpdated(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else { return }

        if (tilemap.hasKey("uiColor")) {
            if let hexString = tilemap.stringForKey("uiColor") {
                self.uiColor = UIColor(hexString: hexString)
            }
        }

        let effectsEnabled = (tilemap.shouldEnableEffects == true)
        let effectsMessage = (effectsEnabled == true) ? (tilemap.shouldRasterize == true) ? "Effects: on (raster)" : "Effects: on" : "Effects: off"
        statsHeaderLabel.text = "Rendering: \(TiledGlobals.default.renderer.name)"
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
        let objectsButtonTitle = (hasObjects == true) ? (tilemap.showObjects == true) ? "hide objects" : "show objects" : "show objects"

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

    /**
     Updates the render stats debugging info.

     - parameter notification: `Notification` notification.
     */
    @objc func renderStatsUpdated(notification: Notification) {
        guard let renderStats = notification.object as? SKTilemap.RenderStatistics else { return }

        self.statsHeaderLabel.text = "Rendering: \(TiledGlobals.default.renderer.name)"
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
    }

    /**
     Show/Hide the render stats data.

     - parameter notification: `Notification` notification.
     */
    @objc func renderStatisticsVisibilityChanged(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
            let showRenderStats = userInfo["showRenderStats"] as? Bool else { return }

        let titleText = (showRenderStats == true) ? "stats: on" : "stats: off"
        self.renderStatsButton.setTitle(titleText, for: .normal)
        self.statsStackView.isHidden = !(self.isLandScape && showRenderStats)
    }

    /**
     Callback when cache is updated.

     - parameter notification: `Notification` notification.
     */
    @objc func tilemapUpdateModeChanged(notification: Notification) {
        guard let tilemap = notification.object as? SKTilemap else { return }
        self.statsRenderModeLabel.text = "Mode: \(tilemap.updateMode.name)"
    }
}


extension UILabel {
    /**
     Set the string value of the text field, with optional animated fade.

     - parameter newValue: `String` new text value.
     - parameter animated: `Bool` enable fade out effect.
     - parameter interval: `TimeInterval` effect length.
     */
    func setTextValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
        if animated {
            animate(change: { self.text = newValue }, interval: interval)
        } else {
            text = newValue
        }
    }

    /**
     Private function to animate a fade effect.

     - parameter change: `() -> Void` closure.
     - parameter interval: `TimeInterval` effect length.
     */
    private func animate(change: @escaping () -> Void, interval: TimeInterval) {
        let fadeDuration: TimeInterval = 0.5

        UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.text = ""
            self.alpha = 1.0
        }, completion: { (Bool) -> Void in
            change()
            UIView.animate(withDuration: fadeDuration, delay: interval, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.alpha = 0.0
            }, completion: nil)
        })
    }
}




extension UIViewController {
    var isLandScape: Bool {
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait, .portraitUpsideDown:
            return false
        case .landscapeLeft, .landscapeRight:
            return true
        default:
            guard let window = self.view.window else { return false }
            return window.frame.size.width > window.frame.size.height
        }
    }
}
