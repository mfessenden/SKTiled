# GameplayKit Integration

*SKTiled* supports Apple's GameplayKit by allowing users to build pathfinding graphs in tile layers (currently only orthogonal tile layers are supported). Every `SKTileLayer` instance has an optional `GKGridGraph` attribute accesible via the `SKTileLayer.graph` attribute:
  
  ```swift
  tileLayer.graph = GKGridGraph
  ```

Passing custom properties in the Tiled scene can be used to create pathfinding graphs automatically:

    SKTilemap:
      buildGraph          (String)    - layer name(s) on which to build graphs.
      walkableIDs         (String)    - list of comma-separated tile gids.
     
    SKTileset:
      walkable            (Bool)      - flags tiles with gid as walkable. 
      weight              (Float)     - custom node weight.

    SKTileLayer:
      buildGraph          (Bool)      - flags the layer as having a grid graph.
      walkableIDs         (String)    - list of comma-separated tile gids.
      
You can also initialize a layer's graph manually in your code:

```swift
let graphLayer = tilemap.tileLayer(named: "Graph")!
let walkable: [Int] = [12, 13, 14]
graphLayer.graph.initializeGraph(walkableIDs: walkable, diagonalsAllowed: false)
```

##Custom Node Weights (iOS10 only)

The included `SKTiledGraphNode` class adds a `weight` attribute that can be used to affect the outcome of heuristic pathfinding.

```swift
tileLayer.graph = GKGridGraph(fromGridStartingAt: int2(0, 0), width: tileLayer.size.width, height: tileLayer.size.height, diagonalsAllowed: diagonalsAllowed, nodeClass: SKTiledGraphNode.self)
```



##Querying Neighbor Nodes*

 *future update
 
 
 
  Next: [Extending SKTiled](extending.html) - [Index](Tutorial.html)
