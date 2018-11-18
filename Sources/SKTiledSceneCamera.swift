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

 Methods for interacting with the custom `SKTiledSceneCamera`. Classes conforming to this
 protocol are notified of camera position & zoom changes - unless the `SKTiledSceneCameraDelegate.receiveCameraUpdates`
 flag is disabled.

 ![Tiled Scene Camera Delegate][tiled-scene-camera-delegate-image]

 ### Properties ###

 | Method                    | Description                                              |
 |---------------------------|----------------------------------------------------------|
 | receiveCameraUpdates      | Delegate will receive camera updates.                    |


 ### Instance Methods ###

 | Method                    | Description                                              |
 |---------------------------|----------------------------------------------------------|
 | containedNodesChanged     | Called when the nodes in the camera view changes.        |
 | cameraPositionChanged     | Called when the camera positon changes.                  |
 | cameraZoomChanged         | Called when the camera zoom changes.                     |
 | cameraBoundsChanged       | Called when the camera bounds updated.                   |
 | sceneDoubleClicked        | Called when the scene is double-clicked. (macOS only)    |
 | mousePositionChanged      | Called when the mouse moves in the scene. (macOS only)   |
 | sceneDoubleTapped         | Called when the scene is double-tapped. (iOS only)       |


 [tiled-scene-camera-delegate-image]:https://mfessenden.github.io/SKTiled/images/camera-delegate.svg

 */
@objc public protocol SKTiledSceneCameraDelegate: class {

    /**
     Allow delegate to receive updates from camera.
     */
    @objc var receiveCameraUpdates: Bool { get set }

    /**
     Allow delegates to receive updates when nodes in view change.

     - parameter nodes: `[SKNode]` nodes in camera view.
     */
    @objc optional func containedNodesChanged(_ nodes: Set<SKNode>)

    /**
     Called when the camera positon changes.

     - parameter newPositon: `CGPoint` updated camera position.
     */
    @objc optional func cameraPositionChanged(newPosition: CGPoint)

    /**
     Called when the camera zoom changes.

     - parameter newZoom: `CGFloat` camera zoom amount.
     */
    @objc optional func cameraZoomChanged(newZoom: CGFloat)

    /**
     Called when the camera bounds updated.

     - parameter bounds:  `CGRect` camera view bounds.
     - parameter positon: `CGPoint` camera position.
     - parameter zoom:    `CGFloat` camera zoom amount.
     */
    @objc optional func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat)

    #if os(macOS)
    /**
     Called when the scene is double-clicked (macOS only).

     - parameter event: `NSEvent` mouse click event.
     */
    @objc optional func sceneDoubleClicked(event: NSEvent)

    /**
     Called when the mouse moves in the scene (macOS only).

     - parameter event: `NSEvent` mouse click event.
     */
    @objc optional func mousePositionChanged(event: NSEvent)
    #endif


    #if os(iOS)
    /**
     Called when the scene receives a double-tap event (iOS only).

     - parameter location: `CGPoint` touch event location.
     */
    @objc optional func sceneDoubleTapped(location: CGPoint)
    #endif
}


/**

 ## Overview ##

 Camera zoom rounding factor. Clamps the zoom value to the nearest whole pixel value in order to alleviate cracks appearing in between individual tiles.

 ### Properties ###

 | Property | Description                                 |
 |----------|---------------------------------------------|
 | none     | Do not clamp camera zoom.                   |
 | half     | Clamp zoom to the nearest half-pixel.       |
 | third    | Clamp zoom to the nearest third of a pixel. |

 */
public enum CameraZoomClamping: CGFloat {
    case none    = 0
    case half    = 2
    case third   = 3
    case quarter = 4
    case tenth   = 10
}


/**

 ## Overview ##

 Determines how an attached controller interacts with the camera.

 ### Properties ###

 | Property | Description                                 |
 |----------|---------------------------------------------|
 | none     | Controller does not affect camera.          |
 | dolly    | Controller pans the camera.                 |
 | zoom     | Controller changes the camera zoom.         |

 */
public enum CameraControlMode: Int {
    case none
    case dolly
    case zoom
}


