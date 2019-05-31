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
    var uid:String {get}
    func latex() -> String;
    mutating func replace(uid:String, to:Exp)-> Bool
}
protocol BinaryOp:Exp {
    var a: Exp { get }
    var b: Exp { get }
}

struct Mul: BinaryOp {
    mutating func replace(uid: String, to: Exp)-> Bool {
        if a.uid == uid {
            a = to
            return true
        } else if b.uid == uid {
            b = to
            return true
        } else {
            return a.replace(uid: uid, to: to) || b.replace(uid: uid, to: to)
        }
    }
    
    let uid: String = UUID().uuidString
    
    var a: Exp
    var b: Exp
    
    func latex() -> String {
        return "{\(a.latex())} * {\(b.latex())}"
    }
}
struct Mat:Exp {
    mutating func replace(uid: String, to: Exp)-> Bool {
        for i in 0..<elements.count {
            for j in 0..<elements[i].count {
                if elements[i][j].uid == uid {
                    elements[i][j] = to
                    return true
                }
            }
        }
        for i in 0..<elements.count {
            for j in 0..<elements[i].count {
                if elements[i][j].replace(uid: uid, to: to) {
                    return true
                }
            }
        }
        return false
    }
    
    let uid: String = UUID().uuidString
    
    func latex() -> String {
        let inner = elements.map({ $0.map({"{\($0.latex())}"}).joined(separator: " & ") }).joined(separator: "\\\\\n")
        return "\\begin{pmatrix}\n" + inner + "\n\\end{pmatrix}"
    }
    
    var elements:[[Exp]];
}
struct Unassigned:Exp {
    func replace(uid: String, to: Exp)-> Bool {  return false  }
    
    let uid: String = UUID().uuidString
    
    func latex() -> String {
        return letter
    }
    
    var letter:String
}
struct BG:Exp {
    mutating func replace(uid: String, to: Exp)-> Bool {
        if e.uid == uid {
            print("replacing BG's e to \(to.latex())")
            e = to
            return true
        }
        return e.replace(uid: uid, to: to)
    }
    
    let uid: String = UUID().uuidString
    
    func latex() -> String {
        return "\\colorbox{\(color.hex)}{\(e.latex())}"
    }
    
    var color:UIColor
    var e:Exp
}
struct Buffer:Exp {
    mutating func replace(uid: String, to: Exp)-> Bool {
        if e.uid == uid {
            e = to
            return true
        }
        return e.replace(uid: uid, to: to)
    }
    
    let uid: String = UUID().uuidString
    
    func latex() -> String {
        return e.latex()
    }
    
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
