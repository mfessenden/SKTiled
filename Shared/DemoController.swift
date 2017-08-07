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
    
    static let `default` = DemoController()
    
    weak open var view: SKView?
    
    /// debug visualizations
    open var loggingLevel: LoggingLevel = .debug
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
            roots.append(rpath)
        }
        
        scanForResourceTypes()
        
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
        loadScene(url: url, usePreviousCamera: true)
    }
    
    /**
     Scan root directories and return any matching resource files.
     */
    private func scanForResourceTypes() {
        var resourcesAdded = 0
        
        for root in roots {
            let urls = FileManager.default.listFiles(path: root.path, withExtensions: resourceTypes)
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
    open func reloadScene(_ interval: TimeInterval=0.4) {
        guard let currentURL = currentURL else { return }
        loadScene(url: currentURL, usePreviousCamera: true, interval: interval)
    }
    
    /**
     Load the next tilemap scene.
     
     - parameter interval: `TimeInterval` transition duration.
     */
    open func loadNextScene(_ interval: TimeInterval=0.4) {
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
    open func loadPreviousScene(_ interval: TimeInterval=0.4) {
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
    internal func loadScene(url: URL, usePreviousCamera: Bool, interval: TimeInterval=0.4) {
        guard let view = self.view else {
            print("[DemoController]: ❗️ERROR: view is not set.")
            return
        }
        
        var liveMode = false
        var showOverlay = true
        var cameraPosition = CGPoint.zero
        var cameraZoom: CGFloat = 1
        
        if let currentScene = view.scene as? SKTiledDemoScene {

            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                cameraPosition = cameraNode.position
                cameraZoom = cameraNode.zoom
            }
            
            liveMode = currentScene.liveMode
            if let tilemap = currentScene.tilemap {
                debugDrawOptions = tilemap.debugDrawOptions
                currentURL = url
            }
        }
        
        
        DispatchQueue.main.async {
            view.presentScene(nil)
            
            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            
            
            nextScene.setup(tmxFile: url.lastPathComponent,
                            inDirectory: (url.baseURL == nil) ? nil : url.baseURL!.path,
                            tilesets: [],
                            verbosity: self.loggingLevel, nil)
            
            nextScene.liveMode = liveMode
            if (usePreviousCamera == true) {
                nextScene.cameraNode?.showOverlay = showOverlay
                nextScene.cameraNode?.position = cameraPosition
                nextScene.cameraNode?.setCameraZoom(cameraZoom)
            }
            nextScene.tilemap?.debugDrawOptions = self.debugDrawOptions
        }
    }
    
    open func fitSceneToView() {
        guard let view = self.view else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        
        if let cameraNode = scene.cameraNode {
            cameraNode.fitToView(newSize: view.bounds.size)
        }
    }
    
    open func toggleMapDemoDraw() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            tilemap.baseLayer.debugDrawOptions = (tilemap.baseLayer.debugDrawOptions != []) ? [] : [.demo]
        }
    }
    
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
    
    open func toggleMapObjectDrawing() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            tilemap.showObjects = !tilemap.showObjects
        }
    }
}


extension FileManager {
    
    func listFiles(path: String, withExtensions: [String]=[]) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls: [URL] = []
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }
            let url = URL(fileURLWithPath: s, relativeTo: baseurl)
            
            if withExtensions.contains(url.pathExtension.lowercased()) || (withExtensions.count == 0) {
                urls.append(url)
            }
        })
        return urls
    }
}
