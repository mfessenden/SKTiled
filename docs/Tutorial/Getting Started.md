# Getting Started


##Requirements

- iOS9+ / macOS 10.11+
- Xcode 8
- Swift 2.3+

Check out the [master](https://github.com/mfessenden/SKTiled/blob/master) branch for Swift 2.3, or the [iOS10](https://github.com/mfessenden/SKTiled/blob/iOS10) branch for Swift 3. Going forward, the minimum requirements will be pushed up to Swift 3/iOS10/macOS 10.11 as some features will require newer versions of Apple's tools.

###Swift 2.3 Installation

If you're using one of the older toolchains, you'll need to enable the **Use Legacy Swift Language Version** option in the project **Build Settings.**

![SKTiled](../img/swift_legacy.png)


##Installation

- Copy the *Swift/SKTiled* directory to your directory and add the files to your project.
- Set the appropriate Swift language target.

That's it!
 

##Adding Tiled Assets

When adding maps (TMX files), images and tilesets (TSX files) to your Xcode project, you'll need to make sure to add the files as groups and not folder references as the assets are stored in the root of the app bundle when compiled.


##Scene Setup

Using tiled maps in your own projects is very easy. The included `SKTiledScene` class conforms to the `SKTiledSceneDelegate` protocol and could serve as a template for your scenes though you are free to implement your own setups.

If you choose to create your own scene type, a simple setup could be as simple as:


```swift
import SpriteKit

public class GameScene: SKScene {
    override public func didMoveToView(view: SKView) {
        if let tilemap = SKTilemap.load(fromFile: "myTiledFile") {
            addChild(tilemap)
            // center the tilemap in the scene
            tilemap.position.x = (view.bounds.size.width / 2.0)
            tilemap.position.y = (view.bounds.size.height / 2.0)
        }
    }
}
```

Use the class method `SKTilemap.load(fromFile:)` will create a parser to read the file name you give it. **SKTiled** can load internal & external tilesets, though there is a slight speed penalty for loading an external tileset with larger scenes.
 
The world container node is set to 0,0 in the scene. When a tile map is loaded, it is parented to the world node. The scene camera contains weak references to the tilemap and world nodes and is used to navigate the scene.


##Tile Coordinates

Tile coordinates in **SKTiled** are represented by the [`TileCoord`](#TileCoord) data type, though most classes have convenience methods to query coordinates with integer values:

```swift
let coord = TileCoord(4, 12)
```

##Working with Layers

Once the map is loaded, you can begin working with the layers. There are several ways to access layers from the [`SKTilemap`](#SKTilemap) object:

```swift
// returns a tile layer with a given name
let backgoundLayer = tilemap.getLayer(named: "Background") as! SKTileLayer
```

Once you have a layer, you can add child nodes to it (any `SKNode` type is allowed):

```swift
// add a child node
playerLayer.addChild(player)

// set the player position based on coordinate x & y values
player.position = playerLayer.pointForCoordinate(4, 12)
```

It is also possible to provide an offset value in x/y for more precise positioning:

```swift
player.position = playerLayer.pointForCoordinate(4, 12, offsetX: 8.0, offsetY: 4.0)
```

All [`TiledLayerObject`](#TiledLayerObject) objects have convenience methods for adding children with coordinate values & optional offset and even zPosition values:

```swift
playerLayer.addChild(player, 4, 12, zPosition: 25.0)
```

###Default Layer

By default, the [`SKTilemap`](SKTilemap.html) class uses a default tile layer accessible via `SKTilemap.baseLayer`. The base layer is automatically created is used for coordinate transforms and for visualizing the grid (the base layer's z-position is always higher than the other layers).

By default, when you query a point in the `SKTilemap` node, you are getting a location in the default base layer (see the [Coordinates](coordinates) section).


###Other Functions

####Isolating Layers

You can isolate layers easily (just as you can in Tiled):

```swift
// isolate the layer named 'Background'
tilemap.isolateLayer("Background")

// show all layers
tilemap.isolateLayer(nil)
```

Next: [Coordinates](coordinates.html)
