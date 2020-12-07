//
//  GameViewController.swift
//  SKTiled Demo - tvOS
//
//  Created by Michael Fessenden.
//
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
import GameController


class GameViewController: GCEventViewController, Loggable {

    let demoController = DemoController.default
    var uiColor: UIColor = UIColor(hexString: "#757B8D")

    // debugging labels (top)
    @IBOutlet weak var cameraInfoLabel: UILabel!
    @IBOutlet weak var pauseInfoLabel: UILabel!

    // debugging labels (bottom)
    @IBOutlet weak var mapInfoLabel: UILabel!
    @IBOutlet weak var debugInfoLabel: UILabel!
    @IBOutlet weak var frameworkVersionLabel: UILabel!


    // demo buttons
    @IBOutlet weak var fitButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var graphButton: UIButton!
    @IBOutlet weak var objectsButton: UIButton!
    @IBOutlet weak var effectsButton: UIButton!
    @IBOutlet weak var updateModeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

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

    // container for the primary UI controls
    @IBOutlet weak var mainControlsView: UIStackView!


    @IBOutlet weak var controlIconView: UIStackView!
    @IBOutlet weak var cameraControlModeIcon: UIImageView!
    @IBOutlet weak var gameControllerIcon: UIImageView!

    // Game controller/remote.
    private var currentController: GCController?

    // unused
    @IBOutlet var demoFileAttributes: NSObject!

    var timer = Timer()

    var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    override func viewDidLoad() {
        super.viewDidLoad()

        /// disable focus for gamepads
        controllerUserInteractionEnabled = false

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
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        #endif


        skView.showsFPS = true
        skView.shouldCullNonVisibleNodes = true
        skView.ignoresSiblingOrder = true

        // initialize the demo interface
        setupDemoInterface()
        setupButtonAttributes()

        setupNotifications()

        /* create the game scene */
        demoController.loadScene(url: currentURL, usePreviousCamera: demoController.preferences.usePreviousCamera)
        frameworkVersionLabel.text = TiledGlobals.default.version.versionString
        frameworkVersionLabel.textColor = UIColor(hexString: "#dddddd7a")
    }

    override func viewDidLayoutSubviews() {
        // Pause the scene while the window resizes if the game is active.

        let skView = self.view as! SKView
        if let scene = skView.scene {

            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.setCameraBounds(bounds: view.bounds)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }


    /// Enable event notifications.
    func setupNotifications() {

        NotificationCenter.default.addObserver(self, selector: #selector(updateDebuggingOutput), name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCommandString), name: Notification.Name.Debug.CommandIssued, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneCameraUpdated), name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatsUpdated), name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapUpdateModeChanged), name: Notification.Name.Map.UpdateModeChanged, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect), name: Notification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidDisconnect), name: Notification.Name.GCControllerDidDisconnect, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(controlInputReceived), name: Notification.Name.Demo.ControlInputReceived, object: nil)
    }

    /**
     Setup the main interface.
     */
    func setupDemoInterface() {
        mapInfoLabel.text = "map: "
        debugInfoLabel.text = "command: "
        pauseInfoLabel.text = ""

        cameraControlModeIcon.isHidden = true

        if let fitButton = fitButton {
            fitButton.isEnabled = true
        }

        if let gridButton = gridButton {
            gridButton.isEnabled = true
        }

        if let graphButton = graphButton {
            graphButton.isEnabled = true
        }

        if let objectsButton = objectsButton {
            objectsButton.isEnabled = true
        }

        if let nextButton = nextButton {
            nextButton.isEnabled = false
        }

        if let effectsButton = effectsButton {
            effectsButton.isEnabled = true
        }

        self.statsUpdatedLabel.isHidden = true
    }

    /// Set up the control buttons.
    func setupButtonAttributes() {
        let allButtons = [fitButton, gridButton, graphButton, objectsButton, effectsButton, updateModeButton, nextButton]
        // set the button attributes
        allButtons.forEach { button in
            if let button = button {
                button.setTitleColor(UIColor.white, for: .normal)

                let buttonColor = (button.state == UIControl.State.normal) ? uiColor : uiColor.withAlphaComponent(0.5)
                button.backgroundColor = buttonColor
                button.layer.cornerRadius = 10
            }
        }
    }

    // MARK: - Controllers


    /// Called when a controller is connected.
    @objc func controllerDidConnect() {
        updateControllerInputView()
    }

    /// Called when a controller is disconnected.
    @objc func controllerDidDisconnect() {
        updateControllerInputView()
    }

    /// Update the UI to reflect the controllers connected.
    func updateControllerInputView() {
        var defaultControlTypeImage = "remote"
        for controller in GCController.controllers() where controller.microGamepad != nil {
            if let _ = controller.extendedGamepad {
                defaultControlTypeImage = "gamepad"
            }
        }
        let controlTypeImage = UIImage(named: defaultControlTypeImage)
        gameControllerIcon.image = controlTypeImage
    }

    /**
     Called when game controller input is recieved. Called when the `Notification.Name.Demo.ControlInputReceived` notification is sent.

     - parameter notification:`Notification` event notification.
     */
    @objc func controlInputReceived(notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }

        if (controller.extendedGamepad != nil) {
            controllerUserInteractionEnabled = false
        } else {
            //controllerUserInteractionEnabled = true
        }

        let controlTypeImage = UIImage(named: controller.imageName)
        gameControllerIcon.image = controlTypeImage
    }

    // MARK: - Button Actions

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

    /**
     Action called when `effects` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func effectsButtonPressed(_ sender: Any) {
        self.demoController.toggleTilemapEffectsRendering()
    }

    /**
     Action called when `update mode` button is pressed.

     - parameter sender: `Any` ui button.
     */
    @IBAction func updateButtonPressed(_ sender: Any) {
        self.demoController.cycleTilemapUpdateMode()
    }

    // MARK: - Callbacks

    /**
     Update the debugging labels with scene information.

     - parameter notification: `Notification` event notification.
     */
    @objc func updateDebuggingOutput(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.text = mapInfo as? String
        }

        if let cameraInfo = notification.userInfo!["cameraInfo"] {
            cameraInfoLabel.text = cameraInfo as? String
        }


        if let sceneIsPaused = notification.userInfo!["pauseInfo"] as? Bool {
            let fontColor: UIColor = (sceneIsPaused == false) ? UIColor.white : UIColor(hexString: "#2CF639")
            let labelStyle = NSMutableParagraphStyle()
            labelStyle.alignment = .center

            let pauseLabelAttributes = [
                .foregroundColor: fontColor,
                .paragraphStyle: labelStyle
            ] as [NSAttributedString.Key: Any]

            let pauseString = (sceneIsPaused == false) ? "" : "•Paused•"
            let outputString = NSMutableAttributedString(string: pauseString, attributes: pauseLabelAttributes)
            pauseInfoLabel.attributedText = outputString
        }

    }

