# Extending SKTiled

- [Custom Objects](#custom-objects)
- [Custom Attributes](#custom-attributes)
- [Tile & Object Handlers](#tile-and-object-handlers)
- [Tiled Object Types](#tiled-object-types)
- [A Note on Subclassing](#a-note-on-subclassing)

## Custom Objects

**SKTiled** allows you to use custom classes in place for the default **tile**, **vector object** and **pathfinding graph** nodes. Any class conforming to the `TilemapDelegate` protocol can access methods for returning custom object types:

```swift
class GameScene: SKScene, TilemapDelegate {

    func objectForTileType(named: String?) -> SKTile.Type {
        return SKTile.self
    }

    func objectForVectorType(named: String?) -> SKTileObject.Type {
        return SKTileObject.self
    }

    func objectForGraphType(named: String?) -> GKGridGraphNode.Type {
        return GKGridGraphNode.self
    }
}
```

## Custom Attributes

You can also provide custom attributes for nodes

## Tile & Object Handlers




## Tiled Object Types

![Custom Tile Object](images/tile-type-dot.png)

You aren't restricted to one object type however, the parser reads the custom **type** attribute of tiles and objects in Tiled, and automatically passes that value to the delegate methods:


```swift

class Dot: SKTile {
    let score: Int = 10
    let ghostMode: GhostMode = GhostMode.chase
}

class Pellet: Dot {
    let score: Int = 50
    let ghostMode: GhostMode = GhostMode.flee
}

class Maze: SKScene, TilemapDelegate {

    // customize the tile type based on the `named` argument
    override func objectForTileType(named: String?) -> SKTile.Type {
        if (named == "dot") {
            return Dot.self
        }

        if (named == "pellet") {
            return Pellet.self
        }
        return SKTile.self
    }
}
```

## A Note on Subclassing


There are issues using objects with superclasses that conform to **protocols with default methods** in Swift. Consider the following example:

```swift
// The default `TilemapDelegate.objectForTileType` method will be called.
class BaseScene: SKScene, TilemapDelegate {...}

// `LevelScene.objectForTileType` will never be called.
class LevelScene: BaseScene {
    func objectForTileType(named: String?) -> SKTile.Type {
        return MyTile.self
    }
}
```

Because the base **`BaseScene`** object doesn't implement the protocol `objectForTileType` method, the **`LevelScene`** class implementation will be be ignored in favor of the default protocol method. This happens because Swift will **ignore the subclassed implementation in favor of the default protocol implementation**.

In order for this setup to work, you must *also* implement the method on the **base class that conforms to the protocol** (ie. `BaseScene` here).

```swift

// We'll just duplicate the default method here...
class BaseScene: SKScene, TilemapDelegate {
    func objectForTileType(named: String?) -> SKTile.Type {
        return SKTile.self
    }
}

// ...so that the superclass method is called correctly
class LevelScene: BaseScene {
    override func objectForTileType(named: String?) -> SKTile.Type {    // <- this works!
        return GameTile.self
    }
}
```

It is recommended that you implement the protocols directly on your objects and avoid subclassing classes that conform to protocols.

If this is a limitation, one way to overcome it is to implement a secondary method in the superclass that is called from the protocol method and override that in the subclass:

```swift
class BaseScene: SKScene, TilemapDelegate {
    func didRenderMap(_ tilemap: SKTilemap) {
        // call a secondary method
        setupTilemap(tilemap)
    }

    func setupTilemap(_ tilemap: SKTilemap) {
        print("BaseScene: setting up tilemap: '\(tilemap.mapName)'")
    }
}

class LevelScene: BaseScene {
    override func setupTilemap(_ tilemap: SKTilemap) {
        print("LevelScene: setting up tilemap: '\(tilemap.mapName)'")
    }
}
```

In this example, the `LevelScene.setupTilemap` method will be called as expected:

```swift
// the `LevelScene.setupMap` method will be called when the map is rendered:
let levelScene = LevelScene(size: viewSize)
if let tilemap = SKTilemap.load(tmxFile: level1, delegate: levelScene) {
    levelScene.tilemap = tilemap
}
```

```
# LevelScene: setting up tilemap: "level1"
```

Next: [Other API Features](other-api-features.html) - [Index](Documentation.html)
