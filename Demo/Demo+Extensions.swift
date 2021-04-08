//
//  Demo+Extensions.swift
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

import SpriteKit
import GameController


// MARK: - Globals


/// Saving & Loading.
extension TiledGlobals {

    /// Load prefs from the `Defaults.plist` file.
    internal func loadFromDemoDefaults() {
        if let defaultsPath = Bundle.main.path(forResource: "Defaults", ofType: "plist"),
           let xml = FileManager.default.contents(atPath: defaultsPath),
           let demoPreferences = try? PropertyListDecoder().decode(DemoPreferences.self, from: xml) {

            /// apply the demo defaults to `TiledGlobals`
            let globals = TiledGlobals.default

            globals.renderQuality.default = CGFloat(demoPreferences.renderQuality)
            globals.renderQuality.object = CGFloat(demoPreferences.objectRenderQuality)
            globals.renderQuality.text = CGFloat(demoPreferences.textRenderQuality)

            globals.enableRenderPerformanceCallbacks = demoPreferences.renderCallbacks
            globals.enableCameraCallbacks = demoPreferences.cameraCallbacks
            globals.enableCameraContainedNodesCallbacks = demoPreferences.cameraTrackContainedNodes
            globals.enableTilemapNotifications = demoPreferences.tilemapNotifications
            globals.enableTilemapInfiniteOffsets = demoPreferences.tilemapInfiniteOffsets

            globals.debugDisplayOptions.mouseFilters = TiledGlobals.DebugDisplayOptions.MouseFilters(rawValue: demoPreferences.mouseFilters)
            globals.debugDisplayOptions.lineWidth = CGFloat(demoPreferences.lineWidth)

            globals.allowDemoMaps = demoPreferences.allowDemoMaps
            globals.allowUserMaps = demoPreferences.allowUserMaps


            // Tile animation mode
            guard let _ = TileUpdateMode.init(rawValue: demoPreferences.updateMode) else {
                return
            }
            
            
            Logger.default.log("loading default preferences...", level: .debug, symbol: "TiledGlobals")

            // call back to the DemoController & Prefs UI
            NotificationCenter.default.post(
                name: Notification.Name.Globals.DefaultsRead,
                object: demoPreferences
            )

        } else {
            fatalError("cannot read preferences from bundle.")
        }
    }

