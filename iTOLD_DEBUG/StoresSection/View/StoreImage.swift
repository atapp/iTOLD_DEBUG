//
//  StoreImage.swift
//  DAWG
//
//  Created by Eddie Craig on 03/01/2019.
//  Copyright © 2019 Simon Hogg. All rights reserved.
//

import UIKit

/// Extends UIImage to allow for `Store` image representation as well as providing hang points on the image for children
public final class StoreImage: UIImage {
    
    /**
        Create a new `StoreImage`
        - parameters
            name: The name of the store image e.g. BRU-55_FRONT
            multiplePoints: Optional value if store has multiple hang points
     */
    public convenience init?(named name: String, multiplePoints: [[String: Double]]? = nil) {
        guard let data = UIImage(named: name)?.pngData() else { return nil }
        
        self.init(data: data)
        
        if (multiplePoints != nil) {
            for point in multiplePoints! {
                guard let width = point["widthDivisor"], let height = point["heightDivisor"] else {
                    print("Error in multiplePoint format for \(name) store in childStorePoints in Stores.plist")
                    break
                }
                let widthDivisor = CGFloat(width)
                let heightDivisor = CGFloat(height)
                self.suspensionPoints.append(CGPoint(x: size.width/widthDivisor, y: size.height/heightDivisor))
            }
        } else {
            self.suspensionPoints.append(CGPoint(x: self.size.width/2, y: self.size.height))
        }
    }
    
    lazy var attachmentPoint = CGPoint(x: size.width/2, y: 0)
    
    /// The array of suspension points on the image
    public var suspensionPoints: [CGPoint] = []

}

extension StoreImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
