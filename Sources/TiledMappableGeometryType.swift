//
//  TiledMappableGeometryType.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//  Web: https://github.com/mfessenden
//  Email: michael.fessenden@gmail.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SpriteKit
import GameplayKit


/// ## Overview
///
/// The `TiledMappableGeometryType` protocol describes a container that is broken up into two-dimensional tiles.
///
/// ### Properties
///
/// | Property        | Description                             |
/// | --------------- | --------------------------------------- |
/// | `orientation`   | Container orientation                   |
/// | `isInfinite`    | Container represents and infinite area. |
/// | `mapSize`       | Container size (in tiles)               |
/// | `graph`         | Container pathfinding graph (optional)  |
/// | `childOffset`   | Child node offset (optional)            |
/// | `tileSize`      | Tile size (in pixels)                   |
/// | `hexsidelength` | Hexagonal side length                   |
/// | `staggeraxis`   | Hexagonal stagger axis                  |
/// | `staggerindex`  | Hexagonal stagger index                 |
///
@objc public protocol TiledMappableGeometryType: TiledGeometryType {

    /// Map orientation type.
    @objc var orientation: TilemapOrientation { get set }

    /// Indicates the container represents an infinite map.
    @objc var isInfinite: Bool { get }

    /// Container size (in tiles).
    @objc var mapSize: CGSize { get }

    /// Pathfinding graph.
    @objc optional weak var graph: GKGridGraph<GKGridGraphNode>? { get set }

    /// Child node offset.
    @objc optional var childOffset: CGPoint { get }

    /// Tile size (in pixels).
    @objc var tileSize: CGSize { get }

    /// Hexagonal side length.
    @objc var hexsidelength: Int { get set }

    /// Hexagonal stagger axis.
    @objc var staggeraxis: StaggerAxis { get set }   // internal set only

    /// Hexagonal stagger index.
    @objc var staggerindex: StaggerIndex { get set } // internal set only
}



// MARK: - Extensions

extension TiledMappableGeometryType {

    // MARK: - Sizing

    /// Returns the width (in tiles) of the map.
    public var width: CGFloat {
        return mapSize.width
    }

    /// Returns the height (in tiles) of the map.
    public var height: CGFloat {
        return mapSize.height
    }

    /// Returns the size (in tiles) of the container halved.
    public var sizeHalved: CGSize {
        return CGSize(width: mapSize.width / 2, height: mapSize.height / 2)
    }

    /// Returns the tile width (in pixels) value.
    public var tileWidth: CGFloat {
        switch orientation {
            case .staggered:
                return CGFloat(Int(tileSize.width) & ~1)

            default:
                return tileSize.width
        }
    }

    /// Returns the tile height (in pixels) value.
    public var tileHeight: CGFloat {
        switch orientation {
            case .staggered:
                return CGFloat(Int(tileSize.height) & ~1)
            default:
                return tileSize.height
        }
    }

    /// Returns the tile size (in pixels) of the container halved.
    public var tileSizeHalved: CGSize {
        return CGSize(width: tileWidthHalf, height: tileHeightHalf)
    }


    /// Returns the tile size width, halved.
    public var tileWidthHalf: CGFloat {
        return tileWidth / 2
    }

    /// Returns the tile size hight, halved.
    public var tileHeightHalf: CGFloat {
        return tileHeight / 2
    }

    /// The size of the map, in points.
    public var sizeInPoints: CGSize {
        switch orientation {
            case .orthogonal:
                return CGSize(width: mapSize.width * tileSize.width, height: mapSize.height * tileSize.height)

            case .isometric:
                let side = width + height
                return CGSize(width: side * tileWidthHalf,  height: side * tileHeightHalf)

            case .hexagonal, .staggered:
                var result = CGSize.zero
                if staggerX == true {
                    result = CGSize(width: width * columnWidth + sideOffsetX,
                                    height: height * (tileHeight + sideLengthY))

                    if width > 1 { result.height += rowHeight }
                } else {
                    result = CGSize(width: width * (tileWidth + sideLengthX),
                                    height: height * rowHeight + sideOffsetY)

                    if height > 1 { result.width += columnWidth }
                }
                return result
        }
    }

