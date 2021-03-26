//
//  SKTiledSceneCamera.swift
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
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


/// The `CameraZoomClamping` enumeration denotes the camera zoom rounding factor. Clamps the zoom value to the nearest whole pixel value in order to alleviate cracks appearing in between individual tiles.
///
/// ### Properties
///
/// - `none`: do not clamp camera zoom.
/// - `half`: clamp zoom to the nearest half-pixel.
/// - `third`: clamp zoom to the nearest third of a pixel.
/// - `quarter`: clamp zoom to the nearest quarter of a pixel.
/// - `tenth`: clamp zoom to the nearest 1/10 of a pixel.
///
public enum CameraZoomClamping: CGFloat {
    case none    = 0
    case half    = 2
    case third   = 3
    case quarter = 4
    case tenth   = 10
}


/// The `CameraControlMode` enumeration determines how an attached controller interacts with the camera.
///
/// ### Properties
///
/// - `none`: Controller does not affect camera.
/// - `dolly`: Controller pans the camera.
/// - `zoom`: Controller changes the camera zoom.
/// :nodoc:
public enum CameraControlMode: UInt8 {
    case none
    case dolly
    case zoom
}


/// The `CameraMovementMode` enumeration determines how the scene camera interprets touch and mouse events.
///
/// ### Properties
///
/// - `none`: camera will not move.
/// - `dolly`: camera will pan based on mouse/touch drag events.
/// - `rotation`: camera rotates on its z-axis.
/// :nodoc:
internal enum CameraMovementMode: UInt8 {
    case none
    case movement
    case rotation
}


/// The `SKTiledSceneCamera` is a custom scene camera that responds to finger gestures and mouse events.
///
/// ![Camera Hierarchy][tiledata-diagram-url]
///
/// This node is a custom camera meant to be used with a scene conforming to the `TiledSceneDelegate` protocol.
/// The camera defines a position in the scene to render the scene from, with a reference to the `TiledSceneDelegate.worldNode`
/// to interact with tile maps.
///
/// ### Properties
///
/// - `world`: world container node.
/// - `delegates`: array of delegates to notify about camera updates.
/// - `zoom`: camera zoom value.
/// - `allowMovement`: toggle to allow camera movement.
/// - `minZoom`: minimum zoom value.
/// - `maxZoom`: maximum zoom value.
/// - `zoomClamping`: clamping factor used to alleviate render artifacts like cracking.
///
/// For more information, see the **[Tiled Scene Camera][camera-doc-url]** page in the **[official documentation][sktiled-docroot-url]**.
///
/// [camera-doc-url]:https://mfessenden.github.io/SKTiled/1.3/scene-setup.html#tiled-scene-camera
/// [sktiled-docroot-url]:https://mfessenden.github.io/SKTiled/1.3/index.html
/// [tiledata-diagram-url]:https://mfessenden.github.io/SKTiled/1.3/images/tiledata-setup.svg
public class SKTiledSceneCamera: SKCameraNode {
    
    /// World container node.
    weak public var world: SKNode?
    
    /// Camera bounds.
    internal var bounds: CGRect = CGRect.zero
    
    /// Array of delegates.
    internal var delegates: [TiledSceneCameraDelegate] = []
    
    /// Camera zoom level.
    public var zoom: CGFloat = 1.0
    
    /// Camera rotation (in degrees).
    @objc public override var rotation: CGFloat {
        get {
            return zRotation.degrees()
        } set {
            zRotation = newValue.radians()
            
            // TODO: document this notification
            NotificationCenter.default.post(
                name: Notification.Name.Camera.Updated,
                object: self
            )
        }
    }
    
    /// Initial camera zoom.
    public var initialZoom: CGFloat = 1.0
    
    /// Movement constraints.
    public var allowMovement: Bool = true
    
    /// Camera can adjust zoom.
    public var allowZoom: Bool = true
    
    /// Camera can rotate.
    public var allowRotation: Bool = true
    
    /// Restore normal rotation values after a certain period.
    public var restoreRotation: Bool = true
    
    /// Amount to dampen the camera rotation.
    public var rotationDamping: CGFloat = 0.001
    
    /// Allow tap events.
    internal var allowTaps: Bool = true
    
    /// Allow gesture recognition.
    public var allowGestures: Bool = false {
        didSet {
            guard oldValue != allowGestures else { return }
            #if os(iOS)
            cameraPanned.isEnabled = allowGestures
            sceneDoubleTapped.isEnabled = allowGestures
            cameraPinched.isEnabled = allowGestures
            cameraRotated.isEnabled = allowGestures
            #endif
        }
    }
    
