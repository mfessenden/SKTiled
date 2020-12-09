//
//  SKTemplateObject.swift
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



internal class SKTemplateObject {
    
    /// The filename for the template (ie: 'green-dragon.tx', 'User/Templaes/green-dragon.tx'). This should be relative to the document root.
    var templateFileName: String
    
    /// The referencing tileset.
    var tileset: SKTileset?
    
    /// Initialize with the template file name.
    ///
    /// - Parameter txFile: template file name.
    init(txFile: String) {
        templateFileName = txFile
    }
}



// MARK: - Extensions



extension SKTemplateObject {
    
    /// Copy attributes to a referencing object. See `SKTileObject.setObjectAttributesFromTemplateAttributes(attributes:)` method.
    ///
    /// - Parameter other: object referencing this template.
    func merge(with other: SKTileObject) {
        
    }
    
}
