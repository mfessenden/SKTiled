//
//  SKTiled+Extensions.swift
//  SKTiled
//
//  Created by Michael Fessenden on 4/5/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//  Compression extensions based on: https://github.com/1024jp/GzipSwift

import Foundation
import SpriteKit
import zlib
#if os(iOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif


// MARK: - Image Creation Functions


#if os(iOS) || os(tvOS)
/**
 Returns an image of the given size.

 - parameter size:       `CGSize` size of resulting image.
 - parameter scale:      `CGFloat` scale of result (0 seems to scale 2x, using 1 seems best)
 - parameter whatToDraw: function detailing what to draw the image.
 - returns: `CGImage` result.
 */
public func imageOfSize(_ size: CGSize, scale: CGFloat=1, _ whatToDraw: (_ context: CGContext, _ bounds: CGRect, _ scale: CGFloat) -> ()) -> CGImage? {
    // create an image of size, not opaque, not scaled
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    let context = UIGraphicsGetCurrentContext()

    context!.interpolationQuality = .high
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    whatToDraw(context!, bounds, scale)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result!.cgImage!
}


#else
/**
 Returns an image of the given size.

 - parameter size:       `CGSize` size of resulting image.
 - parameter scale:      `CGFloat` scale of result, for macOS that should be 1.
 - parameter whatToDraw: `()->()` function detailing what to draw the image.
 - returns: `CGImage` result.
 */
public func imageOfSize(_ size: CGSize, scale: CGFloat=1, _ whatToDraw: (_ context: CGContext, _ bounds: CGRect, _ scale: CGFloat) -> ()) -> CGImage? {
    let scaledSize = size
    let image = NSImage(size: scaledSize)
    image.lockFocus()
    let nsContext = NSGraphicsContext.current()!
    nsContext.imageInterpolation = .medium
    let context = nsContext.cgContext
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    whatToDraw(context, bounds, 1)
    image.unlockFocus()
    var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)

    // force the buffer to empty
    nsContext.flushGraphics()
    return imageRef!
}

#endif



/**
 Check a tile ID for. Returns the translated tile ID and the corresponding flip flags.

 - parameter id: `UInt32` tile ID
 - returns: tuple of global id and flip flags.
 */
public func flippedTileFlags(id: UInt32) -> (gid: UInt32, hflip: Bool, vflip: Bool, dflip: Bool) {
    // masks for tile flipping
    let flippedDiagonalFlag: UInt32   = 0x20000000
    let flippedVerticalFlag: UInt32   = 0x40000000
    let flippedHorizontalFlag: UInt32 = 0x80000000

    let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
    let flippedMask = ~(flippedAll)

    let flipHoriz: Bool = (id & flippedHorizontalFlag) != 0
    let flipVert:  Bool = (id & flippedVerticalFlag) != 0
    let flipDiag:  Bool = (id & flippedDiagonalFlag) != 0

    // get the actual gid from the mask
    let gid = id & flippedMask
    return (gid, flipHoriz, flipVert, flipDiag)
}


// MARK: - Timers

public func duration(_ block: () -> ()) -> TimeInterval {
    let startTime = Date()
    block()
    return Date().timeIntervalSince(startTime)
}


// MARK: - Extensions

extension Bool {
    init<T : Integer>(_ integer: T) {
        self.init(integer != 0)
    }
}


extension Integer {
    init(_ bool: Bool) {
        self = bool ? 1 : 0
    }
}




public extension Int {
    /// returns number of digits in Int number
    public var digitCount: Int {
        return numberOfDigits(in: self)
    }

    // private recursive method for counting digits
    private func numberOfDigits(in number: Int) -> Int {
        if abs(number) < 10 {
            return 1
        } else {
            return 1 + numberOfDigits(in: number/10)
        }
    }

    public init(bitComponents : [Int]) {
        self = bitComponents.reduce(0, +)
    }

    public func bitComponents() -> [Int] {
        return (0 ..< 8*MemoryLayout<Int>.size).map({ 1 << $0 }).filter( { self & $0 != 0 })
    }

    /// SwiftRandom extension
    static public func random(_ range: ClosedRange<Int>) -> Int {
        return range.lowerBound + Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound + 1)))
    }
}




internal extension CGFloat {

    /**
     Convert a float to radians.

     - returns: `CGFloat`
     */
    internal func radians() -> CGFloat {
        let b = CGFloat(Double.pi) * (self / 180)
        return b
    }

    /**
     Convert a float to degrees.

     - returns: `CGFloat`
     */
    internal func degrees() -> CGFloat {
        return self * 180.0 / CGFloat(Double.pi)
    }

    /**
     Clamp the CGFloat between two values. Returns a new value.

     - parameter v1: `CGFloat` min value.
     - parameter v2: `CGFloat` min value.
     - returns: `CGFloat` clamped result.
     */
    internal func clamped(_ minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        let min = minv < maxv ? minv : maxv
        let max = minv > maxv ? minv : maxv
        return self < min ? min : (self > max ? max : self)
    }

    /**
     Clamp the current value between min & max values.

     - parameter v1: `CGFloat` min value.
     - parameter v2: `CGFloat` min value.
     - returns: `CGFloat` clamped result.
     */
    internal mutating func clamp(_ minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        self = clamped(minv, maxv)
        return self
    }

    /**
     Returns a string representation of the value rounded to the current decimals.

     - parameter decimals: `Int` number of decimals to round to.
     - returns: `String` rounded display string.
     */
    internal func roundTo(_ decimals: Int=2) -> String {
        return String(format: "%.\(String(decimals))f", self)
    }

    /**
     Returns the value rounded to the nearest .5 increment.

     - returns: `CGFloat` rounded value.
     */
    internal func roundToHalf() -> CGFloat {
        let scaled = self * 10.0
        let result = scaled - (scaled.truncatingRemainder(dividingBy: 5))
        return result.rounded() / 10
    }

    internal static func random(_ range: ClosedRange<CGFloat>) -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * (range.upperBound - range.lowerBound) + range.lowerBound
    }
}


/**
 Sine function that accepts angle for trig operations.

 - parameter degrees: `CGFloat` angle.
 - returns `CGFloat` sine result.
 */
internal func sin(degrees: CGFloat) -> CGFloat {
    return CGFloat(sin(degrees: degrees.native))
}


/**
 Sine function that accepts angle for trig operations.

 - parameter degrees: `Double` angle.
 - returns `Double` sine result.
 */
internal func sin(degrees: Double) -> Double {
    return __sinpi(degrees/180.0)
}


/**
 Sine function that accepts degrees for trig operations.

 - parameter degrees: `Float` angle.
 - returns `Float` sine result.
 */
internal func sin(degrees: Float) -> Float {
    return __sinpif(degrees/180.0)
}



public extension CGPoint {

    /// Returns an point inverted in the Y-coordinate.
    public var invertedY: CGPoint {
        return CGPoint(x: self.x, y: self.y * -1)
    }

    /**
     Returns a display string rounded.

     - parameter decimals: `Int` decimals to round to.
     - returns: `String` display string.
     */
    public func roundTo(_ decimals: Int=1) -> String {
        return "x: \(self.x.roundTo(decimals)), y: \(self.y.roundTo(decimals))"
    }

    /// Return a vector int (for GameplayKit)
    public var toVec2: int2 {
        return int2(Int32(x), Int32(y))
    }

