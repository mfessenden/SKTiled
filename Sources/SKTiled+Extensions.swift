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


// MARK: - Global Functions


/**
 Returns current framework version.

 - returns: `String` SKTiled framework version.
 */
func getSKTiledVersion() -> String {
    var sktiledVersion = "0"
    if let sdkVersion = Bundle(for: SKTilemap.self).infoDictionary?["CFBundleShortVersionString"] {
        sktiledVersion = "\(sdkVersion)"
    }
    return sktiledVersion
}


/**
 Returns current framework build version.

 - returns: `String` SKTiled framework build version.
 */
func getSKTiledBuildVersion() -> String? {
    var buildVersion: String? = nil
    if let bundleVersion = Bundle(for: SKTilemap.self).infoDictionary?["CFBundleVersion"] {
        buildVersion = "\(bundleVersion)"
    }
    return buildVersion
}


/**
 Returns current framework Swift version.

 - returns: `String` Swift version.
 */
public func getSwiftVersion() -> String {
    var swiftVersion = ""
    #if swift(>=4.2)
    swiftVersion = "4.2"
    #elseif swift(>=4.1)
    swiftVersion = "4.1"
    #elseif swift(>=4.0)
    swiftVersion = "4.0"
    #else
    swiftVersion = "invalid"
    #endif
    return swiftVersion
}


/**
 Dumps SKTiled framework globals to the console.
 */
public func SKTiledGlobals() {
    TiledGlobals.default.dumpStatistics()
}


/**
 Returns the device scale factor.

 - returns: `CGFloat` device scale.
 */
public func getContentScaleFactor() -> CGFloat {
    var scaleFactor: CGFloat = 1.0
    #if os(macOS)
    scaleFactor = NSScreen.main!.backingScaleFactor
    #endif

    #if os(iOS)
    scaleFactor = UIScreen.main.scale
    #endif

    #if os(tvOS)
    scaleFactor = UIScreen.main.scale
    #endif
    return scaleFactor
}


// MARK: - CPU Usage

/**
 Returns a scaled double representing CPU usage.

 - returns: `Double` scaled percentage of CPU power used by the current app.
 */
public func cpuUsage() -> Double {
    var kr: kern_return_t
    var task_info_count: mach_msg_type_number_t

    task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
    var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))

    kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
    if kr != KERN_SUCCESS {
        return -1
    }

    var thread_list: thread_act_array_t? = UnsafeMutablePointer(mutating: [thread_act_t]())
    var thread_count: mach_msg_type_number_t = 0
    defer {
        if let thread_list = thread_list {
            vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(thread_list).pointee), vm_size_t(thread_count))
        }
    }

    kr = task_threads(mach_task_self_, &thread_list, &thread_count)

    if kr != KERN_SUCCESS {
        return -1
    }

    var tot_cpu: Double = 0

    if let thread_list = thread_list {

        for j in 0 ..< Int(thread_count) {
            var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
            var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
            kr = thread_info(thread_list[j], thread_flavor_t(THREAD_BASIC_INFO),
                             &thinfo, &thread_info_count)
            if kr != KERN_SUCCESS {
                return -1
            }

            let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)

            if threadBasicInfo.flags != TH_FLAGS_IDLE {
                tot_cpu += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
            }
        } // for each thread
    }

    return tot_cpu
}



func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
    var result = thread_basic_info()

    result.user_time = time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1])
    result.system_time = time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3])
    result.cpu_usage = threadInfo[4]
    result.policy = threadInfo[5]
    result.run_state = threadInfo[6]
    result.flags = threadInfo[7]
    result.suspend_count = threadInfo[8]
    result.sleep_time = threadInfo[9]

    return result
}

// MARK: - Image Creation Functions


#if os(iOS) || os(tvOS)
/**
 Returns an image of the given size.

 - parameter size:       `CGSize` size of resulting image.
 - parameter scale:      `CGFloat` scale of result (0 seems to scale 2x, using 1 seems best)
 - parameter whatToDraw: function detailing what to draw the image.
 - returns: `CGImage` result.
 */
