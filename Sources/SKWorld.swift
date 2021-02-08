//
//  SKWorld.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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


/// :nodoc:
/// A Generic world container node.
public class SKWorld: SKNode, TiledSceneCameraDelegate {
    
    /// Allow the node to receive camera notifications.
    @objc public var receiveCameraUpdates: Bool = true
    
    /// Camera zoom level.
    public var zoom: CGFloat = 1.0
    
    /// Default initializer.
    public override init() {
        super.init()
        setupNotifications()
        name = "World"
    }
    
    /// Instantiate the node with a decoder instance.
    ///
    /// - Parameter aDecoder: decoder.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Setup notifications.
    func setupNotifications() {}
    
    /// Called when the camera position changes.
    ///
    /// - Parameter newPosition: updated camera position.
    public func cameraPositionChanged(newPosition: CGPoint) {}
    
    /// Called when the camera zoom changes.
    ///
    /// - Parameter newZoom: camera zoom amount.
    public func cameraZoomChanged(newZoom: CGFloat) {
        let currentZoom = zoom
        //let delta = newZoom - currentZoom
        zoom = newZoom
    }
}



/// :nodoc:
extension SKWorld: TiledCustomReflectableType {
    
    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "World Node"
    }
    
    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "world-icon"
    }
    
    /// A description of the node.
    @objc public var tiledListDescription: String {
        return "\(tiledNodeNiceName): pos: \(self.position.coordDescription)"
    }
    
    /// A description of the node.
    @objc public var tiledDescription: String {
        return "World container node."
    }
}