    /**
     Update the camera control controls.

     - parameter notification: `Notification` event notification.
     */
    @objc func sceneCameraUpdated(notification: Notification) {
        guard let camera = notification.object as? SKTiledSceneCamera else {
            fatalError("cannot access scene camera.")
        }




        var isRemoteControlled = true
        switch camera.controlMode {

        case .dolly:
            isRemoteControlled = false
            cameraControlModeIcon.image = UIImage(named: "dolly")
            cameraControlModeIcon.isHidden = false

        case .zoom:
            isRemoteControlled = false
            cameraControlModeIcon.image = UIImage(named: "zoom")
            cameraControlModeIcon.isHidden = false

        case .none:
            isRemoteControlled = true
            cameraControlModeIcon.isHidden = true
        }

        fitButton?.isEnabled = isRemoteControlled
        gridButton?.isEnabled = isRemoteControlled
        graphButton?.isEnabled = isRemoteControlled
        objectsButton?.isEnabled = isRemoteControlled
        nextButton?.isEnabled = isRemoteControlled

        // hide the main control buttons in remote control mode
        mainControlsView.isHidden = (isRemoteControlled == false)
        cameraInfoLabel.text = camera.description
    }

    /**
     Update the the command string label. Called when the `Notification.Name.Debug.CommandIssued` notification is sent.

     - parameter notification: `Notification` event notification.
     */
    @objc func updateCommandString(notification: Notification) {
        var duration: TimeInterval = 3.0

        if let commandDuration = notification.userInfo!["duration"] {
            if let durationValue = commandDuration as? TimeInterval {
                duration = durationValue
            }
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
        debugInfoLabel.text = ""
    }

    /**
     Enables/disable button controls based on the current map attributes.

     - parameter notification: `Notification` event notification.
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
        statsVisibleLabel.text = "Visible: \(tilemap.nodesInView.count)"
        statsEffectsLabel.text = "\(effectsMessage)"
        statsEffectsLabel.isHidden = (effectsEnabled == false)
        let graphsCount = tilemap.graphs.count
        let hasGraphs: Bool = graphsCount > 0

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
        let effectsButtonTitle = (tilemap.shouldEnableEffects == true) ? "effects: on" : "effects: off"
        let updateModeTitle = "mode: \(tilemap.updateMode.name)"

        graphButton.setTitle(graphButtonTitle, for: UIControl.State.normal)
        gridButton.setTitle(gridButtonTitle, for: UIControl.State.normal)
        objectsButton.setTitle(objectsButtonTitle, for: UIControl.State.normal)
        effectsButton.setTitle(effectsButtonTitle, for: UIControl.State.normal)
        updateModeButton.setTitle(updateModeTitle, for: UIControl.State.normal)

        setupButtonAttributes()

        // clean up render stats
        statsCPULabel.isHidden = false
        statsActionsLabel.isHidden = (tilemap.updateMode != .actions)
        statsObjectsLabel.isHidden = false
     }


     // MARK: - Debugging

     /**
      Updates the render stats debugging info.

     - parameter notification: `Notification` event notification.
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


        // update the effects button (tvOS)
        let effectsButtonTitle = (renderStats.effectsEnabled == true) ? "effects: on" : "effects: off"
        effectsButton.setTitle(effectsButtonTitle, for: UIControl.State.normal)
     }

     /**
      Callback when cache is updated.

      - parameter notification: `Notification` event notification.
      */
     @objc func tilemapUpdateModeChanged(notification: Notification) {
         guard let tilemap = notification.object as? SKTilemap else { return }
         self.statsRenderModeLabel.text = "Mode: \(tilemap.updateMode.name)"
     }
}
