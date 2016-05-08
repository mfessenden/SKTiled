# SKTiled

A simple framework for Apple's SpriteKit allowing the creation of game assets from Tiled files.


**Loading a tile map**

```swift
if let tilemap = SKTilemap.loadTMX("sample-map") {
    scene.addChild(tilemap)
}
```

**Accessing tile layers**

```swift
let tileLayer = tilemap.getLayer(named: "Ground")
```

**Working with tilesets**

```swift
let tileSet = tilemap.getTileset("spritesheet-16x16")
// get SKTilesetData for a given id
let tileData = tileSet.getTileData(gid: 177)
```

**Tile data accessible from the parent tilemap**

```swift
let tileData = tilemap.getTileData(gid: 177)
```

**Adding new nodes**

```swift
// tile data contains all tile properties, including texture
let newTile = SKTile(data: tileData)
```

**Features**

- renders all layer types
- supports arbitrary properties for maps, layers & tiles
- supports inline & external tilesets

**Limitations**

- cannot parse data compressed with gzip/zlib compression.
- does not support rotated tiles
- does not support animated tiles