    /**
     Returns the distance to the given point.

     - parameter point: `CGPoint` decimals to round to.
     - returns: `Float` distance to other point.
     */
    public func distance(_ point: CGPoint) -> Float {
        let dx = Float(x - point.x)
        let dy = Float(y - point.y)
        return sqrt((dx * dx) + (dy * dy))
    }

    /// Return an integer value for x-coordinate.
    public var xCoord: Int { return Int(x) }
    /// Return an integer value for y-coordinate.
    public var yCoord: Int { return Int(y) }

    public var description: String { return "x: \(x.roundTo()), y: \(y.roundTo())" }
    public var shortDescription: String { return "\(Int(x)),\(Int(y))" }
}


extension CGPoint: Hashable {

    public var hashValue: Int {
        return x.hashValue << 32 ^ y.hashValue
    }
}


public func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
    return lhs.distance(rhs) < 0.000001
}


public extension CGSize {

    public var count: Int { return Int(width) * Int(height) }
    public var halfSize: CGSize { return CGSize(width: width / 2, height: height / 2) }
    public var halfWidth: CGFloat { return width / 2.0 }
    public var halfHeight: CGFloat { return height / 2.0 }

    public func roundTo(_ decimals: Int=1) -> String {
        return "w: \(self.width.roundTo(decimals)), h: \(self.height.roundTo(decimals))"
    }

    public var shortDescription: String {
        return "\(self.width.roundTo(0))x\(self.height.roundTo(0))"
    }

    public var toVec2: vector_float2 {
        return vector_float2(Float(width), Float(height))
    }
}


public extension CGRect {

    /// Initialize with a center point and size.
    public init(center: CGPoint, size: CGSize) {
        self.origin = CGPoint(x: center.x - size.width / 2.0, y: center.y - size.height / 2.0)
        self.size = size
    }

    /// Returns the center point of the rectangle.
    public var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }

    /// Returns the top-left corner point.
    public var topLeft: CGPoint {
        return origin
    }

    /// Returns the top-right corner point.
    public var topRight: CGPoint {
        return CGPoint(x: origin.x + size.width, y: origin.y)
    }

    /// Returns the bottom-left corner point.
    public var bottomLeft: CGPoint {
        return CGPoint(x: origin.x, y: origin.y + size.height)
    }

    /// Returns the bottom-left corner point.
    public var bottomRight: CGPoint {
        return CGPoint(x: origin.x + size.width, y: origin.y + size.height)
    }

    /// Return the four corner points.
    public var points: [CGPoint] {
        //return [topLeft, topRight, bottomRight, bottomLeft]
        return [bottomLeft, topLeft, topRight, bottomRight]
    }

    /**
     Returns a rect by the bounds by a given amount.

     - parameter amount: `CGFloat` decimals to round to.
     - returns: `CGRect` rectangle with inset value.
     */
    public func insetBy(_ amount: CGFloat) -> CGRect {
        return self.insetBy(dx: amount, dy: amount)
    }

    /**
     Returns a display string rounded.

     - parameter decimals: `Int` decimals to round to.
     - returns: `String` display string.
     */
    public func roundTo(_ decimals: Int=1) -> String {
        return "origin: \(Int(origin.x)), \(Int(origin.y)), size: \(Int(size.width)) x \(Int(size.height))"
    }

    public var shortDescription: String {
        return "x: \(Int(minX)), y: \(Int(minY)), w: \(width.roundTo()), h: \(height.roundTo())"
    }
}


public extension CGVector {
    /**
     * Returns the squared length of the vector described by the CGVector.
     */
    public func lengthSquared() -> CGFloat {
        return dx*dx + dy*dy
    }

    /// Return a vector int (for GameplayKit)
    public var toVec2: int2 {
        return int2(Int32(dx), Int32(dy))
    }
}


public extension SKScene {
    /**
     Returns the center point of a scene.
     */
    public var center: CGPoint {
        return CGPoint(x: (size.width / 2) - (size.width * anchorPoint.x), y: (size.height / 2) - (size.height * anchorPoint.y))
    }

    /**
     Calculate the distance from the scene's origin
     */
    public func distanceFromOrigin(_ pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVector(dx: dx, dy: dy)
    }

    /// Returns a tilemap file name.
    public var tmxFilename: String? {
        var filename: String? = nil
        enumerateChildNodes(withName: "*") { node, stop in
            if node as? SKTilemap != nil {
                if let mapURL = (node as? SKTilemap)?.url {
                    filename = mapURL.path
                    stop.pointee = true
                }
            }
        }
        return filename
    }
}


internal extension SKNode {

    /**
     Position the node by a percentage of the view size.
     */
    internal func posByCanvas(x: CGFloat, y: CGFloat) {
        guard let scene = scene else { return }
        guard let view = scene.view else { return }
        self.position = scene.convertPoint(fromView: (CGPoint(x: CGFloat(view.bounds.size.width * x), y: CGFloat(view.bounds.size.height * (1.0 - y)))))
    }

    /**
     Run an action with key & optional completion function.

     - parameter action:     `SKAction!` SpriteKit action.
     - parameter withKey:    `String!` action key.
     - parameter completion: `() -> ()?` optional completion function.
     */
    internal func run(_ action: SKAction!, withKey: String!, completion block: (()->())?) {
        if let block = block {
            let completionAction = SKAction.run( block )
            let compositeAction = SKAction.sequence([ action, completionAction ])
            run(compositeAction, withKey: withKey)
        } else {
            run(action, withKey: withKey)
        }
    }
}


internal extension SKSpriteNode {

    /**
     Convenience initalizer to set texture filtering to nearest neighbor.

     - parameter pixelImage: `String` texture image named.
     */
    convenience init(pixelImage named: String) {
        self.init(imageNamed: named)
        self.texture?.filteringMode = .nearest
    }
}


public extension SKColor {

