//
//  Demo+Setup.swift
//  SKTiled Demo
//
//  Created by Michael Fessenden on 6/28/18.
//  Copyright © 2018 Michael Fessenden. All rights reserved.
//

import SpriteKit


extension SKTiledDemoScene {
    
    /**
     Special setup functions for various included demo content.
     
     - parameter fileNamed: `String` tiled filename.
     */
    func setupDemoLevel(fileNamed: String) {
        guard let tilemap = tilemap else { return }
        
        let baseFilename = fileNamed.components(separatedBy: "/").last!
        
        let walkableTiles = tilemap.getTilesWithProperty("walkable", true)
        let walkableTilesString = (walkableTiles.isEmpty == true) ? "" : ", \(walkableTiles.count) walkable tiles."
        log("setting up level: \"\(baseFilename)\"\(walkableTilesString)", level: .debug)
        
        switch baseFilename {
            
        case "dungeon-16x16.tmx":
            
            if let upperGraphLayer = tilemap.tileLayers(named: "Graph-Upper").first {
                _ = upperGraphLayer.initializeGraph(walkable: walkableTiles)
            }
            
            if let lowerGraphLayer = tilemap.tileLayers(named: "Graph-Lower").first {
                _ = lowerGraphLayer.initializeGraph(walkable: walkableTiles)
            }
            
            
        case "roguelike-16x16.tmx":
            if let graphLayer = tilemap.tileLayers(named: "Graph").first {
                _ = graphLayer.initializeGraph(walkable: walkableTiles)
            }
            
        default:
            return
        }
        
        
        NotificationCenter.default.post(
            name: Notification.Name.Demo.WindowTitleUpdated,
            object: nil,
            userInfo: ["wintitle": fileNamed]
        )
    }
}
