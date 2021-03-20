//
//  TileObjectOverlay.swift
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
#if os(macOS)
import Cocoa
#endif


/// Vector object proxy container overlay.
internal class TileObjectOverlay: SKNode {

    /// Allow the overlay to receive camera updates.
    @objc var receiveCameraUpdates: Bool = false

    /// Indicates the layer has been initialized.
    var initialized: Bool = false

    /// The current camera zoom level.
    var cameraZoom: CGFloat = 1.0
    
    /// Desired line width for each object.
    var lineWidth: CGFloat = TiledGlobals.default.debugDisplayOptions.lineWidth
    
    /// Desired line width for each object.
    var minimumLineWidth: CGFloat = 0.1

    /// Dispatch queue.
    let renderQueue = DispatchQueue(label: "org.sktiled.tileObjectOverlay.renderQueue")
    
    /// Retina scaling value.
    let contentScale: CGFloat = TiledGlobals.default.contentScale
    
    // MARK: - Initialization
    
    /// Default initializer.
    override init() {
        super.init()
        isUserInteractionEnabled = false
        setupNotifications()
    }

    /// Instantiate the node with a decoder instance.
    ///
    /// - Parameter aDecoder: decoder.
    required init?(coder aDecoder: NSCoder) {
        super.init()
        isUserInteractionEnabled = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.Updated, object: nil)
        self.destroy()
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(mapUpdatedAction), name: Notification.Name.Map.Updated, object: nil)
    }

    /// Returns objects at the given point in the overlay.
    ///
    /// - Parameter point: point (in this node's coordinate space).
    /// - Returns: array of vector objects.
    func objectsAt(point: CGPoint) -> [SKTileObject] {
        let objects = nodes(at: point).compactMap { $0 as? TileObjectProxy }
        return objects.compactMap { $0.reference }
    }
    
    /// Called when the `Notification.Name.Map.Updated` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func mapUpdatedAction(notification: Notification) {
        draw()
    }
    
    /// Called when the `Notification.Name.Globals.Updated` event fires.
    ///
    /// - Parameter notification: event notification.
    @objc func globalsUpdatedAction(notification: Notification) {
        lineWidth = TiledGlobals.default.debugDisplayOptions.lineWidth
        draw()
    }
    
    /// Redraw the overlay.
    @objc func draw() {
        objects.forEach { proxy in
            proxy.zoomLevel = cameraZoom
            proxy.baseLineWidth = lineWidth
            // object.reference?.tintColor
            proxy.draw()
        }
    }
}


// MARK: - Extensions


extension TileObjectOverlay: TiledSceneCameraDelegate {

    /// Called whenever the camera zoom changes.
    ///
    /// - Parameter newZoom: new camera zoom.
    @objc func cameraZoomChanged(newZoom: CGFloat) {
        let oldZoom = cameraZoom
        cameraZoom = newZoom
        
        // only redraw if zoom has changed more than 0.15
        let delta = cameraZoom - oldZoom
        guard delta > 0.15 else {
            return
        }
        
        //let newLineWidth = (newZoom != 0) ? lineWidth / newZoom : minimumLineWidth
        
        let isZoomedIn = newZoom > 1
        
        // at less than 1, number is higher (0.7 zoom = 1.3 padding, 5.0 zoom = 0.2 padding)
        let zoomLineWidthPadding: CGFloat = (isZoomedIn == true) ? 1.0 / newZoom : 2.0 / newZoom
        let newZoomedLineWidth = TiledGlobals.default.debugDisplayOptions.lineWidth + zoomLineWidthPadding
        lineWidth = newZoomedLineWidth
        let isAntialiased = newZoom < 1
        weak var weakSelf = self
        renderQueue.async {
            for proxy in weakSelf!.objects {
                proxy.zoomLevel = newZoom
                proxy.baseLineWidth = self.lineWidth
                proxy.isAntialiased = isAntialiased
            }
        }
    }
    
    #if os(macOS)
    
    /// Called when a mouse click event is passed to the overlay.
    ///
    /// - Parameter event: mouse event
    @objc func sceneClicked(event: NSEvent) {
        let clickedProxies = nodes(at: event.location(in: self)).filter { $0 as? TileObjectProxy != nil} as! [TileObjectProxy]
        
        // TODO: dispatch here?
        for proxy in clickedProxies {
            
            /// calls `Notification.Name.Demo.ObjectClicked` event. Handled by `GameViewController.objectUnderMouseClicked`.
            
            /// muting this now as it's in the `SKTilemap.handleMouseEvent`
            if let referringObject = proxy.reference {
                referringObject.mouseDown(with: event)
            }
        }
    }
    #endif
}


/// :nodoc:
extension TileObjectOverlay: TiledCustomReflectableType {

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "Overlay Node"
    }
    
    @objc var tiledIconName: String {
        return "overlay-icon"
    }
    
    
    @objc var tiledListDescription: String {
        let objCount = objects.count
        let objCountString = (objCount > 0) ? (objCount > 1) ? "\(objCount) objects" : "1 object" : "no objects"
        return "Map Overlay: (\(objCountString))"
    }
    
    @objc var tiledHelpDescription: String {
        return "Vector object proxy container overlay."
    }
}



extension TileObjectOverlay {

    /// Returns an array of contained object proxies.
    internal var objects: [TileObjectProxy] {
        let proxies = children.filter { $0 as? TileObjectProxy != nil }
        return proxies as? [TileObjectProxy] ?? [TileObjectProxy]()
    }

    override var description: String {
        let objString = "<\(String(describing: Swift.type(of: self)))>"
        var attrsString = objString
        attrsString += " objects: \(objects.count)"
        attrsString += " zoom level: \(cameraZoom.stringRoundedTo())"
        return attrsString
    }
}
