//
//  MousePointer.swift
//  SKTiled Demo - macOS
//
//  Copyright © 2020 Michael Fessenden. all rights reserved.
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


/// ### Overview
///
/// Global debug display mouse filter options (macOS).
///
/// #### Properties
///
/// | Property              | Description                              |
/// |:----------------------|:-----------------------------------------|
/// | tileCoordinates       | Show tile coordinates.                   |
/// | sceneCoordinates      | Show position in current scene.          |
/// | mapCoordinates        | Show position in current map.            |
/// | tileDataUnderCursor   | Show tile data properties.               |
///
public struct MouseEventOptions: OptionSet {
    public let rawValue: UInt8

    public static let tileCoordinates      = MouseEventOptions(rawValue: 1 << 0)
    public static let sceneCoordinates     = MouseEventOptions(rawValue: 1 << 1)
    public static let mapCoordinates       = MouseEventOptions(rawValue: 1 << 2)
    public static let tileDataUnderCursor  = MouseEventOptions(rawValue: 1 << 3)

    public static let `default`: MouseEventOptions = [.tileCoordinates, .sceneCoordinates]

    public static let all: MouseEventOptions = [.tileCoordinates, .sceneCoordinates, .mapCoordinates, .tileDataUnderCursor]

    public init(rawValue: UInt8 = 0) {
        self.rawValue = rawValue
    }
}


/// Debugging HUD display that follows the macOS cursor
internal class MousePointer: SKNode {

    var fontName: String = "Menlo"
    var _baseFontSize: CGFloat = TiledGlobals.default.debug.mousePointerSize
    var _fontSizeMultiplier: CGFloat = 1

    var fontSize: CGFloat {
        return _baseFontSize * _fontSizeMultiplier
    }

    var color: SKColor = SKColor.white

    @objc var receiveCameraUpdates: Bool = TiledGlobals.default.enableCameraCallbacks


    
    var _currentCoordinate: simd_int2?
    var isValidCoordinate: Bool = false
    
    var tileDataString: String?
    var mapPositionString: String?
    var scenePositionString: String?

    /// Label node.
    lazy var label: SKLabelNode? = {
        let newLabel = SKLabelNode(fontNamed: fontName)
        newLabel.name = "MOUSEPOINTER_LABEL"
        newLabel.setAttrs(values: ["tiled-node-desc": "Label reflecting the current mouse position in scene."])
        addChild(newLabel)
        newLabel.text = "coord:"
        return newLabel
    }()

    // TODO: put this on the current scene or view.
    
    /// Current mouse filters.
    var mouseFilters: MouseEventOptions = MouseEventOptions.all

    // MARK: - Mouse Pointer Init