    /// Load globals from `UserDefaults`.
    internal func loadFromUserDefaults() {

        let defaults = UserDefaults.shared

        if (defaults.value(forKey: "tiled-gbl-ddoptions") != nil) {
            self.debugDrawOptions = DebugDrawOptions(rawValue: defaults.integer(forKey: "tiled-gbl-ddoptions"))
        }

        if (defaults.value(forKey: "tiled-gbl-zdelta") != nil) {
            self.zDeltaForLayers = CGFloat(defaults.double(forKey: "tiled-gbl-zdelta"))
        }

        if (defaults.value(forKey: "tiled-gbl-logginglevel") != nil) {
            if let savedLoggingLevel = LoggingLevel(rawValue: UInt8(defaults.integer(forKey: "tiled-gbl-logginglevel"))) {
                self.loggingLevel = savedLoggingLevel
            }
        }

        // MARK: Render Quality

        if (defaults.value(forKey: "tiled-gbl-rndqual-default") != nil) {
            self.renderQuality.default = CGFloat(defaults.double(forKey: "tiled-gbl-rndqual-default"))
        }

        if (defaults.value(forKey: "tiled-gbl-rndqual-text") != nil) {
            self.renderQuality.text = CGFloat(defaults.double(forKey: "tiled-gbl-rndqual-text"))
        }

        if (defaults.value(forKey: "tiled-gbl-rndqual-object") != nil) {
            self.renderQuality.object = CGFloat(defaults.double(forKey: "tiled-gbl-rndqual-object"))
        }

        if (defaults.value(forKey: "tiled-gbl-rndqual-override") != nil) {
            self.renderQuality.override = CGFloat(defaults.double(forKey: "tiled-gbl-rndqual-override"))
        }

        if (defaults.value(forKey: "tiled-gbl-mouseevents") != nil) {
            self.enableMouseEvents = defaults.bool(forKey: "tiled-gbl-mouseevents")
        }

        // MARK: Camera

        if (defaults.value(forKey: "tiled-gbl-render-callbacks") != nil) {
            self.enableRenderPerformanceCallbacks = defaults.bool(forKey: "tiled-gbl-render-callbacks")
        }
        
        
        if (defaults.value(forKey: "tiled-gbl-mouseevent-delta") != nil) {
            self.mouseEventDelta = defaults.double(forKey: "tiled-gbl-mouseevent-delta")
        }
        
        if (defaults.value(forKey: "tiled-gbl-map-notifications") != nil) {
            self.enableTilemapNotifications = defaults.bool(forKey: "tiled-gbl-map-notifications")
        }
        
        if (defaults.value(forKey: "tiled-gbl-map-infiniteoffsets") != nil) {
            self.enableTilemapInfiniteOffsets = defaults.bool(forKey: "tiled-gbl-map-infiniteoffsets")
        }

        if (defaults.value(forKey: "tiled-gbl-camera-callbacks") != nil) {
            self.enableCameraCallbacks = defaults.bool(forKey: "tiled-gbl-camera-callbacks")
        }

        if (defaults.value(forKey: "tiled-gbl-camera-contained-callbacks") != nil) {
            self.enableCameraContainedNodesCallbacks = defaults.bool(forKey: "tiled-gbl-camera-contained-callbacks")
        }

        // MARK: Debug Display Options

        if (defaults.value(forKey: "tiled-gbl-dd-contained-hlduration") != nil) {
            self.debugDisplayOptions.highlightDuration = defaults.double(forKey: "tiled-gbl-dd-contained-hlduration")
        }

        if (defaults.value(forKey: "tiled-gbl-dd-gridopacity") != nil) {
            self.debugDisplayOptions.gridOpacity = CGFloat(defaults.double(forKey: "tiled-gbl-dd-gridopacity"))
        }

        if (defaults.value(forKey: "tiled-gbl-dd-gridcolor") != nil) {
            self.debugDisplayOptions.gridColor = SKColor(hexString: defaults.string(forKey: "tiled-gbl-dd-gridcolor")!)
        }

        if (defaults.value(forKey: "tiled-gbl-dd-framecolor") != nil) {
            self.debugDisplayOptions.frameColor = SKColor(hexString: defaults.string(forKey: "tiled-gbl-dd-framecolor")!)
        }

        if (defaults.value(forKey: "tiled-gbl-dd-linewidth") != nil) {
            self.debugDisplayOptions.lineWidth = CGFloat(defaults.double(forKey: "tiled-gbl-dd-linewidth"))
        }

        if (defaults.value(forKey: "tiled-gbl-dd-tilehlcolor") != nil) {
            self.debugDisplayOptions.tileHighlightColor = SKColor(hexString: defaults.string(forKey: "tiled-gbl-dd-tilehlcolor")!)
        }

        if (defaults.value(forKey: "tiled-gbl-dd-objopacity") != nil) {
            self.debugDisplayOptions.objectFillOpacity = CGFloat(defaults.double(forKey: "tiled-gbl-dd-objopacity"))
        }

        if (defaults.value(forKey: "tiled-gbl-dd-objhlcolor") != nil) {
            self.debugDisplayOptions.objectHighlightColor = SKColor(hexString: defaults.string(forKey: "tiled-gbl-dd-objhlcolor")!)
        }

        if (defaults.value(forKey: "tiled-gbl-dd-navcolor") != nil) {
            self.debugDisplayOptions.navigationColor = SKColor(hexString: defaults.string(forKey: "tiled-gbl-dd-navcolor")!)
        }

        if (defaults.value(forKey: "tiled-gbl-dd-camboundscolor") != nil) {
            self.debugDisplayOptions.cameraBoundsColor = SKColor(hexString: defaults.string(forKey: "tiled-gbl-dd-camboundscolor")!)
        }
        
        if (defaults.value(forKey: "tiled-gbl-dd-layerhlcolor") != nil) {
            self.debugDisplayOptions.layerHighlightColor = SKColor(hexString: defaults.string(forKey: "tiled-gbl-dd-layerhlcolor")!)
        }

        if (defaults.value(forKey: "tiled-gbl-dd-mousefilters") != nil) {
            let mouseFiltersRaw = defaults.double(forKey: "tiled-gbl-dd-mousefilters")
            self.debugDisplayOptions.mouseFilters = TiledGlobals.DebugDisplayOptions.MouseFilters(rawValue: UInt8(mouseFiltersRaw))
        }

        if (defaults.value(forKey: "tiled-gbl-dd-mousepointersize") != nil) {
            let mouseFiltersRaw = defaults.double(forKey: "tiled-gbl-dd-mousepointersize")
            self.debugDisplayOptions.mousePointerSize = CGFloat(defaults.double(forKey: "tiled-gbl-dd-mousepointersize"))
        }

        // MARK: Demo Content

        if (defaults.value(forKey: "tiled-gbl-demo-allowusermaps") != nil) {
            self.allowUserMaps = defaults.bool(forKey: "tiled-gbl-demo-allowusermaps")
        }

        if (defaults.value(forKey: "tiled-gbl-demo-allowdemomaps") != nil) {
            self.allowDemoMaps = defaults.bool(forKey: "tiled-gbl-demo-allowdemomaps")
        }


        #if SKTILED_DEMO
        NotificationCenter.default.post(
            name: Notification.Name.Globals.Updated,
            object: nil
        )
        #endif
    }

