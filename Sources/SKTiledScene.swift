//
//  SKTiledScene.swift
//  SKTiled
//
//  Created by Michael Fessenden.
//
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SpriteKit
import GameplayKit


/**
 
 ## Overview
 
 Custom scene type for managing `SKTilemap` nodes.
 
 Conforms to the `SKTiledSceneDelegate`, `SKTilemapDelegate` & `SKTilesetDataSource` protocols.
 
 [SKTiledScene Hierarchy][sktiledscene-hierarchy-img-url]
 
 ### Properties 
 
 | Property   | Description          |
 |:-----------|:---------------------|
 | worldNode  | Root container node. |
 | tilemap    | Tile map object.     |
 | cameraNode | Custom scene camera. |
 
 
 ### Instance Methods ###
 
 | Method                 | Description                                                  |
 |:-----------------------|:-------------------------------------------------------------|
 | sceneDoubleTapped      | Called when the scene receives a double-tap event (iOS only).|
 | cameraPositionChanged  | Called when the camera positon changes.                      |
 | cameraZoomChanged      | Called when the camera zoom changes.                         |
 | cameraBoundsChanged    | Called when the camera bounds updated.                       |
 | sceneDoubleClicked     | Called when the scene is double-clicked (macOS only).        |
 | mousePositionChanged   | Called when the mouse moves in the scene (macOS only).       |
 
 [sktiledscene-hierarchy-img-url]:https://mfessenden.github.io/SKTiled/images/scene_hierarchy.png
 */
open class SKTiledScene: SKScene, SKPhysicsContactDelegate, SKTiledSceneDelegate, SKTilemapDelegate, SKTilesetDataSource {
    
    /// World container node.
    open var worldNode: SKNode!
    
    /// Tile map node.
    open var tilemap: SKTilemap!
    
    /// Custom scene camera.
    open var cameraNode: SKTiledSceneCamera!
    
    /// Logging verbosity level.
    open var loggingLevel: LoggingLevel = .info
    
    /// Reference to navigation graphs.
    open var graphs: [String : GKGridGraph<GKGridGraphNode>] = [:]
    
    /// Last update interval.
    private var lastUpdateTime: TimeInterval = 0
    
    /// Maximum update interval.
    private let maximumUpdateDelta: TimeInterval = 1.0 / 60.0
    
    /// Receive notifications from camera.
    open var receiveCameraUpdates: Bool = true
    
