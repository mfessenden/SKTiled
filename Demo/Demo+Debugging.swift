//
//  Demo+Debugging.swift
//  SKTiled
//
//  Created by Michael Fessenden on 8/17/17.
//  Copyright © 2017 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit




extension SKTiledDemoScene {
    /**
     Run demo keyboard events (macOS).

     - parameter eventKey: `UInt16` event key.

     */
    public func keyboardEvent(eventKey: UInt16) {
        guard let view = view,
            let cameraNode = cameraNode,
            let tilemap = tilemap,
            let worldNode = worldNode else {
                return
        }

        // 'a' or 'f' fits the map to the current view
        if eventKey == 0x0 || eventKey == 0x3 {
            cameraNode.fitToView(newSize: view.bounds.size)
        }

        // 'c' clamps the tilemap
        if eventKey == 0x8 {
            tilemap.clampPositionForMap()
        }


        // 'd' shows/hides debug view
        if eventKey == 0x02 {
            // no command
        }

        // 'h' shows/hides the HUD
        if eventKey == 0x04 {
            if let view = self.view {
                let debugState = !view.showsFPS
                view.showsFPS = debugState
                view.showsNodeCount = debugState
                view.showsDrawCount = debugState
                view.showsPhysics = debugState
                view.showsFields = debugState
            }
        }


        // 'j' fades the layers in succession
        if eventKey == 0x26 {
            var fadeTime: TimeInterval = 3
            let additionalTime: TimeInterval = (tilemap.layerCount > 6) ? 1.25 : 2.25
            for layer in tilemap.getContentLayers() {
                let fadeAction = SKAction.fadeAfter(wait: fadeTime, alpha: 0)
                layer.run(fadeAction)
                fadeTime += additionalTime
            }
        }

        // 'k' updates the render quality
        if eventKey == 0x28 {
            if tilemap.renderQuality < 16 {
                tilemap.renderQuality *= 2
            }
        }

        // 'l' toggles object & tile bounds drawing
        if eventKey == 0x25 {
        }

        // 'm' just shows the map bounds
        if eventKey == 0x2e {
            // if objects are shown...
            tilemap.defaultLayer.debugDrawOptions = (tilemap.defaultLayer.debugDrawOptions != []) ? [] : .drawBounds
            log("tilemap debug options: \(tilemap.debugDrawOptions)", level: .debug)
        }

        // 'o' shows/hides object layers
        if eventKey == 0x1f {
            tilemap.showObjects = !tilemap.showObjects
        }

        // 'p' pauses the scene
        if eventKey == 0x23 {
            self.isPaused = !self.isPaused
        }

        // '←' advances to the next scene
        if eventKey == 0x7B {
            self.loadPreviousScene()
        }

        // '1' zooms to 100%
        if eventKey == 0x12 || eventKey == 0x53 {
            cameraNode.resetCamera()
        }

        // '2' zooms to 200%
        if eventKey == 0x13 || eventKey == 0x54 {
            cameraNode.resetCamera(toScale: 2)
        }


        // 'clear' clears TileShapes
        if eventKey == 0x47 {
            self.enumerateChildNodes(withName: "*") { node, _ in

                if let tile = node as? TileShape {
                    tile.removeFromParent()
                }
            }
        }

        // MARK: - DEBUGGING TESTS
        // TODO: get rid of these in master

        // 'g' shows the grid for the map default layer.
        if eventKey == 0x5 {
            tilemap.debugDrawOptions = (tilemap.debugDrawOptions.contains(.drawGrid)) ? tilemap.debugDrawOptions.subtracting(.drawGrid) : tilemap.debugDrawOptions.insert(.drawGrid).memberAfterInsert
        }

        // 'i' shows the center point of each tile
        if eventKey == 0x22 {
            var fadeTime: TimeInterval = 3
            let shapeRadius = (tilemap.tileHeightHalf / 4) - 0.5
            for x in 0..<Int(tilemap.size.width) {
                for y in 0..<Int(tilemap.size.height) {

                    let shape = SKShapeNode(circleOfRadius: shapeRadius)
                    shape.alpha = 0.7
                    shape.fillColor = SKColor(hexString: "#FD4444")
                    shape.strokeColor = .clear
                    worldNode.addChild(shape)

                    let shapePos = tilemap.defaultLayer.pointForCoordinate(x, y)
                    shape.position = worldNode.convert(shapePos, from: tilemap.defaultLayer)
                    shape.zPosition = tilemap.lastZPosition + tilemap.zDeltaForLayers

                    let fadeAction = SKAction.fadeAfter(wait: fadeTime, alpha: 0)
                    shape.run(fadeAction, completion: {
                        shape.removeFromParent()
                    })
                    fadeTime += 0.003

                }
                fadeTime += 0.02
            }
        }

        // 'n' writes the map to image files
        if eventKey == 0x2d {
            let mapname = tilemap.url.path.basename
            guard let url = createTempDirectory(named: mapname) else {
                Logger.default.log("error creating directory.", level: .error)
                return
            }
            #if os(macOS)
            writeMapToFiles(tilemap: tilemap, url: url)
            #endif
        }

        // 'q' tries to show all object bounds
        if eventKey == 0xc {
            worldNode.childNode(withName: "ROOT")?.removeFromParent()

            let root = SKNode()
            root.name = "ROOT"

            let renderQuality: CGFloat = 16

            enumerateChildNodes(withName: "//*") { node, _ in


                if let shape = node as? SKTileObject {

                    if let vertices = shape.getVertices() {

                        let flippedVertices = (shape.gid == nil) ? vertices.map { $0.invertedY } : vertices
                        let worldVertices = flippedVertices.map { self.worldNode.convert($0, from: shape) }

                        let scaledVertices = worldVertices.map { $0 * renderQuality }


                        let translatedPath = polygonPath(scaledVertices)
                        let bounds = SKShapeNode(path: translatedPath)


                        // draw the path
                        bounds.isAntialiased = true
                        bounds.lineCap = .round
                        bounds.lineJoin = .miter
                        bounds.miterLimit = 0
                        bounds.lineWidth = 1 * (renderQuality / 2)

                        bounds.fillColor = .clear
                        bounds.strokeColor = .green
                        root.addChild(bounds)
                        bounds.setScale(1 / renderQuality)
                    }
                }
            }


            worldNode.addChild(root)
        }


        // 'r' reloads the scene
        if eventKey == 0xf {
            self.reloadScene()
        }

        // 's' draws the tilemap bounds
        if eventKey == 0x1 {
            Logger.default.log("drawing map bounds.", level: .debug)
            tilemap.debugDrawOptions = (tilemap.debugDrawOptions.contains(.drawBounds)) ? tilemap.debugDrawOptions.subtracting(.drawBounds) : tilemap.debugDrawOptions.insert(.drawBounds).memberAfterInsert
        }

        // 't' runs a custom command
        if eventKey == 0x11 {
            Logger.default.log("clearing tile textures.", level: .debug)
            tilemap.tileLayers().filter { $0.graph != nil }.forEach { $0.getTiles().forEach { $0.texture = nil }}
        }

        // 'u' runs a custom command
        if eventKey == 0x20 {
            Logger.default.log("refreshing tile textures.", level: .debug)
            tilemap.tileLayers().filter { $0.graph != nil }.forEach { $0.getTiles().forEach { $0.update() }}
        }

        // 'v' debugs map statistics
        if eventKey == 0x9 {
            tilemap.mapStatistics()
        }



        // 'w' checks graph names
        if eventKey == 0xd {
            for graph in graphs {
                print(graph)
            }
        }

        // 'x' prints new map stats
        if eventKey == 0x7 {
            tilemap.betterMapStatistics()
        }


        // 'z' draws anchors
        if eventKey == 0x06 {
            tilemap.debugDrawOptions = (tilemap.debugDrawOptions.contains(.drawAnchor)) ? tilemap.debugDrawOptions.subtracting(.drawAnchor) : tilemap.debugDrawOptions.insert(.drawAnchor).memberAfterInsert
        }

        // '↑' clamps layer positions
        if eventKey == 0x7e {
            let scaleFactor =  SKTiledContentScaleFactor
            var nodesUpdated = 0
            tilemap.enumerateChildNodes(withName: "*") { node, _ in

                let className = String(describing: type(of: node))

                let oldPos = node.position
                node.position = clampedPosition(point: node.position, scale: scaleFactor)
                self.log("clamping:  <\(className): \(node.position), \(oldPos)>", level: .debug)
                nodesUpdated += 1
            }

            log("\(nodesUpdated) nodes updated.", level: .info)
        }
    }
}