    /// Returns the hue, saturation, brightess & alpha components of the color
    internal var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) = (0, 0, 0, 0)
        self.getHue(&(hsba.h), saturation: &(hsba.s), brightness: &(hsba.b), alpha: &(hsba.a))
        return hsba
    }

    /**
     Lightens the color by the given percentage.

     - parameter percent: `CGFloat`
     - returns: `SKColor` lightened color.
     */
    internal func lighten(by percent: CGFloat) -> SKColor {
        return colorWithBrightness(factor: 1.0 + percent)
    }

    /**
     Darkens the color by the given percentage.

     - parameter percent: `CGFloat`
     - returns: `SKColor` darkened color.
     */
    internal func darken(by percent: CGFloat) -> SKColor {
        return colorWithBrightness(factor: 1.0 - percent)
    }

    /**
     Return a modified color using the brightness factor provided

     - parameter factor: brightness factor
     - returns: `SKColor` modified color
     */
    internal func colorWithBrightness(factor: CGFloat) -> SKColor {
        let components = self.hsba
        return SKColor(hue: components.h, saturation: components.s, brightness: components.b * factor, alpha: components.a)
    }

    /**
     Initialize an SKColor with a hexidecimal string.

     - parameter hexString:  `String` hexidecimal code.
     - returns: `SKColor`
     */
    convenience public init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    /// Returns the individual color components.
    internal var components: [CGFloat] {
        guard let comps = cgColor.components else { return [0,0,0,0] }
        if comps.count < 4 {
            return [comps.first!,comps.first!,comps.first!,comps.last!]
        }
        return comps
    }

    /**
      Returns a hexadecimal string representation of the color.

     - returns: `String` hexadecimal string.
     */
    public func hexString() -> String {
        let comps = components
        let r = Int(comps[0] * 255)
        let g = Int(comps[1] * 255)
        let b = Int(comps[2] * 255)
        let a = Int(comps[3] * 255)

        var rgbHex = "#\(String(format: "%02X%02X%02X", r, g, b))"
        rgbHex += (a == 255) ? "" : String(format: "%02X", a)
        return rgbHex
    }

    /*
     Blend current color with another `SKColor`.

     - parameter color:   `SKColor` color to blend.
     - parameter factor:  `CGFloat` blend factor.
     - returns: `SKColor` blended color.
     */
    internal func blend(with color: SKColor, factor s: CGFloat = 0.5) -> SKColor {

        let r1 = components[0]
        let g1 = components[1]
        let b1 = components[2]

        let r2 = color.components[0]
        let g2 = color.components[1]
        let b2 = color.components[2]

        let r = (r1 * s) + (1 - s) * r2
        let g = (g1 * s) + (1 - s) * g2
        let b = (b1 * s) + (1 - s) * b2

        return SKColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    /**
     Return the color as a vector4.

     - returns: `GLKVector4` color as a vector4.
     */
    internal func vec4() -> GLKVector4 {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return GLKVector4(v: (Float(r), Float(g), Float(b), Float(a)))
    }

    public var toVec4: vector_float4 {
        return vector_float4(components.map {Float($0)})
    }

    public var hexDescription: String {
        return "SKColor(hexString:  \"\(self.hexString())\")"
    }

    public var rgbDescription: String {
        let comps = components
        let r = Int(comps[0] * 255)
        let g = Int(comps[1] * 255)
        let b = Int(comps[2] * 255)
        let a = Int(comps[3] * 255)
        return "SKColor(r: \(r), g: \(g), b: \(b), a: \(a))"
    }

    public var componentDescription: String {
        var result: [String] = []
        for compDesc in components.map({ "\($0.roundTo(1))" }) {
            result.append(compDesc)
        }
        return "SKColor: " + result.joined(separator: ",")
    }
}


public extension String {

    /// Returns `Int` length of the string.
    public var length: Int {
        return self.characters.count
    }

    /**
     Simple function to split a string with the given pattern.

     - parameter pattern: `String` pattern to split string with.
     - returns: `[String]` groups of split strings.
     */
    public func split(_ pattern: String) -> [String] {
        return self.components(separatedBy: pattern)
    }

    /**
     Pads string on the with a pattern to fill width.

     - parameter length:  `Int` length to fill.
     - parameter value:   `String` pattern.
     - parameter padLeft: `Bool` toggle this to pad the right.
     - returns: `String` padded string.
     */
    public func zfill(length: Int, pattern: String="0", padLeft: Bool=true) -> String {
        var filler = ""
        let padamt: Int = length - characters.count > 0 ? length - characters.count : 0
        if padamt <= 0 { return self }
        for _ in 0..<padamt {
            filler += pattern
        }
        return (padLeft == true) ? filler + self : self + filler
    }

    /**
     Pad a string with spaces.

     - parameter toSize: `Int` size of resulting string.
     - returns: `String` padded string.
     */
    public func pad(_ toSize: Int) -> String {
        // current string length
        let currentLength = self.characters.count
        if (toSize < 1) { return self }
        if (currentLength >= toSize) { return self }
        var padded = self
        for _ in 0..<toSize - currentLength {
            padded = " " + padded
        }
        return padded
    }

    /**
     Substitute a pattern in the string

     - parameter pattern:     `String` pattern to replace.
     - parameter replaceWith: replacement `String`.
     - returns: `String` result.
     */
    public func substitute(_ pattern: String, replaceWith: String) -> String {
        return self.replacingOccurrences(of: pattern, with: replaceWith)
    }

    /**
     Initialize with array of bytes.

     - parameter bytes: `[UInt8]` byte array.
     */
    public init(_ bytes: [UInt8]) {
        self.init()
        for b in bytes {
            self.append(String(UnicodeScalar(b)))
        }
    }

    /**
     Clean up whitespace & carriage returns.

     - returns: `String` scrubbed string.
     */
    public func scrub() -> String {
        var scrubbed = self.replacingOccurrences(of: "\n", with: "")
        scrubbed = scrubbed.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return scrubbed.replacingOccurrences(of: " ", with: "")
    }

    // MARK: URL

    /// Returns a url for the string.
    public var url: URL { return URL(fileURLWithPath: self.expanded) }

    /// Expand the users home path.
    public var expanded: String { return NSString(string: self).expandingTildeInPath }

    /// Returns the url parent directory.
    public var parentURL: URL {
        var path = URL(fileURLWithPath: self.expanded)
        path.deleteLastPathComponent()
        return path
    }

    /// Returns true if the string represents a path that exists.
    public var fileExists: Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: self)
    }

    /// Returns true if the string represents a path that exists and is a directory.
    public var isDirectory: Bool {
        let fm = FileManager.default
        var isDir : ObjCBool = false
        return fm.fileExists(atPath: self, isDirectory: &isDir)
    }

    /// Returns the filename if string is a url.
    public var filename: String {
        return self.url.lastPathComponent
    }

    /// Returns the file basename.
    public var basename: String {
        return self.url.deletingPathExtension().lastPathComponent
    }

    /// Returns the file extension.
    public var fileExtension: String {
        return self.url.pathExtension
    }

    /// Captialize the first letter.
    public var uppercaseFirst: String {
        let first = String(characters.prefix(1))
        return first.uppercased() + String(characters.dropFirst())
    }
}


public extension URL {

    /// Returns the path file name without file extension.
    public var basename: String {
        return self.deletingPathExtension().lastPathComponent
    }

    /// Returns the file name without the parent directory.
    public var filename: String {
        return self.lastPathComponent
    }

    /// Returns the parent path of the file.
    public var parent: String? {
        var mutableURL = self
        let result = (mutableURL.deletingLastPathComponent().relativePath == ".") ? nil : mutableURL.deletingLastPathComponent().relativePath
        return result
    }

    /// Returns true if the URL represents a path that exists.
    public var fileExists: Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: self.path)
    }

    /// Returns true if the URL represents a path that exists and is a directory.
    public var isDirectory: Bool {
        let fm = FileManager.default
        var isDir : ObjCBool = false
        return fm.fileExists(atPath: self.path, isDirectory: &isDir)
    }
}


public extension SKAction {

    /**
     Custom action to animate sprite textures with varying frame durations.

     - parameter frames:        `[(texture: SKTexture, duration: TimeInterval)]` array of tuples containing texture & duration.
     - parameter repeatForever: `Bool` run the animation forever.
     - returns: `SKAction` custom animation action.
     */
    public class func tileAnimation(_ frames: [(texture: SKTexture, duration: TimeInterval)], repeatForever: Bool = true) -> SKAction {
        var actions: [SKAction] = []
        for frame in frames {
            actions.append(SKAction.group([
                SKAction.setTexture(frame.texture, resize: false),
                SKAction.wait(forDuration: frame.duration)
                ])
            )
        }

        // add the repeating action
        if (repeatForever == true) {
            return SKAction.repeatForever(SKAction.sequence(actions))
        }
        return SKAction.sequence(actions)
    }

