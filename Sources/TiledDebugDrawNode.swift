//
//  SKTiledDebugDrawNode.swift
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


/// Sprite object for visualizaing grid & graph.
internal class TiledDebugDrawNode: SKNode {
    
    /// Parent layer.
    private weak var layer: TiledLayerObject?
    
    /// Indicates the object is the map's default layer.
    private var isDefault: Bool = false
    
    private var gridSprite: SKSpriteNode!
    private var graphSprite: SKSpriteNode!
    private var frameShape: SKShapeNode!
    
    private var gridTexture: SKTexture?                      // grid texture
    private var graphTexture: SKTexture?                     // GKGridGraph texture
    private var anchorKey: String = "ANCHOR"
    
    init(tileLayer: TiledLayerObject, isDefault def: Bool = false) {
        layer = tileLayer
        isDefault = def

        anchorKey = "ANCHOR_\(tileLayer.shortId)"
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        gridTexture = nil
        graphTexture = nil
    }
    
    var anchorPoint: CGPoint {
        guard let layer = layer else {
            return CGPoint(x: 0.5, y: 0.5)
        }
        return convert(layer.position, from: layer)
    }
    
    /// Debug visualization options.
    var debugDrawOptions: DebugDrawOptions? {
        return (isDefault == true) ? layer?.tilemap.debugDrawOptions : layer?.debugDrawOptions
    }
    
    /// Align with the parent layer.
    func setup() {
        guard let layer = layer else { return }
        
        let nodePrefix = (isDefault == true) ? "MAP" : layer.layerName.uppercased()
        let nodeName = "\(nodePrefix)_DEBUG_DRAW"
        name = nodeName
        
        // set the anchorpoints to 0,0 to match the frame
        gridSprite = SKSpriteNode(texture: nil, color: .clear, size: layer.sizeInPoints)
        gridSprite.anchorPoint = CGPoint.zero
        gridSprite.name = "\(nodePrefix)_GRID_DISPLAY"
        
        #if SKTILED_DEMO
        gridSprite.setAttrs(values: ["tiled-node-icon": "grid-icon", "tiled-node-nicename": "Grid Sprite", "tiled-node-listdesc": "Layer Grid Visualization", "tiled-node-desc": "Sprite containing layer grid visualization."])
        #endif
        
        addChild(gridSprite!)
        
        graphSprite = SKSpriteNode(texture: nil, color: .clear, size: layer.sizeInPoints)
        graphSprite.anchorPoint = CGPoint.zero
        graphSprite.name = "\(nodePrefix)_GRAPH_DISPLAY"
        
        
        #if SKTILED_DEMO
        graphSprite.setAttrs(values: ["tiled-node-icon": "graph-icon", "tiled-node-nicename": "Graph Sprite", "tiled-node-listdesc": "Layer Graph Visualization", "tiled-node-desc": "Sprite containing layer pathfinding graph visualization."])
        #endif
        
        addChild(graphSprite!)
        
        let frameShapeNode = SKShapeNode()
        frameShapeNode.name = "\(nodePrefix)_FRAME_DISPLAY"
        
        #if SKTILED_DEMO
        frameShapeNode.setAttrs(values: ["tiled-node-desc": "Debug visualization shape for the map or layer frame."])
        #endif
        
        addChild(frameShapeNode)
        frameShape = frameShapeNode
        frameShape.isUserInteractionEnabled = false
        graphSprite.isUserInteractionEnabled = false
        gridSprite.isUserInteractionEnabled = false
        isUserInteractionEnabled = false
        updateZPosition()
    }
    
    func updateZPosition() {
        guard let layer = layer else { return }
        
        let tilemap = layer.tilemap
        let zDeltaValue: CGFloat = tilemap.zDeltaForLayers
        
        // z-position values
        let startZposition = (isDefault == true) ? (tilemap.lastZPosition + zDeltaValue) : layer.zPosition
        
        // graph node visualization goes *under* the grid.
        graphSprite.zPosition = startZposition + zDeltaValue
        gridSprite.zPosition = startZposition + (zDeltaValue + 1)
        
        // bounding box goes on top
        frameShape.zPosition = startZposition + (zDeltaValue + 2)
    }
    
