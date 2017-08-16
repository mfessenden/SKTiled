//
//  SKTiledScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 6/22/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
import GameplayKit


/**
 ## Overview ##
 
 Delegate for managing `SKTilemap` nodes in an SpriteKit [`SKScene`][skscene-url] scene. This protocol and the `SKTiledScene` objects are included as a suggested way to use the `SKTilemap` class, but are not required.
 
 In this configuration, the tile map is a child of the world node and reference the custom `SKTiledSceneCamera` camera.
 
 [skscene-url]:https://developer.apple.com/reference/spritekit/skscene
 */
public protocol SKTiledSceneDelegate: class {
    /// World container node. Tiled assets are parented to this node.
    var worldNode: SKNode! { get set }
    /// Custom scene camera.
    var cameraNode: SKTiledSceneCamera! { get set }
    /// Tile map node.
    var tilemap: SKTilemap! { get set }
    /// Load a tilemap from disk, with optional tilesets.
    func load(tmxFile: String, inDirectory: String?, withTilesets tilesets: [SKTileset], ignoreProperties: Bool, loggingLevel: LoggingLevel) -> SKTilemap?
}


/**
 
 ## Overview ##
 
 Custom scene type for managing `SKTilemap` nodes. 
 
 Conforms to the `SKTiledSceneDelegate` & `SKTilemapDelegate` protocols.
 
 ### Properties: ###
 
 ```
 SKTiledScene.worldNode:    `SKNode!` world container node.
 SKTiledScene.tilemap:      `SKTilemap!` tile map object.
 SKTiledScene.cameraNode:   `SKTiledSceneCamera!` custom scene camera.
 ```
 */
open class SKTiledScene: SKScene, SKPhysicsContactDelegate, SKTiledSceneDelegate, SKTilemapDelegate {
    
    /// World container node.
    open var worldNode: SKNode!
    /// Tile map node.
    open var tilemap: SKTilemap!
    /// Custom scene camera.
    open var cameraNode: SKTiledSceneCamera!
    /// Logging verbosity level.
    open var loggingLevel: LoggingLevel = .info
    
    /// Reference to pathfinding graphs.
    open var graphs: [String : GKGridGraph<GKGridGraphNode>] = [:]
    
    // MARK: - Init
    /**
     Initialize without a tiled map.
     
     - parameter size:  `CGSize` scene size.
     - returns:         `SKTiledScene` scene.
     */
    required public override init(size: CGSize) {
        super.init(size: size)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
    }
     
    deinit {
        removeAllActions()
        removeAllChildren()
    }
    
    open func didChange(_ oldSize: CGSize) {
        updateCamera()
    }
        
    override open func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
    
        // setup world node
        worldNode = SKNode()
        addChild(worldNode)
        