    /**
     Custom action to fade a node's alpha after a pause.

     - returns: `SKAction` custom fade action.
     */
    public class func fadeAfter(wait duration: TimeInterval, alpha: CGFloat) -> SKAction {
        return SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.fadeAlpha(to: alpha, duration: 0.5)])
    }

    /**
     * Performs an action after the specified delay.
     */
    public class func afterDelay(_ delay: TimeInterval, performAction action: SKAction) -> SKAction {
        return SKAction.sequence([SKAction.wait(forDuration: delay), action])
    }

    /**
     * Performs a block after the specified delay.
     */
    public class func afterDelay(_ delay: TimeInterval, runBlock block: @escaping () -> Void) -> SKAction {
        return SKAction.afterDelay(delay, performAction: SKAction.run(block))
    }

    /**
     * Removes the node from its parent after the specified delay.
     */
    public class func removeFromParentAfterDelay(_ delay: TimeInterval) -> SKAction {
        return SKAction.afterDelay(delay, performAction: SKAction.removeFromParent())
    }
}


public extension Data {
    // init with a value
    public init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    // export back as value
    public func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.pointee }
    }

    // init with array
    public init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }

    // output to array
    public func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
        }
    }
}


// MARK: - Operators

// MARK: CGFloat

public func + (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) + rhs
}


public func + (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs + CGFloat(rhs)
}


public func - (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) - rhs
}


public func - (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs - CGFloat(rhs)
}


public func * (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) * rhs
}


public func * (lhs: Int32, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) * rhs
}


public func * (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs * CGFloat(rhs)
}


public func / (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) / rhs
}


public func / (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs / CGFloat(rhs)
}


public func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
    return start + (t * (end - start))
}


public func ilerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
    return (t - start) / (end - start)
}


// MARK: CGPoint

public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}


public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}


public func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
}

public func / (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
}

public func + (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x + rhs, y: lhs.y + rhs)
}

public func - (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x - rhs, y: lhs.y - rhs)
}

public func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

public func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}

public func lerp(start: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
    return start + (end - start) * t
}


// MARK: CGSize
public func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}


public func - (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}


public func * (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
}


public func / (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
}


public func + (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width + rhs, height: lhs.height + rhs)
}


public func - (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width - rhs, height: lhs.height - rhs)
}


public func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
}


public func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
}


public func fabs(_ size: CGSize) -> CGSize {
    return CGSize(width: fabs(size.width), height: fabs(size.height))
}


// MARK: CGVector
public func + (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
}


public func += (lhs: inout CGVector, rhs: CGVector) {
    lhs += rhs
}


public func - (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
}


public func -= (lhs: inout CGVector, rhs: CGVector) {
    lhs -= rhs
}


public func * (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx * rhs.dx, dy: lhs.dy * rhs.dy)
}


public func *= (lhs: inout CGVector, rhs: CGVector) {
    lhs *= rhs
}


public func * (vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
}


public func *= (vector: inout CGVector, scalar: CGFloat) {
    vector *= scalar
}


public func / (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx / rhs.dx, dy: lhs.dy / rhs.dy)
}


public func /= (lhs: inout CGVector, rhs: CGVector) {
    lhs /= rhs
}


public func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
    return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
}


public func /= (lhs: inout CGVector, rhs: CGFloat) {
    lhs /= rhs
}


public func lerp(start: CGVector, end: CGVector, t: CGFloat) -> CGVector {
    return start + (end - start) * t
}



// MARK: CGRect

public func + (lhs: CGRect, rhs: CGFloat) -> CGRect {
    return CGRect(x: lhs.minX, y: lhs.minY, width: lhs.width + rhs, height: lhs.height + rhs)
}


public func - (lhs: CGRect, rhs: CGFloat) -> CGRect {
    return CGRect(x: lhs.minX, y: lhs.minY, width: lhs.width - rhs, height: lhs.height - rhs)
}


public func * (lhs: CGRect, rhs: CGFloat) -> CGRect {
    return CGRect(x: lhs.minX, y: lhs.minY, width: lhs.width * rhs, height: lhs.height * rhs)
}


public func / (lhs: CGRect, rhs: CGFloat) -> CGRect {
    return CGRect(x: lhs.minX, y: lhs.minY, width: lhs.width / rhs, height: lhs.height / rhs)
}


// MARK: SKColor

public func lerp(start: SKColor, end: SKColor, t: CGFloat) -> SKColor {
    let newRed   = (1.0 - t) * start.components[0]   + t * end.components[0]
    let newGreen = (1.0 - t) * start.components[1] + t * end.components[1]
    let newBlue  = (1.0 - t) * start.components[2]  + t * end.components[2]
    return SKColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1)
}


// MARK: vector_int2

public func + (lhs: int2, rhs: int2) -> int2 {
    return int2(lhs.x + rhs.x, lhs.y + rhs.y)
}

public func += (lhs: inout int2, rhs: int2) {
    lhs += rhs
}


public func - (lhs: int2, rhs: int2) -> int2 {
    return int2(lhs.x - rhs.x, lhs.y - rhs.y)
}


public func -= (lhs: inout int2, rhs: int2) {
    lhs -= rhs
}


public func * (lhs: int2, rhs: int2) -> int2 {
    return int2(lhs.x * rhs.x, lhs.y * rhs.y)
}

public func *= (lhs: inout int2, rhs: int2) {
    lhs *= rhs
}


public func / (lhs: int2, rhs: int2) -> int2 {
    return int2(lhs.x / rhs.x, lhs.y / rhs.y)
}

/*
public func /= (lhs: inout int2, rhs: int2) {
    lhs /= rhs
}
*/

public func == (lhs: int2, rhs: int2) -> Bool {
    return (lhs.x == rhs.x) && (lhs.y == rhs.y)
}


extension vector_int2 {

    /**
     Returns the difference vector to another in2.

     - parameter v: `vector_int2` coordinate.
     - returns: `CGVector` difference between.
     */
    public func delta(to v: int2) -> CGVector {
        let dx = Float(x - v.x)
        let dy = Float(y - v.y)
        return CGVector(dx: Int(dx), dy: Int(dy))
    }

    /**
     Returns true if the coordinate vector is contiguous to another vector.

     - parameter v: `vector_int2` coordinate.
     - returns: `Bool` coordinates are contiguous.
     */
    public func isContiguousTo(v: int2) -> Bool {
        let dx = Float(x - v.x)
        let dy = Float(y - v.y)
        return sqrt((dx * dx) + (dy * dy)) == 1
    }

    /// Convert the int2 to CGPoint.
    public var cgPoint: CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}


// MARK: - Helper Functions

public func floor(point: CGPoint) -> CGPoint {
    return CGPoint(x: floor(Double(point.x)), y: floor(Double(point.y)))
}


public func normalize(_ value: CGFloat, _ minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
    return (value - minimum) / (maximum - minimum)
}


// MARK: - Visualization Functions


/**
 Visualize a layer grid as a texture.

 - parameter layer:      `SKTiledLayerObject` layer instance.
 - parameter imageScale: `CGFloat` image scale multiplier.
 - parameter lineScale:  `CGFloat` line scale multiplier.
 - returns:              `CGImage` visual grid texture.
 */
