//
//  Extensions.swift
//  DAWG
//
//  Created by Simon Hogg on 2018-10-13.
//  Copyright © 2018 Simon Hogg. All rights reserved.
//

import UIKit

extension UIView {
    func pinSubview(_ subview:UIView, toEdge edge:NSLayoutConstraint.Attribute, withConstant constant:Float) {
        self.pinSubviews(self, subview2: subview, toEdge: edge, withConstant: constant)
    }
    
    func pinSubviews(_ subview1:UIView, subview2:UIView, toEdge edge:NSLayoutConstraint.Attribute, withConstant constant:Float) {
        pin(firstSubview: subview1, firstEdge: edge, secondSubview: subview2, secondEdge: edge, with: constant)
    }
    
    func pin(firstSubview subview1:UIView, firstEdge edge1:NSLayoutConstraint.Attribute, secondSubview subview2:UIView, secondEdge edge2:NSLayoutConstraint.Attribute, with constant:Float) {
        let constraint = NSLayoutConstraint(item: subview1, attribute: edge1, relatedBy: .equal, toItem: subview2, attribute: edge2, multiplier: 1, constant: CGFloat(constant))
        self.addConstraint(constraint)
    }
    
    func pinSubview(_ subview:UIView, withHeight height:CGFloat) {
        let height = NSLayoutConstraint(item: subview, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
        self.addConstraint(height)
    }
    
    func pinSubview(_ subview:UIView, withWidth width:CGFloat) {
        let width = NSLayoutConstraint(item: subview, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
        self.addConstraint(width)
    }
    
    func bindFrameToSuperviewBoundsWithPadding(left: CGFloat = 0, leftActive: Bool, top: CGFloat = 0, topActive: Bool = false, right: CGFloat = 0, rightActive: Bool = false, bottom: CGFloat = 0, bottomActive: Bool = false) {
        guard let superview = self.superview else {
            print("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
            return
        }

        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: superview.topAnchor, constant: top).isActive = topActive
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: bottom).isActive = bottomActive
        self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: left).isActive = leftActive
        self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0 - right).isActive = rightActive
        //self.layoutMargins = UIEdgeInsets(top: 100, left: 10, bottom: 10, right: 10)

    }
}

extension CGRect {
    init(topCentre: CGPoint, size: CGSize) {
        self.init(origin: topCentre, size: size)
        self = offsetBy(dx: -size.width/2, dy: 0)
    }
}

extension ClosedRange {
    /// Clamps the value to ensure it is within the ClosedRange
    ///
    /// - Parameter value: Value to be clamped
    /// - Returns: Returns a number equal to the value given or the upper or lower bound if outside of the range
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}

extension UIColor {
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension UIView {
    func rotate(degrees: CGFloat) {
        rotate(radians: CGFloat.pi * degrees / 180.0)
    }
    
    func rotate(radians: CGFloat) {
        self.transform = CGAffineTransform(rotationAngle: radians)
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension UIView {
    func addTopBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }

    func addRightBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }

    func addBottomBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }

    func addLeftBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
}

extension UIView {
    
    func addCircleOrEditIfExists(color: UIColor, size: CGFloat){
        for view in self.subviews {
            if let subView = view.viewWithTag(1333) {
                subView.backgroundColor = color
                return
            }
        }
        let circle = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        self.addSubview(circle)
        //circle.frame = self.bounds
//        circle.center = self.center
        let frame = self.layoutMarginsGuide
        circle.leadingAnchor.constraint(equalToSystemSpacingAfter: frame.leadingAnchor, multiplier: 0).isActive = true
        circle.topAnchor.constraint(equalTo: frame.topAnchor, constant: 0).isActive = true
        circle.layer.cornerRadius = size / 2
        circle.backgroundColor = color
        circle.clipsToBounds = true
        circle.tag = 1333


        let darkBlur = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurView = UIVisualEffectView(effect: darkBlur)

        blurView.frame = circle.bounds

        //circle.addSubview(blurView)
    }
}

extension UIView {

   func roundCorners(corners:CACornerMask, radius: CGFloat) {
      self.layer.cornerRadius = radius
      self.layer.maskedCorners = corners
   }
}