    // MARK: - Geometry

    /// Returns the position of layer origin point (used to place tiles).
    public var origin: CGPoint {

        // TODO: add layerInfiniteOffset?
        switch orientation {

            case .orthogonal:
                return CGPoint.zero

            case .isometric:
                return CGPoint(x: height * tileWidthHalf, y: tileHeightHalf)

            case .hexagonal:
                let startPoint = CGPoint.zero
                //startPoint.x -= tileWidthHalf
                //startPoint.y -= tileHeightHalf
                return startPoint

            case .staggered:
                return CGPoint.zero
        }
    }


    // MARK: - Helpers

    /// Indicates the x-axis should be staggered.
    public var staggerX: Bool {
        return (staggeraxis == .x)
    }

    /// Indicates even rows should be staggered.
    public var staggerEven: Bool {
        return staggerindex == .even
    }

    /// Returns the side length for flat hexagons.
    public var sideLengthX: CGFloat {
        return (staggeraxis == .x) ? CGFloat(hexsidelength) : 0
    }

    public var sideLengthY: CGFloat {
        return (staggeraxis == .y) ? CGFloat(hexsidelength) : 0
    }

    public var sideOffsetX: CGFloat {
        return (tileSize.width - sideLengthX) / 2
    }

    public var sideOffsetY: CGFloat {
        return (tileSize.height - sideLengthY) / 2
    }

    public var columnWidth: CGFloat {
        return sideOffsetX + sideLengthX
    }

    public var rowHeight: CGFloat {
        return sideOffsetY + sideLengthY
    }

    /// Returns true if the given x-coordinate represents a staggered (offset) column.
    ///
    /// - Parameter x: map x-coordinate.
    /// - Returns: column should be staggered.
    internal func doStaggerX(_ x: Int) -> Bool {
        let hash: Int = (staggerEven == true) ? 1 : 0
        return staggerX && Bool((x & 1) ^ hash)
    }

    /// Returns true if the given y-coordinate represents a staggered (offset) row.
    ///
    /// - Parameter y: map y-coordinate.
    /// - Returns: row should be staggered.
    internal func doStaggerY(_ y: Int) -> Bool {
        let hash: Int = (staggerEven == true) ? 1 : 0
        return !staggerX && Bool((y & 1) ^ hash)
    }


