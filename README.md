<p align="center">
<img src="Docs/images/doc-banner-centered.svg" alt="SKTiled" title="SKTiled" width="881" height="81"/>
<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.3-brightgreen.svg"></a>
<a href="https://developer.apple.com/download/more/"><img src="https://img.shields.io/badge/Xcode-11.0-orange.svg"></a>
<a href="https://travis-ci.org/mfessenden/SKTiled"><img src="https://travis-ci.org/mfessenden/SKTiled.svg?branch=master"></a>
<a href="https://github.com/mfessenden/SKTiled/blob/master/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg"></a>
<a href="http://www.apple.com"><img src="https://img.shields.io/badge/platforms-iOS%20%7C%20tvOS%20%7C%20macOS-red.svg"></a>
<a href="https://github.com/Carthage/Carthage/"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg"></a>
</p>


**SKTiled** is a framework for integrating [Tiled][tiled-url] assets with [Apple's SpriteKit][spritekit-url], built from the ground up with Swift. This project began life as an exercise to learn Apple's new programming language for a game project, but I've decided to release it as open source with the hopes that others will find it useful. **SKTiled** is up-to-date and supports **Tiled's** major features, including all map & object types.

![Demo Image][demo-iphone-img]


Check out the [**Official Documentation**][sktiled-13-doc-url].

## Features

- [x] iOS & macOS versions
- [x] tvOS version
- [x] parses inline & external tilesets
- [x] translates custom properties for maps, layers, objects & tiles
- [x] renders all projections: (orthogonal, isometric, hexagonal & isometric staggered)
- [x] renders all layer types: (tile, object, image, group)
- [x] supports all compression types: (base64, zlib, gzip)
- [x] renders animated and flipped tiles
- [x] pre-loading of tilesets
- [x] group nodes
- [x] tile objects
- [x] text objects
- [x] template objects
- [x] custom tile & object classes
- [x] generate `GKGridGraph` graphs from custom attributes
- [x] user-definable cost properties for `GKGridGraph` nodes
- [x] infinite maps
- [ ] tile collision objects
- [ ] Zstandard compression support
- [ ] layer tinting
- [ ] file properties


## Requirements

- iOS 12
- tvOS 12
- macOS 10.14
- Xcode 11/Swift 5

## Installation



### Carthage

For Carthage installation, create a Cartfile in the root of your project:

    github "mfessenden/SKTiled" "release/1.30"


To use the new **[binary framework][binary-frameworks-url]** format, pass the **`--use-xcframeworks`** parameter to the build command:

	carthage update --use-xcframeworks

For more information, see the **[Carthage Installation][docs-carthage-url]** documentation.


### CocoaPods


For CocoaPods, install via a reference in your podfile:

    pod 'SKTiled', :git => 'https://github.com/mfessenden/SKTiled.git', :branch => 'release/1.30'


## Usage

Loading a tilemap is very straightforward:

```swift
if let tilemap = SKTilemap.load(tmxFile: "sample-map") {
    scene.addChild(tilemap)
}
```
Once loaded, the rendered [`SKTilemap`][sktilemap-url] node reflects the various properties defined in the originating scene:

- `SKTilemap.size`: size of the map in tiles.
- `SKTilemap.tileSize`: size of individual tiles.
- `SKTilemap.orientation`: map orientation (ie orthogonal, isometric, etc).


The [`SKTilemap`][sktilemap-url] node also gives users access to child layers, tilesets, objects or individual tiles.

### Working with Layers

Layers represent containers that hold various types of data:

- tile layers hold an array of tile sprites and associated tileset data
- object groups contain vector shape objects
- image layers display a single image

All **SKTiled** layer types are subclasses of the base [`SKTiledLayerObject`][sktiledlayerobject-url] object and provide access to coordinate transformation and positioning information. Additionally, every layer type can have individual offset transforms and rendering flags.  

Layers can be accessed by type, name or index:

```swift
// query layers by type
let tileLayers   = tilemap.tileLayers
let objectGroups = tilemap.objectGroups
let imageLayers  = tilemap.imageLayers
let groupLayers  = tilemap.groupLayers

// query named layers
let groundLayers = tilemap.getLayers(named: "Ground") as! [SKTileLayer]
let objectGroups = tilemap.getLayers(named: "Objects") as! [SKObjectGroup]
let hudLayers = tilemap.getLayers(named: "HUD") as! [SKImageLayer]

// query layer at a specific index
if let firstLayer = tilemap.getLayer(atIndex: 1) as! SKTileLayer {
    firstLayer.visible = true
}
```


### Working with Tiles

There are a number of ways to access and manipulate tile objects. Tiles can be queried from the [`SKTilemap`][sktilemap-url] node, or the parent [`SKTileLayer`][sktilelayer-url] layer:

```swift
// access a tile via CGPoint
let tileCoord = CGPoint(x: 7, y: 12)
if let tile = groundLayer.tileAt(coord: tileCoord) {
    tile.tileData.tileOffset.x += 8
}

// access a tile with integer coordinates
if let tile = groundLayer.tileAt(7, 12) {
    tile.tileData.tileOffset.x += 8
}

// query tiles at a specific coordinate (all layers)
let tiles = tilemap.tilesAt(2, 4)
```

Tiles assigned custom properties in **Tiled** can be accessed in **SKTiled**:

```swift
// query tiles of a certain type
if let fireTiles = tilemap.getTiles(ofType: "fire") {
    // do something fiery here...
}
```

You can also return tiles with a specific ID value:

```swift
if let waterTiles = waterLayer.getTiles(globalID: 17) {
    // do something watery here...
}
```

### Working with Objects

`SKTileObject` objects can be queried from both the [`SKTilemap`][sktilemap-url] and [`SKObjectGroup`][skobjectgroup-url] nodes:

```swift
let allObjects = tilemap.getObjects()
let allTreeObjects = tilemap.getObjects(named: "Tree")
let allCollisionObjects = tilemap.getObjects(ofType: "Collision")

// get objects from the objects group layer
let entrances = objectsLayer.getObjects(ofType: "Entrance")
```

### Acessing Tile Data

The [`SKTilemap`][sktilemap-url] node stores an array of individual tilesets parsed from the original **Tiled** document. Individual tile data is accessible from either the [`SKTileset`][sktileset-url] object:

```swift
let tileSet = tilemap.getTileset("spritesheet-16x16")
// get data for a specific id
let tileData = tileSet.getTileData(globalID: 177)
```

and the parent [`SKTilemap`][sktilemap-url]:

```swift
let tileData = tilemap.getTileData(globalID: 177)
```


## Adding Nodes

Tile data includes texture data, and [`SKTile`][sktile-url] objects are [`SKSpriteNode`][skspritenode-url] subclasses that can be initialized with tileset data:

```swift
let newTile = SKTile(data: tileData)
scene.addChild(newTile)
```

Coordinate information is available from each layer via the [`SKTiledLayerObject.pointForCoordinate`][sktiledlayerobject-pointforcoordinate-url] method:

```swift
let tilePoint = groundLayer.pointForCoordinate(4, 5)
tile.position = tilePoint
```

New nodes (any [`SKNode`][sknode-url] type) can be added directly to any layer. All [`SKTiledLayerObject`][sktiledlayerobject-url] layer types have expanded convenience methods for adding child nodes with coordinates and z-position.

```swift
let roadRoot = SKNode()
groundLayer.addChild(roadRoot, 4, 5, zpos: 100.0)
```

**SKTiled** also provides methods for getting coordinate data from [`UITouch`][uitouch-url] and [`NSEvent`][nsevent-url] mouse events:

```swift
// get the coordinate at the location of a touch event
let touchLocation: CGPoint = objectsLayer.coordinateAtTouchLocation(touch)
```

## Animated Tiles

Tiles with animation will animate automatically when the tilemap node is added to the [`SKScene.update`][skscene-update-url] method. Animated tiles can be accesssed from the either the [`SKTilemap`][sktilemap-url] node or the parent layer.


```swift
// get all animated tiles, including nested layers
let allAnimated = tilemap.animatedTiles(recursive: true)

// pause/unpause tile animation
for tile in allAnimated {
    tile.isPaused = true
}

// run animation backwards
for tile in allAnimated {
    tile.speed = -1.0
}

// get animated tiles from individual layers
let layerAnimated = groundLayer.animatedTiles()
```


## Custom Properties

Custom properties are supported on all object types. All **SKTiled** objects conform to the [`TiledObjectType`][tiledobjectype-url] protocol and allow access to and parsing of custom properties.

Any property added to an object in **Tiled** will be translated and stored in the `TiledObjectType.properties` dictionary.

```swift
let layerDepth = groundLayer.getValue(forProperty: "depth")
groundLayer.setValue(12.5, forProperty: "depth")
```

To query tiles of a given type:

```swift
let waterTiles = groundLayer.getTiles(ofType: "water")
let allWaterTiles = tilemap.getTiles(ofType: "water")
```

For specific property/value types:

```swift
let groundWalkable = groundLayer.getTilesWithProperty("walkable", true)
let allWalkable = tilemap.getTilesWithProperty("walkable", true")
```


## Acknowledgments

- [Thorbjørn Lindeijer](https://github.com/bjorn): creator of *Tiled*
- [GZipSwift](https://github.com/1024jp/GzipSwift): zlib decompression extensions
- [Steffen Itterheim](http://www.learn-cocos2d.com): Author of TilemapKit, the inspiration for this project
- [Kenney Vleugels](http://www.kenney.nl): demo spritesheet assets
- [Amit Patel](http://www-cs-students.stanford.edu/~amitp/gameprog.html): tile-based game logic
- [Clint Bellanger](http://clintbellanger.net/articles/isometric_math): isometric grid math
- [Amit Patel](https://www.redblobgames.com): hexagonal grid logic



[swift5-image]:https://img.shields.io/badge/Swift-5.3-brightgreen.svg
[swift4-image]:https://img.shields.io/badge/Swift-4.2-brightgreen.svg
[swift3-image]:https://img.shields.io/badge/Swift-3.2-brightgreen.svg
[swift-url]: https://swift.org/
[license-image]:https://img.shields.io/badge/License-MIT-blue.svg
[license-url]:https://github.com/mfessenden/SKTiled/blob/master/LICENSE
[travis-image]:https://travis-ci.org/mfessenden/SKTiled.svg?branch=master
[travis-url]:https://travis-ci.org/mfessenden/SKTiled
[platforms-image]:https://img.shields.io/badge/platforms-iOS%20%7C%20tvOS%20%7C%20macOS-red.svg
[platforms-url]:http://www.apple.com
[carthage-image]:https://img.shields.io/badge/Carthage-compatible-4BC51D.svg
[carthage-url]:https://github.com/Carthage/Carthage
[pod-image]:https://img.shields.io/cocoapods/v/SKTiled.svg
[mailto-url]:(mailto:michael.fessenden@gmail.com?subject=[SKTiled]%20Projects)

[xcode11-image]:https://img.shields.io/badge/Xcode-11.0-orange.svg
[xcode10-image]:https://img.shields.io/badge/Xcode-10.0-orange.svg
[xcode-downloads-url]:https://developer.apple.com/download/more/

[pod-url]:https://cocoapods.org/pods/SKTiled

[branch-master-url]:https://github.com/mfessenden/SKTiled
[branch-xcode8-url]:https://github.com/mfessenden/SKTiled/tree/xcode8
[branch-xcode9-url]:https://github.com/mfessenden/SKTiled/tree/xcode9

[header-image]:https://mfessenden.github.io/SKTiled/1.3/images/header.png
[demo-mac-image]:https://mfessenden.github.io/SKTiled/1.3/images/demo-macos-iso.png
<!--[demo-iphone-img]:https://mfessenden.github.io/SKTiled/1.3/images/demo-iphone.png-->
[demo-iphone-img]:Docs/images/demo-iphone.png


<!--- Documentation --->

[sktiled-gh-url]:https://mfessenden.github.io/SKTiled
[sktiled-12-doc-url]:https://mfessenden.github.io/SKTiled/1.2/
[sktiled-13-doc-url]:https://mfessenden.github.io/SKTiled/1.3/
[sktilemap-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKTilemap.html
[sktiledobject-url]:https://mfessenden.github.io/SKTiled/1.3/Protocols/SKTiledObject.html
[sktile-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKTile.html
[skobjectgroup-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKObjectGroup.html
[sktiledlayerobject-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKTiledLayerObject.html
[sktiledlayerobject-pointforcoordinate-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKTiledLayerObject.html
[sktilelayer-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKTileLayer.html
[sktileobject-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKTileObject.html
[sktileset-url]:https://mfessenden.github.io/SKTiled/1.3/Classes/SKTileset.html
[docs-carthage-url]:https://mfessenden.github.io/SKTiled/1.3/getting-started.html#carthage-installation

<!--- Tiled --->

[tiled-url]:http://www.mapeditor.org
[group-layers-url]:http://doc.mapeditor.org/manual/layers/#group-layers

<!--- Apple --->

[spritekit-url]:https://developer.apple.com/documentation/spritekit
[sknode-url]:https://developer.apple.com/documentation/spritekit/sknode
[skspritenode-url]:https://developer.apple.com/documentation/spritekit/skspritenode
[skscene-url]:https://developer.apple.com/documentation/spritekit/skscene
[skscene-update-url]:https://developer.apple.com/documentation/spritekit/skscene/1519802-update
[uitouch-url]:https://developer.apple.com/documentation/uikit/uitouch
[nsevent-url]:https://developer.apple.com/documentation/appkit/nsevent
[binary-frameworks-url]:https://developer.apple.com/videos/play/wwdc2019/416/
