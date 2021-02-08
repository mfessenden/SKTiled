//
//  DebugDrawOptions.h
//  SKTiled
//
//  Copyright © 2021 Michael Fessenden. all rights reserved.
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

#import <Foundation/Foundation.h>
// #import <Cocoa/Cocoa.h>

#ifndef DebugDrawOptions_h
#define DebugDrawOptions_h


/// The `DebugDrawOptions` structure represents debug drawing options for **SKTiled** objects.
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
/// - `drawGrid`: visualize the nodes's tile grid.
/// - `drawFrame`: visualize the nodes's bounding rect.
/// - `drawGraph`: visualize the nodes's pathfinding graph.
/// - `drawObjectFrames`: draw object's bounding shapes.
/// - `drawAnchor`: draw the layer's anchor point.           
///
typedef NS_OPTIONS(NSInteger, DebugDrawOptions) {
    drawGrid              = 1 << 0,
    drawFrame             = 1 << 1,
    drawGraph             = 1 << 2,
    drawObjectFrames      = 1 << 3,
    drawAnchor            = 1 << 4,
};


#endif /* DebugDrawOptions_h */
