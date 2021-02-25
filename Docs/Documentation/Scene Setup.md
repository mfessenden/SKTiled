# Setting Up Your Scenes

- [Tiled Content in SpriteKit](#tiled-content-in-spritekit)
    - [`TilemapDelegate` Protocol](tilemapdelegate-protocol)
    - [Scene Setup](#scene-setup)
    - [Custom Tile Objects](#custom-tile-objects)
- [`TilesetDataSource` Protocol](#sktilesetdatasource-protocol)
- [`TiledSceneDelegate` Protocol](#tiledscenedelegate-protocol)
    - [Tiled Scene Camera](#tiled-scene-camera)
        - [Adding Delegates](#adding-delegates)
    - [Loading External Content](#loading-external-content)


Using Tiled assets in your projects is very straightforward with **SKTiled**. There are several tools included that allow you to easily access and customize content for your game.


## Tiled Content in SpriteKit

Getting Tiled content into SpriteKit is a breeze!

Simply setup your view controller and scene as you would normally, and add a tilemap to your scene via the `SKScene.load(tmxFile:)` method (included as an extension):

```swift
let scene = SKScene(size: skView.bounds.size)
scene.scaleMode = .aspectFill
skView.presentScene(scene)

if let tilemap = scene.load(tmxFile: "map1") {
    scene.addChild(tilemap)
}
```

### TilemapDelegate Protocol

The `TilemapDelegate` protocol is provided to allow you to easily access (and modify) your content even as it is being created. As the protocol methods are all optional, you only have to implement the controls you need. It is recommended that your SpriteKit scenes conform to this protocol.


```swift
extension  SKScene: TilemapDelegate {}
```

In addition to the optional callback methods, the protocol allows you to substitute your own classes for the default **tile**, **vector** and **pathfinding** objects.


```swift
@objc public protocol TilemapDelegate: TiledEventHandler {

    /// Determines the z-position difference between layers.
    @objc optional var zDeltaForLayers: CGFloat { get }

    /// Called when the tilemap is instantiated.
    ///
    /// - Parameter tilemap: tilemap instance.
    @objc optional func didBeginParsing(_ tilemap: SKTilemap)

    /// Called when a tileset is added to a map.
    ///
    /// - Parameter tileset: tileset instance.
    @objc optional func didAddTileset(_ tileset: SKTileset)

    /// Called when a layer is added to a tilemap.
    ///
    /// - Parameter layer: tilemap instance.
    @objc optional func didAddLayer(_ layer: SKTiledLayerObject)

    /// Called when the tilemap is finished parsing.
    ///
    /// - Parameter tilemap: tilemap instance.
    @objc optional func didReadMap(_ tilemap: SKTilemap)

    /// Called when the tilemap layers are finished rendering.
    ///
    /// - Parameter tilemap: tilemap instance.
    @objc optional func didRenderMap(_ tilemap: SKTilemap)

    /// Called when the a navigation graph is built for a layer.
    ///
    /// - Parameter graph: `GKGridGraph<GKGridGraphNode>` graph node instance.
    @objc optional func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>)

    /// Specify a custom tile object for use in tile layers.
    ///
    /// - Parameter named: optional class name.
    /// - Returns: tile object type.
    @objc optional func objectForTileType(named: String?) -> SKTile.Type

    /// Specify a custom object for use in object groups.
    ///
    /// - Parameter named: optional class name
    /// - Returns: vector object type.
    @objc optional func objectForVectorType(named: String?) -> SKTileObject.Type

    /// Specify a custom graph node object for use in navigation graphs.
    ///
    /// - Parameter named: optional class name.
    /// - Returns: pathfinding graph node type.
    @objc optional func objectForGraphType(named: String?) -> GKGridGraphNode.Type

    /// Called whem a tile is about to be built in a layer.
    ///
    /// - Parameters:
    ///   - globalID: tile global id.
    ///   - coord: tile coordinate.
    ///   - in: layer name.
    /// - Returns: tile global id.
    @objc optional func willAddTile(globalID: UInt32, coord: simd_int2, in: String?) -> UInt32

    /// Called whem a tile was built in a layer.
    ///
    /// - Parameters:
    ///   - tile: tile instance.
    ///   - coord: tile coordinate.
    ///   - in: layer name.
    @objc optional func didAddTile(_ tile: SKTile, coord: simd_int2, in: String?)

    /// Provides custom attributes for objects of a certain *Tiled type*.
    ///
    /// - Parameters:
    ///   - type: type value.
    ///   - named: optional node name.
    /// - Returns: custom attributes dictionary.
    @objc optional func attributesForNodes(ofType: String?, named: String?, globalIDs: [UInt32]) -> [String : String]?
}
```

For instance, if you wanted to create a cache for certain types of tiles, you could implement the `TilemapDelegate.didAddTile` method:


```swift
class GameScene: SKScene {

    func didAddTile(_ tile: SKTile, coord: simd_int2, in: String?) {
        if (tile.tileId == 12) {

        }
    }

}
```


As the methods are optional, you can choose to implement as few or as many methods as you need.


### Scene Setup

Setting up scenes is straightforward. Tile maps should be loaded during the [`SKScene.didMove(to:)`][skscene-didmove-url] method, and updated during the [`SKScene.update(_:)`][skscene-update-url] method (if you choose to render your maps with **SpriteKit actions**, you can forgo adding the `SKTilemap` node to the scene's update method).

A basic scene setup could be as simple as:

```swift
class GameScene: SKScene {

    var tilemap: SKTilemap?

    override func didMove(to view: SKView) {
        // load a named map
        if let tilemap = SKTilemap.load(tmxFile: "myTiledFile") {
            addChild(tilemap)
            // center the tilemap in the scene
            tilemap.position.x = (view.bounds.size.width / 2.0)
            tilemap.position.y = (view.bounds.size.height / 2.0)
            self.tilemap = tilemap
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // update tilemap
        self.tilemap?.update(currentTime)
    }
}
```

If you choose to implement the **`TilemapDelegate`** protocol, you can utilize as many of the optional callback methods as you see fit. You'll need to specify the tilemap's delegate at creation:

```swift
class GameScene: SKScene, TilemapDelegate {

    var tilemap: SKTilemap?

    override func didMove(to view: SKView) {
        if let tilemap = SKTilemap.load(fromFile: "myTiledFile", delegate: self) {
            // add the tilemap to the scene
            addChild(tilemap)
            // center the tilemap in the scene
            tilemap.position.x = (view.bounds.size.width / 2.0)
            tilemap.position.y = (view.bounds.size.height / 2.0)
            self.tilemap = tilemap
        }
    }

    func didRenderMap(_ tilemap: SKTilemap) {
        // finish setting up map here
        if let obstaclesLayer = tilemap.objectGroup(named: "Obstacles") {
            obstaclesLayer.isHidden = true
            obstaclesLayer.setupPhysics()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // update tilemap
        self.tilemap?.update(currentTime)
    }
}
```

### Custom Tile Objects

It is possible to use your own custom tile sprite objects in your projects. Subclass the built-in `SKTile` object and make it available in your scenes allows you to use different tile type for different scenes.


```swift
class MainMenuScene: SKScene, TilemapDelegate {

    /// use a custom tile type for the main menu
    func objectForTile(named: String?) -> SKTile.Type {
        return MenuButtonTile.self
    }
}
```

See the [**Extending**][extending-url] section for more details.


## TilesetDataSource Protocol

The `TilesetDataSource` protocol is new as of **SKTiled 1.20**. Objects conforming to this protocol can specify alternate attributes for a tileset as it is being parsed. For example, you can change the spritesheet image name of a tileset before the source file is loaded:

```swift
extension SceneManager: TilesetDataSource {
    func willAddSpriteSheet(to tileset: SKTileset, fileNamed: String) -> String {
        if let spritesheetForGameResolution = tileset.properties[gameResolution.rawValue] {
            return spritesheetForGameResolution
        }
        return fileNamed
    }
}
```
You'll need to make certain that the image you substitute has the same dimensions & layout as the image you are swapping it out for; the tileset will still retain the size and tile count properties defined in **Tiled**.

## TiledSceneDelegate Protocol

The included demo scene conforms to the `TiledSceneDelegate` protocol. This protocol outlines a standard SpriteKit game scene implementation with a camera that can interact with your tilemap. The included `SKTiledScene` class conforms to this protocol and can serve as a template, though you are free to implement your own setups.

![Scene Hierarchy](images/scene-hierarchy.svg)

```swift
public protocol TiledSceneDelegate: class {

    /// Root container node. Tiled assets are parented to this node.
    var worldNode: SKNode! { get set }

    /// Custom scene camera.
    var cameraNode: SKTiledSceneCamera? { get set }

    /// Tile map node.
    var tilemap: SKTilemap? { get set }

    /// Load a tilemap from disk, with optional tilesets.
    func load(tmxFile: String, inDirectory: String?,
              withTilesets tilesets: [SKTileset],
              ignoreProperties: Bool,
              loggingLevel: LoggingLevel) -> SKTilemap?
}
```

The tilemap is parented to a world container node, which interacts with the included `SKTiledSceneCamera` object and allows you to easily navigate the scene with mouse & touch events, as well as exchanging data with the scene and tilemaps. The world node is set to 0,0 in the scene by default.


Calling the class method [`SKTilemap.load(tmxFile:)`][sktilemap-load-url] will initialize a parser to read the file name given.

To see the `SKTiledScene` in action, compile one of the demo targets and look at the [`SKTiledDemoScene`][sktileddemoscene-source-url] class.


### Tiled Scene Camera

![Camera Delegates](images/camera-delegate.svg)


The `SKTiledSceneCamera` node is a custom [SpriteKit camera][skcameranode-url] that interacts with the your scene and any loaded tilemaps. To allow other objects to be notified of camera changes, you need to conform them to the `TiledSceneCameraDelegate` protocol. With this, you will want to implement the following methods:


```swift
// all platforms
func cameraPositionChanged(newPosition: CGPoint)
func cameraZoomChanged(newZoom: CGFloat)
func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat)

// iOS only
func sceneDoubleTapped(location: CGPoint)

// macOS only
func sceneClicked(event: NSEvent)
func sceneRightClicked(event: NSEvent)
func sceneDoubleClicked(event: NSEvent)
func mousePositionChanged(event: NSEvent)

```

The methods are all optional, so only create methods for the functions you need. For macOS games, be sure to set the [`NSWindow.acceptsMouseEvents`][nswindow-url] property to `true`.

#### Adding Delegates

To add your objects as camera delegates, implement the delegate methods you need and add them to the camera's [delegates][sktiledscenecamera-delegates-url] property:


```swift
extension Marker: TiledSceneCameraDelegate {
    func cameraZoomChanged(newZoom: CGFloat) {
        if (newZoom <= minZoom) {
            self.redraw(zoom: minZoom)
        }
    }
}

// create a new object & add it to the camera delegates
let marker = Marker()

// enable camera notifications
marker.receiveCameraUpdates = true
cameraNode.addDelegate(marker)
```


### Loading External Content

The demo project allows you to load and test your own Tiled content (macOS only). Simply compile the macOS demo target and select **Load tile map** from the **File** menu.

![Loading External](images/demo-load-external.svg)


Next: [Working with Maps](working-with-maps.html) - [Index](Documentation.html)


[extending-url]:extending.html
[sktilemap-load-url]:Classes/SKTilemap.html#/s:7SKTiled9SKTilemapC4loadACSgSS7tmxFile_SSSg11inDirectoryAA0B8Delegate_pSg8delegateSayAA9SKTilesetCGSg12withTilesetsSb16ignorePropertiesAA12LoggingLevelO07loggingP0tFZ
[skscene-url]:https://developer.apple.com/reference/spritekit/skscene
[skscene-didmove-url]:https://developer.apple.com/documentation/spritekit/skscene/1519607-didmove
[skscene-update-url]:https://developer.apple.com/documentation/spritekit/skscene/1519802-update
[skscene-load-url]:



<!-- // TODO: fix this -->
[sktileddemoscene-source-url]:https://github.com/mfessenden/SKTiled/blob/master/Demo/SKTiledDemoScene.swift
[skcameranode-url]:https://developer.apple.com/documentation/spritekit/skcameranode
[sktiledscenecamera-delegates-url]:Classes/SKTiledSceneCamera.html#addDelegate
[nswindow-url]:https://developer.apple.com/documentation/appkit/nswindow/1419340-acceptsmousemovedevents