public func imageOfSize(_ size: CGSize, scale: CGFloat = 1, _ whatToDraw: (_ context: CGContext, _ bounds: CGRect, _ scale: CGFloat) -> Void) -> CGImage? {
    // create an image of size, not opaque, not scaled
    UIGraphicsBeginImageContextWithOptions(size, false, scale)

    guard let context = UIGraphicsGetCurrentContext() else {
        return nil
    }

    context.interpolationQuality = .high
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    whatToDraw(context, bounds, scale)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result!.cgImage!
}

#else

/**
 Returns an image of the given size.

 - parameter size:       `CGSize` size of resulting image.
 - parameter scale:      `CGFloat` scale of result, for macOS that should be 1.
 - parameter whatToDraw: `() -> Void` function detailing what to draw the image.
 - returns: `CGImage` result.
 */
public func imageOfSize(_ size: CGSize, scale: CGFloat = 1, _ whatToDraw: (_ context: CGContext, _ bounds: CGRect, _ scale: CGFloat) -> Void) -> CGImage? {
    let scaledSize = size
    let image = NSImage(size: scaledSize)
    image.lockFocus()
    let nsContext = NSGraphicsContext.current!
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

public func duration(_ block: () -> Void) -> TimeInterval {
    let startTime = Date()
    block()
    return Date().timeIntervalSince(startTime)
}


// MARK: - Extensions

extension Bool {
    init<T : BinaryInteger>(_ integer: T) {
        self.init(integer != 0)
    }
}


extension BinaryInteger {
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
     Calculate a linear interpolation between two values.

     - returns: `CGFloat`
     */
    internal func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
        return start + (end - start) * t
    }

    /**
     Clamp the CGFloat between two values. Returns a new value.

     - parameter minv: `CGFloat` min value.
     - parameter maxv: `CGFloat` min value.
     - returns: `CGFloat` clamped result.
     */
    internal func clamped(_ minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        let min = minv < maxv ? minv : maxv
        let max = minv > maxv ? minv : maxv
        return self < min ? min : (self > max ? max : self)
    }

    /**
     Clamp the current value between min & max values.

     - parameter minv: `CGFloat` min value.
     - parameter maxv: `CGFloat` min value.
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
    internal func roundTo(_ decimals: Int = 2) -> String {
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
    public func roundTo(_ decimals: Int = 1) -> String {
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
    internal var shortDescription: String {
        return "[\(String(format: "%.0f", x)),\(String(format: "%.0f", y))]"
    }
}


extension CGPoint: Hashable {

    public var hashValue: Int {
        return x.hashValue << 32 ^ y.hashValue
    }
}



public extension CGSize {

    public var count: Int { return Int(width) * Int(height) }
    public var halfSize: CGSize { return CGSize(width: width / 2, height: height / 2) }
    public var halfWidth: CGFloat { return width / 2.0 }
    public var halfHeight: CGFloat { return height / 2.0 }

    public func roundTo(_ decimals: Int = 1) -> String {
        return "w: \(self.width.roundTo(decimals)), h: \(self.height.roundTo(decimals))"
    }

    internal var shortDescription: String {
        return "\(self.width.roundTo(0)) x \(self.height.roundTo(0))"
    }

    /// Returns the size as a vector_float2
    public var toVec2: vector_float2 {
        return vector_float2(Float(width), Float(height))
    }
}


public extension CGRect {

    /// Initialize with a center point and size.
    public init(center: CGPoint, size: CGSize) {
        self.init()
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
    public func roundTo(_ decimals: Int = 1) -> String {
        return "origin: \(Int(origin.x)), \(Int(origin.y)), size: \(Int(size.width)) x \(Int(size.height))"
    }

    internal var shortDescription: String {
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
}


public extension SKNode {

    /**
     Run an action with key & optional completion function.

     - parameter action:     `SKAction!` SpriteKit action.
     - parameter withKey:    `String!` action key.
     - parameter completion: `() -> Void?` optional completion function.
     */
    public func run(_ action: SKAction!, withKey: String!, completion block: (() -> Void)?) {
        if let block = block {
            let completionAction = SKAction.run( block )
            let compositeAction = SKAction.sequence([ action, completionAction ])
            run(compositeAction, withKey: withKey)
        } else {
            run(action, withKey: withKey)
        }
    }

    /**
     Animate the speed value over the given duration.

     - parameter to:       `CGFloat` new speed value.
     - parameter duration: `TimeInterval` animation length.
     */
    public func speed(to newSpeed: CGFloat, duration: TimeInterval, completion: (() -> Void)? = nil) {
        run(SKAction.speed(to: newSpeed, duration: duration), withKey: nil, completion: completion)
    }

    /**
     Adds a node to the end of the receiver’s list of child nodes.

     - parameter node:   `SKNode` new child node.
     - parameter fadeIn: `TimeInterval` fade in duration.
     */
    public func addChild(_ node: SKNode, fadeIn duration: TimeInterval) {
        node.alpha = (duration > 0) ? 0 : node.alpha
        self.addChild(node)

        let fadeInAction = SKAction.fadeIn(withDuration: duration)
        node.run(fadeInAction)
    }
}