    /// Save global preferences to `UserDefaults`.
    internal func saveToUserDefaults() {
        
        // preferences group for SKTiled apps
        let defaults = UserDefaults.shared

        // globals
        defaults.set(self.debugDrawOptions.rawValue, forKey: "tiled-gbl-ddoptions")
        defaults.set(self.zDeltaForLayers, forKey: "tiled-gbl-zdelta")
        defaults.set(self.loggingLevel.rawValue, forKey: "tiled-gbl-logginglevel")
        defaults.set(self.enableMouseEvents, forKey: "tiled-gbl-mouseevents")

        // render quality
        defaults.set(self.renderQuality.default, forKey: "tiled-gbl-rndqual-default")
        defaults.set(self.renderQuality.text, forKey: "tiled-gbl-rndqual-text")
        defaults.set(self.renderQuality.object, forKey: "tiled-gbl-rndqual-object")
        defaults.set(self.renderQuality.override, forKey: "tiled-gbl-rndqual-override")

        // camera
        defaults.set(self.enableRenderPerformanceCallbacks, forKey: "tiled-gbl-render-callbacks")
        defaults.set(self.mouseEventDelta, forKey: "tiled-gbl-mouseevent-delta")
        
        
        defaults.set(self.enableTilemapNotifications, forKey: "tiled-gbl-map-notifications")
        defaults.set(self.enableTilemapInfiniteOffsets, forKey: "tiled-gbl-map-infiniteoffsets")
        defaults.set(self.enableCameraCallbacks, forKey: "tiled-gbl-camera-callbacks")
        defaults.set(self.enableCameraContainedNodesCallbacks, forKey: "tiled-gbl-camera-contained-callbacks")

        // debug display
        defaults.set(self.debugDisplayOptions.highlightDuration, forKey: "tiled-gbl-dd-contained-hlduration")
        defaults.set(self.debugDisplayOptions.gridOpacity, forKey: "tiled-gbl-dd-gridopacity")
        defaults.set(self.debugDisplayOptions.gridColor.hexString(), forKey: "tiled-gbl-dd-gridcolor")
        defaults.set(self.debugDisplayOptions.frameColor.hexString(), forKey: "tiled-gbl-dd-framecolor")
        defaults.set(self.debugDisplayOptions.lineWidth, forKey: "tiled-gbl-dd-linewidth")
        defaults.set(self.debugDisplayOptions.tileHighlightColor.hexString(), forKey: "tiled-gbl-dd-tilehlcolor")
        defaults.set(self.debugDisplayOptions.objectFillOpacity, forKey: "tiled-gbl-dd-objopacity")
        defaults.set(self.debugDisplayOptions.objectHighlightColor.hexString(), forKey: "tiled-gbl-dd-objhlcolor")
        defaults.set(self.debugDisplayOptions.navigationColor.hexString(), forKey: "tiled-gbl-dd-navcolor")
        defaults.set(self.debugDisplayOptions.cameraBoundsColor.hexString(), forKey: "tiled-gbl-dd-camboundscolor")
        defaults.set(self.debugDisplayOptions.layerHighlightColor.hexString(), forKey: "tiled-gbl-dd-layerhlcolor")

        // mouse filters
        defaults.set(self.debugDisplayOptions.mouseFilters.rawValue, forKey: "tiled-gbl-dd-mousefilters")
        defaults.set(self.debugDisplayOptions.mousePointerSize, forKey: "tiled-gbl-dd-mousepointersize")

        // demo content
        defaults.set(self.allowUserMaps, forKey: "tiled-gbl-demo-allowusermaps")
        defaults.set(self.allowDemoMaps, forKey: "tiled-gbl-demo-allowdemomaps")


        defaults.synchronize()


        #if SKTILED_DEMO
        NotificationCenter.default.post(
            name: Notification.Name.Globals.SavedToUserDefaults,
            object: nil
        )
        #endif

    }

    /// Reset `TiledGlobals` values in `UserDefaults`.
    internal func resetUserDefaults() {
        let defaults = UserDefaults.shared
        defaults.removePersistentDomain(forName: "org.sktiled")
        loadFromDemoDefaults()
    }
}



// MARK: - Notifications


extension Notification {

    /// Dump the notification contents to the console.
    internal func dump(_ fileId: String, function: String, symbol: String = "◦") {
        var output = "\(symbol) [\(fileId.components(separatedBy: CharacterSet(charactersIn: #"/."#))[1])]: notification received '\(self.loggingName)' -> '\(function)'"
        if let userObject = object {
            output += ", object: '\(String(describing: type(of: userObject)))'"
        }

        if let userDict = userInfo as? [String: Any] {
            let userDictCount = userDict.count - 1
            output += ", user info: ["
            for (idx, attr) in userDict.enumerated() {
                let comma = idx < userDictCount ? ", " : ""

                var valueString = "\(attr.value)"

                if let valstr = attr.value as? String {
                    valueString = "'\(valstr)'"
                }

                if let valurl = attr.value as? URL {
                    valueString = "\(valurl.relativePath)"
                }

                output += "'\(attr.key)' = \(valueString)\(comma)"
            }
            output += "]"
        }
        print(output)
    }

    /// Display name for logging events.
    internal var loggingName: String {
        var result = "Unknown"
        let components = name.rawValue.components(separatedBy: "\(TiledGlobals.default.domain).")
        if let nameValue = components.last {
            let nameComponents = nameValue.components(separatedBy: ".")
            result = nameComponents.reduce("", { (aggregate: String, value: String) -> String in
                let comma: String = (value == nameComponents.last) ? "" : "."

                return "\(aggregate)\(value.uppercaseFirst)\(comma)"
            })
        }
        return result
    }
}



