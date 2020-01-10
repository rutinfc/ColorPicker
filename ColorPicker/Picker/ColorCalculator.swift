//
//  ColorCalculator.swift
//  ColorPicker
//
//  Created by rutinfc on 2020/01/08.
//  Copyright © 2020 rutinfc. All rights reserved.
//

import UIKit

enum ColorHarmonyType {
    
    case none, analogous, triadic
    
    func calculator() -> ColorCalculator {
        
        switch self {
        case .none:
            return ColorCalculator()
        case .analogous:
            return AnalogousColorCalculator()
            
        case .triadic:
            return TriadicColorCalculator()
        }
    }
}

class ColorCalculator {

    var points = [CGPoint]()
    var pointCount : Int = 0
    var radius : CGFloat = 0
    
    var centerPoint = CGPoint()
    
    fileprivate var theta : Double {
        return Double(atan2(self.centerPoint.y, self.centerPoint.x))
    }
    
    func calc() {
//        print("\(self.centerPoint) | \(self.rad2deg(self.theta))")
    }
    
    func rad2deg(_ number:Double) -> Double {
        return number * 180 / Double.pi
    }
    
    func deg2rad(_ number:Double) -> Double {
        return number * Double.pi / 180
    }
}

class AnalogousColorCalculator : ColorCalculator {
    
    override init() {
        super.init()
        self.pointCount = 2
    }
    
    override func calc() {
        
        self.points.removeAll()
        
        let degree = self.rad2deg(self.theta)
        
        let points = (1...pointCount).map { (index) -> CGPoint in
            let theta = self.deg2rad(degree + (30.0 * Double(index)))
            let x = cos(theta) * Double(radius)
            let y = sin(theta) * Double(radius)
            return CGPoint(x: x, y: y)
        }
        self.points.append(contentsOf: points)
    }
}

class TriadicColorCalculator : ColorCalculator {
    
    override init() {
        super.init()
        self.pointCount = 3
    }
    
    override func calc() {
        
        self.points.removeAll()
        
        let degree = self.rad2deg(self.theta)
        
        let points = (1...pointCount).map { (index) -> CGPoint in
            let theta = self.deg2rad(degree + ((360.0/Double(self.pointCount)) * Double(index)))
            let x = cos(theta) * Double(radius)
            let y = sin(theta) * Double(radius)
            return CGPoint(x: x, y: y)
        }
        self.points.append(contentsOf: points)
    }
}
