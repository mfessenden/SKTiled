//
//  TileID.swift
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


/// ## Overview
///
/// The `TileFlags` option set represents the various transformation flags that can be set for a given tile.
///
/// ### Properties
///
/// | Property         | Description                               |
/// |:---------------- |:----------------------------------------- |
/// | `none`           | tile is rendered with no transformations. |
/// | `flipHorizontal` | tile is flipped on the x-axis.            |
/// | `flipVertical`   | tile is flipped on the y-axis.            |
/// | `flipDiagonal`   | tile is rotated.                          |
///
public struct TileFlags: OptionSet {

    public let rawValue: UInt32

    public static let none             = TileFlags([])
    public static let flipHorizontal   = TileFlags(rawValue: 1 << 31)
    public static let flipVertical     = TileFlags(rawValue: 1 << 30)
    public static let flipDiagonal     = TileFlags(rawValue: 1 << 29)
    public static let mask: UInt32     = ~(TileFlags.all.rawValue)

    public static let all: TileFlags = [.flipHorizontal, .flipVertical, .flipDiagonal]

    public init(rawValue: UInt32 = 0) {
        self.rawValue = rawValue
    }
}


/// ## Overview
///
/// The `TileID`structure provides an interface to a **[masked tile id][flip-flags-url]**.
///
/// Tile flipping is represented by a mask of a tile global id, with the upper three bits storing orientation values (flipped horizontally, flipped vertically, flipped diagonally).
///
/// ## Usage
///
/// This structure is not meant to be used directly; simply passing a value to the **[`SKTile.tileId`][sktile-tileid-url]** property will set the global id and orientation of the tile.
///
/// See the [**Working with Tiles**][working-with-tiles-url] documentation for more information.
///
/// ```swift
/// // A raw value of 2147483659 translates to 11, flipped horizontally.
/// let gid: UInt32 = 2147483659
/// var tileId = TileID(wrappedValue: 2147483659)
/// print(tileId)
/// // Tile ID: 11, flags: [ hFlip ]
///
/// // Alternately, we can set the flags directly:
/// tileId.flags = [.all]
/// print(tileId)
/// // Tile ID: 11, flags: [ hFlip, vFlip, dFlip ]
/// ```
///
/// [flip-flags-url]:https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tile-flipping
/// [sktile-tileid-url]:../Classes/SKTile.html#/s:7SKTiled6SKTileC6tileIds6UInt32Vvp
/// [working-with-tiles-url]:../working-with-tiles.html
@propertyWrapper
public struct TileID {

    /// Raw tile id value (for flipped objects, this will be the larger value).
    private var rawValue: UInt32

    /// Associated tile flip flags.
    public var flags: TileFlags = TileFlags.none

    /// Instantiate with a global ID value. The `wrappedValue` argument can be either a global id, or a masked global id.
    ///
    /// - Parameter id: tile global id.
    public init(wrappedValue: UInt32) {
        rawValue = wrappedValue
        flags = flagsFrom(wrappedValue)
    }

    /// Default initializer.
    public init() {
        rawValue = 0
    }

    /// The *unmasked* tile id.
    public var wrappedValue: UInt32 {
        get {
            return TileFlags.mask & rawValue
        }
        set {
            guard (newValue != wrappedValue) else {
                return
            }

            rawValue = newValue
            flags = flagsFrom(newValue)
        }
    }

    /// Returns the global id (including flip flags) value.
    public var realValue: UInt32 {
        return rawValue
    }

    // MARK: Parsing

    /// Parse the tile flags from the given global id.
    ///
    /// - Parameter value: global id.
    /// - Returns: flip flags.
    fileprivate func flagsFrom(_ value: UInt32) -> TileFlags {
        var result: UInt32 = 0
        result += rawValue & TileFlags.flipVertical.rawValue
        result += rawValue & TileFlags.flipHorizontal.rawValue
        result += rawValue & TileFlags.flipDiagonal.rawValue
        return TileFlags(rawValue: result)
    }

    /// Update the raw value.
    fileprivate mutating func updateRawValue() {
        rawValue = maskedGlobalId(globalID: wrappedValue, hflip: isFlippedHorizontally, vflip: isFlippedVertically, dflip: isFlippedDiagonally)
    }
}



// MARK: - Extensions


extension TileID {

    /// Tile is flipped horizontally.
    public var isFlippedHorizontally: Bool {
        get {
            return flags.contains(.flipHorizontal)
        }
        set {
            if (newValue == true) {
                flags.insert(.flipHorizontal)
            } else {
                flags.subtract(.flipHorizontal)
            }
            updateRawValue()
        }
    }

    /// Tile is flipped vertically.
    public var isFlippedVertically: Bool {
        get {
            return flags.contains(.flipVertical)
        }
        set {
            if (newValue == true) {
                flags.insert(.flipVertical)
            } else {
                flags.subtract(.flipVertical)
            }
            updateRawValue()
        }
    }

    /// Tile is flipped diagonally.
    public var isFlippedDiagonally: Bool {
        get {
            return flags.contains(.flipDiagonal)
        }
        set {
            if (newValue == true) {
                flags.insert(.flipDiagonal)
            } else {
                flags.subtract(.flipDiagonal)
            }
            updateRawValue()
        }
    }
}



extension TileFlags {

    /// Descriptor values for each option.
    public var strings: [String] {
        var result: [String] = []
        for option: TileFlags in [.flipHorizontal, .flipVertical, .flipDiagonal] {
            guard self.contains(option) else { continue }
            switch option {
                case .flipHorizontal: result.append("hFlip")
                case .flipVertical:   result.append("vFlip")
                case .flipDiagonal:   result.append("dFlip")
                default: break
            }
        }
        return result
    }
}


/// :nodoc:
extension TileFlags: CustomStringConvertible {

    public var description: String {
        guard (strings.isEmpty == false) else {
            return "[]"
        }
        return "[ \(strings.joined(separator: ", ")) ]"
    }
}


/// :nodoc:
extension TileID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        let flagsvalue = (flags.rawValue > 0) ? ", flags: \(flags.description)" : ""
        return "Tile ID: \(wrappedValue)\(flagsvalue)"
    }

    public var debugDescription: String {
        let flagsvalue = (flags.rawValue > 0) ? ", flags: \(flags.description)" : ""
        return "Tile ID: \(wrappedValue)\(flagsvalue), rawValue: \(rawValue)"
    }
}




// MARK: - Extensions
