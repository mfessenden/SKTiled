//
//  SKTiled+GameplayKit.swift
//  SKTiled
//
//  Created by Michael Fessenden on 10/7/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit
import GameplayKit


extension SKTilemap {
    
    /**
     Initialize the grid graph with an array layer names.
     
     - parameter layers:           `[SKTileLayer]` array of tile layers.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   diagonalsAllowed: Bool=false) {
        
        gridGraphForLayers(layers, walkableIDs: [Int](), diagonalsAllowed: diagonalsAllowed)
    }
    
    /**
     Initialize the grid graph with an array of walkable tiles.
     
     - parameter layers:           `[SKTileLayer]` array of tile layers.
     - parameter walkable:         `[SKTile]` array of walkable tiles.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   walkable: [SKTile],
                                   diagonalsAllowed: Bool=false) {
        
        
        var walkableIDs = walkable.map {$0.tileData.id }
        walkableIDs = Array(Set(walkableIDs))
        gridGraphForLayers(layers, walkableIDs: walkableIDs, diagonalsAllowed: diagonalsAllowed)
    }
    
    /**
     Initialize the grid graph with an array of walkable tile types.
     
     - parameter layers:           `[SKTileLayer]` array of tile layers.
     - parameter walkableTypes:    `[String]` array of walkable types.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   walkableTypes: [String],
                                   diagonalsAllowed: Bool=false) {
        
        var walkableIDs: [Int] = []
        for walkableType in walkableTypes {
            //for walkableData in getTile
            for walkableData in getTileData(withProperty: "type", walkableType as AnyObject) {
                if !walkableIDs.contains(walkableData.id) {
                    walkableIDs.append(walkableData.id)
                }
            }
        }
        
        gridGraphForLayers(layers, walkableIDs: walkableIDs, diagonalsAllowed: diagonalsAllowed)
    }
    
    /**
     Initialize the grid graph with an array of walkable tiles.
     
     - parameter layers:           `[SKTileLayer]` array of tile layers.
     - parameter walkableIDs:      `[Int]` array of walkable GIDs.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   walkableIDs: [Int],
                                   diagonalsAllowed: Bool=false) {
        
        for layer in layers {
            if let _ = layer.initializeGraph(walkableIDs: walkableIDs, diagonalsAllowed: diagonalsAllowed) {
                print("[SKTilemap]: created graph for layer \"\(layer.layerName)\"")
            }
        }
    }
    
    /**
     Post-process to build all pathfinding graphs.
     */
    public func buildGraphs(){
        
        var pathFindingGraphs: [GKGridGraph<SKTiledGraphNode>] = []
        
        for tileLayer in tileLayers() {
            
            if (tileLayer.walkableIDs.count > 0) || (tileLayer.walkableTypes.count > 0) {
                // check for walkable IDs
                if tileLayer.walkableIDs.count > 0 {
                    if let g = tileLayer.initializeGraph(walkableIDs: tileLayer.walkableIDs, diagonalsAllowed: false) {
                        pathFindingGraphs.append(g)
                        continue

                    }
                }
                
                // check for walkable types
                if tileLayer.walkableTypes.count > 0 {
                    if let g = tileLayer.initializeGraph(walkableTypes: tileLayer.walkableTypes, diagonalsAllowed: false) {
                        pathFindingGraphs.append(g)
                        continue
                    }
                }
            }
        }
        
        let gcount = pathFindingGraphs.count
        let resultMsg = (gcount > 0) ? (gcount == 1) ? "Success! \(gcount) graph built" : "success: \(gcount) graphs built" : "WARNING: no graphs built"
        print("[SKTilemap]: \(resultMsg).")
    }
}


public extension SKTileLayer {
    
