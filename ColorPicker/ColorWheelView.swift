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

class ColorWheelView : UIView {
    
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

fileprivate extension ColorWheelView {
    
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
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        indicator.position = viewPointFromHS(hue: self.currentHSB.hue, saturation: self.currentHSB.saturation)
        
        self.indicator.backgroundColor = currentColor.cgColor
        self.updateSubIndicator()
        
        CATransaction.commit()
    }
    
    private func callbackColors() {
        
        var colors = self.subIndicator
            .filter { !$0.isHidden }
            .map { (layer) -> UIColor in
                let centerPoint = self.centerPoint(viewPoint: layer.position)
                return self.colorHSB(centerPoint: centerPoint).color
        }
        
        colors.insert(self.currentColor, at: 0)
        
        self.updatePickerColors?(colors)
    }
    
    private func updateSubIndicator() {
        
        if self.subIndicatorCount == 0 {
            return
        }
        
        for point in self.calculator.points.enumerated() {
            
            let hsb = self.colorHSB(centerPoint: point.element)
            let layer = self.subIndicator[point.offset]
            layer.backgroundColor = hsb.color.cgColor
            layer.position = self.viewPointFromHS(hue: hsb.hue, saturation: hsb.saturation)
            layer.isHidden = false
        }
    }
    
    private func updateWheel() {
        
        if self.diameter == 0 {
            return
        }
        
        self.layer.contents = self.createHSColorWheelImage(size: CGSize(width: self.diameter, height: self.diameter))
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
    
    private func createHSColorWheelImage(size: CGSize) -> CGImage? {
        // Create a bitmap of the Hue Saturation colorWheel
        let colorWheelDiameter = Int(self.diameter)
        let bufferLength = Int(colorWheelDiameter * colorWheelDiameter * 4)

        let bitmapData: CFMutableData = CFDataCreateMutable(nil, 0)
        CFDataSetLength(bitmapData, CFIndex(bufferLength))
        let bitmap = CFDataGetMutableBytePtr(bitmapData)
        
//        let start = Date().currentTimeMillis()
        
        for y in 0 ..< colorWheelDiameter {
            for x in 0 ..< colorWheelDiameter {
                
                var rgb = RGB(red: 0, green: 0, blue: 0, alpha: 0)
                let point = CGPoint(x: x, y: y)
                
                let centerPoint = self.centerPoint(viewPoint: point)
                var hsb = self.colorHSB(centerPoint: centerPoint)
                
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
        
//        print(" END : \(Date().currentTimeMillis() - start)")

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
        
        return HSB(hue: hue, saturation: saturation, brightness: self.brightness, alpha: 1)
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
        var x = colorWheelDiameter / 2.0 + radius * cos(hue * .pi * 2.0)
        var y = colorWheelDiameter / 2.0 + radius * sin(hue * .pi * 2.0)
        
        let diff = (max(self.bounds.width, self.bounds.height) - self.diameter) / 2
        
        if self.bounds.width > self.diameter {
            x += diff
        }
        
        if self.bounds.height > self.diameter {
            y += diff
        }
        
        return CGPoint(x: x, y: y)
    }
    
    private func centerPoint(viewPoint:CGPoint) -> CGPoint {
        let radius = self.radius
        let dx = CGFloat(viewPoint.x - radius) / radius
        let dy = CGFloat(viewPoint.y - radius) / radius
        return CGPoint(x:dx, y:dy)
    }
    
    private func distance(centerPoint:CGPoint) -> CGFloat {
        return sqrt(centerPoint.x * centerPoint.x + centerPoint.y * centerPoint.y)
    }
    
    private func convertValid(viewPoint: CGPoint) -> CGPoint {
        // Calculate distance
        let radius = self.radius
        let x = Int(viewPoint.x)
        let y = Int(viewPoint.y)
        let dx = Double(CGFloat(x) - radius)
        let dy = Double(CGFloat(y) - radius)
        let point = CGPoint(x:dx, y:dy)
        
        if self.distance(centerPoint:point) <= radius {
            return viewPoint
        }
        
        let theta = atan2(dy, dx)
        
        var dPoint = CGPoint()
        dPoint.x = (CGFloat(cos(theta)) * radius) + radius
        dPoint.y = (CGFloat(sin(theta)) * radius) + radius
        return dPoint
    }
}
