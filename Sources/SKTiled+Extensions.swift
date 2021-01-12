//
//  SKTiled+Extensions.swift
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
import zlib
#if os(iOS) || os(tvOS)
import UIKit
import MobileCoreServices
typealias Image = UIImage
typealias SKScreen = UIScreen

#else
import Cocoa
typealias Image = NSImage
typealias SKScreen = NSScreen
#endif



// MARK: - Global Functions

/// Returns true if the current build is a release build.
internal func getBuildConfiguration() -> Bool {
    var result = true
    #if DEBUG
    result = false
    #endif
    return result
}

/// Returns current framework version.
///
/// - Returns: SKTiled framework version.
internal func getSKTiledVersion() -> String {
    var sktiledVersion = "0"
    if let sdkVersion = Bundle(for: SKTilemap.self).infoDictionary?["CFBundleShortVersionString"] {
        sktiledVersion = "\(sdkVersion)"
    }
    return sktiledVersion
}

/// Returns current framework build version.
///
/// - Returns: SKTiled framework build version.
internal func getSKTiledBuildVersion() -> String? {
    var buildVersion: String?
    if let bundleVersion = Bundle(for: SKTilemap.self).infoDictionary?["CFBundleVersion"] {
        buildVersion = "\(bundleVersion)"
    }
    return buildVersion
}

/// Returns current framework version suffix (ie: `beta`).
///
/// - Returns: SKTiled framework version suffix.
internal func getSKTiledVersionSuffix() -> String? {
    var versionSuffix: String?
    if let bundleSuffixValue = Bundle(for: SKTilemap.self).infoDictionary?["CFBundleVersionSuffix"] {
        versionSuffix = "\(bundleSuffixValue)"
    }
    return versionSuffix
}

/// Returns current framework Swift version.
///
/// - Returns: swift version, represented as a string.
internal func getSwiftVersion() -> String {
    var swiftVersion = "5.0"
    #if swift(>=5.4)
    swiftVersion = "5.4"
    #elseif swift(>=5.3)
    swiftVersion = "5.3"
    #elseif swift(>=5.2)
    swiftVersion = "5.2"
    #elseif swift(>=5.1)
    swiftVersion = "5.1"
    #elseif swift(>=5.0)
    swiftVersion = "5.0"
    #elseif swift(>=4.2)
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


/// Dumps SKTiled framework globals to the console.
public func SKTiledGlobals() {
    TiledGlobals.default.dumpStatistics()
}

/// Returns the device screen size.
///
/// - Returns: screen resolution.
public func getScreenSize() -> CGSize {
    var screenSize: CGSize = CGSize.zero
    #if os(macOS)
    screenSize = NSScreen.main!.frame.size
    #endif

    #if os(iOS)
    screenSize = UIScreen.main.bounds.size
    #endif

    #if os(tvOS)
    screenSize = UIScreen.main.bounds.size
    #endif
    return screenSize
}

/// Returns the device scale factor.
///
/// - Returns: device scale.
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


/// Returns a scaled double representing CPU usage.
///
/// - Returns: scaled percentage of CPU power used by the current app.
public func cpuUsage() -> Double {
    var kr: kern_return_t
    var task_info_count: mach_msg_type_number_t

    task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
    var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))

    kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
    if kr != KERN_SUCCESS {
        return -1
    }

    var thread_list: thread_act_array_t?
    var thread_count: mach_msg_type_number_t = 0
    defer {
        if let thread_list = thread_list {
            vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(thread_list).pointee), vm_size_t(thread_count))
        }
    }

    kr = task_threads(mach_task_self_, &thread_list, &thread_count)

    if (kr != KERN_SUCCESS) {
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


internal func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
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


#if os(macOS)

/// Returns an image of the given size.
/// - Parameters:
///   - size: size of resulting image.
///   - scale: scale of result, for macOS that should be 1.
///   - whatToDraw: function detailing what to draw the image.
/// - Returns: resulting image.
public func imageOfSize(_ size: CGSize,
                        scale: CGFloat = 1,
                        _ whatToDraw: (_ context: CGContext,
                                       _ bounds: CGRect,
                                       _ scale: CGFloat) -> Void) -> CGImage? {
    let scaledSize = size
    let image = NSImage(size: scaledSize)
    image.lockFocus()
    let nsContext = NSGraphicsContext.current!
    nsContext.imageInterpolation = .medium
    let context = nsContext.cgContext
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    whatToDraw(context, bounds, scale)   // was `1` not `scale`
    image.unlockFocus()
    var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)

    // force the buffer to empty
    nsContext.flushGraphics()
    return imageRef!
}

#else


/// Returns an image of the given size.
///
/// - Parameters:
///   - size: size of resulting image.
///   - scale: scale of result (0 seems to scale 2x, using 1 seems best).
///   - whatToDraw: function detailing what to draw the image.
/// - Returns: resulting image.
public func imageOfSize(_ size: CGSize,
                        scale: CGFloat = 1,
                        _ whatToDraw: (_ context: CGContext,
                                       _ bounds: CGRect,
                                       _ scale: CGFloat) -> Void) -> CGImage? {

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

#endif


/// Write a PNG image to file.
///
/// - Parameters:
///   - image: image data.
///   - fileUrl: destination url.
/// - Returns: image was created.
@discardableResult
public func writeCGImage(_ image: CGImage, to fileUrl: URL) -> Bool {
    guard let destination = CGImageDestinationCreateWithURL(fileUrl as CFURL, kUTTypePNG, 1, nil) else {
        Logger.default.log("error writing image to '\(fileUrl.path)'", level: .error, symbol: "SKTiled")
        return false
    }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}



/// Check a tile ID for translation information. Returns the translated tile ID and the corresponding flip flags.
///
/// - Parameter id: tile ID.
/// - Returns: tuple of global id and flip flags.
public func flippedTileFlags(id: UInt32) -> (globalID: UInt32, hflip: Bool, vflip: Bool, dflip: Bool) {

    // masks for tile flipping
    let flippedDiagonalFlag: UInt32   = 0x20000000
    let flippedVerticalFlag: UInt32   = 0x40000000
    let flippedHorizontalFlag: UInt32 = 0x80000000

    let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
    let flippedMask = ~(flippedAll)

    let flipHoriz: Bool = (id & flippedHorizontalFlag) != 0
    let flipVert:  Bool = (id & flippedVerticalFlag) != 0
    let flipDiag:  Bool = (id & flippedDiagonalFlag) != 0

    // clear the flags with the mask
    let globalID = id & flippedMask

    return (globalID, flipHoriz, flipVert, flipDiag)
}


/// Given a new id and flip flags, return a new masked id.
///
/// - Parameters:
///   - globalID: global id (no flags).
///   - hflip: flip horizontal flag.
///   - vflip: flip vertically flag.
///   - dflip: flip disagonally flag.
/// - Returns: global id representing the tile id & flags.
public func maskedGlobalId(globalID: UInt32, hflip: Bool = false, vflip: Bool = false, dflip: Bool = false) -> UInt32 {

    /// clear any current flags (just in case)
    var maskedId = flippedTileFlags(id: globalID).globalID

    if (hflip == true) {
        maskedId |= 0x80000000
    }

    if (vflip == true) {
        maskedId |= 0x40000000
    }

    if (dflip == true) {
        maskedId |= 0x20000000
    }

    return maskedId
}


/// Timer function.
///
/// - Parameter block: block to meature for time.
/// - Returns: time in seconds.
public func duration(_ block: () -> Void) -> TimeInterval {
    let startTime = Date()
    block()
    return Date().timeIntervalSince(startTime)
}

@discardableResult
func measure<A>(name: String = "", _ block: () -> A) -> A {
    let startTime = CACurrentMediaTime()
    let result = block()
    let timeElapsed = CACurrentMediaTime() - startTime
    print("Time: \(name) - \(timeElapsed)")
    return result
}


// MARK: - Extensions

extension Bool {
    init<T : BinaryInteger>(_ integer: T) {
        self.init(integer != 0)
    }

    /// Toggle the current value.
    mutating func toggle() {
        self = !self
    }

    /// Return the value as a Github markdown check string.
    var valueAsCheckbox: String {
        return (self == true) ? "[x]" : "[ ]"
    }

    var valueAsOnOff: String {
        return (self == true) ? "on" : "off"
    }
}


extension BinaryInteger {
    init(_ bool: Bool) {
        self = bool ? 1 : 0
    }
}


extension SignedInteger {
    public var hexString: String { return "0x" + String(self, radix: 16) }
    public var binaryString: String { return "0b" + String(self, radix: 2) }
}


extension UnsignedInteger {
    public var hexString: String { return "0x" + String(self, radix: 16) }
    public var binaryString: String { return "0b" + String(self, radix: 2) }
}



extension UInt32 {

    /// returns number of digits in Int number
    public var digitCount: Int {
        return numberOfDigits(in: self)
    }

    // private recursive method for counting digits,
    func numberOfDigits(in number: UInt32) -> Int {
        if (number < 10) {
            return 1
        } else {
            return 1 + numberOfDigits(in: number/10)
        }
    }
}




extension Int {

    /// returns number of digits in Int number
    public var digitCount: Int {
        return numberOfDigits(in: self)
    }

    // private recursive method for counting digits.
    func numberOfDigits(in number: Int) -> Int {
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
    public static func random(_ range: ClosedRange<Int>) -> Int {
        return range.lowerBound + Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound + 1)))
    }
}


extension Array where Element: SKNode {

    public func topMost() -> SKNode? {
        return self.sorted(by: { $0.zPosition > $1.zPosition }).first
    }
}





// MARK: - UIKit


#if os(iOS) || os(tvOS)

extension UIImage {