extension Notification.Name {
    /*

     # file/scanning
     - loaded
     - scanning
     - finished scanning (send asset urls)
     - current map url is set/removed
        - updates currentIndex/menuing in AppDelegate

    */
    public struct DemoController {

        /// demo status
        public static let DemoStatusUpdated             = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.demoStatusUpdated")

        // events
        public static let WillBeginScanForAssets        = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.willBeginScanForAssets")
        public static let AssetsFinishedScanning        = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.assetsFinishedScanning")

        // map events
        public static let CurrentMapSet                 = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.currentMapSet")
        public static let CurrentMapRemoved             = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.currentMapRemoved")

        // debug
        public static let ResetDemoInterface            = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.resetDemoInterface")

        // asset search paths (macOS)
        public static let AssetSearchPathsAdded         = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.AssetSearchPathsAdded")
        public static let AssetSearchPathsRemoved       = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.assetSearchPathsRemoved")
        
        public static let LoadFileManually              = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.loadFileManually")
        
        
        public static let LoadNextScene                 = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.loadNextScene")
        
        public static let LoadPreviousScene             = Notification.Name(rawValue: "org.sktiled.notification.name.demoController.loadPreviousScene")
    }


    public struct Demo {

        /// Call this to tell the appdelegate to load the prefs UI.
        public static let LaunchPreferences             = Notification.Name(rawValue: "org.sktiled.notification.name.demo.launchPreferences")

        /// Demo scene notifications

        /// Indicates the scene is about to be cleared. Called when `DemoController` is about to load a new scene.
        public static let SceneWillUnload               = Notification.Name(rawValue: "org.sktiled.notification.name.demo.sceneWillUnload")
        /// Indicates a new SpriteKit scene has been loaded.
        public static let SceneLoaded                   = Notification.Name(rawValue: "org.sktiled.notification.name.demo.sceneLoaded")
        public static let UpdateDebugging               = Notification.Name(rawValue: "org.sktiled.notification.name.demo.updateDebugging")
        public static let ScenePauseStatusChanged       = Notification.Name(rawValue: "org.sktiled.notification.name.demo.scenePauseStatusChanged")

        // demo controller
        public static let FlushScene                    = Notification.Name(rawValue: "org.sktiled.notification.name.demo.flushScene")

        // macOS

        public static let TileUnderCursor               = Notification.Name(rawValue: "org.sktiled.notification.name.demo.tileUnderCursor")
        public static let TileClicked                   = Notification.Name(rawValue: "org.sktiled.notification.name.demo.tileClicked")
        public static let ObjectUnderCursor             = Notification.Name(rawValue: "org.sktiled.notification.name.demo.objectUnderCursor")
        public static let ObjectClicked                 = Notification.Name(rawValue: "org.sktiled.notification.name.demo.objectClicked")


        public static let NodesRightClicked             = Notification.Name(rawValue: "org.sktiled.notification.name.demo.nodesRightClicked")        // nodes right-clicked in demo app
        public static let NodeAttributesChanged         = Notification.Name(rawValue: "org.sktiled.notification.name.demo.nodeAttributesChanged")    // node changes via inspector
        public static let DumpSelectedNodes             = Notification.Name(rawValue: "org.sktiled.notification.name.demo.dumpSelectedNodes")
        public static let HighlightSelectedNodes        = Notification.Name(rawValue: "org.sktiled.notification.name.demo.highlightSelectedNodes")

        public static let ClearSelectedNodes            = Notification.Name(rawValue: "org.sktiled.notification.name.demo.clearSelectedNodes")  // calls back to GVC to clear selection (macOS)
        public static let NothingUnderCursor            = Notification.Name(rawValue: "org.sktiled.notification.name.demo.nothingUnderCursor")  // handles mouse movements that don't yield an object to highlight

        // iOS
        public static let TileTouched                   = Notification.Name(rawValue: "org.sktiled.notification.name.demo.tileTouched")
        public static let ObjectTouched                 = Notification.Name(rawValue: "org.sktiled.notification.name.demo.objectTouched")


        // node selected in right-click menu
        public static let NodeSelectionChanged           = Notification.Name(rawValue: "org.sktiled.notification.name.demo.nodeSelectionChanged")   // sent from demo delegate to indicate that the current node selection has changed
        public static let NodeSelectionCleared           = Notification.Name(rawValue: "org.sktiled.notification.name.demo.nodeSelectionCleared") // handles 'clear' key pressed (macOS)
        
        public static let NodeHighlightingCleared        = Notification.Name(rawValue: "org.sktiled.notification.name.demo.nodeHighlightingCleared")
        
        
        

        // selected node isolation
        public static let IsolateSelectedEnabled         = Notification.Name(rawValue: "org.sktiled.notification.name.demo.isolateSelectedEnabled")  // nothing is using this currently
        public static let IsolateSelectedDisabled        = Notification.Name(rawValue: "org.sktiled.notification.name.demo.isolateSelectedDisabled")
        
        
        // Inspector
        public static let NodesAboutToBeSelected         = Notification.Name(rawValue: "org.sktiled.notification.name.demo.nodesAboutToBeSelected")
        public static let MousePositionChanged           = Notification.Name(rawValue: "org.sktiled.notification.name.demo.mousePositionChanged")
        public static let RefreshInspectorInterface      = Notification.Name(rawValue: "org.sktiled.notification.name.demo.refreshInspectorInterface")
    }


