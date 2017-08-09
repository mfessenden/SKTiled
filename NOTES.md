# Notes

## SKTileObject tile object flipping

- see commit 8368c23d & 1848ad25
- SKTile.orientTile -> e868dc2

walkableIDs: 8,9,10,23,24
## Release Checklist

- remove debug methods for `SKTiledDemoScene`
- update SKTiled versions
- update podfile with current version
    - `pod trunk push SKTiled.podspec`

- remove references to `SKTiledDemoScene` in `SKTiled+Debug.swift`
- enable `CLANG_WARN_DOCUMENTATION_COMMENTS` for documentation in framework targets
- remove test resources



### Added in master ~ 1.14

- remove `SKTilemap.isolateLayer`
    - do it in the layer
- add `SKTilemap.tiledversion`
- add `TiledApplicationVersion`

## Filename Conventions

`SKTilemapParser.rootPath` : resource path (defaults to bundled resource)

    `SKTilemap.filename` represents the tmx filename (minus .tmx extension)
    `SKTilemap.name` represents the tmx filename (minus .tmx extension)

`SKTilemap.url` represents the full path to the tmx file

## Drawing & Coordinates

#### SpriteKit

(0,0) is lower-left, y increases upward

#### Tiled

(0,0) is top-left, y increases downward


## Tileset ID & Global ID

n/a

## Math

n/a

### Alignment

**Bottom Left**

x-anchor point = (map half tile width / tileset tile width)
y-anchor point = 1 - (map half tile height / tileset tile height)


**Bottom Right**

x-anchor point = 1 - (map half tile width / tileset tile width)
y-anchor point = 1 - (map half tile height / tileset tile height)


**Top Left**

x-anchor point = (map half tile width / tileset tile width)
y-anchor point = (map half tile height / tileset tile height)


**Top Right**

x-anchor point = 1 - (map half tile width / tileset tile width)
y-anchor point = (map half tile height / tileset tile height)



| Tile Width   | Tile Height  | Tileset Width  | Tileset Height |
| ------------ | ------------ | -------------- | -------------- |
| 8            | 8            | 24             | 16             |


### Image Framework (Cocoa <-> iOS)
https://github.com/C4Labs/C4iOS/tree/master/C4/Core

## Xcode Settings

DEFINES_MODULE - should default to yes (leave as yes)
