//
//  TiledSceneCameraDelegate.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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


/// The `TiledSceneCameraDelegate` protocol defines methods for interacting with the custom `SKTiledSceneCamera` object. Classes conforming to this
/// protocol are notified of camera position & zoom changes unless the `TiledSceneCameraDelegate.receiveCameraUpdates`
/// flag is disabled.
///
/// This delegate also receives mouse & touch events and forwards them on to delegates accordingly.
///
/// ![Tiled Scene Camera Delegate][tiled-scene-camera-delegate-image]
///
/// ### Properties
///
///  - `receiveCameraUpdates`:  delegate will receive camera updates.
///  - `currentCoordinate`:  currently focused map coordinate.
///
/// ### Instance Methods
///
///  - `containedNodesChanged`: nodes visible in camera haved changed.
///  - `cameraPositionChanged`: camera position change.
///  - `cameraZoomChanged`: camera zoom change.
///  - `cameraBoundsChanged`: camera bounds updated.
///  - `leftMouseDown`: scene is clicked **(macOS only)**.
///  - `rightMouseDown`: scene is right-clicked **(macOS only)**.
///  - `leftMouseUp`: left mouse button is released **(macOS only)**.
///  - `rightMouseUp`: right mouse button is released **(macOS only)**.
///  - `leftMouseDoubleClicked`: scene is double-clicked **(macOS only)**.
///  - `mousePositionChanged`: mouse moves in the scene **(macOS only)**.
///  - `sceneDoubleTapped`: scene is double-tapped **(iOS only)**.
///  - `sceneRotated`: scene is rotated via gesture **(iOS only)**.
///
///
/// [tiled-scene-camera-delegate-image]:../images/camera-delegate.svg
@objc public protocol TiledSceneCameraDelegate: AnyObject {

    /// Allows the delegate to receive camera updates.
    @objc var receiveCameraUpdates: Bool { get set }

    /// Current focus coordinate.
    @objc optional var currentCoordinate: simd_int2 { get set }

    /// Allow delegates to receive updates when nodes in view change.
    ///
    /// - Parameter nodes: nodes visible in the current camera viewport.
    @objc optional func containedNodesChanged(_ nodes: Set<SKNode>)

    /// Called when the camera position changes.
    ///
    /// - Parameter newPosition: updated camera position.
    @objc optional func cameraPositionChanged(newPosition: CGPoint)

    /// Called when the camera zoom changes.
    ///
    /// - Parameter newZoom: camera zoom amount.
    @objc optional func cameraZoomChanged(newZoom: CGFloat)

    /// Called when the camera bounds are updated.
    ///
    /// - Parameters:
    ///   - bounds: camera view bounds.
    ///   - position: camera position.
    ///   - zoom: camera zoom amount.
    @objc optional func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat)
    
    /// Update delegates when camera attributes have changed.
    ///
    /// - Parameters:
    ///   - camera: camera node.
    ///   - attributes: camera attributes.
    @objc optional func cameraAttributesChanged(_ camera: SKTiledSceneCamera, attributes: [String: Any])

    #if os(macOS)

    /// Called when the scene is clicked **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc optional func leftMouseDown(event: NSEvent)
    
    /// Called when the left mouse button is released **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc optional func leftMouseUp(event: NSEvent)
    
    /// Called when the scene is right-clicked **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc optional func rightMouseDown(event: NSEvent)
    
    /// Called when the right mouse button is released **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc optional func rightMouseUp(event: NSEvent)
    
    /// Called when the scene is double-clicked **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc optional func leftMouseDoubleClicked(event: NSEvent)
    
    /// Called when the right mouse button is released **(macOS only)**.
    ///
    /// - Parameter event: mouse click event.
    @objc optional func sceneRightClickReleased(event: NSEvent)

    /// Called when the mouse moves in the scene **(macOS only)**.
    ///
    /// - Parameter event: mouse move event.
    @objc optional func mousePositionChanged(event: NSEvent)
    
    #endif

    #if os(iOS)

    /// Called when the scene receives a double-tap event (iOS only).
    ///
    /// - Parameter location: touch event location.
    @objc optional func sceneDoubleTapped(location: CGPoint)

    /// Called when the current scene has been rotated.
    ///
    /// - Parameters:
    ///   - new: new rotation value.
    ///   - old: previous rotation value.
    @objc optional func sceneWasRotated(new: CGFloat, old: CGFloat)
    #endif
}



/// :nodoc: Typealias for v1.2 compatibility.
@available(*, deprecated, renamed: "TiledSceneCameraDelegate")
public typealias SKTiledSceneCameraDelegate = TiledSceneCameraDelegate



// MARK: - Renamed/Deprecated


