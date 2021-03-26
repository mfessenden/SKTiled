//
//  InspectorMainSplitViewController.swift
//  SKTiled Demo - macOS
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

import Cocoa

/// This class manages the
class InspectorMainSplitViewController: NSSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var acceptsFirstResponder: Bool {
        return false
    }


    
    func resizeInterface(for newSize: NSSize) {
        let totalWidth = newSize.width
        treeViewController.view.frame.size.width = totalWidth / 2.6
    }
    
    
    /// Returns the attribute editor controller.
    private var treeViewController: NSViewController {
        let leftSplitViewItem = splitViewItems[0]
        return leftSplitViewItem.viewController
    }
    
    /// Returns the attribute editor controller.
    private var detailViewController: NSViewController {
        let rightSplitViewItem = splitViewItems[1]
        return rightSplitViewItem.viewController
    }
    
}


// MARK: - Extensions


extension InspectorMainSplitViewController {
    
    /// Handle key down events.
    ///
    /// - Parameter event: key press event.
    override func keyDown(with event: NSEvent) {
        guard let keysPressed = event.characters else {
            return
        }
        
        if (keysPressed == "r") {
            
            // refresh the inspector ui
            NotificationCenter.default.post(
                name: Notification.Name.Demo.RefreshInspectorInterface,
                object: nil
            )
            
            updateCommandString("refreshing Inspector...", duration: 4)
        }
        
        if (keysPressed == "d") {
            
            // dump stored attributes
            NotificationCenter.default.post(
                name: Notification.Name.Debug.DumpAttributeStorage,
                object: nil
            )
            
            
            updateCommandString("dumping attribute storage...", duration: 4)
        }

    }
}
