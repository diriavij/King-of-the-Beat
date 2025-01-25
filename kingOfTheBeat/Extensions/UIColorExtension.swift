//
//  UIColorExtension.swift
//  fapopovPW1
//
//  Created by Фома Попов on 10.10.2024.
//

import UIKit

// MARK: - Hex to RGB extension
extension UIColor {
    
    
    //MARK: - Private Methods
    static func hexCharToValue(_ char: Character) -> Int? {
        let notation: Int = 16
        switch char {
        case "0"..."9":
            return Int(String(char), radix: notation)
        case "A"..."F":
            return Int(String(char), radix: notation)
        default:
            return nil
        }
    }
    
    
    static private func hexStringToCGFloat(_ hexString: String) -> CGFloat {
        var result: CGFloat = 0.0
        var power: CGFloat = 1.0
        
        for char in hexString.reversed() {
            guard let digit = hexCharToValue(char) else {
                return 0
            }
            result += CGFloat(digit) * power
            power *= 16.0
        }
        
        return result
    }
    
    //MARK: - Public Methods
    static func convertToRGBInit(_ hex: String) -> UIColor {
        let maxValue: CGFloat = 256
        let alphaValue: CGFloat = 1
        
        let stringRed: String = String(hex.prefix(2))
        let stringGreen: String = String(hex.dropFirst(2).dropLast(2))
        let stringBlue: String = String(hex.suffix(2))
        
        let red = hexStringToCGFloat(stringRed) / maxValue
        let green = hexStringToCGFloat(stringGreen) / maxValue
        let blue = hexStringToCGFloat(stringBlue) / maxValue
        
        return UIColor(red: red, green: green, blue: blue, alpha: alphaValue)
    }
    
    func getOpposite() -> UIColor {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(red: 1.0 - red, green: 1.0 - green, blue: 1.0 - blue, alpha: alpha)
    }
}
