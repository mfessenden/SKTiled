//
//  DemoPreferences.swift
//  SKTiled Demo
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

import Foundation


/// Class to manage preferences loaded from a property list.
class DemoPreferences: Codable {

    var renderQuality: Double = 0
    var objectRenderQuality: Double = 0
    var textRenderQuality: Double = 0
    var lineWidth: Double = 1

    var showObjects: Bool = false
    var drawGrid: Bool = false
    var drawBounds: Bool = false
    var drawAnchor: Bool = false
    var enableEffects: Bool = false      // using this?
    var updateMode: UInt8 = 0

    var renderCallbacks: Bool = true
    var mouseEventDelta: TimeInterval = 0.02
    var tilemapNotifications: Bool = false
    var tilemapInfiniteOffsets: Bool = true
    var cameraCallbacks: Bool = true
    var cameraTrackContainedNodes: Bool = true

    var mouseFilters: UInt8 = 0
    var ignoreZoomConstraints: Bool = false
    var usePreviousCamera: Bool = false
    var demoFiles: [String] = []

    var allowUserMaps: Bool = true
    var allowDemoMaps: Bool = true
    var enableMouseEvents: Bool = false

    enum ConfigKeys: String, CodingKey {
        case renderQuality
        case objectRenderQuality
        case textRenderQuality
        case lineWidth
        case showObjects
        case drawGrid
        case drawBounds
        case drawAnchor
        case enableEffects
        case updateMode
        case renderCallbacks
        case mouseEventDelta
        case tilemapNotifications
        case tilemapInfiniteOffsets
        case cameraCallbacks
        case cameraTrackContainedNodes
        case mouseFilters
        case ignoreZoomConstraints
        case usePreviousCamera
        case demoFiles
        case allowUserMaps
        case allowDemoMaps
        case enableMouseEvents
    }
    
    /// Default initializer.
    init() {}

    /// Default initializer.
    required init?(coder aDecoder: NSCoder) {}

    /// Initialize from a decoder instance.
    ///
    /// - Parameter decoder: property list decoder.
    /// - Throws: An `Error` when decoding fails.
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: ConfigKeys.self)
        renderQuality = try values.decode(Double.self, forKey: .renderQuality)
        objectRenderQuality = try values.decode(Double.self, forKey: .objectRenderQuality)
        textRenderQuality = try values.decode(Double.self, forKey: .textRenderQuality)
        lineWidth = try values.decode(Double.self, forKey: .lineWidth)
        showObjects = try values.decode(Bool.self, forKey: .showObjects)
        drawGrid = try values.decode(Bool.self, forKey: .drawGrid)
        drawBounds = try values.decode(Bool.self, forKey: .drawBounds)
        drawAnchor = try values.decode(Bool.self, forKey: .drawAnchor)
        enableEffects = try values.decode(Bool.self, forKey: .enableEffects)
        updateMode = try values.decode(UInt8.self, forKey: .updateMode)
        renderCallbacks = try values.decode(Bool.self, forKey: .renderCallbacks)
        mouseEventDelta = try values.decode(Double.self, forKey: .mouseEventDelta)
        tilemapNotifications = try values.decode(Bool.self, forKey: .tilemapNotifications)
        tilemapInfiniteOffsets = try values.decode(Bool.self, forKey: .tilemapInfiniteOffsets)
        cameraCallbacks = try values.decode(Bool.self, forKey: .cameraCallbacks)
        cameraTrackContainedNodes = try values.decode(Bool.self, forKey: .cameraTrackContainedNodes)
        mouseFilters = try values.decode(UInt8.self, forKey: .mouseFilters)
        ignoreZoomConstraints = try values.decode(Bool.self, forKey: .ignoreZoomConstraints)
        usePreviousCamera = try values.decode(Bool.self, forKey: .usePreviousCamera)
        demoFiles = try values.decode(Array.self, forKey: .demoFiles)
        allowUserMaps = try values.decode(Bool.self, forKey: .allowUserMaps)
        allowDemoMaps = try values.decode(Bool.self, forKey: .allowDemoMaps)
        enableMouseEvents = try values.decode(Bool.self, forKey: .enableMouseEvents)
    }

    
    /// Encode the preference values.
    ///
    /// - Parameter encoder: encoder instance.
    /// - Throws: encoding error.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ConfigKeys.self)
        try container.encode(renderQuality, forKey: .renderQuality)
        try container.encode(objectRenderQuality, forKey: .objectRenderQuality)
        try container.encode(textRenderQuality, forKey: .textRenderQuality)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(showObjects, forKey: .showObjects)
        try container.encode(drawGrid, forKey: .drawGrid)
        try container.encode(drawBounds, forKey: .drawBounds)
        try container.encode(drawAnchor, forKey: .drawAnchor)
        try container.encode(enableEffects, forKey: .enableEffects)
        try container.encode(updateMode, forKey: .updateMode)
        try container.encode(renderCallbacks, forKey: .renderCallbacks)
        try container.encode(mouseEventDelta, forKey: .mouseEventDelta)
        try container.encode(tilemapNotifications, forKey: .tilemapNotifications)
        try container.encode(tilemapInfiniteOffsets, forKey: .tilemapInfiniteOffsets)
        try container.encode(cameraCallbacks, forKey: .cameraCallbacks)
        try container.encode(cameraTrackContainedNodes, forKey: .cameraTrackContainedNodes)
        try container.encode(mouseFilters, forKey: .mouseFilters)
        try container.encode(ignoreZoomConstraints, forKey: .ignoreZoomConstraints)
        try container.encode(usePreviousCamera, forKey: .usePreviousCamera)
        try container.encode(demoFiles, forKey: .demoFiles)
        try container.encode(allowUserMaps, forKey: .allowUserMaps)
        try container.encode(allowDemoMaps, forKey: .allowDemoMaps)
        try container.encode(enableMouseEvents, forKey: .enableMouseEvents)
    }
}