internal func drawLayerGrid(_ layer: SKTiledLayerObject,
                            imageScale: CGFloat=8,
                            lineScale: CGFloat=1) -> CGImage? {
    // get the ui scale value for the device
    let uiScale: CGFloat = SKTiledContentScaleFactor

    let size = layer.size
    let tileWidth = layer.tileWidth * imageScale
    let tileHeight = layer.tileHeight * imageScale

    let tileWidthHalf = tileWidth / 2
    let tileHeightHalf = tileHeight / 2

    let sizeInPoints = (layer.sizeInPoints * imageScale)
    let defaultLineWidth: CGFloat = (imageScale / uiScale) * lineScale

    return imageOfSize(sizeInPoints, scale: uiScale) { context, bounds, scale in

        // reference to shape path
        var shapePath: CGPath?

        let innerColor = layer.gridColor
        // line width should be at least 1 for larger tile sizes
        let lineWidth: CGFloat = defaultLineWidth
        context.setLineWidth(lineWidth)
        context.setShouldAntialias(true)  // layer.antialiased

        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {

                context.setStrokeColor(innerColor.cgColor)
                context.setFillColor(SKColor.clear.cgColor)

                let screenPosition = layer.tileToScreenCoords(CGPoint(x: col, y: row))

                var xpos: CGFloat = screenPosition.x * imageScale
                var ypos: CGFloat = screenPosition.y * imageScale

                switch layer.orientation {
                case .orthogonal:

                    // rectangle shape
                    let points = rectPointArray(tileWidth, height: tileHeight, origin: CGPoint(x: xpos, y: ypos + tileHeight))
                    shapePath = polygonPath(points)
                    context.addPath(shapePath!)

                case .isometric:
                    // xpos, ypos is the top point of the diamond
                    let points: [CGPoint] = [
                        CGPoint(x: xpos, y: ypos),
                        CGPoint(x: xpos - tileWidthHalf, y: ypos + tileHeightHalf),
                        CGPoint(x: xpos, y: ypos + tileHeight),
                        CGPoint(x: xpos + tileWidthHalf, y: ypos + tileHeightHalf),
                        CGPoint(x: xpos, y: ypos)
                    ]

                    shapePath = polygonPath(points)
                    context.addPath(shapePath!)

                case .hexagonal, .staggered:
                    let staggerX = layer.tilemap.staggerX

                    // mirrored in pointForCoordinate
                    xpos += tileWidthHalf

                    if layer.orientation == .hexagonal {

                        ypos += tileHeightHalf

                        var hexPoints = Array(repeating: CGPoint.zero, count: 6)
                        var variableSize: CGFloat = 0
                        var r: CGFloat = 0
                        var h: CGFloat = 0

                        // flat - currently not working
                        if (staggerX == true) {
                            let sizeLengthX = (layer.tilemap.sideLengthX * imageScale)
                            r = (tileWidth - sizeLengthX) / 2
                            h = tileHeight / 2
                            variableSize = tileWidth - (r * 2)
                            hexPoints[0] = CGPoint(x: xpos - (variableSize / 2), y: ypos + h)
                            hexPoints[1] = CGPoint(x: xpos + (variableSize / 2), y: ypos + h)
                            hexPoints[2] = CGPoint(x: xpos + (tileWidth / 2), y: ypos)
                            hexPoints[3] = CGPoint(x: xpos + (variableSize / 2), y: ypos - h)
                            hexPoints[4] = CGPoint(x: xpos - (variableSize / 2), y: ypos - h)
                            hexPoints[5] = CGPoint(x: xpos - (tileWidth / 2), y: ypos)


                        } else {
                            r = tileWidth / 2
                            let sizeLengthY = (layer.tilemap.sideLengthY * imageScale)
                            h = (tileHeight - sizeLengthY) / 2
                            variableSize = tileHeight - (h * 2)
                            hexPoints[0] = CGPoint(x: xpos, y: ypos + (tileHeight / 2))
                            hexPoints[1] = CGPoint(x: xpos + (tileWidth / 2), y: ypos + (variableSize / 2))
                            hexPoints[2] = CGPoint(x: xpos + (tileWidth / 2), y: ypos - (variableSize / 2))
                            hexPoints[3] = CGPoint(x: xpos, y: ypos - (tileHeight / 2))
                            hexPoints[4] = CGPoint(x: xpos - (tileWidth / 2), y: ypos - (variableSize / 2))
                            hexPoints[5] = CGPoint(x: xpos - (tileWidth / 2), y: ypos + (variableSize / 2))
                        }

                        shapePath = polygonPath(hexPoints)
                        context.addPath(shapePath!)
                    }

                    if layer.orientation == .staggered {

                        let points: [CGPoint] = [
                            CGPoint(x: xpos, y: ypos),
                            CGPoint(x: xpos - tileWidthHalf, y: ypos + tileHeightHalf),
                            CGPoint(x: xpos, y: ypos + tileHeight),
                            CGPoint(x: xpos + tileWidthHalf, y: ypos + tileHeightHalf),
                            CGPoint(x: xpos, y: ypos)
                        ]

                        shapePath = polygonPath(points)
                        context.addPath(shapePath!)
                    }
                }

                context.strokePath()
                shapePath = nil
            }
        }
    }
}


/**
 Generate a visual navigation graph texture.

 - parameter layer:      `SKTiledLayerObject` layer instance.
 - parameter imageScale: `CGFloat` image scale multiplier.
 - parameter lineScale:  `CGFloat` line scale multiplier.
 - returns: `CGImage` visual graph texture.
 */
