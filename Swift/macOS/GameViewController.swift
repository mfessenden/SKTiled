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
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* create the game scene */
        let scene = SKTiledDemoScene(size: self.view.bounds.size, tmxFile: currentFilename)
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .aspectFill
        
        //set up notification for scene to load the next file
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: NSNotification.Name(rawValue: "loadNextScene"), object: nil)
        skView.presentScene(scene)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        updateWindowTitle()
    }
    
    override func scrollWheel(with event: NSEvent) {
        guard let view = self.view as? SKView else { return }
        if let currentScene = view.scene as? SKTiledDemoScene {
            currentScene.scrollWheel(with: event)
        }
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `NSTimeInterval` transition duration.
     */
    func loadNextScene(_ interval: TimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
        var debugMode = false
        
        var currentFilename = demoFiles.first!
        if let currentScene = view.scene as? SKTiledDemoScene {
            debugMode = currentScene.debugMode
            if let tilemap = currentScene.tilemap {
                currentFilename = tilemap.name!
            }
            currentScene.removeFromParent()
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
        updateWindowTitle()
    }
    
    /**
     Update the application window title with the current scene
     */
    func updateWindowTitle(){
        guard let view = self.view as? SKView else { return }
        
        var windowTitle = "SKTiled"
        if let currentScene = view.scene as? SKTiledDemoScene {
            if let tilemap = currentScene.tilemap {
                windowTitle += ": \(tilemap.name!)"
            }
        }
        
        self.view.window!.title = windowTitle
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
