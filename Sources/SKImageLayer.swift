//
//  SKImageLayer.swift
//  SKTiled
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
//	Web: https://github.com/mfessenden
//	Email: michael.fessenden@gmail.com
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
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


/// ## Overview
///
/// The `SKImageLayer` object is really nothing more than a sprite with positioning attributes.
///
/// ### Properties
///
/// | Property | Description        |
/// |:---------|:-------------------|
/// | image    | Layer image name.  |
/// | wrapX    | Wrap horizontally. |
/// | wrapY    | Wrap vertically.   |
///
///
/// ### Methods
///
/// | Method          | Description              |
/// |:----------------|:-------------------------|
/// | setLayerImage   | Set the layer's image.   |
/// | setLayerTexture | Set the layer's texture. |
/// | wrapY           | Wrap vertically.         |
///
/// ### Usage
///
/// Set the layer image with:
///
/// ```swift
/// imageLayer.setLayerImage("clouds-background")
/// ```
public class SKImageLayer: TiledLayerObject {

    /// Layer image name.
    public var image: String!

    /// Layer texture values.
    private var textures: [SKTexture] = []

    /// Layer sprite instance.
    private var sprite: SKSpriteNode?

    /// Layer wraps horizontally.
    public var wrapX: Bool = false

    /// Layer wraps vertically.
    public var wrapY: Bool = false

    // MARK: - Initialization

    /// Initialize with a layer name, and parent `SKTilemap` node.
    ///
    /// - Parameters:
    ///   - layerName: image layer name.
    ///   - tilemap: parent map.
    public override init(layerName: String, tilemap: SKTilemap) {
        super.init(layerName: layerName, tilemap: tilemap)
        self.layerType = .image
    }

    /// Initialize with parent `SKTilemap` and layer attributes.
    ///
    /// **Do not use this intializer directly**
    ///
    /// - Parameters:
    ///   - tilemap: parent tilemap.
    ///   - attributes: layer attributes.
    public init?(tilemap: SKTilemap, attributes: [String: String]) {
        let layerName = attributes["name"] ?? "null"
        super.init(layerName: layerName, tilemap: tilemap, attributes: attributes)
        self.layerType = .image
    }

    /// Set the layer image as a sprite.
    ///
    /// - Parameter named: image name.
    public func setLayerImage(_ named: String) {
        self.image = named

        let texture = addTexture(imageNamed: named)
        let textureSize = texture.size()

        self.sprite = SKSpriteNode(texture: texture)
        addChild(self.sprite!)

        self.sprite!.position.x += textureSize.width / 2
        self.sprite!.position.y -= textureSize.height / 2.0
    }

    /// Update the layer texture.
    ///
    /// - Parameter texture: layer image texture.
    public func setLayerTexture(texture: SKTexture) {
        self.sprite = SKSpriteNode(texture: texture)
        addChild(self.sprite!)
    }

    /// Set the layer texture with an image name.
    ///
    /// - Parameter named: image name.
    /// - Returns: texture added.
    private func addTexture(imageNamed named: String) -> SKTexture {
        let inputURL = URL(fileURLWithPath: named)
        // read image from file
        guard let imageDataProvider = CGDataProvider(url: inputURL as CFURL) else {
            let errorMsg = "Image read error: '\(named)'"
            self.log(errorMsg, level: .fatal)
            fatalError(errorMsg)
        }
        
        // creare a data provider
        let image = CGImage(pngDataProviderSource: imageDataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!

        // create the texture
        let sourceTexture = SKTexture(cgImage: image)
        sourceTexture.filteringMode = .nearest
        textures.append(sourceTexture)
        return sourceTexture
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Updating


    /// Update the image layer before each frame is rendered.
    ///
    /// - Parameter currentTime: update interval.
    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
    }

    // MARK: - Debugging

    /// Returns the internal **Tiled** node type.
    @objc public var tiledNodeName: String {
        return "imagelayer"
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public override var tiledNodeNiceName: String {
        return "Image Layer"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public override var tiledIconName: String {
        return "imagelayer-icon"
    }

    /// A description of the node.
    @objc public override var tiledDescription: String {
        return "Tiled image layer type."
    }
}
