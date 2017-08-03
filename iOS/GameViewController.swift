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
    
    var loggingLevel: LoggingLevel = .debug
    let assetManager: AssetManager = AssetManager.default
    var demourls: [URL] = []
    var currentURL: URL? = nil    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load demo files from the bundle
        demourls = assetManager.tilemaps
        
        guard demourls.count > 0 else {
            print("[GameViewController]: ERROR: no resources found.")
            return
        }
        
        currentURL = demourls.first!

        // Configure the view.
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true

        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        setupDebuggingLabels()
        
        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size)

        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .aspectFill

        //set up notification for scene to load the next file
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: NSNotification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadPreviousScene), name: NSNotification.Name(rawValue: "loadPreviousScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabels), name: NSNotification.Name(rawValue: "updateDebugLabels"), object: nil)
        
        skView.presentScene(scene)
        scene.setup(tmxFile:currentURL!, tilesets: [], verbosity: loggingLevel)
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
    
    @IBAction func fitButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        
        if let cameraNode = scene.cameraNode {
            cameraNode.fitToView()
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
     Set up the debugging labels.
     */
    func setupDebuggingLabels() {
        mapInfoLabel.text = "Map: "
        tileInfoLabel.text = "Tile: "
        propertiesInfoLabel.text = "Properties:"
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
            tilemap.baseLayer.debugDrawOptions = (tilemap.baseLayer.debugDrawOptions != []) ? [] : [.demo]
        }
    }
    
    /**
     Action called when `show graph` button is pressed.
     
     - parameter sender: `Any` ui button.
     */
    @IBAction func graphButtonPressed(_ sender: Any) {
        guard let view = self.view as? SKView,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            for tileLayer in tilemap.tileLayers() {
                if tileLayer.graph != nil {
                    tileLayer.debugDrawOptions = (tileLayer.debugDrawOptions != []) ? [] : [.graph]
                }
            }
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
            // if objects are shown...
            if let tilemap = scene.tilemap {
                tilemap.showObjects = !tilemap.showObjects
            }
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
     Reload the current scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func reloadScene(_ interval: TimeInterval=0.4) {
        guard let currentURL = currentURL else { return }
        loadScene(withMap:currentURL, usePreviousCamera: true, interval: interval)
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadNextScene(_ interval: TimeInterval=0.4) {
        guard let currentURL = currentURL else { return }
        var nextFilename = demourls.first!
        if let index = demourls.index(of:currentURL) , index + 1 < demourls.count {
            nextFilename = demourls[index + 1]
        }
        loadScene(withMap: nextFilename, usePreviousCamera: false, interval: interval)
    }

    /**
     Load the previous tilemap scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    func loadPreviousScene(_ interval: TimeInterval=0.4) {
        guard let currentURL = currentURL else { return }
        var nextFilename = demourls.last!
        if let index = demourls.index(of:currentURL), index > 0, index - 1 < demourls.count {
            nextFilename = demourls[index - 1]
        }
        
        loadScene(withMap: nextFilename, usePreviousCamera: false, interval: interval)
    }
    
    /**
     Loads a named scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    func loadScene(withMap: String, usePreviousCamera: Bool, interval: TimeInterval = 0.4) {
        guard let view = self.view as? SKView else { return }
        
        var debugDrawOptions: DebugDrawOptions = []
        var liveMode = false
        var showOverlay = true
        var cameraPosition = CGPoint.zero
        var cameraZoom: CGFloat = 1
        
        if let currentScene = view.scene as? SKTiledDemoScene {
            // block the scene
            currentScene.blocked = true
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                cameraPosition = cameraNode.position
                cameraZoom = cameraNode.zoom
                
            }
            
            liveMode = currentScene.liveMode
            if let tilemap = currentScene.tilemap {
                debugDrawOptions = tilemap.debugDrawOptions
                //currentFilename = tilemap.filename!
            }
        }
        
        DispatchQueue.global().async {
        
            view.presentScene(nil)
            
            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            
            
            nextScene.setup(tmxFile: withMap, tilesets: [], verbosity: self.loggingLevel)
            nextScene.liveMode = liveMode
            
            if (usePreviousCamera == true) {
                nextScene.cameraNode?.showOverlay = showOverlay
                nextScene.cameraNode?.position = cameraPosition
                nextScene.cameraNode?.setCameraZoom(cameraZoom)
            }
            
            guard let nextTilemap = nextScene.tilemap else {
                print(" -> new tilemap not yet loaded...")
                return
            }
            
            
            DispatchQueue.main.async {
                nextScene.tilemap?.debugDrawOptions = debugDrawOptions
                self.currentFilename = withMap
            }
        }
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
}
