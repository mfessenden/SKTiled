//
//  TiledSelectableType.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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


/// :nodoc:
@objc public protocol TiledSelectableType {

    /// Represents a node type that can be interacted with.
    @objc optional var canReceiveFocus: Bool { get }
    
    /// Indicates the current node has received focus or selected.
    @objc var isFocused: Bool { get set }
}



// MARK: - Extensions

extension TiledSelectableType where Self: SKNode {
    
    /// Flag the node as focused for a specified duration.
    ///
    /// - Parameter duration: focus time
    public func setFocused(for duration: TimeInterval) {
        isFocused = true
        let unfocusAction = SKAction.afterDelay(duration, runBlock: {
            self.isFocused = false
        })
        run(unfocusAction)
    }
}



extension Sequence where Element: SKNode {
    
    /// Set all nodes focused.
    public func focusAll() {
        for node in self {
            if let tiledSelectable = node as? TiledSelectableType {
                tiledSelectable.isFocused = true
            }
        }
    }
    
    
    /// Set all nodes unfocused.
    public func unfocusAll() {
        for node in self {
            if let tiledSelectable = node as? TiledSelectableType {
                tiledSelectable.isFocused = false
            } else {
                node.removeHighlight()
            }
        }
    }
}

