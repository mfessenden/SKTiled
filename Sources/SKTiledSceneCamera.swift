//
//  SKTiledSceneCamera.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
#if os(iOS)
import UIKit
#else
import Cocoa
#endif


/**
  Custom scene camera that responds to finger/mouse gestures.
 
 The `SKTiledSceneCamera` is a custom camera meant to be used with a `SKTiledSceneDelegate` scene. The camera defines a position in the scene to render the scene from, with a reference to the `SKTiledSceneDelegate.worldNode` to interact with tile maps. 
 
 The `SKTiledSceneCamera` implements custom `UIGestureRecognizer` (iOS) and `NSEvent` mouse events (macOS) to aid in navigating your scenes.
 */
@available(OSX 10.11, *)
open class SKTiledSceneCamera: SKCameraNode {
    
    unowned let world: SKNode
    fileprivate var bounds: CGRect
    open var zoom: CGFloat = 1.0
    open var initialZoom: CGFloat = 1.0
    
    // movement constraints
    open var allowMovement: Bool = true
    open var allowZoom: Bool = true
    open var allowRotation: Bool = false
    open var allowPause: Bool = true
    
    // zoom constraints
    private var minZoom: CGFloat = 0.2
    private var maxZoom: CGFloat = 5.0
    public var isAtMaxZoom: Bool { return zoom == maxZoom }
    
    // gestures
    #if os(iOS)
    /// Gesture recognizer to recognize camera panning
    open var cameraPanned: UIPanGestureRecognizer!
    /// Gesture recognizer to recognize double taps
    open var sceneDoubleTapped: UITapGestureRecognizer!
    /// Gesture recognizer to recognize pinch actions
    open var cameraPinched: UIPinchGestureRecognizer!
    #endif
    
    // locations
    fileprivate var focusLocation: CGPoint = CGPoint.zero
    fileprivate var lastLocation: CGPoint!
    
    // quick & dirty overlay node
    internal let overlay: SKNode = SKNode()
    open var showOverlay: Bool = true {
        didSet {
            guard oldValue != showOverlay else { return }
            overlay.isHidden = !showOverlay
        }
    }
    
