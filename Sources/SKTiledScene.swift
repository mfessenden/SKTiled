//
//  SKTiledScene.swift
//  SKTiled
//
//  Created by Michael Fessenden on 6/22/16.
//  Copyright (c) 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/**
 Delegate for managing `SKTilemap` nodes in an `SKScene`. This protocol and the `SKTiledScene` objects are included as a suggested way to use the `SKTilemap` class, but are not required.
 
 In this configuration, the tile map is a child of the world node and reference the custom `SKTiledSceneCamera` camera.
 
 - parameter worldNode:  `SKNode!` world container node.
 - parameter cameraNode: `SKTiledSceneCamera!` scene camera node.
 - parameter tilemap:    `SKTilemap!` tile map node.
 */
public protocol SKTiledSceneDelegate {
    /** 
     World container node. All Tiled assets are parented to this node.
    */
    var worldNode: SKWorld! { get set }
    /// Custom scene camera.
    var cameraNode: SKTiledSceneCamera! { get set }
    /// Tile map node.
    var tilemap: SKTilemap! { get set }
}


/**
 Custom parent node for all Tiled assets. If the tilemap has the `cropAtBoundary` flag enabled, the world
 will crop the contents at the map edge.
 */
open class SKWorld: SKCropNode {
    override open func addChild(_ node: SKNode) {
        if let tilemap = node as? SKTilemap {
            let mapSize = CGSize(width: tilemap.sizeInPoints.width * tilemap.xScale, height: tilemap.sizeInPoints.height * tilemap.yScale)
            maskNode = (tilemap.cropAtBoundary == true) ? SKSpriteNode(color: SKColor.black, size: mapSize) : nil
        }
        super.addChild(node)
    }
}


/**
 Custom scene type for managing `SKTilemap` nodes.
 
 - parameter worldNode:  `SKNode!` world container node.
 - parameter cameraNode: `SKTiledSceneCamera!` scene camera node.
 - parameter tilemap:    `SKTilemap!` tile map node.
 */
open class SKTiledScene: SKScene, SKPhysicsContactDelegate, SKTiledSceneDelegate {
    
    /// World container node.
    open var worldNode: SKWorld!
    /// Custom scene camera.
    open var cameraNode: SKTiledSceneCamera!
    /// Tile map node.
    open var tilemap: SKTilemap!
    /// Current TMX file name.
    open var tmxFilename: String!
    
    // MARK: - Init
    /**
     Initialize without a tiled map.
     
     - parameter size:  `CGSize` scene size.
     - returns:         `SKTiledScene` scene.
     */
    override public init(size: CGSize) {
        super.init(size: size)
        setupWorld()
    }
    
    /**
     Initialize with a tiled file name.
     
     - parameter size:    `CGSize` scene size.
     - parameter tmxFile: `String` tiled file name.
     */
    public init(size: CGSize, tmxFile: String) {
        super.init(size: size)
        tmxFilename = tmxFile
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
    }
    
    deinit {
        removeAllActions()
        removeAllChildren()
    }
    
    override open func sceneDidLoad() {
        setupWorld()
    }    

    override open func didMove(to view: SKView) {
        guard let worldNode = worldNode else { return }
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        // setup the camera
        setupCamera()
        
        // load the current tmx file name
        guard let tmxFilename = tmxFilename else { return }
        
        if let tilemap = load(fromFile: tmxFilename) {
            // add the tilemap to the world container node.
            worldNode.addChild(tilemap)
            self.tilemap = tilemap
            
            // apply gravity from the tile map
            physicsWorld.gravity = self.tilemap.gravity
            
            // cmera properties inherited from tilemap
            cameraNode.allowMovement = self.tilemap.allowMovement
            cameraNode.allowZoom = self.tilemap.allowZoom
            
            // initial zoom level
            if (self.tilemap.autoResize == true) {
                cameraNode.fitToView()
            } else {
                cameraNode.setCameraZoom(self.tilemap.worldScale)
            }
        }
    }
    
    
    // MARK: - Setup
    
    /**
     Setup the world container node.
     */
    open func setupWorld(){
        if (worldNode != nil){
            worldNode.removeFromParent()
        }
        // set up world node
        worldNode = SKWorld()
        addChild(worldNode)
    }
    
    /**
     Setup the scene camera, referencing the world container node.
     */
    open func setupCamera(){
        guard let view = self.view else { return }
        cameraNode = SKTiledSceneCamera(view: view, world: worldNode)
        addChild(cameraNode)
        camera = cameraNode
    }
    
    /**
     Load a named TMX file.
     
     - parameter fileNamed: `String` TMX file name.
     - returns: `SKTilemap?` tile map node.
     */
    open func load(fromFile filename: String) -> SKTilemap? {
        if let tilemapNode = SKTilemap.load(fromFile: filename) {
            if (tilemapNode.backgroundColor != nil) {
                self.backgroundColor = tilemapNode.backgroundColor!
            }
            return tilemapNode
        }
        return nil
    }
}
