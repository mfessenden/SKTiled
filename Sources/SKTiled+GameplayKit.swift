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
    
    // MARK: - Main Pathfinding Methods
    /**
     Post-process to automatically build all pathfinding graphs.
    
     - parameter nodeType:  `String?` graph node class name.
     - parameter nodeClass: `GKGridGraphNode.Type` graph node type.
     */
    public func buildPathfindingGraphs(nodeType: String? = nil) {
        
 
    }
    
    
    // MARK: - Primary Tilemap Method
    /**
     Initialize the grid graph with an array of walkable tiles.
     
     - parameter layers:            `[SKTileLayer]` array of tile layers.
     - parameter walkable:          `[SKTile]` array of walkable tiles.
     - parameter obstacles:         `[SKTile]` array of obstacle tiles.
     - parameter diagonalsAllowed:  `Bool` allow diagonal movement in the grid.
     - parameter nodeClass:         `GKGridGraphNode.Type` graph node type.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   walkable: [SKTile],
                                   obstacle: [SKTile]=[],
                                   diagonalsAllowed: Bool=false,
                                   nodeClass: GKGridGraphNode.Type = SKTiledGraphNode.self) {
        

    }
    
    // MARK: - Extension Methods
    
    /**
     Initialize the grid graph with an array layer names.
     
     - parameter layers:           `[SKTileLayer]` array of tile layers.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   diagonalsAllowed: Bool=false,
                                   nodeClass: GKGridGraphNode.Type = SKTiledGraphNode.self) {
        
    }
    
    /**
     Initialize the grid graph with an array of walkable tiles.
     
     - parameter layers:           `[SKTileLayer]` array of tile layers.
     - parameter walkable:         `[SKTile]` array of walkable tiles.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   walkable: [SKTile],
                                   diagonalsAllowed: Bool=false,
                                   nodeClass: GKGridGraphNode.Type = SKTiledGraphNode.self) {
        
        
    }
    
    /**
     Initialize the grid graph with an array of walkable tile types.
     
     - parameter layers:           `[SKTileLayer]` array of tile layers.
     - parameter walkableTypes:    `[String]` array of walkable types.
     - parameter diagonalsAllowed: `Bool` allow diagonal movement in the grid.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   walkableTypes: [String],
                                   diagonalsAllowed: Bool=false,
                                   nodeClass: GKGridGraphNode.Type = SKTiledGraphNode.self) {
        
    }
}


public extension SKTileLayer {
    
    public func gatherWalkableTiles() {
        
        let walkable  = getTiles().filter { $0.tileData.walkable == true }
        let obstacles = getTiles().filter { $0.tileData.obstacle == true }
        
        if (loggingLevel.rawValue < 1) {
            print("[SKTileLayer]: \"\(layerName)\": walkable: \(walkable.count), obstacles: \(obstacles.count)")
        }
        
        if (walkable.count > 0) {
            if let _ = initializeGraph(walkable: walkable, obstacles: obstacles, diagonalsAllowed: false) {
                
            }
        }
    }
    
    //MARK: - Primary TileLayer Method
    /**
     Initialize this layer's grid graph with an array of walkable tiles.
     
     - parameter walkable:          `[SKTile]` array of walkable tiles.
     - parameter obstacles:         `[SKTile]` array of obstacle tiles.
     - parameter diagonalsAllowed:  `Bool` allow diagonal movement in the grid.
     - parameter nodeClass:         `GKGridGraphNode.Type` graph node type.
     */
    public func initializeGraph(walkable: [SKTile],
                                obstacles: [SKTile]=[],
                                diagonalsAllowed: Bool=false,
                                nodeClass: GKGridGraphNode.Type = SKTiledGraphNode.self) -> GKGridGraph<GKGridGraphNode>? {
        
        if (orientation != .orthogonal) {
            print("[SKTileLayer]: pathfinding graphs can only be created with orthogonal tilemaps.")
            return nil
        }
        
        self.graph = GKGridGraph<GKGridGraphNode>(fromGridStartingAt: int2(0, 0),
                                                  width: Int32(size.width),
                                                  height: Int32(size.height),
                                                  diagonalsAllowed: diagonalsAllowed,
                                                  nodeClass: nodeClass)
        
        guard let graph = graph else { return nil }
        
        var nodesToRemove: [GKGridGraphNode] = []
        
        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {
                let coord = int2(Int32(col), Int32(row))
                
                if let node = graph.node(atGridPosition: coord) {
                    
                    if let tile = tileAt(col, row) {

                        if let tiledNode = node as? SKTiledGraphNode {
                            tiledNode.weight = Float(tile.tileData.weight)
                        }
                        
                        if (walkable.contains(tile)) {
                            continue
                        }
                        
                        if (obstacles.contains(tile)) {
                            nodesToRemove.append(node)
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
            if !scene.addGraph(named: self.graphName, graph: graph) {
                print("[SKTileLayer]: WARNING: cannot add graph \"\(self.graphName)\" to scene.")
            }
        }
        
        // unhide the layer & kill textures
        isHidden = false
        getTiles().forEach( {$0.texture = nil} )
        return graph
    }
}


/**
 
 ## Overview ##
 
 Custom [`GKGridGraphNode`][gkgridgraphnode-url] object that adds a weight parameter for used with Tiled scene properties. Can be used with normal [`GKGridGraphNode`][gkgridgraphnode-url] instances. The `SKTiledGraphNode.weight` property is used to affect the estimated cost to a connected node. (Increasing the weight makes it less likely to be travelled to, decreasing more likely).
 
 ## Usage ##
 
 ```swift
 // query a node in the graph and increase the weight property
 if let node = graph.node(atGridPosition: coord) as? SKTiledGraphNode {
    node.weight = 25.0
 }
 ```
 
 [gkgridgraphnode-url]:https://developer.apple.com/documentation/gameplaykit/gkgridgraphnode
 */
public class SKTiledGraphNode: GKGridGraphNode {
    
    /// Weight property.
    public var weight: Float = 1.0
    
    // MARK: - Init
    
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
    
    // MARK: - Pathfinding
    
    /**
     The `GKGridGraphNode.cost` method is used in the `GKGridGraphNode.findPathToNode` method.
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
     - parameter graph: `GKGridGraph<GKGridGraphNode>`
     - returns: `Bool` dictionary insertion was successfull.
     */
    public func addGraph(named: String, graph: GKGridGraph<GKGridGraphNode>) -> Bool {
        if let _ = graphs[named] {
            return false
        }
        graphs[named] = graph
        self.didAddPathfindingGraph(graph)
        return true
    }
    
    /**
     Remove a named `GKGridGraph` from the `SKTIledScene.graphs` property.
     
     - parameter named: `String` name of graph.
     - returns: `GKGridGraph?` removed graph instance.
     */
    public func removeGraph(named: String) -> GKGridGraph<GKGridGraphNode>? {
        return graphs.removeValue(forKey: named)
    }
}


public struct Direction: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }
    
    static public let northWest   = Direction(rawValue: 1 << 0)
    static public let north       = Direction(rawValue: 2 << 0)
    static public let northEast   = Direction(rawValue: 2 << 1)
    static public let west        = Direction(rawValue: 2 << 2)
    static public let east        = Direction(rawValue: 2 << 3)
    static public let southWest   = Direction(rawValue: 2 << 4)
    static public let south       = Direction(rawValue: 2 << 5)
    static public let southEast   = Direction(rawValue: 2 << 6)
    
    static public let cardinal:  Direction  = [.north, .south, .east, .west]
    static public let diagonal:  Direction  = [.northWest, .northEast, .southWest, .southEast]
    static public let all:       Direction  = [.cardinal, .diagonal]
}


extension Direction {
    
    /// Returns a vector based on the direction.
    public var vector: int2 {
        switch self {
        case Direction.north:
            return int2(0, 1)
        case Direction.south:
            return int2(0, -1)
        case Direction.east:
            return int2(1, 0)
        case Direction.west:
            return int2(-1, 0)
        case Direction.northWest:
            return Direction.north.vector + Direction.west.vector
        case Direction.northEast:
            return Direction.north.vector + Direction.east.vector
        case Direction.southWest:
            return Direction.south.vector + Direction.west.vector
        case Direction.southEast:
            return Direction.south.vector + Direction.east.vector
        default:
            return int2(0, 0)
        }
    }
}


extension GKGridGraphNode {
    public func nodeInDirection(direction: Direction) -> GKGridGraphNode? {
        let nextPosition: int2
        switch direction {
        default:
            nextPosition = gridPosition + direction.vector
        }
        
        for node in self.connectedNodes {
            if let gridNode = node as? GKGridGraphNode {
                if gridNode.gridPosition == nextPosition {
                    return gridNode
                }
            }
        }
        return nil
        //return self.connectedNodes.flatMap{ $0 as? GKGridGraphNode }.filter{ $0.gridPosition == nextPosition }.first
    }
}




