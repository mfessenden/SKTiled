//
//  TileObjectProxy.swift
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



/// Vector object proxy.
internal class TileObjectProxy: SKShapeNode {
    
    /// Parent container.
    weak var container: TileObjectOverlay?
    
    /// Referenced vector object.
    weak var reference: SKTileObject?
    
    /// Node is visible to the camera.
    var visibleToCamera: Bool = false
    
    var isRenderable: Bool = false
    
    var animationKey: String = "proxy"
    
    // Current camera zoom.
    var zoomLevel: CGFloat = 1 {
        didSet {
            guard (oldValue != zoomLevel) else {
                return
            }
            
            // FIXME: crash here
            self.draw()
        }
    }
    
    /// Internal line width.
    var _baseLineWidth: CGFloat = TiledGlobals.default.debug.lineWidth
    
    /// Represents the line width at the current zoom level.
    var baseLineWidth: CGFloat {
        get {
            return _baseLineWidth / zoomLevel
        } set {
            _baseLineWidth = newValue
            self.draw()
        }
    }
    
    var showObjects: Bool = false {
        didSet {
            self.draw()
        }
    }
    
    var objectColor: SKColor = TiledGlobals.default.debug.objectHighlightColor {
        didSet {
            self.draw()
        }
    }
    
    var fillOpacity: CGFloat = TiledGlobals.default.debug.objectFillOpacity {
        didSet {
            self.draw()
        }
    }
    
    /// TODO: remember to use this!!
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
    
    required init(object: SKTileObject,
                  visible: Bool = false,
                  renderable: Bool = false) {
        
        self.reference = object
        super.init()
        self.animationKey = "highlight-proxy-\(object.id)"
        self.name = "proxy-\(object.id)"
        object.proxy = self
        showObjects = visible
        isRenderable = renderable
        
        // grab proxy color overrides
        let parentProxyColor = object.layer.proxyColor ?? object.proxyColor
        if let proxyColor = parentProxyColor {
            objectColor = proxyColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
    }
    
    /// Draw the objects in the overlay.
    public func draw() {
        
        let proxyIsVisible = (showObjects == true) || (isFocused == true)
        
        self.removeAction(forKey: self.animationKey)
        
        guard let object = reference,
              let _ = object.layer else {
            self.path = nil
            return
        }
        
        
        // FIXME: crash here
        
        let vertices = object.translatedVertices()
        guard (vertices.count > 0) else {
            self.path = nil
            return
        }
        
        
        // reset scale
        self.setScale(1)
        
        let convertedPoints = vertices.map {
            self.convert($0, from: object)
        }
        
        //let scaleFactor = CGPoint(x: 1 / object.xScale, y: 1 / object.yScale)
        //xScale = scaleFactor.x
        //yScale = scaleFactor.y
        
        let renderQuality = TiledGlobals.default.renderQuality.object
        let objectRenderQuality = renderQuality / 2
        
        if (convertedPoints.isEmpty == false) {
            
            let scaledVertices = convertedPoints.map { $0 * renderQuality }
            
            let objPath: CGPath
            switch object.shapeType {
                
                case .ellipse:
                    objPath = bezierPath(scaledVertices, closed: true, alpha: object.shapeType.curvature).path
                    
                default:
                    objPath = polygonPath(scaledVertices, closed: true)
            }
            
            self.path = objPath
            self.setScale(1 / renderQuality)
            
            
            let currentStrokeColor = (proxyIsVisible == true) ? self.objectColor : SKColor.clear
            let currentFillColor = (proxyIsVisible == true) ? (isRenderable == false) ? currentStrokeColor.withAlphaComponent(fillOpacity) : SKColor.clear : SKColor.clear
            
            self.strokeColor = currentStrokeColor
            self.fillColor = currentFillColor
            self.lineWidth = baseLineWidth * objectRenderQuality
            self.isAntialiased = false
        }
    }
}


// MARK: - Extensions


/// :nodoc:
extension TileObjectProxy {
    
    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return "Object Proxy"
    }
    
    @objc override var tiledIconName: String {
        return "proxy-icon"
    }
    
    @objc override var tiledListDescription: String {
        var refString = ""
        if let refobj = reference {
            refString = ": object id: \(refobj.id)"
        }
        return "Proxy\(refString)"
    }
    
    @objc override var tiledDescription: String {
        return "Tile object proxy node."
    }
}


extension TileObjectProxy {
    
    public override var description: String {
        let objString = "<\(String(describing: Swift.type(of: self)))>"
        var attrsString = objString
        if let object = reference {
            attrsString += " object: \(object.id)"
        }
        return attrsString
    }
    
    public override var debugDescription: String {
        return description
    }
}
