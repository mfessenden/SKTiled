//
//  TileObjectOverlay.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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


/// Vector object proxy container overlay.
internal class TileObjectOverlay: SKNode {

    /// Allow the overlay to receive camera updates.
    @objc var receiveCameraUpdates: Bool = false

    /// Indicates the layer has been initialized.
    var initialized: Bool = false

    /// The current camera zoom level.
    var cameraZoom: CGFloat = 1.0
    
    /// Desired line width for each object.
    var lineWidth: CGFloat = TiledGlobals.default.debug.lineWidth
    
    /// Desired line width for each object.
    var minimumLineWidth: CGFloat = 0.1

    /// Dispatch queue.
    let renderQueue = DispatchQueue(label: "org.sktiled.tileObjectOverlay.renderQueue")
    
    /// Retina scaling value.
    let contentScale: CGFloat = TiledGlobals.default.contentScale
    
    override init() {
        super.init()
        isUserInteractionEnabled = false
        setupNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init()
        isUserInteractionEnabled = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
    }

    /// Returns objects at the given point.
    ///
    /// - Parameter point: point (in this node's coordinate space).
    /// - Returns: array of vector objects.
    func objectsAt(point: CGPoint) -> [SKTileObject] {
        let objects = nodes(at: point).compactMap { $0 as? TileObjectProxy }
        return objects.compactMap { $0.reference }
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
    }
    
    @objc func globalsUpdatedAction(notification: Notification) {
        lineWidth = TiledGlobals.default.debug.lineWidth
        draw()
    }
    
    func draw() {
        objects.forEach { object in
            object.zoomLevel = cameraZoom
            object.baseLineWidth = lineWidth
            object.draw()
        }
    }
}





// MARK: - Extensions


extension TileObjectOverlay: TiledSceneCameraDelegate {

    /// Called whenever the camera zoom changes.
    ///
    /// - Parameter newZoom: new camera zoom.
    @objc func cameraZoomChanged(newZoom: CGFloat) {
        //let oldZoom = cameraZoom
        cameraZoom = newZoom
        //let delta = cameraZoom - oldZoom
        //let newLineWidth = (newZoom != 0) ? lineWidth / newZoom : minimumLineWidth
        lineWidth = TiledGlobals.default.debug.lineWidth
        let isAntialiased = newZoom < 1
        weak var weakSelf = self
        renderQueue.async {
            for object in weakSelf!.objects {
                object.zoomLevel = newZoom
                object.baseLineWidth = self.lineWidth
                object.isAntialiased = isAntialiased
            }
        }
    }
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
    
    @objc var tiledDescription: String {
        return "Vector object proxy container overlay."
    }
}



extension TileObjectOverlay {

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