/**
 ## Overview ##

 Custom scene camera that responds to finger gestures and mouse events.

 The `SKTiledSceneCamera` is a custom camera meant to be used with a scene conforming to the `SKTiledSceneDelegate` protocol.
 The camera defines a position in the scene to render the scene from, with a reference to the `SKTiledSceneDelegate.worldNode`
 to interact with tile maps.

 ### Properties ###

 | Property      | Description                                                       |
 |---------------|-------------------------------------------------------------------|
 | world         | World container node.                                             |
 | delegates     | Array of delegates to notify about camera updates.                |
 | zoom          | Camera zoom value.                                                |
 | allowMovement | Toggle to allow camera movement.                                  |
 | minZoom       | Minimum zoom value.                                               |
 | maxZoom       | Maximum zoom value.                                               |
 | zoomClamping  | Clamping factor used to alleviate render artifacts like cracking. |

 */
public class SKTiledSceneCamera: SKCameraNode {

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
    /// Ignore mix/max zoom constraints
    public var ignoreZoomConstraints: Bool = false
    public var isAtMaxZoom: Bool { return zoom == maxZoom }

    /// Update delegates on visible node changes.
    public var notifyDelegatesOnContainedNodesChange: Bool = true
    
    /// Contained nodes
    public var containedNodes: [SKNode] {
        return containedNodeSet().filter { node in
            return (node as? SKTiledGeometry != nil)
        }
    }

    // camera control mode (tvOS)
    public var controlMode: CameraControlMode = CameraControlMode.none {
        didSet {

            NotificationCenter.default.post(
                name: Notification.Name.Camera.Updated,
                object: self,
                userInfo: ["cameraInfo": self.description,
                           "cameraControlMode": self.controlMode]
            )
        }
    }

    /// Clamping factor used to alleviate render artifacts like cracking.
    public var zoomClamping: CameraZoomClamping = CameraZoomClamping.none {
        didSet {
            setCameraZoom(self.zoom)

            NotificationCenter.default.post(
                name: Notification.Name.Camera.Updated,
                object: self,
                userInfo: nil
            )
        }
    }

    /// Flag to ignore zoom clamping.
    public var ignoreZoomClamping: Bool = true

    // logger
    public var loggingLevel: LoggingLevel = .info

    // gestures

    #if os(iOS)
    /// Gesture recognizer to recognize camera panning
    public var cameraPanned: UIPanGestureRecognizer!
    /// Gesture recognizer to recognize double taps
    public var sceneDoubleTapped: UITapGestureRecognizer!
    /// Gesture recognizer to recognize pinch actions
    public var cameraPinched: UIPinchGestureRecognizer!
    #endif

    /// Turn off to not respond to gestures
    public var allowGestures: Bool = false {
        didSet {
            guard oldValue != allowGestures else { return }
            #if os(iOS)
            cameraPanned.isEnabled = allowGestures
            sceneDoubleTapped.isEnabled = allowGestures
            cameraPinched.isEnabled = allowGestures
            #endif
        }
    }

    // locations
    fileprivate var focusLocation: CGPoint = CGPoint.zero
    fileprivate var lastLocation: CGPoint!

    // quick & dirty overlay node
    internal let overlay: SKNode = SKNode()

    /// Flag to show the overlay
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

        #if os(iOS)
        setupGestures(for: view)
        #endif