    /**
     Initialize this layer's grid graph with an array of walkable tiles.
     
     - parameter walkableIDs:      `[Int]` array of walkable gids.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func initializeGraph(walkableIDs: [Int],
                                diagonalsAllowed: Bool=false) -> GKGridGraph<SKTiledGraphNode>? {
        
        if (orientation != .orthogonal) {
            print("[SKTileLayer]: pathfinding graphs can only be created with orthogonal tilemaps.")
            return nil
        }
        
        self.graph = GKGridGraph<SKTiledGraphNode>(fromGridStartingAt: int2(0, 0), width: Int32(size.width), height: Int32(size.height), diagonalsAllowed: diagonalsAllowed, nodeClass: SKTiledGraphNode.self)
        guard let graph = graph else { return nil }
        
        var nodesToRemove: [SKTiledGraphNode] = []
        
        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {
                let coord = int2(Int32(col), Int32(row))
                
                if let node = graph.node(atGridPosition: coord) {
                    
                    if let tile = tileAt(col, row) {
                        let gid = tile.tileData.id
                        
                        
                        // set custom weight parameter
                        if tile.tileData.hasKey("weight"){
                            if let weight = tile.tileData.doubleForKey("weight"){
                                node.weight = Float(weight)
                            }
                        }
                        
                        if walkableIDs.contains(gid) {
                            tile.texture = nil
                            continue
                        }
                    }
                    
                    nodesToRemove.append(node)
                }
            }
        }
        
        graph.remove(nodesToRemove)
        let nodeCount = (graph.nodes != nil) ? graph.nodes!.count : 0
        
        if nodeCount > 0 {
            print("[SKTileLayer]: pathfinding graph for layer \"\(layerName)\" created with \(nodeCount) nodes.")
        } else {
            print("[SKTileLayer]: WARNING: could not build a pathfinding graph for layer \"\(layerName)\".")
        }
        
        // add the graph to the scene graphs
        if let scene = self.tilemap.scene as? SKTiledScene {
            if !scene.addGraph(named: name!, graph: graph) {
                print("[SKTileLayer]: WARNING: cannot add graph \"\(layerName)\" to scene.")
            }
        }
        
        // unhide the layer
        isHidden = false
        //getTiles().forEach( {$0.texture = nil} )
        return graph
    }
    
    /**
     Initialize this layer's grid graph with an array of walkable types.
     
     - parameter walkableTypes:    `[String]` array of walkable gids.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func initializeGraph(walkableTypes: [String],
                                diagonalsAllowed: Bool=false) -> GKGridGraph<SKTiledGraphNode>? {
        
        if (orientation != .orthogonal) {
            print("[SKTileLayer]: pathfinding graphs can only be created with orthogonal tilemaps.")
            return nil
        }
        
        self.graph = GKGridGraph<SKTiledGraphNode>(fromGridStartingAt: int2(0, 0), width: Int32(size.width), height: Int32(size.height), diagonalsAllowed: diagonalsAllowed, nodeClass: SKTiledGraphNode.self)
        guard let graph = graph else { return nil }
        
        var nodesToRemove: [SKTiledGraphNode] = []
        
        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {
                let coord = int2(Int32(col), Int32(row))
                
                if let node = graph.node(atGridPosition: coord) {
                    if let tile = tileAt(col, row) {

                        
                        // set custom weight parameter
                        if tile.tileData.hasKey("weight"){
                            if let weight = tile.tileData.doubleForKey("weight"){
                                node.weight = Float(weight)
                            }
                        }
                        
                        if tile.tileData.hasKey("type") {
                            let tileType = tile.tileData.stringForKey("type")
                            if walkableTypes.contains(tileType!) {
                                continue
                            }
                        }
                        
                    }
                    
                    nodesToRemove.append(node)
                }
            }
        }
        
        graph.remove(nodesToRemove)
        let nodeCount = (graph.nodes != nil) ? graph.nodes!.count : 0
        if nodeCount > 0 {
            print("[SKTileLayer]: pathfinding graph for layer \"\(layerName)\" created with \(nodeCount) nodes.")
        } else {
            print("[SKTileLayer]: WARNING: could not build a pathfinding graph for layer \"\(layerName)\".")
        }
        
        // add the graph to the scene graphs
        if let scene = self.tilemap.scene as? SKTiledScene {
            if !scene.addGraph(named: name!, graph: graph) {
                print("[SKTileLayer]: WARNING: cannot add graph \"\(layerName)\" to scene.")
            }
        }
        
        // unhide the layer
        isHidden = false
        //getTiles().forEach({$0.texture = nil})
        return graph
    }
    
    /**
     Initialize this layer's grid graph from contained tiles.
     - parameter walkable:         `[SKTile]` array of walkable tiles.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func initializeGraph(walkable: [SKTile], diagonalsAllowed: Bool=false) -> GKGridGraph<SKTiledGraphNode>? {
        if (orientation != .orthogonal) {
            print("[SKTileLayer]: pathfinding graphs can only be created with orthogonal tilemaps.")
            return nil
        }
        
        self.graph = GKGridGraph<SKTiledGraphNode>(fromGridStartingAt: int2(0, 0), width: Int32(size.width), height: Int32(size.height), diagonalsAllowed: diagonalsAllowed, nodeClass: SKTiledGraphNode.self)
        guard let graph = graph else { return nil }
        
        var nodesToRemove: [SKTiledGraphNode] = []
        
        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {
                let coord = int2(Int32(col), Int32(row))
                
                if let node = graph.node(atGridPosition: coord) {
                    if let tile = tileAt(col, row) {
                        // set custom weight parameter
                        if tile.tileData.hasKey("weight"){
                            if let weight = tile.tileData.doubleForKey("weight"){
                                node.weight = Float(weight)
                            }
                        }
                        
                        if walkable.contains(tile) {
                            continue
                        }
                    }
                    
                    nodesToRemove.append(node)
                }
            }
        }
        
        
        graph.remove(nodesToRemove)
        
        let nodeCount = (graph.nodes != nil) ? graph.nodes!.count : 0
        if nodeCount > 0 {
            print("[SKTileLayer]: pathfinding graph for layer \"\(layerName)\" created with \(nodeCount) nodes.")
        } else {
            print("[SKTileLayer]: WARNING: could not build a pathfinding graph for layer \"\(layerName)\".")
        }
        
        // add the graph to the scene graphs
        if let scene = self.tilemap.scene as? SKTiledScene {
            if !scene.addGraph(named: name!, graph: graph) {
                print("[SKTileLayer]: WARNING: cannot add graph \"\(layerName)\" to scene.")
            }
        }
        
        // unhide the layer
        isHidden = false
        //getTiles().forEach( {$0.texture = nil})
        return graph
    }
    
    /**
     Initialize this layer's grid graph from contained tiles.
     
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func initializeGraph(diagonalsAllowed: Bool=false) -> GKGridGraph<SKTiledGraphNode>? {
        return initializeGraph(walkableIDs: [Int](), diagonalsAllowed: diagonalsAllowed)
    }
}


/**
 Custom `GKGridGraphNode` object that adds a weight parameter for used with Tiled scene properties. Can be used with
 normal `GKGridGraphNode` instances.
 
 The `SKTiledGraphNode.weight` property is used to affect the estimated cost to a connected node. (Increasing the weight makes
 it less likely to be travelled to, decreasing more likely).
 
 ```
 // query a node in the graph and increase the weight property
 if let node = graph.node(atGridPosition: coord) {
    node.weight = 25.0
 }
 ```
 */
public class SKTiledGraphNode: GKGridGraphNode {
    
