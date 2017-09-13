//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import UIKit
import SpriteKit


class GameViewController: UIViewController, Loggable {

    let demoController = DemoController.default

    @IBOutlet weak var mapInfoLabel: UILabel!
    @IBOutlet weak var tileInfoLabel: UILabel!
    @IBOutlet weak var propertiesInfoLabel: UILabel!
    @IBOutlet weak var cameraInfoLabel: UILabel!
    @IBOutlet weak var pauseInfoLabel: UILabel!
    @IBOutlet weak var debugInfoLabel: UILabel!

    @IBOutlet weak var objectsButton: UIButton!
    @IBOutlet weak var graphButton: UIButton!


    @IBOutlet var demoFileAttributes: NSObject!
    @IBOutlet weak var buttonsView: UIStackView!

    var timer = Timer()
    var loggingLevel: LoggingLevel = SKTiledLoggingLevel

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = self.view as! SKView

        // setup the controller
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
        skView.showsPhysics = false
        #endif


        skView.showsFields = true
        /* SpriteKit optimizations */
        skView.shouldCullNonVisibleNodes = true
        skView.ignoresSiblingOrder = true
        setupDebuggingLabels()


        NotificationCenter.default.addObserver(self, selector: #selector(updateUIControls), name: NSNotification.Name(rawValue: "updateUIControls"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCommandString), name: NSNotification.Name(rawValue: "updateCommandString"), object: nil)

        /* create the game scene */
        demoController.loadScene(url: currentURL, usePreviousCamera: false)
    }

    override func viewDidLayoutSubviews() {
        // Pause the scene while the window resizes if the game is active.

        let skView = self.view as! SKView
        if let scene = skView.scene {

            if let sceneDelegate = scene as? SKTiledSceneDelegate {
                if let cameraNode = sceneDelegate.cameraNode {
                    cameraNode.bounds = skView.bounds
                }
            }
        }
    }

    func setupDebuggingLabels() {
        mapInfoLabel.text = "Map: "
        tileInfoLabel.text = "Tile: "
        propertiesInfoLabel.text = "Properties:"
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
        self.demoController.toggleMapDemoDrawGridBounds()
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
    func updateDebugLabels(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.text = mapInfo as? String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.text = tileInfo as? String
        }

        var propertiesDefaultText = "  "
        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            if let pinfo = propertiesInfo as? String {
                if (pinfo.characters.isEmpty == false) {
                    propertiesDefaultText = pinfo
                }
            }
        }

        if let cameraInfo = notification.userInfo!["cameraInfo"] {
            cameraInfoLabel.text = cameraInfo as? String
        }

        if let pauseInfo = notification.userInfo!["pauseInfo"] {
            pauseInfoLabel.text = pauseInfo as? String
        }

        propertiesInfoLabel.text = propertiesDefaultText
    }

    /**
     Update the the command string label.

     - parameter notification: `Notification` notification.
     */
    func updateCommandString(notification: Notification) {
        var duration: TimeInterval = 3.0

        if let commandDuration = notification.userInfo!["duration"] {
            duration = commandDuration as! TimeInterval
        }


        if let commandString = notification.userInfo!["command"] {
            var commandFormatted = commandString as! String
            commandFormatted = "\(commandFormatted)".uppercaseFirst

            debugInfoLabel.fadeInThenOut(change: {
                self.debugInfoLabel.text = "▹ \(commandFormatted)"

            }, delay: duration)
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
    func updateUIControls(notification: Notification) {
        if let hasGraphs = notification.userInfo!["hasGraphs"] {
            graphButton.isEnabled = (hasGraphs as? Bool) == true
        }

        if let hasObjects = notification.userInfo!["hasObjects"] {
            objectsButton.isEnabled = (hasObjects as? Bool) == true
        }
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
        guard text != newValue else { return }
        if animated {
            animate(change: { self.text = newValue }, interval: interval)
        } else {
            text = newValue
        }
    }

    /**
     Private function to animate a fade effect.

     - parameter change: `() -> ()` closure.
     - parameter interval: `TimeInterval` effect length.
     */
    private func animate(change: @escaping () -> Void, interval: TimeInterval) {
        UIView.animate(withDuration: interval, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.alpha = 1.0
        }, completion: { (Bool) -> Void in
            change()
            UIView.animate(withDuration: interval, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.alpha = 0.0
            }, completion: nil)

        })
    }

    func fadeInThenOut(change: @escaping () -> Void, delay: TimeInterval) {
        let animationDuration = 0.5

        // Fade in the view
        UIView.animate(withDuration: 0, animations: { () -> Void in
            self.alpha = 1

        }) { (Bool) -> Void in

            // After the animation completes, fade out the view after a delay
            change()

            UIView.animate(withDuration: animationDuration, delay: delay, options: [.curveEaseOut], animations: { () -> Void in
                self.alpha = 0
                self.text = ""
            }, completion: nil)
        }
    }
}