        if let clampingMode = CameraZoomClamping(rawValue: TiledGlobals.default.contentScale) {
            zoomClamping = clampingMode
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(iOS)
    // MARK: - Gestures

    /**
     Setup gesture recognizers for navigating the scene.

     - parameter skView: `SKView` current SpriteKit view.
     */
    public func setupGestures(for skView: SKView) {
        // setup pan recognizer
        cameraPanned = UIPanGestureRecognizer(target: self, action: #selector(cameraPanned(_:)))
        cameraPanned.minimumNumberOfTouches = 1
        cameraPanned.maximumNumberOfTouches = 1
        skView.addGestureRecognizer(cameraPanned)
        cameraPanned.isEnabled = allowGestures

        sceneDoubleTapped = UITapGestureRecognizer(target: self, action: #selector(sceneDoubleTapped(_:)))
        sceneDoubleTapped.numberOfTapsRequired = 2
        skView.addGestureRecognizer(sceneDoubleTapped)
        sceneDoubleTapped.isEnabled = allowGestures

        // setup pinch recognizer
        cameraPinched = UIPinchGestureRecognizer(target: self, action: #selector(scenePinched(_:)))
        skView.addGestureRecognizer(cameraPinched)
        cameraPinched.isEnabled = allowGestures
    }
    #endif

    // MARK: - Delegates

    /**
     Enable/disable camera callbacks for all delegates.

     - parameter value: `Bool` enable delegate callbacks.
     */
    public func enableDelegateCallbacks(_ value: Bool) {
        for delegate in self.delegates {
            delegate.receiveCameraUpdates = value
        }
    }

    /**
     Add a camera delegate to allow it to be notified of camera changes.

     - parameter delegate:  `SKTiledSceneCameraDelegate` camera delegate.
     */
    public func addDelegate(_ delegate: SKTiledSceneCameraDelegate) {
        if (delegates.index(where: { $0 === delegate }) != nil) {
            return
        }
        delegates.append(delegate)
    }

    /**
     Disconnect a camera delegate.

     - parameter delegate:  `SKTiledSceneCameraDelegate` camera delegate.
     */
    public func removeDelegate(_ delegate: SKTiledSceneCameraDelegate) {
        if let idx = delegates.index(where: { $0 === delegate}) {
            delegates.remove(at: idx)
        }
    }

    /**
     Update delegates with the contained nodes array.
     */
    internal func updateContainedNodes() {
        for delegate in self.delegates {
            guard (delegate.receiveCameraUpdates == true) && (notifyDelegatesOnContainedNodesChange == true) else { continue }
            
            DispatchQueue.main.async {
                delegate.containedNodesChanged?(self.containedNodeSet())
            }
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
    public func setCameraZoom(_ scale: CGFloat, interval: TimeInterval = 0) {

        // clamp scaling between min/max zoom
        var zoomClamped = (ignoreZoomConstraints == true) ? scale.clamped(minZoom, maxZoom) : scale

        // round zoom value to alleviate artifact
        zoomClamped = (ignoreZoomClamping == false) ? clampZoomValue(zoomClamped, factor: zoomClamping.rawValue) : scale

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
            delegate.cameraZoomChanged?(newZoom: zoomClamped)
        }

        self.updateContainedNodes()
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
            delegate.cameraBoundsChanged?(bounds: bounds, position: position, zoom: zoom)
        }
        self.updateContainedNodes()
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
            delegate.cameraPositionChanged?(newPosition: position)
        }
        self.updateContainedNodes()
    }

    /**
     Move camera manually.

     - parameter point:    `CGPoint` point to move to.
     - parameter duration: `TimeInterval` duration of move.
     */
    public func panToPoint(_ point: CGPoint, duration: TimeInterval = 0.3) {
        run(SKAction.move(to: point, duration: duration), completion: {
            // notify delegates
            for delegate in self.delegates {
                guard (delegate.receiveCameraUpdates == true) else { continue }
                delegate.cameraPositionChanged?(newPosition: point)
            }
            self.updateContainedNodes()
        })
    }

    /**
     Center the camera on a location in the scene.

     - parameter scenePoint: `CGPoint` point in scene.
     - parameter easeInOut:  `TimeInterval` ease in/out speed.
     */
    public func centerOn(scenePoint point: CGPoint, duration: TimeInterval = 0) {

        defer {
            // notify delegates
            for delegate in self.delegates {
                guard (delegate.receiveCameraUpdates == true) else { continue }
                delegate.cameraPositionChanged?(newPosition: point)
            }
            self.updateContainedNodes()
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
                guard (delegate.receiveCameraUpdates == true) else { continue }
                delegate.cameraPositionChanged?(newPosition: nodePosition)
            }
            self.updateContainedNodes()
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
    public func fitToView(newSize: CGSize, transition: TimeInterval = 0, verbose: Bool = false) {

        guard let scene = scene,
            let tiledScene = scene as? SKTiledSceneDelegate,
            let tilemap = tiledScene.tilemap else { return }


        let mapsize = tilemap.sizeInPoints // (tilemap.sizeInPoints / TiledGlobals.default.contentScale)
        self.log("tilemap size: \(mapsize)", level: .info)
        let tilemapCenter = scene.convert(tilemap.position, from: tilemap)

        let isPortrait: Bool = newSize.height > newSize.width

        let widthFactor: CGFloat = (tilemap.isPortrait == true) ? 0.85 : 0.75
        let heightFactor: CGFloat = (tilemap.isPortrait == true) ? 0.75 : 0.85

        let screenScaleWidth: CGFloat = isPortrait ? widthFactor : 0.8
        let screenScaleHeight: CGFloat = isPortrait ? heightFactor : 0.8

        // get the usable height/width
        let usableWidth: CGFloat = newSize.width * screenScaleWidth
        let usableHeight: CGFloat = newSize.height * screenScaleHeight
        let scaleFactor = (isPortrait == true) ? usableWidth / mapsize.width : usableHeight / mapsize.height

        //let heightOffset: CGFloat = (usableHeight / 20)
        let focusPoint = CGPoint(x: tilemapCenter.x, y: tilemapCenter.y) // -heightOffset

        centerOn(scenePoint: focusPoint)
        setCameraZoom(scaleFactor, interval: transition)
        self.log("fitting to view: \(usableWidth.roundTo()) x \(usableHeight.roundTo()),  scale: \(scaleFactor.roundTo())", level: .debug)

        NotificationCenter.default.post(
            name: Notification.Name.Camera.Updated,
            object: self,
            userInfo: ["cameraInfo": self.description, "cameraControlMode": self.controlMode]
        )
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


// was: 0.50, 0.25, 0.10
extension CameraZoomClamping {

    public var name: String {
        switch self {
        case .none: return "None"
        case .half: return "Half"
        case .third: return "Third"
        case .quarter: return "Quarter"
        case .tenth: return "Tenth"
        }
    }

    /**
     Returns an array of all camera zoom modes.

     - returns `[CameraZoomClamping]` all camera zoom modes.
     */
    static public func allModes() -> [CameraZoomClamping] {
        return [CameraZoomClamping.none, CameraZoomClamping.half, CameraZoomClamping.third, CameraZoomClamping.quarter, CameraZoomClamping.tenth]
    }

    /**
     Returns the next mode in the list.

     - returns `CameraZoomClamping` next mode in the list.
     */
    public func next() -> CameraZoomClamping {
        switch self {
        case .none: return .half
        case .half: return .third
        case .third: return .quarter
        case .quarter: return .tenth
        case .tenth: return .none
        }
    }

    /// Minimum possible value.
    public var minimum: CGFloat {
        switch self {
        case .half:
            return 0.50
        case .third:
            return 0.33
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

    /// Current clamp status
    public var clampDescription: String {
        let clampString = (ignoreZoomClamping == false) ? (zoomClamping != .none) ? ", clamp: \(zoomClamping.minimum)" : "" : ""
        let modeString = (controlMode != .none) ? ", mode: \(controlMode)" : ""
        let clampMode = (ignoreZoomClamping == true) ? ", clamp: off" : ""
        return "\(clampString)\(modeString)\(clampMode)"
    }

    /// Custom camera info description
    override public var description: String {
        guard let scene = scene else { return "Camera: "}
        let rect = CGRect(origin: scene.convert(position, from: self), size: bounds.size)
        let uiScale = getContentScaleFactor()
        let scaleString = (uiScale > 1) ? ", scale: \(uiScale)" : ""
        let sizeString = "origin: \(Int(rect.origin.x)), \(Int(rect.origin.y)), size: \(Int(rect.size.width)) x \(Int(rect.size.height))\(scaleString)"

        let result = "Camera: \(sizeString), zoom: \(zoom.roundTo())"
        return "\(result)\(clampDescription)"
    }

    override public var debugDescription: String {
        let clampString = (zoomClamping != .none) ? ", clamp: \(zoomClamping.minimum)" : ""
        return "Camera: \(bounds.roundTo()), zoom: \(zoom.roundTo())\(clampString)"
    }
}


// MARK: - Debugging

extension SKTiledSceneCamera: CustomDebugReflectable {
    
    public func dumpStatistics() {
        print("\n-------------- Camera --------------")
        print("  - position:              \(position.shortDescription)")
        print("  - zoom:                  \(zoom.roundTo(3))")
        print("  - clamping:              \(zoomClamping.name)")
        print("  - ignore clamping:       \(ignoreZoomClamping)")
        print("  - control mode:          \(controlMode)")
        print("  - tiled nodes visible:   \(containedNodes.count)")
        print("  - world position:        \(world.position.shortDescription)")
        print("\n  - delegates:")
        
        for delegate in delegates {
            let delegateName = String(describing: type(of: delegate) )
            let updateMode = (delegate.receiveCameraUpdates == true) ? "[x]" : "[ ]"
            print("   - \(updateMode) `\(delegateName)`")
        }
    }
}



extension SKTiledSceneCamera {
    #if os(iOS)
    // MARK: - Gesture Handlers

    /**
     Update the scene camera when a pan gesture is recogized.

     - parameter recognizer: `UIPanGestureRecognizer` pan gesture recognizer.
    */
    @objc public func cameraPanned(_ recognizer: UIPanGestureRecognizer) {
        guard (self.scene != nil), (allowMovement == true) else { return }

        if (recognizer.state == .began) {
            let location = recognizer.location(in: recognizer.view)
            lastLocation = location
        }

        if (recognizer.state == .changed) && (allowMovement == true) {
            if lastLocation == nil { return }
            let location = recognizer.location(in: recognizer.view)
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            // calls `cameraPositionChanged`
            centerOn(scenePoint: CGPoint(x: Int(position.x - difference.x), y: Int(position.y - -difference.y)))
            lastLocation = location
        }
    }

    /**
     Handler for double taps.

     - parameter recognizer: `UITapGestureRecognizer` tap gesture recognizer.
     */
    @objc public func sceneDoubleTapped(_ recognizer: UITapGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizer.State.ended && allowPause) {
            let location = recognizer.location(in: recognizer.view)
            for delegate in self.delegates {
                guard (delegate.receiveCameraUpdates == true) else { continue }
                delegate.sceneDoubleTapped?(location: location)
            }
        }
    }

    /**
     Update the camera scale in the scene.

     - parameter recognizer: `UIPinchGestureRecognizer`
     */
    @objc public func scenePinched(_ recognizer: UIPinchGestureRecognizer) {
        guard let scene = self.scene,
                (allowZoom == true) else { return }

        if recognizer.state == .began {
            let location = recognizer.location(in: recognizer.view)
            focusLocation = scene.convertPoint(fromView: location)  // correct
            // calls `cameraPositionChanged`
            centerOn(scenePoint: focusLocation)
        }

        if recognizer.state == .changed {
            zoom *= recognizer.scale

            // set the world scaling here
            setCameraZoomAtLocation(scale: zoom, location: focusLocation)
            recognizer.scale = 1
        }
    }

    #endif

    #if os(macOS)
    // MARK: - Mouse Handlers

    /**
     Handler for mouse click events.

     - parameter event: `NSEvent` mouse event.
     */
    override public func mouseDown(with event: NSEvent) {
        lastLocation = event.location(in: self)

        if (event.clickCount > 1) {
            for delegate in self.delegates {
                guard (delegate.receiveCameraUpdates == true) else { continue }
                delegate.sceneDoubleClicked?(event: event)
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
            guard (delegate.receiveCameraUpdates == true) else { continue }
            delegate.mousePositionChanged?(event: event)
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

    /**
     Callback for mouse drag events.

     - parameter event: `NSEvent` mouse drag event.
     */
    public func scenePositionChanged(with event: NSEvent) {
        guard (self.scene as? SKTiledScene != nil) else { return }
        let location = event.location(in: self)

        if lastLocation == nil { lastLocation = location }
        if allowMovement == true {
            if lastLocation == nil { return }
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            position = CGPoint(x: Int(position.x - difference.x), y: Int(position.y - difference.y))
            lastLocation = location

            for delegate in delegates {
                delegate.cameraPositionChanged?(newPosition: position)
            }
            self.updateContainedNodes()
        }
    }
    #endif
}


extension SKTiledSceneCamera: Loggable {}