        // setup the camera
        cameraNode = SKTiledSceneCamera(view: view, world: worldNode)
        cameraNode.addDelegate(self)
        addChild(cameraNode)
        camera = cameraNode
    }    
    
    // MARK: - Setup
    /**
     Load and setup a named TMX file, with optional tilesets.
     
     - parameter tmxURL:      `URL` TMX path.
     - parameter tilesets:    `[SKTileset]` pre-loaded tilesets.
     - parameter completion:  `(() -> ())?` optional completion handler.
     */
    open func setup(tmxURL: URL,
                    tilesets: [SKTileset]=[],
                    loggingLevel: LoggingLevel = .info,
                    _ completion: (() -> ())? = nil) {
        
        // TODO: finish me
    }

    
    
    /**
     Load and setup a named TMX file, with optional tilesets. Allows for an optional completion handler.
     
     - parameter tmxFile:          `String` TMX file name.
     - parameter inDirectory:      `String?` search directory (if not bundled)
     - parameter withTilesets:     `[SKTileset]` optional pre-loaded tilesets.
     - parameter ignoreProperties: `Bool` don't parse custom properties.
     - parameter loggingLevel:     `LoggingLevel` logging verbosity.
     - parameter completion:  `(() -> ())?` optional completion handler.
     */
    open func setup(tmxFile: String,
                    inDirectory: String? = nil,
                    withTilesets tilesets: [SKTileset]=[],
                    ignoreProperties: Bool = false,
                    loggingLevel: LoggingLevel = .info,
                    _ completion: (() -> ())? = nil) {
        
        guard let worldNode = worldNode else { return }

        self.loggingLevel = loggingLevel
        self.tilemap = nil
        
        if let tilemap = load(tmxFile: tmxFile,
                              inDirectory: inDirectory,
                              withTilesets: tilesets,
                              ignoreProperties: ignoreProperties,
                              loggingLevel: loggingLevel) {
        
            backgroundColor = tilemap.backgroundColor ?? SKColor.clear
        
            // add the tilemap to the world container node.
            worldNode.addChild(tilemap)
            self.tilemap = tilemap
            cameraNode.addDelegate(self.tilemap)
            
            // apply gravity from the tile map
            physicsWorld.gravity = tilemap.gravity
            
            // camera properties inherited from tilemap
            cameraNode.allowMovement = tilemap.allowMovement
            cameraNode.allowZoom = tilemap.allowZoom
            
            // initial zoom level
            if (tilemap.autoResize == true) {
                if let view = view {
                    cameraNode.fitToView(newSize: view.bounds.size)   /// was size
                }
            } else {
                cameraNode.setCameraZoom(tilemap.worldScale)
            }
            
            // run completion handler
            completion?()
        }
    }
    
    // MARK: - Delegate Callbacks
    open func didBeginParsing(_ tilemap: SKTilemap) {
        // Called when tilemap is instantiated.
        if loggingLevel.rawValue == 4 { print(" ❊ `SKTiledScene.didBeginParsing`...")}
    }
            
    open func didAddTileset(_ tileset: SKTileset) {
        // Called when a tileset has been added.
        if loggingLevel.rawValue == 4 { print(" ❊ `SKTiledScene.didAddTileset`: \"\(tileset.name)\"") }
    }
    
    open func didAddLayer(_ layer: TiledLayerObject) {
        // Called when a layer has been added.
        if loggingLevel.rawValue == 4 { print(" ❊ `SKTiledScene.didAddLayer`: \"\(layer.layerName)\"") }
    }
    
    open func didReadMap(_ tilemap: SKTilemap) {
        // Called before layers are rendered.
        if loggingLevel.rawValue == 4 { print(" ❊ `SKTiledScene.didReadMap`: \"\(tilemap.mapName)\"") }
    }
    
    open func didRenderMap(_ tilemap: SKTilemap) {
        // Called after layers are rendered. Perform any post-processing here.
        if loggingLevel.rawValue == 4 { print(" ❊ `SKTiledScene.didRenderMap`: \"\(tilemap.mapName)\"") }
    }

     open func didAddPathfindingGraph(_ graph: GKGridGraph<GKGridGraphNode>) {
        // Called when a graph is added to the scene.
        if loggingLevel.rawValue == 4 { print(" ❊ `SKTiledScene.didAddPathfindingGraph`: \"\(graph)\"") }
    }
    
    open func objectForTileType(named: String?) -> SKTile.Type {
        return SKTile.self
    }
    
    open func objectForVectorType(named: String?) -> SKTileObject.Type {
        return SKTileObject.self
    }
    
    // MARK: - Updating
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        // update the tilemap
        tilemap?.update(currentTime)
    }
    
    override open func didFinishUpdate() {
        tilemap?.clampPositionForMap()
    }

    // TODO: update this
    open func updateCamera() {
        guard let view = view else { return }
        
        let viewSize = view.bounds.size
        if let cameraNode = cameraNode {
            cameraNode.bounds = CGRect(x: -(viewSize.width / 2), y: -(viewSize.height / 2),
                                       width: viewSize.width, height: viewSize.height)
        }
    }
    
    
    open func writeMapToFiles() {
        guard let view = self.view as? SKView else { return }
        guard let tilemap = tilemap else { return }
        
        
        let fm = FileManager.default
        let tmpDir = getTempDirectory()
        let mapDir = tmpDir.appendingPathComponent(tilemap.url.path.basename, isDirectory: true)
        
        do {
            try fm.createDirectory(atPath: mapDir.absoluteString, withIntermediateDirectories: true, attributes: nil)
            print(" → creating temp directory: \(mapDir.path)")
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        
        let boundsRect = tilemap.calculateAccumulatedFrame()
        let skView = SKView()
        for layer in tilemap.tileLayers() {
            
            let layerRect = layer.calculateAccumulatedFrame()
            
            let layerImage = imageOfSize(boundsRect.size, scale: SKTiledContentScaleFactor) { context, bounds, scale in
                layer.flattenLayer(view: skView)
            }
            
            
            writeToFile(layerImage, url: mapDir.appendingPathComponent("\(layer.layerName).png"))
            
        }
        
    }
    
}


