//
//  SKTilemapParser.swift
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

import Foundation
import SpriteKit


/// Current parsing mode.
internal enum TiledParsingMode {
    case none
    case tmx
    case tsx
    case tx
}


/// File types recognized by the parser
internal enum FileType: String {
    case tmx
    case tsx
    case png
    case tx
}


/// Document data encoding.
internal enum TilemapEncoding: String {
    case unknown
    case base64
    case csv
    case xml
}


/// Document data compression type.
internal enum TilemapCompression: String {
    case unknown
    case uncompressed
    case zlib
    case gzip
    case zstd
}


/// Current map mode.
internal enum TilemapCanvasType {
    case `default`
    case infinite
}


/// ## Overview
///
/// The `SKTilemapParser` class is a custom [`XMLParserDelegate`](https://developer.apple.com/reference/foundation/xmlparserdelegate)
/// parser for reading Tiled TMX and tileset TSX files.
///
/// This class is not meant to be instantiated directly, but rather invoked via `SKTilemap.load` class function.
internal class SKTilemapParser: NSObject, XMLParserDelegate {

    // XML Parser error types.
    struct ParsingError: Error {
        enum ErrorType {
            case attribute(attr: String)
            case attributeValue(attr: String, value: String)
            case key(key: String)
            case index(idx: Int)
            case compression(value: String)
            case externalFile(value: String)
            case error
        }

        let line: Int
        let column: Int
        let kind: ErrorType
    }

    // MARK: File Attributes

    /// Root path of the current file (defaults to `Bundle.main.bundleURL`).
    internal var documentRoot: URL = Bundle.main.bundleURL

    /// The filename of the file being currently parsed (ie: `dungeon-16x16.tmx`) relative to the document root.
    internal var currentFilename: String!

    /// Current file url, relative to the document root.
    internal var currentFileUrl: URL!

    /// External file urls (relative to root) for parsing. These are **full paths** for files needed for parsing.
    internal var externalFileUrls: [URL] = []

    /// Tile data file encoding type.
    fileprivate var encoding: TilemapEncoding = .xml

    // MARK: Map Attributes

    /// Tilemap canvas type (normal, infinite).
    internal var canvasType: TilemapCanvasType = TilemapCanvasType.default

    /// Current file parsing mode (map, tileset, template).
    internal var parsingMode: TiledParsingMode = TiledParsingMode.none

    /// Desired tile update mode.
    internal var tileUpdateMode: TileUpdateMode = TileUpdateMode.actions


    // MARK: Delegates

    /// Tilemap data delegate.
    internal weak var tilemapDelegate: TilemapDelegate?

    /// Tileset data delegate.
    internal weak var tilesetDataSource: TilesetDataSource?

    /// The number of images added to a collections tileset.
    fileprivate var tilesetImagesAdded: Int = 0

    /// Logging message verbosity.
    fileprivate var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel


    // MARK: Stored Elements

    /// Currently parsed map.
    internal weak var tilemap: SKTilemap?

    /// External tileset storage. Tilesets are stored as tileset URL & object (ie: ["kong-50x32.tsx": <SKTileset>]).
    fileprivate var tilesets: [URL: SKTileset] = [:]

    /// XML element storage (NYI).
    fileprivate var elements = Stack<AnyObject>()

    /// Current element XML type.
    fileprivate var activeElement: String?

    /// Template object storage. These are objects referenced by template files.
    fileprivate var templateObjects: [SKTileObject] = []

    /// Stash for the currently active tileset. Used for template objects.
    fileprivate var activeTemplateTileset: SKTileset?

    /// Last element created.
    fileprivate var lastElement: AnyObject?

    /// Last tile layer added.
    fileprivate var lastTileLayer: SKTileLayer?

    /// Current element path.
    fileprivate var elementPath: [AnyObject] = []

    /// Current tile/object id. If this is not nil, we're looking for an object in an objectgroup or
    fileprivate var currentID: UInt32?

    /// Current tile type.
    fileprivate var currentType: String?

    /// Current tile probability.
    fileprivate var currentProbability: CGFloat?

    /// Current layer index (flattened).
    fileprivate var layerIndex: UInt32 = 0

    // MARK: Tile Data

    /// Data store for tile layers to render in a second pass. Data is stored as [layer.uuid: [UInt32] ).
    fileprivate var layerTileData: [String: [UInt32]] = [:]

    /// Stash for last tile data read.
    fileprivate var tileData: [UInt32] = []

    /// Tile data string.
    fileprivate var characterData: String = ""

    /// TMX file compression type.
    fileprivate var compression: TilemapCompression = TilemapCompression.uncompressed

    // MARK: Custom Properties

    /// Stashed object properties.
    fileprivate var properties: [String: String] = [:]

    /// Ignore custom properties.
    fileprivate var ignoreProperties: Bool = false

    // MARK: Timing

    /// Time started.
    fileprivate var timer: Date = Date()

    // MARK: Dispatch Attributes

    /// Dispatch queue for parsing tasks.
    internal let parsingQueue = DispatchQueue.global(qos: .userInteractive)

    /// Render group for rendering tasks.
    internal let renderGroup = DispatchGroup()

    // MARK: - Debugging/Reflection

    /// Stash for parsing errors..
    internal var parsingErrors: [String: Any] = [:]

    /// Storage for external tileset urls.
    internal var parsedTilesetUrls: [URL] = []

    /// Files that can't be found are sent here.
    internal var missingFiles: [URL] = []

    /// Parsed XML type files. As soon as a file is read, this gains a value.
    internal var externalXMLFiles: [URL] = []

    /// Parsed image files.
    internal var externalImageAssetFiles: [URL] = []

    /// Current tilemap url, relative to the bundle path. This is used for introspection.
    internal var tilemapUrl: URL?

    // MARK: - New Loading Methods

    /// Load a TMX file and parse it.
    ///
    /// - Parameters:
    ///   - tmxUrl: Tiled tilemap file url.
    ///   - delegate: optional tilemap delegate instance.
    ///   - tilesetDataSource: optional [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - updateMode: tile update mode.
    ///   - withTilesets: use existing tilesets to create the tile map.
    ///   - noparse: ignore custom properties.
    ///   - loggingLevel: logging verbosity.
    ///   - renderQueue: queue to manage rendering.
    /// - Returns: tiled map node.
    internal func load(tmxUrl: URL,
                       delegate: TilemapDelegate? = nil,
                       tilesetDataSource: TilesetDataSource? = nil,
                       updateMode: TileUpdateMode = TiledGlobals.default.updateMode,
                       withTilesets: [SKTileset]? = nil,
                       ignoreProperties noparse: Bool = false,
                       loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                       renderQueue: DispatchQueue) -> SKTilemap? {

        // update the logging level
        Logger.default.loggingLevel = loggingLevel

        // current parsing mode & map update mode
        parsingMode = .tmx
        tileUpdateMode = updateMode


        // set the parser document root (sets `documentRoot`, `currentFilename`, `documentReadUrl`)
        resolveDocumentRoot(tmxFile: tmxUrl.path, assetPath: nil)

        // set the current file name & url
        currentFilename = tmxUrl.lastPathComponent
        currentFileUrl = URL(fileURLWithPath: currentFilename, relativeTo: documentRoot).standardized

        // add the file and go!
        externalFileUrls.append(currentFileUrl)

        // set the root document path (this is mostly just for reflection).
        tilemapUrl = currentFileUrl

        return nil
    }

    /// Load a tilemap from string data.
    ///
    /// - Parameters:
    ///   - string: Tiled tilemap xml string data.
    ///   - documentRoot: document root.
    ///   - delegate: optional tilemap delegate instance.
    ///   - tilesetDataSource: optional [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - updateMode: tile update mode.
    ///   - withTilesets: use existing tilesets to create the tile map.
    ///   - noparse: ignore custom properties.
    ///   - loggingLevel: logging verbosity.
    ///   - renderQueue: queue to manage rendering.
    /// - Returns: tiled map node.
    internal func load(string: String,
                       documentRoot: String? = nil,
                       delegate: TilemapDelegate? = nil,
                       tilesetDataSource: TilesetDataSource? = nil,
                       updateMode: TileUpdateMode = TiledGlobals.default.updateMode,
                       withTilesets: [SKTileset]? = nil,
                       ignoreProperties noparse: Bool = false,
                       loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                       renderQueue: DispatchQueue) -> SKTilemap? {


        guard let encodedString = string.base64Encoded(),
              let data = Data(base64Encoded: encodedString) else {
            log("cannot parse tilemap from string data.", level: .error)
            return nil
        }

        return load(data: data, documentRoot: documentRoot, delegate: delegate, tilesetDataSource: tilesetDataSource, updateMode: updateMode, withTilesets: withTilesets, ignoreProperties: ignoreProperties, loggingLevel: loggingLevel, renderQueue: renderQueue)
    }