    /// Update the node with the various drawing options.
    func draw() {
        guard let _ = layer,
            let debugDrawOptions = debugDrawOptions else {
            return
        }
    
        
        DispatchQueue.main.async {
            self.isHidden = debugDrawOptions.isEmpty
            
            if debugDrawOptions.contains(.drawGrid) {
                self.drawGrid()
                self.gridSprite?.isUserInteractionEnabled = false
            } else {
                self.gridSprite?.isHidden = true
            }
            
            if debugDrawOptions.contains(.drawFrame) {
                self.drawBounds(withColor: nil, duration: 0)
            } else {
                self.frameShape?.isHidden = true
            }
            
            if debugDrawOptions.contains(.drawGraph) {
                self.drawGraph()
            } else {
                self.graphSprite?.isHidden = true
            }
            
            if debugDrawOptions.contains(.drawAnchor) {
                self.drawLayerAnchor()
            } else {
                self.childNode(withName: self.anchorKey)?.removeFromParent()
            }
            self.updateZPosition()
        }
    }
    
    /// Reset all visualizations.
    func reset() {
        gridSprite.texture = nil
        graphSprite.texture = nil
        childNode(withName: anchorKey)?.removeFromParent()
    }
    
    /// Visualize the layer's boundary shape.
    ///
    /// - Parameters:
    ///   - withColor: highlight color.
    ///   - duration: duration of effect.
    @objc func drawBounds(withColor: SKColor? = nil,
                          duration: TimeInterval = 0) {
        
        
        guard let layer = layer else {
            return
        }
        
        let fillColor = layer.tilemap.gridColor
        let objPath: CGPath!
        
        // query dimensions from the layer
        //let width = (isDefault == true) ? layer.tilemap.frame.size.width : layer.width
        //let height = (isDefault == true) ? layer.tilemap.frame.size.height : layer.height
        
        let width = layer.width
        let height = layer.height
        let tileSize = layer.tileSize

        
        switch layer.orientation {
            case .orthogonal:
                objPath = polygonPath(layer.boundingRect.points)
            
            case .isometric:

                let topPoint = CGPoint(x: 0, y: 0)
                let rightPoint = CGPoint(x: (width - 1) * tileSize.height + tileSize.height, y: 0)
                let bottomPoint = CGPoint(x: (width - 1) * tileSize.height + tileSize.height, y: (height - 1) * tileSize.height + tileSize.height)
                let leftPoint = CGPoint(x: 0, y: (height - 1) * tileSize.height + tileSize.height)
                
                let points: [CGPoint] = [
                    // point order is top, right, bottom, left
                    layer.pixelToScreenCoords(point: topPoint),
                    layer.pixelToScreenCoords(point: rightPoint),
                    layer.pixelToScreenCoords(point: bottomPoint),
                    layer.pixelToScreenCoords(point: leftPoint)
                ]
                
                // CONVERTED
                let invertedPoints = points.map { $0.invertedY }
                objPath = polygonPath(invertedPoints)
            
            case .hexagonal, .staggered:
                objPath = polygonPath(layer.boundingRect.points)
        }
        
        if let objPath = objPath {
            frameShape.path = objPath
            frameShape.isAntialiased = layer.antialiased
            frameShape.lineWidth = (layer.tileSize.halfHeight > 8) ? 1 : 0.5
            frameShape.lineJoin = .miter
            //frameShape.alpha = layer.gridOpacity * 3
            
            // don't draw bounds of hexagonal maps
            if (layer.orientation == .hexagonal) {
                //frameShape.strokeColor = SKColor.clear
            }
            
            frameShape.fillColor = SKColor.clear
        }
        
        isHidden = false
        //frameShape.fillColor = .white
        frameShape.strokeColor = fillColor
        frameShape.isHidden = false
        updateZPosition()
    }
    
