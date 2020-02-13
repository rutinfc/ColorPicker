//
//  ColorWheelView.swift
//  ColorPicker
//
//  Created by rutinfc on 2020/01/08.
//  Copyright © 2020 rutinfc. All rights reserved.
//

import UIKit

fileprivate extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

struct IndicatorInfo {
    var diameter : CGFloat
    var borderWidth : CGFloat
    var borderColor : UIColor
}

public class ColorWheelView : UIView {
    
    private var isDirty : Bool = false
    
    private var currentHSB = UIColor.white.hsb {
        didSet {
            
            if oldValue == self.currentHSB, self.isDirty == false {
                return
            }
            
            self.isDirty = true
            
            let point = self.viewPointFromHS(hue: self.currentHSB.hue, saturation: self.currentHSB.saturation)
            
            self.calculator.radius = self.currentHSB.saturation
            self.calculator.centerPoint = self.centerPoint(viewPoint: point)
            self.calculator.calc()
            
            self.updateIndicator()
            
            self.callbackColors()
        }
    }
    
    var brightness : CGFloat = 1 {
        didSet {
            
            if oldValue == self.brightness {
                return
            }
            
            self.currentHSB.brightness = self.brightness
            self.updateWheel()
            self.updateIndicator()
            self.callbackColors()
        }
    }
    
    var calculator = ColorCalculator()  {
        didSet {
            self.calculator.radius = self.radius
            self.subIndicatorCount = self.calculator.pointCount
        }
    }
    
    var updatePickerColors : (([UIColor])->Void)?
    
    private var subIndicator = [CALayer]()
    
    private var subIndicatorCount : Int = 0 {
        
        didSet {
            self.loadSubIndicator()
            self.calculator.radius = self.currentHSB.saturation
            self.calculator.centerPoint = self.centerPoint(viewPoint: self.indicator.position)
            self.calculator.calc()
            self.updateIndicator()
            self.callbackColors()
        }
    }
    
    var currentColor : UIColor {
        set {
            self.currentHSB = newValue.hsb
        }
        get {
            return currentHSB.color
        }
    }
    
    private var diameter : CGFloat = 0
    
    private var radius : CGFloat {
        return self.diameter / 2
    }
    
    private var subIndicatorInfo = IndicatorInfo(diameter: 30, borderWidth: 0.5, borderColor: UIColor.gray)
    
    private var indicatorInfo = IndicatorInfo(diameter:30, borderWidth:1, borderColor:UIColor.black) {
        didSet {
            indicator.bounds.size = CGSize(width: indicatorInfo.diameter, height: indicatorInfo.diameter)
            indicator.borderColor = indicatorInfo.borderColor.cgColor
            indicator.borderWidth = indicatorInfo.borderWidth
            indicator.cornerRadius = indicatorInfo.diameter / 2
        }
    }
    
    private lazy var indicator : CALayer = {
        let indicator = CALayer()
        indicator.shadowColor = UIColor.black.cgColor
        indicator.shadowOffset = .zero
        indicator.shadowRadius = 1
        indicator.shadowOpacity = 0.5
        return indicator
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.updateWheel()
        self.loadIndicator()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.updateWheel()
        self.loadIndicator()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.isDirty = true
        self.diameter = min(self.frame.width, self.frame.height)
        self.updateWheel()
        self.loadIndicator()
    }
}

public extension ColorWheelView {
    