    /// Set the tilemap speed.
    override open var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            if let tilemap = tilemap {
                tilemap.speed = speed
            }
        }
    }
    
    // MARK: - Init
    
    /**
     Initialize without a tiled map.
     
     - parameter size:  `CGSize` scene size.
     - returns:         `SKTiledScene` scene.
     */
    required override public init(size: CGSize) {
        super.init(size: size)
    }
    
    /// Default initializer.
    ///
    /// - Parameter aDecoder: decoder instance.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    /// Called when the parent view size changes.
    ///
    /// - Parameter oldSize: previous size.
    override open func didChangeSize(_ oldSize: CGSize) {
        updateCamera()
    }
    
    /// Called when the parent view is displayed.
    ///
    /// - Parameter view: parent view.
    override open func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        // setup world node
        worldNode = SKNode()
        worldNode.name = "World"
        addChild(worldNode)
        
        // setup the camera
        cameraNode = SKTiledSceneCamera(view: view, world: worldNode)
        // scene should notified of camera changes
        cameraNode.addDelegate(self)
        addChild(cameraNode)
        camera = cameraNode
    }
    
    // MARK: - Setup
    /**
     Load and setup a named TMX file, with optional tilesets.
     
     - parameter url:              `URL` Tiled file url.
     - parameter withTilesets:     `[SKTileset]` pre-loaded tilesets.
     - parameter ignoreProperties: `Bool` don't parse custom properties.
     - parameter loggingLevel:     `LoggingLevel` logging verbosity.
     - parameter completion:       `((_ SKTilemap) -> Void)?` optional completion handler.
     */
    open func setup(url: URL,
                    withTilesets: [SKTileset] = [],
                    ignoreProperties: Bool = false,
                    loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                    _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) {
        
        let dirname = url.deletingLastPathComponent()
        let filename = url.lastPathComponent
        let relativeURL = URL(fileURLWithPath: filename, relativeTo: dirname)
        
        self.setup(tmxFile: relativeURL.relativePath,
                   inDirectory: (relativeURL.baseURL == nil) ? nil : relativeURL.baseURL!.path,
                   withTilesets: withTilesets,
                   ignoreProperties: ignoreProperties,
                   loggingLevel: loggingLevel,
                   completion)
    }
    
    
    /**
     Load and setup a named TMX file, with optional tilesets. Allows for an optional completion handler.
     
     - parameter tmxFile:          `String` TMX file name.
     - parameter inDirectory:      `String?` search path for assets.
     - parameter withTilesets:     `[SKTileset]` optional pre-loaded tilesets.
     - parameter ignoreProperties: `Bool` don't parse custom properties.
     - parameter loggingLevel:     `LoggingLevel` logging verbosity.
     - parameter completion:       `((_ SKTilemap) -> Void)?` optional completion handler.
     */
    open func setup(tmxFile: String,
                    inDirectory: String? = nil,
                    withTilesets tilesets: [SKTileset] = [],
                    ignoreProperties: Bool = false,
                    loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                    _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) {
        
        guard let worldNode = worldNode else {
            self.log("cannot access world node.", level: .error)
            return
        }
        
        self.loggingLevel = loggingLevel
        self.tilemap = nil
        
        if let tilemap = load(tmxFile: tmxFile,
                              inDirectory: inDirectory,
                              withTilesets: tilesets,
                              ignoreProperties: ignoreProperties,
                              loggingLevel: loggingLevel) {
            
            backgroundColor = tilemap.backgroundColor ?? SKColor.clear
            
            // add the tilemap to the world container node.
            worldNode.addChild(tilemap, fadeIn: 0.2)
            self.tilemap = tilemap
            
            // tilemap will be notified of camera changes
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
            completion?(tilemap)
        }
    }
    
    // MARK: - Tilemap Delegate
    
    open func didBeginParsing(_ tilemap: SKTilemap) {
        // Called when tilemap is instantiated.
    }
    
    open func didAddTileset(_ tileset: SKTileset) {
        // Called when a tileset has been added.
    }
    
    open func didAddLayer(_ layer: SKTiledLayerObject) {
        // Called when a layer has been added.
    }
    
    open func didReadMap(_ tilemap: SKTilemap) {
        // Called before layers are rendered.
    }
    
    open func didRenderMap(_ tilemap: SKTilemap) {
        // Called after layers are rendered. Perform any post-processing here.
    }
    
    open func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>) {
        // Called when a graph is added to the scene.
    }
    
    open func objectForTileType(named: String?) -> SKTile.Type {
        return SKTile.self
    }
    
    open func objectForVectorType(named: String?) -> SKTileObject.Type {
        return SKTileObject.self
    }
    
    // MARK: - Tileset Delegate
    
    open func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String {
        // Called when a tileset is about to add a spritesheet image.
        return fileNamed
    }
    
    
    open func willAddImage(to tileset: SKTileset, forId: Int, fileNamed: String) -> String {
        // Called when a tileset is about to add an image to a collection.
        return fileNamed
    }
    
    // MARK: - Updating
    
    /**
     Called before each frame is rendered.
     
     - parameter currentTime: `TimeInterval` update interval.
     */
    override open func update(_ currentTime: TimeInterval) {
        // Initialize lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        var dt = currentTime - self.lastUpdateTime
        dt = dt > maximumUpdateDelta ? maximumUpdateDelta : dt
        
        self.lastUpdateTime = currentTime
        
        // update tilemap
        self.tilemap?.update(currentTime)
    }
    
    /**
     Update the camera bounds.
     */
    open func updateCamera() {
        guard (view != nil) else { return }
        
        // update camera bounds
        if let cameraNode = cameraNode {
            cameraNode.setCameraBounds(bounds: CGRect(x: -(size.width / 2), y: -(size.height / 2), width: size.width, height: size.height))
        }
    }
}