extension DemoPreferences: TiledCustomReflectableType {

    public func dumpStatistics() {
        var headerString = " Demo Preferences ".padEven(toLength: 40, withPad: "-")

        var animModeString = "**invalid**"
        if let demoAnimationMode = TileUpdateMode.init(rawValue: updateMode) {
            animModeString = demoAnimationMode.name
        }

        let mousefilters = TiledGlobals.DebugDisplayOptions.MouseFilters(rawValue: mouseFilters)
        let filterstrings = mousefilters.strings
        let literals = filterstrings.map { #""\#($0)""# }
        let filterString = literals.joined(separator: ",")


        headerString = "\n\(headerString)\n"
        headerString += " - render quality:              \(renderQuality)\n"
        headerString += " - object quality:              \(objectRenderQuality)\n"
        headerString += " - text quality:                \(textRenderQuality)\n"
        headerString += " - show objects:                \(showObjects)\n"
        headerString += " - line width:                  \(lineWidth)\n"
        headerString += " - draw grid:                   \(drawGrid)\n"
        headerString += " - draw anchor:                 \(drawAnchor)\n"
        headerString += " - effects rendering:           \(enableEffects)\n"
        headerString += " - update mode:                 \(updateMode)\n"
        headerString += " - animation mode:              \(animModeString)\n"
        headerString += " - allow user maps:             \(allowUserMaps)\n"
        
        headerString += " - render callbacks:            \(renderCallbacks)\n"
        headerString += " - mouse event frequency:       \(mouseEventDelta.stringRoundedTo(4))\n"
        headerString += " - tilemap notificatins:        \(tilemapNotifications)\n"
        headerString += " - infinite offsets:            \(tilemapInfiniteOffsets)\n"
        headerString += " - camera callbacks:            \(cameraCallbacks)\n"
        headerString += " - visible nodes callbacks:     \(cameraTrackContainedNodes)\n"
        headerString += " - ignore camera contstraints:  \(ignoreZoomConstraints)\n"
        headerString += " - use previous camera:         \(usePreviousCamera)\n"
        #if os(macOS)
        headerString += " - allow demo assets:           \(allowDemoMaps)\n"
        headerString += " - allow user assets:           \(allowUserMaps)\n"
        headerString += " - enable mouse events:         \(enableMouseEvents)\n"
        headerString += " - mouse filters:               \(filterString)\n"
        #endif
        print("\(headerString)\n\n")
    }
}
