//
//  TiledSceneCameraDelegate.swift
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


/**

 ## Overview

 Methods for interacting with the custom `SKTiledSceneCamera`. Classes conforming to this
 protocol are notified of camera position & zoom changes - unless the `SKTiledSceneCameraDelegate.receiveCameraUpdates`
 flag is disabled.

 ![Tiled Scene Camera Delegate][tiled-scene-camera-delegate-image]

 ### Properties

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
@objc public protocol SKTiledSceneCameraDelegate: AnyObject {

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
