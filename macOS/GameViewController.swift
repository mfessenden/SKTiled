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
    
    @IBOutlet weak var chooseButton: NSButton!
    @IBOutlet weak var fitButton: NSButton!
    @IBOutlet weak var gridButton: NSButton!
    @IBOutlet weak var objectsButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
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
        setupDebuggingLabels()
        
        
        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size, tmxFile: currentFilename)
        
        /* set the scale mode to scale to fit the window */
        scene.scaleMode = .aspectFill
        
        //set up notification for scene to load the next file
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: NSNotification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadPreviousScene), name: NSNotification.Name(rawValue: "loadPreviousScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        
        skView.presentScene(scene)
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
     Set up the debugging labels.
     */
    func setupDebuggingLabels() {
        mapInfoLabel.stringValue = "Map: "
        tileInfoLabel.stringValue = "Tile: "
        propertiesInfoLabel.stringValue = "Properties:"
        
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 2, height: 1)
        shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.75)
        shadow.shadowBlurRadius = 0.5
        mapInfoLabel.shadow = shadow
        tileInfoLabel.shadow = shadow
        propertiesInfoLabel.shadow = shadow
        
    }
    
    @IBAction func fitButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        
        if let cameraNode = scene.cameraNode {
            cameraNode.fitToView(newSize: view.bounds.size)
        }
    }
    
    @IBAction func gridButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            tilemap.debugDraw = !tilemap.debugDraw
        }
    }
    
    @IBAction func objectsButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            let debugState = !tilemap.showObjects
            tilemap.showObjects = debugState
        }
    }
    
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
    
    override func mouseEntered(with event: NSEvent) {}
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadNextScene(_ interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        var debugMode = false
        var currentFilename = demoFiles.first!
        var showOverlay: Bool = true
        if let currentScene = view.scene as? SKTiledDemoScene {
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
            }
            debugMode = currentScene.debugMode
            if let tilemap = currentScene.tilemap {
                currentFilename = tilemap.filename!
            }
            
            currentScene.removeFromParent()
            currentScene.removeAllActions()
        }
        
        view.presentScene(nil)
        
        var nextFilename = demoFiles.first!
        if let index = demoFiles.index(of: currentFilename) , index + 1 < demoFiles.count {
            nextFilename = demoFiles[index + 1]
        }
        
        let nextScene = SKTiledDemoScene(size: view.bounds.size, tmxFile: nextFilename)
        nextScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: interval)
        nextScene.debugMode = debugMode
        view.presentScene(nextScene, transition: transition)
        
        nextScene.cameraNode?.showOverlay = showOverlay
        updateWindowTitle(withString: nextFilename)
        
        nextScene.tilemap?.layerStatistics()
    }
    
    /**
     Load the previous tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadPreviousScene(_ interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
        var currentFilename = demoFiles.first!
        var showOverlay: Bool = true
        if let currentScene = view.scene as? SKTiledDemoScene {
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
            }
            if let tilemap = currentScene.tilemap {
                currentFilename = tilemap.filename!
            }
            
            currentScene.removeFromParent()
            currentScene.removeAllActions()
        }
        
        view.presentScene(nil)
        
        var nextFilename = demoFiles.last!
        if let index = demoFiles.index(of: currentFilename), index > 0, index - 1 < demoFiles.count {
            nextFilename = demoFiles[index - 1]
        }
        
        let nextScene = SKTiledDemoScene(size: view.bounds.size, tmxFile: nextFilename)
        nextScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: interval)
        view.presentScene(nextScene, transition: transition)
        nextScene.cameraNode?.showOverlay = showOverlay
        
        nextScene.tilemap?.layerStatistics()
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
    }
}