    override init() {
        super.init()
        zPosition = 10000
        setupNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init()
        setupNotifications()
    }


    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.FocusCoordinateChanged, object: nil)
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderCursor), name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileClicked), name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(focusCoordinateChanged), name: Notification.Name.Map.FocusCoordinateChanged, object: nil)
    }

    /// Called when the tilemap focus coordinate is updated. Called when the `Notification.Name.Map.FocusCoordinateChanged` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func focusCoordinateChanged(notification: Notification) {
        guard let mapFocusedCoordinate = notification.object as? simd_int2,
              let userInfo = notification.userInfo as? [String: Any],
              let oldCoordinate = userInfo["old"] as? simd_int2,
              let isValidCoord = userInfo["isValid"] as? Bool else {
            return
        }
        
        isValidCoordinate = isValidCoord
        _currentCoordinate = mapFocusedCoordinate
        draw()
    }

    /// Set the current tile value. Called when the `Notification.Name.Demo.TileUnderCursor` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func tileUnderCursor(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        
        
    }


    /// Set the current tile value. Called when the `Notification.Name.Demo.TileClicked` notification is sent.
    ///
    /// - Parameter notification: event notification.
    @objc func tileClicked(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        
        tileDataString = #"gid: \#(tile.globalId)"#
        draw()
    }


    /// Called when the globals are updated.
    ///
    /// - Parameter notification: event notification.
    @objc func globalsUpdatedAction(notification: Notification) {
        let mousePointerEnabled = TiledGlobals.default.debug.mouseFilters.enableMousePointer
        isHidden = !mousePointerEnabled
        self.draw()
    }
    
    func draw() {
        guard (TiledGlobals.default.debug.mouseFilters.enableMousePointer == true),
              let currentCoordinate = _currentCoordinate else {
            return
        }
        
        let coordColor = (isValidCoordinate == true) ? TiledObjectColors.grass : TiledObjectColors.coral
        let labelStyle = NSMutableParagraphStyle()
        
        labelStyle.alignment = .center
        let stop = NSTextTab(type: .rightTabStopType, location: 8)
        labelStyle.addTabStop(stop)
        
        let defaultLabelAttributes = [
            .font: NSFont(name: self.fontName, size: self.fontSize)!,
            .foregroundColor: self.color,
            .paragraphStyle: labelStyle
            
        ] as [NSAttributedString.Key: Any]
        
        let coordAttributes = [
            .font: NSFont(name: self.fontName, size: self.fontSize)!,
            .foregroundColor: coordColor,
            .paragraphStyle: labelStyle
        ] as [NSAttributedString.Key: Any]
        
        
        /// here's the result
        let outputString = NSMutableAttributedString()
        
        
        let labelText = "coord: "
        
        if (mouseFilters.isShowingTileCoordinates == true) {
        
            let labelString = NSMutableAttributedString(string: labelText, attributes: defaultLabelAttributes)
            let dataString = NSMutableAttributedString(string: currentCoordinate.shortDescription, attributes: coordAttributes)
            
            outputString.append(labelString)
            outputString.append(dataString)
        
        }
        
        if (mouseFilters.isShowingTileData == true) {
            if let tileDataInfo = tileDataString {
                let dataString = "\\n\(tileDataInfo)"
                let dataOutput = NSMutableAttributedString(string: dataString, attributes: defaultLabelAttributes)
                
                outputString.append(dataOutput)
            }
        }
        
        
        
        if #available(OSX 10.13, *) {
            label?.attributedText = outputString
        } else {
            label?.text = outputString.string
        }
    }

    func draw(event: NSEvent) {
        guard (TiledGlobals.default.debug.mouseFilters.enableMousePointer == true) else {
            return
        }

        /*
        /// here's the result
        var attributedStringResult: NSAttributedString = NSMutableAttributedString()
        let scenePosition = event.location(in: tiledScene)
        let mapPosition = event.location(in: tilemap)
        self.position = scenePosition


        let coordinate = tilemap.coordinateAtMouse(event: event)

        let coordColor = tilemap.isValid(coord: coordinate) ? self.color : TiledObjectColors.coral


        let labelStyle = NSMutableParagraphStyle()
        labelStyle.alignment = .center

        let defaultLabelAttributes = [
            .font: NSFont(name: self.fontName, size: self.fontSize)!,
            .foregroundColor: self.color,
            .paragraphStyle: labelStyle
        ] as [NSAttributedString.Key: Any]

        let coordAttributes = [
            .font: NSFont(name: self.fontName, size: self.fontSize)!,
            .foregroundColor: coordColor,
            .paragraphStyle: labelStyle
        ] as [NSAttributedString.Key: Any]


        var labelIndex = 0

        if (mouseFilters.isShowingSceneCoordinates == true) {

            let outputString = NSMutableAttributedString()

            let labelText = "scene: "
            let labelString = NSMutableAttributedString(string: labelText, attributes: defaultLabelAttributes)
            let dataString = NSMutableAttributedString(string: scenePosition.shortDescription, attributes: defaultLabelAttributes)

            outputString.append(labelString)
            outputString.append(dataString)
            if #available(OSX 10.13, *) {
                self.sceneLabel?.attributedText = outputString
            } else {
                self.sceneLabel?.text = outputString.string
            }
            self.sceneLabel?.position.y = CGFloat(labelIndex - self.lineCount / 2) * self.fontSize + self.fontSize
            labelIndex += 1
        }

        if (mouseFilters.isShowingTileCoordinates == true) {

            let outputString = NSMutableAttributedString()

            let labelText = "coord: "
            let labelString = NSMutableAttributedString(string: labelText, attributes: defaultLabelAttributes)
            let dataString = NSMutableAttributedString(string: coordinate.shortDescription, attributes: coordAttributes)

            outputString.append(labelString)
            outputString.append(dataString)

            if #available(OSX 10.13, *) {
                self.coordLabel?.attributedText = outputString
            } else {
                self.coordLabel?.text = outputString.string
            }
            self.coordLabel?.position.y = CGFloat(labelIndex - self.lineCount / 2) * self.fontSize + self.fontSize
            labelIndex += 1
        }

        if (mouseFilters.isShowingMapCoordinates == true) {
            let outputString = NSMutableAttributedString()

            let labelText = "map: "
            let labelString = NSMutableAttributedString(string: labelText, attributes: defaultLabelAttributes)
            let dataString = NSMutableAttributedString(string: mapPosition.shortDescription, attributes: defaultLabelAttributes)

            outputString.append(labelString)
            outputString.append(dataString)

            if #available(OSX 10.13, *) {
                self.mapLabel?.attributedText = outputString
            } else {
                self.mapLabel?.text = outputString.string
            }
            self.mapLabel?.position.y = CGFloat(labelIndex - self.lineCount / 2) * self.fontSize + self.fontSize
            labelIndex += 1
        }

        self.tileLabel?.isHidden = true

        if (mouseFilters.isShowingTileData == true) {

            // tile id: 0, gid: 27
            let outputString = NSMutableAttributedString()

            if let currentTile = self.currentTile {
                let td = currentTile.tileData
                let idsIdentical = (td.id == td.globalID)

                var globalIDString = "\(td.globalID)"
                var originalIDString: String? = nil
                var idColor = self.color

                switch currentTile.renderMode {
                    case .animated(let gid):
                        if (gid != nil) {
                            globalIDString = "\(gid!)"
                            originalIDString = "\(td.globalID)"
                            idColor = TiledObjectColors.dandelion
                        }

                    default:
                        break
                }

                let globalIDLabelAttributes = [
                    .font: NSFont(name: self.fontName, size: self.fontSize)!,
                    .foregroundColor: idColor,
                    .paragraphStyle: labelStyle
                ] as [NSAttributedString.Key: Any]


                // contruct the first part of the label
                let tileDataString = (idsIdentical == true) ? "tile gid: " : (mouseFilters.isShowingTileLocalId == true) ? "tile id: \(td.id), gid: " : "tile gid: "
                let labelStringFirst = NSMutableAttributedString(string: tileDataString, attributes: defaultLabelAttributes)
                outputString.append(labelStringFirst)

                // tile id: 0, gid:
                if let originalIDString = originalIDString {
                    // highlight the global id in yellow
                    let labelStringSecond = NSMutableAttributedString(string: globalIDString, attributes: globalIDLabelAttributes)
                    // after, in parenthesis, indicate the ORIGINAL gid
                    let labelStringThird = NSMutableAttributedString(string: " (\(originalIDString))", attributes: defaultLabelAttributes)
                    outputString.append(labelStringSecond)
                    outputString.append(labelStringThird)

                } else {
                    // just add the normal tile gid
                    let labelStringSecond = NSMutableAttributedString(string: globalIDString, attributes: defaultLabelAttributes)
                    outputString.append(labelStringSecond)
                }

                self.tileLabel?.position.y = CGFloat(labelIndex - self.lineCount / 2) * self.fontSize + self.fontSize
                self.tileLabel?.isHidden = false

                if #available(OSX 10.13, *) {
                    self.tileLabel?.attributedText = outputString
                } else {
                    self.tileLabel?.text = outputString.string
                }
                labelIndex += 1
            }
        }
        */
    }
}


