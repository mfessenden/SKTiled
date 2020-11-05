//
//  TiledDebugDrawNode.swift
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


/// Sprite object for visualizaing grid & graph.
internal class SKTiledDebugDrawNode: SKNode {

    private var layer: SKTiledLayerObject                     // parent layer
    private var isDefault: Bool = false                       // is the tilemap default layer

    private var gridSprite: SKSpriteNode!
    private var graphSprite: SKSpriteNode!
    private var frameShape: SKShapeNode!

    private var gridTexture: SKTexture?                      // grid texture
    private var graphTexture: SKTexture?                     // GKGridGraph texture
    private var anchorKey: String = "ANCHOR"

    init(tileLayer: SKTiledLayerObject, isDefault def: Bool = false) {
        layer = tileLayer
        isDefault = def
        anchorKey = "ANCHOR_\(layer.uuid)"
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
        return convert(layer.position, from: layer)
    }

    /// Debug visualization options.
    var debugDrawOptions: DebugDrawOptions {
        return (isDefault == true) ? layer.tilemap.debugDrawOptions : layer.debugDrawOptions
    }

    /**
     Align with the parent layer.
     */
    func setup() {
        let nodeName = (isDefault == true) ? "MAP_DEBUG_DRAW" : "\(layer.layerName.uppercased())_DEBUG_DRAW"
        name = nodeName

        // set the anchorpoints to 0,0 to match the frame
        gridSprite = SKSpriteNode(texture: nil, color: .clear, size: layer.sizeInPoints)
        gridSprite.anchorPoint = CGPoint.zero
        addChild(gridSprite!)

        graphSprite = SKSpriteNode(texture: nil, color: .clear, size: layer.sizeInPoints)
        graphSprite.anchorPoint = CGPoint.zero
        addChild(graphSprite!)

        frameShape = SKShapeNode()
        addChild(frameShape!)
        //updateZPosition()
    }

    func updateZPosition() {
        let tilemap = layer.tilemap
        let zDeltaValue: CGFloat = tilemap.zDeltaForLayers

        // z-position values
        let startZposition = (isDefault == true) ? (tilemap.lastZPosition + zDeltaValue) : layer.zPosition

        graphSprite!.zPosition = startZposition + zDeltaValue
        gridSprite!.zPosition = startZposition + (zDeltaValue + 10)
        frameShape!.zPosition = startZposition + (zDeltaValue + 20)
    }

    /**
     Update the node with the various options.
     */
    func draw() {
        DispatchQueue.main.async {
            self.isHidden = self.debugDrawOptions.isEmpty
            if self.debugDrawOptions.contains(.drawGrid) {
                self.drawGrid()
            } else {
                self.gridSprite?.isHidden = true
            }

            if self.debugDrawOptions.contains(.drawBounds) {
                self.drawBounds()
            } else {
                self.frameShape?.isHidden = true
            }

            if self.debugDrawOptions.contains(.drawGraph) {
                self.drawGraph()
            } else {
                self.graphSprite?.isHidden = true
            }

            if self.debugDrawOptions.contains(.drawAnchor) {
                self.drawLayerAnchor()
            } else {
                self.childNode(withName: self.anchorKey)?.removeFromParent()
            }
            self.updateZPosition()
        }
    }

    /**
     Reset all visualizations.
     */
    func reset() {
        gridSprite.texture = nil
        graphSprite.texture = nil
        childNode(withName: anchorKey)?.removeFromParent()
    }

    /**
     Visualize the layer's boundary shape.
     */
    func drawBounds() {
        let objectPath: CGPath!

        // grab dimensions from the layer
        let width = layer.width
        let height = layer.height
        let tileSize = layer.tileSize

        switch layer.orientation {
            case .orthogonal:
                objectPath = polygonPath(layer.bounds.points)

            case .isometric:
                let topPoint = CGPoint(x: 0, y: 0)
                let rightPoint = CGPoint(x: (width - 1) * tileSize.height + tileSize.height, y: 0)
                let bottomPoint = CGPoint(x: (width - 1) * tileSize.height + tileSize.height, y: (height - 1) * tileSize.height + tileSize.height)
                let leftPoint = CGPoint(x: 0, y: (height - 1) * tileSize.height + tileSize.height)

                let points: [CGPoint] = [
                    // point order is top, right, bottom, left
                    layer.pixelToScreenCoords(topPoint),
                    layer.pixelToScreenCoords(rightPoint),
                    layer.pixelToScreenCoords(bottomPoint),
                    layer.pixelToScreenCoords(leftPoint)
                ]

                let invertedPoints = points.map { $0.invertedY }
                objectPath = polygonPath(invertedPoints)

            case .hexagonal, .staggered:
                objectPath = polygonPath(layer.bounds.points)
        }

        if let objectPath = objectPath {
            frameShape.path = objectPath
            frameShape.isAntialiased = layer.antialiased
            frameShape.lineWidth = (layer.tileSize.halfHeight > 8) ? 2 : 0.75
            frameShape.lineJoin = .miter

            // don't draw bounds of hexagonal maps
            frameShape.strokeColor = layer.frameColor
            frameShape.alpha = layer.gridOpacity * 3

            if (layer.orientation == .hexagonal) {
                frameShape.strokeColor = SKColor.clear
            }

            frameShape.fillColor = SKColor.clear
        }

        isHidden = false
        frameShape.isHidden = false
    }

    /// Display the current tile grid.
    func drawGrid() {
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
            if let gridImage = drawLayerGrid(self.layer, imageScale: imageScale, lineScale: lineScale) {
                gridTexture = SKTexture(cgImage: gridImage)
                gridTexture?.filteringMode = .linear

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
                self.log("error drawing layer grid.", level: .error)
            }
        }
        gridSprite.isHidden = false
    }

    /// Display the current tile graph (if it exists).
    func drawGraph() {

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

            if let graphImage = drawLayerGraph(self.layer, imageScale: imageScale, lineScale: lineScale) {

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

                // need to flip the graph texture in y
                // currently not doing this to the parent node so that objects will draw correctly.
                #if os(iOS) || os(tvOS)
                graphSprite.position.y = -layer.sizeInPoints.height
                #else
                graphSprite.yScale *= -1
                #endif

            }
        }
        graphSprite.isHidden = false
    }

    /**
     Visualize the layer's anchor point.
     */
    func drawLayerAnchor() {
        let anchor = drawAnchor(self, withKey: anchorKey)
        anchor.name = anchorKey
        anchor.position = anchorPoint
    }

    // MARK: - Memory

    /**
     Flush large textures.
     */
    func flush() {
        gridSprite.texture = nil
        graphSprite.texture = nil
        gridTexture = nil
        graphTexture = nil
    }
}



// MARK: - Extensions

/// :nodoc:
extension SKTiledDebugDrawNode: CustomReflectable {
    
    var customMirror: Mirror {
        return Mirror(reflecting: SKTiledDebugDrawNode.self)
    }
    
    override var description: String {
        return "Debug Draw Node: \(layer.layerName)"
    }
    
    override var debugDescription: String {
        return description
    }
}
