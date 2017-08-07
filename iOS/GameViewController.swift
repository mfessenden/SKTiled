//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import UIKit
import SpriteKit


class GameViewController: UIViewController {

    @IBOutlet weak var mapInfoLabel: UILabel!
    @IBOutlet weak var tileInfoLabel: UILabel!
    @IBOutlet weak var propertiesInfoLabel: UILabel!
    @IBOutlet weak var graphButton: UIButton!

    let demoController = DemoController.default
    var loggingLevel: LoggingLevel = .debug

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = self.view as! SKView
        // set the controller view
        demoController.view = skView


        guard let currentURL = demoController.currentURL else {
            print("[GameViewController]: WARNING: no tilemap to load.")
            return
        }

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.showsPhysics = true
        #endif

        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = false
        setupDebuggingLabels()


        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        scene.setup(tmxFile: currentURL.relativePath, inDirectory: currentURL.baseURL?.relativePath, tilesets: [], verbosity: loggingLevel)

        NotificationCenter.default.addObserver(self, selector: #selector(updateGraphControls), name: NSNotification.Name(rawValue: "updateGraphControls"), object: nil)
    }

    func setupDebuggingLabels() {
        mapInfoLabel.text = "Map: "
        tileInfoLabel.text = "Tile: "
        propertiesInfoLabel.text = "Properties:"

        let shadowColor = SKColor(white: 0.1, alpha: 0.65)
        let shadowOffset = CGSize(width: 1, height: 1)

        mapInfoLabel.shadowColor = shadowColor
        mapInfoLabel.shadowOffset = shadowOffset

        tileInfoLabel.shadowColor = shadowColor
        tileInfoLabel.shadowOffset = shadowOffset

        propertiesInfoLabel.shadowColor = shadowColor
        propertiesInfoLabel.shadowOffset = shadowOffset

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
        self.demoController.toggleMapDemoDraw()
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
            return .landscapeRight
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

        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            propertiesInfoLabel.text = propertiesInfo as? String
        }
    }

    func updateGraphControls(notification: Notification) {
        if let hasGraphs = notification.userInfo!["hasGraphs"] {
            graphButton.isEnabled = (hasGraphs as? Bool) == true
        }
    }
}
