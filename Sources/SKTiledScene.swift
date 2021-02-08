//
//  SKTiledScene.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
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


/// ## Overview
///
/// The `SKTiledScene` object represents a scene of content in SpriteKit, customized for including **Tiled** asset types. This scene type automatically creates  **camera** and **world container** nodes and sets up interactivity between them and an associated tile map node.
///
/// ![SKTiledScene Hierarchy](../images/scene-hierarchy.svg)
///
/// The **camera node** determines what part of the scene’s coordinate space is visible in the view.
///
/// ### Properties
///
/// | Property   | Description          |
/// |:-----------|:---------------------|
/// | worldNode  | Root container node. |
/// | tilemap    | Tile map node.       |
/// | cameraNode | Custom scene camera. |
///
///
/// ### Instance Methods
///
/// | Method                 | Description                                                  | Platform  |
/// |:-----------------------|:-------------------------------------------------------------|:---------:|
/// | cameraPositionChanged  | Called when the camera position changes.                     | (all)     |
/// | cameraZoomChanged      | Called when the camera zoom changes.                         | (all)     |
/// | cameraBoundsChanged    | Called when the camera bounds updated.                       | (all)     |
/// | sceneDoubleTapped      | Called when the scene receives a double-tap event (iOS only).| iOS       |
/// | sceneClicked           | Called when the scene is clicked (macOS only).               | macOS     |
/// | sceneDoubleClicked     | Called when the scene is double-clicked (macOS only).        | macOS     |
/// | mousePositionChanged   | Called when the mouse moves in the scene (macOS only).       | macOS     |
///
open class SKTiledScene: SKScene, SKPhysicsContactDelegate, TiledSceneDelegate, TilemapDelegate, TilesetDataSource {

    /// World container node.
    open var worldNode: SKNode!

    /// Tile map node.
    open weak var tilemap: SKTilemap?

    /// Custom scene camera.
    open weak var cameraNode: SKTiledSceneCamera?

    /// Logging verbosity level.
    open var loggingLevel: LoggingLevel = .info

    /// Reference to navigation graphs.
    open var graphs: [String : GKGridGraph<GKGridGraphNode>] = [:]

    /// Time scene was last updated.
    private var lastUpdateTime: TimeInterval = 0

    /// Maximuum update delta.
    private let maximumUpdateDelta: TimeInterval = 1.0 / 60.0

    /// Receive notifications from camera.
    @objc open var receiveCameraUpdates: Bool = true

    /// Indicates the mouse is within scene bounds.
    internal var hasMouseFocus: Bool = false

    /// Current focus coordinate.
    open var currentCoordinate = simd_int2(arrayLiteral: 0, 0)

    /// Z-position difference between layers.
    open var zDeltaForLayers: CGFloat = TiledGlobals.default.zDeltaForLayers

    /// Speed modifier applied to all actions executed by the scene and its descendants.
    open override var speed: CGFloat {
        didSet {
            guard oldValue != speed else { return }
            if let tilemap = tilemap {
                tilemap.speed = speed
            }
        }
    }

    // MARK: - Initialization

    /// Initialize without a tiled map name.
    ///
    /// - Parameter size: scene size
    required public override init(size: CGSize) {
        super.init(size: size)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        graphs = [:]
        camera?.removeFromParent()
        camera = nil
        tilemap = nil
    }

    open override func didChangeSize(_ oldSize: CGSize) {
        updateCamera()
    }

    open override func sceneDidLoad() {
        isUserInteractionEnabled = true
    }

    /// Called when the scene is displayed in the parent `SKView`.
    ///
    /// - Parameter view: parent view.
    open override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self

        // setup world node
        worldNode = SKWorld()
        addChild(worldNode)

        // CHECKME: this is different from 1.2
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        //worldNode.position = view.bounds.center

        // setup the camera
        let tiledCamera = SKTiledSceneCamera(view: view, world: worldNode)

        if let tiledWorld = worldNode as? SKWorld {
            tiledCamera.addDelegate(tiledWorld)
        }