    internal func topLeft(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        // if the value of y is odd & stagger index is odd
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y - 1)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        } else {
            // if the value of x is odd & stagger index is odd
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y)
            } else {
                return CGPoint(x: x - 1, y: y - 1)
            }
        }
    }

    internal func topRight(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y - 1)
            } else {
                return CGPoint(x: x, y: y - 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y)
            } else {
                return CGPoint(x: x + 1, y: y - 1)
            }
        }
    }

    internal func bottomLeft(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y + 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x - 1, y: y + 1)
            } else {
                return CGPoint(x: x - 1, y: y)
            }
        }
    }

    internal func bottomRight(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        if (staggerX == false) {
            if Bool((Int(y) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x, y: y + 1)
            }
        } else {
            if Bool((Int(x) & 1) ^ staggerindex.hashValue) {
                return CGPoint(x: x + 1, y: y + 1)
            } else {
                return CGPoint(x: x + 1, y: y)
            }
        }
    }

    // MARK: - Coordinate Conversion

    /// Returns a screen point for a given coordinate in the object (layer or map), with optional offset values for x/y.
    ///
    /// - Parameters:
    ///   - coord: tile coordinate.
    ///   - offsetX: x-offset value.
    ///   - offsetY: y-offset value.
    /// - Returns: point in layer (spritekit space).
    public func pointForCoordinate(coord: simd_int2,
                                   offsetX: CGFloat = 0,
                                   offsetY: CGFloat = 0) -> CGPoint {

        /// this point is in **Tiled space**.
        var screenPoint = tileToScreenCoords(coord: coord)

        var tileOffsetX: CGFloat = offsetX
        var tileOffsetY: CGFloat = offsetY

        // return a point at the center of the tile
        switch orientation {
            case .orthogonal:
                tileOffsetX += tileWidthHalf
                tileOffsetY += tileHeightHalf

            case .isometric:
                tileOffsetY += tileHeightHalf

            case .hexagonal, .staggered:
                tileOffsetX += tileWidthHalf
                tileOffsetY += tileHeightHalf
        }

        screenPoint.x += tileOffsetX
        screenPoint.y += tileOffsetY

        return floor(point: screenPoint.invertedY)
    }

    /// Returns a tile coordinate for a given screen point in the object (layer or map).
    ///
    /// - Parameter point: point in layer (spritekit space).
    /// - Returns: tile coordinate.
    public func coordinateForPoint(point: CGPoint) -> simd_int2 {
        return screenToTileCoords(point: point.invertedY)
    }

    // MARK: Internal Coordinate Mapping

    /// Returns a tile coordinate from a point in **Tiled map space**.
    ///
    /// - Parameter point: point in map space.
    /// - Returns: tile coordinate.
    internal func pixelToTileCoords(_ point: CGPoint) -> simd_int2 {
        switch orientation {
            case .orthogonal:
                let cx = floor(point.x / tileWidth)
                let cy = floor(point.y / tileHeight)
                return simd_int2(x: Int32(cx), y: Int32(cy))

            case .isometric:
                let cx = floor(point.x / tileHeight)
                let cy = floor(point.y / tileHeight)
                return simd_int2(x: Int32(cx), y: Int32(cy))

            case .hexagonal:
                return screenToTileCoords(point: point)

            case .staggered:
                return screenToTileCoords(point: point)
        }
    }

    /// Converts a tile coordinate to a coordinate in map space. Note that this function returns a point that needs to be converted to SpriteKit scene space.
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: point in map space.
    internal func tileToPixelCoords(coord: simd_int2) -> CGPoint {
        switch orientation {
            case .orthogonal:
                return CGPoint(x: CGFloat(coord.x * tileWidth), y: CGFloat(coord.y * tileHeight))
            case .isometric:
                return CGPoint(x: coord.x * tileHeight, y: coord.y * tileHeight)
            case .hexagonal:
                return tileToScreenCoords(coord: coord)
            case .staggered:
                return tileToScreenCoords(coord: coord)
        }
    }

    /// Converts a screen point **in Tiled space** to a tile coordinate. Note that this function expects SpriteKit points to be converted to Tiled scene space before being passed as input.
    ///
    /// This method is generally used when querying coordinates at touch/mouse events.
    ///
    /// - Parameter point: point in screen space.
    /// - Returns: tile coordinate.
    internal func screenToTileCoords(point: CGPoint) -> simd_int2 {

        // CHECKME: math here might be off. Is the result a tile coordinate or a *point in tile space*?
        var pixelX = point.x
        var pixelY = point.y

        switch orientation {

            case .orthogonal:
                return simd_int2(Int32(floor(pixelX / tileWidth)), Int32(floor(pixelY / tileHeight)))

            case .isometric:
                pixelX -= height * tileWidthHalf
                let tileY = pixelY / tileHeight
                let tileX = pixelX / tileWidth
                return simd_int2(Int32(floor(tileY + tileX)), Int32(floor(tileY - tileX)))

            case .hexagonal:

                // initial offset
                if (staggerX == true) {
                    pixelX -= (staggerEven) ? tileWidth : sideOffsetX
                } else {
                    pixelY -= (staggerEven) ? tileHeight : sideOffsetY
                }

                // reference coordinates on a grid aligned tile
                var referencePoint = CGPoint(x: floor(pixelX / (columnWidth * 2)),
                                             y: floor(pixelY / (rowHeight * 2)))


                // relative distance between hex centers
                let relative = CGVector(dx: pixelX - referencePoint.x * (columnWidth * 2),
                                        dy: pixelY - referencePoint.y * (rowHeight * 2))

                // reference point adjustment
                let indexOffset: CGFloat = (staggerEven == true) ? 1 : 0
                if (staggerX == true) {
                    referencePoint.x *= 2
                    referencePoint.x += indexOffset

                } else {
                    referencePoint.y *= 2
                    referencePoint.y += indexOffset
                }

                // get nearest hexagon
                var centers: [CGVector]

                // flat-topped
                if (staggerX == true) {
                    let left: Int = Int(sideLengthX / 2)
                    let centerX: Int = left + Int(columnWidth)
                    let centerY: Int = Int(tileHeight / 2)
                    centers = [CGVector(dx: left, dy: centerY),
                               CGVector(dx: centerX, dy: centerY - Int(rowHeight)),
                               CGVector(dx: centerX, dy: centerY + Int(rowHeight)),
                               CGVector(dx: centerX + Int(columnWidth), dy: centerY)
                    ]

                    // pointy
                } else {
                    let top: Int = Int(sideLengthY / 2)
                    let centerX: Int = Int(tileWidth / 2)
                    let centerY: Int = top + Int(rowHeight)

                    centers = [CGVector(dx: centerX, dy: top),
                               CGVector(dx: centerX - Int(columnWidth), dy: centerY),
                               CGVector(dx: centerX + Int(columnWidth), dy: centerY),
                               CGVector(dx: centerX, dy: centerY + Int(rowHeight))
                    ]
                }

                var nearest: Int = 0
                var minDist = CGFloat.greatestFiniteMagnitude

                // get the nearest center
                for i in 0..<4 {
                    let center = centers[i]
                    let dc = (center - relative).lengthSquared()
                    if (dc < minDist) {
                        minDist = dc
                        nearest = i
                    }
                }

                // flat
                let offsetsStaggerX: [CGPoint] = [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: 1, y: -1),
                    CGPoint(x: 1, y: 0),
                    CGPoint(x: 2, y: 0)
                ]

                //pointy
                let offsetsStaggerY: [CGPoint] = [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: -1, y: 1),
                    CGPoint(x: 0, y: 1),
                    CGPoint(x: 0, y: 2)
                ]

                let offsets: [CGPoint] = (staggerX == true) ? offsetsStaggerX : offsetsStaggerY
                let result = referencePoint + offsets[nearest]
                return result.toVec2


            case .staggered:

                if (staggerX == true) {
                    pixelX -= staggerEven ? sideOffsetX : 0
                } else {
                    pixelY -= staggerEven ? sideOffsetY : 0
                }

                // get a point in the reference grid
                var referencePoint = CGPoint(x: floor(pixelX / tileWidth), y: floor(pixelY / tileHeight))

                // relative x & y position to grid aligned tile
                var relativePoint = CGPoint(x: pixelX - referencePoint.x * tileWidth,
                                            y: pixelY - referencePoint.y * tileHeight)


                // make adjustments to reference point
                if (staggerX == true) {
                    relativePoint.x *= 2
                    if staggerEven {
                        referencePoint.x += 1
                    }
                } else {
                    referencePoint.y *= 2
                    if staggerEven {
                        referencePoint.y += 1
                    }
                }

                let delta: CGFloat = relativePoint.x * (tileHeight / tileWidth)

                // check if the screen position is in the corners
                if (sideOffsetY - delta > relativePoint.y) {
                    return topLeft(referencePoint.x, referencePoint.y).toVec2
                }

                if (-sideOffsetY + delta > relativePoint.y) {
                    return topRight(referencePoint.x, referencePoint.y).toVec2
                }

                if (sideOffsetY + delta < relativePoint.y) {
                    return bottomLeft(referencePoint.x, referencePoint.y).toVec2
                }

                if (sideOffsetY * 3 - delta < relativePoint.y) {
                    return bottomRight(referencePoint.x, referencePoint.y).toVec2
                }

                return referencePoint.toVec2
        }
    }

    /// Converts a tile coordinate into a screen point.
    ///
    /// - Parameter coord: tile coordinate.
    /// - Returns: point in screen space.
    internal func tileToScreenCoords(coord: simd_int2) -> CGPoint {

        switch orientation {

            case .orthogonal:
                return CGPoint(x: coord.x * tileWidth, y: coord.y * tileHeight)

            case .isometric:
                let x = coord.x
                let y = coord.y
                let originX = height * tileWidthHalf
                return CGPoint(x: (x - y) * tileWidthHalf + originX,
                               y: (x + y) * tileHeightHalf)

            case .hexagonal, .staggered:

                let tileX = Int(coord.x)
                let tileY = Int(coord.y)

                var pixelX: Int = 0
                var pixelY: Int = 0


                // flat
                if (staggerX) {
                    pixelY = tileY * Int(tileHeight + sideLengthY)
                    if doStaggerX(tileX) {
                        pixelY += Int(rowHeight)
                    }
                    pixelX = tileX * Int(columnWidth)

                    // pointy
                } else {
                    pixelX = tileX * Int(tileWidth + sideLengthX)
                    if doStaggerY(tileY) {
                        // hex error here?
                        pixelX += Int(columnWidth)
                    }

                    pixelY = tileY * Int(rowHeight)
                }

                return CGPoint(x: pixelX, y: pixelY)
        }
    }

    /// Converts a screen (isometric) coordinate to a coordinate in map space. Note that this function returns a point that needs to be converted to SpriteKit space.
    ///
    /// - Parameter point: point in screen space.
    /// - Returns: point in map space.
    internal func screenToPixelCoords(point: CGPoint) -> CGPoint {
        switch orientation {
            case .isometric:
                var x = point.x
                let y = point.y
                x -= height * tileWidthHalf
                let tileY = y / tileHeight
                let tileX = x / tileWidth

                return CGPoint(x: (tileY + tileX) * tileHeight,
                               y: (tileY - tileX) * tileHeight)
            default:
                return point
        }
    }

    /// Converts a coordinate in map space to screen space. See: [Stack Overflow](http://stackoverflow.com/questions/24747420/tiled-map-editor-size-of-isometric-tile-side) link.
    ///
    /// - Parameter point:  point in map space.
    /// - Returns: point in screen space.
    internal func pixelToScreenCoords(point: CGPoint) -> CGPoint {
        var mutablePoint = point

        // infinite offset
        if (isInfinite == true) {
            mutablePoint.x -= tileWidth
            mutablePoint.y += tileHeightHalf
        }

        switch orientation {
            case .isometric:
                let originX = height * tileWidth / 2
                let tileY = point.y / tileHeight
                let tileX = point.x / tileHeight

                return CGPoint(x: (tileX - tileY) * tileWidth / 2 + originX,
                               y: (tileX + tileY) * tileHeight / 2)
            default:
                return mutablePoint
        }
    }
}


// MARK: - Extensions


extension TiledMappableGeometryType {
    /*
     u_tile_w: tile width
     u_tile_h: tile height
     u_size_w: number of tiles in x
     u_size_h: number of tiles in y
     */
    /// Returns an array of shader unforms based on the current attributes.
    public var shaderUniforms: [SKUniform] {
        let uniforms: [SKUniform] = [
            SKUniform(name: "u_tile_w", float: Float(tileWidth)),
            SKUniform(name: "u_tile_h", float: Float(tileHeight)),
            SKUniform(name: "u_size_w", float: Float(mapSize.width)),
            SKUniform(name: "u_size_h", float: Float(mapSize.height))
        ]
        return uniforms
    }
}
