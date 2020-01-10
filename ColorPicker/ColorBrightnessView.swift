//
//  ColorBrightnessView.swift
//  ColorPicker
//
//  Created by rutinfc on 2020/01/09.
//  Copyright © 2020 rutinfc. All rights reserved.
//

import UIKit
import Foundation

class ColorBrightnessView : UIView {
    
    private var isDirty : Bool = false
    
    var color : UIColor = UIColor.white {
        didSet {
            if oldValue == color, self.isDirty == false {
                return
            }
            self.isDirty = true
            self.brightness = color.hsb.brightness
            self.updateColor()
            self.updateIndicator()
        }
    }
    
    var brightness : CGFloat = 0 {
        didSet {
            
            if oldValue == self.brightness {
                return
            }
            
            self.updateIndicator()
            self.updatePickerBrightness?(self.brightness)
        }
    }
    
    var updatePickerBrightness : ((CGFloat)->Void)?
    
    private var padding : CGFloat = 10
    
    private lazy var contentView : UIView = {
        return UIView(frame: CGRect.zero)
    }()
    
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
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.loadContent()
        self.loadIndicator()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadContent()
        self.loadIndicator()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.isDirty = true
        self.indicator.bounds = CGRect(x:0, y:0, width: self.bounds.width, height:20)
        self.updateIndicator()
        self.updateColor()
    }
}

private extension ColorBrightnessView {
    
    func loadContent() {
        self.backgroundColor = UIColor.white
        self.addSubview(self.contentView)
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.topAnchor.constraint(equalTo: self.topAnchor, constant: self.padding).isActive = true
        self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: self.padding * -1).isActive = true
        self.contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.contentView.setNeedsUpdateConstraints()
    }
    
    func loadIndicator() {
        // Configure indicator layer
        
        self.indicator.bounds = CGRect(x:0, y:0, width: self.bounds.width, height:20)
        self.indicator.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        self.indicator.borderWidth = 1
        
        self.updateIndicator()
        self.contentView.layer.addSublayer(indicator)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didChangeIndicator(gesture:)))
        self.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didChangeIndicator(gesture:)))
        self.addGestureRecognizer(panGesture)
        
        self.contentView.layer.contentsGravity = .center
    }
    
    func updateIndicator () {
        
        let hsb = self.color.hsb
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        let centerY = self.contentView.bounds.maxY * (1 - self.brightness)
        self.indicator.position = CGPoint(x:self.contentView.bounds.midX, y:centerY)
        self.indicator.backgroundColor = HSB(hue: hsb.hue, saturation: hsb.saturation, brightness: self.brightness, alpha: 1).color.cgColor
        
        CATransaction.commit()
    }
    
    func updateColor() {
        self.contentView.layer.contents = self.createBrightSheetImage()
    }
    
    @objc private func didChangeIndicator(gesture:UIGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            self.indicator.bounds = CGRect(x: 0, y: 0, width: self.bounds.width * 1.2, height: 30)
            self.indicator.borderColor = UIColor.yellow.withAlphaComponent(0.6).cgColor
        case .ended, .cancelled :
            self.indicator.bounds = CGRect(x: 0, y: 0, width: self.bounds.width, height: 20)
            self.indicator.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        default:
            break
        }
        
        let position = gesture.location(in: self)
        let positionY = min(max(0, position.y - self.padding), self.contentView.bounds.maxY)
        self.brightness = 1 - (positionY / self.contentView.bounds.maxY)
    }
    
    func createBrightSheetImage() -> CGImage? {
        
        if self.contentView.bounds.equalTo(CGRect.zero) {
            return nil
        }
        
        let bufferLength = Int(self.contentView.bounds.width * self.contentView.bounds.height * 4)
        let bitmapData: CFMutableData = CFDataCreateMutable(nil, 0)
        CFDataSetLength(bitmapData, CFIndex(bufferLength))
        let bitmap = CFDataGetMutableBytePtr(bitmapData)
        
        let height = Int(self.contentView.bounds.maxY)
        let width = Int(self.contentView.bounds.maxX)
        
        for y in 0..<height {
            
            let brightness = 1 - (CGFloat(y) / CGFloat(height))
            
            let rgb = HSB(hue: self.color.hsb.hue, saturation: self.color.hsb.saturation, brightness: brightness, alpha: 1).rgb
            
            for x in 0..<width {
                let offset = Int(4 * (x + y * width))
                bitmap?[offset] = UInt8(rgb.red * 255)
                bitmap?[offset + 1] = UInt8(rgb.green * 255)
                bitmap?[offset + 2] = UInt8(rgb.blue * 255)
                bitmap?[offset + 3] = UInt8(rgb.alpha * 255)
            }
        }
        
        // Convert the bitmap to a CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let dataProvider = CGDataProvider(data: bitmapData)
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo().rawValue | CGImageAlphaInfo.last.rawValue)
        let imageRef = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: Int(width) * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent)
        return imageRef!
    }
}