public extension SKSpriteNode {

    /**
     Convenience initalizer to set texture filtering to nearest neighbor.

     - parameter pixelImage: `String` texture image named.
     */
    convenience public init(pixelImage named: String) {
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

    /// Returns the red, green and blue components of the color.
    internal var rgb: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let comps = components
        return (comps[0], comps[1], comps[2], comps[3])
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
        switch hex.count {
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

    /**
    
     Initialize an SKColor with integer values (0-255).
    
     - Parameters:
       - red:   `Int` red value (0-255).
       - green: `Int` green value (0-255).
       - blue:  `Int` blue value (0-255).
       - alpha: `Int` alpha value (0-255).
     - returns: `SKColor`
     */
    convenience public init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha) / 255)
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

        // Swift 4.2
        // let hex = String(254, radix: 16, uppercase: true)

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
        return vector_float4(components.map { Float($0) })
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
        for compDesc in components.map({ "\($0.roundTo(4))" }) {
            result.append(compDesc)
        }
        return "SKColor: " + result.joined(separator: ",")
    }
    
    
    // TODO: Take this out in master
    public var integerComponentDescription: String {
        var result: [String] = []
        let intComponents = components.map { Int($0 * 255)}
        for compDesc in intComponents.map({ "\($0)" }) {
            result.append(compDesc)
        }
        return "SKColor: " + result.joined(separator: ",")
    }
}


// MARK: - String

extension String {

    /**
     Simple function to split a string with the given pattern.

     - parameter pattern: `String` pattern to split string with.
     - returns: `[String]` groups of split strings.
     */
    func split(_ pattern: String) -> [String] {
        return self.components(separatedBy: pattern)
    }

