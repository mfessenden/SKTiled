//
//  GameViewController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 9/19/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Cocoa
import SpriteKit


class GameViewController: NSViewController {
    
    // debugging labels
    @IBOutlet weak var mapInfoLabel: NSTextField!
    @IBOutlet weak var tileInfoLabel: NSTextField!
    @IBOutlet weak var propertiesInfoLabel: NSTextField!
    @IBOutlet weak var debugInfoLabel: NSTextField!
    @IBOutlet weak var cameraInfoLabel: NSTextField!
    
    @IBOutlet weak var cursorTracker: NSTextField!
    
    var demoFiles: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // load demo files from a propertly list
        demoFiles = loadDemoFiles("DemoFiles")
        let currentFilename = demoFiles.first!

        
        // Configure the view.
        let skView = self.view as! SKView
        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        #endif
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        skView.showsPhysics = false
        setupDebuggingLabels()
        
        
        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size)
        
        /* set the scale mode to scale to fit the window */
        scene.scaleMode = .aspectFill
        
        //set up notifications for managing scene transitions
        NotificationCenter.default.addObserver(self, selector: #selector(reloadScene), name: NSNotification.Name(rawValue: "reloadScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: NSNotification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadPreviousScene), name: NSNotification.Name(rawValue: "loadPreviousScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        
        skView.presentScene(scene)
        scene.setup(tmxFile: currentFilename)
        debugInfoLabel?.isHidden = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        guard let view = self.view as? SKView else { return }
        
        if let currentScene = view.scene as? SKTiledScene {
            if let tmxName = currentScene.tmxFilename {
                updateWindowTitle(withString: tmxName)
            }
        }
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
    }
    
    /**
     Action called when `fit to view` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func fitButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let cameraNode = scene.cameraNode {
            cameraNode.fitToView(newSize: view.bounds.size)
        }
    }
    
    /**
     Action called when `show grid` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func gridButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            tilemap.debugDraw = !tilemap.debugDraw
        }
    }
    
    /**
     Action called when `show objects` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func objectsButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            let debugState = !tilemap.showObjects
            tilemap.showObjects = debugState
        }
    }
    
    /**
     Action called when `next` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func nextButtonPressed(_ sender: Any) {
        loadNextScene()
    }
    
    /**
     Mouse scroll wheel event handler.
     
     - parameter event: `NSEvent` mouse event.
     */
    override func scrollWheel(with event: NSEvent) {
        guard let view = self.view as? SKView else { return }
        
        if let currentScene = view.scene as? SKTiledDemoScene {
            currentScene.scrollWheel(with: event)
        }
    }
    
    /**
     Reload the current scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func reloadScene(_ interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
        var debugMode = false
        var liveMode = false
        var showOverlay = true
        
        var currentFilename: String! = nil
        if let currentScene = view.scene as? SKTiledDemoScene {
            currentScene.blocked = true
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
            }
            
            liveMode = currentScene.liveMode
            if let tilemap = currentScene.tilemap {
                debugMode = tilemap.debugDraw
                currentFilename = tilemap.filename!
            }
        }
        
        DispatchQueue.main.async {
            view.presentScene(nil)
            
            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            
            nextScene.setup(tmxFile: currentFilename)
            nextScene.liveMode = liveMode
            nextScene.cameraNode?.showOverlay = showOverlay
            self.updateWindowTitle(withString: currentFilename)
            nextScene.tilemap?.debugDraw = debugMode
        }
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadNextScene(_ interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
        var debugMode = false
        var liveMode = false
        var showOverlay = true
        
        var currentFilename = demoFiles.first!
        if let currentScene = view.scene as? SKTiledDemoScene {
            currentScene.blocked = true
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
            }
            
            liveMode = currentScene.liveMode
            if let tilemap = currentScene.tilemap {
                debugMode = tilemap.debugDraw
                currentFilename = tilemap.filename!
            }
        }

        var nextFilename = demoFiles.first!
        if let index = demoFiles.index(of: currentFilename) , index + 1 < demoFiles.count {
            nextFilename = demoFiles[index + 1]
        }
        
        DispatchQueue.main.async {
            
            view.presentScene(nil)
            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            
            nextScene.setup(tmxFile: nextFilename)
            nextScene.liveMode = liveMode
            nextScene.cameraNode?.showOverlay = showOverlay
            self.updateWindowTitle(withString: nextFilename)
            nextScene.tilemap?.debugDraw = debugMode
        }
    }
    
    /**
     Load the previous tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadPreviousScene(_ interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
        var debugMode = false
        var liveMode = false
        var showOverlay = true
        var zoomLevel: CGFloat = 0
        
        var currentFilename = demoFiles.first!
        if let currentScene = view.scene as? SKTiledDemoScene {
            currentScene.blocked = true
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                zoomLevel = cameraNode.zoom
            }
            
            
            liveMode = currentScene.liveMode
            if let tilemap = currentScene.tilemap {
                debugMode = tilemap.debugDraw
                currentFilename = tilemap.filename!
            }
        }

        var nextFilename = demoFiles.last!
        if let index = demoFiles.index(of: currentFilename), index > 0, index - 1 < demoFiles.count {
            nextFilename = demoFiles[index - 1]
        }
        
        DispatchQueue.main.async {
            view.presentScene(nil)
            
            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            
            nextScene.setup(tmxFile: nextFilename)
            nextScene.liveMode = liveMode
            nextScene.cameraNode?.showOverlay = showOverlay
            nextScene.cameraNode?.zoom = zoomLevel
            self.updateWindowTitle(withString: nextFilename)
            nextScene.tilemap?.debugDraw = debugMode
        }
    }
    
    /**
     Update the window's title bar with the current scene name.
     
     - parameter withFile: `String` currently loaded scene name.
     */
    func updateWindowTitle(withString named: String) {
        // Update the application window title with the current scene
        if let infoDictionary = Bundle.main.infoDictionary {
            if let bundleName = infoDictionary[kCFBundleNameKey as String] as? String {
                self.view.window?.title = "\(bundleName): \(named) "
            }
        }
    }
    
    /**
     Load TMX files from the property list.
     
     - returns: `[String]` array of tiled file names.
     */
    func loadDemoFiles(_ filename: String) -> [String] {
        var result: [String] = []
        if let fileList = Bundle.main.path(forResource: filename, ofType: "plist"){
            if let data = NSArray(contentsOfFile: fileList) as? [String] {
                result = data
            }
        }
        return result
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
    }
}