        // scene should notified of camera changes
        tiledCamera.addDelegate(self)
        addChild(tiledCamera)
        camera = tiledCamera
        cameraNode = tiledCamera
    }

    // MARK: - Setup

    /// Load and setup a named TMX file, with optional tilesets.
    ///
    /// - Parameters:
    ///   - url: Tiled file url.
    ///   - withTilesets: pre-loaded tilesets.
    ///   - ignoreProperties: don't parse custom properties.
    ///   - loggingLevel: logging verbosity.
    ///   - completion: optional completion handler.
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

    /// Load and setup a named TMX file, with optional tilesets. Allows for an optional completion handler.
    ///
    /// - Parameters:
    ///   - tmxFile: TMX file name.
    ///   - inDirectory: search path for assets.
    ///   - tilesets: optional pre-loaded tilesets.
    ///   - ignoreProperties: don't parse custom properties.
    ///   - loggingLevel: logging verbosity.
    ///   - completion: optional completion handler.
    open func setup(tmxFile: String,
                    inDirectory: String? = nil,
                    withTilesets tilesets: [SKTileset] = [],
                    ignoreProperties: Bool = false,
                    loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                    _ completion: ((_ tilemap: SKTilemap) -> Void)? = nil) {

        guard let worldNode = worldNode else {
            self.log("error accessing world node, check that your scene has been presented in the current view.", level: .error)
            return
        }

        self.loggingLevel = loggingLevel
        self.tilemap = nil

        weak var weakSelf = self

        if let tilemap = load(tmxFile: tmxFile,
                              inDirectory: inDirectory,
                              withTilesets: tilesets,
                              ignoreProperties: ignoreProperties,
                              loggingLevel: loggingLevel) {


            backgroundColor = tilemap.backgroundColor ?? SKColor.clear

            // if let _ = weakSelf?.view {}

            // add the tilemap to the world container node.
            worldNode.addChild(tilemap, fadeIn: 0.2)
            weakSelf!.tilemap = tilemap

            // tilemap will be notified of camera changes
            cameraNode?.addDelegate(tilemap)
            cameraNode?.addDelegate(tilemap.objectsOverlay)

            if let tiledWorld = worldNode as? SKWorld {
                cameraNode?.addDelegate(tiledWorld)
            }

            // apply gravity from the tile map
            physicsWorld.gravity = tilemap.gravity

            // camera properties inherited from tilemap
            cameraNode?.allowMovement = tilemap.allowMovement
            cameraNode?.allowZoom = tilemap.allowZoom
            cameraNode?.allowRotation = tilemap.allowRotation

            // initial zoom level
            if (tilemap.autoResize == true) {
                if let view = view {
                    cameraNode?.fitToView(newSize: view.bounds.size)   /// was size
                }
            } else {
                cameraNode?.setCameraZoom(tilemap.worldScale)
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

    open func didAddLayer(_ layer: TiledLayerObject) {
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

    /// Called before each frame is rendered.
    ///
    /// - Parameter currentTime: update interval.
    open override func update(_ currentTime: TimeInterval) {
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

    /// Update the camera bounds.
    open func updateCamera() {
        guard (view != nil) else { return }

        // update camera bounds
        if let cameraNode = cameraNode {
            cameraNode.setCameraBounds(bounds: CGRect(x: -(size.width / 2), y: -(size.height / 2), width: size.width, height: size.height))
        }
    }
}



#if os(macOS)
extension SKTiledScene {

    /// Mouse click event handler.
    ///
    /// - Parameter event: mouse event.
    open override func mouseDown(with event: NSEvent) {
        cameraNode?.mouseDown(with: event)
    }

    /// Mouse right-click event handler.
    ///
    /// - Parameter event: mouse event.
    open override func rightMouseDown(with event: NSEvent) {
        cameraNode?.rightMouseDown(with: event)
    }

    /// Mouse click event handler.
    ///
    /// - Parameter event: mouse event.
    open override func mouseUp(with event: NSEvent) {
        cameraNode?.mouseUp(with: event)
    }

    /// Mouse right-click event handler.
    ///
    /// - Parameter event: mouse event.
    open override func rightMouseUp(with event: NSEvent) {
        cameraNode?.rightMouseUp(with: event)
    }

    /// Mouse move event handler.
    ///
    /// - Parameter event: mouse event.
    open override func mouseMoved(with event: NSEvent) {
        //guard (TiledGlobals.default.enableMouseEvents == true) else { return }
        cameraNode?.mouseMoved(with: event)
    }

    /// Mouse scroll wheel event handler.
    ///
    /// - Parameter event: mouse event.
    open override func scrollWheel(with event: NSEvent) {
        // guard (TiledGlobals.default.enableMouseEvents == true) else { return }
        cameraNode?.scrollWheel(with: event)
    }

    /// Mouse drag event handler.
    ///
    /// - Parameter event: mouse event.
    open override func mouseDragged(with event: NSEvent) {
        // guard (TiledGlobals.default.enableMouseEvents == true) else { return }
        cameraNode?.mouseDragged(with: event)
    }

    /// Mouse enter event handler.
    ///
    /// - Parameter event: mouse event.
    open override func mouseEntered(with event: NSEvent) {
        hasMouseFocus = true
        //tilemap?.mouseEntered(with: event)
    }

    /// Mouse exit event handler.
    ///
    /// - Parameter event: mouse event.
    open override func mouseExited(with event: NSEvent) {
        hasMouseFocus = false
        //tilemap?.mouseExited(with: event)
    }
}


#endif


// Delegate default methods.
extension SKTiledScene: TiledSceneCameraDelegate {

    #if os(iOS)

    /// Called when the scene receives a double-tap event (iOS only).
    ///
    /// - Parameter location: touch event location.
    open func sceneDoubleTapped(location: CGPoint) {}
    #endif

    // MARK: - Delegate Methods

    /// Called when the camera position changes.
    ///
    /// - Parameter newPosition: updated camera position.
    @objc open func cameraPositionChanged(newPosition: CGPoint) {}

    /// Called when the camera zoom changes.
    ///
    /// - Parameter newZoom: camera zoom amount.
    @objc open func cameraZoomChanged(newZoom: CGFloat) {}

    /// Called when the camera bounds updated.
    ///
    /// - Parameters:
    ///   - bounds: camera view bounds.
    ///   - position: camera position.
    ///   - zoom: camera zoom amount.
    @objc open func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {}

    #if os(macOS)

    /// Called when the scene is double-clicked (macOS only).
    ///
    /// - Parameter event: mouse click event.
    @objc open func sceneDoubleClicked(event: NSEvent) {}


    /// Called when the mouse moves in the scene (macOS only).
    ///
    /// - Parameter event: mouse move event.
    @objc open func mousePositionChanged(event: NSEvent) {}
    #endif
}





extension SKTiledScene {

    /// Returns a string representation of the node.
    open override var description: String {
        let objString = "<\(String(describing: type(of: self)))>"
        let nameString = name ?? "'(null)'"
        var mapString = ""
        if let curmap = tilemap {
            mapString = " map: '\(curmap.mapName)' "
        }
        return "\(objString) name: \(nameString)\(mapString) frame: \(frame), anchor: \(anchorPoint)"
    }

    open override var debugDescription: String {
        return description
    }
}