internal func drawLayerGraph(_ layer: SKTiledLayerObject,
                             imageScale: CGFloat = 8,
                             lineScale: CGFloat = 1) -> CGImage? {


    // get the ui scale value for the device
    let uiScale: CGFloat = SKTiledContentScaleFactor

    let size = layer.size
    let tileWidth = layer.tileWidth * imageScale
    let tileHeight = layer.tileHeight * imageScale

    let tileWidthHalf = tileWidth / 2
    let tileHeightHalf = tileHeight / 2

    let sizeInPoints = (layer.sizeInPoints * imageScale)
    let defaultLineWidth: CGFloat = (imageScale / uiScale) * lineScale


    return imageOfSize(sizeInPoints, scale: uiScale) { context, bounds, scale in

        guard let graph = layer.graph else { return }

        // line width should be at least 1 for larger tile sizes
        let lineWidth: CGFloat = defaultLineWidth
        context.setLineWidth(lineWidth)
        context.setShouldAntialias(true)  // layer.antialiased

        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {

                let strokeColor = SKColor.black
                var fillColor = SKColor.clear

                 if let node = graph.node(atGridPosition: int2(Int32(col), Int32(row))) {


                    fillColor = SKColor.gray

                    if let tiledNode = node as? SKTiledGraphNode {

                        switch tiledNode.weight {
                        case (-2000)...(-1):
                            fillColor = TiledObjectColors.lime
                        case 0...10:
                            fillColor = SKColor.gray
                        case 11...200:
                            fillColor = TiledObjectColors.tangerine
                        case 201...Float.greatestFiniteMagnitude:
                            fillColor = TiledObjectColors.english
                        default:
                            fillColor = SKColor.gray
                        }
                    }


                    let screenPosition = layer.tileToScreenCoords(CGPoint(x: col, y: row))

                    var xpos: CGFloat = screenPosition.x * imageScale
                    var ypos: CGFloat = screenPosition.y * imageScale


                    // points for node shape
                    var points: [CGPoint] = []

                    switch layer.orientation {
                    case .orthogonal:

                        // rectangle shape
                        points = rectPointArray(tileWidth, height: tileHeight, origin: CGPoint(x: xpos, y: ypos + tileHeight))


                    case .isometric:
                        // xpos, ypos is the top point of the diamond
                        points = [
                            CGPoint(x: xpos, y: ypos),
                            CGPoint(x: xpos - tileWidthHalf, y: ypos + tileHeightHalf),
                            CGPoint(x: xpos, y: ypos + tileHeight),
                            CGPoint(x: xpos + tileWidthHalf, y: ypos + tileHeightHalf),
                            CGPoint(x: xpos, y: ypos)
                        ]

                    case .hexagonal, .staggered:
                        let staggerX = layer.tilemap.staggerX

                        xpos += tileWidthHalf

                        if layer.orientation == .hexagonal {

                            ypos += tileHeightHalf

                            var hexPoints = Array(repeating: CGPoint.zero, count: 6)
                            var variableSize: CGFloat = 0
                            var r: CGFloat = 0
                            var h: CGFloat = 0

                            // flat - currently not working
                            if (staggerX == true) {
                                let sizeLengthX = (layer.tilemap.sideLengthX * imageScale)
                                r = (tileWidth - sizeLengthX) / 2
                                h = tileHeight / 2
                                variableSize = tileWidth - (r * 2)
                                hexPoints[0] = CGPoint(x: xpos - (variableSize / 2), y: ypos + h)
                                hexPoints[1] = CGPoint(x: xpos + (variableSize / 2), y: ypos + h)
                                hexPoints[2] = CGPoint(x: xpos + (tileWidth / 2), y: ypos)
                                hexPoints[3] = CGPoint(x: xpos + (variableSize / 2), y: ypos - h)
                                hexPoints[4] = CGPoint(x: xpos - (variableSize / 2), y: ypos - h)
                                hexPoints[5] = CGPoint(x: xpos - (tileWidth / 2), y: ypos)


                            } else {
                                r = tileWidth / 2
                                let sizeLengthY = (layer.tilemap.sideLengthY * imageScale)
                                h = (tileHeight - sizeLengthY) / 2
                                variableSize = tileHeight - (h * 2)
                                hexPoints[0] = CGPoint(x: xpos, y: ypos + (tileHeight / 2))
                                hexPoints[1] = CGPoint(x: xpos + (tileWidth / 2), y: ypos + (variableSize / 2))
                                hexPoints[2] = CGPoint(x: xpos + (tileWidth / 2), y: ypos - (variableSize / 2))
                                hexPoints[3] = CGPoint(x: xpos, y: ypos - (tileHeight / 2))
                                hexPoints[4] = CGPoint(x: xpos - (tileWidth / 2), y: ypos - (variableSize / 2))
                                hexPoints[5] = CGPoint(x: xpos - (tileWidth / 2), y: ypos + (variableSize / 2))
                            }

                            points = hexPoints
                        }

                        if layer.orientation == .staggered {

                            points = [
                                CGPoint(x: xpos, y: ypos),
                                CGPoint(x: xpos - tileWidthHalf, y: ypos + tileHeightHalf),
                                CGPoint(x: xpos, y: ypos + tileHeight),
                                CGPoint(x: xpos + tileWidthHalf, y: ypos + tileHeightHalf),
                                CGPoint(x: xpos, y: ypos)
                            ]
                        }
                    }

                    // draw the node
                    if (points.isEmpty == false) {
                        let fillPath = polygonPath(points)
                        context.addPath(fillPath)
                        context.setFillColor(fillColor.cgColor)
                        context.fillPath()

                        context.setStrokeColor(strokeColor.cgColor)

                        let shapePath = polygonPath(points)
                        context.addPath(shapePath)
                        context.strokePath()
                    }
                 }
            }
        }
    }
}



// MARK: - File System
#if os(macOS)
/**
 Create a temporary directory.
 */
internal func createTempDirectory(named: String) -> URL? {
    let directory = NSTemporaryDirectory()
    guard let url = NSURL.fileURL(withPathComponents: [directory, named]) else {
        Logger.default.log("Unable get temp directory: \(named)", level: .warning)
        return nil
    }
    do {
        try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        Logger.default.log("Creating directory: \(url.path)", level: .info)
        return url
    } catch let error as NSError {
        Logger.default.log("Unable to create directory \(error.debugDescription)", level: .error)
    }
    return nil
}


/**
 Write the given image to PNG file.
 */
internal func writeToFile(_ image: CGImage, url: URL) -> Data {
    let bitmapRep: NSBitmapImageRep = NSBitmapImageRep(cgImage: image)
    let properties = Dictionary<String, AnyObject>()
    let data: Data = bitmapRep.representation(using: NSBitmapImageFileType.PNG, properties: properties)!
    if !((try? data.write(to: URL(fileURLWithPath: url.path), options: [])) != nil) {
        Logger.default.log("Error: write to file failed.", level: .error)
    }

    Logger.default.log("writing image: \(url.path)", level: .info)
    return data
}
#endif



internal func drawAnchor(_ node: SKNode,
                         withLabel: String? = nil,
                         labelSize: CGFloat = 10,
                         labelOffsetX: CGFloat = 0,
                         labelOffsetY: CGFloat = 0,
                         radius: CGFloat = 4,
                         anchorColor: SKColor = SKColor.red) {

    node.childNode(withName: "ANCHOR")?.removeFromParent()

    let anchorShape = SKShapeNode(circleOfRadius: radius)
    anchorShape.name = "ANCHOR"
    node.addChild(anchorShape)
    anchorShape.fillColor = anchorColor
    anchorShape.strokeColor = .clear
    anchorShape.zPosition = node.zPosition + 1

    if let withLabel = withLabel {
        let anchorLabel = SKLabelNode(fontNamed: "Courier")
        anchorLabel.text = withLabel
        anchorLabel.fontSize = labelSize * 4
        anchorShape.addChild(anchorLabel)
        anchorLabel.zPosition = anchorShape.zPosition + 1
        anchorLabel.position.x += labelOffsetX
        anchorLabel.position.y += labelOffsetY
        anchorLabel.setScale(1.0 / 4.0)
        anchorLabel.color = .white
    }
}


// MARK: - Polygon Drawing

/**
 Returns an array of points for the given dimensions. ** In Use **

 - parameter width:   `CGFloat` rect width.
 - parameter height:  `CGFloat` rect height.
 - parameter origin: `CGPoint` rectangle origin.
 - returns: `[CGPoint]` array of points.
 */
public func rectPointArray(_ width: CGFloat, height: CGFloat, origin: CGPoint = .zero) -> [CGPoint] {
    let points: [CGPoint] = [
        origin,
        CGPoint(x: origin.x + width, y: origin.y),
        CGPoint(x: origin.x + width, y: origin.y - height),
        CGPoint(x: origin.x, y: origin.y - height)
    ]
    return points
}


/**
 Returns an array of points for the given dimensions.

 - parameter size:   `CGSize` rect size.
 - parameter origin: `CGPoint` rectangle origin.
 - returns: `[CGPoint]` array of points.
 */
public func rectPointArray(_ size: CGSize, origin: CGPoint = .zero) -> [CGPoint] {
    return rectPointArray(size.width, height: size.height, origin: origin)
}


/**
 Returns an array of points describing a polygon shape.

 - parameter sides:  `Int` number of sides.
 - parameter radius: `CGSize` radius of circle.
 - parameter offset: `CGFloat` rotation offset (45 to return a rectangle).
 - parameter origin: `CGPoint` origin point.
  - returns: `[CGPoint]` array of points.
 */
