//
//  SKTilemapParser.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


// XML Parser error types.
internal enum ParsingError: Error {
    case attribute(attr: String)
    case attributeValue(attr: String, value: String)
    case key(key: String)
    case index(idx: Int)
    case compression(value: String)
    case error
}


internal enum ParsingMode {
    case none
    case tmx
    case tsx
}


// File types recognized by the parser
internal enum FileType: String {
    case tmx
    case tsx
    case png
}


// Document compression type.
internal enum CompressionType: String {
    case uncompressed
    case zlib
    case gzip
}


/**

 ## Overview ##

 The `SKTilemapParser` class is a custom [`XMLParserDelegate`](https://developer.apple.com/reference/foundation/xmlparserdelegate) 
 parser for reading Tiled TMX and tileset TSX files.

 This class is not meant to be called directly, but rather invoked via `SKTilemap.load` class function.
 */
internal class SKTilemapParser: NSObject, XMLParserDelegate, Loggable {

    private var fileManager = FileManager.default
    /// Root path of the current file (defaults to `Bundle.main.bundleURL`)
    internal var rootPath: URL = Bundle.main.bundleURL
    internal var fileNames: [String] = []
    internal var currentFilename: String!                              // the current filename being parsed

    internal var parsingMode: ParsingMode = .none                      // current parsing mode
    weak var mapDelegate: SKTilemapDelegate?
    internal var tilemap: SKTilemap!

    fileprivate var encoding: TilemapEncoding = .xml                   // xml encoding
    fileprivate var tilesets: [String: SKTileset] = [:]                // stash external tilesets by FILE name (ie: ["kong-50x32.tsx": <SKTileset>])
    fileprivate var tilesetImagesAdded: Int = 0                        // for reporting the number of images added to a collections tileset

    fileprivate var loggingLevel: LoggingLevel = SKTiledLoggingLevel   // normally warning
    fileprivate var activeElement: String?                             // current object

    fileprivate var lastElement: AnyObject?                            // last element created
    fileprivate var elementPath: [AnyObject] = []                      // current element path

    fileprivate var currentID: Int?                                    // current tile/object ID
    fileprivate var currentType: String?                               // current tile type
    fileprivate var currentProbability: CGFloat?                       // current tile probability

    fileprivate var properties: [String: String] = [:]                 // last properties created
    fileprivate var data: [String: [UInt32]] = [:]                     // store data for tile layers to render in a second pass
    fileprivate var tileData: [UInt32] = []                            // last tile data read
    fileprivate var characterData: String = ""                         // current tile data (string)

    fileprivate var compression: CompressionType = .uncompressed       // compression type
    fileprivate var timer: Date = Date()                               // timer
    fileprivate var finishedParsing: Bool = false
    fileprivate var ignoreProperties: Bool = false                     // ignore custom properties
    fileprivate var layerIndex: Int = 0

    // dispatch queues & groups
    internal let parsingQueue = DispatchQueue.global(qos: .userInteractive)
    internal let renderGroup = DispatchGroup()

    // MARK: - Loading