    /// Add an image to this image.
    ///
    /// - Parameters:
    ///   - image: image to add
    ///   - rect: draw rectangle.
    /// - Returns: resulting image.
    internal func image(byDrawingImage image: UIImage, inRect rect: CGRect) -> UIImage! {
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image.draw(in: rect)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    /// Instantiate an image with an file url.
    ///
    /// - Parameter fileUrl: image file url.
    public convenience init?(contentsOf fileUrl: URL) {
        self.init(contentsOfFile: fileUrl.path.expanded)
    }
}



extension UIColor {


    /// Returns a slightly darkened version of the color.
    ///
    /// - Parameter value: shadow amount.
    /// - Returns: darkened color.
    public func shadow(withLevel value: CGFloat) -> UIColor? {
        return self.colorWithBrightness(factor: -value)
    }
}

#endif




// MARK: - CoreGraphics


extension CGFloat {

    /// Returns the absolute value.
    var abs: CGFloat {
        return Swift.abs(self)
    }

    /// Convert a float to radians.
    ///
    /// - Returns: the float in radians.
    func radians() -> CGFloat {
        let b = CGFloat(Double.pi) * (self / 180)
        return b
    }

    /// Convert a float to degrees.
    ///
    /// - Returns: the float in degrees.
    func degrees() -> CGFloat {
        return self * 180.0 / CGFloat(Double.pi)
    }

    /// Calculate a linear interpolation between a minimum & maximum value.
    ///
    /// - Parameters:
    ///   - start: minimum (start) value.
    ///   - end: maximum (end) value.
    ///   - t: percentage of the given range.
    /// - Returns: interpolated value.
    func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
        return start + (end - start) * t
    }

    /// Clamp the CGFloat between two values. Returns a new value.
    ///
    /// - Parameters:
    ///   - minv: min value.
    ///   - maxv: max value.
    /// - Returns: clamped result.
    func clamped(_ minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        let min = minv < maxv ? minv : maxv
        let max = minv > maxv ? minv : maxv
        return self < min ? min : (self > max ? max : self)
    }

    /// Clamp the current value between min & max values.
    ///
    /// - Parameters:
    ///   - minv: min value.
    ///   - maxv: min value.
    /// - Returns: clamped result.
    mutating func clamp(_ minv: CGFloat, _ maxv: CGFloat) -> CGFloat {
        self = clamped(minv, maxv)
        return self
    }

    /// Returns a string representation of the value rounded to the current decimals.
    ///
    /// - Parameter decimals: number of decimals to round to.
    /// - Returns: rounded display string.
    func roundTo(_ decimals: Int = 2) -> String {
        return String(format: "%.\(String(decimals))f", self)
    }

    /// Returns the value rounded to the nearest .5 increment.
    ///
    /// - Returns: rounded value.
    func roundToHalf() -> CGFloat {
        let scaled = self * 10.0
        let result = scaled - (scaled.truncatingRemainder(dividingBy: 5))
        return result.rounded() / 10
    }

    static func random(_ range: ClosedRange<CGFloat>) -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * (range.upperBound - range.lowerBound) + range.lowerBound
    }
}


/// Sine function that accepts angle for trig operations.
///
/// - Parameters:
///   - degrees: angle.
/// - Returns: sine result.
internal func sin(degrees: CGFloat) -> CGFloat {
    return CGFloat(sin(degrees: degrees.native))
}


/// Sine function that accepts an angle for trig operations.
///
/// - Parameter degrees: angle.
/// - Returns: sine result.
internal func sin(degrees: Double) -> Double {
    return __sinpi(degrees/180.0)
}


/// Sine function that accepts degrees for trig operations.
///
/// - Parameter degrees: angle.
/// - Returns: sine result.
internal func sin(degrees: Float) -> Float {
    return __sinpif(degrees/180.0)
}



extension CGPoint {

    /// Returns the current point, snapped to a `simd_int2` coordinate.
    ///
    /// - Parameter squareSize: rounding size (grid size).
    /// - Returns: rounded vector coordinate.
    public func gridPoint(squareSize: simd_int2) -> simd_int2 {
        let gx = Int32(Darwin.round(x))/squareSize.x
        let gy = Int32(Darwin.round(y))/squareSize.y
        return simd_int2(arrayLiteral: gx,gy)
    }

    /// Returns the current point, snapped to a `GGSize` value.
    ///
    /// - Parameter squareSize: rounding size (grid size).
    /// - Returns: rounded vector coordinate.
    public func gridPoint(size: CGSize) -> CGPoint {
        let point = gridPoint(squareSize: simd_int2(arrayLiteral: Int32(size.halfWidth), Int32(size.halfHeight)))
        return point.cgPoint
    }

    /// Returns an point inverted in the Y-coordinate.
    public var invertedY: CGPoint {
        return CGPoint(x: self.x, y: self.y * -1)
    }

    /// Returns a display string rounded to a given number of decimal places.
    ///
    /// - Parameter decimals: decimals to round to.
    /// - Returns: display string.
    public func stringRoundedTo(_ decimals: Int = 1) -> String {
        return "x: \(self.x.roundTo(decimals)), y: \(self.y.roundTo(decimals))"
    }

    /// Returns the point as a `simd_int2` instance.
    public var toVec2: simd_int2 {
        return simd_int2(arrayLiteral: xCoord, yCoord)
    }

    /// Returns the distance to another point.
    ///
    /// - Parameter point: point to compare.
    /// - Returns: distance to other point.
    public func distance(_ point: CGPoint) -> Float {
        let dx = Float(x - point.x)
        let dy = Float(y - point.y)
        return sqrt((dx * dx) + (dy * dy))
    }

    /// Returns the distance to the given node.
    ///
    /// - Parameter node: node to compare.
    /// - Returns: distance to the node.
    public func distance(to node: SKNode) -> CGFloat {
        return CGFloat(distance(node.position))
    }

    /// Return an integer value for x-coordinate.
    public var xCoord: Int32 {
        return Int32(x)
    }

    /// Return an integer value for y-coordinate.
    public var yCoord: Int32 {
        return Int32(y)
    }

    /// Returns a Boolean value indicating whether the two given values are equal.
    ///
    /// - Parameters:
    ///   - lhs: `CGPoint` point.
    ///   - rhs: `simd_int2` point.
    /// - Returns: values are equal.
    static func == (lhs: CGPoint, rhs: simd_int2) -> Bool {
        return Int32(lhs.x) == rhs.x && Int32(lhs.y) == rhs.y
    }

    /// Remaps current point values rounded up to the next largest integer.
    ///
    /// - Returns: remapped point.
    mutating public func ceil() -> CGPoint  {
        x = CGFloat(Darwin.ceil(Double(x)))
        y = CGFloat(Darwin.ceil(Double(x)))
        return self
    }

    /// Remaps current point values rounded down to the next largest integer.
    ///
    /// - Returns: remapped point.
    mutating public func floor() -> CGPoint  {
        x = CGFloat(Darwin.floor(Double(x)))
        y = CGFloat(Darwin.floor(Double(x)))
        return self
    }
}

// MARK: - CGPoint

extension CGPoint {

    /// Returns a shortened textual representation for debugging. ('[x: 10, y: 2]')
    public var coordDescription: String {
        return " [x: \(String(format: "%.0f", x)), y: \(String(format: "%.0f", y))]"
    }

    /// Returns a shortened textual representation for debugging. ('[10, 2]')
    public var shortDescription: String {
        return "[\(String(format: "%.0f", x)),\(String(format: "%.0f", y))]"
    }
}


extension CGPoint: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}


extension CGSize {

    public var area: CGFloat {
        return width * height
    }

    public var isSquare: Bool {
        width.abs == height.abs
    }

    public var isVertical: Bool {
        width.abs < height.abs
    }

    public var isHorizontal: Bool {
        width.abs > height.abs
    }
}

// MARK: - CGSize


/// :nodoc:
extension CGSize {

    /// Initialize with a single integer value representing both weidth & height.
    ///
    /// - Parameter value: width & height value.
    public init(value: IntegerLiteralType) {
        self.init(width: value, height: value)
    }

    /// Returns the count (in points) of this size.
    public var pointCount: Int {
        return Int(width) * Int(height)
    }

    /// Returns the width, halved.
    public var halfWidth: CGFloat {
        return width / 2.0
    }

    /// Returns the height, halved.
    public var halfHeight: CGFloat {
        return height / 2.0
    }

    /// Returns the size, halved.
    public var halfSize: CGSize {
        return CGSize(width: halfWidth, height: halfHeight)
    }

    /// Returns the size as a `vector_float2` type.
    public var toVec2: vector_float2 {
        return vector_float2(Float(width), Float(height))
    }

    /// Returns the scale ratio to another `CGSize`.
    ///
    /// - Parameter other: size to compare to.
    /// - Returns: scale ratio.
    public func scaleFactor(to other: CGSize) -> CGSize {
        return CGSize(width: other.width / self.width, height: other.height / self.height)
    }

    /// Returns a display string rounded to a given number of decimal places.
    ///
    /// - Parameter decimals: decimals to round to.
    /// - Returns: display string.
    public func stringRoundedTo(_ decimals: Int = 1) -> String {
        return "w: \(self.width.roundTo(decimals)), h: \(self.height.roundTo(decimals))"
    }

    /// Returns a shortened textual representation for debugging.
    public var shortDescription: String {
        return "\(self.width.roundTo(0)) x \(self.height.roundTo(0))"
    }
}


extension CGRect {

    /// Initialize with a center point and size.
    ///
    /// - Parameters:
    ///   - center: rectangle center point.
    ///   - size: rectangle size.
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

    /// Returns a rect by the bounds by a given amount.
    ///
    /// - Parameter amount: decimals to round to.
    /// - Returns: rectangle with inset value.
    public func insetBy(_ amount: CGFloat) -> CGRect {
        return self.insetBy(dx: amount, dy: amount)
    }

