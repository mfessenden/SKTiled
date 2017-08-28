//
//  Demo+Debugging.swift
//  SKTiled
//
//  Created by Michael Fessenden on 8/17/17.
//  Copyright © 2017 Michael Fessenden. All rights reserved.
//

import Foundation
import SpriteKit
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#else
import Cocoa
#endif



#if os(iOS) || os(watchOS) || os(tvOS)
public extension UIFont {
    // print all fonts
    public static func allFontNames() {
        for family: String in UIFont.familyNames {
            print("\(family)")
            for names: String in UIFont.fontNames(forFamilyName: family){
                print("== \(names)")
            }
        }
    }
}
#else
public extension NSFont {
    public static func allFontNames() {
        let fm = NSFontManager.shared()
        for family in fm.availableFonts {
            print("\(family)")
        }
    }
}
#endif