    /**
     Pads string on the with a pattern to fill width.

     - parameter length:  `Int` length to fill.
     - parameter value:   `String` pattern.
     - parameter padLeft: `Bool` toggle this to pad the right.
     - returns: `String` padded string.
     */
    func zfill(length: Int, pattern: String="0", padLeft: Bool = true) -> String {
        var filler = ""
        let padamt: Int = length - self.count > 0 ? length - self.count : 0
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
    func pad(_ toSize: Int) -> String {
        // current string length
        let currentLength = self.count
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
    func substitute(_ pattern: String, replaceWith: String) -> String {
        return self.replacingOccurrences(of: pattern, with: replaceWith)
    }

    /**
     Initialize with array of bytes.

     - parameter bytes: `[UInt8]` byte array.
     */
    public init(_ bytes: [UInt8]) {
        self.init()
        for byte in bytes {
            self.append(String(UnicodeScalar(byte)))
        }
    }

    /**
     Clean up whitespace & carriage returns.

     - returns: `String` scrubbed string.
     */
    func scrub() -> String {
        var scrubbed = self.replacingOccurrences(of: "\n", with: "")
        scrubbed = scrubbed.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return scrubbed.replacingOccurrences(of: " ", with: "")
    }


    /// Captialize the first letter.
    var uppercaseFirst: String {
        let lowerString = self.lowercased()
        let first = lowerString.prefix(1)
        return first.uppercased() + lowerString.dropFirst()
    }

    func nsRange(fromRange range: Range<Index>) -> NSRange {
        let from = range.lowerBound
        let to = range.upperBound
        let location = distance(from: startIndex, to: from)
        let length = distance(from: from, to: to)
        return NSRange(location: location, length: length)
    }

    // MARK: URL

    /// Returns a url for the string.
    var url: URL { return URL(fileURLWithPath: self.expanded) }

    /// Expand the users home path.
    var expanded: String { return NSString(string: self).expandingTildeInPath }

    /// Returns the url parent directory.
    var parentURL: URL {
        var path = URL(fileURLWithPath: self.expanded)
        path.deleteLastPathComponent()
        return path
    }

    /// Returns true if the string represents a path that exists.
    var fileExists: Bool {
        return FileManager.default.fileExists(atPath: self.url.path)
    }

    /// Returns true if the string represents a path that exists and is a directory.
    var isDirectory: Bool {
        var isDir : ObjCBool = false
        return FileManager.default.fileExists(atPath: self, isDirectory: &isDir)
    }

    /// Returns the filename if string is a url.
    var filename: String {
        return FileManager.default.displayName(atPath: self.url.path)
    }

    /// Returns the file basename.
    var basename: String {
        return self.url.deletingPathExtension().lastPathComponent
    }

    /// Returns the file extension.
    var fileExtension: String {
        return self.url.pathExtension
    }
}


// MARK: - URL

extension URL {

    /// Returns the path file name without file extension.
    var basename: String {
        return self.deletingPathExtension().lastPathComponent
    }

    /// Returns the file name without the parent directory.
    var filename: String {
        return FileManager.default.displayName(atPath: path)
    }

    /// Returns the parent path of the file.
    var parent: String? {
        let mutableURL = self
        let result = (mutableURL.deletingLastPathComponent().relativePath == ".") ? nil : mutableURL.deletingLastPathComponent().relativePath
        return result
    }

    /// Returns true if the URL represents a path that exists.
    var fileExists: Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }

    /// Returns true if the URL represents a path that exists and is a directory.
    var isDirectory: Bool {
        var isDir : ObjCBool = false
        return FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir)
    }

    /// Returns true if the URL represents a path in the app bundle.
    var isBundled: Bool {
        let mutableURL = self
        let result = (mutableURL.deletingLastPathComponent().relativePath == ".") ? nil : mutableURL.deletingLastPathComponent().relativePath
        return result == nil
    }
}


// MARK: - TimeInterval

extension TimeInterval {

    /// Returns the current value in milleseconds.
    var milleseconds: Double {
        return Double(self * 1000)
    }
}


// MARK: - Events & Vallbacks

extension Notification.Name {

    public struct Tileset {
        public static let DataAdded             = Notification.Name(rawValue: "com.sktiled.notification.name.tileset.dataAdded")
        public static let DataRemoved           = Notification.Name(rawValue: "com.sktiled.notification.name.tileset.dataRemoved")
        public static let SpriteSheetUpdated    = Notification.Name(rawValue: "com.sktiled.notification.name.tileset.spritesheetUpdated")
    }

    public struct TileData {
        public static let FrameAdded            = Notification.Name(rawValue: "com.sktiled.notification.name.tileData.frameAdded")
        public static let TextureChanged        = Notification.Name(rawValue: "com.sktiled.notification.name.tileData.textureChanged")
        public static let ActionAdded           = Notification.Name(rawValue: "com.sktiled.notification.name.tileData.actionAdded")
    }