public func polygonPointArray(_ sides: Int, radius: CGSize, offset: CGFloat=0, origin: CGPoint = .zero) -> [CGPoint] {
    let angle = (360 / CGFloat(sides)).radians()
    let cx = origin.x       // x origin
    let cy = origin.y       // y origin
    let rx = radius.width   // radius of circle
    let ry = radius.height
    var i = 0
    var points: [CGPoint] = []
    while i <= sides {
        let xpo = cx + rx * cos(angle * CGFloat(i) - offset.radians())
        let ypo = cy + ry * sin(angle * CGFloat(i) - offset.radians())
        points.append(CGPoint(x: xpo, y: ypo))
        i += 1
    }
    return points
}


/**

 Takes an array of points and returns a path.

 - parameter points:  `[CGPoint]` polygon points.
 - parameter closed:  `Bool` path should be closed.
  - returns: `CGPath` path from the given points.
 */
public func polygonPath(_ points: [CGPoint], closed: Bool=true) -> CGPath {
    let path = CGMutablePath()
    var mpoints = points
    let first = mpoints.remove(at: 0)
    path.move(to: first)

    for p in mpoints {
        path.addLine(to: p)
    }
    if (closed == true) { path.closeSubpath() }
    return path
}


/**
 Draw a polygon shape based on an aribitrary number of sides.

 - parameter sides:    `Int` number of sides.
 - parameter radius:   `CGSize` w/h radius.
 - parameter offset:   `CGFloat` rotation offset (45 to return a rectangle).
 - returns: `CGPathf`  path from the given points.
 */
public func polygonPath(_ sides: Int, radius: CGSize, offset: CGFloat=0, origin: CGPoint=CGPoint.zero) -> CGPath {
    let path = CGMutablePath()
    let points = polygonPointArray(sides, radius: radius, offset: offset)
    let cpg = points[0]
    path.move(to: cpg)
    for p in points {
        path.addLine(to: p)
    }
    path.closeSubpath()
    return path
}


/**
 Takes an array of points and returns a bezier path.

 - parameter points:  `[CGPoint]` polygon points.
 - parameter closed:  `Bool` path should be closed.
 - parameter alpha:   `CGFloat` curvature.
 - returns: `(CGPath, [CGPoint])` bezier path and control points.
 */
public func bezierPath(_ points: [CGPoint], closed: Bool = true, alpha: CGFloat = 1) -> (path: CGPath, points: [CGPoint]) {
    guard points.count > 1 else { return (CGMutablePath(), [CGPoint]()) }
    assert(alpha >= 0 && alpha <= 1.0, "Alpha must be between 0 and 1")

    let numberOfCurves = closed ? points.count : points.count - 1

    var previousPoint: CGPoint? = closed ? points.last : nil
    var currentPoint:  CGPoint  = points[0]
    var nextPoint:     CGPoint? = points[1]

    let path = CGMutablePath()
    path.move(to: currentPoint)

    var cpoints: [CGPoint] = []
    let tension: CGFloat = 2.7

    for index in 0 ..< numberOfCurves {
        let endPt = nextPoint!

        var mx: CGFloat
        var my: CGFloat

        if previousPoint != nil {
            mx = (nextPoint!.x - currentPoint.x) * alpha + (currentPoint.x - previousPoint!.x) * alpha
            my = (nextPoint!.y - currentPoint.y) * alpha + (currentPoint.y - previousPoint!.y) * alpha
        } else {
            mx = (nextPoint!.x - currentPoint.x) * alpha
            my = (nextPoint!.y - currentPoint.y) * alpha
        }

        let ctrlPt1 = CGPoint(x: currentPoint.x + mx / tension, y: currentPoint.y + my / tension)

        previousPoint = currentPoint
        currentPoint = nextPoint!
        let nextIndex = index + 2
        if closed {
            nextPoint = points[nextIndex % points.count]
        } else {
            nextPoint = nextIndex < points.count ? points[nextIndex % points.count] : nil
        }

        if nextPoint != nil {
            mx = (nextPoint!.x - currentPoint.x) * alpha + (currentPoint.x - previousPoint!.x) * alpha
            my = (nextPoint!.y - currentPoint.y) * alpha + (currentPoint.y - previousPoint!.y) * alpha
        } else {
            mx = (currentPoint.x - previousPoint!.x) * alpha
            my = (currentPoint.y - previousPoint!.y) * alpha
        }

        let ctrlPt2 = CGPoint(x: currentPoint.x - mx / tension, y: currentPoint.y - my / tension)

        cpoints.append(ctrlPt1)
        cpoints.append(ctrlPt2)

        path.addCurve(to: endPt, control1: ctrlPt1, control2: ctrlPt2)
    }

    if (closed == true) { path.closeSubpath() }
    return (path, cpoints)
}


/**
 Takes an array of grid graph points and returns a path. Set threshold value to allow for gaps in the path.

 - parameter points:    `[CGPoint]` path points.
 - parameter threshold: `CGFloat` gap threshold size.
 - returns: `CGPath` path from the given points.
 */
public func polygonPath(_ points: [CGPoint], threshold: CGFloat) -> CGPath {
    let path = CGMutablePath()
    var mpoints = points
    let first = mpoints.remove(at: 0)
    path.move(to: first)
    var current = first
    for p in mpoints {
        let distToLast = CGFloat(p.distance(current))
        if (distToLast > threshold) {
            path.move(to: p)
        } else {
            path.addLine(to: p)
        }
        current = p
    }
    return path
}

/**
 Given two points, create an arrowhead.

 - parameter startPoint:  `CGPoint` first point.
 - parameter endPoint:    `CGPoint` last point.
 - parameter tailWidth:   `CGFloat` arrow tail width.
 - parameter headWidth:   `CGFloat` arrow head width.
 - parameter headLength:  `CGFloat` arrow head length.
 - returns: `CGPath` path from the given points.
 */
public func arrowFromPoints(startPoint: CGPoint,
                            endPoint: CGPoint,
                            tailWidth: CGFloat,
                            headWidth: CGFloat,
                            headLength: CGFloat) -> CGPath {

    let length = CGFloat(hypotf(Float(endPoint.x) - Float(startPoint.x), Float(endPoint.y) - Float(startPoint.y)))

    // offset from start to end
    let offsetX = startPoint.x - endPoint.x
    let offsetY = startPoint.y - endPoint.y
    let offset = CGPoint(x: offsetX, y: offsetY)
    var points: [CGPoint] = []

    let tailLength = length - headLength

    points.append(CGPoint(x: 0, y: tailWidth/2))
    points.append(CGPoint(x: tailLength, y: tailWidth))
    points.append(CGPoint(x: tailLength, y: headLength/2))
    points.append(CGPoint(x: length, y: 0))
    points.append(CGPoint(x: tailLength, y: -headWidth/2))
    points.append(CGPoint(x: tailLength, y: -tailWidth/2 ))
    points.append(CGPoint(x: 0, y: -tailWidth/2))

    let cosine = (endPoint.x - startPoint.x)/length
    let sine = (endPoint.y - startPoint.y)/length

    var transform = CGAffineTransform()
    transform.a = cosine
    transform.b = sine
    transform.c = -sine
    transform.d = cosine
    transform.tx = startPoint.x - offset.x
    transform.ty = startPoint.y - offset.y


    let path = CGMutablePath()
    path.addLines(between: points, transform: transform)
    path.closeSubpath()
    return path
}


/**
 Returns the device scale factor.

 - returns: `CGFloat` device scale.
 */
public func getContentScaleFactor() -> CGFloat {
    #if os(iOS) || os(tvOS)
    return UIScreen.main.scale
    #else
    return NSScreen.main()!.backingScaleFactor
    #endif
}