    /// Return a scaled copy.
    ///
    /// - Parameter scale: rectangle scale.
    /// - Returns: scaled rect.
    public func scaled(_ scale: CGFloat) -> CGRect {
        return CGRect(x: origin.x * scale, y: origin.y * scale,
                      width: size.width * scale, height: size.height * scale)
    }

    /// The bounding box size based from from the frame's rect.
    public var boundingRect: CGRect {
        return CGRect(origin: .zero, size: size)
    }

    /// Returns a display string rounded.
    ///
    /// - Parameter decimals: decimals to round to.
    /// - Returns: display string.
    public func stringRoundedTo(_ decimals: Int = 1) -> String {
        return "origin: \(Int(origin.x)), \(Int(origin.y)), size: \(Int(size.width)) x \(Int(size.height))"
    }

    /// Returns a shortened textual representation for debugging.
    public var shortDescription: String {
        return "x: \(Int(minX)), y: \(Int(minY)), w: \(width.roundTo()), h: \(height.roundTo())"
    }
}


extension CGVector {

    /// Returns the squared length of the vector described by the CGVector.
    ///
    /// - Returns: vector length.
    public func lengthSquared() -> CGFloat {
        return dx*dx + dy*dy
    }

    /// Return a vector int (for GameplayKit).
    public var toVec2: simd_int2 {
        return simd_int2(Int32(dx), Int32(dy))
    }
}


// MARK: - SpriteKit


extension SKScene {

    /// Returns the center point of a scene.
    public var center: CGPoint {
        return CGPoint(x: (size.width / 2) - (size.width * anchorPoint.x), y: (size.height / 2) - (size.height * anchorPoint.y))
    }

    /// Calculate the distance from the scene's origin.
    ///
    /// - Parameter pos: point in the scene.
    /// - Returns: distance from the given point to the scene center.
    public func distanceFromOrigin(_ pos: CGPoint) -> CGVector {
        let dx = (pos.x - center.x)
        let dy = (pos.y - center.y)
        return CGVector(dx: dx, dy: dy)
    }
}


extension SKTexture {

    /// Instantiate the texture with an image file url.
    ///
    /// - Parameter fileUrl: image file url.
    public convenience init?(contentsOf fileUrl: URL) {
        guard let image = Image(contentsOf: fileUrl) else {
            return nil
        }
        self.init(image: image)
    }

    /// Instantiate the texture with an image file path.
    ///
    /// - Parameter fileNamed: image file path.
    public convenience init?(contentsOfFile fileNamed: String) {
        guard let image = Image(contentsOfFile: fileNamed) else {
            return nil
        }
        self.init(image: image)
    }

    /// Save the texture to file.
    ///
    /// - Parameter url: export file path.
    /// - Returns: save was successful.
    public func writeTexture(to url: URL) -> Bool {
        let cgImage = self.cgImage()
        return writeCGImage(cgImage, to: url)
    }

    /// Returns the name of the current texture.
    public var name: String? {
        let comps = description.components(separatedBy: "'")
        return comps.count > 1 ? comps[1] : nil
    }
}



extension SKNode {

    /// Returns the distance from this node to another.
    ///
    /// - Parameter other: other node.
    /// - Returns: distance to other node.
    public func distance(to other: SKNode) -> CGFloat {
        return CGFloat(position.distance(other.position))
    }

    /// Returns the distance from this node to the given point.
    ///
    /// - Parameter point: point
    /// - Returns: distance to the given point.
    public func distance(to point: CGPoint) -> CGFloat {
        return CGFloat(position.distance(point))
    }
}



extension SKNode {

    /// Run an action with key & optional completion function.
    ///
    /// - Parameters:
    ///   - action: SpriteKit action.
    ///   - withKey: action key.
    ///   - block: optional completion function.
    public func run(_ action: SKAction!, withKey: String!, completion block: (() -> Void)?) {
        if let block = block {
            let completionAction = SKAction.run( block )
            let compositeAction = SKAction.sequence([ action, completionAction ])
            run(compositeAction, withKey: withKey)
        } else {
            run(action, withKey: withKey)
        }
    }

    /// Animate the speed value over the given duration.
    ///
    /// - Parameters:
    ///   - newSpeed: new speed value.
    ///   - duration: animation length.
    ///   - completion: optional completion handler.
    public func speed(to newSpeed: CGFloat, duration: TimeInterval, completion: (() -> Void)? = nil) {
        run(SKAction.speed(to: newSpeed, duration: duration), withKey: nil, completion: completion)
    }

    /// Add a node to the end of the receiver’s list of child nodes.
    ///
    /// - Parameters:
    ///   - node: new child node.
    ///   - duration: fade in duration.
    public func addChild(_ node: SKNode, fadeIn duration: TimeInterval) {
        node.alpha = (duration > 0) ? 0 : node.alpha
        self.addChild(node)

        let fadeInAction = SKAction.fadeIn(withDuration: duration)
        node.run(fadeInAction)
    }

    /// Returns an array of all parent nodes.
    ///
    /// - Returns: array of parent nodes.
    public func allParents() -> [SKNode] {
        var current = self as SKNode
        var result: [SKNode] = [current]
        while current.parent != nil {
            result.append(current.parent!)
            current = current.parent!
        }
        return result
    }
}


extension Sequence where Element: SKNode {

    /// Remove each node from their parent.
    public func removeFromParent() {
        forEach{ $0.removeFromParent() }
    }
}


// TODO: MOVE INTO DEMO FOLDER



extension SKSpriteNode {

    /// Convenience initalizer to set texture filtering to nearest neighbor.
    ///
    /// - Parameter named: texture image named.
    public convenience init(pixelImage named: String) {
        self.init(imageNamed: named)
        self.texture?.filteringMode = .nearest
    }
}


extension SKColor {

    /// Returns the hue, saturation, brightess & alpha components of the color.
    internal var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) = (0, 0, 0, 0)
        self.getHue(&(hsba.h), saturation: &(hsba.s), brightness: &(hsba.b), alpha: &(hsba.a))
        return hsba
    }

    /// Returns the red, green and blue components of the color.
    ///
    /// - Returns: color components.
    internal var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let comps = self.components
        return (comps.r, comps.g, comps.b, comps.a)
    }

    /// Lightens the color by the given percentage.
    ///
    /// - Parameter percent: amount to lighten.
    /// - Returns: lightened color.
    public func lighten(by percent: CGFloat) -> SKColor {
        return colorWithBrightness(factor: 1.0 + percent)
    }

    /// Darkens the color by the given percentage.
    ///
    /// - Parameter percent: amount to darken.
    /// - Returns: darkened color.
    public func darken(by percent: CGFloat) -> SKColor {
        return colorWithBrightness(factor: 1.0 - percent)
    }

    /// Return a modified color using the brightness factor provided.
    ///
    /// - Parameter factor: brightness factor.
    /// - Returns: modified color.
    public func colorWithBrightness(factor: CGFloat) -> SKColor {
        let components = self.hsba
        return SKColor(hue: components.h, saturation: components.s, brightness: components.b * factor, alpha: components.a)
    }

    /// Initialize an [`SKColor`][skcolor-url] with a hexadecimal string.
    ///
    /// - Parameter hexString: hexadecimal code.
    /// [skcolor-url]:https://developer.apple.com/reference/spritekit/skcolor
    public convenience init(hexString: String) {
        //let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let hex = expandShortenedHexString(hexString)
        var hexNumber = UInt64()
        Scanner(string: hex).scanHexInt64(&hexNumber)
        let a, r, g, b: UInt64
        switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (hexNumber >> 8) * 17, (hexNumber >> 4 & 0xF) * 17, (hexNumber & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, hexNumber >> 16, hexNumber >> 8 & 0xFF, hexNumber & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (hexNumber & 0x000000ff, hexNumber >> 24 & 0xFF, hexNumber >> 16 & 0xFF, hexNumber >> 8 & 0xFF)
            default:
                (a, r, g, b) = (0, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    /// Initialize an [`SKColor`][skcolor-url] with integer values (0-255).
    ///
    /// - Parameters:
    ///   - red: red value (0-255).
    ///   - green: green value (0-255).
    ///   - blue: blue value (0-255).
    ///   - alpha: alpha value (0-255).
    ///
    /// [skcolor-url]:https://developer.apple.com/reference/spritekit/skcolor
    public convenience init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha) / 255)
    }

    /// Returns the individual color RGBA components as float values.
    ///
    /// - Returns: RGBA color components.
    internal var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        guard let comps = cgColor.components else {
            return (0,0,0,0)
        }
        if (comps.count < 4) {
            return (comps.first!,comps.first!,comps.first!,comps.last!)
        }
        return (comps[0], comps[1], comps[2], comps[3])
    }

    /// Returns the individual color RGBA components as integer values.
    ///
    /// - Returns: RGBA color components.
    internal var integerCompoments: (r: Int, g: Int, b: Int, a: Int) {
        let comps = components
        let r = Int(comps.r * 255)
        let g = Int(comps.g * 255)
        let b = Int(comps.b * 255)
        let a = Int(comps.a * 255)
        return (r,g,b,a)
    }

    /// Returns a hexadecimal string representation of the color.
    ///
    /// - Returns: hexadecimal color value.
    public func hexString() -> String {
        let comps = integerCompoments
        var rgbHex = "#\(String(format: "%02x%02x%02x", comps.r, comps.g, comps.b))"
        rgbHex += (comps.a == 255) ? "" : String(format: "%02x", comps.a)
        return rgbHex
    }

    /// Blend this color with another `SKColor`.
    ///
    ///
    /// - Parameters:
    ///   - color: color to blend.
    ///   - s: blend amount.
    /// - Returns: resulting blended color
    internal func blend(with color: SKColor, factor s: CGFloat = 0.5) -> SKColor {
        let r1 = components.r
        let g1 = components.g
        let b1 = components.b
        let a1 = components.a

        let r2 = color.components.r
        let g2 = color.components.g
        let b2 = color.components.b
        let a2 = color.components.a

        let r = (r1 * s) + (1 - s) * r2
        let g = (g1 * s) + (1 - s) * g2
        let b = (b1 * s) + (1 - s) * b2
        let a = (a1 * s) + (1 - s) * a2

        return SKColor(red: r, green: g, blue: b, alpha: a)
    }

    /// Return the color as a floating-point vector.
    ///
    /// - Returns: vector representation of the color.
    internal func vec4() -> GLKVector4 {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return GLKVector4(v: (Float(r), Float(g), Float(b), Float(a)))
    }

    /// Returns the color represented as a `vector_float4` instance.
    public var toVec4: vector_float4 {
        let comps = components
        return vector_float4([comps.r, comps.g, comps.b, comps.a].map { Float($0) })
    }
}