    public struct Layer {
        public static let TileAdded             = Notification.Name(rawValue: "com.sktiled.notification.name.layer.tileAdded")
        public static let AnimatedTileAdded     = Notification.Name(rawValue: "com.sktiled.notification.name.layer.animatedTileAdded")
        public static let ObjectAdded           = Notification.Name(rawValue: "com.sktiled.notification.name.layer.objectAdded")
        public static let ObjectRemoved         = Notification.Name(rawValue: "com.sktiled.notification.name.layer.objectRemoved")
    }

    public struct Tile {
        public static let DataChanged           = Notification.Name(rawValue: "com.sktiled.notification.name.tile.dataChanged")
        public static let RenderModeChanged     = Notification.Name(rawValue: "com.sktiled.notification.name.tile.renderModeChanged")
    }

    public struct Map {
        public static let FinishedRendering     = Notification.Name(rawValue: "com.sktiled.notification.name.map.finishedRendering")
        public static let Updated               = Notification.Name(rawValue: "com.sktiled.notification.name.map.updated")
        public static let RenderStatsUpdated    = Notification.Name(rawValue: "com.sktiled.notification.name.map.renderStatsUpdated")
        public static let CacheUpdated          = Notification.Name(rawValue: "com.sktiled.notification.name.map.cacheUpdated")
        public static let UpdateModeChanged     = Notification.Name(rawValue: "com.sktiled.notification.name.map.updateModeChanged")

    }

    public struct DataStorage {
        public static let ProxyVisibilityChanged  = Notification.Name(rawValue: "com.sktiled.notification.name.dataStorage.proxyVisibilityChanged")
        public static let IsolationModeChanged    = Notification.Name(rawValue: "com.sktiled.notification.name.dataStorage.isolationModeChanged")
    }

    public struct Globals {
        public static let Updated                 = Notification.Name(rawValue: "com.sktiled.notification.name.globals.updated")
    }

    public struct Camera {
        public static let Updated                 = Notification.Name(rawValue: "com.sktiled.notification.name.camera.updated")
    }

    public struct RenderStats {
        public static let StaticTilesUpdated    = Notification.Name(rawValue: "com.sktiled.notification.name.renderStats.staticTilesUpdated")
        public static let AnimatedTilesUpdated  = Notification.Name(rawValue: "com.sktiled.notification.name.renderStats.animatedTilesUpdated")
        public static let VisibilityChanged     = Notification.Name(rawValue: "com.sktiled.notification.name.renderStats.visibilityChanged")
    }
}


extension OptionSet where RawValue: FixedWidthInteger {

    public func elements() -> AnySequence<Self> {
        var remainingBits = rawValue
        var bitMask: RawValue = 1
        return AnySequence {
            return AnyIterator {
                while remainingBits != 0 {
                    defer { bitMask = bitMask &* 2 }
                    if remainingBits & bitMask != 0 {
                        remainingBits = remainingBits & ~bitMask
                        return Self(rawValue: bitMask)
                    }
                }
                return nil
            }
        }
    }
}



extension SKAction {

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
     Custom action to animate shape colors over a duration.

     - parameter duration: `TimeInterval` time for the effect.
     - returns: `SKAction` custom shape fade action.
     */
    public class func colorFadeAction(after delay: TimeInterval) -> SKAction {
        // Create a custom action for color fade
        let duration: TimeInterval = 1.0
        let action = SKAction.customAction(withDuration: duration) {(node, elapsed) in
            if let shape = node as? SKShapeNode {

                let currentStroke = shape.strokeColor
                let currentFill = shape.fillColor

                // Calculate the changing color during the elapsed time.
                let fraction = elapsed / CGFloat(duration)

                let currentStrokeRGB = currentStroke.rgb
                let currentFillRGB = currentFill.rgb
                let endColorRGB: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) = (0,0,0,0)

                let sred = CGFloat().lerp(start: currentStrokeRGB.red, end: endColorRGB.red, t: fraction)
                let sgreen = CGFloat().lerp(start: currentStrokeRGB.green, end: endColorRGB.green, t: fraction)
                let sblue = CGFloat().lerp(start: currentStrokeRGB.blue, end: endColorRGB.blue, t: fraction)
                let salpha = CGFloat().lerp(start: currentStrokeRGB.alpha, end: endColorRGB.alpha, t: fraction)

                let fred = CGFloat().lerp(start: currentFillRGB.red, end: endColorRGB.red, t: fraction)
                let fgreen = CGFloat().lerp(start: currentFillRGB.green, end: endColorRGB.green, t: fraction)
                let fblue = CGFloat().lerp(start: currentFillRGB.blue, end: endColorRGB.blue, t: fraction)
                let falpha = CGFloat().lerp(start: currentFillRGB.alpha, end: endColorRGB.alpha, t: fraction)


                let newStokeColor = SKColor(red: sred, green: sgreen, blue: sblue, alpha: salpha)
                let newFillColor = SKColor(red: fred, green: fgreen, blue: fblue, alpha: falpha)

                shape.strokeColor = newStokeColor
                shape.fillColor = newFillColor
            }
        }