    /// Display the current tile grid.
    func drawGrid() {
        guard let layer = layer else { return }
        
        let fillColor = layer.tilemap.gridColor
        
        if (gridTexture == nil) {
            gridSprite.isHidden = true
            
    
            // get the last z-position
            zPosition = layer.tilemap.lastZPosition + (layer.tilemap.zDeltaForLayers + 10)
            isHidden = false
            var gridSize = CGSize.zero
            
            // scale factor for texture
            let uiScale: CGFloat = TiledGlobals.default.contentScale
            
            // multipliers used to generate smooth lines
            let imageScale: CGFloat = layer.tilemap.renderQuality
            
            // line scale should be a multiple of 1
            let lineScale: CGFloat = (layer.tilemap.tileHeightHalf > 8) ? 2 : (layer.tilemap.tileHeightHalf > 4) ? 1 : 0.75
            
            // generate the texture
            if let gridImage = drawLayerGrid(layer, imageScale: imageScale, lineScale: lineScale) {
                gridTexture = SKTexture(cgImage: gridImage)

                gridTexture?.preload {
                    
                }
                
                gridTexture?.filteringMode = .nearest
                
                // sprite scaling factor
                let spriteScaleFactor: CGFloat = (1 / imageScale)
                gridSize = (gridTexture != nil) ? gridTexture!.size() / uiScale : .zero
                gridSprite.setScale(spriteScaleFactor)
                Logger.default.log("grid texture size: \(gridSize.shortDescription), bpc: \(gridImage.bitsPerComponent), line scale: \(lineScale), scale: \(imageScale), content scale: \(uiScale)", level: .debug, symbol: "SKTiledDebugDrawNode")
                
                gridSprite.texture = gridTexture
                gridSprite.alpha = layer.gridOpacity
                gridSprite.size = gridSize / imageScale
                gridSprite.zPosition = zPosition * 3

                
                // need to flip the grid texture in y
                // currently not doing this to the parent node so that objects will draw correctly.
                #if os(iOS) || os(tvOS)
                gridSprite.position.y = -layer.sizeInPoints.height
                #else
                gridSprite.yScale *= -1
                #endif
            } else {
                self.log("error drawing layer grid ( quality: \(imageScale) )", level: .error)
            }
        }
        
        gridSprite.color = fillColor
        gridSprite.colorBlendFactor = 0.5
        gridSprite.isHidden = false
    }
    
    /// Display the current tile graph (if it exists).
    func drawGraph() {
        guard let layer = layer else {
            return
        }
        
        // drawLayerGrid
        graphTexture = nil
        graphSprite.isHidden = true
        
        // get the last z-position
        zPosition = layer.tilemap.lastZPosition + (layer.tilemap.zDeltaForLayers - 10)
        isHidden = false
        var graphSize = CGSize.zero
        
        // scale factor for texture
        let uiScale: CGFloat = TiledGlobals.default.contentScale
        
        // multipliers used to generate smooth lines
        let imageScale: CGFloat = layer.tilemap.renderQuality
        let lineScale: CGFloat = (layer.tilemap.tileHeightHalf > 8) ? 2 : 1
        
        
        // generate the texture
        if (graphTexture == nil) {
            
            if let graphImage = drawLayerGraph(layer, imageScale: imageScale, lineScale: lineScale) {
                
                graphTexture = SKTexture(cgImage: graphImage)
                graphTexture?.filteringMode = .linear
                
                // sprite scaling factor
                let spriteScaleFactor: CGFloat = (1 / imageScale)
                graphSize = (graphTexture != nil) ? graphTexture!.size() / uiScale : .zero
                graphSprite.setScale(spriteScaleFactor)
                Logger.default.log("graph texture size: \(graphSize.shortDescription), bpc: \(graphImage.bitsPerComponent), scale: \(imageScale)", level: .debug)
                
                graphSprite.texture = graphTexture
                graphSprite.alpha = layer.gridOpacity * 3
                graphSprite.size = graphSize / imageScale
                graphSprite.zPosition = zPosition * 3
                
                #if os(macOS)
                // need to flip the graph texture in y
                graphSprite.yScale *= -1
                graphSprite.position.y = layer.sizeInPoints.height
                #endif
            }
        }
        graphSprite.isHidden = false
    }
    
    /// Visualize the layer's anchor point.
    func drawLayerAnchor() {
        let anchor = drawAnchor(self, withKey: anchorKey)
        anchor.name = anchorKey
        anchor.position = anchorPoint
    }
    
    // MARK: - Memory
    
    /// Flush large textures.
    func flush() {
        layer = nil
        gridSprite.texture = nil
        graphSprite.texture = nil
        gridTexture = nil
        graphTexture = nil
    }
}



// MARK: - Extensions

extension TiledDebugDrawNode: TiledCustomReflectableType {
    
    @objc var tiledNodeName: String {
        return "debugroot"
    }
    
    @objc var tiledNodeNiceName: String {
        return "Debug Draw Node"
    }
    
    @objc var tiledIconName: String {
        return "debug-icon"
    }
    
    @objc var tiledListDescription: String {
        var objName = ""
        if let objname = name {
            objName = ": '\(objname)'"
        }
        return "\(tiledNodeNiceName)\(objName)"
    }
    
    @objc var tiledDescription: String {
        return "Tilemap node debug visualization root."
    }
}




extension TiledDebugDrawNode {
    
    override var description: String {
        let objString = "<\(String(describing: Swift.type(of: self)))>"
        var attrsString = objString
        if let layer = layer {
            attrsString += " layer: '\(layer.layerName)'"
        }
        attrsString += " anchor: \(anchorPoint.shortDescription)"
        return attrsString
    }
    
    override var debugDescription: String {
        return description
    }
}
