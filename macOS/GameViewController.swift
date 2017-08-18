//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 9/19/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Cocoa
import SpriteKit


class GameViewController: NSViewController, Loggable {

    // debugging labels
    @IBOutlet weak var mapInfoLabel: NSTextField!
    @IBOutlet weak var tileInfoLabel: NSTextField!
    @IBOutlet weak var propertiesInfoLabel: NSTextField!
    @IBOutlet weak var debugInfoLabel: NSTextField!
    @IBOutlet weak var cameraInfoLabel: NSTextField!
    
    @IBOutlet weak var pauseInfoLabel: NSTextField!

    @IBOutlet weak var graphButton: NSButton!
    @IBOutlet weak var objectsButton: NSButton!

    @IBOutlet var demoFileAttributes: NSArrayController!

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

        //set up notifications
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateWindowTitle), name: NSNotification.Name(rawValue: "updateWindowTitle"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIControls), name: NSNotification.Name(rawValue: "updateUIControls"), object: nil)

        debugInfoLabel?.isHidden = true

        /* create the game scene */
        demoController.loadScene(url: currentURL, usePreviousCamera: false)
    }


    override func viewDidAppear() {
        super.viewDidAppear()
    }

    /**
     Set up the debugging labels. (Mimics the text style in iOS controller).
     */
    func setupDebuggingLabels() {
        mapInfoLabel.stringValue = "Map: "
        tileInfoLabel.stringValue = "Tile: "
        propertiesInfoLabel.stringValue = "Properties:"
        cameraInfoLabel.stringValue = "~"

        // text shadow
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 2, height: 1)
        shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.75)
        shadow.shadowBlurRadius = 0.5

        mapInfoLabel.shadow = shadow
        tileInfoLabel.shadow = shadow
        propertiesInfoLabel.shadow = shadow
        debugInfoLabel.shadow = shadow
        cameraInfoLabel.shadow = shadow
        pauseInfoLabel.shadow = shadow
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
    
    // MARK: - Tracking
    
    // MARK: - Mouse Events
    
    /**
     Mouse scroll wheel event handler.

     - parameter event: `NSEvent` mouse event.
     */
    override func scrollWheel(with event: NSEvent) {
        log("scroll wheel...", level: .info)
        guard let view = self.view as? SKView else { return }

        if let currentScene = view.scene as? SKTiledDemoScene {
            currentScene.scrollWheel(with: event)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        log("mouse entered...", level: .info)
    }
    
    override func mouseUp(with event: NSEvent) {
        log("mouse up...", level: .info)
    }
    
    override func mouseDown(with event: NSEvent) {
        log("mouse down...", level: .info)
    }
    
    override func mouseDragged(with event: NSEvent) {
        log("mouse dragged...", level: .info)
    }
    
    override func mouseMoved(with event: NSEvent) {
        log("mouse moved...", level: .info)
        guard let view = self.view as? SKView else { return }
        
        if let currentScene = view.scene as? SKTiledScene {
            if let cameraNode = currentScene.cameraNode {
                cameraNode.mouseMoved(with: event)
            }
        }
    }
    
    /**
     Update the window's title bar with the current scene name.

     - parameter notification: `Notification` callback.
     */
    func updateWindowTitle(notification: Notification) {
        if let wintitle = notification.userInfo!["wintitle"] {
            if let infoDictionary = Bundle.main.infoDictionary {
                if let bundleName = infoDictionary[kCFBundleNameKey as String] as? String {
                    self.view.window?.title = "\(bundleName): \(wintitle as! String)"
                }
            }
        }
    }

    /**
     Update the debugging labels with scene information.

     - parameter notification: `Notification` notification.
     */
    func updateDebugLabels(notification: Notification) {
        if let mapInfo = notification.userInfo!["mapInfo"] {
            mapInfoLabel.stringValue = mapInfo as! String
        }

        if let tileInfo = notification.userInfo!["tileInfo"] {
            tileInfoLabel.stringValue = tileInfo as! String
        }

        if let propertiesInfo = notification.userInfo!["propertiesInfo"] {
            propertiesInfoLabel.stringValue = propertiesInfo as! String
        }

        if let debugInfo = notification.userInfo!["debugInfo"] {
            debugInfoLabel.stringValue = debugInfo as! String
        }

        if let cameraInfo = notification.userInfo!["cameraInfo"] {
            cameraInfoLabel.stringValue = cameraInfo as! String
        }

        if let pauseInfo = notification.userInfo!["pauseInfo"] {
            pauseInfoLabel.stringValue = pauseInfo as! String
        }
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