    // MARK: - Init
    public init(view: SKView, world node: SKNode) {
        world = node
        bounds = view.bounds
        super.init()
        
        // add the overlay
        addChild(overlay)
        
        #if os(iOS)
        // setup pan recognizer
        cameraPanned = UIPanGestureRecognizer(target: self, action: #selector(cameraPanned(_:)))
        cameraPanned.minimumNumberOfTouches = 1
        cameraPanned.maximumNumberOfTouches = 1
        view.addGestureRecognizer(cameraPanned)
            
            
        sceneDoubleTapped = UITapGestureRecognizer(target: self, action: #selector(sceneDoubleTapped(_:)))
        sceneDoubleTapped.numberOfTapsRequired = 2
        view.addGestureRecognizer(sceneDoubleTapped)
            
        // setup pinch recognizer
        cameraPinched = UIPinchGestureRecognizer(target: self, action: #selector(scenePinched(_:)))
        view.addGestureRecognizer(cameraPinched)
        #endif
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Zooming
    
    /**
     Apply zooming to the world node (as scale).
     
     - parameter scale: `CGFloat` zoom amount.
     */
    open func setCameraZoom(_ scale: CGFloat) {
        // clamp scaling
        var realScale = scale <= minZoom ? minZoom : scale
        realScale = realScale >= maxZoom ? maxZoom : realScale
        self.zoom = realScale
        world.setScale(realScale)
        
        if let tilemap = (scene as? SKTiledScene)?.tilemap {
            tilemap.autoResize = false
        }
    }
    
    /**
     Apply zooming to the camera based on location.
     
     - parameter scale:    `CGFloat` zoom amount.
     - parameter location: `CGPoint` zoom location.
     */
    open func setCameraZoomAtLocation(scale: CGFloat, location: CGPoint) {
        setCameraZoom(scale)
        moveCamera(location: location, previous: position)
    }
    
    /**
     Set the camera min/max zoom values.
     
     - parameter minimum:    `CGFloat` minimum zoom vector.
     - parameter maximum:    `CGFloat` maximum zoom vector.
     */
    open func setZoomConstraints(minimum: CGFloat, maximum: CGFloat) {
        let minValue = minimum > 0 ? minimum : 0
        minZoom = minValue
        maxZoom = maximum
    }
    
    // MARK: - Movement
    
    /**
     Move the camera to the given location.
     
     - parameter location:  `CGPoint` new location.
     - parameter previous:  `CGPoint` old location.
     */
    open func moveCamera(location: CGPoint, previous: CGPoint) {
        let dy = position.y - (location.y - previous.y)
        let dx = position.x - (location.x - previous.x)
        position = CGPoint(x: dx, y: dy)
    }
    
    /**
     Move camera around manually.
     
     - parameter point:    `CGPoint` point to move to.
     - parameter duration: `TimeInterval` duration of move.
     */
    open func panToPoint(_ point: CGPoint, duration: TimeInterval=0.3) {
        run(SKAction.move(to: point, duration: duration))
    }
    
    /**
     Center the camera on a location in the scene.
     
     - parameter scenePoint: `CGPoint` point in scene.
     - parameter easeInOut:  `TimeInterval` ease in/out speed.
     */
    open func centerOn(scenePoint point: CGPoint, duration: TimeInterval=0) {
        if duration == 0 {
            position = point
        } else {
            let moveAction = SKAction.move(to: point, duration: duration)
            moveAction.timingMode = .easeOut
            run(moveAction)
        }
    }
    
    /**
     Center the camera on a node in the scene.
     
     - parameter scenePoint: `SKNode` node in scene.
     - parameter easeInOut:  `TimeInterval` ease in/out speed.
     */
    open func centerOn(_ node: SKNode, duration: TimeInterval = 0) {
        guard let scene = self.scene else { return }
        
        let nodePosition = scene.convert(node.position, from: node)
        if duration == 0 {
            position = nodePosition
        } else {
            let moveAction = SKAction.move(to: nodePosition, duration: duration)
            moveAction.timingMode = .easeOut
            run(moveAction)
        }
    }
    
    /**
     Reset the camera position & zoom level.
     */
    open func resetCamera() {
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setCameraZoom(initialZoom)
    }
    
    /**
     Reset the camera position & zoom level.
     
     - parameter toScale: `CGFloat` camera scale.
     */
    open func resetCamera(toScale scale: CGFloat) {
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setCameraZoom(scale)
    }
    
    /**
     Center & fit the current tilemap in the frame. 
     Also sets the `SKTilemap.autoResize` parameter.
     */
    open func fitToView() {
        guard let scene = self.scene as? SKTiledScene else { return }
        guard let view = scene.view else { return }
        guard let tilemap = scene.tilemap else { return }
                
        let screenScaleWidth: CGFloat = 0.75
        let viewSize = view.bounds.size
        
        // get the usable height/width
        let useableWidth: CGFloat = viewSize.width * screenScaleWidth
        let currentWidth = tilemap.sizeInPoints.width
        
        let scaleFactor = (useableWidth / currentWidth)
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setCameraZoom(scaleFactor)
        
        // flag the map as auto-resized
        tilemap.autoResize = true
    }
}


#if os(iOS)
extension SKTiledSceneCamera {
    // MARK: - Gesture Handlers    
    
    /**
     Update the scene camera when a pan gesture is recogized.
     
     - parameter recognizer: `UIPanGestureRecognizer` pan gesture recognizer.
    */
    open func cameraPanned(_ recognizer: UIPanGestureRecognizer) {
        guard (self.scene != nil) else { return }
        if (recognizer.state == .began) {
            let location = recognizer.location(in: recognizer.view)
            lastLocation = location
        }
        
        if (recognizer.state == .changed) && (allowMovement == true) {
            if lastLocation == nil { return }
            let location = recognizer.location(in: recognizer.view)
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            centerOn(scenePoint: CGPoint(x: Int(position.x - difference.x), y: Int(position.y - -difference.y)))
            lastLocation = location
        }
    }
    
    /**
     Handler for double taps.
     
     - parameter recognizer: `UITapGestureRecognizer` tap gesture recognizer.
     */
    open func sceneDoubleTapped(_ recognizer: UITapGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.ended && allowPause) {
            //focusLocation = recognizer.location(in: recognizer.view)
            guard let scene = self.scene as? SKTiledScene else { return }
            // get the current point
            lastLocation = scene.convertPoint(fromView: recognizer.location(in: recognizer.view))
            scene.tilemap.isPaused = !scene.tilemap.isPaused
        }
    }
    
    /**
     Update the camera scale in the scene.
     
     - parameter recognizer: `UIPinchGestureRecognizer`
     */
    open func scenePinched(_ recognizer: UIPinchGestureRecognizer) {
        guard let scene = self.scene else { return }
        
        if recognizer.state == .began {
            let location = recognizer.location(in: recognizer.view)
            focusLocation = scene.convertPoint(fromView: location)  // correct
            centerOn(scenePoint: focusLocation)
        }
        
        if recognizer.state == .changed {
            zoom *= recognizer.scale            
            // set the world scaling here
            //setCameraZoom(zoom)
            setCameraZoomAtLocation(scale: zoom, location: focusLocation)
            recognizer.scale = 1
            //centerOn(scenePoint: focusLocation)
        }
    }
}
#endif


#if os(OSX)
extension SKTiledSceneCamera {
    // MARK: - Mouse Events
    
    /**
     Handler for double clicks.
     
     - parameter recognizer: `UITapGestureRecognizer` tap gesture recognizer.
     */
    open func sceneDoubleClicked(_ event: NSEvent) {
        guard let scene = self.scene as? SKTiledScene else { return }
        let _ = event.location(in: scene)
    }
    
    override open func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        lastLocation = location
    }
    
    override open func mouseUp(with event: NSEvent) {
        let location = event.location(in: self)
        lastLocation = location
        focusLocation = location
    }
    
    override open func scrollWheel(with event: NSEvent) {
        let location = event.location(in: self)
        focusLocation = location
        centerOn(scenePoint: focusLocation)
        
        zoom += (event.deltaY * 0.05) // max 0.25
        // set the world scaling here
        setCameraZoom(zoom)
    }
    
    open func scenePositionChanged(_ event: NSEvent) {
        guard let _ = self.scene as? SKTiledScene else { return }
        let location = event.location(in: self)
        if lastLocation == nil { lastLocation = location }
        if allowMovement == true {
            if lastLocation == nil { return }
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            centerOn(scenePoint: CGPoint(x: Int(position.x - difference.x), y: Int(position.y - difference.y)))
            lastLocation = location
        }
    }
}
#endif

