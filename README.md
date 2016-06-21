# SKTiled

**SKTiled** is a simple library for using [Tiled](http://www.mapeditor.org) files with Apple's SpriteKit, allowing the creation of game assets from .tmx files. Inspired by [TilemapKit](http://tilemapkit.com) and written purely in Swift 2.0, I began working on this for a project after the development of TilemapKit was halted. While initially created as an exercise in learning Apple's new programming language, I've decided to open-source it in case others find it helpful.  


##Installation

Simply drag the *SKTiled* directory into your Xcode project, and add the files to your game target:

![Xcode installation](https://github.com/mfessenden/SKTiled/blob/master/doc/installation.png)


## Usage

Loading a tilemap is simple:

```swift
if let tilemap = SKTilemap.loadFromFile("sample-map") {
    scene.addChild(tilemap)
}
```

The included `GameScene` object conforms to the `SKTiledSceneDelegate` protocol should be used as a template. The tilemap is accessed via the `GameScene.tilemap` property, and should be added as a child of the `GameScene.worldNode` object.


## Working with Tilemaps


**Acessing Layers**


Layers can be accessed by type:

```swift
let tileLayers = tilemap.tileLayers
let objectGroups = tilemap.objectGroups
```

or by name:

```swift
let groundLayer = tilemap.getLayer(named: "Ground") as! SKTileLayer
let objectsGroup = tilemap.getLayer(named: "Objects") as! SKObjectGroup
let hudLayer = tilemap.getLayer(named: "HUD") as! SKImageLayer

if let groundLayer = tilemap.tileLayer(named: "Ground") {
    groundLayer.visualizeGrid = true
}
```

Properties like map size & tile size can be accessed via the `SKTilemap.mapSize` and `SKTilemap.tileSize` properties.


**Accessing Tiles**

```swift
let tileCoord = TileCoord(7, 12)
let tile = groundLayer.tileAt(coord: tileCoord)
let tile = groundLayer.tileAt(7, 12)
```


**Accessing Objects**

`SKTileObject` objects can be returned in a number of ways:

```swift
let allObjects = tilemap.getObjects()
let allTreeObjects = tilemap.getObjects(named: "Tree")
let allCollisionObjects = tilemap.getObjects(ofType: "Collision")
```

**Acessing Tile Data**

Tile data is accessible from either the `SKTileSet` object:

```swift
let tileSet = tilemap.getTileset("spritesheet-16x16")
// get data for a specific id
let tileData = tileSet.getTileData(gid: 177)
```


as well as the parent `SKTilemap`:

```swift
let tileData = tilemap.getTileData(gid: 177)
```


### Adding Nodes

Tile data includes texture data, and `SKTile` objects are `SKSpriteNode` subclasses that can be initialized with tileset data:

```swift
let newTile = SKTile(data: tileData)
scene.addChild(newTile)
```

Coordinate information is accessible within each layer via the `TiledLayerObject.pointForCoordinate` method:

```swift
let tilePoint = groundLayer.pointForCoordinate(4, 5)
tile.position = tilePoint
```

New nodes (any `SKNode` type) can be added directly to any layer:


```swift
let newNode = SKNode()
groundLayer.addNode(newNode, 4, 5, zPosition: 100.0)
```

### Animated Tiles

Animated tiles will animate automatically; animated tiles can be accesssed from the tilemap. The `SKTile.pauseAnimation` property can stop/start animations:

```swift
let animatedTiles = tilemap.getAnimatedTiles()

for tile in animatedTiles {
    // pause the current animation
    tile.pauseAnimation = true
}
```


### Custom Properties

Custom properties are supported on all object types, and can be accessed easily:

```swift
let value = groundLayer.getValue(forProperty: "type")
groundLayer.setValue("water", forProperty: "type")
```

To query tiles of a given type:

```swift
let waterTiles = groundLayer.getTiles(ofType: "water")
let allWaterTiles = tilemap.getTiles(ofType: "water")
```

####Features

- renders all Tiled layer types (tile, object, image)
- custom properties for maps, layers, objects & tiles
- parses inline & external tilesets
- render tile layers as a single sprite
- render animated tiles
- render flipped tiles


####Limitations

- only orthogonal & isometric tilemaps supported.
- cannot parse data compressed with gzip/zlib compression.
- external tilesets can increase the overall load time.
- animated tiles are restricted to a per-tile frame duration (Tiled application supports per-frame durations).


####Upcoming Features

- generate GKGridGraph graphs based on custom tile attributes
- user-definable cost properties for GKGridGraph nodes


####SKTiled Wiki

- [class reference](https://github.com/mfessenden/SKTiled/wiki/Class-Reference)


####Acknowledgements

- [Steffen Itterheim](http://www.learn-cocos2d.com) creator of TilemapKit, the inspiration for this project
- [Kenney Vleugels](http://www.kenney.nl) for use of his spritesheet assets.
- [Amit Patel](http://www-cs-students.stanford.edu/~amitp/gameprog.html) for his excellent tutorials on tile-based game logic
- [Clint Bellanger: Isometric Tiles Math](http://clintbellanger.net/articles/isometric_math/)
