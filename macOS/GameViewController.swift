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
        
        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size, tmxFile: currentFilename)
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .aspectFill
        
        //set up notification for scene to load the next file
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: NSNotification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadPreviousScene), name: NSNotification.Name(rawValue: "loadPreviousScene"), object: nil)
        skView.presentScene(scene)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        guard let view = self.view as? SKView else { return }
        
        if let currentScene = view.scene as? SKTiledScene {
            if let tmxName = currentScene.tmxFilename {
                updateWindowTitle(withFile: tmxName)
            }
        }
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
    
    override func mouseEntered(with event: NSEvent) {
        
    }
    
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
                currentFilename = tilemap.name!
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
        updateWindowTitle(withFile: nextFilename)
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
                currentFilename = tilemap.name!
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
    }
    
    /**
     Update the window's title bar with the current scene name.
     
     - parameter withFile: `String` currently loaded scene name.
     */
    fileprivate func updateWindowTitle(withFile named: String) {
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
    fileprivate func loadDemoFiles(_ filename: String) -> [String] {
        var result: [String] = []
        if let fileList = Bundle.main.path(forResource: filename, ofType: "plist"){
            if let data = NSArray(contentsOfFile: fileList) as? [String] {
                result = data
            }
        }
        return result
    }
}
