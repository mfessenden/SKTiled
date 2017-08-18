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
    
    @IBOutlet weak var mapInfoLabel: UILabel!
    @IBOutlet weak var tileInfoLabel: UILabel!
    @IBOutlet weak var propertiesInfoLabel: UILabel!
    @IBOutlet weak var cameraInfoLabel: UILabel!
    @IBOutlet weak var pauseInfoLabel: UILabel!
    
    @IBOutlet weak var objectsButton: UIButton!
    @IBOutlet weak var graphButton: UIButton!

    
    @IBOutlet var demoFileAttributes: NSObject!
    @IBOutlet weak var buttonsView: UIStackView!
    
    let demoController = DemoController.default
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
        skView.showsPhysics = true
        skView.showsPhysics = true
        #endif
        
        
        skView.showsFields = true
        /* SpriteKit optimizations */
        skView.shouldCullNonVisibleNodes = true
        skView.ignoresSiblingOrder = true
        setupDebuggingLabels()


        NotificationCenter.default.addObserver(self, selector: #selector(updateUIControls), name: NSNotification.Name(rawValue: "updateUIControls"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        
        /* create the game scene */
        demoController.loadScene(url: currentURL, usePreviousCamera: false)
    }
    
    override func viewDidLayoutSubviews() {
        
    }

    func setupDebuggingLabels() {
        mapInfoLabel.text = "Map: "
        tileInfoLabel.text = "Tile: "
        propertiesInfoLabel.text = "Properties:"
        cameraInfoLabel.text = "Camera:"
        pauseInfoLabel.text = "-"

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
        
        var propertiesDefaultText = "~"
        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            if let pinfo = propertiesInfo as? String {
                if pinfo.characters.count > 0 {
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

    func updateUIControls(notification: Notification) {
        if let hasGraphs = notification.userInfo!["hasGraphs"] {
            graphButton.isHidden = (hasGraphs as? Bool) == false
        }
        
        if let hasObjects = notification.userInfo!["hasObjects"] {
            objectsButton.isHidden = (hasObjects as? Bool) == false
        }
    }
}
