# Setting Up Your Scenes

- [`SKTilemapDelegate` Protocol](#sktilemapdelegate-protocol)
- [`SKTiledScene`](#sktiledscene)


Using tile map content in your projects is very straightforward. **SKTiled** includes tools that allow you to easily access and customize content for your game.

## `SKTilemapDelegate` Protocol

The [`SKTilemapDelegate`](Protocols/SKTilemapDelegate.html) protocol allows you to use optional callbacks that are called at various stages of tile map creation. It is recommended that your SpriteKit scenes conform to this protocol.


```swift
protocol SKTilemapDelegate {
    /// Called when the tilemap is instantiated.
    func didBeginParsing(_ tilemap: SKTilemap){}
    /// Called when a tileset has been added.
    func didAddTileset(_ tileset: SKTileset) {}
    /// Called when a layer has been added.
    func didAddLayer(_ layer: TiledLayerObject) {}
    /// Called before layers are rendered.
    func didReadMap(_ tilemap: SKTilemap) {}
    /// Called when layers are rendered. Perform post-processing here.
    func didRenderMap(_ tilemap: SKTilemap) {}
}
```

The callback methods are optional; you are free to implement any or all of them as needed.

A basic scene setup could be as simple as: 

```swift
class GameScene: SKScene, SKTilemapDelegate {
    override func didMove(to view: SKView) {
        if let tilemap = SKTilemap.load(fromFile: "myTiledFile", delegate: self) {
            addChild(tilemap)
            // center the tilemap in the scene
            tilemap.position.x = (view.bounds.size.width / 2.0)
            tilemap.position.y = (view.bounds.size.height / 2.0)
        }
    }
}
```

To access the rendered layers, implement the `SKTilemapDelegate.didRenderMap` method:

```swift
class GameScene: SKScene, SKTilemapDelegate {
    override func didMove(to view: SKView) {
        if let tilemap = SKTilemap.load(fromFile: "myTiledFile", delegate: self) {
            addChild(tilemap)
            // center the tilemap in the scene
            tilemap.position.x = (view.bounds.size.width / 2.0)
            tilemap.position.y = (view.bounds.size.height / 2.0)
        }
    }
    
    func didRenderMap(_ tilemap: SKTilemap) {
        if let obstaclesLayer = tilemap.objectGroup(named: "Obstacles") {
            obstaclesLayer.isHidden = true
            obstaclesLayer.setupPhysics()
        }
    }
}
```

## SKTiledScene

The [`SKTiledSceneDelegate`](Protocols/SKTiledSceneDelegate.html) protocol outlines a basic game scene setup with a world container node and camera. The included [`SKTiledScene`](Classes/SKTiledScene.html) conforms to this protocol and is meant to serve as a template, though you are free to implement your own setup.


```swift
class GameScene: SKScene, SKTiledSceneDelegate  {
    var worldNode: SKNode!                  // world container node
    var cameraNode: SKTiledSceneCamera!     // custom scene camera
    var tilemap: SKTilemap!                 // tile map node
}
```

![Scene Hierarchy](images/scene_hierarchy.png)

The tile map is parented to a world container node, which interacts with the included [`SKTiledSceneCamera`](Classes/SKTiledSceneCamera.html) class and allows you to easily move the scene around with mouse & touch events. The world node is set to 0,0 in the scene by default. 

If you choose to subclass [`SKTiledScene`](Classes/SKTiledScene.html), you can simply initialize the object with the name of the map you want to load:

```swift
// initialize a tiled scene in the GameViewController
let scene = SKTiledScene(size: viewSize, tmxFile: "first-scene")

// transition to another scene
scene.transitionTo(tmxFile: "second-scene", duration: 1.0)
```

Calling the class method [`SKTilemap.load(fromFile:)`](Classes/SKTilemap.html#/Loading) will initialize a parser to read the file name given. To see the [`SKTiledScene`](Classes/SKTiledScene.html) in action, compile the project demo target and look at the `SKTiledDemoScene`.


Next: [Working with Layers](layers.html) - [Index](Tutorial.html)
