//
//  MousePointer.swift
//  SKTiled Demo - macOS
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


/// The `MouseEventOptions` option set defines global debug display mouse filter options (macOS).
///
/// #### Properties
///
/// - `tileCoordinates`: display tile coordinates at the mouse cursor position.
/// - `sceneCoordinates`: display the mouse position in current scene.
/// - `mapCoordinates`: display the mouse position in current map.
/// - `tileDataUnderCursor`: display tile data properties under the cursor.
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

    /// The current font name used for the labels.
    var fontName: String = "Menlo"

    /// Base size for the labels.
    var _baseFontSize: CGFloat {
        return TiledGlobals.default.debugDisplayOptions.mousePointerSize
    }

    /// Labell size multiplier.
    var _fontSizeMultiplier: CGFloat = 1

    /// Computed font size.
    var fontSize: CGFloat {
        return _baseFontSize * _fontSizeMultiplier
    }

    /// Computed font size.
    var rootOffset: CGPoint {
        return CGPoint(x: 0, y: fontSize * 2)
    }

    /// Label base color.
    var color: SKColor = SKColor.white

    /// Enable camera updates.
    @objc var receiveCameraUpdates: Bool = TiledGlobals.default.enableCameraCallbacks

    /// The currently focused tile.
    weak var currentTile: SKTile?

    /// The currently focused object.
    weak var currentObject: SKTileObject?

    /// Current location of mouse.
    var _currentCoordinate: simd_int2?

    /// Indicates the coordinate is a valid map coordinate.
    var isValidCoordinate: Bool = false

    /// Root position node.
    var rootNode = SKNode()

    /// Label for scene position.
    var sceneLabel: SKLabelNode?

    /// Label for map coordinates.
    var coordLabel: SKLabelNode?

    /// Label for tile data display.
    var tileLabel:  SKLabelNode?

    /// Label for window position.
    var winLabel:  SKLabelNode?

    /// Current mouse filters.
    var mouseFilters: TiledGlobals.DebugDisplayOptions.MouseFilters {
        return TiledGlobals.default.debugDisplayOptions.mouseFilters
    }

    /// Draw the tile local id.
    var drawLocalID: Bool {
        return mouseFilters.contains(.tileLocalID)
    }

    /// Calculates the line count.
    var lineCount: Int {
        var result = 1   // 0 if not using winLabel
        if (mouseFilters.isShowingTileCoordinates) {
            result += 1
        }
        if (mouseFilters.isShowingSceneCoordinates) {
            result += 1
        }

        if (mouseFilters.isShowingTileData) {
            result += 1
        }
        return result
    }

    // MARK: - Initialization

    override init() {
        super.init()
        addChild(rootNode)
        zPosition = 10000
        setupLabels()
        setupNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init()
        addChild(rootNode)
        zPosition = 10000
        setupLabels()
        setupNotifications()
    }

    deinit {
        // remove references to objects
        currentTile = nil
        currentObject = nil

        // destroy the labels
        sceneLabel?.removeFromParent()
        sceneLabel = nil

        coordLabel?.removeFromParent()
        coordLabel = nil

        tileLabel?.removeFromParent()
        tileLabel = nil

        winLabel?.removeFromParent()
        winLabel = nil

        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Map.FocusCoordinateChanged, object: nil)

        rootNode.removeAllChildren()
        rootNode.removeFromParent()
    }

    // MARK: - Setup

    func setupLabels() {
        if (sceneLabel == nil) {
            let label = SKLabelNode(fontNamed: fontName)
            rootNode.addChild(label)
            sceneLabel = label
        }
        if (coordLabel == nil) {
            let label = SKLabelNode(fontNamed: fontName)
            rootNode.addChild(label)
            coordLabel = label
        }

        if (tileLabel == nil) {
            let label = SKLabelNode(fontNamed: fontName)
            rootNode.addChild(label)
            tileLabel = label
        }

        if (winLabel == nil) {
            let label = SKLabelNode(fontNamed: fontName)
            rootNode.addChild(label)
            winLabel = label
        }
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderCursor), name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tileClicked), name: Notification.Name.Demo.TileClicked, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(globalsUpdatedAction), name: Notification.Name.Globals.Updated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(focusCoordinateChanged), name: Notification.Name.Map.FocusCoordinateChanged, object: nil)
    }


    // MARK: - Notification Handlers

    /// Called when the tilemap focus coordinate is updated. Called when the `Notification.Name.Map.FocusCoordinateChanged` notification is received.
    ///
    ///  object: `simd_int2`, userInfo: `["oldValue": simd_int2, "isValid": Bool]`
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
        //redraw()
    }

    /// Set the current tile value. Called when the `Notification.Name.Demo.TileUnderCursor` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func tileUnderCursor(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        guard let tile = notification.object as? SKTile else {
            return
        }
        currentTile = tile
        redraw()
    }

    /// Set the current tile value. Called when the `Notification.Name.Demo.TileClicked` notification is received.
    ///
    /// - Parameter notification: event notification.
    @objc func tileClicked(notification: Notification) {
        guard let tile = notification.object as? SKTile else {
            return
        }
        currentTile = tile
        redraw()
    }

    /// Called when the globals are updated.
    ///
    /// - Parameter notification: event notification.
    @objc func globalsUpdatedAction(notification: Notification) {
        //notification.dump(#fileID, function: #function)
        let mousePointerEnabled = TiledGlobals.default.debugDisplayOptions.mouseFilters.enableMousePointer
        isHidden = !mousePointerEnabled
        redraw()
    }

    /// Draw the pointer.
    ///
    /// - Parameter event: mouse event.
    func draw(event: NSEvent) {
        guard (TiledGlobals.default.debugDisplayOptions.mouseFilters.enableMousePointer == true) else {
            isHidden = true
            return
        }

        guard let tiledScene = scene as? SKTiledScene,
              let tilemap = tiledScene.tilemap else {
            isHidden = true
            return
        }


        rootNode.position = rootOffset

        let sceneSize = tiledScene.size   // 640x480
        let windowLocation = event.locationInWindow
        let scenePosition = event.location(in: tiledScene)



        self.position = scenePosition
        let coordinate = tilemap.coordinateAtMouse(event: event)
        let coordColor = tilemap.isValid(coord: coordinate) ? TiledObjectColors.grass : TiledObjectColors.coral


        let labelStyle = NSMutableParagraphStyle()
        labelStyle.alignment = .center

        let defaultLabelAttributes = [
            .font: NSFont(name: fontName, size: fontSize)!,
            .foregroundColor: color,
            .paragraphStyle: labelStyle
        ] as [NSAttributedString.Key: Any]

        let coordAttributes = [
            .font: NSFont(name: fontName, size: fontSize)!,
            .foregroundColor: coordColor,
            .paragraphStyle: labelStyle
        ] as [NSAttributedString.Key: Any]


        var labelIndex = 0

        let winLabelText = "window: \(windowLocation.shortDescription)"
        let winLabelString = NSMutableAttributedString(string: winLabelText, attributes: defaultLabelAttributes)
        if #available(OSX 10.13, *) {
            winLabel?.attributedText = winLabelString
        } else {
            winLabel?.text = winLabelString.string
        }

        if (mouseFilters.isShowingSceneCoordinates == true) {
            sceneLabel?.isHidden = false
            let outputString = NSMutableAttributedString()

            let labelText = "scene: "
            let labelString = NSMutableAttributedString(string: labelText, attributes: defaultLabelAttributes)
            let dataString = NSMutableAttributedString(string: scenePosition.shortDescription, attributes: defaultLabelAttributes)

            outputString.append(labelString)
            outputString.append(dataString)
            if #available(OSX 10.13, *) {
                sceneLabel?.attributedText = outputString
            } else {
                sceneLabel?.text = outputString.string
            }
            sceneLabel?.position.y = CGFloat(labelIndex - lineCount / 1.5) * self.fontSize + self.fontSize
            labelIndex += 1
        } else {
            sceneLabel?.isHidden = true
        }


        if (mouseFilters.isShowingTileCoordinates == true) {
            coordLabel?.isHidden = false

            let outputString = NSMutableAttributedString()

            let labelText = "coord: "
            let labelString = NSMutableAttributedString(string: labelText, attributes: defaultLabelAttributes)
            let dataString = NSMutableAttributedString(string: coordinate.shortDescription, attributes: coordAttributes)

            outputString.append(labelString)
            outputString.append(dataString)

            if #available(OSX 10.13, *) {
                coordLabel?.attributedText = outputString
            } else {
                coordLabel?.text = outputString.string
            }
            coordLabel?.position.y = CGFloat(labelIndex - lineCount / 1.5) * self.fontSize + self.fontSize
            labelIndex += 1
        } else {
            coordLabel?.isHidden = true
        }

        tileLabel?.isHidden = true

        if (mouseFilters.isShowingTileData == true) {

            // tile id: 0, gid: 27
            let outputString = NSMutableAttributedString()

            if let currentTile = currentTile {

                let td = currentTile.tileData
                let idsIdentical = (td.id == td.globalID)

                var globalIDString = "\(td.globalID)"
                var originalIDString: String? = nil
                var idColor = color

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
                    .font: NSFont(name: fontName, size: fontSize)!,
                    .foregroundColor: idColor,
                    .paragraphStyle: labelStyle
                ] as [NSAttributedString.Key: Any]


                // contruct the first part of the label
                let tileDataString = (idsIdentical == true) ? "tile gid: " : (drawLocalID == true) ? "tile id: \(td.id), gid: " : "tile gid: "
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

                tileLabel?.position.y = CGFloat(labelIndex - lineCount / 1.5) * self.fontSize + self.fontSize
                tileLabel?.isHidden = false
                if #available(OSX 10.13, *) {
                    tileLabel?.attributedText = outputString
                } else {
                    tileLabel?.text = outputString.string
                }
                labelIndex += 1
            }
        }
    }

    func postitionLabels() {
        var labelindex = 0
        for label in [sceneLabel, coordLabel, tileLabel, winLabel] {
            guard let thisLabel = label else {
                continue
            }

            if thisLabel.isHidden == false {
                thisLabel.position.y = CGFloat(labelindex - lineCount / 1.5) * self.fontSize + self.fontSize
                labelindex += 1
            }
        }
    }

    func redraw() {}
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
    @objc func mousePositionChanged(event: NSEvent) {
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

    /// A description of the node used for list (menu) views.
    @objc public var tiledListDescription: String {
        return "MousePointer"
    }

    /// A description of the node.
    @objc public var tiledHelpDescription: String {
        return "A node that tracks mouse movement."
    }
}
