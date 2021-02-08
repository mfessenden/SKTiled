//
//  SKTiled+GameplayKit.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
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
import GameplayKit


extension SKTilemap {

    /// Initialize the grid graph with an array of walkable tiles.
    ///
    /// - Parameters:
    ///   - layers: array of tile layers.
    ///   - walkable: array of walkable tiles.
    ///   - obstacle: array of obstacle tiles.
    ///   - diagonalsAllowed: allow diagonal movement in the grid.
    ///   - nodeClass: graph node type.
    public func gridGraphForLayers(_ layers: [SKTileLayer],
                                   walkable: [SKTile],
                                   obstacle: [SKTile] = [],
                                   diagonalsAllowed: Bool = false,
                                   nodeClass: String? = nil) {

       layers.forEach {
            _ = $0.initializeGraph(walkable: walkable, obstacles: obstacle,
                                              diagonalsAllowed: diagonalsAllowed,
                                              withName: nil, nodeClass: nodeClass)
        }
    }
}


extension SKTileLayer {

    /// Initialize this layer's grid graph with an array of walkable tiles.
    ///
    /// - Parameters:
    ///   - walkable: array of walkable tiles.
    ///   - obstacles: array of obstacle tiles.
    ///   - diagonalsAllowed:  allow diagonal movement in the grid.
    ///   - withName: optional graph name for identifying in scene.
    ///   - nodeClass: graph node type.
    /// - Returns: navigation graph, if created.
    @discardableResult
    public func initializeGraph(walkable: [SKTile],
                                obstacles: [SKTile] = [],
                                diagonalsAllowed: Bool = false,
                                withName: String? = nil,
                                nodeClass: String? = nil) -> GKGridGraph<GKGridGraphNode>? {

        if (orientation != .orthogonal) {
            log("navigation graphs can only be created with orthogonal tilemaps.", level: .warning)
            return nil
        }

        // get the node type from the delegate
        let GraphNode = (tilemap.delegate != nil) ? tilemap.delegate!.objectForGraphType?(named: nodeClass) ?? GKGridGraphNode.self : GKGridGraphNode.self

        // create the navigation graph
        let gridGraph = GKGridGraph<GKGridGraphNode>(fromGridStartingAt: simd_int2(arrayLiteral: 0, 0),
                                                  width: Int32(mapSize.width),
                                                  height: Int32(mapSize.height),
                                                  diagonalsAllowed: diagonalsAllowed,
                                                  nodeClass: GraphNode)

        self.graph = gridGraph

        guard let graph = self.graph else { return nil }

        var nodesToRemove: [GKGridGraphNode] = []

        for col in 0 ..< Int(mapSize.width) {
            for row in (0 ..< Int(mapSize.height)) {
                let coord = simd_int2(arrayLiteral: Int32(col), Int32(row))

                if let node = graph.node(atGridPosition: coord) {

                    if let tile = tileAt(col, row) {

                        if let tiledNode = node as? SKTiledGraphNode {
                            tiledNode.weight = Float(tile.tileData.weight)
                            // transfer properties
                            tiledNode.properties = tile.tileData.properties
                            tiledNode.parseProperties(completion: nil)
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
        let statusMessage = (nodeCount > 0) ? "navigation graph for layer '\(layerName)' created with \(nodeCount) nodes." : "could not find any walkable tiles for layer '\(layerName)'."
        let statusLevel: LoggingLevel = (nodeCount > 0) ? .info : .warning
        log(statusMessage, level: statusLevel)

        // automatically add the graph to the scene graphs property.
        let sceneGraphName = withName ?? self.navigationKey
        if let scene = self.tilemap.scene as? SKTiledScene {
            if (scene.addGraph(named: sceneGraphName, graph: graph) == false) {
                log("graph with key '\(sceneGraphName)' already exists, skipping.", level: .warning)
            }
        }

        // unhide the layer & kill textures
        isHidden = false
        clearTiles()
        return graph
    }

    /// Initialize layer navigation graph by not specifying tiles to utilize.
    ///
    /// - Returns: navigation graph, if created.
    @discardableResult
    public func initializeGraph() -> GKGridGraph<GKGridGraphNode>? {
        let walkable = getTiles()
        return self.initializeGraph(walkable: walkable)
    }

    /// Initialize this layer's grid graph with an array of walkable & obstacle tile ids.
    ///
    /// - Parameters:
    ///   - walkableIDs: array of walkable tile ids.
    ///   - obstacleIDs: array of obstacle tile ids.
    ///   - diagonalsAllowed: allow diagonal movement in the grid.
    ///   - nodeClass: graph node type.
    /// - Returns: navigation graph, if created.
    @discardableResult
    public func initializeGraph(walkableIDs: [Int],
                                obstacleIDs: [Int] = [],
                                diagonalsAllowed: Bool = false,
                                nodeClass: String? = nil) -> GKGridGraph<GKGridGraphNode>? {

        let walkable: [SKTile] = getTiles().filter { tile in

            let uid = Int(tile.tileData.id)
            return walkableIDs.contains(uid)
        }

        var obstacles: [SKTile] = []
        if (obstacleIDs.isEmpty == false) {
            obstacles = getTiles().filter { tile in
                let uid = Int(tile.tileData.id)
                return obstacleIDs.contains(uid)
            }
        }
        return self.initializeGraph(walkable: walkable, obstacles: obstacles,
                                    diagonalsAllowed: diagonalsAllowed, nodeClass: nodeClass)
    }
    /// Return tiles with walkable data attributes.
    ///
    /// - Returns: array of tiles with walkable attribute.
    public func gatherWalkable() -> [SKTile] {
        return self.getTiles().filter { $0.tileData.walkable == true }
    }

    /// Return tiles with obstacle data attributes.
    ///
    /// - Returns: array of tiles with obstacle attribute.
    public func gatherObstacles() -> [SKTile] {
        return self.getTiles().filter { $0.tileData.obstacle == true }
    }
}

/// The `SKTiledGraphNode` node is a custom [`GKGridGraphNode`][gkgridgraphnode-url] object that adds a weight parameter for
/// use with Tiled scene properties. Can be used with normal [`GKGridGraphNode`][gkgridgraphnode-url]
/// instances. The `SKTiledGraphNode.weight` property is used to affect the estimated cost to a
/// connected node. (Increasing the weight makes it less likely to be travelled to, decreasing more likely).
///
/// ## Usage
///
/// ```swift
/// // query a node in the graph and increase the weight property
/// if let node = graph.node(atGridPosition: coord) as? SKTiledGraphNode {
///    node.weight = 25.0
/// }
/// ```
///
/// [gkgridgraphnode-url]:https://developer.apple.com/documentation/gameplaykit/gkgridgraphnode
public class SKTiledGraphNode: GKGridGraphNode, TiledAttributedType {

    /// Unique id.
    public var uuid: String = UUID().uuidString

    /// Node type.
    public var type: String!

    /// Node attributes.
    public var properties: [String : String] = [:]

    /// Ignore custom node properties.
    public var ignoreProperties: Bool = false

    /// Render scaling property.
    public var renderQuality: CGFloat = TiledGlobals.default.renderQuality.default

    /// Weight property.
    public var weight: Float = 1.0

    // MARK: - Initialization


    /// Initialize the node with a weight parameter.
    ///
    /// - Parameters:
    ///   - gridPosition: vector simd_int2 coordinates.
    ///   - weight: node weight.
    public init(gridPosition: simd_int2, weight: Float = 1.0) {
        self.weight = weight
        super.init(gridPosition: gridPosition)
    }

    public override init(gridPosition: simd_int2) {
        super.init(gridPosition: gridPosition)
    }

    /// Instantiate the node with a decoder instance.
    ///
    /// - Parameter aDecoder: decoder.
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Pathfinding

    /// The `GKGridGraphNode.cost` method is used in the `GKGridGraphNode.findPathToNode` method. Returns the cost (lower is better) for each node in the possible nodes.
    ///
    /// - Parameter node: node to estimate from.
    /// - Returns: cost to travel to the given node.
    public override func cost(to node: GKGraphNode) -> Float {
        guard let gridNode = node as? SKTiledGraphNode else {
            return super.cost(to: node)
        }
        return connectedNodes.contains(gridNode) ? weight - (1.0 - gridNode.weight) : Float.greatestFiniteMagnitude
    }

    /// Returns the heuristic cost to node.
    ///
    /// - Parameter node: target graph node.
    /// - Returns: heuristic cost to node.
    public override func estimatedCost(to node: GKGraphNode) -> Float {
        guard let gridNode = node as? SKTiledGraphNode else {
            return super.estimatedCost(to: node)
        }
        let dx: Float = abs(Float(gridPosition.x) - Float(gridNode.gridPosition.x))
        let dy: Float = abs(Float(gridPosition.y) - Float(gridNode.gridPosition.y))
        return (dx + dy) - 1 * min(dx, dy)
    }
}


extension SKTiledScene {

    /// Return a custom graph node type.
    ///
    /// - Parameter named: graph node type.
    /// - Returns: dictionary insertion was successful.
    open func objectForGraphType(named: String?) -> GKGridGraphNode.Type {
        return SKTiledGraphNode.self
    }

    /// Add a `GKGridGraph` instance to the `SKTIledScene.graphs` property. Returns false if that name exists already.
    ///
    /// - Parameters:
    ///   - named:  name of graph
    ///   - graph: graph object.
    /// - Returns: graph was added sucessfully.
    open func addGraph(named: String, graph: GKGridGraph<GKGridGraphNode>) -> Bool {
        if (graphs[named] != nil) {
            return false
        }
        graphs[named] = graph
        log("adding graph '\(named)' to scene.", level: .debug)
        self.didAddNavigationGraph(graph)
        return true
    }

    /// Remove a named `GKGridGraph` from the `SKTIledScene.graphs` property.
    ///
    /// - Parameter named: name of graph.
    /// - Returns: removed graph instance.
    open func removeGraph(named: String) -> GKGridGraph<GKGridGraphNode>? {
        log("removing graph '\(named)' from scene.", level: .debug)
        return graphs.removeValue(forKey: named)
    }
}


extension SKTiledGraphNode {

    /// Parse the tile data's properties value.
    ///
    /// - Parameter completion: optional completion function.
    public func parseProperties(completion: (() -> Void)?) {
        if (ignoreProperties == true) { return }
        if (self.type == nil) { self.type = properties.removeValue(forKey: "type") }
        completion?()
    }
}
