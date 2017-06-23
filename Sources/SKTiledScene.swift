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
    var worldNode: SKNode! { get set }
    /// Custom scene camera.
    var cameraNode: SKTiledSceneCamera! { get set }
    /// Tile map node.
    var tilemap: SKTilemap! { get set }
    /// Load a tilemap from disk, with optional tilesets
    func load(fromFile filename: String, withTilesets tilesets: [SKTileset]) -> SKTilemap?
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
    
    // MARK: - View
    
    override open func didChangeSize(_ oldSize: CGSize) {
        updateCamera()
    }
        
    override open func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        // set up world node
        worldNode = SKNode()
        addChild(worldNode)
        
        // setup the camera
        cameraNode = SKTiledSceneCamera(world: worldNode, view: view)
        addChild(cameraNode)
        camera = cameraNode
    }
        
    // MARK: - Setup
        
    /**
     Load a named TMX file, with optional tilesets.
     
     - parameter fileNamed:  `String` TMX file name.
     - parameter tilesets:   `[SKTileset]` pre-loaded tilesets.
     */
    open func setup(fileNamed: String, tilesets: [SKTileset]=[], _ completion: (() -> ())? = nil) {
        guard let worldNode = worldNode else { return }
        
        self.tilemap?.removeAllActions()
        self.tilemap?.removeAllChildren()
        self.tilemap?.removeFromParent()
        
        self.tilemap = nil
        
        if let tilemap = load(fromFile: fileNamed, withTilesets: tilesets) {
            
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
    public func cameraPositionChanged(_ oldPosition: CGPoint) {}
    public func cameraZoomChanged(_ oldZoom: CGFloat) {}
    public func sceneDoubleTapped() {}
}


// setup methods
extension SKTiledSceneDelegate where Self: SKScene {
    
    /**
     Load a named TMX file, with optional tilesets.
     
     - parameter fromFile:      `String` TMX file name.
     - parameter withTilesets:  `[SKTileset]`
     - returns: `SKTilemap?` tile map node.
     */
    public func load(fromFile filename: String, withTilesets tilesets: [SKTileset]=[]) -> SKTilemap? {
        if let tilemap = SKTilemap.load(fromFile: filename, delegate: self as? SKTilemapDelegate, withTilesets: tilesets) {
            
            if let cameraNode = cameraNode {
                // camera properties inherited from tilemap
                cameraNode.allowMovement = tilemap.allowMovement
                cameraNode.allowZoom = tilemap.allowZoom
                cameraNode.setCameraZoom(tilemap.worldScale)
                cameraNode.setZoomConstraints(minimum: 0.2, maximum: tilemap.maxZoom)
            }
            
            return tilemap
        }
        return nil
    }
}