/// :nodoc:
extension SKColor {

    /// Returns a string description of the color hex string value.
    ///
    ///  ie: `SKColor(hexString: "##2FD62A")`
    ///
    /// - Returns: RGBA component string description.
    public var hexDescription: String {
        return "SKColor(hexString:  '\(self.hexString())')"
    }

    /// Returns a string description of the color RGBA integer components.
    ///
    ///  ie: `SKColor(r: 227, g: 180, b: 71, a: 71)`
    ///
    /// - Returns: RGBA component string description.
    public var rgbaDescription: String {
        let comps = components
        let r = Int(comps.r * 255)
        let g = Int(comps.g * 255)
        let b = Int(comps.b * 255)
        let a = Int(comps.a * 255)
        return "SKColor(r: \(r), g: \(g), b: \(b), a: \(a))"
    }

    /// Returns a string description of the color RGBA float components.
    ///
    ///  ie: `SKColor(r: 0.1843, g: 0.8392, b: 0.1647, a: 1.0)`
    ///
    /// - Returns: RGBA component string description.
    public var componentDescription: String {
        let comps = components
        let r = comps.r.roundTo(3)
        let g = comps.g.roundTo(3)
        let b = comps.b.roundTo(3)
        let a = comps.a.roundTo(3)
        return "SKColor(r: \(r), g: \(g), b: \(b), a: \(a))"
    }
}



extension SKAction {

    /// Custom action to animate sprite textures with varying frame durations.
    ///
    /// - Parameters:
    ///   - frames: Array of tuples containing texture & duration.
    ///   - repeatForever: Run the animation forever.
    /// - Returns: Custom animation action.
    public class func tileAnimation(_ frames: [(texture: SKTexture, duration: TimeInterval)], repeatForever: Bool = true) -> SKAction {
        var actions: [SKAction] = []
        for frame in frames {
            actions.append(
                SKAction.group(
                    [
                        SKAction.setTexture(frame.texture, resize: false),
                        SKAction.wait(forDuration: frame.duration)
                    ]
                )
            )
        }

        // add the repeating action
        if (repeatForever == true) {
            return SKAction.repeatForever(SKAction.sequence(actions))
        }
        return SKAction.sequence(actions)
    }

    /// Creates an action to animate shape colors over a duration.
    ///
    /// - Parameter delay: Time for the effect.
    /// - Returns: Custom shape fade action.
    public class func colorFadeAction(after delay: TimeInterval) -> SKAction {
        // Create a custom action for color fade
        let duration: TimeInterval = 1.0
        let action = SKAction.customAction(withDuration: duration) {(node, elapsed) in
            if let shape = node as? SKShapeNode {

                let currentStroke = shape.strokeColor
                let currentFill = shape.fillColor

                // Calculate the changing color during the elapsed time.
                let fraction = elapsed / CGFloat(duration)

                let currentStrokeRGB = currentStroke.rgba
                let currentFillRGB = currentFill.rgba
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

    /// Custom action to fade a node's alpha after a pause.
    ///
    /// - Parameters:
    ///   - duration: effect duration.
    ///   - alpha: alpha value.
    /// - Returns: custom fade action.
    class func fadeAfter(wait duration: TimeInterval, alpha: CGFloat) -> SKAction {
        return SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.fadeAlpha(to: alpha, duration: 0.5)])
    }

    /// Performs an action after the specified delay.
    ///
    /// - Parameters:
    ///   - delay: length of delay.
    ///   - action: action to delay.
    /// - Returns: delayed action.
    class func afterDelay(_ delay: TimeInterval, performAction action: SKAction) -> SKAction {
        return SKAction.sequence([SKAction.wait(forDuration: delay), action])
    }

    /// Performs a block after the specified delay.
    ///
    /// - Parameters:
    ///   - delay: length of delay.
    ///   - block: closure.
    /// - Returns: delayed action.
    class func afterDelay(_ delay: TimeInterval, runBlock block: @escaping () -> Void) -> SKAction {
        return SKAction.afterDelay(delay, performAction: SKAction.run(block))
    }

    /// Removes the node from its parent after the specified delay.
    ///
    /// - Parameter delay: length of delay.
    /// - Returns: delayed action.
    class func removeFromParentAfterDelay(_ delay: TimeInterval) -> SKAction {
        return SKAction.afterDelay(delay, performAction: SKAction.removeFromParent())
    }

    /// Creates an action to colorize a sprite over time.
    ///
    /// - Parameters:
    ///   - with: blend color.
    ///   - colorBlendFactor: blend factor, 0-1.
    ///   - duration: transformation time.
    /// - Returns: colorize action.
    class func colorize(with: SKColor, colorBlendFactor: CGFloat, duration: TimeInterval) -> SKAction {
        // TODO: implement this
        return SKAction()
    }
}

/// Initialize a color with RGB Integer values (0-255).
///
/// - Parameters:
///   - r: red component.
///   - g: green component.
///   - b: blue component.
/// - Returns: color with given values.
internal func SKColorWithRGB(_ r: Int, g: Int, b: Int) -> SKColor {
    return SKColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
}

/// Initialize a color with RGBA Integer values (0-255).
///
/// - Parameters:
///   - r: red component.
///   - g: green component.
///   - b: blue component.
///   - a: alpha component.
/// - Returns: color with given values.
internal func SKColorWithRGBA(_ r: Int, g: Int, b: Int, a: Int) -> SKColor {
    return SKColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(a)/255.0)
}


// MARK: - Foundation


// MARK: - String Extensions

extension String {

    /// Returns a titlecased string.
    ///
    /// - Returns: title cased string copy.
    func titleCased() -> String {
        if self.count <= 1 {
            return self.uppercased()
        }

        let regex = try! NSRegularExpression(pattern: "(?=\\S)[A-Z]", options: [])
        let range = NSMakeRange(1, self.count - 1)
        var titlecased = regex.stringByReplacingMatches(in: self, range: range, withTemplate: " $0")

        for i in titlecased.indices {
            if i == titlecased.startIndex || titlecased[titlecased.index(before: i)] == " " {
                titlecased.replaceSubrange(i...i, with: String(titlecased[i]).uppercased())
            }
        }
        return titlecased
    }


    /// Simple function to split a string with the given pattern.
    ///
    /// - Parameter pattern: pattern to split string with.
    func split(_ pattern: String) -> [String] {
        return self.components(separatedBy: pattern)
    }

    /// Returns a string left-padded to the given length.
    ///
    /// - Parameters:
    ///   - toLength: resulting string size.
    ///   - withPad: padded string
    /// - Returns: padded string.
    func padLeft(toLength: Int, withPad: String?) -> String {
        let paddingString = withPad ?? " "
        if (self.count >= toLength) {
            return String(self.prefix(toLength))
        }

        let remainingLength: Int = toLength - self.count
        var padString = ""
        for _ in 0 ..< remainingLength {
            padString += paddingString
        }
        return [padString, self].joined(separator: "")
    }

    /// Returns a string right-padded to the given length.
    ///
    /// - Parameters:
    ///   - toLength: resulting string size.
    ///   - withPad: padded string.
    /// - Returns: padded string.
    func padRight(toLength: Int, withPad: String?) -> String {
        let paddingString = withPad ?? " "
        if self.count >= toLength {
            return String(self.suffix(toLength))
        }

        let remainingLength: Int = toLength - self.count
        var padString = ""
        for _ in 0 ..< remainingLength {
            padString += paddingString
        }
        return [self, padString].joined(separator: "")
    }

    /// Returns a string right-padded to the given length.
    ///
    /// - Parameters:
    ///   - toLength: resulting string size.
    ///   - withPad: padded string.
    func padEven(toLength: Int, withPad: String?) -> String {
        let paddingString = withPad ?? " "
        if self.count >= toLength {
            let remainder = self.count - toLength
            let leftpad = remainder / 2
            let rightpad = remainder - leftpad

            let startIndex = self.index(self.startIndex, offsetBy: leftpad)
            let endIndex = self.index(self.startIndex, offsetBy: (self.count - 1) - rightpad)
            return String(self[startIndex...endIndex])
        }

        let remainder = toLength - self.count
        let leftpad = remainder / 2
        let rightpad = remainder - leftpad
        return String(repeating: paddingString, count: leftpad) + self + String(repeating: paddingString, count: rightpad)
    }

    /// Substitute a pattern in the string.
    ///
    /// - Parameters:
    ///   - pattern: pattern to replace.
    ///   - replaceWith: replacement string.
    /// - Returns: resulting string.
    func substitute(_ pattern: String, replaceWith: String) -> String {
        return self.replacingOccurrences(of: pattern, with: replaceWith)
    }

    /// Initialize with array of bytes.
    ///
    /// - Parameter bytes: byte array.
    public init(_ bytes: [UInt8]) {
        self.init()
        for byte in bytes {
            self.append(String(UnicodeScalar(byte)))
        }
    }