    /// Load a tilemap from xml string data.
    ///
    /// - Parameters:
    ///   - data: Tiled tilemap xml string data.
    ///   - documentRoot: document root.
    ///   - delegate: optional tilemap delegate instance.
    ///   - tilesetDataSource: optional [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - updateMode: tile update mode.
    ///   - withTilesets: use existing tilesets to create the tile map.
    ///   - noparse: ignore custom properties.
    ///   - loggingLevel: logging verbosity.
    ///   - renderQueue: queue to manage rendering.
    /// - Returns: tiled map node.
    internal func load(data: Data,
                       documentRoot: String? = nil,
                       delegate: TilemapDelegate? = nil,
                       tilesetDataSource: TilesetDataSource? = nil,
                       updateMode: TileUpdateMode = TiledGlobals.default.updateMode,
                       withTilesets: [SKTileset]? = nil,
                       ignoreProperties noparse: Bool = false,
                       loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                       renderQueue: DispatchQueue) -> SKTilemap? {


        // update the default logging level
        Logger.default.loggingLevel = loggingLevel

        // current parsing mode & map update mode
        self.parsingMode = .tmx
        self.tileUpdateMode = updateMode

        // set the delegate property
        self.tilemapDelegate = delegate
        self.tilesetDataSource = tilesetDataSource

        // start the timer
        self.timer = Date()
        self.ignoreProperties = noparse
        self.loggingLevel = loggingLevel

        // document root
        if let documentRootPath = documentRoot {
            self.documentRoot = URL(fileURLWithPath: documentRootPath).standardized
        }

        let parser: XMLParser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = self


        // hacky, but it works
        currentFilename = "tilemap"

        // parse the file
        let successs: Bool = parser.parse()


        // report errors
        if (successs == false) {

            let parseError = parser.parserError
            let errorLine = parser.lineNumber
            let errorCol = parser.columnNumber

            let errorDescription = parseError!.localizedDescription
            log("\(parsingMode) parser error '\(errorDescription)' at line \(errorLine), column \(errorCol)", level: .error)
        }

        guard let currentMap = self.tilemap else {
            return nil
        }

        // reset to tmx
        parsingMode = TiledParsingMode.tmx

        // reset tileset data
        tilesets = [:]

        // pre-processing callback
        renderQueue.sync {
            currentMap.parseTime = Date().timeIntervalSince(self.timer)
            self.tilemapDelegate?.didReadMap?(currentMap)
        }

        
        parsingQueue.sync {
            /// render, then notify the delegates of completion
            self.didBeginRendering(currentMap, queue: renderQueue)
        }

        currentMap.dataStorage?.sync()
        return currentMap
    }


    // MARK: - Original Loading Methods

    /// Load a TMX file and parse it.
    ///
    /// - Parameters:
    ///   - tmxFile: Tiled file name (does not need TMX extension).
    ///   - inDirectory: search path for assets.
    ///   - delegate: optional tilemap delegate instance.
    ///   - tilesetDataSource: optional [`TilesetDataSource`](Protocols/TilesetDataSource.html) instance.
    ///   - updateMode: tile update mode.
    ///   - withTilesets: use existing tilesets to create the tile map.
    ///   - noparse: ignore custom properties.
    ///   - loggingLevel: logging verbosity.
    ///   - renderQueue: queue to manage rendering.
    /// - Returns: tiled map node.
    internal func load(tmxFile: String,
                       inDirectory: String? = nil,
                       delegate: TilemapDelegate? = nil,
                       tilesetDataSource: TilesetDataSource? = nil,
                       updateMode: TileUpdateMode = TiledGlobals.default.updateMode,
                       withTilesets: [SKTileset]? = nil,
                       ignoreProperties noparse: Bool = false,
                       loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                       renderQueue: DispatchQueue) -> SKTilemap? {

        // update the logging level
        Logger.default.loggingLevel = loggingLevel


        // current parsing mode & map update mode
        self.parsingMode = .tmx
        self.tileUpdateMode = updateMode

        // set the delegate property
        self.tilemapDelegate = delegate
        self.tilesetDataSource = tilesetDataSource

        // start the timer
        self.timer = Date()
        self.ignoreProperties = noparse
        self.loggingLevel = loggingLevel


        // append extension if not already there.
        var tmxFilename = tmxFile.components(separatedBy: "/").last!


        if !tmxFilename.hasSuffix(".tmx") {
            tmxFilename = tmxFilename.appending(".tmx")
        }

        // set the document root & file name
        resolveDocumentRoot(tmxFile: tmxFile, assetPath: inDirectory)


        // create a url relative to the current root
        currentFileUrl = URL(fileURLWithPath: tmxFilename, relativeTo: documentRoot).standardized
        externalFileUrls.append(currentFileUrl)


        // add existing tilesets
        if let withTilesets = withTilesets {
            for tileset in withTilesets {

                guard let filename = tileset.filename else {
                    log("tileset '\(tileset.name)' has no filename property.", level: .error)
                    continue
                }


                let tilesetUrl = URL(fileURLWithPath: filename, relativeTo: documentRoot)
                tilesets[tilesetUrl] = tileset
                parsedTilesetUrls.append(tilesetUrl)
            }
        }


        while !(externalFileUrls.isEmpty) {

            // firstFileToParse = full path (relative to doc root)
            if let firstFileToParse = externalFileUrls.first {

                // current file name (minus doc root)  (ie 'User/Templates/dragon-green.tx')
                currentFilename = firstFileToParse.relativePath

                // current file name only (ie 'dragon-green.tx')
                let currentFile = firstFileToParse.lastPathComponent

                defer {
                    let fileRead = externalFileUrls.remove(at: 0)
                    if (fileRead.path != tilemapUrl?.path) {
                        externalXMLFiles.append(fileRead)
                    }
                }

                // check file type with the path extension.
                let pathExtension = firstFileToParse.pathExtension.lowercased()

                switch pathExtension {
                case "tmx":
                    parsingMode = TiledParsingMode.tmx
                case "tsx":
                    parsingMode = TiledParsingMode.tsx
                case "tx":
                    parsingMode = TiledParsingMode.tx
                default:
                    parsingMode = TiledParsingMode.none
                }

                var filetype = "filename"
                if let ftype = FileType(rawValue: pathExtension) {
                    filetype = ftype.description
                }


                // set the url for the **current file being read**
                currentFileUrl = URL(fileURLWithPath: currentFilename, relativeTo: documentRoot).standardized

                // check that file exists
                guard self.fileExists(at: currentFileUrl) else {
                    // TODO: throw here
                    log("cannot find file '\(currentFile)'", level: .fatal)
                    return nil
                }

                // use custom logging levels for different parsing modes (reduce spam with external files).
                let customLoggingLevel = (parsingMode == .tmx) ? LoggingLevel.custom : LoggingLevel.debug
                log("\(parsingMode) parser: reading \(filetype): '\(currentFileUrl.lastPathComponent)'", level: customLoggingLevel)


                // read the data

                // TODO: throw here
                let data: Data = try! Data(contentsOf: currentFileUrl)
                let parser: XMLParser = XMLParser(data: data)

                parser.shouldResolveExternalEntities = false
                parser.delegate = self

                // parse the file
                let successs: Bool = parser.parse()

                // report errors
                if (successs == false) {

                    let parseError = parser.parserError
                    let errorLine = parser.lineNumber
                    let errorCol = parser.columnNumber

                    let errorDescription = parseError!.localizedDescription
                    log("\(parsingMode) parser '\(currentFile)' \(errorDescription) at line \(errorLine), column \(errorCol)", level: .error)
                }
            }
        }

        // if the tilemap wasn't parsed correctly, return nil
        guard let currentMap = self.tilemap else {
            return nil
        }

        // reset to tmx
        parsingMode = TiledParsingMode.tmx

        // reset tileset data
        tilesets = [:]

        // pre-processing callback
        renderQueue.sync {
            currentMap.parseTime = Date().timeIntervalSince(self.timer)

            // call back to the tilemap delegate for overrides
            self.tilemapDelegate?.didReadMap?(currentMap)
        }


        parsingQueue.sync {
            /// render, then notify the delegates of completion
            self.didBeginRendering(currentMap, queue: renderQueue)
        }

        currentMap.dataStorage?.sync()
        return currentMap
    }

