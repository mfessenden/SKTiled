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

 ## Overview ##

 Delegate for interacting with `SKTiledSceneCamera`. Classes conforming to this 
 protocol are notified of camera position & zoom changes.
 */
public protocol SKTiledSceneCameraDelegate: class {
    
    /**
     Called when the camera positon changes.

     - parameter newPositon: `CGPoint` updated camera position.
     */
    func cameraPositionChanged(newPosition: CGPoint)

    /**
     Called when the camera zoom changes.

     - parameter newZoom: `CGFloat` camera zoom amount.
     */
    func cameraZoomChanged(newZoom: CGFloat)

    /**
     Called when the camera bounds updated.

     - parameter bounds:  `CGRect` camera view bounds.
     - parameter positon: `CGPoint` camera position.
     - parameter zoom:    `CGFloat` camera zoom amount.
     */
    func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat)

    #if os(iOS) || os(tvOS)
    /**
     Called when the scene is double-tapped. (iOS only)

     - parameter location: `CGPoint` touch location.
     */
    func sceneDoubleTapped(location: CGPoint)
    #else

    /**
     Called when the scene is double-clicked. (macOS only)

     - parameter NSEvent: `NSEvent` click event.
     */
    func sceneDoubleClicked(event: NSEvent)

    /**
     Called when the mouse moves in the scene. (macOS only)

     - parameter event: `NSEvent` mouse event.
     */
    func mousePositionChanged(event: NSEvent)
    #endif
}

/**
 Camera zoom rounding factor. Clamps the zoom value to nearest quarter or half percentage.
 */
public enum CameraZoomClamping: CGFloat {
    case none    = 0
    case half    = 2
    case quarter = 4
    case tenth   = 10
}



/**
 ## Overview ##

 Custom scene camera that responds to finger gestures and mouse events.

 The `SKTiledSceneCamera` is a custom camera meant to be used with a scene conforming to the `SKTiledSceneDelegate` protocol. 
 The camera defines a position in the scene to render the scene from, with a reference to the `SKTiledSceneDelegate.worldNode` 
 to interact with tile maps.

 */
public class SKTiledSceneCamera: SKCameraNode, Loggable {

    unowned let world: SKNode
    internal var bounds: CGRect
    internal var delegates: [SKTiledSceneCameraDelegate] = []

    public var zoom: CGFloat = 1.0
    public var initialZoom: CGFloat = 1.0

    // movement constraints
    public var allowMovement: Bool = true
    public var allowZoom: Bool = true
    public var allowRotation: Bool = false
    public var allowPause: Bool = true

    // zoom constraints
    public var minZoom: CGFloat = 0.2
    public var maxZoom: CGFloat = 5.0
    public var isAtMaxZoom: Bool { return zoom == maxZoom }
    /// Clamp factor to alleviate cracks in tilemap.
    public var zoomClamping: CameraZoomClamping = .none {
        didSet {
            setCameraZoom(self.zoom)
        }
    }

    // logger
    public var loggingLevel: LoggingLevel = .info

    // gestures
    #if os(iOS) || os(tvOS)
    /// Gesture recognizer to recognize camera panning
    public var cameraPanned: UIPanGestureRecognizer!
    /// Gesture recognizer to recognize double taps
    public var sceneDoubleTapped: UITapGestureRecognizer!
    /// Gesture recognizer to recognize pinch actions
    public var cameraPinched: UIPinchGestureRecognizer!
    #endif

    // locations
    fileprivate var focusLocation: CGPoint = CGPoint.zero
    fileprivate var lastLocation: CGPoint!