    /// Clean up whitespace & carriage returns.
    ///
    /// - Returns: scrubbed string.
    func scrub() -> String {
        var scrubbed = self.replacingOccurrences(of: "\n", with: "")
        scrubbed = scrubbed.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return scrubbed.replacingOccurrences(of: " ", with: "")
    }

    /// Captialize the first letter.
    var uppercaseFirst: String {
        let first = self.prefix(1)
        return first.uppercased() + self.dropFirst()
    }

    func nsRange(fromRange range: Range<Index>) -> NSRange {
        let from = range.lowerBound
        let to = range.upperBound
        let location = distance(from: startIndex, to: from)
        let length = distance(from: from, to: to)
        return NSRange(location: location, length: length)
    }

    // MARK: URL Helpers

    /// Returns a url for the string.
    var url: URL {
        return URL(fileURLWithPath: self.expanded).standardized
    }

    /// Expand the users home path.
    var expanded: String {
        return NSString(string: self).expandingTildeInPath
    }

    /// Returns the url parent directory.
    var parentURL: URL {
        var path = URL(fileURLWithPath: self.expanded)
        path.deleteLastPathComponent()
        return path
    }

    /*
    /// Returns true if the string represents a path that exists.
    var fileExists: Bool {
        return FileManager.default.fileExists(atPath: self.url.path)
    }

    /// Returns true if the string represents a path that exists and is a directory.
    var isDirectory: Bool {
        var isDir : ObjCBool = false
        return FileManager.default.fileExists(atPath: self, isDirectory: &isDir)
    }
     */
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

    /// Indicates a path string.
    var upOneDirectory: Bool {
        return hasPrefix("../")
    }
}


extension String {

    /// Returns true if the string represents a valid hexadecimal color.
    public var isValidHexColor: Bool {
        let pattern = "^#?([0-9A-F]{3}){1,2}$|^#?([0-9A-F]{4}){1,2}$"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let numberOfMatches = regex.numberOfMatches(in: self, options: [], range: NSMakeRange(0, self.count))

            if (numberOfMatches != 1) {
                return false
            }

            return true

        } catch {
            return false
        }
    }

    /// Returns a SpriteKit color for this string. Returns `SKColor.clear` if the string cannot be parsed.
    ///
    /// - Returns: hex color, or clear if the string is invalid.
    public func toHexColor() -> SKColor {
        return (self.isValidHexColor == true) ? SKColor(hexString: self) : SKColor.clear
    }
}



// MARK: - Dictionary Extensions

extension Dictionary {

    /// Returns true if the given dictionary key has a value.
    ///
    /// - Parameter key: dictionary key.
    func has(key: Key) -> Bool {
        return self[key] != nil
    }

    /// Returns a value for the given key. Optionally add a default value if no value is present.
    ///
    /// - Parameters:
    ///   - key: dictionary key.
    ///   - defaultValue: default value.
    mutating func get(key: Key, _ defaultValue: Value? = nil) -> Value? {
        guard let value = self[key] else {
            self[key] = defaultValue
            return defaultValue
        }
        return value
    }

    /// Pop a value from the dictionary.
    ///
    /// - Parameter key: dictionary key.
    mutating func pop(key: Key) -> Value? {
        return remove(key: key)
    }

    /// Remove a value from the dictionary.
    ///
    /// - Parameter key: dictionary key.
    mutating func remove(key: Key) -> Value? {
        if let value = self.get(key: key) {
            removeValue(forKey: key)
            return value
        }
        return nil
    }

    /// Return a value from a dictionary, with optional default closure.
    ///
    /// - Parameters:
    ///   - key: key to search for.
    ///   - defaultValue: default value if nothing is returned.
    /// - Returns: value type.
    func value<T>(forKey key: Key, defaultValue: @autoclosure () -> T) -> T {
        guard let value = self[key] as? T else {
            return defaultValue()
        }
        return value
    }
}




// MARK: - URL Extensions

extension URL {

    /// Expand the path string before initialization.
    ///
    /// - Parameter expandedFilePath: string representing a file path.
    public init(fileURLWithExpandedPath expandedPath: String) {
        self.init(fileURLWithPath: NSString(string: expandedPath).expandingTildeInPath)
    }

    /// Returns the path file name without file extension.
    var basename: String {
        return self.deletingPathExtension().lastPathComponent
    }

    /// Returns the file name without the parent directory.
    var filename: String {
        return FileManager.default.displayName(atPath: path)
    }

    /// Returns true if the URL represents a path that exists and is a directory.
    var isDirectory: Bool {
        return hasDirectoryPath
    }

    /// Returns a hash key for the path.
    var pathHash: Int {
        var hasher = Hasher()
        hasher.combine(self.path)
        return hasher.finalize()
    }

    var relativePathString: String {
        return #"~/\#(relativePath)"#
    }

    var isTilemap: Bool {
        return pathExtension.lowercased() == "tmx"
    }

    var isTileset: Bool {
        return pathExtension.lowercased() == "tsx"
    }

    var isTemplate: Bool {
        return pathExtension.lowercased() == "tx"
    }
}


extension URL {

    /// Returns the parent path of the file.
    var parent: String? {
        let mutableURL = self
        let result = (mutableURL.deletingLastPathComponent().relativePath == ".") ? nil : mutableURL.deletingLastPathComponent().relativePath
        return result
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


// MARK: - FloatingPoint


extension FloatingPoint {

    /// Returns a value that is precise to a given number of digits.
    ///
    /// - Parameter value: floating point precision.
    /// - Returns: the current value with the given accuracy.
    public func precised(_ value: Int = 1) -> Self {
        let offset = Self(Int(pow(10.0, Double(value))))
        return (self * offset).rounded() / offset
    }

    /// Returns true if the values are equal within a range of accuracy.
    ///
    /// - Parameters:
    ///   - lhs: first value.
    ///   - rhs: second value.
    ///   - accuracy: floating point accuracy.
    /// - Returns: values are equal within the given accuracy.
    static func equal(_ lhs: Self, _ rhs: Self, accuracy: Int? = nil) -> Bool {
        guard let accuracy = accuracy else {
            return lhs == rhs
        }

        return lhs.precised(accuracy) == rhs.precised(accuracy)
    }
}




// MARK: - Event Notifications

extension Notification.Name {

    public struct Camera {
        public static let Updated                   = Notification.Name(rawValue: "org.sktiled.notification.name.camera.updated")

        // TODO: rename these as `ZoomIncreaseRequested` as these aren't coming from the camera itself.
        public static let ZoomIncreased             = Notification.Name(rawValue: "org.sktiled.notification.name.camera.zoomIncreased")
        public static let ZoomDecreased             = Notification.Name(rawValue: "org.sktiled.notification.name.camera.zoomDecreased")
    }

    public struct DataStorage {
        public static let ProxyVisibilityChanged    = Notification.Name(rawValue: "org.sktiled.notification.name.dataStorage.proxyVisibilityChanged")
        public static let IsolationModeChanged      = Notification.Name(rawValue: "org.sktiled.notification.name.dataStorage.isolationModeChanged")
    }

    public struct Globals {

        /// Called when Tiled globals are updated.
        public static let Updated                   = Notification.Name(rawValue: "org.sktiled.notification.name.globals.updated")
        public static let DefaultsRead              = Notification.Name(rawValue: "org.sktiled.notification.name.globals.defaultsRead")
        public static let SavedToUserDefaults       = Notification.Name(rawValue: "org.sktiled.notification.name.globals.savedToUserDefaults")
    }

    public struct Layer {
        public static let TileAdded                 = Notification.Name(rawValue: "org.sktiled.notification.name.layer.tileAdded")
        public static let TileRemoved               = Notification.Name(rawValue: "org.sktiled.notification.name.layer.tileRemoved")
        public static let AnimatedTileAdded         = Notification.Name(rawValue: "org.sktiled.notification.name.layer.animatedTileAdded")
        public static let ObjectAdded               = Notification.Name(rawValue: "org.sktiled.notification.name.layer.objectAdded")
        public static let ObjectRemoved             = Notification.Name(rawValue: "org.sktiled.notification.name.layer.objectRemoved")
    }

    public struct Map {
        public static let FinishedRendering         = Notification.Name(rawValue: "org.sktiled.notification.name.map.finishedRendering")
        public static let Updated                   = Notification.Name(rawValue: "org.sktiled.notification.name.map.updated")
        public static let RenderStatsUpdated        = Notification.Name(rawValue: "org.sktiled.notification.name.map.renderStatsUpdated")
        public static let UpdateModeChanged         = Notification.Name(rawValue: "org.sktiled.notification.name.map.updateModeChanged")
        public static let TileIsolationModeChanged  = Notification.Name(rawValue: "org.sktiled.notification.name.map.tileIsolationModeChanged")
        public static let FocusCoordinateChanged    = Notification.Name(rawValue: "org.sktiled.notification.name.map.focusCoordinateChanged")
    }

    public struct RenderStats {
        public static let StaticTilesUpdated        = Notification.Name(rawValue: "org.sktiled.notification.name.renderStats.staticTilesUpdated")
        public static let AnimatedTilesUpdated      = Notification.Name(rawValue: "org.sktiled.notification.name.renderStats.animatedTilesUpdated")
        public static let VisibilityChanged         = Notification.Name(rawValue: "org.sktiled.notification.name.renderStats.visibilityChanged")
    }

    public struct Tile {
        public static let TileIDChanged             = Notification.Name(rawValue: "org.sktiled.notification.name.tile.tileTileIdChanged")
        public static let TileDataChanged           = Notification.Name(rawValue: "org.sktiled.notification.name.tile.tileTileDataChanged")
        // Called when the tile render mode is updated.
        public static let RenderModeChanged         = Notification.Name(rawValue: "org.sktiled.notification.name.tile.renderModeChanged")
    }

    public struct TileData {
        public static let FrameAdded                = Notification.Name(rawValue: "org.sktiled.notification.name.tileData.frameAdded")
        public static let TextureChanged            = Notification.Name(rawValue: "org.sktiled.notification.name.tileData.textureChanged")
        public static let ActionAdded               = Notification.Name(rawValue: "org.sktiled.notification.name.tileData.actionAdded")
    }

    public struct Tileset {
        public static let DataAdded                 = Notification.Name(rawValue: "org.sktiled.notification.name.tileset.dataAdded")
        public static let DataRemoved               = Notification.Name(rawValue: "org.sktiled.notification.name.tileset.dataRemoved")
        public static let SpriteSheetUpdated        = Notification.Name(rawValue: "org.sktiled.notification.name.tileset.spritesheetUpdated")
    }
}



extension OptionSet where RawValue: FixedWidthInteger {

    /// Returns an array of all the options in an `OptionSet`.
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





// MARK: - Operators

public func + (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) + rhs
}

public func - (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) - rhs
}

public func * (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) * rhs
}

