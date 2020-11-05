//
//  TileObjectProxy.swift
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


/// Vector object proxy.
internal class TileObjectProxy: SKShapeNode, SKTiledGeometry {
    
    /// Parent container.
    weak var container: TileObjectOverlay?
    
    /// Referenced vector object.
    weak var reference: SKTileObject?
    
    /// Node is visible to the camera.
    var visibleToCamera: Bool = false
    
    var isRenderable: Bool = false
    
    var animationKey: String = "proxy"

    var showObjects: Bool = false {
        didSet {
            self.draw()
        }
    }

    var objectColor = TiledGlobals.default.debug.objectHighlightColor {
        didSet {
            self.draw()
        }
    }

    var fillOpacity = TiledGlobals.default.debug.objectFillOpacity {
        didSet {
            self.draw()
        }
    }

    var isFocused: Bool = false {
        didSet {
            guard (oldValue != isFocused) else { return }
            removeAction(forKey: animationKey)
            if (isFocused == false) && (showObjects == false) {
                let fadeAction = SKAction.colorFadeAction(after: 0.5)
                self.run(fadeAction, withKey: animationKey)
            } else {
                self.draw()
            }
        }
    }

    required init(object: SKTileObject, visible: Bool = false, renderable: Bool = false) {
        self.reference = object
        super.init()
        self.animationKey = "highlight-proxy-\(object.id)"
        self.name = "proxy-\(object.id)"
        object.proxy = self
        showObjects = visible
        isRenderable = renderable
    }

    required init?(coder aDecoder: NSCoder) {
        super.init()
    }

    func draw(debug: Bool = false) {

        let showFocused = TiledGlobals.default.debug.mouseFilters.contains(.objectsUnderCursor)
        let proxyIsVisible = (showObjects == true) || (isFocused == true && showFocused == true)

        self.removeAction(forKey: self.animationKey)
        guard let object = reference,
            let vertices = object.translatedVertices() else {
                self.path = nil
                return
        }

        // reset scale
        self.setScale(1)

        let convertedPoints = vertices.map {
            self.convert($0, from: object)
        }

        let renderQuality = TiledGlobals.default.renderQuality.object
        let objectRenderQuality = renderQuality / 2

        if (convertedPoints.isEmpty == false) {

            let scaledVertices = convertedPoints.map { $0 * renderQuality }

            let objectPath: CGPath
            switch object.shapeType {
                case .ellipse:
                    objectPath = bezierPath(scaledVertices, closed: true, alpha: object.shapeType.curvature).path
                default:
                    objectPath = polygonPath(scaledVertices, closed: true)
            }

            self.path = objectPath
            self.setScale(1 / renderQuality)


            let currentStrokeColor = (proxyIsVisible == true) ? self.objectColor : SKColor.clear
            let currentFillColor = (proxyIsVisible == true) ? (isRenderable == false) ? currentStrokeColor.withAlphaComponent(fillOpacity) : SKColor.clear : SKColor.clear

            self.strokeColor = currentStrokeColor
            self.fillColor = currentFillColor
            self.lineWidth = objectRenderQuality
        }
    }
}


// MARK: - Extensions


extension TileObjectProxy {

    override var description: String {
        guard let object = reference else {
            return "Object Proxy: nil"
        }
        return "Object Proxy: \(object.id)"
    }

    override var debugDescription: String {
        return description
    }
}
