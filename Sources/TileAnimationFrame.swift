//
//  TileAnimationFrame.swift
//  SKTiled
//
//  Created by Michael Fessenden.
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


/**
 
 ## Overview
 
 A structure representing a single frame of animation. Time is stored in milliseconds.
 
 ### Properties
 
 | Property | Description             |
 |----------|-------------------------|
 | id       | unique tile (local) id. |
 | duration | frame duration.         |
 | texture  | optional tile texture.  |
 
 */
public class TileAnimationFrame: NSObject {
    
    /// Frame tile id.
    public var id: Int = 0
    
    /// Frame duration.
    public var duration: Int = 0
    
    /// Frame texture.
    public var texture: SKTexture?
    
    /**
     Initialize with an id, frame duration and texture.
     
     - parameter id: `Int` tile id.
     - parameter duration: `Int` frame duration.
     - parameter texture: `SKTexture?` frame texture.
     */
    public init(id: Int, duration: Int, texture: SKTexture? = nil) {
        super.init()
        self.id = id
        self.duration = duration
        self.texture = texture
    }
}


// MARK: - Extensions


extension TileAnimationFrame {
    
    /// Frame description.
    override public var description: String {
        return "Frame: \(id): \(duration)"
    }
    
    override public var debugDescription: String {
        return "<\(description)>"
    }
}
