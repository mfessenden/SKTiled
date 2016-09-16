//
//  SKTiledSceneCamera.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//  Adapted from http://www.avocarrot.com/blog/implement-gesture-recognizers-swift/


import SpriteKit
#if os(iOS)
import UIKit
#else
import Cocoa
#endif


/**
  Custom scene camera that responds to finger/mouse gestures.
 */
open class SKTiledSceneCamera: SKCameraNode {
    
    open let world: SKNode
    fileprivate var bounds: CGRect
    open var zoom: CGFloat = 1.0
    open var initialZoom: CGFloat = 1.0
    
    // movement constraints
    open var allowMovement: Bool = true
    open var allowZoom: Bool = true
    open var allowRotation: Bool = false
    
    // zoom constraints
    private var minZoom: CGFloat = 0.2
    private var maxZoom: CGFloat = 5.0
    
    public var isAtMaxZoom: Bool { return zoom == maxZoom }
    
    // gestures
    #if os(iOS)
    open var scenePanned: UIPanGestureRecognizer!              // gesture recognizer to recognize scene panning
    #endif
    
    // locations
    fileprivate var focusLocation = CGPoint.zero
    fileprivate var lastLocation: CGPoint!
    
    // MARK: - Init
    public init(view: SKView, world node: SKNode) {
        world = node
        bounds = view.bounds
        super.init()
        
        #if os(iOS)
        // setup pan recognizer
        scenePanned = UIPanGestureRecognizer(target: self, action: #selector(scenePanned(_:)))
        scenePanned.minimumNumberOfTouches = 1
        scenePanned.maximumNumberOfTouches = 1
        view.addGestureRecognizer(scenePanned)
        #endif
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Apply zooming to the world node (as scale).
     
     - parameter scale: `CGFloat` zoom amount.
     */
    open func setWorldScale(_ scale: CGFloat) {
        // clamp scaling
        var realScale = scale <= minZoom ? minZoom : scale
        realScale = realScale >= maxZoom ? maxZoom : realScale
        self.zoom = realScale
        world.setScale(realScale)
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
    
    /**
     Move camera around manually.
     
     - parameter point:    `CGPoint` point to move to.
     - parameter duration: `NSTimeInterval` duration of move.
     */
    open func panToPoint(_ point: CGPoint, duration: TimeInterval=0.3) {
        run(SKAction.move(to: point, duration: duration))
    }
    
    /**
     Center the camera on a location in the scene.
     
     - parameter scenePoint: `CGPoint` point in scene.
     - parameter easeInOut:  `NSTimeInterval` ease in/out speed.
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
     - parameter easeInOut:  `NSTimeInterval` ease in/out speed.
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
        setWorldScale(initialZoom)
    }
    
    open func resetCamera(toScale scale: CGFloat) {
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setWorldScale(scale)
    }
}


#if os(iOS)
public extension SKTiledSceneCamera {
    // MARK: - Gesture Handlers    
    
    /**
     Update the scene camera when a pan gesture is recogized.
     
     - parameter recognizer: `UIPanGestureRecognizer` pan gesture recognizer.
     */
    open func scenePanned(_ recognizer: UIPanGestureRecognizer) {
        guard let scene = self.scene else { return }
        if recognizer.state == .began {
            let location = recognizer.location(in: recognizer.view)
            lastLocation = location
        }
        
        if recognizer.state == .changed && allowMovement == true {
            if lastLocation == nil { return }
            let location = recognizer.location(in: recognizer.view)
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            centerOn(scenePoint: CGPoint(x: Int(position.x - difference.x), y: Int(position.y - -difference.y)))
            lastLocation = location
        }
    }
}
#endif

#if os(OSX)
public extension SKTiledSceneCamera {
    // MARK: - Mouse Events
    
    /**
     Handler for double clicks.
     
     - parameter recognizer: `UITapGestureRecognizer` tap gesture recognizer.
     */
    open func sceneDoubleClicked(_ event: NSEvent) {
        guard let scene = self.scene as? SKTiledScene else { return }
        let sceneLocation = event.location(in: scene)
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
        zoom += (event.deltaY * 0.25)
        // set the world scaling here
        setWorldScale(zoom)
        centerOn(scenePoint: CGPoint(x: focusLocation.x, y: focusLocation.y))
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