public func / (lhs: Int, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) / rhs
}



public func + (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs + CGFloat(rhs)
}

public func - (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs - CGFloat(rhs)
}

public func * (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs * CGFloat(rhs)
}

public func / (lhs: CGFloat, rhs: Int) -> CGFloat {
    return lhs / CGFloat(rhs)
}



public func + (lhs: Int32, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) + rhs
}

public func - (lhs: Int32, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) - rhs
}

public func * (lhs: Int32, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) * rhs
}

public func / (lhs: Int32, rhs: CGFloat) -> CGFloat {
    return CGFloat(lhs) / rhs
}



public func lerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
    return start + (t * (end - start))
}


public func ilerp(start: CGFloat, end: CGFloat, t: CGFloat) -> CGFloat {
    return (t - start) / (end - start)
}

/// Euclidean distance function.
///
/// Computes the square root of the sum of the squares of x and y, without undue overflow or underflow at intermediate stages of the computation.
///
/// - Parameters:
///   - lhs: first value.
///   - rhs: second value.
/// - Returns: square root of the sum of the values.
public func hypotf(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
    return CGFloat(hypotf(Float(lhs), Float(rhs)))
}

/// Arc tangent function of two values. Calculates the principal value of the arc tangent of y/x, using the signs of the two arguments to determine the quadrant of the result.
///
/// - Parameters:
///   - lhs: first value.
///   - rhs: second value.
/// - Returns: arc tangent.
public func atan2f(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
    return CGFloat(atan2f(Float(lhs), Float(rhs)))
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



/// Performs a linear interpolation between two CGPoint values.
///
/// - Parameter start: start point.
/// - Parameter end: end point.
/// - Parameter t: interpolation amount.
/// - Returns: interpolated point.
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


public func * (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx * rhs.dx, dy: lhs.dy * rhs.dy)
}


public func * (vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
}


public func / (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx / rhs.dx, dy: lhs.dy / rhs.dy)
}


public func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
    return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
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


// MARK: - SKColor


/// Returns a new color based on interpolated values of two source colors.
///
/// - Parameters:
///   - start: start color.
///   - end: end color.
///   - t: blend amount.
/// - Returns: interpolated color.
public func lerp(start: SKColor, end: SKColor, t: CGFloat) -> SKColor {
    let newRed   = (1.0 - t) * start.components.r   + t * end.components.r
    let newGreen = (1.0 - t) * start.components.g + t * end.components.g
    let newBlue  = (1.0 - t) * start.components.b  + t * end.components.b
    return SKColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1)
}


// MARK: - simd_int2

public func + (lhs: simd_int2, rhs: simd_int2) -> simd_int2 {
    return simd_int2(arrayLiteral: lhs.x + rhs.x, lhs.y + rhs.y)
}

public func - (lhs: simd_int2, rhs: simd_int2) -> simd_int2 {
    return simd_int2(arrayLiteral: lhs.x - rhs.x, lhs.y - rhs.y)
}

public func += (lhs: inout simd_int2, rhs: simd_int2) {
    lhs.x += rhs.x
    lhs.y += rhs.y
}

public func -= (lhs: inout simd_int2, rhs: simd_int2) {
    lhs.x -= rhs.x
    lhs.y -= rhs.y
}

public func * (lhs: simd_int2, rhs: simd_int2) -> simd_int2 {
    return simd_int2(arrayLiteral: lhs.x * rhs.x, lhs.y * rhs.y)
}

public func *= (lhs: inout simd_int2, rhs: simd_int2) {
    lhs.x *= rhs.x
    lhs.y *= rhs.y
}


public func / (lhs: simd_int2, rhs: simd_int2) -> simd_int2 {
    return simd_int2(arrayLiteral: lhs.x / rhs.x, lhs.y / rhs.y)
}



extension simd_int2 {

    /// Returns a coordinate at 0,0.
    static public var zero: simd_int2 {
        return simd_int2(0,0)
    }

    /// Returns the coordinate as a `CGVector` type.
    public var toCGVec: CGVector {
        return CGVector(dx: CGFloat(x), dy: CGFloat(y))
    }

    /// Initialize the vector with a `CGPoint`.
    ///
    /// - Parameter point: `CGPoint`
    public init(point: CGPoint) {
        self.init(x: Int32(point.x), y: Int32(point.y))
    }

    /// Returns the difference vector to another `simd_int2`.
    ///
    /// - Parameter v: vector to compare.
    /// - Returns: difference between the two vectors.
    public func delta(to v: simd_int2) -> CGVector {
        let dx = Float(x - v.x)
        let dy = Float(y - v.y)
        return CGVector(dx: Int(dx), dy: Int(dy))
    }

    /// Returns true if the coordinate vector is contiguous to another vector.
    ///
    /// - Parameter v: coordinate
    /// - Returns: coordinates are contiguous.
    public func isContiguousTo(v: simd_int2) -> Bool {
        let dx = Float(x - v.x)
        let dy = Float(y - v.y)
        return sqrt((dx * dx) + (dy * dy)) == 1
    }

    /// Convert the simd_int2 to CGPoint.
    public var cgPoint: CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    /// Returns true if the vector matches a `CGPoint`.
    public static func == (lhs: simd_int2, rhs: CGPoint) -> Bool {
        return lhs.x == Int32(rhs.x) && lhs.y == Int32(rhs.y)
    }

    /// Returns a shortened textual representation for debugging.
    public var shortDescription: String {
        return "[\(String(format: "%d", x)),\(String(format: "%d", y))]"
    }

    /// Returns a shortened textual representation for debugging.
    public var coordDescription: String {
        return " [x: \(String(format: "%d", x)), y: \(String(format: "%d", y))]"
    }
}



// MARK: - Helper Functions

public func floor(point: CGPoint) -> CGPoint {
    return CGPoint(x: floor(Double(point.x)), y: floor(Double(point.y)))
}


public func ceil(point: CGPoint) -> CGPoint {
    return CGPoint(x: ceil(Double(point.x)), y: ceil(Double(point.y)))
}

/// Normalize a value between min/max values.
///
/// - Parameters:
///   - value: value to normalize.
///   - minimum: minimum possible value.
///   - maximum: maximum possible value.
/// - Returns: normalized value.
public func normalize(_ value: CGFloat, _ minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
    return (value - minimum) / (maximum - minimum)
}

/// Function that calculates the distance between two points.
///
/// - Parameters:
///   - first: first point.
///   - second: second point.
/// - Returns: distance between the two points.
public func distanceBetween(first: CGPoint, second: CGPoint) -> CGFloat {
    return hypotf(second.x - first.x, second.y - first.y)
}


/// Calculates the angle between 2 points in radians.
///
/// - Parameters:
///   - first: first point.
///   - second: second point.
/// - Returns: angle in radians.
public func radiansBetween(first: CGPoint, second: CGPoint) -> CGFloat {
    let deltaX = second.x - first.x
    let deltaY = second.y - first.y
    return atan2f(deltaY, deltaX)
}

/// Expand shortened hex color strings.
///
///   ie: `333` -> `333333`, or `6573` -> `66557733`
///
/// - Parameter hexString: input hex string.
/// - Returns: valid hex string.
public func expandShortenedHexString(_ hexString: String) -> String {
    let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    switch hex.count {
        case 3, 4:
            let hexStringArray = Array(hex)
            return zip(hexStringArray, hexStringArray).reduce("") { (result, values) in
                return result + String(values.0) + String(values.1)
            }
        default:
            return hex
    }
}


// MARK: - Visualization Functions