    /// Zoom minimum constraint.
    public var minZoom: CGFloat = 0.2
    
    /// Zoom maximum constraint.
    public var maxZoom: CGFloat = 5.0
    
    /// Ignore mix/max zoom constraints.
    public var ignoreZoomConstraints: Bool = false
    
    /// Allow the camera zoom to be inverted.
    public var allowNegativeZoom: Bool = false
    
    /// Returns true if the camera is zoomed out completely.
    public var isAtMaxZoom: Bool {
        return zoom == maxZoom
    }
    
    /// Indicates the camera is currently moving.
    public private(set) var isMoving: Bool = false
    
    /// Update delegates on visible node changes.
    public var notifyDelegatesOnContainedNodesChange: Bool = TiledGlobals.default.enableCameraContainedNodesCallbacks {
        didSet {
            guard (oldValue != notifyDelegatesOnContainedNodesChange) else  { return }
            
            NotificationCenter.default.post(
                name: Notification.Name.Camera.Updated,
                object: self
            )
        }
    }
    
    /// Returns all **SKTiled** nodes contained within the camera view.
    public var containedNodes: [SKNode] {
        // FIXME: crash here
        return containedNodeSet().filter { node in
            return (node as? TiledGeometryType != nil)
        }
    }
    
    /// Camera control mode (tvOS).
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
            
