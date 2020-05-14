# Working with Maps

- [Loading a Tilemap](#loading-a-tilemap)
- [Tile Rendering](#tile-rendering)
    - [Full & Dynamic](#full-amp-dynamic)
    - [SpriteKit Actions](#spritekit-actions)
        - [Manually Starting & Stopping](#manually-starting-amp-starting)
- [Tile Render Flags](#tile-render-flags)
- [Effects Rendering](#effects-rendering)
   - [Shaders & Filters](#shaders-amp-filters)
- [Tile Cracking](#tile-cracking)
    - [Camera Zoom Clamping](#camera-zoom-clamping)


## Loading a Tilemap

Creating a tilemap node is very straightforward; simply call the `SKTilemap.load(tmxFile:)` function to read a Tiled tmx file from disk:

```swift
if let tilemap = SKTilemap.load(tmxFile: "MyTilemap.tmx") {
    worldNode.addChild(tilemap)
}
```

If you are implementing the `SKTilemapDelegate` and `SKTilesetDataSource` protocols, you can optionally specify those when you load the tilemap:

```swift
if let tilemap = SKTilemap.load(tmxFile: tmxFile,
                                delegate: self as? SKTilemapDelegate,
                                tilesetDataSource: self as? SKTilesetDataSource) {

    worldNode.addChild(tilemap)
}
```

Once the map is loaded, you'll need to add your tilemap node to your [`SKScene.update`][skscene-update-url] method:


```swift
class GameScene: SKScene {
    var tilemap: SKTilemap?
    override func update(_ currentTime: TimeInterval) {
        self.tilemap?.update(currentTime)
    }
}
```


## Tile Rendering


By default, **SKTiled** updates each tile on a concurrent background queue. This includes tile animations, ensuring that frames are synced each frame. For performance, tile data is cached and updated with each frame. How the cache is updated is determined by the `TileUpdateMode` flag. There are three settings for rendering maps, choose the option that is best suited to your content:


|  Mode   | Description                                                           |
|:-------:|:----------------------------------------------------------------------|
|  full   | All tiles are updated each frame.                                     |
| dynamic | Only animated tiles are updated.                                      |
| actions | No tiles are updated, animations are rendered with SpriteKit actions. |


The default tile update method is `dynamic` which provides a good mix of performance and accuracy. For best performance, use `actions` and for greatest accuracy consider `full`.

Tile update mode can be passed as an argument to the load method, or set later:

```swift
// tilemap will update only animated tiles
if let tilemap = SKTilemap.load(tmxFile: "MyTilemap.tmx", 
									delegate: nil, 
									updateMode: TileUpdateMode.dynamic) {
		
									
}

// change the rendering to update all tiles for every frame
tilemap.updateMode = TileUpdateMode.full
```


### Full & Dynamic

Using either of these methods, you can change the [`SKNode.speed`][sknode-speed-url] property of your scene/tilemap/layer which will scale the speed of tile animations accordingly (including moving in reverse). In addition, tile animations are updated independent of frame rate, so animation speed will be the same regardless of fps.


### SpriteKit Actions

If your tilemap is set to run in `TileUpdateMode.actions` mode, animated tiles will render with [**SpriteKit Actions**][skaction-url]. Actions are more efficient with memory and CPU usage. If you are using a large map or don't need exact frame synchronization, this option might be more viable. While faster, this method might result in frames getting out of sync slightly so use accordingly. Tile animations *will* respect pausing using this method, but animation speed can't be changed reliably.


#### Manually Starting & Stopping

To manually enable/disable SpriteKit actions, call the `SKTilemap.runAnimationAsActions(_:restore:)` method:


```swift
// run animations as actions
tilemap.runAnimationAsActions(true)

// remove all animations & restore initial texture
tilemap.runAnimationAsActions(false, restore: true)
```

Passing a value of `false` will remove all actions and effectively halt all animation.


It is also possible to start & stop SpriteKit actions for each layer individually:

```swift

// run SpriteKit actions for all animated tiles in the layer
tileLayer.runAnimationAsActions()


// remove all SpriteKit actions for the layer (stop tile animations)
tileLayer.removeAnimationActions(restore: false)
```


## Tile Render Flags

Individual tiles can also have separate render flags that determine their behavior.

For more information, see the [**Working with Tiles**](working-with-tiles.html#tile-render-mode) section.

## Effects Rendering

`SKTilemap` & `SKTiledLayerObject` nodes are subclassed from the SpriteKit [`SKEffectNode`][skeffectnode-url] node. The [`SKEffectNode`][skeffectnode-url] node renders its children into a private buffer and additionally allows Core Image effects to be applied. You may also apply shaders and distortions to these nodes, allowing for sophisticated rendering effects.

To enable shader effects, turn on the [`SKTilemap.shouldEnableEffects`][skeffectnode-effects-url] attribute. This will consume slightly more CPU & GPU power, so by default it is disabled to conserve resources. One additional benefit is that rendering into a buffer eliminates tile "cracking" artifacts.

```swift
tilemap.shouldEnableEffects = true
```

Effects rendering also softens the edges of nearest-neighbor filtered textures slightly, which may be undesirable for retro-themed games with blocky edges.

Be careful enabling this option for large maps; the [`SKEffectNode`][skeffectnode-url] node buffer maximum texture size is 2048x2048. If your map is larger than that, your map will render as cropped.

![Effects Rendering](images/effects-rendering.gif)


### Shaders & Filters

Applying a shader (or filter) is done the same way as it is done with a sprite node:

```swift
// emable effects rendering on the map node
tilemap.shouldEnableEffects = true

// load a shader from the current project
let shader = SKShader(fileNamed: "waves")

// create an attribute to pass the tilemap's render size to the shader as an attribute
shader.attributes = [SKAttribute(name: "a_map_size", type: .vectorFloat2)]

// set the tilemap shader
tilemap.shader = shader

// pass the tilemap size to the shader
tilemap.setValue(SKAttributeValue(vectorFloat2: tilemap.sizeInPoints.toVec2), forAttribute: "a_map_size")
```

For more details, check out [**Apple's SKShader tutorial page**][skshader-url].




Next: [Working with Tilesets](working-with-tilesets.html) - [Index](Table of Contents.html)

[skscene-update-url]:https://developer.apple.com/documentation/spritekit/skscene/1519802-update
[skshader-url]:https://developer.apple.com/documentation/spritekit/skshader
[skeffectnode-url]:https://developer.apple.com/documentation/spritekit/skeffectnode
[skeffectnode-effects-url]:https://developer.apple.com/documentation/spritekit/skeffectnode/1459385-shouldenableeffects
[sknode-speed-url]:https://developer.apple.com/documentation/spritekit/sknode/1483036-speed
[skaction-url]:https://developer.apple.com/documentation/spritekit/skaction