/// Visualize a layer grid as a texture.
///
/// - Parameters:
///   - object: mappable object type instance.
///   - imageScale: image scale multiplier.
///   - lineScale: line scale multiplier.
///   - gridColor: grid line color.
/// - Returns: visual grid texture.
internal func drawLayerGrid(_ object: TiledMappableGeometryType,
                            imageScale: CGFloat = 8,
                            lineScale: CGFloat = 1,
                            gridColor: SKColor? = nil) -> CGImage? {


    let gridColor = gridColor ?? TiledGlobals.default.debug.gridColor


    // get the ui scale value for the device
    let uiScale: CGFloat = TiledGlobals.default.contentScale

    let size = object.mapSize
    let tileWidth = object.tileWidth * imageScale
    let tileHeight = object.tileHeight * imageScale

    let tileWidthHalf = tileWidth / 2
    let tileHeightHalf = tileHeight / 2

    // image size is the rendered size
    let sizeInPoints = (object.sizeInPoints * imageScale)
    let defaultLineWidth: CGFloat = (imageScale / uiScale) * lineScale

    guard sizeInPoints != CGSize.zero else {
        return nil
    }


    return imageOfSize(sizeInPoints, scale: uiScale) { context, bounds, scale in

        // reference to shape path
        var shapePath: CGPath?
        let innerColor = SKColor.white

        // line width should be at least 1 for larger tile sizes
        let lineWidth: CGFloat = defaultLineWidth

        context.setLineWidth(lineWidth)
        context.setShouldAntialias(true)  // layer.antialiased

        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {

                context.setStrokeColor(innerColor.cgColor)
                context.setFillColor(SKColor.clear.cgColor)

                let coordinate = simd_int2(x: Int32(col), y: Int32(row))
                let screenPosition = object.tileToScreenCoords(coord: coordinate)

                var xpos: CGFloat = screenPosition.x * imageScale
                var ypos: CGFloat = screenPosition.y * imageScale

                switch object.orientation {
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
                    let staggerX = object.staggerX

                    // mirrored in pointForCoordinate
                    xpos += tileWidthHalf

                    if object.orientation == .hexagonal {

                        ypos += tileHeightHalf

                        var hexPoints = Array(repeating: CGPoint.zero, count: 6)
                        var variableSize: CGFloat = 0
                        var r: CGFloat = 0
                        var h: CGFloat = 0

                        // flat - currently not working
                        if (staggerX == true) {
                            let sizeLengthX = (object.sideLengthX * imageScale)
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
                            let sizeLengthY = (object.sideLengthY * imageScale)
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

                    if object.orientation == .staggered {

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


/// Generate a visual navigation graph texture.
///
/// - Parameters:
///   - object: mappable object type instance.
///   - imageScale: image scale multiplier.
///   - lineScale: line scale multiplier.
/// - Returns: visual graph texture.
internal func drawLayerGraph(_ object: TiledMappableGeometryType,
                             imageScale: CGFloat = 8,
                             lineScale: CGFloat = 1) -> CGImage? {



    guard let graph = object.graph else {
        Logger.default.log("object does not contain a pathfinding graph.", level: .error)
        return nil
    }

    // get the ui scale value for the device
    let uiScale: CGFloat = TiledGlobals.default.contentScale

    let size = object.mapSize
    let tileWidth = object.tileWidth * imageScale
    let tileHeight = object.tileHeight * imageScale

    let tileWidthHalf = tileWidth / 2
    let tileHeightHalf = tileHeight / 2

    let sizeInPoints = (object.sizeInPoints * imageScale)
    let defaultLineWidth: CGFloat = (imageScale / uiScale) * lineScale


    return imageOfSize(sizeInPoints, scale: uiScale) { context, bounds, scale in

        // line width should be at least 1 for larger tile sizes
        let lineWidth: CGFloat = defaultLineWidth
        context.setLineWidth(lineWidth)
        context.setShouldAntialias(true)  // layer.antialiased

        for col in 0 ..< Int(size.width) {
            for row in (0 ..< Int(size.height)) {

                let strokeColor = SKColor.black
                var fillColor = SKColor.clear

                if let node = graph?.node(atGridPosition: simd_int2(arrayLiteral: Int32(col), Int32(row))) {

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

                    let coordinate = simd_int2(x: Int32(col), y: Int32(row))
                    let screenPosition = object.tileToScreenCoords(coord: coordinate)

                    var xpos: CGFloat = screenPosition.x * imageScale
                    var ypos: CGFloat = screenPosition.y * imageScale


                    // points for node shape
                    var points: [CGPoint] = []

                    switch object.orientation {
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
                        let staggerX = object.staggerX

                        xpos += tileWidthHalf

                        if object.orientation == .hexagonal {

                            ypos += tileHeightHalf

                            var hexPoints = Array(repeating: CGPoint.zero, count: 6)
                            var variableSize: CGFloat = 0
                            var r: CGFloat = 0
                            var h: CGFloat = 0

                            // flat - currently not working
                            if (staggerX == true) {
                                let sizeLengthX = (object.sideLengthX * imageScale)
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
                                let sizeLengthY = (object.sideLengthY * imageScale)
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

                        if object.orientation == .staggered {

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


/// Create a temporary directory.
///
/// - Parameter named: directory name.
/// - Returns: url of the created directory, if successful.
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


/// Write the given image to PNG file. Returns a data representation of the image.
///
/// - Parameters:
///   - image: image to export to file.
///   - url: url of exported image.
/// - Returns: image data.
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

// TODO: cleanup for master

/// Draw an node visualizing the node's anchor point.
///
/// - Parameter node: parent node.
/// - Parameter key: anchor name.
/// - Parameter withLabel: string label (optional).
/// - Parameter labelSize: label font size.
/// - Parameter labelOffsetX: label x-offset.
/// - Parameter labelOffsetY: label y-offset.
/// - Parameter radius: anchor radius.
/// - Parameter anchorColor: anchor color.
/// - Parameter zoomScale: scene camera zoom.
@discardableResult
internal func drawAnchor(_ node: SKNode,
                         withKey key: String = "ANCHOR",
                         withLabel: String? = nil,
                         labelSize: CGFloat = 10,
                         labelOffsetX: CGFloat = 0,
                         labelOffsetY: CGFloat = 0,
                         radius: CGFloat = 1,
                         anchorColor: SKColor = SKColor.red,
                         zoomScale: CGFloat = 0) -> AnchorNode {

    node.childNode(withName: key)?.removeFromParent()
    let anchor = AnchorNode(radius: radius, color: anchorColor, label: withLabel, offsetX: labelOffsetX, offsetY: labelOffsetY, zoom: zoomScale)
    anchor.labelSize = labelSize
    node.addChild(anchor)

    if let tileScene = node.scene as? SKTiledScene {
        tileScene.cameraNode?.addDelegate(anchor)
    }

    // let x = "⎚"
    anchor.position = CGPoint(x: 0, y: 0)
    anchor.zPosition = node.zPosition * 100
    return anchor
}


/// Draw an node visualizing the node's anchor point.
///
/// - Parameter node: parent node.
/// - Parameter radius: anchor radius.
/// - Parameter anchorColor: anchor color.
/// - Parameter zoomScale: scene camera zoom.
@discardableResult
internal func drawAnchor(_ node: SKNode,
                         radius: CGFloat = 1,
                         anchorColor: SKColor = SKColor.red,
                         zoomScale: CGFloat = 0) -> AnchorNode {

    return drawAnchor(node, withKey: "ANCHOR", withLabel: nil, labelSize: 10, labelOffsetX: 0, labelOffsetY: 0, radius: radius, anchorColor: anchorColor, zoomScale: zoomScale)
}

// MARK: - Polygon Drawing


/// Returns an array of points for the given dimensions.
///
/// - Parameters:
///   - width: rect width.
///   - height: rect height.
///   - origin: rectangle origin.
/// - Returns: array of points.
public func rectPointArray(_ width: CGFloat, height: CGFloat, origin: CGPoint = CGPoint.zero) -> [CGPoint] {
    let points: [CGPoint] = [
        origin,
        CGPoint(x: origin.x + width, y: origin.y),
        CGPoint(x: origin.x + width, y: origin.y - height),
        CGPoint(x: origin.x, y: origin.y - height)
    ]
    return points
}

/// Returns an array of points for the given dimensions.
///
/// - Parameters:
///   - size: rectangle size.
///   - origin: rectangle origin.
/// - Returns: array of points.
public func rectPointArray(_ size: CGSize, origin: CGPoint = CGPoint.zero) -> [CGPoint] {
    return rectPointArray(size.width, height: size.height, origin: origin)
}


/// Returns an array of points describing a polygonal shape.
///
/// - Parameters:
///   - sides: number of sides.
///   - radius: radius of circle.
///   - offset: rotation offset (45 to return a rectangle).
///   - origin: origin point.
/// - Returns: array of points.
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


/// Returns a `CGPath` from an array of points.
///
/// - Parameters:
///   - points: polygon points.
///   - closed: path should be closed.
/// - Returns: path from the given points.
public func polygonPath(_ points: [CGPoint], closed: Bool = true) -> CGPath {
    //assert(points.count > 2, "A polygon needs more than two points.")
    guard (points.count > 2) else {
        return CGMutablePath()
    }

    let path = CGMutablePath()
    var mpoints = points
    let first = mpoints.remove(at: 0)
    path.move(to: first)

    for p in mpoints {
        path.addLine(to: p)
    }
    if (closed == true) {
        path.closeSubpath()
    }
    return path
}


/// Draw a polygon shape based on an aribitrary number of sides.
///
/// - Parameters:
///   - sides: number of sides.
///   - radius: w/h radius.
///   - offset: rotation offset (45 to return a rectangle).
///   - origin: center point.
/// - Returns: polygon path.
public func polygonPath(_ sides: Int,
                        radius: CGSize,
                        offset: CGFloat = 0,
                        origin: CGPoint = CGPoint.zero) -> CGPath {

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


/// Creates a bezier path from an array of points.
///
/// - Parameters:
///   - points: polygon points.
///   - closed: path should be closed.
///   - alpha: alpha descriptionpath curvature.
/// - Returns: bezier path and control points.
public func bezierPath(_ points: [CGPoint],
                       closed: Bool = true,
                       alpha: CGFloat = 1) -> (path: CGPath, points: [CGPoint]) {

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


/// Takes an array of grid graph points and returns a path. Set threshold value to allow for gaps in the path.
///
/// - Parameters:
///   - points: path points.
///   - threshold: gap threshold size.
/// - Returns: path from the given points.
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


/// Given two points, create an arrowhead.
///
/// - Parameters:
///   - startPoint: first point.
///   - endPoint: last point.
///   - tailWidth: arrow tail width.
///   - headWidth: arrow head width.
///   - headLength: arrow head length.
/// - Returns: path from the given points.
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


/// Draws a point marker at a singular point.
///
/// - Parameters:
///   - size: marker size.
///   - scale: scale multiplier.
/// - Returns: path at the given point/size.
public func pointObjectPath(size: CGFloat = 32, scale: CGFloat = 1) -> CGPath {
    let path = CGMutablePath()
    let start: CGPoint = CGPoint(x: 0, y: 0)

    let startX: CGFloat = start.x
    let halfSize: CGFloat = size / 2.0
    let quarterSize: CGFloat = halfSize / 1.80
    let cpx1: CGFloat = -quarterSize
    let firstX: CGFloat = -halfSize
    let height: CGFloat = size + size / 2.0
    let secondY: CGFloat = height
    let cpy1: CGFloat = height - halfSize / 2.0
    let firstY: CGFloat = size
    let cpy2: CGFloat = size - quarterSize

    path.move(to: start)
    path.addCurve(to: CGPoint(x: firstX, y: firstY), control1: start, control2: CGPoint(x: firstX, y: cpy2))
    path.addCurve(to: CGPoint(x: startX, y: secondY), control1: CGPoint(x: firstX, y: cpy1), control2: CGPoint(x: cpx1, y: secondY))
    path.addCurve(to: CGPoint(x: halfSize, y: firstY), control1: CGPoint(x: quarterSize, y: secondY), control2: CGPoint(x: halfSize, y: cpy1))
    path.addCurve(to: start, control1: CGPoint(x: halfSize, y: cpy2), control2: start)
    path.closeSubpath()
    return path
}


/// Clamp a point to the given scale.
///
/// - Parameters:
///   - point: point to clamp.
///   - scale: device scale.
/// - Returns: clamped point.
internal func clampedPosition(point: CGPoint, scale: CGFloat) -> CGPoint {
    let clampedX = round(Int(point.x * scale) / scale)
    let clampedY = round(Int(point.y * scale) / scale)
    return CGPoint(x: clampedX, y: clampedY)
}


/// Clamp the position of a given node (and parent).
///
/// - Parameters:
///   - node: node to re-position.
///   - scale: device scale.
public func clampNodePosition(node: SKNode, scale: CGFloat) {
    node.position = clampedPosition(point: node.position, scale: scale)
    if let parentNode = node.parent {
        // check that the parent is not the scene
        if parentNode != node.scene {
            clampNodePosition(node: parentNode, scale: scale)
        }
    }
}


// MARK: - Deprecations

/// Dumps `SKTiled` framework globals to the console.
@available(*, deprecated, renamed: "SKTiledGlobals()")
public func getSKTiledGlobals() {
    TiledGlobals.default.dumpStatistics()
}


/// Clamp the position of a given node (and parent).
///
/// - Parameters:
///   - node: node to re-position.
///   - scale: device scale.
@available(*, deprecated, renamed: "clampNodePosition(node:scale:)")
public func clampPositionWithNode(node: SKNode, scale: CGFloat) {
    clampNodePosition(node: node, scale: scale)
}


extension CGSize {

    /// Returns a display string rounded to a given number of decimal places.
    ///
    /// - Parameter decimals: decimals to round to.
    /// - Returns: display string.
    @available(*, deprecated, renamed: "stringRoundedTo(_:)")
    public func roundTo(_ decimals: Int = 1) -> String {
        return stringRoundedTo(decimals)
    }

    /// Returns the width x height.
    @available(*, deprecated, renamed: "pointCount")
    public var count: Int {
        return Int(width) * Int(height)
    }
}


extension CGPoint {

    /// Returns a display string rounded to a given number of decimal places.
    ///
    /// - Parameter decimals: decimals to round to.
    /// - Returns: display string.
    @available(*, deprecated, renamed: "stringRoundedTo(_:)")
    public func roundTo(_ decimals: Int = 1) -> String {
        return stringRoundedTo(decimals)
    }
}



extension CGRect {

    /// Returns a display string rounded to a given number of decimal places.
    ///
    /// - Parameter decimals: decimals to round to.
    /// - Returns: display string.
    @available(*, deprecated, renamed: "stringRoundedTo(_:)")
    public func roundTo(_ decimals: Int = 1) -> String {
        return stringRoundedTo(decimals)
    }
}


extension SKColor {

    /// Returns a string description of the color RGBA components.
    @available(*, deprecated, renamed: "rgbaDescription")
    public var rgbDescription: String {
        let comps = components
        let r = Int(comps.r * 255)
        let g = Int(comps.g * 255)
        let b = Int(comps.b * 255)
        let a = Int(comps.a * 255)
        return "SKColor(r: \(r), g: \(g), b: \(b), a: \(a))"
    }
}



// MARK: - Compression

/// Compression level whose rawValue is based on the zlib's constants.
public struct CompressionLevel: RawRepresentable {

    /// Compression level in the range of `0` (no compression) to `9` (maximum compression).
    public let rawValue: Int32

    public static let noCompression = CompressionLevel(Z_NO_COMPRESSION)
    public static let bestSpeed = CompressionLevel(Z_BEST_SPEED)
    public static let bestCompression = CompressionLevel(Z_BEST_COMPRESSION)
    public static let defaultCompression = CompressionLevel(Z_DEFAULT_COMPRESSION)


    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }


    public init(_ rawValue: Int32) {
        self.rawValue = rawValue
    }
}


/// Errors on gzipping/gunzipping based on the zlib error codes.
public struct GzipError: Swift.Error {
    // cf. http://www.zlib.net/manual.html

    public enum Kind: Equatable {
        /// The stream structure was inconsistent.
        ///
        /// - underlying zlib error: `Z_STREAM_ERROR` (-2)
        case stream

        /// The input data was corrupted
        /// (input stream not conforming to the zlib format or incorrect check value).
        ///
        /// - underlying zlib error: `Z_DATA_ERROR` (-3)
        case data

        /// There was not enough memory.
        ///
        /// - underlying zlib error: `Z_MEM_ERROR` (-4)
        case memory

        /// No progress is possible or there was not enough room in the output buffer.
        ///
        /// - underlying zlib error: `Z_BUF_ERROR` (-5)
        case buffer

        /// The zlib library version is incompatible with the version assumed by the caller.
        ///
        /// - underlying zlib error: `Z_VERSION_ERROR` (-6)
        case version

        /// An unknown error occurred.
        ///
        /// - parameter code: return error by zlib
        case unknown(code: Int)
    }

    /// Error kind.
    public let kind: Kind

    /// Returned message by zlib.
    public let message: String


    internal init(code: Int32, msg: UnsafePointer<CChar>?) {

        self.message = {
            guard let msg = msg, let message = String(validatingUTF8: msg) else {
                return "Unknown gzip error"
            }
            return message
        }()

        self.kind = {
            switch code {
            case Z_STREAM_ERROR:
                    return .stream
            case Z_DATA_ERROR:
                    return .data
            case Z_MEM_ERROR:
                    return .memory
            case Z_BUF_ERROR:
                    return .buffer
            case Z_VERSION_ERROR:
                    return .version
            default:
                    return .unknown(code: Int(code))
            }
        }()
    }


    public var localizedDescription: String {

        return self.message
    }

}

/// Extension for Data objectsfor roundtripping data from arrays.
/// https://stackoverflow.com/questions/38023838/round-trip-swift-number-types-to-from-data
extension Data {

    // Initialize with a value.
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }

    // Export back as value.
    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        guard count >= MemoryLayout.size(ofValue: value) else { return nil }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )
        return value
    }

    // Initialize with an array.
    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }

    // Output data to an array.
    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}


extension Data {

    /// Whether the receiver is compressed in gzip format.
    public var isGzipped: Bool {
        return self.starts(with: [0x1f, 0x8b])  // check magic number
    }

    /// Whether the receiver is compressed in zlib format.
    public var isZlibCompressed: Bool {
        return self.starts(with: [0x78, 0x9C])
    }


    /// Create a new `Data` object by compressing the receiver using zlib.
    /// Throws an error if compression failed.
    ///
    /// - Parameter level: Compression level.
    /// - Returns: Gzip-compressed `Data` object.
    /// - Throws: `GzipError`
    public func gzipped(level: CompressionLevel = .defaultCompression) throws -> Data {

        guard !self.isEmpty else {
            return Data()
        }

        var stream = z_stream()
        var status: Int32

        status = deflateInit2_(&stream, level.rawValue, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(DataSize.stream))

        guard status == Z_OK else {
            // deflateInit2 returns:
            // Z_VERSION_ERROR  The zlib library version is incompatible with the version assumed by the caller.
            // Z_MEM_ERROR      There was not enough memory.
            // Z_STREAM_ERROR   A parameter is invalid.

            throw GzipError(code: status, msg: stream.msg)
        }

        var data = Data(capacity: DataSize.chunk)
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += DataSize.chunk
            }

            let inputCount = self.count
            let outputCount = data.count

            self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!).advanced(by: Int(stream.total_in))
                stream.avail_in = uint(inputCount) - uInt(stream.total_in)

                data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)

                    status = deflate(&stream, Z_FINISH)
                    stream.next_out = nil
                }

                stream.next_in = nil
            }

        } while stream.avail_out == 0

        guard deflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            throw GzipError(code: status, msg: stream.msg)
        }

        data.count = Int(stream.total_out)

        return data
    }


    /// Create a new `Data` object by decompressing the receiver using zlib.
    /// Throws an error if decompression failed.
    ///
    /// - Returns: Gzip-decompressed `Data` object.
    /// - Throws: `GzipError`
    public func gunzipped() throws -> Data {

        guard !self.isEmpty else {
            return Data()
        }

        var stream = z_stream()
        var status: Int32

        status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(DataSize.stream))

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

            let inputCount = self.count
            let outputCount = data.count

            self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!).advanced(by: Int(stream.total_in))
                stream.avail_in = uint(inputCount) - uInt(stream.total_in)

                data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)

                    status = inflate(&stream, Z_SYNC_FLUSH)

                    stream.next_out = nil
                }

                stream.next_in = nil
            }

        } while status == Z_OK

        guard inflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
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
}


private struct DataSize {

    static let chunk = 1 << 14
    static let stream = MemoryLayout<z_stream>.size

    private init() { }
}