    /// Pre-load tilesets from external files.
    ///
    /// - Parameters:
    ///   - tsxFiles: array of tileset filenames.
    ///   - inDirectory: search path for assets.
    ///   - delegate: optional tilemap delegate instance.
    ///   - tilesetDataSource: ignore custom properties from Tiled.
    ///   - noparse: ignore custom properties.
    ///   - loggingLevel: logging verbosity.
    ///   - renderQueue: queue to manage rendering.
    /// - Returns: tilesets.
    public func load(tsxFiles: [String],
                     inDirectory: String? = nil,
                     delegate: TilemapDelegate? = nil,
                     tilesetDataSource: TilesetDataSource? = nil,
                     ignoreProperties noparse: Bool = false,
                     loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel,
                     renderQueue: DispatchQueue) -> [SKTileset] {



        TiledGlobals.default.loggingLevel = loggingLevel

        // current parsing mode is tsx
        parsingMode = .tsx

        // set the delegate property
        self.tilemapDelegate = delegate
        self.tilesetDataSource = tilesetDataSource
        self.timer = Date()
        self.loggingLevel = loggingLevel
        self.ignoreProperties = noparse

        // if a directory is passed, use that as the root path, otherwise default to bundle's resource
        if (TiledGlobals.default.isPlayground == false) {
            if let resourceURL = Bundle.main.resourceURL {
                documentRoot = resourceURL
            }
        } else {
            if let bundleResourceUrl = Bundle.main.url(forResource: nil, withExtension: "tsx") {
                documentRoot = bundleResourceUrl.deletingLastPathComponent()
            }
        }

        // if the user has passed a search directory...
        if let _ = inDirectory {
            //documentRoot = self.getAssetDirectory(path: rootDirectory)
        }

        // create urls relative to root
        for tsxfile in tsxFiles {

            // append extension if not already there.
            var tsxFilename = tsxfile
            if !tsxFilename.hasSuffix(".tsx") {
                tsxFilename = tsxFilename.appending(".tsx")
            }


            let fileURL = URL(fileURLWithPath: tsxFilename, relativeTo: documentRoot).standardized
            if FileManager.default.fileExists(atPath: fileURL.path) {
                externalFileUrls.append(fileURL)
            } else {
                fatalError("cannot find file '\(fileURL.lastPathComponent)'")
            }
        }


        // stash results
        var tilesetResults: [SKTileset] = []

        while !(externalFileUrls.isEmpty) {

            // firstFileToParse = full path (relative to doc root)
            if let firstFileToParse = externalFileUrls.first {

                currentFilename = firstFileToParse.relativePath
                let currentFile = firstFileToParse.lastPathComponent


                defer {
                    let fileRead = externalFileUrls.remove(at: 0)
                    if (fileRead.path != tilemapUrl?.path) {
                        externalXMLFiles.append(fileRead)
                    }
                }


                // check file type with the path extension.
                let pathExtension = firstFileToParse.pathExtension.lowercased()

                switch pathExtension {
                case "tmx":
                    parsingMode = .tmx
                case "tsx":
                    parsingMode = .tsx
                default:
                    parsingMode = .none
                }

                var filetype = "filename"
                if let ftype = FileType(rawValue: pathExtension) {
                    filetype = ftype.description
                }


                // absolute url
                let currentURL = URL(fileURLWithPath: currentFilename)

                // check that file exists
                guard self.fileExists(at: currentURL) else {
                    continue
                }

                if (parsingMode == .tmx) {
                    log("\(parsingMode) parser: reading \(filetype): '\(currentFile)'", level: .debug)
                }

                // set the root path to the current file
                if let currentParent = currentURL.parent {
                    documentRoot = URL(fileURLWithPath: currentParent)
                }

                // read file data
                let data: Data = try! Data(contentsOf: currentURL)
                let parser: XMLParser = XMLParser(data: data)

                parser.shouldResolveExternalEntities = false
                parser.delegate = self

                // parse the file
                let successs: Bool = parser.parse()

                // report errors
                if (successs == false) {
                    let parseError = parser.parserError
                    let errorLine = parser.lineNumber
                    let errorCol = parser.columnNumber

                    let errorDescription = parseError!.localizedDescription
                    Logger.default.log("\(parsingMode) parser: \(errorDescription) at line \(errorLine), column \(errorCol)", level: .error, symbol: self.logSymbol)
                }
            }
        }

        renderQueue.sync {
            for filename in tsxFiles {
                for (tsxurl, tileset) in tilesets {
                    let basename = tsxurl.path.components(separatedBy: ".").first!
                    if (basename == filename) || (tsxurl.path == filename) {
                        tilesetResults.append(tileset)
                    }
                }
            }
        }

        return tilesetResults
    }

    // MARK: - Post-Processing

    /// Post-process to render all of the layers in the map.
    ///
    /// - Parameters:
    ///   - tilemap: tile map node.
    ///   - queue: external queue.
    ///   - duration: fade-in time for each layer.
    fileprivate func didBeginRendering(_ tilemap: SKTilemap, queue: DispatchQueue, duration: TimeInterval = 0.025) {

        // loop through the layers
        for layer in tilemap.getLayers(recursive: true) {

            // assign each layer a work item
            let renderItem = DispatchWorkItem {

                // Render object groups.
                if let objectGroup = layer as? SKObjectGroup {
                    objectGroup.draw()
                }

                // Render tile layers.
                if let tileLayer = layer as? SKTileLayer {

                    switch self.canvasType {

                        case .infinite:
                            for chunk in tileLayer.chunks {
                                // get stashed tile data
                                if let chunkTileData = self.layerTileData[chunk.uuid] {
                                    // add the layer data
                                    if (chunk.setLayerData(chunkTileData) == false) {
                                        self.log("layer chunk '\(chunk.name ?? "unknown chunk")' failed to set data.", level: .warning)
                                    }
                                }
                            }


                        default:

                            // get stashed tile data
                            if let tileData = self.layerTileData[tileLayer.uuid] {
                                // add the layer data
                                if (tileLayer.setLayerData(tileData) == false) {
                                    self.log("layer '\(tileLayer.layerName)' failed to set data.", level: .warning)
                                }
                            }

                            // report errors but don't throw
                            if (tileLayer.gidErrors.isEmpty == false) {
                                let errorString = tileLayer.gidErrors.reduce("") { aggregate, item -> String in
                                    return aggregate + "\(item.value) [\(item.key.x),\(item.key.y)], "
                                }.dropLast(2)
                                Logger.default.log("layer '\(tileLayer.layerName)': the following gids could not be found: \(errorString)", level: .warning, symbol: self.logSymbol)
                        }
                    }
                }

                // run the layer callback on the parser queue
                self.parsingQueue.sync {
                    layer.didFinishRendering(duration: duration)
                }
            }

            // add the layer render work item to the external queue
            queue.async(group: renderGroup, execute: renderItem)
        }

        // run callbacks when the group is finished
        renderGroup.notify(queue: DispatchQueue.main) {
            self.layerTileData = [:]
            self.tilesets = [:]
        }

        // sync external queue here
        queue.sync {
            self.tilemap?.didFinishRendering(timeStarted: self.timer)
        }
    }


    // MARK: - Helpers

    /// Ascertain the document root for the given file. Generally, the bundle url. Sets the `documentRoot` property.
    ///
    /// - Parameters:
    ///   - tmxFile: tiled file name.
    ///   - assetPath: optional asset (root) path.
    internal func resolveDocumentRoot(tmxFile: String, assetPath: String?) {
        // if the tmxFile string represents a full path, use that & return
        let absTmxUrl = URL(fileURLWithPath: tmxFile).standardized

        // if the user passes a full path, just parse it
        if (FileManager.default.fileExists(atPath: absTmxUrl.path) == true) {
            documentRoot = absTmxUrl.deletingLastPathComponent()
            currentFilename = absTmxUrl.lastPathComponent
            return
        }

        // the default is the bundle resource path
        if let bundleResourceUrl = Bundle.main.resourceURL {
            documentRoot = bundleResourceUrl
        }

        // if the tmxFile string represents a relative path...

        /// ...check the `assetPath`...
        if let assetPath = assetPath {

            /// if the `assetPath` string is a path that exists, assume that's the document root
            var assetPathExists : ObjCBool = false
            if (FileManager.default.fileExists(atPath: assetPath, isDirectory: &assetPathExists) == true) {
                documentRoot = URL(fileURLWithPath: assetPath).standardized

            /// otherwise, the `assetPath` string may refer to a search path (ie: `User`), so we
            /// should append it to the existing `documentRoot` property
            } else {
                let bundledAssetUrl = documentRoot.appendingPathComponent(assetPath)
                var bundledAssetPathExists : ObjCBool = false
                if (FileManager.default.fileExists(atPath: bundledAssetUrl.path, isDirectory: &bundledAssetPathExists) == true) {
                    documentRoot = bundledAssetUrl
                }
            }
        }

        // now that the document root is taken care of, let's look at the fmx file name...
        var tmxUrlExists : ObjCBool = false
        let relTmxUrl = documentRoot.appendingPathComponent(tmxFile).standardized

        if (FileManager.default.fileExists(atPath: relTmxUrl.path, isDirectory: &tmxUrlExists) == true) {
            documentRoot = relTmxUrl.deletingLastPathComponent()
            currentFilename = relTmxUrl.lastPathComponent
            /// set the tilemap url
            tilemapUrl = relTmxUrl
        }
    }