// setup methods
extension SKTiledSceneDelegate where Self: SKScene {
    
    /**
     Load a named TMX file, with optional tilesets. 
     
     - parameter inDirectory:      `String?` search directory (if not bundled)
     - parameter withTilesets:     `[SKTileset]` optional pre-loaded tilesets.
     - parameter ignoreProperties: `Bool` don't parse custom properties.
     - parameter verbosity:        `LoggingLevel` logging verbosity.
     - returns: `SKTilemap?` tile map node.
     */
    public func load(tmxFile: String,
                     inDirectory: String? = nil,
                     withTilesets tilesets: [SKTileset]=[],
                     ignoreProperties: Bool = false,
                     loggingLevel: LoggingLevel = .info) -> SKTilemap? {
        
                
        if let tilemap = SKTilemap.load(tmxFile: tmxFile,
                                        inDirectory: inDirectory,
                                        delegate: self as? SKTilemapDelegate,
                                        withTilesets: tilesets,
                                        ignoreProperties: ignoreProperties,
                                        loggingLevel: loggingLevel) {
            
            if let cameraNode = cameraNode {
                // camera properties inherited from tilemap
                cameraNode.allowMovement = tilemap.allowMovement
                cameraNode.allowZoom = tilemap.allowZoom
                cameraNode.setCameraZoom(tilemap.worldScale)
                cameraNode.maxZoom = tilemap.maxZoom
            }
            
            return tilemap
        }
        return nil
    }
}


// default methods
extension SKTiledScene: TiledSceneCameraDelegate {
    
    /**
     Called when the camera positon changes.
     
     - parameter newPositon: `CGPoint` updated camera position.
     */
    public func cameraPositionChanged(newPosition: CGPoint) {
        // TODO: remove this notification callback in master
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": cameraNode?.description ?? "nil"])
    }
    
    /**
     Called when the camera zoom changes.
     
     - parameter newZoom: `CGFloat` camera zoom amount.
     */
    public func cameraZoomChanged(newZoom: CGFloat) {
        // TODO: remove this notification callback in master
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": cameraNode?.description ?? "nil"])
    }
    
    /**
     Called when the camera bounds updated.
     
     - parameter bounds:  `CGRect` camera view bounds.
     - parameter positon: `CGPoint` camera position.
     - parameter zoom:    `CGFloat` camera zoom amount.
     */
    public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {
        // override in subclass
        print("-> camera bounds updated: \(bounds.roundTo()), pos: \(position.roundTo()), zoom: \(zoom.roundTo())")
    }

    #if os(iOS) || os(tvOS)
    /**
     Called when the scene is double tapped. (iOS only)
     
     - parameter location: `CGPoint` touch location.
     */
    public func sceneDoubleTapped(location: CGPoint) {
        print("[SKTiledScene]: DEBUG: scene was double tapped.")
        self.isPaused = !self.isPaused
    }
    
    /**
     Called when the scene is swiped. (iOS only)
     */
    public func sceneSwiped() {}
    #else
    
    /**
     Called when the scene is double-clicked. (macOS only)
     
     - parameter event: `NSEvent` mouse click event.
     */
    public func sceneDoubleClicked(event: NSEvent) {
        let location = event.location(in: self)
        print("[SKTiledScene]: scene double clicked: \(location.shortDescription)")
        addTemporaryShape(at: location, radius: 4, duration: 1.5)
    }
    
    /**
     Called when the mouse moves in the scene. (macOS only)
     
     - parameter event: `NSEvent` mouse event.
     */
    public func mousePositionChanged(event: NSEvent) {
        let location = event.location(in: self)
        print("[SKTiledScene]: mouse moved: \(location.shortDescription)")
        addTemporaryShape(at: location, radius: 4, duration: 1.5)
    }
    #endif
}





