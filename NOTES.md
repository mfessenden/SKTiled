# Notes

## Release Checklist

- remove debug methods for `SKTiledDemoScene`
- update SKTiled versions
- update podfile with current version
    - `pod trunk push SKTiled.podspec`

- remove references to `SKTiledDemoScene` in `SKTiled+Debug.swift`
- enable `CLANG_WARN_DOCUMENTATION_COMMENTS` for documentation in framework targets

git-commit -a 6/23/2017 16:07:13


### Added in master ~ 1.14

- remove `SKTilemap.isolateLayer`
    - do it in the layer
- add `SKTilemap.tiledversion`
- add `TiledApplicationVersion`

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
