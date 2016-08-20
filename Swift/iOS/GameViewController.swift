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
        scene.scaleMode = .AspectFill        
        
        //set up notification for scene to load the next file
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loadNextScene), name: "loadNextScene", object: nil)
        skView.presentScene(scene)
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `NSTimeInterval` transition duration.
     */
    func loadNextScene(interval: NSTimeInterval=0.4) {
        guard let view = self.view as? SKView else { return }
        
        var currentFilename = demoFiles.first!
        if let currentScene = view.scene as? SKTiledDemoScene {            
            if let tilemap = currentScene.tilemap {
                currentFilename = tilemap.name!
            }
            currentScene.removeFromParent()
        }
        
        view.presentScene(nil)
        
        var nextFilename = demoFiles.first!
        if let index = demoFiles.indexOf(currentFilename) where index + 1 < demoFiles.count {
            nextFilename = demoFiles[index + 1]
        }
        
        let nextScene = SKTiledDemoScene(size: view.bounds.size, tmxFile: nextFilename)
        nextScene.scaleMode = .AspectFill
        let transition = SKTransition.fadeWithDuration(interval)
        view.presentScene(nextScene, transition: transition)

    }
    

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private func loadDemoFiles(filename: String) -> [String] {
        var result: [String] = []
        if let fileList = NSBundle.mainBundle().pathForResource(filename, ofType: "plist"){
            if let data = NSArray(contentsOfFile: fileList) as? [String] {
                result = data
            }
        }
        return result
    }
}


