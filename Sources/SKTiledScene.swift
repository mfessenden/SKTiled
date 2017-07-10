//
//  SKTiledScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 6/22/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/**
 Delegate for managing `SKTilemap` nodes in an [`SKScene`](https://developer.apple.com/reference/spritekit/skscene). This protocol and the `SKTiledScene` objects are included as a suggested way to use the `SKTilemap` class, but are not required.
 
 In this configuration, the tile map is a child of the world node and reference the custom `SKTiledSceneCamera` camera.
 
 - parameter worldNode:  `SKNode?` world container node.
 - parameter cameraNode: `SKTiledSceneCamera!` scene camera node.
 - parameter tilemap:    `SKTilemap?` tile map node.
    */
public protocol SKTiledSceneDelegate: class {
    /// World container node. Tiled assets are parented to this node.
    var worldNode: SKNode? { get set }
    /// Custom scene camera.
    var cameraNode: SKTiledSceneCamera! { get set }
    /// Tile map node.
    var tilemap: SKTilemap? { get set }
    /// Load a tilemap from disk, with optional tilesets
    func load(fromFile filename: String, withTilesets tilesets: [SKTileset]) -> SKTilemap?

    func cameraPositionChanged(_ oldPosition: CGPoint)
    func cameraZoomChanged(_ oldZoom: CGFloat)
    func sceneDoubleTapped()
}


/**
 Custom scene type for managing `SKTilemap` nodes.
 
 - parameter worldNode:  `SKNode!` world container node.
 - parameter cameraNode: `SKTiledSceneCamera!` scene camera node.
 - parameter tilemap:    `SKTilemap!` tile map node.
 */
open class SKTiledScene: SKScene, SKPhysicsContactDelegate, SKTiledSceneDelegate, SKTilemapDelegate {
    
    /// World container node.
    open var worldNode: SKNode?
    /// Tile map node.
    open var tilemap: SKTilemap?
    /// Custom scene camera.
    open var cameraNode: SKTiledSceneCamera!
    
    // MARK: - Init
    /**
     Initialize without a tiled map.
     
     - parameter size:  `CGSize` scene size.
     - returns:         `SKTiledScene` scene.
     */
    required public override init(size: CGSize) {
        super.init(size: size)
        setupWorld()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
    }
    
    deinit {
        removeAllActions()
        removeAllChildren()
    }
    
    // MARK: - View
    
    override open func sceneDidLoad() {
        setupWorld()
    }
    
    override open func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateCamera()
        cameraNode?.fitToView(newSize: size)
    }
        
    override open func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        // setup the camera
        setupCamera(view: view)
    }
        
    // MARK: - Setup
        
    /**
     Load a named TMX file, with optional tilesets.
     
     - parameter tmxFile:    `String` TMX file name.
     - parameter tilesets:   `[SKTileset]` pre-loaded tilesets.
     - parameter completion: `(() -> ())?` optional completion handler.
     */
    open func setup(tmxFile: String, tilesets: [SKTileset]=[], _ completion: (() -> ())? = nil) {
        guard let worldNode = worldNode else { return }
        
        self.tilemap?.removeAllActions()
        self.tilemap?.removeAllChildren()
        self.tilemap?.removeFromParent()
        
        self.tilemap = nil
        
        if let tilemap = load(fromFile: tmxFile, withTilesets: tilesets) {
            
            backgroundColor = tilemap.backgroundColor ?? SKColor.clear
            
            // add the tilemap to the world container node.
            worldNode.addChild(tilemap)
            self.tilemap = tilemap
            
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
    
    /**
     Transition the scene with a new tilemap.
     
     - parameter tmxFile:   `String` TMX file name.
     - parameter duration:  `TimeInterval` transition length.
     - parameter tilesets:  `[SKTileset]?` optional pre-loaded tilesets.
     */
    open func transitionTo<Scene: SKTiledScene>(tmxFile: String, duration: TimeInterval=0.5) -> Scene? {
        guard let view = self.view else { return nil }
    
        // clear the current scene
        view.presentScene(nil)
        let reveal = SKTransition.fade(with: SKColor.black, duration: duration)
     
        let nextScene = Scene(size: view.bounds.size)
        nextScene.scaleMode = self.scaleMode
        view.presentScene(nextScene, transition: reveal)
        // setup next tilemap
        nextScene.setup(tmxFile: tmxFile)
        return nextScene
    }
    
    // MARK: - Delegate Callbacks
    open func didBeginParsing(_ tilemap: SKTilemap) {
        // Called when tilemap is instantiated.
    }
    
    open func didAddTileset(_ tileset: SKTileset) {
        // Called when a tileset has been added.
    }
    
    open func didAddLayer(_ layer: TiledLayerObject) {
        // Called when a layer has been added.
    }
    
    open func didReadMap(_ tilemap: SKTilemap) {
        // Called before layers are rendered.
    }
    
    open func didRenderMap(_ tilemap: SKTilemap) {
        // Called after layers are rendered. Perform any post-processing here.
        self.physicsWorld.speed = 1
    }
    
    // MARK: - Updates
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
    }
    
    open func updateCamera() {
        guard let view = view else { return }
        let viewSize = view.bounds.size
        if let cameraNode = cameraNode {
            cameraNode.bounds = CGRect(x: -(viewSize.width / 2), y: -(viewSize.height / 2),
                                       width: viewSize.width, height: viewSize.height)
        }
    }
}


