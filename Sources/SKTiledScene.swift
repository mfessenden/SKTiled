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
 Delegate for managing `SKTilemap` nodes in an [`SKScene`](https://developer.apple.com/reference/spritekit/skscene). This protocol and the `SKTiledScene` objects are included as a suggested way to use the `SKTilemap` class, but are not required.
 
 In this configuration, the tile map is a child of the world node and reference the custom `SKTiledSceneCamera` camera.
 */
public protocol SKTiledSceneDelegate: class {
    /// World container node. Tiled assets are parented to this node.
    var worldNode: SKNode! { get set }
    /// Custom scene camera.
    var cameraNode: SKTiledSceneCamera! { get set }
    /// Tile map node.
    var tilemap: SKTilemap! { get set }
    /// Load a tilemap from disk, with optional tilesets
    func load(tmxFile: String, inDirectory: String?, withTilesets tilesets: [SKTileset], verbosity: LoggingLevel) -> SKTilemap?
}


/**
 Custom scene type for managing `SKTilemap` nodes.
 
 - parameter worldNode:  `SKNode!` world container node.
 - parameter cameraNode: `SKTiledSceneCamera!` scene camera node.
 - parameter tilemap:    `SKTilemap!` tile map node.
 */
open class SKTiledScene: SKScene, SKPhysicsContactDelegate, SKTiledSceneDelegate, SKTilemapDelegate {
    
    /// World container node.
    open var worldNode: SKNode!
    /// Tile map node.
    open var tilemap: SKTilemap!
    /// Custom scene camera.
    open var cameraNode: SKTiledSceneCamera!
    
    open var loggingLevel: LoggingLevel = .info
    
    /// Reference to pathfinding graphs.
    open var graphs: [String : GKGridGraph<SKTiledGraphNode>] = [:]
    
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
    
        // set up world node
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
                    verbosity: LoggingLevel = .info,
                    _ completion: (() -> ())? = nil) {
        
        // TODO: finish me
    }
    
    /**
     Load and setup a named TMX file, with optional tilesets.
     
     - parameter tmxFile:     `String` TMX file name.
     - parameter inDirectory: `String?` optional path for file.
     - parameter tilesets:    `[SKTileset]` pre-loaded tilesets.
     - parameter completion:  `(() -> ())?` optional completion handler.
     */
    open func setup(tmxFile: String,
                    inDirectory: String? = nil,
                    tilesets: [SKTileset]=[],
                    verbosity: LoggingLevel = .info,
                    _ completion: (() -> ())? = nil) {
        
        guard let worldNode = worldNode else { return }
        
        // TODO: Concurrency
        //self.tilemap?.removeAllActions()
        //self.tilemap?.removeAllChildren()
        //self.tilemap?.removeFromParent()
        
        self.tilemap = nil
        
        if let tilemap = load(tmxFile: tmxFile, inDirectory: inDirectory, withTilesets: tilesets, verbosity: verbosity) {
        
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
        print(" ❊ `SKTiledScene.didBeginParsing`...")
        
    }
            
    open func didAddTileset(_ tileset: SKTileset) {
        // Called when a tileset has been added.
        print(" ❊ `SKTiledScene.didAddTileset`: \"\(tileset.name)\"")
    }
    
    open func didAddLayer(_ layer: TiledLayerObject) {
        // Called when a layer has been added.
        print(" ❊ `SKTiledScene.didAddLayer`: \"\(layer.layerName)\"")
    }
    
    open func didReadMap(_ tilemap: SKTilemap) {
        // Called before layers are rendered.
        print(" ❊ `SKTiledScene.didReadMap`: \"\(tilemap.mapName)\"")
    }
    
    open func didRenderMap(_ tilemap: SKTilemap) {
        // Called after layers are rendered. Perform any post-processing here.
    }
    
    // MARK: - Updates
    override open func didFinishUpdate() {
        tilemap?.clampPositionForMap()
    }
    
    
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        // update the tilemap
        tilemap?.update(currentTime)
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
}


// setup methods
extension SKTiledSceneDelegate where Self: SKScene {
    
    /**
     Load a named TMX file, with optional tilesets.
     
     - parameter tmxFile:      `String` TMX file name.
     - parameter withTilesets:  `[SKTileset]`
     - returns: `SKTilemap?` tile map node.
     */
    public func load(tmxFile: String,
                     inDirectory: String? = nil,
                     withTilesets tilesets: [SKTileset]=[],
                     verbosity: LoggingLevel = .info) -> SKTilemap? {
        
                
        if let tilemap = SKTilemap.load(tmxFile: tmxFile,
                                        inDirectory: inDirectory,
                                        delegate: self as? SKTilemapDelegate,
                                        withTilesets: tilesets,
                                        ignoreProperties: false,
                                        verbosity: verbosity) {
            
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
    
    public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {
        // override in subclass
        print("-> camera bounds updated: \(bounds.roundTo()), pos: \(position.roundTo()), zoom: \(zoom.roundTo())")
    }
    
    // TODO: remove this notification callback in master
    public func cameraPositionChanged(newPosition: CGPoint) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": cameraNode?.description ?? "nil"])
    }
    
    // TODO: remove this notification callback in master
    public func cameraZoomChanged(newZoom: CGFloat) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": cameraNode?.description ?? "nil"])
    }
    
    #if os(iOS) || os(tvOS)
    public func sceneDoubleTapped() {}
    #endif
}





