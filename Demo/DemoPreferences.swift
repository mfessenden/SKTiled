//
//  DemoPreferences.swift
//  SKTiled Demo
//
//  Created by Michael Fessenden.
//
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
    var maxRenderQuality: Double = 0
    
    var showObjects: Bool = false
    var drawGrid: Bool = false
    var drawAnchor: Bool = false
    var enableEffects: Bool = false
    var updateMode: Int = 0
    var allowUserMaps: Bool = true
    var loggingLevel: Int = 0
    var renderCallbacks: Bool = true
    var cameraCallbacks: Bool = true
    var mouseFilters: Int = 0
    var ignoreZoomConstraints: Bool = false
    var usePreviousCamera: Bool = false
    var demoFiles: [String] = []
    
    enum ConfigKeys: String, CodingKey {
        case renderQuality
        case objectRenderQuality
        case textRenderQuality
        case maxRenderQuality
        case showObjects
        case drawGrid
        case drawAnchor
        case enableEffects
        case updateMode
        case allowUserMaps
        case loggingLevel
        case renderCallbacks
        case cameraCallbacks
        case mouseFilters
        case ignoreZoomConstraints
        case usePreviousCamera
        case demoFiles
    }
    
    required init?(coder aDecoder: NSCoder) {}
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: ConfigKeys.self)
        renderQuality = try values.decode(Double.self, forKey: .renderQuality)
        objectRenderQuality = try values.decode(Double.self, forKey: .objectRenderQuality)
        textRenderQuality = try values.decode(Double.self, forKey: .textRenderQuality)
        maxRenderQuality = try values.decode(Double.self, forKey: .maxRenderQuality)
        showObjects = try values.decode(Bool.self, forKey: .showObjects)
        drawGrid = try values.decode(Bool.self, forKey: .drawGrid)
        drawAnchor = try values.decode(Bool.self, forKey: .drawAnchor)
        enableEffects = try values.decode(Bool.self, forKey: .enableEffects)
        updateMode = try values.decode(Int.self, forKey: .updateMode)
        allowUserMaps = try values.decode(Bool.self, forKey: .allowUserMaps)
        loggingLevel = try values.decode(Int.self, forKey: .loggingLevel)
        renderCallbacks = try values.decode(Bool.self, forKey: .renderCallbacks)
        cameraCallbacks = try values.decode(Bool.self, forKey: .cameraCallbacks)
        mouseFilters = try values.decode(Int.self, forKey: .mouseFilters)
        ignoreZoomConstraints = try values.decode(Bool.self, forKey: .ignoreZoomConstraints)
        usePreviousCamera = try values.decode(Bool.self, forKey: .usePreviousCamera)
        demoFiles = try values.decode(Array.self, forKey: .demoFiles)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ConfigKeys.self)
        try container.encode(renderQuality, forKey: .renderQuality)
        try container.encode(objectRenderQuality, forKey: .objectRenderQuality)
        try container.encode(textRenderQuality, forKey: .textRenderQuality)
        try container.encode(maxRenderQuality, forKey: .maxRenderQuality)
        try container.encode(showObjects, forKey: .showObjects)
        try container.encode(drawGrid, forKey: .drawGrid)
        try container.encode(drawAnchor, forKey: .drawAnchor)
        try container.encode(enableEffects, forKey: .enableEffects)
        try container.encode(updateMode, forKey: .updateMode)
        try container.encode(allowUserMaps, forKey: .allowUserMaps)
        try container.encode(loggingLevel, forKey: .loggingLevel)
        try container.encode(renderCallbacks, forKey: .renderCallbacks)
        try container.encode(cameraCallbacks, forKey: .cameraCallbacks)
        try container.encode(mouseFilters, forKey: .mouseFilters)
        try container.encode(ignoreZoomConstraints, forKey: .ignoreZoomConstraints)
        try container.encode(usePreviousCamera, forKey: .usePreviousCamera)
        try container.encode(demoFiles, forKey: .demoFiles)
    }
}



extension DemoPreferences: CustomDebugReflectable {
    
    func dumpStatistics() {
        let spacing = "     "
        var headerString = "\(spacing)Demo Preferences\(spacing)"
        let headerUnderline = String(repeating: "-", count: headerString.count )
        
        var animModeString = "**invalid**"
        if let demoAnimationMode = TileUpdateMode.init(rawValue: updateMode) {
            animModeString = demoAnimationMode.name
        }
        
        //var mouseFilterStrings = mouseFilters
        
        var loggingLevelString = "**invalid**"
        if let demoLoggingLevel = LoggingLevel.init(rawValue: loggingLevel) {
            loggingLevelString = demoLoggingLevel.description
        }
        
        headerString = "\n\(headerString)\n\(headerUnderline)\n"
        headerString += " - render quality:              \(renderQuality)\n"
        headerString += " - object quality:              \(objectRenderQuality)\n"
        headerString += " - text quality:                \(textRenderQuality)\n"
        headerString += " - max render quality:          \(maxRenderQuality)\n"
        headerString += " - show objects:                \(showObjects)\n"
        headerString += " - draw grid:                   \(drawGrid)\n"
        headerString += " - draw anchor:                 \(drawAnchor)\n"
        headerString += " - effects rendering:           \(enableEffects)\n"
        headerString += " - update mode:                 \(updateMode)\n"
        headerString += " - animation mode:              \(animModeString)\n"
        headerString += " - allow user maps:             \(allowUserMaps)\n"
        headerString += " - logging level:               \(loggingLevelString)\n"
        headerString += " - render callbacks:            \(renderCallbacks)\n"
        headerString += " - camera callbacks:            \(cameraCallbacks)\n"
        headerString += " - ignore camera contstraints:  \(ignoreZoomConstraints)\n"
        headerString += " - user previous camera:        \(usePreviousCamera)\n"
        headerString += " - mouse filters:\n"
        
        print("\(headerString)\n\n")
    }
}