    static func thumbImage(diameter:CGFloat) -> UIImage? {
        
        if let cgImage = self.createHSColorWheelImage(diameter: diameter, brightness: 1) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}

fileprivate extension ColorWheelView {
    
    private static func createHSColorWheelImage(diameter: CGFloat, brightness:CGFloat) -> CGImage? {
        // Create a bitmap of the Hue Saturation colorWheel
        let colorWheelDiameter = Int(diameter)
        let bufferLength = Int(colorWheelDiameter * colorWheelDiameter * 4)
        
        let bitmapData: CFMutableData = CFDataCreateMutable(nil, 0)
        CFDataSetLength(bitmapData, CFIndex(bufferLength))
        let bitmap = CFDataGetMutableBytePtr(bitmapData)
        
        for y in 0 ..< colorWheelDiameter {
            for x in 0 ..< colorWheelDiameter {
                
                var rgb = RGB(red: 0, green: 0, blue: 0, alpha: 0)
                let point = CGPoint(x: x, y: y)
                let centerPoint = self.centerPoint(viewPoint: point, radius: diameter/2)
                var hsb = self.colorHSB(centerPoint: centerPoint, brightness:brightness)
                
                if hsb.saturation < 1.0 {
                    // Antialias the edge of the circle.
                    if hsb.saturation > 0.99 {
                        hsb.alpha = (1.0 - hsb.saturation) * 100
                    } else {
                        hsb.alpha = 1.0
                    }
                    rgb = hsb.rgb
                }
                let offset = Int(4 * (x + y * colorWheelDiameter))
                bitmap?[offset] = UInt8(rgb.red * 255)
                bitmap?[offset + 1] = UInt8(rgb.green * 255)
                bitmap?[offset + 2] = UInt8(rgb.blue * 255)
                bitmap?[offset + 3] = UInt8(rgb.alpha * 255)
            }
        }
        
        // Convert the bitmap to a CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let dataProvider = CGDataProvider(data: bitmapData) else {
            return nil
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo().rawValue | CGImageAlphaInfo.last.rawValue)
        let imageRef = CGImage(
            width: Int(colorWheelDiameter),
            height: Int(colorWheelDiameter),
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: Int(colorWheelDiameter) * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent)
        return imageRef
    }
    
    private static func centerPoint(viewPoint:CGPoint, radius:CGFloat) -> CGPoint {
        let dx = CGFloat(viewPoint.x - radius) / radius
        let dy = CGFloat(viewPoint.y - radius) / radius
        return CGPoint(x:dx, y:dy)
    }
    
    private static func distance(centerPoint:CGPoint) -> CGFloat {
        return sqrt(centerPoint.x * centerPoint.x + centerPoint.y * centerPoint.y)
    }
    
