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
    func buttonTriggered(button: ButtonNode)
}


public class ButtonNode: SKSpriteNode {
    
    public var buttonAction: () -> ()
    
    // textures
    public var selectedTexture: SKTexture!
    public var defaultTexture: SKTexture! {
        didSet {
            defaultTexture.filteringMode = .Nearest
            self.texture = defaultTexture
        }
    }
    
    public var disabled: Bool = false {
        didSet {
            guard oldValue != disabled else { return }
            userInteractionEnabled = !disabled
        }
    }
    
    // action to show highlight scaling
    private let scaleAction: SKAction = SKAction.scaleBy(1.15, duration: 0.05)
    
    public init(defaultImage: String, highlightImage: String, action: () -> ()) {
        buttonAction = action
        
        defaultTexture = SKTexture(imageNamed: defaultImage)
        selectedTexture = SKTexture(imageNamed: highlightImage)
        
        defaultTexture.filteringMode = .Nearest
        selectedTexture.filteringMode = .Nearest
        
        super.init(texture: defaultTexture, color: SKColor.clearColor(), size: defaultTexture.size())
        userInteractionEnabled = true
    }
    
    public init(texture: SKTexture, highlightTexture: SKTexture, action: () -> ()) {
        defaultTexture = texture
        selectedTexture = highlightTexture
        buttonAction = action
        
        defaultTexture.filteringMode = .Nearest
        selectedTexture.filteringMode = .Nearest
        
        super.init(texture: defaultTexture, color: SKColor.clearColor(), size: texture.size())
        userInteractionEnabled = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        buttonAction = { _ in }
        super.init(coder: aDecoder)
    }
    
    override public var userInteractionEnabled: Bool {
        didSet {
            guard oldValue != userInteractionEnabled else { return }
            color = userInteractionEnabled ? SKColor.clearColor() : SKColor.grayColor()
            colorBlendFactor = userInteractionEnabled ? 0 : 0.8
        }
    }
    
    // swap textures when button is pressed
    public var wasPressed = false {
        didSet {
            // Guard against repeating the same action.
            guard oldValue != wasPressed else { return }
            texture = wasPressed ? selectedTexture : defaultTexture
            let action = wasPressed ? scaleAction : scaleAction.reversedAction()
            runAction(action)
        }
    }
    
    // MARK: - Touch Handling
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        if userInteractionEnabled {
            wasPressed = true
        }
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        wasPressed = false
        if containsTouches(touches) {
            buttonTriggered()
        }
    }
    
    override public func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        wasPressed = false
    }
    
    /**
     Runs the trigger action.
     */
    public func buttonTriggered() {
        if userInteractionEnabled {
            buttonAction()
        }
    }
    
    /**
     Returns true if any of the touches are within the `ButtonNode` body.
     
     - parameter touches: `Set<UITouch>`
     
     - returns: `Bool` button was touched.
     */
    private func containsTouches(touches: Set<UITouch>) -> Bool {
        guard let scene = scene else { fatalError("Button must be used within a scene.") }
        return touches.contains { touch in
            let touchPoint = touch.locationInNode(scene)
            let touchedNode = scene.nodeAtPoint(touchPoint)
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