        return SKAction.afterDelay(delay, performAction: action)
    }


    /**
     Custom action to fade a node's alpha after a pause.

     - returns: `SKAction` custom fade action.
     */
    class func fadeAfter(wait duration: TimeInterval, alpha: CGFloat) -> SKAction {
        return SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.fadeAlpha(to: alpha, duration: 0.5)])
    }

    /**
     * Performs an action after the specified delay.
     */
    class func afterDelay(_ delay: TimeInterval, performAction action: SKAction) -> SKAction {
        return SKAction.sequence([SKAction.wait(forDuration: delay), action])
    }

    /**
     * Performs a block after the specified delay.
     */
    class func afterDelay(_ delay: TimeInterval, runBlock block: @escaping () -> Void) -> SKAction {
        return SKAction.afterDelay(delay, performAction: SKAction.run(block))
    }

    /**
     * Removes the node from its parent after the specified delay.
     */
    class func removeFromParentAfterDelay(_ delay: TimeInterval) -> SKAction {
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
    return CGSize(width: abs(size.width), height: abs(size.height))
}


// MARK: CGVector
public func + (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
}


public func += (lhs: inout CGVector, rhs: CGVector) {
    lhs.dx += rhs.dx
    lhs.dy += rhs.dy
}


public func - (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
}

/*
public func -= (lhs: inout CGVector, rhs: CGVector) {
    lhs -= rhs
}
*/

public func * (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx * rhs.dx, dy: lhs.dy * rhs.dy)
}

/*
public func *= (lhs: inout CGVector, rhs: CGVector) {
    lhs *= rhs
}
*/

public func * (vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
}

/*
public func *= (vector: inout CGVector, scalar: CGFloat) {
    vector *= scalar
}
*/

public func / (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx / rhs.dx, dy: lhs.dy / rhs.dy)
}

/*
public func /= (lhs: inout CGVector, rhs: CGVector) {
    lhs /= rhs
}
*/

public func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
    return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
}

/*
public func /= (lhs: inout CGVector, rhs: CGFloat) {
    lhs /= rhs
}
*/

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
    lhs.x += rhs.x
    lhs.y += rhs.y
}


public func - (lhs: int2, rhs: int2) -> int2 {
    return int2(lhs.x - rhs.x, lhs.y - rhs.y)
}


public func -= (lhs: inout int2, rhs: int2) {
    lhs.x -= rhs.x
    lhs.y -= rhs.y

}


public func * (lhs: int2, rhs: int2) -> int2 {
    return int2(lhs.x * rhs.x, lhs.y * rhs.y)
}

public func *= (lhs: inout int2, rhs: int2) {
    lhs.x *= rhs.x
    lhs.y *= rhs.y
}


public func / (lhs: int2, rhs: int2) -> int2 {
    return int2(lhs.x / rhs.x, lhs.y / rhs.y)
}