    // TODO: clean these up
    public struct Debug {
        
        public static let UpdateDebugging               = Notification.Name(rawValue: "org.sktiled.notification.name.debug.updateDebugging")
        public static let DebuggingMessageSent          = Notification.Name(rawValue: "org.sktiled.notification.name.debug.debuggingMessageSent")  // sends a debugging command & duration to GVC (displays on bottom)
        public static let MapDebugDrawingChanged        = Notification.Name(rawValue: "org.sktiled.notification.name.debug.mapDebuggingChanged")   // sent when the `g` key is pressed (shows grid & bounds)
        public static let MapEffectsRenderingChanged    = Notification.Name(rawValue: "org.sktiled.notification.name.debug.mapEffectsRenderingChanged")
        public static let MapObjectVisibilityChanged    = Notification.Name(rawValue: "org.sktiled.notification.name.debug.mapObjectVisibilityChanged")
        
        // Infinite
        public static let RepositionLayers              = Notification.Name(rawValue: "org.sktiled.notification.name.debug.repositionLayers")
        
        // Inspector
        public static let DumpAttributeEditor           = Notification.Name(rawValue: "org.sktiled.notification.name.debug.dumpAttributeEditor")
        public static let DumpAttributeStorage          = Notification.Name(rawValue: "org.sktiled.notification.name.debug.dumpAttributeStorage")

    }
}


// MARK: - SKNode/NSTreeController

extension SKNode {

    @objc var isLeaf: Bool {
        return children.isEmpty
    }

    @objc public var childCount: Int {
        return children.count
    }
}


// MARK: - Inspector

/// Store & retrieve custom `SKTiled` attributes.
extension SKNode {

    /// Set a named `SKTiled` attribute.
    ///
    /// - Parameters:
    ///   - key: attribute name.
    ///   - value: attribute value.
    public func setAttr(key: String, value: Any) {
        initializeAttributes()
        guard let tiledAttrs = userData!["__sktiled_attributes"] as? NSMutableDictionary else {
            return
        }
        tiledAttrs[key] = value
    }

    /// Set an array of named `SKTiled` attributes.
    ///
    /// - Parameter values: key/value pairs.
    public func setAttrs(values: [String: Any]) {
        initializeAttributes()
        guard let tiledAttrs = userData!["__sktiled_attributes"] as? NSMutableDictionary else {
            return
        }
        for (_, property) in values.enumerated() {
            // FIXME: crash with object proxy here
            tiledAttrs[property.key] = property.value
        }
    }

    /// Retrurns a named attribute from the `userData` dictionary with an option to add a default value if none is found.
    ///
    /// - Parameters:
    ///   - key: attribute name.
    ///   - defaultValue: optional default vale.
    public func getAttr(key: String, defaultValue: Any? = nil) -> Any? {
        initializeAttributes()
        guard let tiledAttrs = userData!["__sktiled_attributes"] as? NSMutableDictionary else {
            return nil
        }

        guard let currentValue = tiledAttrs[key] else {
            if (defaultValue != nil) {
                tiledAttrs[key] = defaultValue
            }
            return defaultValue
        }
        return currentValue
    }

    /// Returns all of the values from the `SKTiled` attributes.
    ///
    /// - Returns: dictionary of Tiled attributes.
    public func getAttrs() -> [String: Any] {
        initializeAttributes()
        guard let tiledAttrs = userData!["__sktiled_attributes"] as? NSMutableDictionary else {
            return [:]
        }

        return tiledAttrs as! [String: Any]
    }

    /// Initialize a new dictionary of default values.
    private func initializeAttributes() {
        if (userData == nil) {
            let tiledData = NSMutableDictionary()
            let nodeAttributes = NSMutableDictionary()
            
            
            // FIXME: crash here
            
            nodeAttributes["sk-node-hidden"] = isHidden
            nodeAttributes["sk-node-paused"] = isPaused
            nodeAttributes["sk-node-posx"] = position.x
            nodeAttributes["sk-node-posy"] = position.y
            nodeAttributes["sk-node-scalex"] = xScale
            nodeAttributes["sk-node-scaley"] = yScale
            nodeAttributes["sk-node-posz"] = zPosition
            nodeAttributes["sk-node-speed"] = speed
            nodeAttributes["sk-node-alpha"] = alpha
            nodeAttributes["sk-node-rotz"] = zRotation.degrees()

            if let sprite = self as? SKSpriteNode {
                if let spriteTexture = sprite.texture {
                    let textureSize = spriteTexture.size()
                    nodeAttributes["sk-sprite-texture"] = spriteTexture
                    nodeAttributes["sk-sprite-sizew"] = textureSize.width
                    nodeAttributes["sk-sprite-sizeh"] = textureSize.height
                }
            }


            tiledData["__sktiled_attributes"] = nodeAttributes
            userData = tiledData
        }
    }

