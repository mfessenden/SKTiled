//
//  ButtonNode.swift
//  SKTiled
//
//  Created by Michael Fessenden on 4/18/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit
#if os(iOS)
import UIKit
#else
import Cocoa
#endif


protocol ButtonNodeResponderType: class {
    func buttonTriggered(_ button: ButtonNode)
}


open class ButtonNode: SKSpriteNode {
    
    open var buttonAction: () -> ()
    
    // textures
    open var selectedTexture: SKTexture!
    open var hoveredTexture: SKTexture!
    open var defaultTexture: SKTexture! {
        didSet {
            defaultTexture.filteringMode = .nearest
            self.texture = defaultTexture
        }
    }
    
    open var disabled: Bool = false {
        didSet {
            guard oldValue != disabled else { return }
            isUserInteractionEnabled = !disabled
        }
    }
    
    // actions to show highlight scaling & hover (OSX)
    fileprivate let scaleAction: SKAction = SKAction.scale(by: 0.95, duration: 0.025)
    fileprivate let hoverAction: SKAction = SKAction.colorize(with: SKColor.white, colorBlendFactor: 0.5, duration: 0.025)
    
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
    
    override open var isUserInteractionEnabled: Bool {
        didSet {
            guard oldValue != isUserInteractionEnabled else { return }
            color = isUserInteractionEnabled ? SKColor.clear : SKColor.gray
            colorBlendFactor = isUserInteractionEnabled ? 0 : 0.8
        }
    }
    
    /**
     Runs the trigger action.
     */
    open func buttonTriggered() {
        if isUserInteractionEnabled {
            buttonAction()
        }
    }
    
    // swap textures when button is pressed
    open var wasPressed = false {
        didSet {
            // Guard against repeating the same action.
            guard oldValue != wasPressed else { return }
            let action = wasPressed ? scaleAction : scaleAction.reversed()
            run(action)
        }
    }
    
    // swap textures when mouse hovers
    open var mouseHover = false {
        didSet {
            // Guard against repeating the same action.
            guard oldValue != mouseHover else { return }
            texture = mouseHover ? selectedTexture : defaultTexture
            let action = mouseHover ? hoverAction : hoverAction.reversed()
            run(action)
        }
    }
}

#if os(iOS)
public extension ButtonNode {
    
    // MARK: - Touch Handling
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if isUserInteractionEnabled {
            wasPressed = true
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        wasPressed = false
        if containsTouches(touches) {
            buttonTriggered()
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        wasPressed = false
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
}
#endif


#if os(OSX)
extension ButtonNode {
    
    override open func mouseEntered(with event: NSEvent) {
        if isUserInteractionEnabled {
            if containsEvent(event){
                mouseHover = true
            }
        }
    }
    
    override open func mouseExited(with event: NSEvent) {
        mouseHover = false
    }
    
    override open func mouseDown(with event: NSEvent) {
        if isUserInteractionEnabled {
            wasPressed = true
        }
    }
    
    override open func mouseUp(with event: NSEvent) {
        wasPressed = false
        if containsEvent(event) {
            buttonTriggered()
        }
    }
    
    /**
     Returns true if any of the touches are within the `ButtonNode` body.
     
     - parameter touches: `Set<UITouch>`
     - returns: `Bool` button was touched.
     */
    fileprivate func containsEvent(_ event: NSEvent) -> Bool {
        guard let scene = scene else { fatalError("Button must be used within a scene.") }
        let touchedNode = scene.atPoint(event.location(in: scene))
        return touchedNode === self || touchedNode.inParentHierarchy(self)
    }
}
#endif
