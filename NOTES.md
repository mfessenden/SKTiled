## Drawing & Coordinates

### SpriteKit

(0,0) is lower-left, y increases upward

### Tiled

(0,0) is top-left, y increases downward


## Tileset ID & Global ID



## Math


### Alignment

// 33 / 230 = 0.14
//  8 /  16 = 0.50
//  8 /  24 = 0.33
//  4 /   8 = 0.5



// Bottom Left
x-anchor point = (map half tile width / tileset tile width)
y-anchor point = 1 - (map half tile height / tileset tile height)


// Bottom Right
x-anchor point = 1 - (map half tile width / tileset tile width)
y-anchor point = 1 - (map half tile height / tileset tile height)


// Top Left
x-anchor point = (map half tile width / tileset tile width)
y-anchor point = (map half tile height / tileset tile height)


// Top Right
x-anchor point = 1 - (map half tile width / tileset tile width)
y-anchor point = (map half tile height / tileset tile height)



| Tile Width   | Tile Height  | Tileset Width  | Tileset Height |
| ------------ | ------------ | -------------- | -------------- |
| 8            | 8            | 24             | 16             |