    /// Update the node's basic SpriteKit attributes.
    func updateAttributes() {
        initializeAttributes()
        guard let tiledAttrs = userData!["__sktiled_attributes"] as? NSMutableDictionary else {
            fatalError("could not create node attributes.")
        }

        let tiledData = NSMutableDictionary()
        let nodeAttributes = NSMutableDictionary()

        for (key, val) in tiledAttrs {
            nodeAttributes[key] = val
        }
        
        if let nodeName = name {
            nodeAttributes["sk-node-name"] = nodeName
        }

        nodeAttributes["sk-node-hidden"] = isHidden
        nodeAttributes["sk-node-paused"] = isPaused
        nodeAttributes["sk-node-posx"] = position.x
        nodeAttributes["sk-node-posy"] = position.y
        nodeAttributes["sk-node-scalex"] = xScale
        nodeAttributes["sk-node-scaley"] = yScale
        nodeAttributes["sk-node-posz"] = zPosition
        nodeAttributes["sk-node-speed"] = speed
        nodeAttributes["sk-node-alpha"] = alpha
        nodeAttributes["sk-node-rotz"] = zRotation.degrees()

        if let sprite = self as? SKSpriteNode {
            if let spriteTexture = sprite.texture {
                let textureSize = spriteTexture.size()
                nodeAttributes["sk-sprite-texture"] = spriteTexture
                nodeAttributes["sk-sprite-sizew"] = textureSize.width
                nodeAttributes["sk-sprite-sizeh"] = textureSize.height
            }
        }

        tiledData["__sktiled_attributes"] = nodeAttributes
        userData = tiledData
    }

    /// Remove custom `SKTiled` attributes.
    private func removeAttributes() {
        guard let userData = userData else {
            return
        }

        userData.removeObject(forKey: "__sktiled_attributes")
    }
    
    /// Returns the current attributes dictionary as Mirror attributes.
    ///
    /// - Returns: attributes represented as a mirror.
    func attrsMirror() -> [(label: String?, value: Any)] {
        var attributes: [(label: String?, value: Any)] = []
        for attr in getAttrs() {
            attributes.append((attr.key, attr.value))
        }
        return attributes
    }
}



extension SKNode {

    /// Dumps the children of this node to the console.
    public func dumpNode() {
        for child in allDescendants(byType: SKNode.self) {
            print(" - child: \(child.description)")
        }
    }

    /// Returns an array of all child nodes of the given node.
    ///
    ///  https://stackoverflow.com/questions/44274220/spritekit-find-all-descendants-of-sknode-of-certain-class
    ///
    /// - Parameter type: node type to filter.
    /// - Returns: array of hild nodes of the given type.
    public func allDescendants<Element: SKNode>(byType type: Element.Type) -> [Element] {
        let currentLevel:[Element] = children.compactMap { $0 as? Element }
        let moreLevels:[Element] = children.reduce([Element]()) { $0 + $1.allDescendants(byType: type) }
        return currentLevel + moreLevels
    }
}



// MARK: SKTUtils Actions

extension SKAction {


    /// Create an action from an effect.
    ///
    /// - Parameter effect: SpriteKit effect.
    /// - Returns: customm action.
    public class func actionWithEffect(_ effect: SKTEffect) -> SKAction {
        return SKAction.customAction(withDuration: effect.duration) { node, elapsedTime in
            var t = elapsedTime / CGFloat(effect.duration)

            if let timingFunction = effect.timingFunction {
                t = timingFunction(t)  // the magic happens here
            }

            effect.update(t)
        }
    }
    
    /// Creates a shake animation action.
    ///
    /// - Parameters:
    ///   - node: target node.
    ///   - amount: shake amount.
    ///   - oscillations: number of oscillations.
    ///   - duration: length of effect.
    /// - Returns: SpritKit shake action.
    public class func shakeNode(_ node: SKNode, amount: CGPoint, oscillations: Int, duration: TimeInterval) -> SKAction {
        let oldPosition = node.position
        let newPosition = oldPosition + amount
        let effect = SKTMoveEffect(node: node, duration: duration, startPosition: newPosition, endPosition: oldPosition)
        effect.timingFunction = SKTCreateShakeFunction(oscillations)
        return SKAction.actionWithEffect(effect)
    }
}

/// :nodoc:
public class SKTEffect {
    unowned var node: SKNode
    var duration: TimeInterval
    public var timingFunction: ((CGFloat) -> CGFloat)?

    public init(node: SKNode, duration: TimeInterval) {
        self.node = node
        self.duration = duration
        timingFunction = SKTTimingFunctionLinear
    }

    public func update(_ t: CGFloat) {
        // subclasses implement this
    }
}


public func SKTTimingFunctionLinear(_ t: CGFloat) -> CGFloat {
    return t
}

public func SKTCreateShakeFunction(_ oscillations: Int) -> (CGFloat) -> CGFloat {
    return {t in -pow(2.0, -10.0 * t) * sin(t * CGFloat.pi * CGFloat(oscillations) * 2.0) + 1.0}
}


public class SKTMoveEffect: SKTEffect {
    var startPosition: CGPoint
    var delta: CGPoint
    var previousPosition: CGPoint

