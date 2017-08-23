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


public class DemoController: NSObject, Loggable {

    private let fm = FileManager.default
    static let `default` = DemoController()

    weak public var view: SKView?

    /// Logging verbosity.
    public var loggingLevel: LoggingLevel = SKTiledLoggingLevel
    /// Debug visualization options.
    public var debugDrawOptions: DebugDrawOptions = []

    /// tiled resources
    public var demourls: [URL] = []
    public var currentURL: URL!

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

        Logger.default.loggingLevel = loggingLevel

        // scan for resources
        if let rpath = Bundle.main.resourceURL {
            self.addRoot(url: rpath)
        }


        if (tilemaps.isEmpty == false) {
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
        let statusLevel = (resourcesAdded > 0) ? LoggingLevel.info : LoggingLevel.warning
        log(statusMsg, level: statusLevel)
    }

    // MARK: - Scene Management

    /**
     Reload the current scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    public func reloadScene(_ interval: TimeInterval=0.25) {
        guard let currentURL = currentURL else { return }
        loadScene(url: currentURL, usePreviousCamera: true, interval: interval)
    }

    /**
     Load the next tilemap scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    public func loadNextScene(_ interval: TimeInterval=0.25) {
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
    public func loadPreviousScene(_ interval: TimeInterval=0.25) {
        guard let currentURL = currentURL else { return }
        var nextFilename = demourls.last!
        if let index = demourls.index(of: currentURL), index > 0, index - 1 < demourls.count {
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
    internal func loadScene(url: URL, usePreviousCamera: Bool, interval: TimeInterval=0.25) {
        guard let view = self.view else {
            log("view is not set.", level: .error)
            return
        }

        var hasCurrent = false
        var liveMode = true
        var showOverlay = true
        var cameraPosition = CGPoint.zero
        var cameraZoom: CGFloat = 1
        var isPaused: Bool = false
        var showObjects: Bool = false

        if let currentScene = view.scene as? SKTiledDemoScene {
            hasCurrent = true
            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                cameraPosition = cameraNode.position
                cameraZoom = cameraNode.zoom
            }

            liveMode = currentScene.liveMode
            if let tilemap = currentScene.tilemap {
                debugDrawOptions = tilemap.defaultLayer.debugDrawOptions
                currentURL = url
                showObjects = tilemap.showObjects
            }

            isPaused = currentScene.isPaused
        }


        DispatchQueue.main.async {

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
            }

            guard let tilemap = nextScene.tilemap else {
                self.log("tilemap not loaded.", level: .warning)
                return
            }

            // create the transition
            //let transition = SKTransition.fade(withDuration: interval)
            //view.presentScene(nextScene, transition: transition)
            //nextScene.isPaused = isPaused


            tilemap.defaultLayer.debugDrawOptions = self.debugDrawOptions
            tilemap.showObjects = showObjects

            let sceneInfo = ["hasGraphs": (nextScene.graphs.isEmpty == false),
                             "hasObjects": nextScene.tilemap.getObjects().isEmpty == false]

            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateUIControls"), object: nil, userInfo: sceneInfo)
            nextScene.setupDemoLevel(fileNamed: url.relativePath)

            if (hasCurrent == false) {
                self.log("auto-resizing the view.", level: .debug)
                nextScene.cameraNode.fitToView(newSize: view.bounds.size)
            }

        }
    }

    // MARK: - Demo Control

    /**
     Fit the current scene to the view.
     */
    public func fitSceneToView() {
        guard let view = self.view else { return }
        guard let scene = view.scene as? SKTiledScene else { return }

        if let cameraNode = scene.cameraNode {
            cameraNode.fitToView(newSize: view.bounds.size)
        }
    }

    /**
     Show/hide the grid & map bounds.
     */
    public func toggleMapDemoDraw() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            tilemap.debugDrawOptions = (tilemap.debugDrawOptions.contains(.drawGrid)) ? tilemap.debugDrawOptions.subtracting([.drawGrid, .drawBounds]) : tilemap.debugDrawOptions.insert([.drawGrid, .drawBounds]).memberAfterInsert
        }
    }

    /**
     Show/hide navigation graph visualizations.
     */
    public func toggleMapGraphVisualization() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            for tileLayer in tilemap.tileLayers() where tileLayer.graph != nil {
                tileLayer.debugDrawOptions = (tileLayer.debugDrawOptions.contains(.drawGraph)) ? tileLayer.debugDrawOptions.subtracting([.drawGrid, .drawBounds, .drawGraph]) : tileLayer.debugDrawOptions.insert([.drawGrid, .drawBounds, .drawGraph]).memberAfterInsert
            }
        }
    }

    /**
     Show/hide current scene objects.
     */
    public func toggleMapObjectDrawing() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            tilemap.showObjects = !tilemap.showObjects
            /*
            for objectLayer in tilemap.objectGroups() {
                objectLayer.debugDrawOptions = (objectLayer.debugDrawOptions.contains(.drawObjectBounds)) ? objectLayer.debugDrawOptions.subtracting(.drawObjectBounds) : objectLayer.debugDrawOptions.insert(.drawObjectBounds).memberAfterInsert
            }*/
        }
    }

    /**
     Dump the map statistics to the console.
     */
    public func printMapStatistics() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            tilemap.mapStatistics()
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

            if withExtensions.contains(url.pathExtension.lowercased()) || (withExtensions.isEmpty) {
                urls.append(url)
            }
        })
        return urls
    }
}
