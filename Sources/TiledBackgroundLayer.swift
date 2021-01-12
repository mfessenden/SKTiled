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


/// ## Overview
///
/// The `TiledBackgroundLayer` object represents the default background for a tilemap.
internal class TiledBackgroundLayer: TiledLayerObject {
    
    /// Sprite to hold the background color.
    private weak var sprite: SKSpriteNode?
    
    /// The debug color.
    private var _debugColor: SKColor?
    
    /// Background offset.
    public var frameOffset: CGSize = CGSize.zero {
        didSet {
            guard (oldValue != frameOffset) else { return }
            sprite?.size.width += frameOffset.width
            sprite?.size.height += frameOffset.height
        }
    }
    
    /// The background color.
    override var color: SKColor {
        didSet {
            guard let sprite = sprite else { return }
            sprite.color = (_debugColor == nil) ? color : _debugColor!
        }
    }
    
    /// Layer color blend factor.
    override var colorBlendFactor: CGFloat {
        didSet {
            guard let sprite = sprite else { return }
            sprite.colorBlendFactor = colorBlendFactor
        }
    }
    
    // MARK: - Init
    
    /// Initialize with a parent `SKTilemap` node.
    ///
    /// - Parameter tilemap: parent tilemap node.
    override init(tilemap: SKTilemap) {
        super.init(layerName: "MAP_BACKGROUND_LAYER", tilemap: tilemap)
        layerType = .none
        index = 0
        
        let spriteNode = SKSpriteNode(texture: nil, color: tilemap.backgroundColor ?? SKColor.clear, size: tilemap.sizeInPoints)
        
        #if SKTILED_DEMO
        spriteNode.setAttr(key: "tiled-node-name", value: "overlay")
        #endif
        spriteNode.name = "MAP_BACKGROUND_SPRITE"
        addChild(spriteNode)
        
        // position sprite
        spriteNode.position.x += tilemap.sizeInPoints.width / 2
        spriteNode.position.y -= tilemap.sizeInPoints.height / 2
        
        // frame offset
        spriteNode.size.width += tilemap.backgroundOffset.width
        spriteNode.size.height += tilemap.backgroundOffset.height
        
        sprite = spriteNode
    }
    
    /// Set the color of the background node.
    ///
    /// - Parameter color: parent map.
    public func setBackground(color: SKColor) {
        self.sprite?.color = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



// MARK: - Extensions


extension TiledBackgroundLayer {
    
    
    /// Returns the internal **Tiled** node type.
    @objc public override var tiledNodeName: String {
        return "background"
    }
    
    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return "Background Layer"
    }
    
    /// Returns the internal **Tiled** node type icon.
    @objc public override var tiledIconName: String {
        return "background-icon"
    }
    
    /// A description of the node.
    @objc public override var tiledListDescription: String {
        return "\(tiledNodeNiceName): color \(color.hexString())"
    }
    
    /// A description of the node.
    @objc public override var tiledDescription: String {
        return "Layer type for map background color."
    }
}
