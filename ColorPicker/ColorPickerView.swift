//
//  ColorPickerView.swift
//  ColorPicker
//
//  Created by rutinfc on 2020/01/10.
//  Copyright © 2020 rutinfc. All rights reserved.
//

import UIKit

public enum ColorType {
    case main, complementary, harmony
}

public class ColorPickerView : UIView {
    
    @IBOutlet weak var colorWheelView: ColorWheelView!
    @IBOutlet weak var brightnessView: ColorBrightnessView!
    
    public var harmony : ColorHarmonyType = .none {
        didSet {
            self.colorWheelView.calculator = self.harmony.calculator()
        }
    }
    
    public var color : UIColor = UIColor.white {
        didSet {
            if self.colorWheelView.currentColor != color {
                self.brightnessView.color = color
                self.colorWheelView.currentColor = color
            }
        }
    }
    
    /// Description
    /// colors index = 0 : primary, index = 1 : complementary, others : harmony colors
    public var didChangeColorsWithType : (([(type:ColorType, color:UIColor)])->Void)?
    
    public static func createPicker() -> ColorPickerView? {
        
        let array = Bundle(for: ColorPickerView.self).loadNibNamed("ColorPickerView", owner: self, options: nil)
        
        guard let view = array?.first as? ColorPickerView else {
            return nil
        }
        return view
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.loadControls()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadControls()
    }
    
}

fileprivate extension ColorPickerView {
    
    /// <#Description#>
    func loadControls() {
        
        self.colorWheelView.calculator = self.harmony.calculator()
        
        self.brightnessView.updatePickerBrightness = { [weak self] (brightness) in
            self?.colorWheelView.brightness = brightness
        }
        
        self.colorWheelView.updatePickerColors = { [weak self] (colors) in
            
            guard let primaryColor = colors.first else {
                return
            }
            
            if self?.brightnessView.color != primaryColor {
                self?.brightnessView.color = primaryColor
            }
            
            // 하모니 기능을 하지 않을 경우에는 primary colors만 반환하고 종료
            if let type = self?.harmony, type == .none {
                DispatchQueue.main.async {
                    self?.didChangeColorsWithType?([(type:ColorType.main, color:primaryColor)])
                }
                
                return
            }
            
            let complementary = primaryColor.complementary
            var response = colors.enumerated().compactMap { (offset,element) -> (type:ColorType, color:UIColor)? in
                if offset == 0 {
                    return (type:.main, color:element)
                }
                return (type:.harmony, color:element)
            }
            response.append((type:.complementary, color:complementary))
            
            DispatchQueue.main.async {
                self?.didChangeColorsWithType?(response)
            }
        }
    }
}