    public init(node: SKNode, duration: TimeInterval, startPosition: CGPoint, endPosition: CGPoint) {
        previousPosition = node.position
        self.startPosition = startPosition
        delta = endPosition - startPosition
        super.init(node: node, duration: duration)
    }

    public override func update(_ t: CGFloat) {
        // This allows multiple SKTMoveEffect objects to modify the same node
        // at the same time.
        let newPosition = startPosition + delta*t
        let diff = newPosition - previousPosition
        previousPosition = newPosition
        node.position += diff
    }
}



// MARK: - Tilemap

extension SKTilemap {
    
    
    /// Reposition all of the child layers.
    public func repositionLayers() {
        for layer in tileLayers() {
            self.positionLayer(layer)
        }
    }
}


// MARK: - Cocoa/AppKit


extension UserDefaults {

    /// Returns defaults for this framework.
    static var shared: UserDefaults {
        return UserDefaults(suiteName: "org.sktiled")!
    }
}

#if os(macOS)


extension NSColor {

    /// Create an NSColor with different colors for light and dark mode.
    ///
    /// - Parameters:
    ///     - light: Color to use in light/unspecified mode.
    ///     - dark: Color to use in dark mode.
    @available(OSX 10.15, *)
    convenience init(light: NSColor, dark: NSColor) {
        self.init(name: nil, dynamicProvider: { $0.name == .darkAqua ? dark : light })
    }
}


extension NSView {

    /// Returns an array of subviews of the given parent view, recursively.
    ///
    /// - Parameter parentView: parent view.
    /// - Returns: array of subviews.
    class func getAllSubviews<T: NSView>(from parentView: NSView) -> [T] {
        return parentView.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(from: subView) as [T]
            if let view = subView as? T { result.append(view) }
            return result
        }
    }

    /// Returns an array of subviews of the given parent view, recursively.
    ///
    /// - Parameters:
    ///   - parentView: parent view.
    ///   - types: types of view to return.
    /// - Returns: array of subviews.
    class func getAllSubviews(from parentView: NSView, types: [NSView.Type]) -> [NSView] {
        return parentView.subviews.flatMap { subView -> [NSView] in
            var result = getAllSubviews(from: subView) as [NSView]
            for type in types {
                if subView.classForCoder == type {
                    result.append(subView)
                    return result
                }
            }
            return result
        }
    }

    /// Returns an array of subviews of this view, recursively.
    ///
    /// - Returns: array of subviews.
    func getAllSubviews<T: NSView>() -> [T] {
        return NSView.getAllSubviews(from: self) as [T]
    }

    /// Returns an array of subviews of the given type, of this view, recursively.
    ///
    /// - Parameter type: view type to return.
    /// - Returns: array of subviews.
    func get<T: NSView>(all type: T.Type) -> [T] {
        return NSView.getAllSubviews(from: self) as [T]
    }

    /// Returns an array of subviews of the given types, of this view, recursively.
    ///
    /// - Parameter types: types of view to return.
    /// - Returns: array of subviews.
    func get(all types: [NSView.Type]) -> [NSView] {
        return NSView.getAllSubviews(from: self, types: types)
    }
}



extension NSOutlineView {

    /// Selects a row at the given index.
    ///
    /// - Parameter index: row number.
    func selectRow(_ index: Int) {
        guard index != -1 else { return }
        selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
    }

    /// expand/Collapse
    public func expandOrCollapseItem(item: Any?, children: Bool = true) {
        let isItemExpanded = self.isItemExpanded(item)
        let animator = self.animator() as NSOutlineView;

        if isItemExpanded == true {
            animator.collapseItem(item, collapseChildren: children)
        } else {
            animator.expandItem(item, expandChildren: children)
        }
    }
}


extension NSOutlineView {


    func findParent<T>(of item: Any?, type:T.Type) -> T? {
        guard let item = item else {
            return nil
        }

        var currentItem: Any? = item
        while let parent = parent(forItem: currentItem)   {
            if let parent = parent as? T {
                return parent
            }
            else {
                currentItem = parent
            }
        }

        return nil
    }

    func expandParents(forItem item: Any?) {
        var item = item
        while item != nil {
            let parentItem = parent(forItem: item)
            if !isExpandable(parentItem) {
                break
            }
            if !isItemExpanded(parentItem) {
                expandItem(item)
            }
            item = parentItem
        }
    }
    
    /// Select the given item in the outline view.
    ///
    /// - Parameters:
    ///   - item: item in the current view.
    ///   - byExtendingSelection: true if the selection should be extended, false if the current selection should be changed.
    func selectItem(item: Any?, byExtendingSelection: Bool = true) {
        var index = row(forItem: item)
        if index < 0 {
            expandParents(forItem: item)
            index = row(forItem: item)
            if index < 0 {
                return
            }
        }
        selectRowIndexes(IndexSet(integer: index), byExtendingSelection: byExtendingSelection)
    }

    var visibleRows: [NSTableRowView] {
        var rows = [NSTableRowView]()
        enumerateAvailableRowViews { (view, _) in
            rows.append(view)
        }
        return rows
    }

    func childIndex(forRow row: Int) -> Int? {
        guard let item = self.item(atRow: row) else { return nil }
        return childIndex(forItem: item)
    }