    // quick & dirty overlay node
    internal let overlay: SKNode = SKNode()
    public var showOverlay: Bool = true {
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

     - parameter delegate:  `SKTiledSceneCameraDelegate` camera delegate.
     */
    public func addDelegate(_ delegate: SKTiledSceneCameraDelegate) {
        if (delegates.index(where: { $0 === delegate }) != nil) {
            return
        }
        delegates.append(delegate)
    }

    /**
     Remove a camera delegate.

     - parameter delegate:  `SKTiledSceneCameraDelegate` camera delegate.
     */
    public func removeDelegate(_ delegate: SKTiledSceneCameraDelegate) {
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
    public func setCameraZoom(_ scale: CGFloat, interval: TimeInterval=0) {
        // clamp scaling between min/max zoom
        var zoomClamped = scale.clamped(minZoom, maxZoom)

        // round zoom value to alleviate cracking
        zoomClamped = clampZoomValue(zoomClamped, factor: zoomClamping.rawValue)

        self.zoom = zoomClamped
        let zoomAction = SKAction.scale(to: zoomClamped, duration: interval)

        if (interval == 0) {
            world.setScale(zoomClamped)
        } else {
            world.run(zoomAction)
        }

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
    public func setCameraZoomAtLocation(scale: CGFloat, location: CGPoint) {
        setCameraZoom(scale)
        moveCamera(location: location, previous: position)
    }

    /**
     Set the camera min/max zoom values.

     - parameter minimum:    `CGFloat` minimum zoom vector.
     - parameter maximum:    `CGFloat` maximum zoom vector.
     */
    public func setZoomConstraints(minimum: CGFloat, maximum: CGFloat) {
        let minValue = minimum > 0 ? minimum : 0
        minZoom = minValue
        maxZoom = maximum
    }

    /**
     Clamp the camera scale to alleviate cracking. Default clamps float value to the nearest 0.25.

     - parameter value:   `CGFloat` zoom value.
     - parameter factor:  `CGFloat` scale factor.
     - returns: `CGFloat` clamped zoom value.
     */
    internal func clampZoomValue(_ value: CGFloat, factor: CGFloat = 0) -> CGFloat {
        guard factor != 0 else { return value }
        let result = round(value * factor) / factor
        return (result > 0) ? result : value
    }

    // MARK: - Bounds
    /**
     Update the camera bounds.

     - parameter bounds: `CGRect` camera view bounds.
     */
    public func setCameraBounds(bounds: CGRect) {
        self.bounds = bounds

        // notify delegates
        for delegate in delegates {
            delegate.cameraBoundsChanged(bounds: bounds, position: position, zoom: zoom)
        }
    }

    // MARK: - Movement

    /**
     Move the camera to the given location.

     - parameter location:  `CGPoint` new location.
     - parameter previous:  `CGPoint` old location.
     */
    public func moveCamera(location: CGPoint, previous: CGPoint) {
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
    public func panToPoint(_ point: CGPoint, duration: TimeInterval=0.3) {
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
    public func centerOn(scenePoint point: CGPoint, duration: TimeInterval=0) {
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
    public func centerOn(_ node: SKNode, duration: TimeInterval = 0) {
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
    public func resetCamera() {
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setCameraZoom(initialZoom)
    }

    /**
     Reset the camera position & zoom level.

     - parameter toScale: `CGFloat` camera scale.
     */
    public func resetCamera(toScale scale: CGFloat) {
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setCameraZoom(scale)
    }

    /**
     Center & fit the current tilemap in the frame when the parent scene is resized.

     - parameter newSize:    `CGSize` updated scene size.
     - parameter transition: `TimeInterval` transition time.
     */
    public func fitToView(newSize: CGSize, transition: TimeInterval=0) {

        guard let scene = scene,
            let tiledScene = scene as? SKTiledSceneDelegate,
            let tilemap = tiledScene.tilemap else { return }


        let tilemapSize = tilemap.sizeInPoints
        let tilemapCenter = scene.convert(tilemap.position, from: tilemap)

        let isPortrait: Bool = newSize.height > newSize.width

        let widthFactor: CGFloat = (tilemap.isPortrait == true) ? 0.7 : 0.6
        let heightFactor: CGFloat = (tilemap.isPortrait == true) ? 0.6 : 0.75

        let screenScaleWidth: CGFloat = isPortrait ? widthFactor : 0.7
        let screenScaleHeight: CGFloat = isPortrait ? heightFactor : 0.7

        // get the usable height/width
        let usableWidth: CGFloat = newSize.width * screenScaleWidth
        let usableHeight: CGFloat = newSize.height * screenScaleHeight
        let scaleFactor = (isPortrait == true) ? usableWidth / tilemapSize.width : usableHeight / tilemapSize.height

        //let heightOffset: CGFloat = (usableHeight / 20)
        let focusPoint = CGPoint(x: tilemapCenter.x, y: tilemapCenter.y) // -heightOffset

        centerOn(scenePoint: focusPoint)
        setCameraZoom(scaleFactor, interval: transition)

        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDebugLabels"), object: nil, userInfo: ["cameraInfo": self.description])
    }

    // MARK: - Geometry
    /**
     Returns the points of the camera's bounding shape.

     - returns: `[CGPoint]` array of points.
     */
    public func getVertices() -> [CGPoint] {
        return self.bounds.points
    }
}



extension CameraZoomClamping {
    /// Minimum possible value.
    public var minimum: CGFloat {
        switch self {
        case .half:
            return 0.50
        case .quarter:
            return 0.25
        case .tenth:
            return 0.10
        default:
            return 0
        }
    }
}


extension SKTiledSceneCamera {
    override public var description: String {
        guard let scene = scene else { return "Camera: "}
        let rect = CGRect(origin: scene.convert(position, from: self), size: bounds.size)
        let clampString = (zoomClamping != .none) ? ", clamp: \(zoomClamping.minimum)" : ""
        return "Camera: \(rect.roundTo()), zoom: \(zoom.roundTo())\(clampString)"
    }

    override public var debugDescription: String {
        let clampString = (zoomClamping != .none) ? ", clamp: \(zoomClamping.minimum)" : ""
        return "Camera: \(bounds.roundTo()), zoom: \(zoom.roundTo())\(clampString)"
    }
}





extension SKTiledSceneCamera {
    #if os(iOS) || os(tvOS)
    // MARK: - Gesture Handlers

    /**
     Update the scene camera when a pan gesture is recogized.

     - parameter recognizer: `UIPanGestureRecognizer` pan gesture recognizer.
    */
    public func cameraPanned(_ recognizer: UIPanGestureRecognizer) {
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
    public func sceneDoubleTapped(_ recognizer: UITapGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.ended) {
            let location = recognizer.location(in: recognizer.view)
            for delegate in self.delegates {
                recognizer.numberOfTouches

                delegate.sceneDoubleTapped(location: location)
            }
        }
    }

    /**
     Update the camera scale in the scene.

     - parameter recognizer: `UIPinchGestureRecognizer`
     */
    public func scenePinched(_ recognizer: UIPinchGestureRecognizer) {
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

    #else

    // MARK: - Mouse Handlers

    /**
     Handler for mouse click events.

     - parameter event: `NSEvent` mouse event.
     */
    override public func mouseDown(with event: NSEvent) {
        lastLocation = event.location(in: self)

        if (event.clickCount > 1) {
            for delegate in self.delegates {
                delegate.sceneDoubleClicked(event: event)
            }
        }
    }

    /**
     Track mouse movement in the scene. Location is in local space, so 
     coordinate origin will be the center of the current window.

     - parameter event: `NSEvent` mouse event.
     */
    override public func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        lastLocation = event.location(in: self)

        for delegate in self.delegates {
            delegate.mousePositionChanged(event: event)
        }
    }

    override public func mouseUp(with event: NSEvent) {
        guard (self.scene as? SKTiledScene != nil) else { return }
        let location = event.location(in: self)
        lastLocation = location
        focusLocation = location
    }

    /**
     Manage mouse wheel zooming. Need to make sure that lastLocation is a location in *this* node.
     */
    override public func scrollWheel(with event: NSEvent) {
        guard let scene = self.scene as? SKTiledScene else { return }

        var anchorPoint = event.locationInWindow
        anchorPoint = scene.convertPoint(fromView: anchorPoint)

        let anchorPointInCamera = convert(anchorPoint, from: scene)
        zoom += (event.deltaY * 0.05)

        let anchorPointInScene = scene.convert(anchorPointInCamera, from: self)
        let translationOfAnchorInScene = (x: anchorPoint.x - anchorPointInScene.x, y: anchorPoint.y - anchorPointInScene.y)
        position = CGPoint(x: position.x - translationOfAnchorInScene.x, y: position.y - translationOfAnchorInScene.y)

        focusLocation = position
        lastLocation = position

        setCameraZoom(zoom)
        //setCameraZoomAtLocation(scale: zoom, location: position)
    }

    public func scenePositionChanged(_ event: NSEvent) {
        guard (self.scene as? SKTiledScene != nil) else { return }
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
    #endif
}


/// Default methods.
extension SKTiledSceneCameraDelegate {
    public func cameraPositionChanged(newPosition: CGPoint) {}
    public func cameraZoomChanged(newZoom: CGFloat) {}
    public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {}
    #if os(iOS) || os(tvOS)
    public func sceneDoubleTapped(location: CGPoint) {}
    #else
    public func sceneDoubleClicked(event: NSEvent) {}
    public func mousePositionChanged(event: NSEvent) {}
    #endif
}