    // less weight == more likely travel through
    public var weight: Float = 1.0
    
    /**
     Initialize the node with a weight parameter.
     
     - parameter gridPosition: `int2` vector int2 coordinates.
     - parameter weight: `Float` node weight.
     - returns: `SKTiledGraphNode` node instance.
     */
    public init(gridPosition: int2, weight: Float=1.0) {
        self.weight = weight
        super.init(gridPosition: gridPosition)
    }
    
    override public init(gridPosition: int2){
        super.init(gridPosition: gridPosition)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     The costToNode method is used in the GridGraphNode.findPathToNode method.
     Returns the cost (lower is better) for each node in the possible nodes.
     
     TODO: if the node is not connected, return FLT_MAX?
     
     - parameter node: `GKGraphNode` node to estimate from.
     - returns: `Float` cost to travel to the given node.
     */
    override public func cost(to node: GKGraphNode) -> Float {
        guard let gridNode = node as? SKTiledGraphNode else {
            return super.cost(to: node)
        }
        return weight - abs(1.0 - gridNode.weight)
    }
    
    /**
     Returns the heuristic cost to node.
     
     - parameter node: `GKGraphNode` target graph node.
     - returns: `Float` heuristic cost to node.
     */
    override public func estimatedCost(to node: GKGraphNode) -> Float {
        guard let gridNode = node as? SKTiledGraphNode else {
            return super.estimatedCost(to: node)
        }
        let dx: Float = abs(Float(gridPosition.x) - Float(gridNode.gridPosition.x))
        let dy: Float = abs(Float(gridPosition.y) - Float(gridNode.gridPosition.y))
        return (dx + dy) - 1 * min(dx, dy)
    }
}


extension SKTiledScene {
    
    /**
     Add a `GKGridGraph` instance to the `SKTIledScene.graphs` property. Returns false if that
     name exists already.
     
     - parameter named: `String` name of graph.
     - parameter graph: `GKGridGraph<SKTiledGraphNode>`
     - returns: `Bool` dictionary insertion was successfull.
     */
    public func addGraph(named: String, graph: GKGridGraph<SKTiledGraphNode>) -> Bool {
        if let _ = graphs[named] {
            return false
        }
        graphs[named] = graph
        return true
    }
    
    /**
     Remove a named `GKGridGraph` from the `SKTIledScene.graphs` property.
     
     - parameter named: `String` name of graph.
     - returns: `GKGridGraph?` removed graph instance.
     */
    public func removeGraph(named: String) -> GKGridGraph<SKTiledGraphNode>? {
        return graphs.removeValue(forKey: named)
    }
}

