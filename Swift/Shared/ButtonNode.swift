//
//  ButtonNode.swift
//  SKTiled
//
//  Created by Michael Fessenden on 4/18/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit


protocol ButtonNodeResponderType: class {
    func buttonTriggered(_ button: ButtonNode)
}


public class ButtonNode: SKSpriteNode {
    
    public var buttonAction: () -> ()
    
    // textures
    public var selectedTexture: SKTexture!
    public var defaultTexture: SKTexture! {
        didSet {
            defaultTexture.filteringMode = .nearest
            self.texture = defaultTexture
        }
    }
    
    public var disabled: Bool = false {
        didSet {
            guard oldValue != disabled else { return }
            isUserInteractionEnabled = !disabled
        }
    }
    
    // action to show highlight scaling
    fileprivate let scaleAction: SKAction = SKAction.scale(by: 1.15, duration: 0.05)
    
    public init(defaultImage: String, highlightImage: String, action: @escaping () -> ()) {
        buttonAction = action
        
        defaultTexture = SKTexture(imageNamed: defaultImage)
        selectedTexture = SKTexture(imageNamed: highlightImage)
        
        defaultTexture.filteringMode = .nearest
        selectedTexture.filteringMode = .nearest
        
        super.init(texture: defaultTexture, color: SKColor.clear, size: defaultTexture.size())
        isUserInteractionEnabled = true
    }
    
    public init(texture: SKTexture, highlightTexture: SKTexture, action: @escaping () -> ()) {
        defaultTexture = texture
        selectedTexture = highlightTexture
        buttonAction = action
        
        defaultTexture.filteringMode = .nearest
        selectedTexture.filteringMode = .nearest
        
        super.init(texture: defaultTexture, color: SKColor.clear, size: texture.size())
        isUserInteractionEnabled = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        buttonAction = { _ in }
        super.init(coder: aDecoder)
    }
    
    override public var isUserInteractionEnabled: Bool {
        didSet {
            guard oldValue != isUserInteractionEnabled else { return }
            color = isUserInteractionEnabled ? SKColor.clear : SKColor.gray
            colorBlendFactor = isUserInteractionEnabled ? 0 : 0.8
        }
    }
    
    // swap textures when button is pressed
    public var wasPressed = false {
        didSet {
            // Guard against repeating the same action.
            guard oldValue != wasPressed else { return }
            texture = wasPressed ? selectedTexture : defaultTexture
            let action = wasPressed ? scaleAction : scaleAction.reversed()
            run(action)
        }
    }
    
    // MARK: - Touch Handling
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if isUserInteractionEnabled {
            wasPressed = true
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        wasPressed = false
        if containsTouches(touches) {
            buttonTriggered()
        }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
        wasPressed = false
    }
    
    /**
     Runs the trigger action.
     */
    public func buttonTriggered() {
        if isUserInteractionEnabled {
            buttonAction()
        }
    }
    
    /**
     Returns true if any of the touches are within the `ButtonNode` body.
     
     - parameter touches: `Set<UITouch>`
     
     - returns: `Bool` button was touched.
     */
    fileprivate func containsTouches(_ touches: Set<UITouch>) -> Bool {
        guard let scene = scene else { fatalError("Button must be used within a scene.") }
        return touches.contains { touch in
            let touchPoint = touch.location(in: scene)
            let touchedNode = scene.atPoint(touchPoint)
            return touchedNode === self || touchedNode.inParentHierarchy(self)
        }
    }
    
    /**
     Returns a representation for use in playgrounds.
     
     - returns: `AnyObject?` visual representation.
     */
    public func debugQuickLookObject() -> AnyObject? {
        return defaultTexture
    }
}
