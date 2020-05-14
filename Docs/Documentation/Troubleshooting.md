# Troubleshooting

- [Tile Cracking](#tile-cracking)
    - [Camera Zoom Clamping](#camera-zoom-clamping)
- [XML Parsing Errors](#xml-parsing-errors)
    - [External Tileset Errors](#external-tileset-errors)
- [Code Signing Errors](#code-signing-errors)
- [Carthage Problems](#carthage-problems)

## Tile Cracking

![Tile Cracking][tile-cracking-img]

Sometimes small breaks will appear at the edges of tiles. They can be tricky to troubleshoot, but generally the cause is  zooming (or scaling) a node/camera zoom to an uneven value.

Usually rounding the zoom/scale value will alleviate cracking. Additionally, turning on the [`SKTilemap.shouldEnableEffects`][skeffectnode-shouldenableeffects-url] attribute will smooth out artifacts, at the expense of some performance.

`SKEffectNode` objects have a max framebuffer texture size of 2048x2048, so if your map size exceeds this, be aware that SpriteKit might crop out areas of your map.


### Camera Zoom Clamping

![Zoom Cracking](images/clamping.gif)

**SKTiled's** default camera can automatically clamp zoom values to the nearest whole pixel value to help eliminate render artifacts.


```swift
// for retina devices at 2x resolution, use CameraZoomClamping.half
myCamera.zoomClamping = CameraZoomClamping.half
```

If clamping is enabled, camera zooming will not appear as smooth, so if you need dynamic scaling in your game, you may want to turn off clamping. To do this, simply enable the `SKTiledSceneCamera.ignoreZoomClamping` flag:

```swift
myCamera.ignoreZoomClamping = true
```



## XML Parsing Errors

### External Tileset Errors

Occasionally the XML parser will throw errors with older external tilesets that have been downloaded from the internet. Importing & re-exporting the Tiled document(s) should make the error go away.

## Code Signing Errors

Occasionally you'll get a code signing error when compiling:

![Codesign Error](images/codesign-error.png)

If you're using Photoshop to create & save images, you might need to cleanup Finder metadata. To check, browse to your images directory in shell and run the following command:

    ls -al@

If any of your files have extra metadata that Xcode doesn't like, you'll see it listed below the file name:

![Image Metadata](images/xattr-cleanup.png)

Running the `xattr` command in your images directory will clean up the extra data:

    xattr -rc .

Additionally, you could add a script phase to your app target. In Xcode, select your target and add a new *New Run Script Phase*. Add the following code:

```bash
xattr -rc $PROJECT_DIR/Assets/.
```


## Carthage Problems

If you are getting errors including a framework in Xcode, use the `--no-use-binaries` flag when updating SKTiled.


Next: [Getting Started](getting-started.html) - [Index](Table of Contents.html)


[zlib-include-img]:images/zlib-include.png
[tile-cracking-img]:images/tile-cracking.png
[skeffectnode-shouldenableeffects-url]:https://developer.apple.com/documentation/spritekit/skeffectnode/1459385-shouldenableeffects
