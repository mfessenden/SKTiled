//
//  SKTiledSceneCamera.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif

/**
 Delegate for managing `SKTiledSceneCamera`. Delegates are alerted when camera position & zoom are changed.
 */
public protocol TiledSceneCameraDelegate: class {
    func cameraPositionChanged(newPosition: CGPoint)
    func cameraZoomChanged(newZoom: CGFloat)
    func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat)
    #if os(iOS) || os(tvOS)
    func sceneDoubleTapped()
    func sceneSwiped()
    #endif
}


/**
  Custom scene camera that responds to finger/mouse gestures.
 
 The `SKTiledSceneCamera` is a custom camera meant to be used with a scene conforming to the `SKTiledSceneDelegate` protocol. The camera defines a position in the scene to render the scene from, with a reference to the `SKTiledSceneDelegate.worldNode` to interact with tile maps. 
 
 The `SKTiledSceneCamera` implements custom `UIGestureRecognizer` (iOS) and `NSEvent` mouse events (macOS) to aid in navigating your scenes.
 */
@available(OSX 10.11, *)
open class SKTiledSceneCamera: SKCameraNode {
    
    unowned let world: SKNode
    internal var bounds: CGRect
    internal var delegates: [TiledSceneCameraDelegate] = []
    
    open var zoom: CGFloat = 1.0
    open var initialZoom: CGFloat = 1.0
    
    // movement constraints
    open var allowMovement: Bool = true
    open var allowZoom: Bool = true
    open var allowRotation: Bool = false
    open var allowPause: Bool = true
    
    // zoom constraints
    open var minZoom: CGFloat = 0.2
    open var maxZoom: CGFloat = 5.0
    open var isAtMaxZoom: Bool { return zoom == maxZoom }
    