// default methods
extension SKTiledSceneDelegate {
    public func cameraPositionChanged(_ oldPosition: CGPoint) {
        guard let cameraNode = cameraNode else { return }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": cameraNode.description])
    }
    
    public func cameraZoomChanged(_ oldZoom: CGFloat) {
        guard let cameraNode = cameraNode else { return }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": cameraNode.description])
    }
    public func sceneDoubleTapped() {}
}


// setup methods
extension SKTiledSceneDelegate where Self: SKScene {
    
    /**
     Load a named TMX file.
     
     - parameter filename:  `String` TMX file name.
     - returns: `SKTilemap?` tile map node.
     */
    public func load(fromFile filename: String, withTilesets tilesets: [SKTileset]=[]) -> SKTilemap? {
        if let tilemap = SKTilemap.load(fromFile: filename, delegate: self as? SKTilemapDelegate, withTilesets: tilesets) {
            
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
    
    /**
     Present a new scene with a TMX filename.
     
     - parameter nextScene:  `SKScene` SpriteKit scene.
     - parameter tmxFile:    `String?` optional TMX file name.
     - parameter duration:   `TimeInterval` transition duration.
     - parameter completion: `(() -> ())?` optional completion method.
     - returns: `SKTilemap?` tile map node.
     */
    public func presentScene(_ nextScene: SKScene, tmxFile: String? = nil, duration: TimeInterval = 0.5, _ completion: (() -> ())? = nil) {
        let transition = SKTransition.fade(withDuration: duration)
        nextScene.scaleMode = scaleMode
        
        defer {
            //print("[SKTiledSceneDelegate]: running completion...")
            completion?()
        }
        view?.presentScene(nextScene, transition: transition)
        
        if let sceneDelegate = nextScene as? SKTiledSceneDelegate {
            if tmxFile != nil {
                if let newTilemap = sceneDelegate.load(fromFile: tmxFile!, withTilesets: []) {
                    
                    sceneDelegate.tilemap = newTilemap
                    sceneDelegate.worldNode?.addChild(newTilemap)
                    
                    if let cameraNode = sceneDelegate.cameraNode {
                        // camera properties inherited from tilemap
                        cameraNode.allowMovement = newTilemap.allowMovement
                        cameraNode.allowZoom = newTilemap.allowZoom
                        cameraNode.setCameraZoom(newTilemap.worldScale)
                        cameraNode.maxZoom = newTilemap.maxZoom
                    }
                }
            }
        }
    }

    /**
     Setup a world node.
     */
    public func setupWorld(){
        // remove current node
        worldNode?.removeFromParent()
        // set up world node
        let world = SKNode()
        world.name = "World"
        addChild(world)
        worldNode = world
    }
    
    /**
     Setup the scene camera, referencing the world container node.
     */
    public func setupCamera(view: SKView?){
        guard let worldNode = worldNode else { return }
        cameraNode = SKTiledSceneCamera(world: worldNode, delegate: self, view: view)
        addChild(cameraNode)
        camera = cameraNode
    }
}



