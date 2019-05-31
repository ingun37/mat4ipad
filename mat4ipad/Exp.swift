//
//  Exp.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit

protocol item {
    
}
enum Err:Error {
    case stackisempty
    case unknownArith
}

protocol Exp: item {
    func latex() -> String;
}
protocol BinaryOp:Exp {
    var a: Exp { get }
    var b: Exp { get }
}
struct Mul:BinaryOp {
    var a: Exp
    
    var b: Exp
    
    func latex() -> String {
        return "{\(a.latex())} * {\(b.latex())}"
    }
}
struct Mat:Exp {
    func latex() -> String {
        let inner = elements.map({ $0.map({"{\($0.latex())}"}).joined(separator: " & ") }).joined(separator: "\\\\\n")
        return "\\begin{pmatrix}\n" + inner + "\n\\end{pmatrix}"
    }
    
    var elements:[[Exp]];
}
struct Unassigned:Exp {
    func latex() -> String {
        return letter
    }
    
    var letter:String
}
struct BG:Exp {
    func latex() -> String {
        return "\\colorbox{\(color.hex)}{\(e.latex())}"
    }
    
    var color:UIColor
    var e:Exp
}
extension UIColor {
    var hex: String {
        get {
            var r:CGFloat = 0
            var g:CGFloat = 0
            var b:CGFloat = 0
            var a:CGFloat = 0
            
            getRed(&r, green: &g, blue: &b, alpha: &a)
            
            let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
            
            return NSString(format:"#%06x", rgb) as String
        }
    }
}