    // gestures
    #if os(iOS) || os(tvOS)
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
    /**
     Initialize the camera with SKView and world node reference.
     
     - parameter view:     `SKView?` optional view.
     - parameter world:    `SKNode` world container node.
     */
    public init(view: SKView, world node: SKNode) {
        world = node
        bounds = view.bounds
        super.init()
        
        // add the overlay
        addChild(overlay)
        overlay.isHidden = true
        
        #if os(iOS) || os(tvOS)
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
    
    // MARK: - Delegates
    
    /**
     Add a camera delegate.
     
     - parameter delegate:  `TiledSceneCameraDelegate` camera delegate.
     */
    public func addDelegate(_ delegate: TiledSceneCameraDelegate) {
        if let _ = delegates.index(where: { $0 === delegate}) {
            return
        }
        delegates.append(delegate)
    }
    
    /**
     Remove a camera delegate.
     
     - parameter delegate:  `TiledSceneCameraDelegate` camera delegate.
     */
    public func removeDelegate(_ delegate: TiledSceneCameraDelegate) {
        if let idx = delegates.index(where: { $0 === delegate}) {
            delegates.remove(at: idx)
        }
    }
    
    // MARK: - Overlay
    /**
     Add an overlay node.
     */
    public func addToOverlay(_ node: SKNode) {
        overlay.addChild(node)
        node.zPosition = zPosition + 10
    }
    
    // MARK: - Zooming
    
    /**
     Apply zooming to the world node (as scale).
     
     - parameter scale: `CGFloat` zoom amount.
     */
    open func setCameraZoom(_ scale: CGFloat, interval: TimeInterval=0) {
        // clamp scaling
        let zoomClamped = scale.clamped(minZoom, maxZoom)
        
        self.zoom = zoomClamped
        let zoomAction = SKAction.scale(to: zoomClamped, duration: interval)
        //world.setScale(zoomClamped)
        world.run(zoomAction)
        
        if let tilemap = (scene as? SKTiledScene)?.tilemap {
            tilemap.autoResize = false
        }
        
        // notify delegates
        for delegate in delegates {
            delegate.cameraZoomChanged(newZoom: zoomClamped)
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
        
        // notify delegates
        for delegate in delegates {
            delegate.cameraPositionChanged(newPosition: position)
        }
    }
    
    /**
     Move camera manually.
     
     - parameter point:    `CGPoint` point to move to.
     - parameter duration: `TimeInterval` duration of move.
     */
    open func panToPoint(_ point: CGPoint, duration: TimeInterval=0.3) {
        run(SKAction.move(to: point, duration: duration), completion: {
            // notify delegates
            for delegate in self.delegates {
                delegate.cameraPositionChanged(newPosition: point)
            }
        })
    }
    
    /**
     Center the camera on a location in the scene.
     
     - parameter scenePoint: `CGPoint` point in scene.
     - parameter easeInOut:  `TimeInterval` ease in/out speed.
     */
    open func centerOn(scenePoint point: CGPoint, duration: TimeInterval=0) {
        defer {
            // notify delegates
            for delegate in self.delegates {
                delegate.cameraPositionChanged(newPosition: point)
            }
        }
        
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
        defer {
            // notify delegates
            for delegate in self.delegates {
                delegate.cameraPositionChanged(newPosition: nodePosition)
            }
        }
        // run the action
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
     Center & fit the current tilemap in the frame when the parent scene is resized.
     
     - parameter newSize: `CGSize` updated scene size.
     */
    open func fitToView(newSize: CGSize, transition: TimeInterval=0) {
        
        guard let scene = scene,
            let tiledScene = scene as? SKTiledSceneDelegate,
            let tilemap = tiledScene.tilemap else { return }
        
        
        

        let tilemapSize = tilemap.sizeInPoints
        let tilemapCenter = scene.convert(tilemap.position, from: tilemap)
        
        let isPortrait: Bool = newSize.height > newSize.width
        
        let screenScaleWidth: CGFloat = isPortrait ? 0.7 : 0.7
        let screenScaleHeight: CGFloat = isPortrait ? 0.7 : 0.7   // was 0.8 & 0.7
        
        // get the usable height/width
        let usableWidth: CGFloat = newSize.width * screenScaleWidth
        let usableHeight: CGFloat = newSize.height * screenScaleHeight
        let scaleFactor = (tilemap.isPortrait == true) ? usableHeight / tilemapSize.height : usableWidth / tilemapSize.width
        
        
        
        centerOn(scenePoint: tilemapCenter) //CGPoint(x: 0, y: 0))
        setCameraZoom(scaleFactor, interval: transition)
        //tilemap.autoResize = !tilemap.autoResize
        let absoluteSize = tilemapSize * scaleFactor
        print("[SKTiledSceneCamera]: fitting: \(newSize.shortDescription), \(absoluteSize.shortDescription), scale: \(scaleFactor.roundTo())")
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": self.description])
    }
    
    // MARK: - Geometry
    /**
     Returns the points of the camera's bounding shape.
     
     - returns: `[CGPoint]` array of points.
     */
    open func getVertices() -> [CGPoint] {
        return self.bounds.points
    }
}


extension SKTiledSceneCamera {
    override open var description: String {
        return "Camera: \(bounds.roundTo()), zoom: \(zoom.roundTo())"
    }
    
    override open var debugDescription: String {
        return "Camera: \(bounds.roundTo()), zoom: \(zoom.roundTo())"
    }
}




#if os(iOS) || os(tvOS)
extension SKTiledSceneCamera {
    // MARK: - Gesture Handlers    
    
    /**
     Update the scene camera when a pan gesture is recogized.
     
     - parameter recognizer: `UIPanGestureRecognizer` pan gesture recognizer.
    */
    open func cameraPanned(_ recognizer: UIPanGestureRecognizer) {
        guard (self.scene != nil),
                (allowMovement == true) else { return }
        
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
        if (recognizer.state == UIGestureRecognizerState.ended) {
            for delegate in self.delegates {
                delegate.sceneDoubleTapped()
            }
        }
    }
    
    /**
     Update the camera scale in the scene.
     
     - parameter recognizer: `UIPinchGestureRecognizer`
     */
    open func scenePinched(_ recognizer: UIPinchGestureRecognizer) {
        guard let scene = self.scene,
                (allowZoom == true) else { return }
        
        if recognizer.state == .began {
            let location = recognizer.location(in: recognizer.view)
            focusLocation = scene.convertPoint(fromView: location)  // correct
            centerOn(scenePoint: focusLocation)
        }
        
        if recognizer.state == .changed {
            zoom *= recognizer.scale            
            
            // set the world scaling here
            setCameraZoomAtLocation(scale: zoom, location: focusLocation)
            recognizer.scale = 1
        }
    }
}
#endif


#if os(OSX)
// need to make sure that lastLocation is a location in *this* node
extension SKTiledSceneCamera {
    // MARK: - Mouse Events
    
    /**
     Handler for double clicks.
     
     - parameter recognizer: `UITapGestureRecognizer` tap gesture recognizer.
     */
    open func sceneDoubleClicked(_ event: NSEvent) {
        guard let _ = self.scene as? SKTiledScene else { return }
        let _ = event.location(in: self)
    }
    
    override open func mouseDown(with event: NSEvent) {
        guard let _ = self.scene as? SKTiledScene else { return }
        let location = event.location(in: self)
        lastLocation = location
    }
    
    /**
     Track mouse movement in the scene. Location is in local space, so coordinate origin will be the center of the current window.
     */
    override open func mouseMoved(with event: NSEvent) {
        let _ = event.location(in: self)
    }
    
    override open func mouseEntered(with event: NSEvent) {
        let _ = event.location(in: self)
    }
    
    override open func mouseUp(with event: NSEvent) {
        guard let _ = self.scene as? SKTiledScene else { return }
        let location = event.location(in: self)
        lastLocation = location
        focusLocation = location
    }
    
    /**
     Manage mouse wheel zooming.
     */
    override open func scrollWheel(with event: NSEvent) {
        guard let scene = self.scene as? SKTiledScene else { return }
        
        var anchorPoint = event.locationInWindow
        anchorPoint = scene.convertPoint(fromView: anchorPoint)
         
        let anchorPointInCamera = convert(anchorPoint, from: scene)
        zoom += (event.deltaY * 0.05)
        setCameraZoom(zoom)

        let anchorPointInScene = scene.convert(anchorPointInCamera, from: self)
        let translationOfAnchorInScene = (x: anchorPoint.x - anchorPointInScene.x, y: anchorPoint.y - anchorPointInScene.y)
        position = CGPoint(x: position.x - translationOfAnchorInScene.x, y: position.y - translationOfAnchorInScene.y)
        
        // TODO: debug these
        focusLocation = position
        lastLocation = position
        //setCameraZoomAtLocation(scale: zoom, location: position)
    }
    
    open func scenePositionChanged(_ event: NSEvent) {
        guard let _ = self.scene as? SKTiledScene else { return }
        let location = event.location(in: self)
        
        if lastLocation == nil { lastLocation = location }
        if allowMovement == true {
            if lastLocation == nil { return }
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            position = CGPoint(x: Int(position.x - difference.x), y: Int(position.y - difference.y))
            lastLocation = location
            
            for delegate in delegates {
                delegate.cameraPositionChanged(newPosition: position)
            }
        }
    }
}
#endif

/// Default methods.
extension TiledSceneCameraDelegate {
    public func cameraPositionChanged(newPosition: CGPoint) {}
    public func cameraZoomChanged(newZoom: CGFloat) {}
    public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {}
    #if os(iOS) || os(tvOS)
    public func sceneDoubleTapped() {}
    public func sceneSwiped() {}
    #endif
}