            // TODO: demo only?
            NotificationCenter.default.post(
                name: Notification.Name.Camera.Updated,
                object: self
            )
        }
    }
    
    /// The current movement mode.
    internal var cameraMovementMode: CameraMovementMode = CameraMovementMode.none
    
    /// Flag to ignore zoom clamping.
    public var ignoreZoomClamping: Bool = true
    
    /// Logging verbosity.
    public var loggingLevel: LoggingLevel = .info
    
    /// Camera bounds inset value.
    internal var boundsInset: CGFloat = 4
    
    /// Bounds visualization.
    internal lazy var cameraBoundsShape: SKShapeNode = {
        let shape = SKShapeNode(rect: self.bounds.insetBy(self.boundsInset))
        addChild(shape)
        shape.position = CGPoint(x: -self.bounds.size.width / 2, y: -self.bounds.size.height / 2)
        return shape
    }()
    
    
    // gestures
    
    #if os(iOS)
    
    /// Gesture recognizer to handle camera pan actions.
    public var cameraPanned: UIPanGestureRecognizer!
    
    /// Gesture recognizer to handle double-tap events.
    public var sceneDoubleTapped: UITapGestureRecognizer!
    
    /// Gesture recognizer to handle pinch actions.
    public var cameraPinched: UIPinchGestureRecognizer!
    
    /// Gesture recognizer to handle touch rotation actions.
    public var cameraRotated: UIRotationGestureRecognizer!
    #endif
    
    // MARK: - Locations
    
    /// Current focal point.
    fileprivate var focusLocation: CGPoint = CGPoint.zero
    
    /// Last focal point.
    fileprivate var lastLocation: CGPoint!
    
    
    // MARK: - Overlay
    
    
    /// Quick & dirty overlay node.
    internal let overlay: SKNode = SKNode()
    
    /// Flag to show the overlay.
    public var showOverlay: Bool = true {
        didSet {
            guard oldValue != showOverlay else { return }
            overlay.isHidden = !showOverlay
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize the camera with a `SKView` and world node references.
    ///
    /// - Parameters:
    ///   - view: parent view.
    ///   - node: world container node.
    public init(view: SKView, world node: SKNode) {
        delegates = []
        world = node
        bounds = view.bounds
        super.init()
        
        // add the overlay
        overlay.name = "CAMERA_OVERLAY"
        addChild(overlay)
        overlay.isHidden = true
        
        #if SKTILED_DEMO
        overlay.setAttrs(values: ["tiled-element-name": "overlay", "tiled-node-icon": "overlay-icon", "tiled-help-desc": "Camera overlay node.", "tiled-node-listdesc": "Camera Overlay", "tiled-node-nicename": "Camera Overlay"])
        #endif
        
        #if os(iOS)
        setupGestures(for: view)
        #endif
        
        if let clampingMode = CameraZoomClamping(rawValue: TiledGlobals.default.contentScale) {
            zoomClamping = clampingMode
        }
        
        #if os(macOS)
        if let mainWindow = view.window {
            mainWindow.acceptsMouseMovedEvents = true
        }
        #endif
    }
    
    /// Instantiate the map with a decoder instance.
    ///
    /// - Parameter aDecoder: decoder.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        // remove delegates
        delegates.removeAll()
    }
    
    // MARK: - Gestures
    
    #if os(iOS)
    
    /// Setup gesture recognizers for navigating the scene.
    ///
    /// - Parameter skView: current SpriteKit view.
    public func setupGestures(for skView: SKView) {
        /// setup pan recognizer
        cameraPanned = UIPanGestureRecognizer(target: self, action: #selector(cameraPanned(_:)))
        cameraPanned.minimumNumberOfTouches = 1
        cameraPanned.maximumNumberOfTouches = 1
        skView.addGestureRecognizer(cameraPanned)
        cameraPanned.isEnabled = allowGestures
        
        /// double-tap recognizer
        sceneDoubleTapped = UITapGestureRecognizer(target: self, action: #selector(sceneDoubleTapAction))
        sceneDoubleTapped.numberOfTapsRequired = 2
        skView.addGestureRecognizer(sceneDoubleTapped)
        sceneDoubleTapped.isEnabled = allowGestures
        
        /// setup pinch recognizer
        cameraPinched = UIPinchGestureRecognizer(target: self, action: #selector(scenePinched(_:)))
        skView.addGestureRecognizer(cameraPinched)
        cameraPinched.isEnabled = allowGestures
        
        /// setup rotation recognizer
        cameraRotated = UIRotationGestureRecognizer(target: self, action: #selector(sceneRotated(_:)))
        skView.addGestureRecognizer(cameraRotated)
        cameraRotated.isEnabled = allowGestures
    }
    
    #endif
    
    // MARK: - Delegates
    
    /// Enable/disable camera callbacks for *all* delegates.
    ///
    /// - Parameter value: enable delegate callbacks.
    public func enableDelegateCallbacks(_ value: Bool) {
        for delegate in self.delegates {
            delegate.receiveCameraUpdates = value
        }
    }
    
    /// Add a camera delegate to allow it to be notified of camera changes.
    ///
    /// - Parameter delegate: camera delegate.
    public func addDelegate(_ delegate: TiledSceneCameraDelegate) {
        if (delegates.firstIndex(where: { $0 === delegate }) != nil) {
            return
        }
        //delegate.currentZoomLevel = zoom
        delegates.append(delegate)
    }
    
    /// Disconnect a camera delegate.
    ///
    /// - Parameter delegate: camera delegate.
    public func removeDelegate(_ delegate: TiledSceneCameraDelegate) {
        if let idx = delegates.firstIndex(where: { $0 === delegate}) {
            delegates.remove(at: idx)
        }
    }
    
    /// Notify delegates when the contained nodes change.
    internal func updateContainedNodes() {
        guard (notifyDelegatesOnContainedNodesChange == true) else {
            return
        }
        
        let currentlyContained = Set(self.containedNodes)
        
        // pass nodes to delegates
        for delegate in self.delegates {
            guard (delegate.receiveCameraUpdates == true) else {
                continue
            }
            
            DispatchQueue.main.async {
                delegate.containedNodesChanged?(currentlyContained)
            }
        }
    }
    
    // MARK: - Overlay
    
    /// Add a node to the overlay node.
    ///
    /// - Parameter node: node.
    public func addToOverlay(_ node: SKNode) {
        overlay.addChild(node)
        node.zPosition = zPosition + 10
    }
    
    // MARK: - Zooming
    
    /// Apply zooming to the world node (as scale).
    ///
    /// - Parameters:
    ///   - scale: zoom amount.
    ///   - interval: zoom transition time.
    ///   - update: update the contained nodes.
    public func setCameraZoom(_ scale: CGFloat,
                              interval: TimeInterval = 0,
                              update: Bool = true) {
        
        // clamp scaling between min/max zoom
        var zoomClamped = (ignoreZoomConstraints == true) ? scale.clamped(minZoom, maxZoom) : scale
        
        // round zoom value to alleviate artifact
        zoomClamped = (ignoreZoomClamping == false) ? clampZoomValue(zoomClamped, factor: zoomClamping.rawValue) : scale
        
        // if scale is negative, decide how to handle it
        //zoomClamped = (allowNegativeZoom == false) ? minZoom : zoomClamped
        
        if (zoomClamped <= 0) {
            if (allowNegativeZoom == false) {
                zoomClamped = abs(zoomClamped)
            }
        }
        
        self.zoom = zoomClamped
        
        let zoomAction = SKAction.scale(to: zoomClamped, duration: interval)
        
        if (interval == 0) {
            world?.setScale(zoomClamped)
        } else {
            world?.run(zoomAction)
        }
        
        if let tilemap = (scene as? TiledSceneDelegate)?.tilemap {
            tilemap.autoResize = false
        }
        
        
        // notify delegates
        DispatchQueue.main.async {
            for delegate in self.delegates {
                delegate.cameraZoomChanged?(newZoom: zoomClamped)
            }
        }
        
        
        if (update == true) {
            self.updateContainedNodes()
        }
    }
    
    /// Apply zooming to the camera at a specific location.
    ///
    /// - Parameters:
    ///   - scale: zoom amount.
    ///   - location: zoom location.
    public func setCameraZoomAtLocation(scale: CGFloat, location: CGPoint) {
        focusLocation = location
        setCameraZoom(scale, interval: 0, update: false)
        moveCamera(location: location, previous: position)
    }
    
    /// Set the camera min/max zoom values. This setting will be ignored if the `SKTiledSceneCamera.ignoreZoomConstraints` property is `false`.
    ///
    /// - Parameters:
    ///   - minimum: minimum zoom vector.
    ///   - maximum: maximum zoom vector.
    public func setZoomConstraints(minimum: CGFloat, maximum: CGFloat) {
        let minValue = minimum > 0 ? minimum : 0
        minZoom = minValue
        maxZoom = maximum
    }
    
    /// Clamp the camera scale to alleviate cracking. Default clamps float value to the nearest 0.25.
    ///
    /// - Parameters:
    ///   - value: zoom value.
    ///   - factor: scale factor.
    /// - Returns: clamped zoom value.
    internal func clampZoomValue(_ value: CGFloat, factor: CGFloat = 0) -> CGFloat {
        guard factor != 0 else { return value }
        let result = round(value * factor) / factor
        return (result > 0) ? result : value
    }
    
    // MARK: - Bounds
    
    /// Update the camera bounds. Camera delegates are notified automatically with the changes.
    ///
    /// - Parameter bounds: camera view bounds.
    public func setCameraBounds(bounds: CGRect) {
        self.bounds = bounds
        
        // notify delegates
        DispatchQueue.main.async {
            for delegate in self.delegates {
                delegate.cameraBoundsChanged?(bounds: bounds, position: self.position, zoom: self.zoom)
            }
        }
        self.updateContainedNodes()
    }
    
    /// Redraw the camera bounding shape.
    func drawBounds(withColor: SKColor? = nil,
                    duration: TimeInterval = 0) {
        
        let boundsColor = (withColor != nil) ? withColor! : TiledGlobals.default.debugDisplayOptions.cameraBoundsColor
        cameraBoundsShape.path = CGPath(rect: bounds.insetBy(boundsInset), transform: nil)
        cameraBoundsShape.strokeColor = boundsColor.withAlphaComponent(0.6)
        cameraBoundsShape.position = CGPoint(x: -bounds.size.width / 2, y: -bounds.size.height / 2)
    }
    
    // MARK: - Movement
    
    /// Move the camera to a given location in the scene.
    ///
    /// - Parameters:
    ///   - location: new location.
    ///   - previous: old location.
    public func moveCamera(location: CGPoint, previous: CGPoint) {
        
        let dy = position.y - (location.y - previous.y)
        let dx = position.x - (location.x - previous.x)
        
        position = CGPoint(x: dx, y: dy)
        
        // notify delegates
        DispatchQueue.main.async {
            for delegate in self.delegates {
                delegate.cameraPositionChanged?(newPosition: self.position)
            }
        }
        
        self.updateContainedNodes()
    }
    
    /// Pan the camera manually. Optionally, a duration can be specified for the movement.
    ///
    /// - Parameters:
    ///   - point: point to move to.
    ///   - duration: duration of move.
    public func panToPoint(_ point: CGPoint, duration: TimeInterval = 0.3) {
        run(SKAction.move(to: point, duration: duration), completion: { [unowned self] in
            // notify delegates
            DispatchQueue.main.async {
                for delegate in self.delegates {
                    guard (delegate.receiveCameraUpdates == true) else { continue }
                    
                    // TODO: async notify
                    delegate.cameraPositionChanged?(newPosition: point)
                }
            }
            
            self.updateContainedNodes()
        })
    }
    
    /// Center the camera on a location in the scene.
    ///
    /// - Parameters:
    ///   - point: point in scene.
    ///   - duration: ease in/out speed.
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
    
    /// Center the camera on a node in the scene.
    ///
    /// - Parameters:
    ///   - node: node in scene.
    ///   - duration: ease in/out speed.
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
    
    // MARK: - Camera Reset
    
    
    /// Reset the camera position & zoom level.
    public func resetCamera(duration: TimeInterval = 0) {
        if duration == 0 {
            centerOn(scenePoint: .zero)
            rotation = 0
            return
        }
        
        let resetAction = SKAction.group([
            SKAction.run {
                //panToPoint(.zero, duration: duration)
                self.centerOn(scenePoint: .zero, duration: duration)
                self.setCameraZoom(self.initialZoom)
            },
            SKAction.rotate(toAngle: 0, duration: duration)
        ])
        
        run(resetAction)
    }
    
    /// Reset the camera position & zoom level.
    ///
    /// - Parameter scale: camera scale.
    public func resetCamera(toScale scale: CGFloat, duration: TimeInterval = 0) {
        centerOn(scenePoint: CGPoint(x: 0, y: 0))
        setCameraZoom(scale)
        run(SKAction.rotate(toAngle: 0, duration: 1))
    }
    
    /// Center & fit the current tilemap in the frame when the parent scene is resized.
    ///
    /// - Parameters:
    ///   - newSize: updated scene size.
    ///   - transition: transition time.
    public func fitToView(newSize: CGSize, transition: TimeInterval = 0) {
        guard let scene = scene,
              let tiledScene = scene as? TiledSceneDelegate,
              let tilemap = tiledScene.tilemap else {
            return
        }
        
        // get the tilemap anchor position
        let mapsize = tilemap.sizeInPoints
        // FIXME: this only works for `center` layer alignment
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
        self.log("fitting to view: \(usableWidth.stringRoundedTo()) x \(usableHeight.stringRoundedTo()),  scale: \(scaleFactor.stringRoundedTo())", level: .debug)
        
        NotificationCenter.default.post(
            name: Notification.Name.Camera.Updated,
            object: self,
            userInfo: ["cameraInfo": self.description, "cameraControlMode": self.controlMode]
        )
    }
    
    // MARK: - Geometry
    
    /// Returns the points of the camera's bounding shape.
    ///
    /// - Returns: array of points.
    @objc public func getVertices() -> [CGPoint] {
        return self.bounds.points
    }
}


// MARK: - Extensions


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
    
    /// Returns an array of all camera zoom modes.
    ///
    /// - Returns: current camera zoom modes.
    public static func allModes() -> [CameraZoomClamping] {
        return [CameraZoomClamping.none, CameraZoomClamping.half, CameraZoomClamping.third, CameraZoomClamping.quarter, CameraZoomClamping.tenth]
    }
    
    /// Returns the next camera clamping mode.
    ///
    /// - Returns: next camera zoom clamping mode.
    public func next() -> CameraZoomClamping {
        switch self {
            case .none: return .half
            case .half: return .third
            case .third: return .quarter
            case .quarter: return .tenth
            case .tenth: return .none
        }
    }
    
    /// The *minimum* possible value for a given zoom clamping level.
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


// :nodoc:
extension SKTiledSceneCamera {
    
    /// Current clamp status.
    fileprivate var clampDescription: String {
        let clampString = (ignoreZoomClamping == false) ? (zoomClamping != .none) ? ", clamp: \(zoomClamping.minimum)" : "" : ""
        let clampMode = (ignoreZoomClamping == true) ? ", clamp: off" : ""
        return "\(clampString)\(clampMode)"
    }
    
    /// World rotation status.
    fileprivate var rotationDescription: String {
        return (rotation != 0) ? " rotation: \(rotation.stringRoundedTo(2))" : ""
    }
    
    
    /// Custom camera info description.
    public override var description: String {
        guard let scene = scene else {
            return "\(tiledNodeNiceName): "
        }
        
        let rect = CGRect(origin: scene.convert(position, from: self), size: bounds.size)
        let uiScale = getContentScaleFactor()
        let scaleString = (uiScale > 1) ? " scale: \(uiScale) " : ""
        let clampString = (zoomClamping != .none) ? " clamp: \(zoomClamping.minimum)" : ""
        let attrsString = "origin: \(rect.origin.stringRoundedTo(1)) size: \(rect.size)\(scaleString) zoom: \(zoom.stringRoundedTo())\(clampString)"
        return "\(tiledNodeNiceName): \(attrsString)\(rotationDescription)"
    }
}


// MARK: - Debugging

// :nodoc:
extension SKTiledSceneCamera: TiledCustomReflectableType {
    
    /// Dump camera statistics to the console.
    public func dumpStatistics() {
        let headerString = "--------------- Camera ---------------"
        guard let world = world else {
            print("\n\(headerString)\n  - no world node \n\n")
            return
        }
        
        print("\n\(headerString)")
        print("  ▸ position:                  \(position.shortDescription)")
        print("  ▸ rotation:                  \(rotation.stringRoundedTo(1))")
        print("  ▾ zoom:                      \(zoom.stringRoundedTo(3))")
        print("     ▸ min:                    \(minZoom)")
        print("     ▸ max:                    \(maxZoom)")
        print("  ▸ ignore zoom constraints:   \(ignoreZoomConstraints)")
        print("  ▸ allow negative:            \(allowNegativeZoom)")
        print("  ▸ clamping:                  \(zoomClamping.name)")
        print("  ▸ ignore clamping:           \(ignoreZoomClamping)")
        print("  ▸ control mode:              \(controlMode)")
        print("  ▸ tiled nodes visible:       \(containedNodes.count)")
        print("  ▸ world position:            \(world.position.shortDescription)")
        print("  ▸ world rotation:            \(world.zRotation.stringRoundedTo(3))")
        print("\n  ▾ Delegates:")
        
        for delegate in delegates {
            let dname = String(describing: type(of: delegate))
            print("   ▸ \(delegate.receiveCameraUpdates.valueAsCheckbox) '\(dname)'")
        }
        
        print("\n\n")
    }
    
    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "Camera"
    }
    
    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "camera-icon"
    }
    
    /// A description of the node used in list or outline views.
    @objc public var tiledListDescription: String {
        let nameString = (name != nil) ? ": '\(name!)'" : ""
        let delegateString = "( \(delegates.count) delegates )"
        return "\(tiledNodeNiceName)\(nameString) \(delegateString)"
    }
    
    /// A description of the node used for list views.
    @objc public var tiledHelpDescription: String {
        return "Tiled scene camera."
    }
}



// MARK: - Extensions


extension SKTiledSceneCamera {
    
    #if os(iOS)
    
    // MARK: - Gesture Handlers
    
    /// Update the scene camera when a pan gesture is recogized.
    ///
    /// - Parameter recognizer: pan gesture recognizer.
    @objc public func cameraPanned(_ recognizer: UIPanGestureRecognizer) {
        guard (self.scene != nil), (allowMovement == true) else {
            return
        }
        
        if (recognizer.state == .began) {
            let location = recognizer.location(in: recognizer.view)
            lastLocation = location
        }
        
        if (recognizer.state == .changed) && (allowMovement == true) {
            if lastLocation == nil { return }
            let location = recognizer.location(in: recognizer.view)
            let delta = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            
            // calls `cameraPositionChanged`
            centerOn(scenePoint: CGPoint(x: Int(position.x - delta.x), y: Int(position.y - -delta.y)))
            lastLocation = location
        }
    }
    
    /// Handler for double-tap gestures.
    ///
    /// - Parameter recognizer: tap gesture recognizer.
    @objc public func sceneDoubleTapAction(_ recognizer: UITapGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizer.State.ended && allowTaps) {
            let location = recognizer.location(in: recognizer.view)
            for delegate in self.delegates {
                guard (delegate.receiveCameraUpdates == true) else { continue }
                delegate.sceneDoubleTapped?(location: location)
            }
        }
    }
    
    ///  Handler for pinch gesture events. Updates the camera scale in the scene.
    ///
    /// - Parameter recognizer: pinch gesture recognizer.
    @objc public func scenePinched(_ recognizer: UIPinchGestureRecognizer) {
        guard let scene = self.scene,(allowZoom == true) else {
            return
        }
        
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
    
    ///  Handler for multi-touch rotation events. Updates the camera rotation in the scene.
    ///
    /// - Parameter recognizer: rotation gesture recognizer.
    @objc public func sceneRotated(_ recognizer: UIRotationGestureRecognizer) {
        guard let world = self.world, (allowRotation == true) else {
            return
        }
        
        let rotationAmount = recognizer.rotation
        let rotationVelocity = abs(recognizer.velocity)
        let newRotation = rotationAmount * rotationVelocity
        rotation -= newRotation
    }
    
    #endif
    
    #if os(macOS)
    
    // MARK: - Mouse Handlers
    
    /// Handler for mouse down events.
    ///
    /// - Parameter event: mouse event.
    public override func mouseDown(with event: NSEvent) {
        lastLocation = event.location(in: self)
        isMoving = true
        if (event.modifierFlags.contains(.option) && allowRotation == true) {
            cameraMovementMode = .rotation
        } else {
            cameraMovementMode = .movement
        }
        
        // single-click event
        if (event.clickCount == 1) {
            for delegate in self.delegates {
                guard (delegate.receiveCameraUpdates == true) else { continue }
                delegate.sceneClicked?(event: event)
            }
            return
        }
        
        // double-click event
        if (event.clickCount > 1) {
            for delegate in self.delegates {
                guard (delegate.receiveCameraUpdates == true) else { continue }
                delegate.sceneDoubleClicked?(event: event)
            }
            return
        }
        
        super.mouseDown(with: event)
    }
    
    ///  Handler for mouse up events.
    ///
    /// - Parameter event: mouse event.
    public override func mouseUp(with event: NSEvent) {
        guard (self.scene as? TiledSceneDelegate != nil) else {
            return
        }
        
        if (isMoving == true) {
            updateContainedNodes()
        }
        
        let location = event.location(in: self)
        lastLocation = location
        focusLocation = location
        isMoving = false
        
        super.mouseUp(with: event)
    }
    
    /// Track mouse movement in the scene. Location is in local space, so coordinate origin will be the center of the current window.
    ///
    /// - Parameter event: mouse event.
    public override func mouseMoved(with event: NSEvent) {
        guard (TiledGlobals.default.enableMouseEvents == true) else {
            return
        }
        
        if (event.type == .mouseMoved) {
            lastLocation = event.location(in: self)
            
            for delegate in self.delegates {
                guard (delegate.receiveCameraUpdates == true) else {
                    continue
                }
                delegate.mousePositionChanged?(event: event)
            }
        }
        super.mouseMoved(with: event)
    }
    
    /// Tracks mouse drag events.
    ///
    /// - Parameter event: mouse event
    public override func mouseDragged(with event: NSEvent) {
        guard (TiledGlobals.default.enableMouseEvents == true) else {
            return
        }
        super.mouseDragged(with: event)
        if (event.modifierFlags.contains(.option) && allowRotation == true) {
            sceneRotationChanged(with: event)
        } else {
            scenePositionChanged(with: event)
        }
    }
    
    /// Manage mouse wheel zooming. Need to ensure that lastLocation is a location in *this* node.
    ///
    /// - Parameter event: mouse wheel event.
    public override func scrollWheel(with event: NSEvent) {
        guard (TiledGlobals.default.enableMouseEvents == true),
              let scene = self.scene, (allowZoom == true) else {
            return
        }
        
        super.scrollWheel(with: event)
        
        if (allowZoom == true) {
            
            // get mouse position in window
            // get mouse position relative to center
            
            isMoving = true
            
            // this is correct
            var windowLocation = event.locationInWindow
            windowLocation = scene.convertPoint(fromView: windowLocation)
            
            // convert the scene position
            let anchorPointInCamera = convert(windowLocation, from: scene)
            
            // set the zoom level
            zoom += (event.deltaY * 0.05) * (zoom * 0.5)
            
            let anchorPointInScene = scene.convert(anchorPointInCamera, from: self)
            let translationOfAnchorInScene = (x: windowLocation.x - anchorPointInScene.x, y: windowLocation.y - anchorPointInScene.y)
            position = CGPoint(x: position.x - translationOfAnchorInScene.x, y: position.y - translationOfAnchorInScene.y)
            
            focusLocation = windowLocation
            lastLocation = position
            setCameraZoom(zoom)
        }
    }
    
    /// Handler for mouse right-click events. The mouse event is forwarded to any delegates implementing the `TiledSceneCameraDelegate.sceneRightClicked(event:)` method.
    ///
    ///
    /// - Important:
    ///   delegates need to have the `TiledSceneCameraDelegate.receiveCameraUpdates` property set to `true` in order for these events to be forwarded.
    ///
    /// - Parameter event: mouse right-click event.
    public override func rightMouseDown(with event: NSEvent) {
        guard (TiledGlobals.default.enableMouseEvents == true) else {
            return
        }
        
        for delegate in self.delegates {
            guard (delegate.receiveCameraUpdates == true) else {
                continue
            }
            delegate.sceneRightClicked?(event: event)
        }
        
        NotificationCenter.default.post(
            name: Notification.Name.Camera.MouseRightClicked,
            object: nil
        )
        
        
        super.rightMouseDown(with: event)
    }
    
    /// Handler for mouse right-click events. The mouse event is forwarded to any delegates implementing the `TiledSceneCameraDelegate.sceneRightClicked(event:)` method.
    ///
    ///
    /// - Important:
    ///   delegates need to have the `TiledSceneCameraDelegate.receiveCameraUpdates` property set to `true` in order for these events to be forwarded.
    ///
    /// - Parameter event: mouse right-click event.
    public override func rightMouseUp(with event: NSEvent) {
        guard (TiledGlobals.default.enableMouseEvents == true) else {
            return
        }
        
        for delegate in self.delegates {
            guard (delegate.receiveCameraUpdates == true) else {
                continue
            }
            delegate.sceneRightClickReleased?(event: event)
        }
        
        super.rightMouseUp(with: event)
        
        #if SKTILED_DEMO
        
        // TODO: figure out where to do this...right now we're also doing it in the `SKTilemap.handleMouseEvent(event:)` method.
        if let tiledScene = scene as? SKTiledScene {
            let locationInScene = event.location(in: tiledScene)
            let nodesUnderMouse = tiledScene.nodes(at: locationInScene).filter( { node in
                guard node.isHidden == false else {
                    return false
                }
                
                if let tiledNode = node as? TiledGeometryType {
                    if let _ = tiledNode as? TiledBackgroundLayer {
                        return false
                    }
                    
                    
                    if let tile = node as? SKTile {
                        if tile.object != nil {
                            return false
                        }
                    }
                    
                    return true
                }
                
                return false
            })
            
            // REFERENCE: these nodes are correct!
            NotificationCenter.default.post(
                name: Notification.Name.Demo.NodesRightClicked,
                object: nil,
                userInfo: ["nodes": nodesUnderMouse,
                           "windowPosition": event.locationInWindow,
                           "scenePosition": locationInScene]
            )
        }
        #endif
    }
    
    
    
    // MARK: - Movement Handlers
    
    /// Handler for mouse drag events.
    ///
    /// - Parameter event: mouse drag event.
    public func scenePositionChanged(with event: NSEvent) {
        guard (self.scene != nil) else {
            return
        }
        
        let location = event.location(in: self)
        if (lastLocation == nil) {
            lastLocation = location
        }
        
        
        if (allowMovement == true) {
            isMoving = true
            
            let difference = CGPoint(x: location.x - lastLocation.x, y: location.y - lastLocation.y)
            position = CGPoint(x: Int(position.x - difference.x), y: Int(position.y - difference.y))
            lastLocation = location
            
            /// notify delegates
            for delegate in delegates {
                
                // TODO: async operation
                delegate.cameraPositionChanged?(newPosition: position)
            }
        }
    }
    
    /// Handler for mouse drag events (with option modifier).
    ///
    /// - Parameter event: mouse drag event.
    public func sceneRotationChanged(with event: NSEvent) {
        let location = event.location(in: self)
        if (lastLocation == nil) {
            lastLocation = location
        }
        
        if (allowRotation == true) {
            let delta = event.delta
            zRotation += delta * rotationDamping
        }
    }
    #endif
}


// MARK: - Deprecations


extension SKTiledSceneCamera {
    
    /// Center & fit the current tilemap in the frame when the parent scene is resized.
    ///
    /// - Parameters:
    ///   - newSize: updated scene size.
    ///   - transition: transition time.
    ///   - verbose: logging verbosity.
    @available(*, deprecated, renamed: "SKTiledSceneCamera.fitToView(newSize:transition:)")
    public func fitToView(newSize: CGSize, transition: TimeInterval = 0, verbose: Bool = false) {
        fitToView(newSize: newSize, transition: transition)
    }
    
    #if os(iOS)
    /// Handler for double-tap gestures.
    ///
    /// - Parameter recognizer: tap gesture recognizer.
    @available(*, deprecated, renamed: "sceneDoubleTapAction(_:)")
    @objc public func sceneDoubleTapped(_ recognizer: UITapGestureRecognizer) {
        sceneDoubleTapAction(recognizer)
    }
    #endif
}
