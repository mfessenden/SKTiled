//
//  GameViewController.swift
//  SKTiled Demo - tvOS
//
//  Created by Michael Fessenden on 3/26/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//
//  tvOS Game View Controller

import UIKit
import SpriteKit
import GameController


class GameViewController: GCEventViewController, Loggable {

    let demoController = DemoController.default
    var uiColor: UIColor = UIColor(hexString: "#757B8D")

    // debugging labels (top)
    @IBOutlet weak var cameraInfoLabel: UILabel!

    // debugging labels (bottom)
    @IBOutlet weak var mapInfoLabel: UILabel!
    @IBOutlet weak var debugInfoLabel: UILabel!


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

    // container for the buttons
    @IBOutlet weak var mainControlsView: UIStackView!

    // camera mode icons
    @IBOutlet weak var controlIconView: UIStackView!

    // icon controls
    @IBOutlet weak var dollyIcon: UIImageView!
    @IBOutlet weak var zoomIcon: UIImageView!

    @IBOutlet var demoFileAttributes: NSObject!

    var timer = Timer()

    var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    override func viewDidLoad() {
        super.viewDidLoad()

        controllerUserInteractionEnabled = true

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
        
        // demo notifications
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebuggingOutput), name: Notification.Name.Demo.UpdateDebugging, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCommandString), name: Notification.Name.Debug.CommandIssued, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapWasUpdated), name: Notification.Name.Map.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneCameraUpdated), name: Notification.Name.Camera.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renderStatsUpdated), name: Notification.Name.Map.RenderStatsUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tilemapUpdateModeChanged), name: Notification.Name.Map.UpdateModeChanged, object: nil)

        /* create the game scene */
        demoController.loadScene(url: currentURL, usePreviousCamera: demoController.preferences.usePreviousCamera)
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

    /**
     Setup the main interface.
     */
    func setupDemoInterface() {

        mapInfoLabel.text = "map: "
        debugInfoLabel.text = "command: "

        controlIconView.isHidden = true
        controlIconView.isHidden = true
        dollyIcon.isHidden = false
        zoomIcon.isHidden = false

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

    /**
     Set up the control buttons.
     */
    func setupButtonAttributes() {
        let allButtons = [fitButton, gridButton, graphButton, objectsButton, effectsButton, updateModeButton, nextButton]
        // set the button attributes
        allButtons.forEach { button in
            if let button = button {
                button.setTitleColor(UIColor.white, for: .normal)

                let buttonColor = (button.state == UIControl.State.normal) ? uiColor : uiColor.withAlphaComponent(0.5)
                button.backgroundColor = buttonColor
                button.layer.cornerRadius = 4
            }
        }
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

     - parameter notification: `Notification` notification.
     */
    @objc func updateDebuggingOutput(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.text = mapInfo as? String
        }

        if let cameraInfo = notification.userInfo!["cameraInfo"] {
            cameraInfoLabel.text = cameraInfo as? String
        }
    }

    /**
     Update the camera control controls.

     - parameter notification: `Notification` notification.
     */
    @objc func sceneCameraUpdated(notification: Notification) {
        guard let camera = notification.object as? SKTiledSceneCamera else {
            fatalError("no camera!!")
        }

        //controlIconView.isHidden = true
        //dollyIcon.isHidden = true
        //zoomIcon.isHidden = true

        var stackViewHidden = true
        var dollyHidden = true
        var zoomHidden = true

        switch camera.controlMode {

        case .dolly:
            stackViewHidden = false
            dollyHidden = false
            zoomHidden = true

        case .zoom:
            stackViewHidden = false
            dollyHidden = true
            zoomHidden = false

        case .none:
            stackViewHidden = true
            dollyHidden = false
            zoomHidden = false
        }

        controlIconView.isHidden = stackViewHidden

        dollyIcon.isHidden = dollyHidden
        zoomIcon.isHidden = zoomHidden

        fitButton?.isEnabled = stackViewHidden
        gridButton?.isEnabled = stackViewHidden
        graphButton?.isEnabled = stackViewHidden
        objectsButton?.isEnabled = stackViewHidden
        nextButton?.isEnabled = stackViewHidden

        mainControlsView.isHidden = !stackViewHidden
        cameraInfoLabel.text = camera.description
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
        debugInfoLabel.text = ""
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


        // update the effects button (tvOS)
        let effectsButtonTitle = (renderStats.effectsEnabled == true) ? "effects: on" : "effects: off"
        effectsButton.setTitle(effectsButtonTitle, for: UIControl.State.normal)
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
