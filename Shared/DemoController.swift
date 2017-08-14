//
//  DemoController.swift
//  SKTiled
//
//  Created by Michael Fessenden on 8/4/17.
//  Copyright © 2017 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


open class DemoController: NSObject {
    
    private let fm = FileManager.default
    static let `default` = DemoController()
    
    weak open var view: SKView?
    
    /// Logging verbosity.
    open var loggingLevel: LoggingLevel = SKTiledLoggingLevel
    /// Debug visualization options.
    open var debugDrawOptions: DebugDrawOptions = []
    
    /// tiled resources
    open var demourls: [URL] = []
    open var currentURL: URL!
    
    private var roots: [URL] = []
    private var resources: [URL] = []
    public var resourceTypes: [String] = ["tmx", "tsx", "png"]
    
    public var tilemaps: [URL] {
        return resources.filter { $0.pathExtension.lowercased() == "tmx" }
    }
    
    public var tilesets: [URL] {
        return resources.filter { $0.pathExtension.lowercased() == "tsx" }
    }
    
    /// Returns the current demo file index.
    public var currentIndex: Int {
        guard let currentURL = currentURL else { return 0 }
        
        var currentMapIndex = demourls.count - 1
        if let mapIndex = demourls.index(of: currentURL) {
            currentMapIndex = Int(mapIndex) + 1
        }
        return currentMapIndex
    }
    
    
    // MARK: - Init
    override public init() {
        super.init()
        
        // scan for resources
        if let rpath = Bundle.main.resourceURL {
            self.addRoot(url: rpath)
        }
        
        scanForResourceTypes()
        listBundledResources()
        
        if tilemaps.count > 0 {
            demourls = tilemaps
            currentURL = demourls.first
        }
        
        
        //set up notification for scene to load the next file
        NotificationCenter.default.addObserver(self, selector: #selector(reloadScene), name: NSNotification.Name(rawValue: "reloadScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadNextScene), name: NSNotification.Name(rawValue: "loadNextScene"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadPreviousScene), name: NSNotification.Name(rawValue: "loadPreviousScene"), object: nil)
    }
    
    public init(view: SKView) {
        self.view = view
        super.init()
    }
    
    // MARK: - Asset Management
    /**
     Add a new root path and scan.
     
     - parameter path: `String` resource root path.
     */
    public func addRoot(url: URL) {
        if !roots.contains(url) {
            print("[DemoController]: adding root:  \"\(url.path)\"")
            roots.append(url)
            scanForResourceTypes()
        }
    }
    
    /**
     URL is relative.
     */
    public func addTilemap(url: URL, at index: Int) {
        demourls.insert(url, at: index)
        loadScene(url: url, usePreviousCamera: false)
    }
    
    /**
     Scan root directories and return any matching resource files.
     */
    private func scanForResourceTypes() {
        var resourcesAdded = 0
        
        for root in roots {
            let urls = fm.listFiles(path: root.path, withExtensions: resourceTypes, loggingLevel: loggingLevel)
            resources.append(contentsOf: urls)
            resourcesAdded += urls.count
        }
        
        let statusMsg = (resourcesAdded > 0) ? "\(resourcesAdded) resources added." : "WARNING: no resources found."
        print("[DemoController]: \(statusMsg)")
    }
    
    // MARK: - Scene Management
    
    /**
     Reload the current scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    open func reloadScene(_ interval: TimeInterval=0) {
        guard let currentURL = currentURL else { return }
        loadScene(url: currentURL, usePreviousCamera: true, interval: interval)
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    open func loadNextScene(_ interval: TimeInterval=0) {
        guard let currentURL = currentURL else { return }
        var nextFilename = demourls.first!
        if let index = demourls.index(of: currentURL), index + 1 < demourls.count {
            nextFilename = demourls[index + 1]
        }
        loadScene(url: nextFilename, usePreviousCamera: false, interval: interval)
    }
    
    /**
     Load the previous tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    open func loadPreviousScene(_ interval: TimeInterval=0) {
        guard let currentURL = currentURL else { return }
        var nextFilename = demourls.last!
        if let index = demourls.index(of:currentURL), index > 0, index - 1 < demourls.count {
            nextFilename = demourls[index - 1]
        }
        loadScene(url: nextFilename, usePreviousCamera: false, interval: interval)
    }
    
    /**
     Loads a named scene.
     - parameter url:               `URL` file url.
     - parameter usePreviousCamera: `Bool` transfer camera information.
     - parameter interval:          `TimeInterval` transition duration.
     */
    internal func loadScene(url: URL, usePreviousCamera: Bool, interval: TimeInterval=0) {
        guard let view = self.view else {
            print("[DemoController]: ❗️ERROR: view is not set.")
            return
        }
        
        var liveMode = false
        var showOverlay = true
        var cameraPosition = CGPoint.zero
        var cameraZoom: CGFloat = 1
        var isPaused: Bool = false
        
        if let currentScene = view.scene as? SKTiledDemoScene {

            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                cameraPosition = cameraNode.position
                cameraZoom = cameraNode.zoom
            }
            
            liveMode = currentScene.liveMode
            if let tilemap = currentScene.tilemap {
                debugDrawOptions = tilemap.defaultLayer.debugDrawOptions
                currentURL = url
            }
            
            isPaused = currentScene.isPaused
        }
        
        
        DispatchQueue.main.async {
            view.presentScene(nil)
            
            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            
            // create the transition
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            nextScene.isPaused = isPaused
            
            nextScene.setup(tmxFile: url.relativePath,
                            inDirectory: (url.baseURL == nil) ? nil : url.baseURL!.path,
                            withTilesets: [],
                            ignoreProperties: false,
                            loggingLevel: self.loggingLevel, nil)
            
            nextScene.liveMode = liveMode
            
            if (usePreviousCamera == true) {
                nextScene.cameraNode?.showOverlay = showOverlay
                nextScene.cameraNode?.position = cameraPosition
                nextScene.cameraNode?.setCameraZoom(cameraZoom, interval: interval)
                //nextScene.cameraNode.fitToView(newSize: view.bounds.size, transition: interval)
            }
            
            guard let tilemap = nextScene.tilemap else { return }
            tilemap.defaultLayer.debugDrawOptions = self.debugDrawOptions
            
            let sceneInfo = ["hasGraphs": nextScene.graphs.count > 0, "hasObjects": nextScene.tilemap.getObjects().count > 0]
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateUIControls"), object: nil, userInfo: sceneInfo)
            
            
            nextScene.setup(fileNamed: url.relativePath)
            
        }
    }
    