    /**
     Load a TMX file and parse it.

     - parameter tmxFile:          `String` Tiled file name (does not need TMX extension).
     - parameter inDirectory:      `String?` search path for assets.
     - parameter delegate:         `SKTilemapDelegate?` optional tilemap delegate instance.
     - parameter withTilesets:     `[SKTileset]?` use existing tilesets to create the tile map.
     - parameter ignoreProperties: `Bool` ignore custom properties from Tiled.
     - parameter loggingLevel:    `LoggingLevel` logging verbosity.
     - returns: `SKTilemap?` tiled map node.
     */
    internal func load(tmxFile: String,
                       inDirectory: String? = nil,
                       delegate: SKTilemapDelegate? = nil,
                       withTilesets: [SKTileset]? = nil,
                       ignoreProperties noparse: Bool = false,
                       loggingLevel: LoggingLevel = .info,
                       renderQueue: DispatchQueue) -> SKTilemap? {


        // current parsing mode
        parsingMode = .tmx

        // set the delegate property
        self.mapDelegate = delegate
        self.timer = Date()
        self.ignoreProperties = noparse
        self.loggingLevel = loggingLevel

        // append extension if not already there.
        var tmxFilename = tmxFile
        if !tmxFilename.hasSuffix(".tmx") {
            tmxFilename = tmxFilename.appending(".tmx")
        }

        log("file name: \"\(tmxFilename)\"", level: .debug)

        // if a directory is passed, use that as the root path, otherwise default to bundle's resource
        if let resourceURL = Bundle.main.resourceURL {
            rootPath = resourceURL
        }

        // if the user has passed a search directory...
        if let rootDirectory = inDirectory {
            rootPath = self.getAssetDirectory(path: rootDirectory)
        }

        // create a url relative to the current root
        let fileURL = URL(fileURLWithPath: tmxFilename, relativeTo: rootPath)
        fileNames.append(fileURL.path)


        // add existing tilesets
        if let withTilesets = withTilesets {
            for tileset in withTilesets {

                guard let filename = tileset.filename else {
                    log("tileset \"\(tileset.name)\" has no filename property.", level: .error)
                    continue
                }

                tilesets[filename] = tileset
            }
        }

        while !(fileNames.isEmpty) {

            if let firstFileName = fileNames.first {

                currentFilename = firstFileName
                let currentFile = firstFileName.url.lastPathComponent

                defer { fileNames.remove(at: 0) }


                // check file type
                var fileExt = currentFilename.components(separatedBy: ".").last!
                fileExt = fileExt.lowercased()

                switch fileExt {
                case "tmx":
                    parsingMode = .tmx
                case "tsx":
                    parsingMode = .tsx
                default:
                    parsingMode = .none
                }

                var filetype = "filename"
                if let ftype = FileType(rawValue: fileExt) {
                    filetype = ftype.description
                }

                // absolute url
                let currentURL = URL(fileURLWithPath: currentFilename)


                // check that file exists
                guard self.fileExists(at: currentURL) else { return nil }

                log("\(parsingMode) parser: reading \(filetype): \"\(currentFile)\"", level: .info)

                // set the root path to the current file
                if let currentParent = currentURL.parent {
                    rootPath = URL(fileURLWithPath: currentParent)
                }

                // read the data
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
                    log("\(parsingMode) parser: \(errorDescription) at line:\(errorLine), column: \(errorCol)", level: .error)

                }
            }
        }



        guard let currentMap = self.tilemap else { return nil }

        // reset tileset data
        tilesets = [:]

        // pre-processing callback
        renderQueue.sync {
            self.mapDelegate?.didReadMap(currentMap)
        }

        parsingQueue.sync {
            self.didBeginRendering(currentMap, queue: renderQueue)
        }