    /// Returns true if the file exists on disk.
    ///
    /// - Parameter url: file url.
    /// - Returns: file exists.
    internal func fileExists(at url: URL) -> Bool {
        // check that file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        return true
    }

    // MARK: - Element Start


    internal func parser(_ parser: XMLParser,
                         didStartElement elementName: String,
                         namespaceURI: String?,
                         qualifiedName qName: String?,
                         attributes attributeDict: [String: String]) {

        activeElement = elementName


        if (elementName == "map") {

            // create the tilemap
            guard let tilemap = SKTilemap(attributes: attributeDict) else {
                log("invalid tilemap attributes.", level: .fatal)
                parser.abortParsing()
                return
            }

            // set global logging level
            tilemap.loggingLevel = self.loggingLevel
            tilemap.updateMode = self.tileUpdateMode


            log("tilemap update mode: '\(tilemap.updateMode.name)'", level: .debug)

            // initialize cache
            tilemap.dataStorage = TileDataStorage(map: tilemap)
            tilemap.receiveCameraUpdates = TiledGlobals.default.enableCameraCallbacks

            // initialize notifications
            tilemap.setupNotifications()
            tilemap.ignoreProperties = self.ignoreProperties
            tilemap.delegate = self.tilemapDelegate

            // set the tilemap url property
            if (currentFilename != nil) {
                tilemap.url = URL(fileURLWithPath: currentFilename).standardized
                tilemap.fileUrl = currentFileUrl
            }

            if let tiledVersion = tilemap.tiledversion {
                log("Tiled map version: \(tiledVersion)", level: .debug)
            }

            if let tilemapDelegate = self.tilemapDelegate {
                tilemap.zDeltaForLayers = tilemapDelegate.zDeltaForLayers ?? TiledGlobals.default.zDeltaForLayers
            }

            // get the filename to use as the map name
            if (currentFilename != nil) {
                let currentFile = currentFilename.url.lastPathComponent
                let currentBasename = currentFile.components(separatedBy: ".").first!

                // `SKTilemap.name` represents the tmx filename (minus .tmx extension)
                tilemap.name = currentBasename
                tilemap.displayName = currentBasename
            }

            // run setup functions on tilemap
            self.tilemapDelegate?.didBeginParsing?(tilemap)

            lastElement = tilemap
            elements.push(tilemap)


            elementPath.append(tilemap)
            self.tilemap = tilemap


            // Set the current map type
            self.canvasType = (tilemap.isInfinite == true) ? .infinite : .default
        }

        // external will have a 'source' attribute, otherwise 'image'
        if (elementName == "tileset") {

            /* inline declaration in tmx:    <tileset firstgid="1" name="ortho4-16x16" tilewidth="16" tileheight="16" tilecount="552" columns="23"> */
            /* external declaration in tmx:  <tileset firstgid="1" source="roguelike-16x16.tsx"/> */
            /* reading external tsx:         <tileset name="roguelike-16x16" tilewidth="16" tileheight="16" spacing="1" tilecount="1938" columns="57">*/


            // reading tmx/tx, external tileset reference
            if let source = attributeDict["source"] {

                // get the first gid attribute
                guard let firstgid = attributeDict["firstgid"] else {
                    log("external tileset reference '\(source)' needs a 'firstgid' attribute", level: .fatal)
                    parser.abortParsing()
                    return
                }

                let firstGID = UInt32(firstgid)!

                // check to see if tileset already exists (either an empty new tileset, or we've passed a pre-loaded tileset).
                let externalTilesetUrl = URL(fileURLWithPath: source, relativeTo: documentRoot).standardized

                if let existingTileset = tilesets[externalTilesetUrl] {

                    // if we're in tilemap parsing mode, add the tileset to the map
                    if (parsingMode == .tmx) {

                        // add the tileset
                        self.tilemap?.addTileset(existingTileset)

                        // set the first gid parameter
                        existingTileset.firstGID = firstGID

                        lastElement = existingTileset

                        // set this to nil, just in case we're looking for a collections tileset.
                        currentID = nil

                    // we're in a template
                    } else {

                        // set the current tileset
                        activeTemplateTileset = existingTileset
                    }

                } else {

                    // new tileset reference, in tmx file
                    if !(externalFileUrls.contains(externalTilesetUrl)) {

                        // append the source path to parse queue
                        let tilesetFileURL = URL(fileURLWithPath: source, relativeTo: documentRoot).standardized

                        // check that file exists
                        guard self.fileExists(at: tilesetFileURL) else {
                            log("tileset file not found: '\(tilesetFileURL.lastPathComponent)'.", level: .fatal)
                            parser.abortParsing()
                            return
                        }

                        externalFileUrls.append(tilesetFileURL)

                        guard let tilemap = tilemap else {
                            log("cannot access tilemap instance.", level: .fatal)
                            parser.abortParsing()
                            return
                        }

                        // create a new tileset
                        let tileset = SKTileset(source: source, firstgid: firstGID, tilemap: tilemap)
                        tileset.loggingLevel = self.loggingLevel
                        tileset.ignoreProperties = self.ignoreProperties
                        tileset.url = tilesetFileURL

                        // add tileset to external file list (full file name)
                        tilesets[externalTilesetUrl] = tileset
                        parsedTilesetUrls.append(externalTilesetUrl)

                        // add the tileset to the tilemap
                        self.tilemap?.addTileset(tileset)
                        lastElement = tileset

                        // set this to nil, just in case we're looking for a collections tileset.
                        currentID = nil
                    }
                }
            }

            // inline tileset in TMX, or the current file **is** a tileset
            if let name = attributeDict["name"] {

                // update an existing tileset ( to set properties like `name`)
                let currentUrl = URL(fileURLWithPath: currentFilename, relativeTo: documentRoot).standardized

                if let existingTileset = tilesets[currentUrl] {

                    guard let width = attributeDict["tilewidth"] else {
                        parser.abortParsing()
                        return
                    }

                    guard let height = attributeDict["tileheight"] else {
                        parser.abortParsing()
                        return
                    }

                    existingTileset.name = name
                    existingTileset.tileSize = CGSize(width: CGFloat(Int(width)!), height: CGFloat(Int(height)!))

                    // optionals
                    if let columns = attributeDict["columns"] {
                         existingTileset.columns = Int(columns)!
                    }

                    if let spacing = attributeDict["spacing"] {
                        existingTileset.spacing = Int(spacing)!
                    }

                    if let margin = attributeDict["margin"] {
                        existingTileset.margin = Int(margin)!
                    }

                    lastElement = existingTileset

                } else {
                    // create inline tileset
                    guard let tileset = SKTileset(attributes: attributeDict) else {
                        log("could not initialize tileset.", level: .fatal)
                        parser.abortParsing()
                        return
                    }

                    tileset.loggingLevel = self.loggingLevel
                    tileset.ignoreProperties = self.ignoreProperties

                    // add the tileset to the tilemap (if it exists)
                    self.tilemap?.addTileset(tileset)

                    lastElement = tileset

                    // set this to nil, just in case we're looking for a collections tileset.
                    currentID = nil

                    if (parsingMode == .tsx) {
                        guard let currentFilename = currentFilename else {
                            fatalError("Cannot add a tileset without a filename.")
                        }

                        let tilesetUrl = URL(fileURLWithPath: currentFilename, relativeTo: documentRoot).standardized
                        tileset.filename = currentFilename
                        tilesets[tilesetUrl] = tileset
                        parsedTilesetUrls.append(tilesetUrl)
                    }
                }
            }
        }

        // draw offset for tilesets
        if elementName == "tileoffset" {
            guard let offsetx = attributeDict["x"] else {
                log("tile offset element requires an 'x' value", level: .error)
                parser.abortParsing()
                return
            }


            guard let offsety = attributeDict["y"] else {
                log("tile offset element requires an 'y' value", level: .error)
                parser.abortParsing()
                return
            }

            if let tileset = lastElement as? SKTileset {
                tileset.tileOffset = CGPoint(x: Int(offsetx)!, y: Int(offsety)!)
            }
        }

        if elementName == "property" {
            guard let name = attributeDict["name"] else {
                log("property element requires a name", level: .error)
                parser.abortParsing()
                return
            }

            guard let value = attributeDict["value"] else {
                log("property element requires a value", level: .error)
                parser.abortParsing()
                return
            }

            // stash properties
            properties[name] = value
        }

        // 'layer' element indicates a tile layer
        if (elementName == "layer") {

            guard let layer = SKTileLayer(tilemap: self.tilemap!, attributes: attributeDict) else {
                let layerName = attributeDict["name"] ?? "null"
                log("Error creating tile layer '\(layerName)'", level: .fatal)
                    parser.abortParsing()
                    return
            }

            let parentElement = elementPath.last!
            if let group = parentElement as? SKGroupLayer {
                group.addLayer(layer)
                layer.rawIndex = layerIndex
                layerIndex += 1
            }

            if let tilemap = parentElement as? SKTilemap {
                tilemap.addLayer(layer)
                layer.rawIndex = layerIndex
                layerIndex += 1
            }


            lastElement = layer
            lastTileLayer = layer
        }

        // Tile layer chunk (infinite mode)
        if (elementName == "chunk") {

            if (self.tilemap?.chunkSize == nil) {

            }

            guard let tileLayer = lastTileLayer else {
                log("Cannot create a chunk without a parent layer, (last: '\(lastElementString)').", level: .fatal)
                parser.abortParsing()
                return
            }

            guard let layerChunk = SKTileLayerChunk(layer: tileLayer, attributes: attributeDict) else {
                let chunkName = attributeDict["name"] ?? "null"
                log("Error creating tile layer chunk: '\(chunkName)'", level: .fatal)
                parser.abortParsing()
                return
            }


            if let currentMap = self.tilemap {
                if (currentMap.chunkSize == nil) {
                    currentMap.chunkSize = layerChunk.chunkSize
                }
            }

            tileLayer.addChunk(layerChunk, at: CGPoint.zero)
            lastElement = layerChunk
        }


        // 'objectgroup' indicates an object layer or tile collision object
        if (elementName == "objectgroup") {

            // if tileset is last element and currentID exists....
            if let tileset = lastElement as? SKTileset {

                if let currentID = currentID {

                    // get the global id
                    let tileGid = tileset.firstGID + currentID

                    // query tile data for the given objects
                    if let _ = tileset.getTileData(globalID: tileGid) {}
                }

            // create a new object group...
            } else {

                guard let objectsGroup = SKObjectGroup(tilemap: self.tilemap!, attributes: attributeDict) else {
                    let layerName = attributeDict["name"] ?? "null"
                    log("Error creating object layer: '\(layerName)'", level: .fatal)
                        parser.abortParsing()
                        return
                }

                let parentElement = elementPath.last!

                if let group = parentElement as? SKGroupLayer {
                    group.addLayer(objectsGroup)
                    objectsGroup.rawIndex = layerIndex
                    layerIndex += 1
                }

                if let tilemap = parentElement as? SKTilemap {
                    tilemap.addLayer(objectsGroup)
                    objectsGroup.rawIndex = layerIndex
                    layerIndex += 1
                }

                lastElement = objectsGroup
            }
        }

        // 'imagelayer' indicates an Image layer
        if (elementName == "imagelayer") {

            guard let imageLayer = SKImageLayer(tilemap: self.tilemap!, attributes: attributeDict) else {
                let layerName = attributeDict["name"] ?? "null"
                log("Error creating image layer: '\(layerName)'", level: .fatal)
                    parser.abortParsing()
                    return
            }

            let parentElement = elementPath.last!
            if let group = parentElement as? SKGroupLayer {
                group.addLayer(imageLayer)
                imageLayer.rawIndex = layerIndex
                layerIndex += 1
            }

            if let tilemap = parentElement as? SKTilemap {
                tilemap.addLayer(imageLayer)
                imageLayer.rawIndex = layerIndex
                layerIndex += 1
            }


            lastElement = imageLayer
        }

        // 'group' indicates a Group layer
        if (elementName == "group") {

            guard let groupLayer = SKGroupLayer(tilemap: self.tilemap!, attributes: attributeDict) else {
                    log("error parsing group layer.", level: .fatal)
                    parser.abortParsing()
                    return
            }

            let parentElement = elementPath.last!
            if let group = parentElement as? SKGroupLayer {
                group.addLayer(groupLayer)
                groupLayer.rawIndex = layerIndex
                layerIndex += 1
            }

            if let tilemap = parentElement as? SKTilemap {
                tilemap.addLayer(groupLayer)
                groupLayer.rawIndex = layerIndex
                layerIndex += 1
            }

            // delegate callback
            parsingQueue.sync {
                self.tilemapDelegate?.didAddLayer?(groupLayer)
            }

            elementPath.append(groupLayer)
            lastElement = groupLayer
        }

        // look for last element to be a tileset or imagelayer
        if (elementName == "image") {

            guard attributeDict["width"] != nil,
                  attributeDict["height"] != nil,
                  let sourceImageName = attributeDict["source"] else {
                fatalError("source image error: \(attributeDict)")
            }

            // image resources might be store in the xcassets catalog.
            let imageURL = URL(fileURLWithPath: sourceImageName, isDirectory: false, relativeTo: documentRoot).standardized

            // get the absolute path to the image
            var sourceImagePath = imageURL.path

            // update an image layer
            if let imageLayer = lastElement as? SKImageLayer {
                // set the image property
                imageLayer.setLayerImage(sourceImagePath)
            }

            // update a tileset
            if let tileset = lastElement as? SKTileset {

                // If `currentID` == nil, image is a spritesheet so look for lastElement to be a tileset,
                // otherwise, the image is part of a collections tileset.
                if let currentID = currentID {

                    if let imagePath = self.tilesetDataSource?.willAddImage(to: tileset, forId: currentID, fileNamed: sourceImagePath) {
                        let replacementImagePath = URL(fileURLWithPath: imagePath, isDirectory: false, relativeTo: documentRoot).standardized
                        sourceImagePath = replacementImagePath.path
                    }

                    // add an image property to the tileset collection
                    let tileData = tileset.addTilesetTile(tileID: currentID, source: sourceImagePath)
                    tilesetImagesAdded += 1
                    if (tileData == nil) {
                        log("\(parsingMode) parser: tile id \(currentID) is invalid.", level: .warning)
                    }

                } else {
                    // parse tileset properties
                    tileset.parseProperties(completion: nil)

                    // query data source delegate for source image substitution
                    if let imagePath = self.tilesetDataSource?.willAddSpriteSheet(to: tileset, fileNamed: sourceImagePath) {
                        let replacementImagePath = URL(fileURLWithPath: imagePath, isDirectory: false, relativeTo: documentRoot).standardized
                        sourceImagePath = replacementImagePath.path
                    }

                    // add the tileset spritesheet image
                    tileset.addTextures(fromSpriteSheet: sourceImagePath, replace: false, transparent: attributeDict["trans"])


                    // delegate callback
                    parsingQueue.sync {
                        tileset.setupAnimatedTileData()
                        self.tilemapDelegate?.didAddTileset?(tileset)
                    }
                }
            }
        }

        // `tile` is used to flag properties in a tileset, as well as store tile layer data in an XML-formatted map.
        if elementName == "tile" {

            /*
              XML layer data is stored with a `tile` tag and `gid` atribute. No other attributes will be present:

                <tile gid="0"/>
            */
            if let gid = attributeDict["gid"] {
                let intValue = Int(gid)!
                // just append this to the tileData property
                if (encoding == .xml) {
                    tileData.append(UInt32(intValue))
                }
            }

            // otherwise, we're adding data to a tileset. Attributes can be `type` and `probability`.
            else if let id = attributeDict["id"] {

                let intValue = UInt32(id)!
                currentID = intValue


                // optional tile attributes
                if let tileType = attributeDict["type"] {
                    currentType = tileType
                }

                if let tileProbabilty = attributeDict["probability"] {
                    if let doubleValue = Double(tileProbabilty) {
                        currentProbability = CGFloat(doubleValue)
                    }
                }

            } else {
                log("id not found.", level: .fatal)
                parser.abortParsing()
                return
            }
        }

        // look for last element to be an object group
        // id, x, y required
        if (elementName == "object") {


            // We're parsing object data from inside a template file. This updates the last `templateObjects` object with attributes.
            if (parsingMode == .tx) {

                // get last object saved to the templates group (already assigned to an objects group node)
                if let currentObject = templateObjects.popLast() {

                    /// if the object already has a gid value, it's global and we can ignore parsing from the template
                    let templateObjectHasTileId = (currentObject.globalID != nil)

                    var templateGid: UInt32?
                    if let templateGidValue = attributeDict["gid"] {
                        templateGid = UInt32(templateGidValue)
                    }

                    if (templateObjectHasTileId == false) {
                        if let templateGlobalId = templateGid {

                            // get the current tileset
                            guard let templateTileset = activeTemplateTileset else {

                                // TODO: throw here
                                log("no active tileset for this template.", level: .error)
                                return
                            }

                            let globalIdWithFlags = flippedTileFlags(id: templateGlobalId)
                            let unmaskedGlobalId = globalIdWithFlags.globalID

                            let hFlip = globalIdWithFlags.hflip
                            let vFlip = globalIdWithFlags.vflip
                            let dFlip = globalIdWithFlags.dflip

                            let templateTilesetFirstGid = templateTileset.firstGID
                            let actualGid = (unmaskedGlobalId + templateTilesetFirstGid) - 1


                            let remaskedGlobalId = maskedGlobalId(globalID: actualGid, hflip: hFlip, vflip: vFlip, dflip: dFlip)

                            currentObject.globalID = remaskedGlobalId
                            currentObject.initialProperties["gid"] = "\(remaskedGlobalId)"

                        }
                    }

                    // update the referencing object with attributes from the template file. If any of these attributes are different than the initial attributes, we need to keep the initial values as template values might be overwritten on the object node (ie. if a tile GID is flipped from the template).
                    currentObject.setObjectAttributesFromTemplateAttributes(attributes: attributeDict)
                    currentObject.visible = (currentObject.globalID != nil)


                    // set the last object
                    lastElement = currentObject
                }


            // object in a tmx file
            } else {


                guard let tilemap = tilemap else {
                    log("could not access tilemap.", level: .fatal)
                    parser.abortParsing()
                    return
                }

                // adding a group to object layer
                if let objectGroup = lastElement as? SKObjectGroup {

                    let Object = (tilemap.delegate != nil) ? tilemap.delegate!.objectForVectorType?(named: attributeDict["type"]) ?? SKTileObject.self : SKTileObject.self


                    guard let tileObject = Object.init(attributes: attributeDict) else {
                        log("\(parsingMode) parser: Error creating object.", level: .fatal)
                        parser.abortParsing()
                        return
                    }

                    #if os(macOS)
                    tileObject.onMouseOver = (tilemap.delegate != nil) ? tilemap.delegate!.mouseOverObjectHandler?(withID: tileObject.id, ofType: tileObject.type) : nil
                    tileObject.onMouseClick = (tilemap.delegate != nil) ? tilemap.delegate!.objectClickedHandler?(withID: tileObject.id, ofType: tileObject.type, button: 0) : nil

                    #elseif os(iOS)
                    tileObject.onTouch = (tilemap.delegate != nil) ? tilemap.delegate!.objectTouchedHandler?(withID: tileObject.id, ofType: tileObject.type, userData: nil) : nil

                    #endif


                    // set the initial properties here
                    tileObject.initialProperties = attributeDict


                    // add the object to the layer
                    _ = objectGroup.addObject(tileObject)

                    // stash the object id
                    currentID = tileObject.id

                    // if the object has a `template` attribute, stash it for later update
                    if let templateFile = tileObject.template {
                        let templateURL = URL(fileURLWithPath: templateFile, relativeTo: documentRoot).standardized

                        externalFileUrls.append(templateURL)
                        tileObject.isInitialized = false

                        // add the templated object to the stack
                        templateObjects.insert(tileObject, at: 0)
                    }
                }
            }
        }

        // special case - look for last element to be a object
        // this signifies that the object should be an ellipse
        if (elementName == "ellipse") {
            if let objectsgroup = lastElement as? SKObjectGroup {
                if (currentID != nil) {
                    if let currentObject = objectsgroup.getObject(withID: currentID!) {
                        currentObject.shapeType = .ellipse
                    }
                }
            }
        }

        if (elementName == "polygon") {

            // polygon object
            if let pointsString = attributeDict["points"] {
                var coordinates: [[CGFloat]] = []
                let points = pointsString.components(separatedBy: " ")
                for point in points {
                    let coords = point.components(separatedBy: ",").compactMap { x in Double(x) }
                    coordinates.append(coords.compactMap { CGFloat($0) })
                }


                if let objectsgroup = lastElement as? SKObjectGroup {
                    if (currentID != nil) {
                        if let currentObject = objectsgroup.getObject(withID: currentID!) {
                            currentObject.addPoints(coordinates)
                        }
                    }
                }
            }
        }

        if (elementName == "polyline") {
            // polygon object
            if let pointsString = attributeDict["points"] {
                var coordinates: [[CGFloat]] = []
                let points = pointsString.components(separatedBy: " ")
                for point in points {
                    let coords = point.components(separatedBy: ",").compactMap { x in Double(x) }
                    coordinates.append(coords.compactMap { CGFloat($0) })
                }


                if let objectGroup = lastElement as? SKObjectGroup {
                    if (currentID != nil) {
                        if let currentObject = objectGroup.getObject(withID: currentID!) {
                            currentObject.addPoints(coordinates, closed: false)
                        }
                    }
                }
            }
        }

        // point object
        if (elementName == "point") {
            if let objectGroup = lastElement as? SKObjectGroup {
                if (currentID != nil) {
                    if let currentObject = objectGroup.getObject(withID: currentID!) {
                        currentObject.objectType = .point
                    }
                }
            }
        }


        // animated tiles
        if (elementName == "frame") {
            guard let currentID = currentID else {
                // TODO: throw here
                log("\(parsingMode) parser: cannot assign frame animation information without tile id.", level: .fatal)
                parser.abortParsing()
                return
            }

            guard let id = attributeDict["tileid"],
                let duration = attributeDict["duration"], Int(duration) != nil,
                let tileset = lastElement as? SKTileset else {
                    parser.abortParsing()
                    return
            }


            if let currentTileData = tileset.getTileData(globalID: currentID + tileset.firstGID) {

                // add the frame id to the frames property
                let animationFrame = currentTileData.addFrame(withID: UInt32(id)! + tileset.firstGID, interval: Int(duration)!)

                // set the texture for the frame
                if let frameData = tileset.getTileData(localID: animationFrame.id) {
                    if let frameTexture = frameData.texture {
                        animationFrame.texture = frameTexture
                    }
                }
            }
        }

        // text object attributes
        if (elementName == "text") {

            if let objectGroup = lastElement as? SKObjectGroup {
                if (currentID != nil) {
                    if let currentObject = objectGroup.getObject(withID: currentID!) {
                        // basic text attributes
                        let fontName: String = (attributeDict["fontfamily"] != nil) ? attributeDict["fontfamily"]! : "system"
                        let fontSize: CGFloat = (attributeDict["pixelsize"] != nil) ? CGFloat(Int(attributeDict["pixelsize"]!)!) : 16  // was 12
                        let fontColor: SKColor = (attributeDict["color"] != nil) ? SKColor(hexString: attributeDict["color"]!) : .black

                        // create text attributes
                        currentObject.textAttributes = TextObjectAttributes(font: fontName, size: fontSize, color: fontColor)
                        currentObject.visible = true

                        if let bold = attributeDict["bold"] {
                            currentObject.textAttributes.isBold = (bold == "1")
                        }

                        if let italic = attributeDict["italic"] {
                            currentObject.textAttributes.isItalic = (italic == "1")
                        }

                        if let underline = attributeDict["underline"] {
                            currentObject.textAttributes.isUnderline = (underline == "1")
                        }

                        if let strikeout = attributeDict["strikeout"] {
                            currentObject.textAttributes.isStrikeout = (strikeout == "1")
                        }

                        if let textWrap = attributeDict["wrap"] {
                            currentObject.textAttributes.wrap = (textWrap == "1")
                        }

                        // alignment
                        if let halign = attributeDict["halign"] {
                            if let halignment = TextObjectAttributes.TextAlignment.HoriztonalAlignment(rawValue: halign) {
                                currentObject.textAttributes.alignment.horizontal = halignment
                            }
                        }

                        if let valign = attributeDict["valign"] {
                            if let valignment = TextObjectAttributes.TextAlignment.VerticalAlignment(rawValue: valign) {
                                currentObject.textAttributes.alignment.vertical = valignment
                            }
                        }
                    }
                }
            }
        }

        // decode data here, and reset
        if (elementName == "data") {
            // get the encoding...
            if let encoding = attributeDict["encoding"] {
                self.encoding = TilemapEncoding(rawValue: encoding)!
            }

            // compression algorithms
            if let ctype = attributeDict["compression"] {

                guard let compression = TilemapCompression(rawValue: ctype) else {
                    let fn = currentFilename ?? "unknwon"
                    log("invalid compression type '\(ctype)' found at line \(parser.lineNumber) in '\(fn)'", level: .fatal)
                    parser.abortParsing()
                    return
                }

                self.compression = compression
            }
        }
    }