    private static func colorHSB(centerPoint:CGPoint, brightness:CGFloat) -> HSB {
        var hue = CGFloat()
        
        let saturation = self.distance(centerPoint: centerPoint)
        
        if saturation == 0 {
            hue = 0
        } else {
            hue = acos(centerPoint.x / saturation) / .pi / 2

            if centerPoint.y < 0 {
                hue = 1.0 - hue
            }
        }
        
        return HSB(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    private func loadIndicator() {
        // Configure indicator layer
        
        self.indicator.bounds = CGRect(x:0, y:0, width: indicatorInfo.diameter, height:indicatorInfo.diameter)
        self.indicator.borderColor = indicatorInfo.borderColor.cgColor
        self.indicator.borderWidth = indicatorInfo.borderWidth
        self.indicator.cornerRadius = indicatorInfo.diameter / 2
        
        self.updateIndicator()
        layer.addSublayer(indicator)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didChangeIndicator(gesture:)))
        self.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didChangeIndicator(gesture:)))
        self.addGestureRecognizer(panGesture)
        
        self.layer.contentsGravity = .center
    }
    
    private func loadSubIndicator() {
        
        self.subIndicator.forEach { (layer) in
            layer.removeFromSuperlayer()
        }
        
        self.subIndicator.removeAll()
        
        if self.subIndicatorCount == 0 {
            return
        }
        
        let cornerRadius = self.subIndicatorInfo.diameter / 2
        
        (0..<self.subIndicatorCount).map { (index) -> CALayer in
            let subIndicator = CALayer()
            subIndicator.cornerRadius = cornerRadius
            subIndicator.bounds = CGRect(x: 0, y: 0, width: subIndicatorInfo.diameter, height: subIndicatorInfo.diameter)
            subIndicator.borderWidth = self.subIndicatorInfo.borderWidth
            subIndicator.borderColor = self.subIndicatorInfo.borderColor.cgColor
            subIndicator.isHidden = true
            return subIndicator
        }.forEach { (subLayer) in
            layer.insertSublayer(subLayer, at: 0)
            self.subIndicator.append(subLayer)
        }
    }
    
    private func loadWheel() {
        layer.cornerRadius = min(frame.width, frame.height) / 2
        self.updateWheel()
    }
    
    private func updateIndicator () {
        
        if self.diameter == 0 {
            return
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        let viewPoint = viewPointFromHS(hue: self.currentHSB.hue, saturation: self.currentHSB.saturation)
        
        indicator.position = adjustViewPointInBounds(viewPoint: viewPoint)
        
        self.indicator.backgroundColor = currentColor.cgColor
        self.updateSubIndicator()
        
        CATransaction.commit()
    }
    
    private func callbackColors() {
        
        var colors = [UIColor]()
        
        colors.append(self.currentColor)
        
        if self.subIndicatorCount > 0 {
            
            let subColors = self.calculator.points.map { (centerPoint) -> UIColor in
                return self.colorHSB(centerPoint: centerPoint).color
            }
            
            colors.append(contentsOf: subColors)
        }
        
        self.updatePickerColors?(colors)
    }
    
    private func updateSubIndicator() {
        
        if self.subIndicatorCount == 0 {
            return
        }
        
        self.calculator.points.enumerated().forEach { (offset, element) in
            let hsb = self.colorHSB(centerPoint: element)
            let layer = self.subIndicator[offset]
            layer.backgroundColor = hsb.color.cgColor
            let viewPoint = self.viewPointFromHS(hue: hsb.hue, saturation: hsb.saturation)
            
            layer.position = self.adjustViewPointInBounds(viewPoint: viewPoint)
            layer.isHidden = false
        }
    }
    
    private func updateWheel() {
        
        if self.diameter == 0 {
            return
        }
        
        self.layer.contents = ColorWheelView.createHSColorWheelImage(diameter:self.diameter, brightness: self.brightness)
    }

    @objc private func didChangeIndicator(gesture:UIGestureRecognizer) {
        
        let position = gesture.location(in: self)
        
        let viewPoint = self.convertValid(viewPoint: position)
        let centerPoint = self.centerPoint(viewPoint: viewPoint)
        self.updateCurrentColor(centerPoint:centerPoint)
        
        switch gesture.state {
        case .began:
            
            self.indicatorInfo.diameter = 50
            self.indicatorInfo.borderColor = UIColor.yellow
            
        case .ended, .cancelled :
            self.indicatorInfo.diameter = 30
            self.indicatorInfo.borderColor = UIColor.black

        default:
            break
        }
    }
    
    private func updateCurrentColor(centerPoint:CGPoint) {
        self.currentHSB = self.colorHSB(centerPoint: centerPoint)
    }

    /// Get hue and saturation component for a given point in the color wheel.
    ///
    /// - Parameters:
    ///   - point: The point in the color wheel.
    ///   - hue: On return, the hue component for given point.
    ///   - saturation: On return, the saturation component for given point.
    private func colorHSB(centerPoint:CGPoint) -> HSB {
        return ColorWheelView.colorHSB(centerPoint: centerPoint, brightness: self.brightness)
    }
    
    /// Get point in the color wheel for a given hue and saturation component.
    ///
    /// - Parameters:
    ///   - hue: The hue component for HSB.
    ///   - saturation: The saturation component for HSB.
    /// - Returns: The point in the color wheel corresponding the hue and saturation component.
    private func viewPointFromHS(hue: CGFloat, saturation: CGFloat) -> CGPoint {
        let colorWheelDiameter = self.diameter
        let radius = saturation * colorWheelDiameter / 2.0
        let x = colorWheelDiameter / 2.0 + radius * cos(hue * .pi * 2.0)
        let y = colorWheelDiameter / 2.0 + radius * sin(hue * .pi * 2.0)
        
        return CGPoint(x: x, y: y)
    }
    
    private func adjustViewPointInBounds(viewPoint:CGPoint) -> CGPoint {
        let colorWheelDiameter = self.diameter
        var result : CGPoint = viewPoint
        if self.bounds.width > colorWheelDiameter {
            result.x += ((self.bounds.width - colorWheelDiameter) / 2)
        }

        if self.bounds.height > colorWheelDiameter {
            result.y += ((self.bounds.height - colorWheelDiameter) / 2)
        }
        return result
    }
    
    private func centerPoint(viewPoint:CGPoint) -> CGPoint {
        return ColorWheelView.centerPoint(viewPoint: viewPoint, radius: self.radius)
    }
    
    private func convertValid(viewPoint: CGPoint) -> CGPoint {
        // Calculate distance
        let radius = self.radius
        let x = Int(viewPoint.x)
        let y = Int(viewPoint.y)
        let dx = Double(CGFloat(x) - radius)
        let dy = Double(CGFloat(y) - radius)
        let point = CGPoint(x:dx, y:dy)
        
        if ColorWheelView.distance(centerPoint:point) <= radius {
            return viewPoint
        }
        
        let theta = atan2(dy, dx)
        
        var dPoint = CGPoint()
        dPoint.x = (CGFloat(cos(theta)) * radius) + radius
        dPoint.y = (CGFloat(sin(theta)) * radius) + radius
        return dPoint
    }
}