    func expandAll() {
        DispatchQueue.main.async {
            self.expandItem(nil, expandChildren: true)
        }
    }
}



extension NSOutlineView {

    @objc var allSelectedItems:[Any] {
        return self.selectedRowIndexes.compactMap { index in
            return self.item(atRow: index)
        }
    }

    @objc(selectItem:byExtendingSelection:) func select(item: Any?, byExtendingSelection: Bool) {
        if (!byExtendingSelection) {
            self.deselectAll(self)
        }

        let row = self.row(forItem: item)
        if row < 0 {
            return
        }

        self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: true)
    }

    @objc(selectItems:byExtendingSelection:) func select(items:[Any]?, byExtendingSelection:Bool) {
        if (!byExtendingSelection || items == nil) {
            self.deselectAll(self)
        }

        guard let nonNilItems = items else {
            return
        }

        for item in nonNilItems {
            self.select(item: item, byExtendingSelection: true)
        }
    }
}



extension NSTextField {

    /// Returns true if the text field has a numeric formatter.
    var isNumericTextField: Bool {
        return formatter as? NumberFormatter != nil
    }

    /// Returns the identifier string for this field.
    var identifierString: String? {
        return identifier?.rawValue
    }

    /// Reset the text field.
    func reset() {
        attributedStringValue = NSMutableAttributedString()
        stringValue = ""
        placeholderString = ""
    }

    /// Set the string value of the text field, with optional animated fade.
    ///
    /// - Parameters:
    ///   - newValue: new text value.
    ///   - animated: enable fade out effect.
    ///   - interval: effect length.
    func setStringValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard stringValue != newValue else { return }
        if animated {
            animate(change: { self.stringValue = newValue }, interval: interval)
        } else {
            stringValue = newValue
        }
    }

    /// Set the attributed string value of the text field, with optional animated fade.
    ///
    /// - Parameters:
    ///   - newValue: new attributed string value.
    ///   - animated: enable fade out effect.
    ///   - interval: effect length.
    func setAttributedStringValue(_ newValue: NSAttributedString, animated: Bool = true, interval: TimeInterval = 0.7) {
        guard attributedStringValue != newValue else { return }
        if animated {
            animate(change: { self.attributedStringValue = newValue }, interval: interval)
        }
        else {
            attributedStringValue = newValue
        }
    }

    /// Highlight the label with the given color.
    ///
    /// - Parameters:
    ///   - color: label color.
    ///   - interval: effect length.
    func highlighWith(color: NSColor, interval: TimeInterval = 3.0) {
        animate(change: {
            self.textColor = color
        }, interval: interval)
    }

    /// Private function to animate a fade-in effect.
    ///
    /// - Parameters:
    ///   - change: transformation block.
    ///   - interval: effect length.
    fileprivate func animate(change: @escaping () -> Void, interval: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = interval / 2.0
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animator().alphaValue = 0.0
        }, completionHandler: {
            change()   // set the string value here
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = interval / 2.0
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                self.animator().alphaValue = 1.0
            }, completionHandler: {
                
            })
        })
    }
}


extension NSClipView {

    open override var isFlipped: Bool {
        return true
    }
}


extension NSImageView {

    /// Reset the image view with the default image.
    func reset(_ to: String = "default-icon") {
        self.image = NSImage(named: to)
        self.sizeToFit()
    }
}


/// Create & open a system alert dialog. Returns true if the user clicks the `OK` button.
///
/// - Parameters:
///   - title: dialog title.
///   - message: dialog informative description.
/// - Returns: user clicked `OK`
internal func createAlert(title: String, message: String) -> Bool {
    
    let alertDialog = NSAlert()
    alertDialog.addButton(withTitle: "OK")      // 1st button
    alertDialog.addButton(withTitle: "Cancel")  // 2nd button
    alertDialog.messageText = title
    alertDialog.informativeText = message

    // alertDialog.accessoryView = stackView
    
    // run modal
    let response: NSApplication.ModalResponse = alertDialog.runModal()
    
    // if the user clicks `OK`...
    if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
        return true
        
    } else {
        return false
    }
}




#endif


// MARK: - UIKit


#if os(iOS) || os(tvOS)


extension UILabel {

    /// Set the string value of the text field, with optional animated fade.
    ///
    /// - Parameters:
    ///   - newValue: new text value.
    ///   - animated: enable fade out effect.
    ///   - interval: effect duration.
    internal func setTextValue(_ newValue: String, animated: Bool = true, interval: TimeInterval = 0.7) {
        if animated {
            animate(change: { self.text = newValue }, interval: interval)
        } else {
            text = newValue
        }
    }

    /// Animate a fading effect.
    ///
    /// - Parameters:
    ///   - change: transformation block.
    ///   - interval: effect duration.
    private func animate(change: @escaping () -> Void, interval: TimeInterval) {
        let fadeDuration: TimeInterval = 0.5

        UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.text = ""
            self.alpha = 1.0
        }, completion: { (Bool) -> Void in
            change()
            UIView.animate(withDuration: fadeDuration, delay: interval, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.alpha = 0.0
            }, completion: nil)
        })
    }
}


#endif
