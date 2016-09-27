#Extending SKTiled

##Custom Nodes

It is also possible to use a custom node class in place of the `SKTile` object. Any object that conforms to the `SKTiledGeometry` protocol can be used as a custom tile type:

```swift
// pseudo-code for now
public class Player: SKTiledGeometry {
    public var layer: TiledLayerObject!
}
```

To use your custom tile type, you'll need to create a custom string property in Tiled called **nodeClass** for the tile:

![NodeClass](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/nodeClass.png)


##Custom Layer Types

It's also possible to create custom layer types by subclassing the `TiledLayerObject` base class. For instance, if you wanted to have an empty layer with extra logic for dealing with character entities:


```swift
public class ActorsLayer: TiledLayerObject {
    public var entities: [GKTentity] = []
}
```


  Next: [Debugging](debugging.html) - [Index](Tutorial.html)
