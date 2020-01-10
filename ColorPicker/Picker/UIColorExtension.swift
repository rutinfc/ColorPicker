//
//  UIColorExtension.swift
//  ColorPicker
//
//  Created by rutinfc on 2020/01/08.
//  Copyright © 2020 rutinfc. All rights reserved.
//

import UIKit

public extension UIColor {
    
    var hsb: HSB {
        var hue = CGFloat()
        var saturation = CGFloat()
        var brightness = CGFloat()
        var alpha = CGFloat()
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return HSB(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    var rgb: RGB {
        var red = CGFloat()
        var green = CGFloat()
        var blue = CGFloat()
        var alpha = CGFloat()
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGB(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    var complementary : UIColor {
        
        let cicolor = CIColor(color: self)
        
        let compR = 1.0 - cicolor.red
        let compG = 1.0 - cicolor.green
        let compB = 1.0 - cicolor.blue
        
        return UIColor(red: compR, green: compG, blue: compB, alpha: 1.0)
    }
    
    var blackOrWhite : UIColor {
        var white : CGFloat = 0
        self.getWhite(&white, alpha:nil)
        return white < 0.7 ? UIColor.black : UIColor.white
    }
    
    func hexString() -> String {
    
        guard let components = self.cgColor.components, components.count == 4 else {
            return ""
        }
        
        let r: CGFloat = components[0]
        let g: CGFloat = components[1]
        let b: CGFloat = components[2]
        
        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
}

public extension UIImage {
    
    var color : UIColor? {
        
        guard let inputImage = CIImage(image: self) else {
            return nil
        }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else {
            return nil
        }
        guard let outputImage = filter.outputImage else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: nil)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}