// setup methods
extension SKTiledSceneDelegate where Self: SKScene {
    
    /**
     Load a named TMX file, with optional tilesets.
     
     - parameter inDirectory:      `String?` search path for assets.
     - parameter withTilesets:     `[SKTileset]` optional pre-loaded tilesets.
     - parameter ignoreProperties: `Bool` don't parse custom properties.
     - parameter verbosity:        `LoggingLevel` logging verbosity.
     - returns: `SKTilemap?` tile map node.
     */
    public func load(tmxFile: String,
                     inDirectory: String? = nil,
                     withTilesets tilesets: [SKTileset] = [],
                     ignoreProperties: Bool = false,
                     loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel) -> SKTilemap? {
        
        
        if let tilemap = SKTilemap.load(tmxFile: tmxFile,
                                        inDirectory: inDirectory,
                                        delegate: self as? SKTilemapDelegate,
                                        tilesetDataSource: self as? SKTilesetDataSource,
                                        withTilesets: tilesets,
                                        ignoreProperties: ignoreProperties,
                                        loggingLevel: loggingLevel) {
            
            if let cameraNode = cameraNode {
                // camera properties inherited from tilemap
                cameraNode.allowMovement = tilemap.allowMovement
                cameraNode.allowZoom = tilemap.allowZoom
                cameraNode.setCameraZoom(tilemap.worldScale)
                cameraNode.maxZoom = tilemap.zoomConstraints.max
            }
            
            return tilemap
        }
        return nil
    }
}


#if os(macOS)
extension SKTiledScene {
    
    /// Mouse click event handler.
    ///
    /// - Parameter event: mouse event.
    override open func mouseDown(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseDown(with: event)
    }
    
    /// Mouse move event handler.
    ///
    /// - Parameter event: mouse event.
    override open func mouseMoved(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.mouseMoved(with: event)
    }
    
    override open func mouseUp(with event: NSEvent) {}
    override open func mouseEntered(with event: NSEvent) {}
    override open func mouseExited(with event: NSEvent) {}
    
    /// Mouse scroll wheel event handler.
    ///
    /// - Parameter event: mouse event.
    override open func scrollWheel(with event: NSEvent) {
        guard let cameraNode = cameraNode else { return }
        cameraNode.scrollWheel(with: event)
    }
}
#endif


// default methods
extension SKTiledScene: SKTiledSceneCameraDelegate {
    
    #if os(iOS)
    /**
     Called when the scene receives a double-tap event (iOS only).
     
     - parameter location: `CGPoint` touch event location.
     */
    public func sceneDoubleTapped(location: CGPoint) {}
    #endif
    
    // MARK: - Delegate Methods
    /**
     Called when the camera positon changes.
     
     - parameter newPositon: `CGPoint` updated camera position.
     */
    @objc public func cameraPositionChanged(newPosition: CGPoint) {}
    
    /**
     Called when the camera zoom changes.
     
     - parameter newZoom: `CGFloat` camera zoom amount.
     */
    @objc public func cameraZoomChanged(newZoom: CGFloat) {}
    
    /**
     Called when the camera bounds updated.
     
     - parameter bounds:  `CGRect` camera view bounds.
     - parameter positon: `CGPoint` camera position.
     - parameter zoom:    `CGFloat` camera zoom amount.
     */
    @objc public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {}
    
    #if os(macOS)
    /**
     Called when the scene is double-clicked (macOS only).
     
     - parameter event: `NSEvent` mouse click event.
     */
    @objc public func sceneDoubleClicked(event: NSEvent) {}
    
    /**
     Called when the mouse moves in the scene (macOS only).
     
     - parameter event: `NSEvent` mouse click event.
     */
    @objc public func mousePositionChanged(event: NSEvent) {}
    #endif
}


extension SKTiledScene: Loggable {}