        return currentMap
    }

    /**
     Load tilesets from external files.

     - parameter tsxFiles:         `[String]` array of tileset filenames.
     - parameter inDirectory:      `String?` search path for assets.
     - parameter delegate:         `SKTilemapDelegate?` optional tilemap delegate instance.
     - parameter ignoreProperties: `Bool` ignore custom properties from Tiled.
     - parameter loggingLevel:    `LoggingLevel` logging verbosity.
     - returns: `[SKTileset]` tilesets.
     */
    public func load(tsxFiles: [String],
                     inDirectory: String? = nil,
                     delegate: SKTilemapDelegate? = nil,
                     ignoreProperties noparse: Bool = false,
                     loggingLevel: LoggingLevel = .info,
                     renderQueue: DispatchQueue) -> [SKTileset] {



        // current parsing mode is tsx
        parsingMode = .tsx

        // set the delegate property
        self.mapDelegate = delegate
        self.timer = Date()
        self.loggingLevel = loggingLevel
        self.ignoreProperties = noparse

        // if a directory is passed, use that as the root path, otherwise default to bundle's resource
        if let resourceURL = Bundle.main.resourceURL {
            rootPath = resourceURL
        }

        // if the user has passed a search directory...
        if let rootDirectory = inDirectory {
            rootPath = self.getAssetDirectory(path: rootDirectory)
        }

        // create urls relative to root
        for tsxfile in tsxFiles {

            let fileURL = URL(fileURLWithPath: tsxfile, relativeTo: rootPath)
            if fileManager.fileExists(atPath: fileURL.path) {
                fileNames.append(fileURL.path)
            }
        }



        // stash results
        var tilesetResults: [SKTileset] = []

        while !(fileNames.isEmpty) {
            if let firstFileName = fileNames.first {

                currentFilename = firstFileName
                let currentFile = firstFileName.url.lastPathComponent


                defer { fileNames.remove(at: 0) }


                // check file type
                var fileExt = currentFilename.components(separatedBy: ".").last!
                fileExt = fileExt.lowercased()

                switch fileExt {
                case "tmx":
                    parsingMode = .tmx
                case "tsx":
                    parsingMode = .tsx
                default:
                    parsingMode = .none
                }

                var filetype = "filename"
                if let ftype = FileType(rawValue: fileExt) {
                    filetype = ftype.description
                }


                // absolute url
                let currentURL = URL(fileURLWithPath: currentFilename)

                // check that file exists
                guard self.fileExists(at: currentURL) else { continue }

                log("\(parsingMode) parser: reading \(filetype): \"\(currentFile)\"", level: .info)

                // set the root path to the current file
                if let currentParent = currentURL.parent {
                    rootPath = URL(fileURLWithPath: currentParent)
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
                    Logger.default.cache(LogEvent("\(parsingMode) parser: \(errorDescription) at line:\(errorLine), column: \(errorCol)", level: .error, caller: self.logSymbol))
                }
            }
        }

        renderQueue.sync {
            for filename in tsxFiles {
                for (tsxfile, tileset) in tilesets {
                    let basename = tsxfile.components(separatedBy: ".").first!
                    if basename == filename || tsxfile == filename {
                        tilesetResults.append(tileset)
                    }
                }
            }
        }

        return tilesetResults
    }


    // MARK: - Post-Processing

    /**
     Post-process to render each layer.

     - parameter tilemap:  `SKTilemap`    tile map node.
     - parameter duration: `TimeInterval` fade-in time for each layer.
     */
    fileprivate func didBeginRendering(_ tilemap: SKTilemap, queue: DispatchQueue, duration: TimeInterval=0.025) {

        let debugLevel: Bool = (loggingLevel.rawValue < 1) ? true : false

        // loop through the layers
        for layer in tilemap.getLayers(recursive: true) {


            // assign each layer a work item
            let renderItem = DispatchWorkItem {
                // render object groups
                if let objectGroup = layer as? SKObjectGroup {
                    objectGroup.drawObjects()
                }

                // render image layers
                //_ = layer as? SKImageLayer {}

                // render tile layers
                if let tileLayer = layer as? SKTileLayer {

                    if let tileData = self.data[tileLayer.uuid] {
                        // add the layer data
                        if (tileLayer.setLayerData(tileData, debug: debugLevel) == false) {
                            self.log("layer \"\(tileLayer.layerName)\" failed to set data.", level: .warning)
                        }
                    }

                    // report errors
                    if tileLayer.gidErrors.isEmpty == false {
                        let gidErrorString : String = tileLayer.gidErrors.reduce("", { "\($0)" == "" ? "\($1)" : "\($0)" + ", " + "\($1)" })
                        Logger.default.cache(LogEvent("layer \"\(tileLayer.layerName)\": the following gids could not be found: \(gidErrorString)", level: .warning, caller: self.logSymbol))
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
            self.data = [:]
            self.tilesets = [:]
        }

        // release logging messages
        Logger.default.release()

        // sync external queue here
        queue.sync {
            self.tilemap.didFinishRendering(timeStarted: self.timer)
        }
    }


    // MARK: - Helpers

    /**
     Return the curret asset directory.

     - parameter url:  `URL` file url.
     - returns  `Bool` file exists.
     */
    internal func getAssetDirectory(path: String) -> URL {
        // if the path is a directory that exists, return it.
        if (path.isDirectory == true) {
            return URL(fileURLWithPath: path, isDirectory: true)
        }


        // if the path argument respresents a directory name, append it to the resource path.
        let relativePath = self.rootPath.appendingPathComponent(path)

        if (relativePath.isDirectory == true) {
            return relativePath
        }

        // if neither of the paths exists, just return the current root
        return rootPath
    }

    /**
     Returns true if the file exists on disk.

     - parameter url:  `URL` file url.
     - returns  `Bool` file exists.
     */
    internal func fileExists(at url: URL) -> Bool {
        // check that file exists
        guard fileManager.fileExists(atPath: url.path) else {
            //log("file: \"\(url.path)\" does not exist.", level: .warning)
            return false
        }
        return true
    }


    // MARK: - XMLParserDelegate
    internal func parser(_ parser: XMLParser,
                         didStartElement elementName: String,
                         namespaceURI: String?,
                         qualifiedName qName: String?,
                         attributes attributeDict: [String: String])  {

        activeElement = elementName

        if (elementName == "map") {
            guard let tilemap = SKTilemap(attributes: attributeDict) else {
                self.log("could not create tilemap.", level: .fatal)
                parser.abortParsing()
                return
            }

            tilemap.loggingLevel = self.loggingLevel
            self.tilemap = tilemap
            self.tilemap.ignoreProperties = self.ignoreProperties
            self.tilemap.delegate = self.mapDelegate
            self.tilemap.url = URL(fileURLWithPath: currentFilename)

            self.log("Tiled version: \(SKTiledTiledApplicationVersion)", level: .debug)

            if (self.mapDelegate != nil) {
                self.tilemap.zDeltaForLayers = self.mapDelegate!.zDeltaForLayers
            }

            let currentFile = currentFilename.url.lastPathComponent
            let currentBasename = currentFile.components(separatedBy: ".").first!

            // `SKTilemap.filename` represents the tmx filename (minus .tmx extension)
            self.tilemap.name = currentBasename
            self.tilemap.displayName = currentBasename
            
            // run setup functions on tilemap
            self.mapDelegate?.didBeginParsing(tilemap)

            lastElement = tilemap
            elementPath.append(tilemap)
        }


        // MARK: - Tilesets
        // external will have a 'source' attribute, otherwise 'image'
        if (elementName == "tileset") {

            /* inline declaration in tmx:    <tileset firstgid="1" name="ortho4-16x16" tilewidth="16" tileheight="16" tilecount="552" columns="23"> */
            /* external declaration in tmx:  <tileset firstgid="1" source="roguelike-16x16.tsx"/> */
            /* reading external tsx:         <tileset name="roguelike-16x16" tilewidth="16" tileheight="16" spacing="1" tilecount="1938" columns="57">*/

            // reading tmx, external tileset
            if let source = attributeDict["source"] {
                // get the first gid attribute
                guard let firstgid = attributeDict["firstgid"] else {
                    log("external tileset reference \"\(source)\" with no firstgid.", level: .fatal)
                    parser.abortParsing()
                    return
                }

                let firstGID = Int(firstgid)!

                // check to see if tileset already exists (either an empty new tileset, or we've passed a pre-loaded tileset).

                let externalTileset = URL(fileURLWithPath: source, relativeTo: rootPath)

                if let existingTileset = tilesets[externalTileset.path] {
                    self.tilemap?.addTileset(existingTileset)

                    // set the first gid parameter
                    existingTileset.firstGID = firstGID

                    lastElement = existingTileset

                    // set this to nil, just in case we're looking for a collections tileset.
                    currentID = nil


                } else {

                    // new tileset reference, in tmx file
                    if !(fileNames.contains(externalTileset.path)) {

                        // append the source path to parse queue
                        let tilesetFileURL = URL(fileURLWithPath: source, relativeTo: rootPath)

                        // check that file exists
                        guard self.fileExists(at: tilesetFileURL) else {
                            self.log("tileset file not found: \"\(tilesetFileURL.lastPathComponent)\".", level: .fatal)
                            parser.abortParsing()
                            return
                        }

                        fileNames.append(tilesetFileURL.path)

                        // create a new tileset
                        let tileset = SKTileset(source: source, firstgid: firstGID, tilemap: self.tilemap)
                        tileset.loggingLevel = self.loggingLevel
                        tileset.ignoreProperties = self.ignoreProperties

                        // add tileset to external file list (full file name)
                        tilesets[externalTileset.path] = tileset

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
                if let existingTileset = tilesets[currentFilename] {

                    guard let width = attributeDict["tilewidth"] else { parser.abortParsing(); return }
                    guard let height = attributeDict["tileheight"] else { parser.abortParsing(); return }

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
                    guard let tileset = SKTileset(attributes: attributeDict) else { parser.abortParsing(); return }
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

                        tileset.filename = currentFilename
                        tilesets[currentFilename.url.lastPathComponent] = tileset
                    }
                }
            }
        }

        // draw offset for tilesets
        if elementName == "tileoffset" {
            guard let offsetx = attributeDict["x"] else { parser.abortParsing(); return }
            guard let offsety = attributeDict["y"] else { parser.abortParsing(); return }

            if let tileset = lastElement as? SKTileset {
                tileset.tileOffset = CGPoint(x: Int(offsetx)!, y: Int(offsety)!)
            }
        }

        if elementName == "property" {
            guard let name = attributeDict["name"] else { parser.abortParsing(); return }
            guard let value = attributeDict["value"] else { parser.abortParsing(); return }
            //guard let propertyType = attributeDict["type"] else { parser.abortParsing(); return }

            // stash properties
            properties[name] = value
        }


        // 'layer' indicates a Tile layer
        if (elementName == "layer") {
            guard let layerName = attributeDict["name"] else { parser.abortParsing(); return }
            guard let layer = SKTileLayer(tilemap: self.tilemap!, attributes: attributeDict)
                else {
                    log("Error creating tile layer: \"\(layerName)\"", level: .fatal)
                    parser.abortParsing()
                    return
            }

            let parentElement = elementPath.last!
            if let group = parentElement as? SKGroupLayer {
                let _ = group.addLayer(layer)
                layer.rawIndex = layerIndex
                layerIndex += 1
            }

            if let tilemap = parentElement as? SKTilemap {
                let _ = tilemap.addLayer(layer)
                layer.rawIndex = layerIndex
                layerIndex += 1
            }


            lastElement = layer
        }

        // 'objectgroup' indicates an Object layer or tile collision
        if (elementName == "objectgroup") {

            // if tileset is last element and currentID exists....
            if let tileset = lastElement as? SKTileset {

                if let currentID = currentID {

                    let tileID = tileset.firstGID + currentID
                    if tileset.getTileData(globalID: tileID) != nil {
                        // add to object group
                    }
                }
            } else {

                guard let objectsGroup = SKObjectGroup(tilemap: self.tilemap!, attributes: attributeDict)
                    else {
                        parser.abortParsing()
                        return
                }

                let parentElement = elementPath.last!

                if let group = parentElement as? SKGroupLayer {
                    let _ = group.addLayer(objectsGroup)
                    objectsGroup.rawIndex = layerIndex
                    layerIndex += 1
                }

                if let tilemap = parentElement as? SKTilemap {
                    let _ = tilemap.addLayer(objectsGroup)
                    objectsGroup.rawIndex = layerIndex
                    layerIndex += 1
                }


                lastElement = objectsGroup
            }
        }

        // 'imagelayer' indicates an Image layer
        if (elementName == "imagelayer") {
            guard let _ = attributeDict["name"] else { parser.abortParsing(); return }
            guard let imageLayer = SKImageLayer(tilemap: self.tilemap!, attributes: attributeDict)
                else {
                    parser.abortParsing()
                    return
            }

            let parentElement = elementPath.last!
            if let group = parentElement as? SKGroupLayer {
                let _ = group.addLayer(imageLayer)
                imageLayer.rawIndex = layerIndex
                layerIndex += 1
            }

            if let tilemap = parentElement as? SKTilemap {
                let _ = tilemap.addLayer(imageLayer)
                imageLayer.rawIndex = layerIndex
                layerIndex += 1
            }


            lastElement = imageLayer
        }

        // 'group' indicates a Group layer
        if (elementName == "group") {
            guard let _ = attributeDict["name"] else { parser.abortParsing(); return }
            guard let groupLayer = SKGroupLayer(tilemap: self.tilemap!, attributes: attributeDict)
                else {
                    log("error parsing group layer.", level: .fatal)
                    parser.abortParsing()
                    return
            }

            let parentElement = elementPath.last!
            if let group = parentElement as? SKGroupLayer {
                let _ = group.addLayer(groupLayer)
                groupLayer.rawIndex = layerIndex
                layerIndex += 1
            }

            if let tilemap = parentElement as? SKTilemap {
                let _ = tilemap.addLayer(groupLayer)
                groupLayer.rawIndex = layerIndex
                layerIndex += 1
            }

            // delegate callback
            parsingQueue.sync {
                self.mapDelegate?.didAddLayer(groupLayer)
            }

            elementPath.append(groupLayer)
            lastElement = groupLayer
        }

        // look for last element to be a tileset or imagelayer
        if (elementName == "image") {
            guard attributeDict["width"] != nil,
                attributeDict["height"] != nil,
                let sourceImageName = attributeDict["source"] else {
                        log("source image not found.", level: .fatal)
                        parser.abortParsing()
                        return
            }


            // image resources might be store in the xcassets catalog.
            let imageURL = URL(fileURLWithPath: sourceImageName, isDirectory: false, relativeTo: rootPath)


            // get the absolute path to the image
            let sourceImagePath = imageURL.path 

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

                    // add an image property to the tileset collection
                    let tileData = tileset.addTilesetTile(currentID, source: sourceImagePath)
                    tilesetImagesAdded += 1
                    if (tileData == nil) {
                        log("\(parsingMode) parser: Warning: tile id \(currentID) is invalid.", level: .warning)
                    }
                } else {

                    // add the tileset spritesheet image
                    tileset.addTextures(fromSpriteSheet: sourceImagePath, replace: false, transparent: attributeDict["trans"])
                    tileset.parseProperties(completion: nil)

                    // delegate callback
                    parsingQueue.sync {
                        tileset.renderTileData()
                        self.mapDelegate?.didAddTileset(tileset)
                    }
                }
            }
        }

        // `tile` is used to flag properties in a tileset, as well as store tile layer data in an XML-formatted map.
        if elementName == "tile" {

            // XML layer data is stored with a `tile` tag and `gid` atribute. No other attributes will be present.
            // <tile gid="0"/>
            if let gid = attributeDict["gid"] {
                let intValue = Int(gid)!
                // just append this to the tileData property
                if (encoding == .xml) {
                    tileData.append(UInt32(intValue))
                }
            }

            // otherwise, we're adding data to a tileset. Attributes can be `type` and `probability`.
            else if let id = attributeDict["id"] {

                let intValue = Int(id)!
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


            // adding a group to tileset tile
            if let _ = lastElement as? SKTileset {}

            // adding a group to object layer
            if let objectGroup = lastElement as? SKObjectGroup {

                let Object = (tilemap.delegate != nil) ? tilemap.delegate!.objectForVectorType(named: attributeDict["type"]) : SKTileObject.self

                guard let tileObject = Object.init(attributes: attributeDict) else {
                    log("\(parsingMode) parser: Error creating object.", level: .fatal)
                    parser.abortParsing()
                    return
                }


                let _ = objectGroup.addObject(tileObject)
                currentID = tileObject.id
            }
        }

        // special case - look for last element to be a object
        // this signifies that the object should be an ellipse
        if (elementName == "ellipse") {
            if let objectsgroup = lastElement as? SKObjectGroup {
                if (currentID != nil) {
                    if let currentObject = objectsgroup.getObject(withID: currentID!) {
                        currentObject.objectType = .ellipse
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
                    let coords = point.components(separatedBy: ",").flatMap { x in Double(x) }
                    coordinates.append(coords.flatMap { CGFloat($0) })
                }

                if let _ = lastElement as? SKTileset {

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
                    let coords = point.components(separatedBy: ",").flatMap { x in Double(x) }
                    coordinates.append(coords.flatMap { CGFloat($0) })
                }

                if let _ = lastElement as? SKTileset {}

                if let objectGroup = lastElement as? SKObjectGroup {
                    if (currentID != nil) {
                        if let currentObject = objectGroup.getObject(withID: currentID!) {
                            currentObject.addPoints(coordinates, closed: false)
                        }
                    }
                }
            }
        }

        // animated tiles
        if (elementName == "frame") {
            guard let currentID = currentID else {
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
                let animationFrame = currentTileData.addFrame(withID: Int(id)! + tileset.firstGID, interval: Int(duration)!)

                if let frameData = tileset.getTileData(localID: animationFrame.gid) {
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
                //throw ParsingError.Compression(value: compression)
                guard let compression = CompressionType(rawValue: ctype) else {
                    fatalError("compression type: \(ctype) not supported.")
                }
                self.compression = compression
            }
        }
    }


    // Runs when parser ends a key: </key>
    internal func parser(_ parser: XMLParser,
                         didEndElement elementName: String,
                         namespaceURI: String?,
                         qualifiedName qName: String?) {

        // look for last element to add properties to
        if elementName == "properties" {

            // tilemap properties
            if let tilemap = lastElement as? SKTilemap {
                for (key, value) in properties {
                    tilemap.properties[key] = value
                }
                
                tilemap.parseProperties(completion: nil)
            }

            // layer properties
            if let layer = lastElement as? SKTiledLayerObject {
                if (currentID == nil) {
                    for (key, value) in properties {
                        layer.properties[key] = value
                    }
                }

                layer.parseProperties(completion: nil)
            }

            // tileset properties
            if let tileset = lastElement as? SKTileset {
                if (currentID == nil) {
                    tileset.properties = properties
                    tileset.parseProperties(completion: nil)

                } else {

                    let tileID = tileset.firstGID + currentID!
                    if let tileData = tileset.getTileData(globalID: tileID) {
                        for (key, value) in properties {
                            tileData.properties[key] = value
                        }

                        tileData.parseProperties(completion: nil)
                        properties = [:]
                    }
                }
            }

            // clear if no last ID
            if currentID == nil {
                properties = [:]
            }
        }

        // look for last element to be a layer
        if (elementName == "data") {
            guard let tileLayer = lastElement as? SKTileLayer else {
                log("\(parsingMode) parser: cannot find layer to add data.", level: .fatal)
                parser.abortParsing()
                return
            }

            var foundData = false

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
                data[tileLayer.uuid] = tileData

            } else {
                log("error adding tile data.", level: .fatal)
                parser.abortParsing()
                return
            }

            // reset csv data
            tileData = []
        }

        if (elementName == "tile") {
            // parse properties
            if let tileset = lastElement as? SKTileset {
                if (currentID != nil) {

                    let tileID = tileset.firstGID + currentID!
                    if let currentTileData = tileset.getTileData(globalID: tileID) {

                        for (key, value) in properties {
                            currentTileData.properties[key] = value
                        }

                        properties = [:]

                        // set the type attribute for the tile data
                        if let currentType = currentType {
                            currentTileData.type = currentType
                        }

                        // set the probability attribute for the tile data
                        if let currentProbability = currentProbability {
                            currentTileData.probability = currentProbability
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
                    }
                    currentID = nil
                }
            }

            // if we're dealing with a tile collision object...
            if (lastElement as? SKTileset) != nil {}
            //currentID = nil
        }


        if (elementName == "layer") {

            if let tileLayer = lastElement as? SKTileLayer {

                // delegate callback
                parsingQueue.sync {
                    self.mapDelegate?.didAddLayer(tileLayer)
                }
            }
        }

        if (elementName == "objectgroup") {
            if let objectGroup = lastElement as? SKObjectGroup {
                // delegate callback
                parsingQueue.sync {
                    self.mapDelegate?.didAddLayer(objectGroup)
                }
            }
        }

        if (elementName == "imagelayer") {
            if let imageLayer = lastElement as? SKImageLayer {
                // delegate callback
                parsingQueue.sync {
                    self.mapDelegate?.didAddLayer(imageLayer)
                }
            }
        }

        if (elementName == "group") {
            if let groupLayer = lastElement as? SKGroupLayer {
                // delegate callback
                parsingQueue.sync {
                    self.mapDelegate?.didAddLayer(groupLayer)
                }
            }

            // if we're closing a group layer, pop it from the element path
            let _ = elementPath.popLast()
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

        if (elementName == "tileset") {
            if tilesetImagesAdded > 0 {
                if let tileset = lastElement as? SKTileset {
                    Logger.default.cache(LogEvent("tileset \"\(tileset.name)\" finished, \(tilesetImagesAdded) images added.", level: .debug, caller: self.logSymbol))
                    tileset.isRendered = true
                    // delegate callback
                    parsingQueue.sync {
                        tileset.renderTileData()
                        self.mapDelegate?.didAddTileset(tileset)
                    }
                }
                tilesetImagesAdded = 0
            }

            // important to close this here!!
            lastElement = nil
        }


        // reset character data
        characterData = ""
    }

    // foundCharacters happens whenever parser enters a key poop
    internal func parser(_ parser: XMLParser, foundCharacters string: String) {
        // append data attribute
        characterData += string
    }

    internal func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        //if parseError.code == NSXMLParserError.InternalError {}
    }

    // MARK: - Decoding
    /**
     Scrub CSV data.

     - parameter data: `String` data to decode
     - returns: `[UInt32]` parsed CSV data.
     */
    fileprivate func decode(csvString data: String) -> [UInt32] {
        return data.scrub().components(separatedBy: ",").map {UInt32($0)!}
    }

    /**
     Decode Base64-formatted data.

     - parameter data:        `String` Base64 formatted data to decode
     - parameter compression: `CompressionType` compression type.
     - returns: `[UInt32]?` parsed data.
     */
    fileprivate func decode(base64String data: String,
                            compression: CompressionType = .uncompressed) -> [UInt32]? {

        guard let decodedData = Data(base64Encoded: data, options: .ignoreUnknownCharacters) else {
            print("ERROR: data is not base64 encoded.")
            return nil
        }

        switch compression {
        case .zlib, .gzip:
            if let decompressed = try? decodedData.gunzipped() {
                return decompressed.toArray(type: UInt32.self)
            }

        default:
            return decodedData.toArray(type: UInt32.self)
        }

        return nil
    }
}


// MARK: - Extensions

extension FileType: CustomStringConvertible {
    /// File type description.
    var description: String {
        switch self {
        case .tmx: return "tile map"
        case .tsx: return "tileset"
        case .png: return "image"
        }
    }
}
