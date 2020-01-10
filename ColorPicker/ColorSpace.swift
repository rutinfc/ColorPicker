//
//  ColorSpace.swift
//  ColorPicker
//
//  Created by rutinfc on 2020/01/08.
//  Copyright © 2020 rutinfc. All rights reserved.
//

import UIKit

public struct RGB {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat) {
        self.red = red >= 0 ? red : 0
        self.green = green >= 0 ? green : 0
        self.blue = blue >= 0 ? blue : 0
        self.alpha = alpha >= 0 ? alpha : 0
    }

    public var color: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public var hsb : HSB {
        return self.color.hsb
    }
}

public struct HSB : Equatable {
    public var hue: CGFloat
    public var saturation: CGFloat
    public var brightness: CGFloat
    public var alpha: CGFloat

    public init(
        hue: CGFloat,
        saturation: CGFloat,
        brightness: CGFloat,
        alpha: CGFloat) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = alpha
    }

    public var color: UIColor {
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    public var rgb : RGB {
        return self.color.rgb
    }
}

extension HSB {
    public static func ==(lhs:HSB, rhs:HSB) -> Bool {
        return (lhs.hue == rhs.hue) && (lhs.saturation == rhs.saturation) && (lhs.brightness == rhs.brightness) && (lhs.alpha == rhs.alpha)
    }
}