// Swift 4 Error
/*
public func /= (lhs: inout int2, rhs: int2) {
    lhs /= rhs
}


public func == (lhs: int2, rhs: int2) -> Bool {
    return (lhs.x == rhs.x) && (lhs.y == rhs.y)
}

internal func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
    return lhs.distance(rhs) < 0.000001
}
*/


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
                            imageScale: CGFloat = 8,
                            lineScale: CGFloat = 1) -> CGImage? {


    // get the ui scale value for the device
    let uiScale: CGFloat = TiledGlobals.default.contentScale

    let size = layer.size
    let tileWidth = layer.tileWidth * imageScale
    let tileHeight = layer.tileHeight * imageScale

    let tileWidthHalf = tileWidth / 2
    let tileHeightHalf = tileHeight / 2

    // image size is the rendered size
    let sizeInPoints = (layer.sizeInPoints * imageScale)
    let defaultLineWidth: CGFloat = (imageScale / uiScale) * lineScale

    guard sizeInPoints != CGSize.zero else {
        return nil
    }


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
    let uiScale: CGFloat = TiledGlobals.default.contentScale

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
    let properties = Dictionary<NSBitmapImageRep.PropertyKey, AnyObject>()
    let data: Data = bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: properties)!
    if !((try? data.write(to: URL(fileURLWithPath: url.path), options: [])) != nil) {
        Logger.default.log("Error: write to file failed.", level: .error)
    }

    Logger.default.log("writing image: \(url.path)", level: .info)
    return data
}
#endif



internal func drawAnchor(_ node: SKNode,
                         withKey key: String = "ANCHOR",
                         withLabel: String? = nil,
                         labelSize: CGFloat = 10,
                         labelOffsetX: CGFloat = 0,
                         labelOffsetY: CGFloat = 0,
                         radius: CGFloat = 4,
                         anchorColor: SKColor = SKColor.red,
                         zoomScale: CGFloat = 0) -> AnchorNode {

    node.childNode(withName: key)?.removeFromParent()
    let anchor = AnchorNode(radius: radius, color: anchorColor, label: withLabel, offsetX: labelOffsetX, offsetY: labelOffsetY, zoom: zoomScale)
    anchor.labelSize = labelSize
    node.addChild(anchor)
    anchor.position = CGPoint(x: 0, y: 0)
    anchor.zPosition = node.zPosition * 10
    return anchor
}


// MARK: - Polygon Drawing

/**
 Returns an array of points for the given dimensions.

 - parameter width:   `CGFloat` rect width.
 - parameter height:  `CGFloat` rect height.
 - parameter origin: `CGPoint` rectangle origin.
 - returns: `[CGPoint]` array of points.
 */
public func rectPointArray(_ width: CGFloat, height: CGFloat, origin: CGPoint = CGPoint.zero) -> [CGPoint] {
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
public func rectPointArray(_ size: CGSize, origin: CGPoint = CGPoint.zero) -> [CGPoint] {
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
public func polygonPointArray(_ sides: Int, radius: CGSize, offset: CGFloat = 0, origin: CGPoint = CGPoint.zero) -> [CGPoint] {
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
public func polygonPath(_ points: [CGPoint], closed: Bool = true) -> CGPath {
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
public func polygonPath(_ sides: Int, radius: CGSize, offset: CGFloat = 0, origin: CGPoint = CGPoint.zero) -> CGPath {
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
 - parameter scale: `CGFloat` device scale.
 */
public func clampNodePosition(node: SKNode, scale: CGFloat) {
    node.position = clampedPosition(point: node.position, scale: scale)
    if let parentNode = node.parent {
        // check that the parent is not the scene
        if parentNode != node.scene {
            clampNodePosition(node: parentNode, scale: scale)
        }
    }
}



/**
 Dumps SKTiled framework globals to the console.
 */
@available(*, deprecated, renamed: "SKTiledGlobals()")
public func getSKTiledGlobals() {
    TiledGlobals.default.dumpStatistics()
}


/**
 Clamp the position of a given node (and parent).

 - parameter node:  `SKNode` node to re-position.
 - parameter scale: `CGFloat` device scale.
 */
@available(*, deprecated, renamed: "clampNodePosition(node:scale:)")
public func clampPositionWithNode(node: SKNode, scale: CGFloat) {
    clampNodePosition(node: node, scale: scale)
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