    // MARK: - Element End

    // Runs when parser ends a key: </key>
    internal func parser(_ parser: XMLParser,
                         didEndElement elementName: String,
                         namespaceURI: String?,
                         qualifiedName qName: String?) {





        // look for last element to add properties to
        if elementName == "properties" {

            /// The expected node type.
            let nodeType = properties["type"]

            /// Append custom properties from delegate.
            if let customProperties = tilemapDelegate?.attributesForNodes?(ofType: nodeType, named: nil, globalIDs: []) {
                for (key, value) in customProperties {
                    properties[key] = value
                }
            }

            // TODO: this can be reduced if we simply query the object as `TiledAttributedType`


            // tilemap properties
            if let tilemap = lastElement as? SKTilemap {
                for (key, value) in properties {
                    tilemap.properties[key] = value
                }

                tilemap.parseProperties(completion: nil)
            }

            // layer properties
            if let layer = lastElement as? TiledLayerObject {
                if (currentID == nil) {
                    for (key, value) in properties {
                        layer.properties[key] = value
                    }
                }

                layer.parseProperties(completion: nil)
            }

            // tileset properties
            if let tileset = lastElement as? SKTileset {

                // no current id, the properties are for the tileset
                if (currentID == nil) {
                    tileset.properties = properties
                    tileset.parseProperties(completion: nil)

                // if current id is set, add the properties to the appropriate tile data
                } else {

                    let globalId = tileset.firstGID + currentID!

                    if let tileData = tileset.getTileData(globalID: globalId) {
                        for (key, value) in properties {
                            tileData.properties[key] = value
                        }

                        tileData.parseProperties(completion: nil)

                        // add custom properties from the delegate
                        if let customProperties = self.tilemapDelegate?.attributesForNodes?(ofType: nodeType, named: tileData.name, globalIDs: [globalId]) {
                            for (attr, value) in customProperties {
                                tileData.properties[attr] = value
                            }
                        }

                        properties = [:]
                    }
                }
            }

            // clear if no last ID
            if (currentID == nil) {
                properties = [:]
            }
        }


        // Tile layer chunk (infinite mode)
        if (elementName == "chunk") {
            guard let layerChunk = lastElement as? SKTileLayerChunk else {
                log("error parsing chunk.", level: .fatal)
                parser.abortParsing()
                return
            }


            var foundData = false

            // decode Base64 encoded strings
            if (encoding == .base64) {
                foundData = true

                if let dataArray = decode(base64String: characterData, compression: self.compression) {
                    for id in dataArray {
                        tileData.append(id)
                    }
                }

            }

            if (encoding == .csv) {
                foundData = true
                let dataArray = decode(csvString: characterData)
                for id in dataArray {
                    tileData.append(id)
                }

            }

            if (encoding == .xml) {
                foundData = true
            }

            // write data to buffer
            if (foundData == true) {
                layerTileData[layerChunk.uuid] = tileData

            } else {
                log("error adding tile data.", level: .fatal)
                parser.abortParsing()
                return
            }

            // Reset tile gid array
            tileData = []
        }


        // In default mode, the last element should be a Tile Layer. In infinite mode, the last element is a Chunk.
        if (elementName == "data") {

            guard let tileContainer = lastElement as? TileContainerType else {
                log("\(parsingMode) parser: cannot find container to add data.", level: .fatal)
                parser.abortParsing()
                return
            }

            // In default mode, decode the tile data and add it to the layer
            if canvasType == .default {
                guard let tileLayer = tileContainer as? SKTileLayer else {
                    log("cannot add layer data to node type '\(lastElementString)'", level: .fatal)
                    parser.abortParsing()
                    return
                }


                var foundData = false

                // decode Base64 encoded strings
                if (encoding == .base64) {
                    foundData = true

                    if let dataArray = decode(base64String: characterData, compression: self.compression) {
                        for id in dataArray {
                            tileData.append(id)
                        }
                    }
                }

                if (encoding == .csv) {
                    foundData = true
                    let dataArray = decode(csvString: characterData)
                    for id in dataArray {
                        tileData.append(id)
                    }
                }

                if (encoding == .xml) {
                    foundData = true
                }

                // write data to buffer
                if (foundData == true) {
                    layerTileData[tileLayer.uuid] = tileData

                } else {
                    log("error adding tile data.", level: .fatal)
                    parser.abortParsing()
                    return
                }

                // Reset tile gid array
                tileData = []
            }

        }

        // look for the last element to be tileset
        if (elementName == "tile") {
            // parse properties
            if let tileset = lastElement as? SKTileset {
                if (currentID != nil) {

                    let tileID = tileset.firstGID + currentID!
                    if let tileData = tileset.getTileData(globalID: tileID) {

                        for (key, value) in properties {
                            tileData.properties[key] = value
                        }

                        properties = [:]

                        // set the type attribute for the tile data
                        if let currentType = currentType {
                            tileData.type = currentType
                        }

                        // set the probability attribute for the tile data
                        if let currentProbability = currentProbability {
                            tileData.probability = currentProbability
                        }
                    }
                }
            }

            // we're no longer adding attributes to a tile, so unset tile properties
            currentID = nil
            currentType = nil
            currentProbability = nil
        }

        // add properties to last object
        if (elementName == "object") {

            // if we're dealing with an object in an object layer....
            if let objectsgroup = lastElement as? SKObjectGroup {
                if (currentID != nil) {
                    if let lastObject = objectsgroup.getObject(withID: currentID!) {

                        for (key, value) in properties {
                            lastObject.properties[key] = value
                        }

                        lastObject.parseProperties(completion: nil)
                        properties = [:]


                        if (lastObject.globalID != nil) {
                           // get tileset properties for template
                        }
                    }
                    currentID = nil
                }
            }

            // if we're dealing with a tile collision object...
            if (lastElement as? SKTileset) != nil {
                //currentID = nil
            }
        }


        if (elementName == "layer") {

            if let tileLayer = lastElement as? SKTileLayer {

                // delegate callback
                parsingQueue.sync {
                    self.tilemapDelegate?.didAddLayer?(tileLayer)
                }
            }

            lastTileLayer = nil
        }

        if (elementName == "objectgroup") {
            if let objectGroup = lastElement as? SKObjectGroup {
                // delegate callback
                parsingQueue.sync {
                    self.tilemapDelegate?.didAddLayer?(objectGroup)
                }
            }
        }

        if (elementName == "imagelayer") {
            if let imageLayer = lastElement as? SKImageLayer {
                // delegate callback
                parsingQueue.sync {
                    self.tilemapDelegate?.didAddLayer?(imageLayer)
                }
            }
        }

        if (elementName == "group") {
            if let groupLayer = lastElement as? SKGroupLayer {
                // delegate callback
                parsingQueue.sync {
                    self.tilemapDelegate?.didAddLayer?(groupLayer)
                }
            }

            // if we're closing a group layer, pop it from the element path
            _ = elementPath.popLast()
            lastElement = nil
        }

        // text object text
        if (elementName == "text") {
            if let objectGroup = lastElement as? SKObjectGroup {
                if (currentID != nil) {
                    if let currentObject = objectGroup.getObject(withID: currentID!) {
                        // set the object's text attribute
                        currentObject.text = characterData.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }

        // embedded tileset only
        if (elementName == "tileset") {

            if tilesetImagesAdded > 0 {
                if let tileset = lastElement as? SKTileset {
                    Logger.default.log("tileset '\(tileset.name)' finished, \(tilesetImagesAdded) images added.", level: .debug, symbol: self.logSymbol)
                    tileset.isRendered = true

                    // delegate callback
                    parsingQueue.sync {
                        tileset.setupAnimatedTileData()
                        self.tilemapDelegate?.didAddTileset?(tileset)
                    }
                }
                tilesetImagesAdded = 0
            }

            // important to close this here!!
            lastElement = nil
        }

        // indicates we're reading a template, and now at the end.
        if (elementName == "template") {

            if let currentObject = lastElement as? SKTileObject {
                currentObject.isInitialized = true
            }

            lastElement = nil
            activeTemplateTileset = nil
        }


        // reset character data
        characterData = ""
        activeElement = nil
    }

    internal func parser(_ parser: XMLParser, foundCharacters string: String) {
        // append data attribute
        characterData += string
    }

    // MARK: - Decoding

    /// Scrub CSV data.
    ///
    /// - Parameter data: data to decode.
    /// - Returns: parsed CSV data.
    fileprivate func decode(csvString data: String) -> [UInt32] {
        if data.isEmpty {
            return []
        }
        return data.scrub().components(separatedBy: ",").map {UInt32($0)!}
    }

    /// Decode Base64-formatted data.
    ///
    /// - Parameters:
    ///   - data: Base64-formatted data to decode
    ///   - compression: compression type.
    /// - Returns: parsed data.
    fileprivate func decode(base64String data: String,
                            compression: TilemapCompression = .uncompressed) -> [UInt32]? {

        guard let decodedData = Data(base64Encoded: data, options: .ignoreUnknownCharacters) else {
            log("data is not base64 encoded.", level: .error)
            return nil
        }

        switch compression {
        case .zlib, .gzip:
            if let decompressed = try? decodedData.gunzipped() {
                return decompressed.toArray(type: UInt32.self)
            }
        case .zstd:
            log("Zstandard compression is not supported.", level: .error)
            return nil

        default:
            return decodedData.toArray(type: UInt32.self)
        }

        return nil
    }
}


// MARK: - Extensions

/// :nodoc:
extension TiledParsingMode: CustomStringConvertible {

    /// Parsing mode description.
    var description: String {
        switch self {
            case .none: return "none"
            case .tmx: return "tmx"
            case .tsx: return "tsx"
            case .tx: return "tx"
        }
    }
}

/// :nodoc:
extension TilemapCanvasType: CustomStringConvertible {

    /// Map mode description.
    var description: String {
        switch self {
            case .default: return "Default"
            case .infinite: return "Infinite"
        }
    }
}

/// :nodoc:
extension FileType: CustomStringConvertible {

    /// File type description.
    var description: String {
        switch self {
            case .tmx: return "tile map"
            case .tsx: return "tileset"
            case .png: return "image"
            case .tx:  return "template"
        }
    }
}

/// :nodoc:
extension SKTilemapParser.ParsingError.ErrorType: CustomStringConvertible {

    /// Error description.
    var description: String {
        switch self {
            case .attribute(let attr):
                return "invalid attribute '\(attr)'."

            case .attributeValue(let attr, let value):
                return "invalid attribute '\(attr)' with value '\(value)'."

            case .key(let key):
                return "invalid key '\(key)'."

            case .index(let idx):
                return "invalid index '\(idx)'."

            case .compression(let value):
                return "invalid compression value '\(value)'."

            case .externalFile(let value):
                return "invalid external file reference '\(value)'."

            case .error:
                return "xml parsing error."
        }
    }
}


// MARK: - New Helpers

extension SKTilemapParser {


    /// Start the parsing.
    internal func parse() throws {
        while (externalFileUrls.isEmpty == false) {

            // firstFileToParse = full path (relative to doc root)
            if let firstFileToParse = externalFileUrls.first {

                // current file name (minus doc root)  (ie 'User/Templates/dragon-green.tx')
                currentFilename = firstFileToParse.relativePath

                // current file name only (ie 'dragon-green.tx')
                let currentFile = firstFileToParse.lastPathComponent

                defer {
                    let fileRead = externalFileUrls.remove(at: 0)
                    if (fileRead.path != tilemapUrl?.path) {
                        externalXMLFiles.append(fileRead)
                    }
                }

                // check file type with the path extension.
                let pathExtension = firstFileToParse.pathExtension.lowercased()

                switch pathExtension {
                    case "tmx":
                        parsingMode = TiledParsingMode.tmx
                    case "tsx":
                        parsingMode = TiledParsingMode.tsx
                    case "tx":
                        parsingMode = TiledParsingMode.tx
                    default:
                        parsingMode = TiledParsingMode.none
                }

                var filetype = "filename"
                if let ftype = FileType(rawValue: pathExtension) {
                    filetype = ftype.description
                }

                // set the url for the **current file being read**
                currentFileUrl = URL(fileURLWithPath: currentFilename, relativeTo: documentRoot).standardized

                // use custom logging levels for different parsing modes (reduce spam with external files).
                let customLoggingLevel = (parsingMode == .tmx) ? LoggingLevel.custom : LoggingLevel.debug
                log("\(parsingMode) parser: reading \(filetype): '\(currentFileUrl.lastPathComponent)'", level: customLoggingLevel)

                do {
                    // read the data
                    let data: Data = try Data(contentsOf: currentFileUrl)
                    let parser: XMLParser = XMLParser(data: data)

                    parser.shouldResolveExternalEntities = false
                    parser.delegate = self

                    // parse the file
                    let successs: Bool = parser.parse()

                    // report errors
                    if (successs == false) {

                        let parseError = parser.parserError
                        let errorLine = parser.lineNumber
                        let errorCol = parser.columnNumber

                        let errorDescription = parseError!.localizedDescription
                        log("\(parsingMode) parser '\(currentFile)' \(errorDescription) at line \(errorLine), column \(errorCol)", level: .error)
                    }
                } catch let error {
                    log(error.localizedDescription, level: .error)
                }
            }
        }
    }

    /// Get the parser ready to render!
    ///
    /// - Parameter renderQueue: dispatch queue.
    /// - Returns: tilemap, if rendererd.
    internal func resetAndRender(renderQueue: DispatchQueue) -> SKTilemap? {
        guard let currentMap = self.tilemap else {
            return nil
        }

        // reset to tmx
        parsingMode = TiledParsingMode.tmx

        // reset tileset data
        tilesets = [:]

        // pre-processing callback
        renderQueue.async {
            currentMap.parseTime = Date().timeIntervalSince(self.timer)
            self.tilemapDelegate?.didReadMap?(currentMap)
        }


        parsingQueue.async {
            /// render, then notify the delegates of completion
            self.didBeginRendering(currentMap, queue: renderQueue)
        }

        currentMap.dataStorage?.sync()
        return currentMap
    }
}


// MARK: Debugging - REMOVE


extension SKTilemapParser {


    /// Return a string showing the active element.
    fileprivate var activeElementString: String {
        return activeElement ?? "null"
    }

    /// Return a string showing the last element added.
    fileprivate var lastElementString: String {
        return (lastElement != nil) ? String(describing: type(of: lastElement!)) : "null"
    }

    fileprivate func parsingElementStatus(_ start: Bool = true) {
        let parseStatus = (start == true) ? "start" : "end"
        print("❗️element \(parseStatus), current: '\(activeElementString)', last: '\(lastElementString)'")
    }
}


extension SKTilemapParser: CustomReflectable {

    /// Custom mirror.
    public var customMirror: Mirror {
        var mapdelegate = "nil"
        if (self.tilemapDelegate != nil) {
            mapdelegate = String(describing: type(of: self.tilemapDelegate!))
        }

        var tilesetdatasource = "nil"
        if (self.tilesetDataSource != nil) {
            tilesetdatasource = String(describing: type(of: self.tilesetDataSource!))
        }

        return Mirror(self, children: ["tmxFile": tilemapUrl?.path ?? "nil",
                                       "documentRoot": documentRoot.path,
                                       "currentFilename": currentFilename ?? "nil",
                                       "currentFileUrl": currentFileUrl.relativePathString,
                                       "externalFileUrls": externalXMLFiles.map({ $0.relativePathString }),
                                       "externalImageAssetFiles": externalImageAssetFiles.map({ $0.relativePathString }),
                                       "parsingMode": parsingMode.description,
                                       "compression": compression.rawValue,
                                       "tilemapDelegate": mapdelegate,
                                       "tilesetDataSource": tilesetdatasource,
                                       "tileUpdateMode": tileUpdateMode,
                                       "tilesets": parsedTilesetUrls.map( { $0.relativePathString })],
                            displayStyle: .class
                     )
    }
}



// MARK: Parsing Helpers


protocol TiledParsableType {
    var objectType: String { get }
}



extension TiledParsableType {


    // CHECKME: is this conflicting with other className extensions?

    /// Returns the object class name (`TiledParsableType`).
    var objectType: String {
        return String(describing: Swift.type(of: self))
    }
}


extension SKTilemap: TiledParsableType {}
extension SKTileset: TiledParsableType {}
extension TiledLayerObject: TiledParsableType {}
extension SKTile: TiledParsableType {}
extension SKTilesetData: TiledParsableType {}
extension SKTileObject: TiledParsableType {}
extension SKTiledScene: TiledParsableType {}
extension SKTiledSceneCamera: TiledParsableType {}
extension SKTiledGraphNode: TiledParsableType {}