// MARK: - Extensions

extension MouseEventOptions {
    
    /// Indicates the mouse should display tile coordinates.
    public var isShowingTileCoordinates: Bool {
        get {
            return self.contains(.tileCoordinates)
        } set {
            if (newValue == true) {
                self.insert(.tileCoordinates)
            } else {
                self = self.subtracting(.tileCoordinates)
            }
        }
    }
    
    /// Indicates the mouse should display scene coordinates.
    public var isShowingSceneCoordinates: Bool {
        get {
            return self.contains(.sceneCoordinates)
        } set {
            if (newValue == true) {
                self.insert(.sceneCoordinates)
            } else {
                self = self.subtracting(.sceneCoordinates)
            }
        }
    }
    
    /// Indicates the mouse should display tile data attributes .
    public var isShowingTileData: Bool {
        get {
            return self.contains(.tileDataUnderCursor)
        } set {
            if (newValue == true) {
                self.insert(.tileDataUnderCursor)
            } else {
                self = self.subtracting(.tileDataUnderCursor)
            }
        }
    }
}



extension MousePointer: TiledSceneCameraDelegate {

    /// Called when the mouse moves in the scene.
    ///
    /// - Parameter event: mouse event.
    func mousePositionChanged(event: NSEvent) {
        draw(event: event)
    }
}


extension MousePointer: TiledCustomReflectableType {

    public func dumpStatistics() {
        dump(self)
    }

    /// Returns a "nicer" node name, for usage in the inspector.
    @objc public var tiledNodeNiceName: String {
        return "MousePointer"
    }

    /// Returns the internal **Tiled** node type icon.
    @objc public var tiledIconName: String {
        return "mousepointer-icon"
    }

    /// A description of the node used for list views.
    @objc public var tiledListDescription: String {
        return "MousePointer"
    }

    /// A description of the node.
    @objc public var tiledDescription: String {
        return "A node that tracks mouse movement."
    }
}
