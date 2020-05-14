# Extending SKTiled

- [Custom Objects](#custom-objects)
- [Tiled Object Types](#tiled-object-types)
- [A Note on Subclassing](#a-note-on-subclassing)

## Custom Objects

**SKTiled** allows you to use custom classes in place for the default **tile**, **vector object** and **pathfinding graph** nodes. Any class conforming to the `SKTilemapDelegate` protocol can access methods for returning custom object types:

```swift
class GameScene: SKScene, SKTilemapDelegate {

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

class Maze: SKScene, SKTilemapDelegate {

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

// `LevelScene.objectForTileType` will never be called.
class BaseScene: SKScene, SKTilemapDelegate {...}

class LevelScene: BaseScene {
    func objectForTileType(named: String?) -> SKTile.Type {
        return MyTile.self
    }
}
```

The `SKTilemapDelegate.objectForGraphType(named:)` method implemented in `LevelScene` will never be called. That's because Swift will ignore the subclassed implementation in favor of the default protocol implementation.

In order for this setup to work, you must implement it on the **base class that conforms to the protocol** (ie `BaseScene` here).

```swift

// `LevelScene.objectForTileType` will be called as expected.
class BaseScene: SKScene, SKTilemapDelegate {
    func objectForTileType(named: String?) -> SKTile.Type {
        return SKTile.self
    }
}

class LevelScene: BaseScene {
    override func objectForTileType(named: String?) -> SKTile.Type {
        return GameTile.self
    }
}
```

It is recommended that you implement the protocols directly on your objects and avoid subclassing classes that conform to protocols.

If this is a limitation, one way to overcome it is to implement a secondary method (or property) in the superclass and override that in the subclass:

```swift
class BaseScene: SKScene, SKTilemapDelegate {
    func didRenderMap(_ tilemap: SKTilemap) {
        // call a secondary method
        setupTilemap(tilemap)
    }

    func setupTilemap(_ tilemap: SKTilemap) {
        print("BaseScene: setting up tilemap: \"\(tilemap.name!)\"")
    }
}

class LevelScene: BaseScene {
    override func setupTilemap(_ tilemap: SKTilemap) {
        print("LevelScene: setting up tilemap: \"\(tilemap.name!)\"")
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

Next: [Debugging](debugging.html) - [Index](Table of Contents.html)
