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
let tileLayer = tilemap.getTileLayer(named: "Ground/terrain")
```

**Working with tilesets**

```swift
let tileSet = tilemap.getTileset("Roguelike")
tileSet.getTileData(gid: 177)
```