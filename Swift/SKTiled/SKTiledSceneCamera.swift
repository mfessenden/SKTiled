//
//  SKTiledSceneCamera.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/22/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//  Adapted from http://www.avocarrot.com/blog/implement-gesture-recognizers-swift/

import SpriteKit
import UIKit


public class SKTiledSceneCamera: SKCameraNode {
    
    public let world: SKNode
    fileprivate var bounds: CGRect
    public var zoom: CGFloat = 1.0
    public var initialZoom: CGFloat = 1.0
    
    public var allowRotation: Bool = false
    public var allowMovement: Bool = true
    public var allowZoom: Bool = true
    public var scenePanned: UIPanGestureRecognizer!            // gesture recognizer to recognize scene panning
    
    // locations
    fileprivate var touchLocation = CGPoint.zero
    fileprivate var lastLocation: CGPoint!
    
    // MARK: - Init
    public init(view: SKView, world node: SKNode) {
        world = node
        bounds = view.bounds
        super.init()
        
        // setup drag recognizer
        scenePanned = UIPanGestureRecognizer(target: self, action: #selector(scenePannedHandler(_:)))
        scenePanned.minimumNumberOfTouches = 1
        scenePanned.maximumNumberOfTouches = 1
        view.addGestureRecognizer(scenePanned)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    /**
     Update the scene camera when a pan gesture is recogized.
     
     - parameter recognizer: `UIPanGestureRecognizer` pan gesture recognizer.
     */
    public func scenePannedHandler(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            lastLocation = recognizer.location(in: recognizer.view)
        }
        
        if recognizer.state == .changed {
            if lastLocation == nil { return }
            let location = recognizer.location(in: recognizer.view)
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            centerOn(CGPoint(x: Int(position.x - difference.x), y: Int(position.y - -difference.y)))
            lastLocation = location
        }
    }

    /**
     Apply zooming to the world node (as scale).
     
     - parameter scale: `CGFloat` zoom amount.
     */
    public func setWorldScale(_ scale: CGFloat) {
        self.zoom = scale
        world.setScale(scale)
    }
    
    /**
     Move camera around manually.
     
     - parameter point:    `CGPoint` point to move to.
     - parameter duration: `NSTimeInterval` duration of move.
     */
    public func panToPoint(_ point: CGPoint, duration: TimeInterval=0.3) {
        run(SKAction.move(to: point, duration: duration))
    }
    
    /**
     Center the camera on a location in the scene.
     
     - parameter scenePoint: `CGPoint` point in scene.
     - parameter easeInOut:  `NSTimeInterval` ease in/out speed.
     */
    public func centerOn(_ scenePoint: CGPoint, easeInOut: TimeInterval = 0) {
        if easeInOut == 0 {
            position = scenePoint
        } else {
            let moveAction = SKAction.move(to: scenePoint, duration: easeInOut)
            moveAction.timingMode = .easeOut
            run(moveAction)
        }
    }
    
    /**
     Reset the camera position & zoom level.
     */
    public func resetCamera() {
        centerOn(CGPoint(x: 0, y: 0))
        setWorldScale(initialZoom)
    }
}