    // MARK: - Demo Control
    
    /**
     Fit the current scene to the view.
     */
    open func fitSceneToView() {
        guard let view = self.view else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        
        if let cameraNode = scene.cameraNode {
            cameraNode.fitToView(newSize: view.bounds.size)
        }
    }
    
    /**
     Show/hide the grid & map bounds.
     */
    open func toggleMapDemoDraw() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            tilemap.defaultLayer.debugDrawOptions = (tilemap.defaultLayer.debugDrawOptions != []) ? [] : [.demo]
        }
    }
    
    /**
     Show/hide pathfinding graph visualizations.
     */
    open func toggleMapGraphVisualization() {
        guard let view = self.view,
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
     Show/hide current scene objects.
     */
    open func toggleMapObjectDrawing() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            tilemap.showObjects = !tilemap.showObjects
        }
    }
    
    // MARK: - Experimental
    // TODO: experimental
    open func listBundledResources() {
        let bundleURL = Bundle.main.bundleURL  // SKTiledDemo.app
        let assetname = "pm-maze-8x8"
        print(" ❊ Querying asset: ")
        
        if let asset = NSDataAsset(name: assetname) {
            print("   ➜ found asset \"\(assetname)\"")
            let texture = SKTexture(data: asset.data, size: .zero)
            print("    ↳ created texture: \"\(assetname)\"")
            print(texture)
            
        }
    }
}


extension FileManager {
    
    func listFiles(path: String, withExtensions: [String]=[], loggingLevel: LoggingLevel = .info) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls: [URL] = []
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }
            let url = URL(fileURLWithPath: s, relativeTo: baseurl)
            
            if withExtensions.contains(url.pathExtension.lowercased()) || (withExtensions.count == 0) {
                
                if loggingLevel.rawValue < 1 {
                    print("[FileManager]: adding resource: \"\(url.relativePath)\"")
                }
                urls.append(url)
            }
        })
        return urls
    }
}