/**
 Clamp a point to the given scale.

 - parameter point:  `CGPoint` point to clamp.
 - parameter scale:  `CGFloat` device scale.
 - returns: `CGPoint` clamped point.
 */
internal func clampedPosition(point: CGPoint, scale: CGFloat) -> CGPoint {
    let clampedX = round(Int(point.x * scale) / scale)
    let clampedY = round(Int(point.y * scale) / scale)
    return CGPoint(x: clampedX, y: clampedY)
}


/**
 Clamp the position of a given node (and parent).

 - parameter node:  `SKNode` node to re-position.
 - parameter scale:  `CGFloat` device scale.
 */
internal func clampPositionWithNode(node: SKNode, scale: CGFloat) {
    node.position = clampedPosition(point: node.position, scale: scale)
    if let parentNode = node.parent {
        if parentNode != node.scene {
            clampPositionWithNode(node: parentNode, scale: scale)
        }
    }
}


// MARK: - Compression

/**
 Compression level with constants based on the zlib's constants.
 */
public typealias CompressionLevel = Int32

public extension CompressionLevel {

    static public let noCompression      = Z_NO_COMPRESSION
    static public let bestSpeed          = Z_BEST_SPEED
    static public let bestCompression    = Z_BEST_COMPRESSION
    static public let defaultCompression = Z_DEFAULT_COMPRESSION
}


/**
 Errors on gzipping/gunzipping based on the zlib error codes.
 */
public enum GzipError: Error {
    // cf. http://www.zlib.net/manual.html

    /**
     The stream structure was inconsistent.

     - underlying zlib error: `Z_STREAM_ERROR` (-2)
     - parameter message: returned message by zlib
     */
    case stream(message: String)

    /**
     The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).

     - underlying zlib error: `Z_DATA_ERROR` (-3)
     - parameter message: returned message by zlib
     */
    case data(message: String)

    /**
     There was not enough memory.

     - underlying zlib error: `Z_MEM_ERROR` (-4)
     - parameter message: returned message by zlib
     */
    case memory(message: String)

    /**
     No progress is possible or there was not enough room in the output buffer.

     - underlying zlib error: `Z_BUF_ERROR` (-5)
     - parameter message: returned message by zlib
     */
    case buffer(message: String)

    /**
     The zlib library version is incompatible with the version assumed by the caller.

     - underlying zlib error: `Z_VERSION_ERROR` (-6)
     - parameter message: returned message by zlib
     */
    case version(message: String)

    /**
     An unknown error occurred.

     - parameter message: returned message by zlib
     - parameter code: return error by zlib
     */
    case unknown(message: String, code: Int)


    internal init(code: Int32, msg: UnsafePointer<CChar>?) {

        let message: String = {
            guard let msg = msg, let message = String(validatingUTF8: msg) else {
                return "Unknown gzip error"
            }
            return message
        }()

        self = {
            switch code {
            case Z_STREAM_ERROR:
                return .stream(message: message)

            case Z_DATA_ERROR:
                return .data(message: message)

            case Z_MEM_ERROR:
                return .memory(message: message)

            case Z_BUF_ERROR:
                return .buffer(message: message)

            case Z_VERSION_ERROR:
                return .version(message: message)

            default:
                return .unknown(message: message, code: Int(code))
            }
        }()
    }


    public var localizedDescription: String {

        let description: String = {
            switch self {
            case .stream(let message):
                return message
            case .data(let message):
                return message
            case .memory(let message):
                return message
            case .buffer(let message):
                return message
            case .version(let message):
                return message
            case .unknown(let message, _):
                return message
            }
        }()

        return NSLocalizedString(description, comment: "error message")
    }

}


public extension Data {

    /**
     Check if the reciever is already gzipped.

     - returns: Whether the data is compressed.
     */
    public var isGzipped: Bool {
        return self.starts(with: [0x1f, 0x8b])
    }

    /**
     Check if the reciever is already zlib compressed.

     - returns: Whether the data is compressed.
     */
    public var isZlibCompressed: Bool {
        return self.starts(with: [0x78, 0x9C])
    }

    /**
     Create a new `Data` object by compressing the receiver using zlib.
     Throws an error if compression failed.

     - parameters:
     - level: Compression level in the range of `0` (no compression) to `9` (maximum compression).

     - throws: `GzipError`
     - returns: Gzip-compressed `Data` object.
     */
    public func gzipped(level: CompressionLevel = .defaultCompression) throws -> Data {

        guard self.isEmpty == false else {
            return Data()
        }

        var stream = self.createZStream()
        var status: Int32

        status = deflateInit2_(&stream, level, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, STREAM_SIZE)

        guard status == Z_OK else {
            // deflateInit2 returns:
            // Z_VERSION_ERROR  The zlib library version is incompatible with the version assumed by the caller.
            // Z_MEM_ERROR      There was not enough memory.
            // Z_STREAM_ERROR   A parameter is invalid.

            throw GzipError(code: status, msg: stream.msg)
        }

        var data = Data(capacity: CHUNK_SIZE)
        while stream.avail_out == 0 {
            if Int(stream.total_out) >= data.count {
                data.count += CHUNK_SIZE
            }

            data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<Bytef>) in
                stream.next_out = bytes.advanced(by: Int(stream.total_out))
            }
            stream.avail_out = uInt(data.count) - uInt(stream.total_out)

            deflate(&stream, Z_FINISH)
        }

        deflateEnd(&stream)
        data.count = Int(stream.total_out)

        return data
    }


    /**
     Create a new `Data` object by decompressing the receiver using zlib.
     Throws an error if decompression failed.

     - throws: `GzipError`
     - returns: Gzip-decompressed `Data` object.
     */
    public func gunzipped() throws -> Data {

        guard self.isEmpty == false else {
            return Data()
        }

        var stream = self.createZStream()
        var status: Int32

        status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, STREAM_SIZE)

        guard status == Z_OK else {
            // inflateInit2 returns:
            // Z_VERSION_ERROR   The zlib library version is incompatible with the version assumed by the caller.
            // Z_MEM_ERROR       There was not enough memory.
            // Z_STREAM_ERROR    A parameters are invalid.

            throw GzipError(code: status, msg: stream.msg)
        }

        var data = Data(capacity: self.count * 2)

        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += self.count / 2
            }

            data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<Bytef>) in
                stream.next_out = bytes.advanced(by: Int(stream.total_out))
            }
            stream.avail_out = uInt(data.count) - uInt(stream.total_out)

            status = inflate(&stream, Z_SYNC_FLUSH)

        } while status == Z_OK

        guard inflateEnd(&stream) == Z_OK && status == Z_STREAM_END else {
            // inflate returns:
            // Z_DATA_ERROR   The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
            // Z_STREAM_ERROR The stream structure was inconsistent (for example if next_in or next_out was NULL).
            // Z_MEM_ERROR    There was not enough memory.
            // Z_BUF_ERROR    No progress is possible or there was not enough room in the output buffer when Z_FINISH is used.

            throw GzipError(code: status, msg: stream.msg)
        }

        data.count = Int(stream.total_out)

        return data
    }

    private func createZStream() -> z_stream {

        var stream = z_stream()

        self.withUnsafeBytes { (bytes: UnsafePointer<Bytef>) in
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: bytes)
        }
        stream.avail_in = uint(self.count)

        return stream
    }

}


private let CHUNK_SIZE: Int = 2 ^ 14
private let STREAM_SIZE: Int32 = Int32(MemoryLayout<z_stream>.size)
