//
//  MousePointer.swift
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

import SpriteKit


/// Debugging HUD display that follows the macOS cursor
internal class MousePointer: SKNode {

    var fontName: String = "Courier"
    var fontSize: CGFloat = 12

    var color: SKColor = SKColor.white
    var receiveCameraUpdates: Bool = TiledGlobals.default.enableCameraCallbacks

    var currentTile: SKTile?
    var currentObject: SKTileObject?

    var sceneLabel: SKLabelNode?
    var coordLabel: SKLabelNode?
    var tileLabel:  SKLabelNode?


    var mouseFilters: TiledGlobals.DebugDisplayOptions.MouseFilters {
        return TiledGlobals.default.debug.mouseFilters
    }

    var lineCount: Int {
        var result = 0
        if (mouseFilters.contains(.tileCoordinates)) {
            result += 1
        }
        if (mouseFilters.contains(.sceneCoordinates)) {
            result += 1
        }

        if (mouseFilters.contains(.tileDataUnderCursor)) {
            result += 1
        }
        return result
    }

    var drawTileCoordinates: Bool {
        return mouseFilters.contains(.tileCoordinates)
    }

    var drawSceneCoordinates: Bool {
        return mouseFilters.contains(.sceneCoordinates)
    }

    var drawTileData: Bool {
        return mouseFilters.contains(.tileDataUnderCursor)
    }

    var drawLocalID: Bool {
        return mouseFilters.contains(.tileLocalID)
    }

    override init() {
        super.init()
        zPosition = 10000
        setupLabels()
        setupNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init()
        setupLabels()
        setupNotifications()
    }

    func setupLabels() {
        if (sceneLabel == nil) {
            sceneLabel = SKLabelNode(fontNamed: fontName)
            addChild(sceneLabel!)
        }
        if (coordLabel == nil) {
            coordLabel = SKLabelNode(fontNamed: fontName)
            addChild(coordLabel!)
        }
        if (tileLabel == nil) {
            tileLabel = SKLabelNode(fontNamed: fontName)
            addChild(tileLabel!)
        }
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(tileUnderCursor), name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(objectUnderCursor), name: Notification.Name.Demo.ObjectUnderCursor, object: nil)
    }

    @objc func tileUnderCursor(notification: Notification) {
        guard let tile = notification.object as? SKTile else { return }
        currentTile = tile
    }

    @objc func objectUnderCursor(notification: Notification) {
        guard let object = notification.object as? SKTileObject else { return }
        currentObject = object
    }


    func draw(event: NSEvent, scene: SKScene) {

        if let tiledScene = scene as? SKTiledScene {
            if let tilemap = tiledScene.tilemap {

                let scenePosition = event.location(in: scene)

                self.position = scenePosition
                let coordinate = tilemap.coordinateAtMouseEvent(event: event)
                let coordColor = tilemap.isValid(coord: coordinate) ? color : TiledObjectColors.coral


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

                if (drawSceneCoordinates == true) {

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
                    sceneLabel?.position.y = CGFloat(labelIndex - lineCount / 2) * self.fontSize + self.fontSize
                    labelIndex += 1
                }


                if (drawTileCoordinates == true) {

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
                    coordLabel?.position.y = CGFloat(labelIndex - lineCount / 2) * self.fontSize + self.fontSize
                    labelIndex += 1
                }

                tileLabel?.isHidden = true

                if (drawTileData == true) {
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

                        tileLabel?.position.y = CGFloat(labelIndex - lineCount / 2) * self.fontSize + self.fontSize
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
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.TileUnderCursor, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Demo.ObjectUnderCursor, object: nil)
    }
}

// MARK: - Extensions


extension MousePointer: SKTiledSceneCameraDelegate {

    /**
     Called when the mouse moves in the scene.

     - parameter event: `NSEvent` mouse click event.
     */
    func mousePositionChanged(event: NSEvent) {
        guard let scene = scene else { return }
        self.draw(event: event, scene: scene)
    }
}
