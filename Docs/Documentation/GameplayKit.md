# GameplayKit Integration

- [Building Graphs](#building-graphs)
    - [Navigation Key](#navigation-key)
- [Custom Graph Nodes](#custom-graph-nodes)
- [Debugging the Graph](#debugging-the-graph)


**SKTiled** supports Apple's [GameplayKit][gameplaykit-url]  by allowing users to build pathfinding graphs in tile layers (currently only orthogonal tile layers are supported). Every `SKTileLayer` instance has an optional [`GKGridGraph`][gkgridgraph-url] attribute accessible via the `SKTileLayer.graph` attribute.


## Building Graphs

![Tile Data Pathfinding](images/tiledata-pathfinding-attrs.png)

You can create navigation graphs in tile layers by using the layer's `SKTileLayer.initializeGraph` method. To do so, you'll need to specify which tiles you intend to be **walkable**, and are not.

You can automatically flag tiles as walkable/obstacle by adding a custom property to a tileset tile id in **Tiled**.

```swift
// gather walkable & obstacles
let walkable  = graphLayer.getTiles().filter { $0.tileData.walkable == true }
let obstacles = graphLayer.getTiles().filter { $0.tileData.obstacle == true }

// initialize the graph for the layer
let graph = graphLayer.initializeGraph(walkable: walkable, obstacles: obstacles, diagonalsAllowed: false)!
```

Any tile matching those ids will be assigned a graph node.

You can also initialize a layer's graph with an array of walkable IDs:

```swift
let pathsLayer = tilemap.tileLayers(named: "Paths").first!
let walkable: [Int] = [12, 13, 14, 42, 43, 44]
let graph = graphLayer.initializeGraph(walkableIDs: walkable, obstacleIDs, [], diagonalsAllowed: false)!
```

### Navigation Key

If your SpriteKit scene is subclassed from `SKTiledScene`, navigation graphs will automatically be added to the `SKTiledScene.graphs` dictionary on creation. Each graph is accessible with a key, which defaults to the name of the parent tile layer. To customize the key value, add a custom property to the tile layer named **"navigationKey"**.

## Custom Graph Nodes

**SKTiled** allows you to deploy your own [`GKGridGraphNode`][gkgridgraphnode-url] node types for use in pathfinding graphs. If you implement the `SKTilemapDelegate` protocol, you can override the `SKTilemapDelegate.objectForGraphType`
function to return your custom [`GKGridGraphNode`][gkgridgraphnode-url] type.

### Graph Node Weight

The included `SKTiledGraphNode` class adds a `weight` attribute that can be used to affect the outcome of heuristic pathfinding.

```swift
let coord = CGPoint(x: 10, y: 8)
if let node = tileLayer.graph.node(atGridPosition: coord) as? SKTiledGraphNode {
    node.weight = 100.0
}
```

You can also pass the value through a property in Tiled with a float attribute `weight`:



![Walkable IDs](images/node-weight-property.png)


## Debugging the Graph

To see a visual representation of any layer's navigation graph, use the `SKTileLayer.debugDrawOptions` property.

```swift
graphLayer.debugDrawOptions = .drawGraph
```

See the [**debugging**](debugging.html) page for more information.


![Show Graph](images/showGraph.gif)

Next: [Extending SKTiled](extending-sktiled.html) - [Index](Table of Contents.html)

<!--- Apple --->

[spritekit-url]:https://developer.apple.com/documentation/spritekit
[gameplaykit-url]:https://developer.apple.com/documentation/gameplaykit
[gkgridgraph-url]:https://developer.apple.com/documentation/gameplaykit/gkgridgraph
[gkgridgraphnode-url]:https://developer.apple.com/documentation/gameplaykit/gkgridgraphnode
[sktilelayer-url]:https://mfessenden.github.io/SKTiled/Classes/SKTileLayer.html
