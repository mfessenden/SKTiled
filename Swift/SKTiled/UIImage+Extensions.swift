//
//  UIImage+Extensions.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/23/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import UIKit


/**
 Returns an image of the given size.
 
 - parameter size:       `CGSize` size of resulting image.
 - parameter scale:      `CGFloat` scale of result (0 seems to scale 2x, using 1 seems best)
 - parameter whatToDraw: function detailing what to draw the image.
 
 - returns: `UIImage` resulting image.
 */
public func imageOfSize(size: CGSize, scale: CGFloat=1, _ whatToDraw: ()->()) -> UIImage {
    // create an image of size, not opaque, not scaled
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    whatToDraw()
    let result = UIGraphicsGetImageFromCurrentImageContext()
    return result
}
