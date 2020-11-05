//
//  TiledBackgroundLayer.swift
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

import SpriteKit

/**
 The `BackgroundLayer` object represents the default background for a tilemap.
 */
internal class BackgroundLayer: SKTiledLayerObject {

    private var sprite: SKSpriteNode!
    private var _debugColor: SKColor?

    override var color: SKColor {
        didSet {
            guard let sprite = sprite else { return }
            sprite.color = (_debugColor == nil) ? color : _debugColor!
        }
    }

    override var colorBlendFactor: CGFloat {
        didSet {
            guard let sprite = sprite else { return }
            sprite.colorBlendFactor = colorBlendFactor
        }
    }

    // MARK: - Init
    
    /**
     Initialize with the parent `SKTilemap` node.

     - parameter tilemap:   `SKTilemap` parent map.
     */
    public init(tilemap: SKTilemap) {
        super.init(layerName: "DEFAULT", tilemap: tilemap)
        layerType = .none
        index = -1
        sprite = SKSpriteNode(texture: nil, color: tilemap.backgroundColor ?? SKColor.clear, size: tilemap.sizeInPoints)
        addChild(self.sprite!)

        // position sprite
        sprite!.position.x += tilemap.sizeInPoints.width / 2
        sprite!.position.y -= tilemap.sizeInPoints.height / 2
    }

    /**
     Set the color of the background node.

     - parameter tilemap:   `SKTilemap` parent map.
     */
    public func setBackground(color: SKColor) {
        self.sprite?.color = color
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Updating: Background Layer

    /**
     Update the background layer before each frame is rendered.

     - parameter currentTime: `TimeInterval` update interval.
     */
    override public func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
    }
}
