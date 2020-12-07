//
//  SKTiled.h
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

@import Foundation;

FOUNDATION_EXPORT double SKTiledVersionNumber;
FOUNDATION_EXPORT const unsigned char SKTiledVersionString[];

/// ## Overview
///
/// A structure representing debug drawing options for **SKTiled** objects.
///
/// ### Usage
///
/// ```swift
/// // show the map's grid & bounds shape
/// tilemap.debugDrawOptions = [.drawGrid, .drawFrame]
///
/// // turn off layer grid visibility
/// layer.debugDrawOptions.remove(.drawGrid)
/// ```
///
/// ### Properties
///
/// | Property            | Description                              |
/// |:------------------- |:---------------------------------------- |
/// | drawGrid            | Visualize the nodes's tile grid.         |
/// | drawFrame           | Visualize the nodes's bounding rect.     |
/// | drawGraph           | Visualize the nodes's pathfinding graph. |
/// | drawObjectFrames    | Draw object's bounding shapes.           |
/// | drawAnchor          | Draw the layer's anchor point.           |
///
typedef NS_OPTIONS(NSInteger, DebugDrawOptions) {
    drawGrid              = 1 << 0,
    drawFrame             = 1 << 1,
    drawGraph             = 1 << 2,
    drawObjectFrames      = 1 << 3,
    drawAnchor            = 1 << 4,
};

/// ## Overview
///
/// This describes the tilemap orientation type.
///
/// ### Constants
///
/// | Property      | Description                                   |
/// |:-------------:|:----------------------------------------------|
/// | `orthogonal`  | Orthogonal(square tiles) tile map.            |
/// | `isometric`   | Isometric tile map.                           |
/// | `hexagonal`   | Hexagonal tile map.                           |
/// | `staggered`   | Staggered isometric tile map.                 |
///
typedef NS_CLOSED_ENUM(uint8_t, TilemapOrientation) {
    orthogonal,
    isometric,
    hexagonal,
    staggered,
};

/// Hexagonal stagger axis.
///
/// - `x`: axis is along the x-coordinate.
/// - `y`: axis is along the y-coordinate.
typedef NS_CLOSED_ENUM(uint8_t, StaggerAxis) {
    x,
    y,
};

/// Hexagonal stagger index.
///
/// - `even`: stagger evens.
/// - `odd`:  stagger odds.
typedef NS_CLOSED_ENUM(uint8_t, StaggerIndex) {
    odd,
    even,
};
