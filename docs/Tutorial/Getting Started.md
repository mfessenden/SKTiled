#Getting Started

**SKTiled** was designed to be flexible and easy to use. Installation is very straightforward. If you have any problems or requests, please open an issue at the [Github page](https://github.com/mfessenden/SKTiled/issues).


##Requirements

- iOS9+ / macOS 10.11+
- Xcode 8
- Swift 2.3+

Check out the [master](https://github.com/mfessenden/SKTiled/tree/master) branch for Swift 2.3, or the [iOS10](https://github.com/mfessenden/SKTiled/tree/iOS10) branch for Swift 3. Going forward, the minimum requirements will be pushed up to Swift 3/iOS10/macOS 10.11 as some features will require newer versions of Apple's tools.

**SKTiled** should work with tvOS, though it has not yet been extensively tested.

##Swift 2.3 Note

If you're using one of the older toolchains, you'll need to enable the **Use Legacy Swift Language Version** option in the project **Build Settings.**

![Legacy Swift Version](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/swift_legacy.png)


##Installation

- Copy the *Sources* directory to your project (or drag the individual files).
- Set the appropriate Swift language target.

![Xcode installation](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/installation.png)


### Compression

You'll need to add a path to the zlib module in your project under **Import Paths:**

*Project > Build Settings > Swift Compiler - Search Paths > Import Paths*

Add the following to the project:

`$(SRCROOT)/Sources`


![zlib compression](https://raw.githubusercontent.com/mfessenden/SKTiled/master/docs/Images/zlib_linking.png)
 

##Adding Tiled Assets

When adding maps (TMX files), images and tilesets (TSX files) to your Xcode project, you'll need to make sure to add the files as *groups* and not folder references as the assets are stored in the root of the app bundle when compiled.


##Setting up your Scenes

Using tiled maps in your own projects is very easy. The included [`SKTiledScene`](Classes/SKTiledScene.html) class conforms to the [`SKTiledSceneDelegate`](Protocols/SKTiledSceneDelegate.html) protocol and could serve as a template for your scenes, though you are free to implement your own setups.

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

Calling the class method [`SKTilemap.load(fromFile:)`](Classes/SKTilemap.html#/s:ZFC7SKTiled9SKTilemap4loadFT8fromFileSS_GSqS0__) will initialize a parser to read the file name you give it. **SKTiled** can load internal & external tilesets, though there is a slight speed penalty for loading an external tileset with larger scenes.
 
If you do use the included [`SKTiledScene`](Classes/SKTiledScene.html), you'll notice that Tiled assets are parented to the `SKTiledScene.worldNode`. This world container node interacts with the included [`SKTiledSceneCamera`](Classes/SKTiledSceneCamera.html) class and allows you to easily move the scene around with mouse & touch events. The world node is set to 0,0 in the scene by default. 


##Working with Layers

Once the map is loaded, you can begin working with the layers. There are several ways to access layers from the [`SKTilemap`](Classes/SKTilemap.html) object:

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

All [`TiledLayerObject`](Classes/TiledLayerObject.html) objects have convenience methods for adding children with coordinate values & optional offset and even zPosition values:

```swift
playerLayer.addChild(player, 4, 12, zpos: 25.0)
```

See the [Coordinates](coordinates.html) page for more information.

###Default Layer

By default, the [`SKTilemap`](Classes/SKTilemap.html) class uses a default tile layer accessible via `SKTilemap.baseLayer`. The base layer is automatically created is used for coordinate transforms and for visualizing the grid (the base layer's z-position is always higher than the other layers).



###Isolating Layers

You can isolate layers easily (just as you can in Tiled):

```swift
// isolate the layer named 'Background'
tilemap.isolateLayer("Background")

// show all layers
tilemap.isolateLayer(nil)
```

Next: [Working with Tiles](tiles.html) - [Index](Tutorial.html)
