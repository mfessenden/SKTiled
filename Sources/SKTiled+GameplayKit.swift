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
     Initialize the grid graph with an array of walkable tiles.

     - parameter layers:            `[SKTileLayer]` array of tile layers.
     - parameter walkable:          `[SKTile]` array of walkable tiles.
     - parameter obstacles:         `[SKTile]` array of obstacle tiles.
     - parameter diagonalsAllowed:  `Bool` allow diagonal movement in the grid.
     - parameter nodeClass:         `String?` graph node type.
     */
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   walkable: [SKTile],
                                   obstacle: [SKTile]=[],
                                   diagonalsAllowed: Bool=false,
                                   nodeClass: String? = nil) {

       layers.forEach {
            _ = $0.initializeGraph(walkable: walkable, obstacles: obstacle,
                                              diagonalsAllowed: diagonalsAllowed,
                                              withName: nil, nodeClass: nodeClass)
        }
    }
}


public extension SKTileLayer {

    /**
     Initialize this layer's grid graph with an array of walkable tiles.

     - parameter walkable:          `[SKTile]` array of walkable tiles.
     - parameter obstacles:         `[SKTile]` array of obstacle tiles.
     - parameter diagonalsAllowed:  `Bool` allow diagonal movement in the grid.
     - parameter withName:          `String?` optional graph name for identifying in scene.
     - parameter nodeClass:         `String?` graph node type.
     - returns:  `GKGridGraph<GKGridGraphNode>?` navigation graph, if created.
     */
    public func initializeGraph(walkable: [SKTile],
                                obstacles: [SKTile]=[],
                                diagonalsAllowed: Bool=false,
                                withName: String? = nil,
                                nodeClass: String? = nil) -> GKGridGraph<GKGridGraphNode>? {

        if (orientation != .orthogonal) {
            log("navigation graphs can only be created with orthogonal tilemaps.", level: .warning)
            return nil
        }

        // get the node type from the delegate
        let GraphNode = (tilemap.delegate != nil) ? tilemap.delegate!.objectForGraphType(named: nodeClass) : GKGridGraphNode.self

        // create the navigation graph
        self.graph = GKGridGraph<GKGridGraphNode>(fromGridStartingAt: int2(0, 0),
                                                  width: Int32(size.width),
                                                  height: Int32(size.height),
                                                  diagonalsAllowed: diagonalsAllowed,
                                                  nodeClass: GraphNode)

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

        // logging output
        let statusMessage = (nodeCount > 0) ? "navigation graph for layer \"\(layerName)\" created with \(nodeCount) nodes." : "could not build a navigation graph for layer \"\(layerName)\"."
        let statusLevel: LoggingLevel = (nodeCount > 0) ? .info : .warning
        log(statusMessage, level: statusLevel)

        // automatically add the graph to the scene graphs property.
        let sceneGraphName = withName ?? self.navigationKey
        if let scene = self.tilemap.scene as? SKTiledScene {
            if (scene.addGraph(named: sceneGraphName, graph: graph) == false) {
                log("graph with key \"\(sceneGraphName)\" already exists, skipping.", level: .warning)
            }
        }

        // unhide the layer & kill textures
        isHidden = false
        getTiles().forEach { $0.texture = nil }
        return graph
    }

    /**
     Initialize layer navigation graph by not specifying tiles to utilize.
     
     - returns:  `GKGridGraph<GKGridGraphNode>?` navigation graph, if created.
     */
    public func initializeGraph() -> GKGridGraph<GKGridGraphNode>? {
        let walkable = getTiles()
        return self.initializeGraph(walkable: walkable)
    }

    /**
     Initialize this layer's grid graph with an array of walkable & obstacle tile ids.

     - parameter walkableIDs:       `[Int]` array of walkable tile ids.
     - parameter obstacleIDs:       `[Int]` array of obstacle tile ids.
     - parameter diagonalsAllowed:  `Bool` allow diagonal movement in the grid.
     - parameter nodeClass:         `String?` graph node type.
     - returns:  `GKGridGraph<GKGridGraphNode>?` navigation graph, if created.
     */
    public func initializeGraph(walkableIDs: [Int],
                                obstacleIDs: [Int]=[],
                                diagonalsAllowed: Bool=false,
                                nodeClass: String? = nil) -> GKGridGraph<GKGridGraphNode>? {

        let walkable: [SKTile] = getTiles().filter { tile in
            walkableIDs.contains(tile.tileData.id)
        }

        var obstacles: [SKTile] = []
        if (obstacleIDs.isEmpty == false) {
            obstacles = getTiles().filter { tile in
                obstacleIDs.contains(tile.tileData.id)
            }
        }
        return self.initializeGraph(walkable: walkable, obstacles: obstacles,
                                    diagonalsAllowed: diagonalsAllowed, nodeClass: nodeClass)
    }

    /**
     Return tiles with walkable data attributes.
     
     - returns: `[SKTile]` array of tiles with walkable attribute.
     */
    public func gatherWalkable() -> [SKTile] {
        return self.getTiles().filter { $0.tileData.walkable == true }
    }

    /**
     Return tiles with obstacle data attributes.

     - returns: `[SKTile]` array of tiles with obstacle attribute.
     */
    public func gatherObstacles() -> [SKTile] {
        return self.getTiles().filter { $0.tileData.obstacle == true }
    }
}


/**

 ## Overview ##

 Custom [`GKGridGraphNode`][gkgridgraphnode-url] object that adds a weight parameter for 
 use with Tiled scene properties. Can be used with normal [`GKGridGraphNode`][gkgridgraphnode-url] 
 instances. The `SKTiledGraphNode.weight` property is used to affect the estimated cost to a 
 connected node. (Increasing the weight makes it less likely to be travelled to, decreasing more likely).

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

    override public init(gridPosition: int2) {
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
     Return a custom graph node type.

     - parameter named: `String` graph node type.
     - returns: `GKGridGraphNode.Type` dictionary insertion was successfull.
     */
    open func objectForGraphType(named: String?) -> GKGridGraphNode.Type { return SKTiledGraphNode.self }

    /**
     Add a `GKGridGraph` instance to the `SKTIledScene.graphs` property. Returns false if that
     name exists already.

     - parameter named: `String` name of graph.
     - parameter graph: `GKGridGraph<GKGridGraphNode>`
     - returns: `Bool` dictionary insertion was successfull.
     */
    open func addGraph(named: String, graph: GKGridGraph<GKGridGraphNode>) -> Bool {
        if (graphs[named] != nil) {
            return false
        }
        graphs[named] = graph
        log("adding graph \"\(named)\" to scene.", level: .debug)
        self.didAddNavigationGraph(graph)
        return true
    }

    /**
     Remove a named `GKGridGraph` from the `SKTIledScene.graphs` property.

     - parameter named: `String` name of graph.
     - returns: `GKGridGraph?` removed graph instance.
     */
    open func removeGraph(named: String) -> GKGridGraph<GKGridGraphNode>? {
        log("removing graph \"\(named)\" to scene.", level: .debug)
        return graphs.removeValue(forKey: named)
    }
}


// TODO: not yet implemented, take these out in master
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
