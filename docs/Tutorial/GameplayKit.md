# GameplayKit Integration (WIP)

- [Custom Node Weights](#)
- [Debugging the Graph](#debugging-the-graph)
- [Querying Neighbor Nodes](#querying-neighbor-nodes)


**SKTiled** supports Apple's GameplayKit by allowing users to build pathfinding graphs in tile layers (currently only orthogonal tile layers are supported). Every `SKTileLayer` instance has an optional `GKGridGraph` attribute accessible via the `SKTileLayer.graph` attribute:
  
  ```swift
  tileLayer.graph = GKGridGraph<SKTiledGraphNode>
  ```

Passing custom properties in the Tiled scene can be used to create pathfinding graphs automatically:

    SKTilemap:
      buildGraph          (String)    - layer name(s) on which to build graphs.
      walkableIDs         (String)    - list of comma-separated tile gids.
      walkableTypes       (String)    - list of comma-separated tile types.
     
    SKTileset:
      walkable            (Bool)      - flags tiles with gid as walkable. 
      weight              (Float)     - custom node weight.

    SKTileLayer:
      buildGraph          (Bool)      - flags the layer as having a grid graph.
      walkableIDs         (String)    - list of comma-separated tile gids.
      walkableTypes       (String)    - list of comma-separated tile types.



      
To automatically create a graph in one of your tile layers, you can simply add the *buildGraph* and *walkableIDs* properties on a tile layer in Tiled.
      

![Walkable IDs](images/walkable-ids.png)
      

You can also initialize a layer's graph manually in your code:

```swift
let graphLayer = tilemap.tileLayer(named: "Graph")!
let walkable: [Int] = [12, 13, 14]
graphLayer.graph.initializeGraph(walkableIDs: walkable, diagonalsAllowed: false)
```

##Custom Node Weights (iOS10 only)

The included [`SKTiledGraphNode`](Classes/SKTiledGraphNode.html) class adds a `weight` attribute that can be used to affect the outcome of heuristic pathfinding.

```swift
let coord = CGPoint(x: 10, y: 8)
let node = tileLayer.graph.node(atGridPosition: coord)
node.weight = 10.0
```

You can also pass the value through a property in Tiled with a float attribute *weight*:


![Walkable IDs](images/node-weight-property.png)


##Debugging the Graph

To see a visual representation of any layer's pathfinding graph, use the `SKTileLayer.showGraph` property. Node weights will be represented by a heat map from gray to red:

![Show Graph](images/showGraph.gif)


##Querying Neighbor Nodes*

 *Not yet implemented.
 
 
Next: [Debugging](debugging.html) - [Index](Tutorial.html)
 
