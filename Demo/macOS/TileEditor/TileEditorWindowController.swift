//
//  TileEditorWindowController.swift
//  SKTiled Demo - macOS
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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


class TileEditorWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        // keep the window on top until closed
        window?.level = .floating

        // set the window title
        window?.title = "Tile Editor"

        // set the correct size
        window?.setContentSize(NSSize(width: 350, height: 250))
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide the window instead of closing
        self.window?.orderOut(sender)
        return false
    }
}


// MARK: - Extensions


extension TileEditorWindowController {

    // MARK: Storyboard instantiation
    
    static func newTileEditorWindow() -> TileEditorWindowController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("TileEditorWindowController")
        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? TileEditorWindowController else {
            fatalError("cannot access 'TileEditorWindowController' in 'Main' storyboard.")
        }
        return windowController
    }
}
