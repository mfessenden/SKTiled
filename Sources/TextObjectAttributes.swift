//
//  TextObjectAttributes.swift
//  SKTiled
//
//  Copyright ©2016-2021 Michael Fessenden. all rights reserved.
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


/// The `TextObjectAttributes` structure is used for managing basic font rendering attributes for **[text objects][text-objects-url]**.
///
/// ### Properties
///
/// - `fontName`: font name.
/// - `fontSize`: font size.
/// - `fontColor`: font color.
/// - `alignment`: horizontal/vertical text alignment.
/// - `wrap`: text wraps.
/// - `isBold`: text is **bold**.
/// - `isItalic`: text is *italicized*.
/// - `isUnderline`: text is <u>underlined</u>.
/// - `renderQuality`: font scaling attribute.
///
/// [text-objects-url]:https://doc.mapeditor.org/en/stable/manual/objects/#insert-text
public struct TextObjectAttributes {

    /// Font name.
    public var fontName: String  = "Arial"

    /// Font size.
    public var fontSize: CGFloat = 16

    /// Font color.
    public var fontColor: SKColor = SKColor.black

    /// Structure describing text alignment.
    ///
    /// ### Properties
    ///
    /// - `horizontal`: Horizontal text alignment.
    /// - `vertical`: Vertical text alignment.
    ///
    public struct TextAlignment {

        var horizontal: HoriztonalAlignment = HoriztonalAlignment.left
        var vertical: VerticalAlignment = VerticalAlignment.top

        /// Horizontal text alignment.
        enum HoriztonalAlignment: String {
            case left
            case center
            case right
        }

        /// Vertical text alignment.
        enum VerticalAlignment: String {
            case top
            case center
            case bottom
        }
    }

    /// Text alignment.
    public var alignment: TextAlignment = TextAlignment()

    /// Text is wrapped.
    public var wrap: Bool = true

    /// Text is bolded.
    public var isBold: Bool = false

    /// Text is italicized.
    public var isItalic: Bool = false

    /// Text is underlined.
    public var isUnderline: Bool = false

    /// Text is has a strike through it.
    public var isStrikeout: Bool = false

    /// Font scaling property. Increase this value to increase text clarity at higher resolutions.
    public var renderQuality: CGFloat = TiledGlobals.default.renderQuality.text

    /// Default initializer.
    public init() {}

    /// Initialize with basic font attributes.
    ///
    /// - Parameters:
    ///   - font: font name.
    ///   - size: font size.
    ///   - color: font color.
    public init(font: String, size: CGFloat, color: SKColor = .black) {
        fontName = font
        fontSize = size
        fontColor = color
    }
}


// MARK: - Extensions


extension TextObjectAttributes {

    #if os(iOS) || os(tvOS)

    /// Returns a font for the text object attributes, if available (iOS & tvOS).
    public var font: UIFont {
        if let uifont = UIFont(name: fontName, size: fontSize * renderQuality) {
            return uifont
        }
        return UIFont.systemFont(ofSize: fontSize * renderQuality)
    }
    #else

    /// Returns a font for the text object attributes, if available (macOS).
    public var font: NSFont {
        if let nsfont = NSFont(name: fontName, size: fontSize * renderQuality) {
            return nsfont
        }
        return NSFont.systemFont(ofSize: fontSize * renderQuality)
    }
    #endif
}


extension TextObjectAttributes.TextAlignment.HoriztonalAlignment {

    #if os(iOS) || os(tvOS)
    /// Return a integer value for passing to NSTextAlignment.
    public var intValue: Int {
        switch self {
            case .left:
                return 0
            case .right:
                return 1
            case .center:
                return 2
        }
    }
    #else
    /// Return a integer value for passing to NSTextAlignment.
    public var intValue: UInt {
        switch self {
            case .left:
                return 0
            case .right:
                return 1
            case .center:
                return 2
        }
    }
    #endif
}


extension TextObjectAttributes.TextAlignment.VerticalAlignment {

    #if os(iOS) || os(tvOS)
    /// Return a integer value for passing to NSTextAlignment.
    public var intValue: Int {
        switch self {
            case .top:
                return 0
            case .center:
                return 1
            case .bottom:
                return 2
        }
    }
    #else
    /// Return a integer value for passing to NSTextAlignment.
    public var intValue: UInt {
        switch self {
            case .top:
                return 0
            case .center:
                return 1
            case .bottom:
                return 2
        }
    }
    #endif
}
