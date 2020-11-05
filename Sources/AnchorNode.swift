//
//  AnchorNode.swift
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


/// Anchor point visualization.
internal class AnchorNode: SKNode {
    
    var radius: CGFloat = 0
    var color: SKColor = SKColor.clear
    var labelText = "Anchor"
    var labelSize: CGFloat = 18.0
    var renderQuality: CGFloat = TiledGlobals.default.renderQuality.default
    
    var labelOffsetX: CGFloat = 0
    var labelOffsetY: CGFloat = 0
    
    var receiveCameraUpdates: Bool = true
    
    private var shapeKey = "ANCHOR_SHAPE"
    private var labelKey = "ANCHOR_LABEL"
    
    var sceneScale: CGFloat = 1
    
    private var shape: SKShapeNode? {
        return childNode(withName: shapeKey) as? SKShapeNode
    }
    private var label: SKLabelNode? {
        return childNode(withName: labelKey) as? SKLabelNode
    }
    
    init(radius: CGFloat, color shapeColor: SKColor, label text: String? = nil, offsetX: CGFloat = 0, offsetY: CGFloat = 0, zoom: CGFloat = 1) {
        self.radius = radius
        self.color = shapeColor
        self.labelOffsetX = offsetX
        self.labelOffsetY = offsetY
        self.sceneScale = zoom
        super.init()
        self.labelText = text ?? ""
        self.name = "ANCHOR"
        self.draw()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func draw() {
        shape?.removeFromParent()
        label?.removeFromParent()
        
        
        //let sceneScaleInverted = (sceneScale > 1) ? abs(1 - sceneScale) : sceneScale
        let scaledRenderQuality = renderQuality * sceneScale
        
        let minRadius: CGFloat = 4.0
        let maxRadius: CGFloat = 8.0
        var zoomedRadius = (radius / sceneScale)
        
        // clamp the anchor radius to min/max values
        zoomedRadius = (zoomedRadius > maxRadius) ? maxRadius : (zoomedRadius < minRadius) ? minRadius : zoomedRadius
        
        // debugging
        //let clampedString = (isClampedAtMin == true || isClampedAtMax == true) ? " (clamped)" : ""
        //let outputString = " - radius: \(zoomedRadius.roundTo(1)) -> \(radius.roundTo())"
        
        let scaledFontSize = (labelSize * renderQuality) * sceneScale
        let scaledOffsetX = (labelOffsetX / sceneScale)
        let scaledOffsetY = (labelOffsetY / sceneScale)
        
        let anchor = SKShapeNode(circleOfRadius: zoomedRadius)
        anchor.name = shapeKey
        addChild(anchor)
        anchor.fillColor = color
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = parent?.zPosition ?? 100
        
        // label
        let nameLabel = SKLabelNode(fontNamed: "Courier")
        nameLabel.name = labelKey
        nameLabel.text = labelText
        nameLabel.fontSize = scaledFontSize
        anchor.addChild(nameLabel)
        nameLabel.zPosition = anchor.zPosition + 1
        nameLabel.position.x += scaledOffsetX
        nameLabel.position.y += scaledOffsetY
        nameLabel.setScale(1.0 / scaledRenderQuality)
        nameLabel.color = .white
    }
}


// MARK: - Extensions


extension AnchorNode: SKTiledSceneCameraDelegate {
    
    func cameraZoomChanged(newZoom: CGFloat) {
        if (newZoom != sceneScale) {
            sceneScale = newZoom
            draw()
        }
    }
}


