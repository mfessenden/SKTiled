//
//  TileObjectProxy.swift
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


/// Vector object proxy.
internal class TileObjectProxy: SKShapeNode {
    
    /// Parent container.
    weak var container: TileObjectOverlay?
    
    /// Referenced vector object.
    weak var reference: SKTileObject?
    
    /// Node is visible to the camera.
    var visibleToCamera: Bool = false
    
    /// Indicates this node is renderable.
    var isRenderable: Bool = false
    
    /// Proxy animation key.
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
    var _baseLineWidth: CGFloat = TiledGlobals.default.debugDisplayOptions.lineWidth
    
    /// Represents the line width at the current zoom level.
    var baseLineWidth: CGFloat {
        get {
            return _baseLineWidth / zoomLevel
        } set {
            _baseLineWidth = newValue
            self.draw()
        }
    }
    
    /// Toggle proxy drawing.
    var showObjects: Bool = false {
        didSet {
            self.draw()
        }
    }
    
    /// Governs the color of each proxy object.
    var objectColor: SKColor = TiledGlobals.default.debugDisplayOptions.objectHighlightColor {
        didSet {
            guard objectColor != oldValue else {
                return
            }
            
            self.draw()
        }
    }
    
    /// Governs the fill color opacity of each proxy object.
    var fillOpacity: CGFloat = TiledGlobals.default.debugDisplayOptions.objectFillOpacity {
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
                print("⭑ [TileObjectProxy]: is focused: \(isFocused)")
                self.draw()
            }
        }
    }
    
    /// Initialize with an object reference.
    ///
    /// - Parameters:
    ///   - object: reference object.
    ///   - visible: obejct is initially visible.
    ///   - renderable: object is renderable.
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
        
        // FIXME: this is causing selected object frame to disappear (but leave anchor)
        let proxyIsVisible = (showObjects == true) || (isFocused == true)
        
        self.removeAction(forKey: self.animationKey)
        
        guard let object = reference,
              let _ = object.layer else {
            self.path = nil
            return
        }
        
        // don't draw text objects in iso, hex, staggered (for now)
        if object.layer.orientation != .orthogonal {
            if (object.objectType == .text) {
                self.path = nil
                return
            }
        }
        
        
        // FIXME: crash here
        
        let vertices = object.translatedVertices()
        guard (vertices.count > 2) else {
            self.path = nil
            return
        }
        
        // reset scale
        self.setScale(1)
        
        // FIXME: crash here
        let convertedPoints = vertices.map {
            self.convert($0, from: object)
        }
        
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
            
            
            if objPath.isEmpty == true {
                return
            }
            
            // FIXME: crash here
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
    
    @objc override var tiledHelpDescription: String {
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
