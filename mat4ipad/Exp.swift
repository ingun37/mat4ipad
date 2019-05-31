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
    mutating func askRemove(removingUid:String)->Bool
}
protocol MultiOp:Exp {
    var elements:[Exp] {get}
}

struct Mul: MultiOp {
    mutating func askRemove(removingUid: String) -> Bool {
        if removingUid == uid {
            return true
        }
        
        (0..<elements.count).filter({elements[$0].askRemove(removingUid: removingUid)}).sorted(by: {$0>$1}).forEach({removingIdx in
            self.elements.remove(at: removingIdx)
        })

        return elements.count < 2
    }
    
    var elements: [Exp]
    
    mutating func replace(uid: String, to: Exp)-> Bool {
        for i in 0..<elements.count {
            if elements[i].uid == uid {
                elements[i] = to
                return true
            }
        }
        for i in 0..<elements.count {
            if elements[i].replace(uid: uid, to: to) {
                return true
            }
        }
        return false
    }
    
    let uid: String = UUID().uuidString
    
    func latex() -> String {
        return elements.map({"{\($0.latex())}"}).joined(separator: " * ")
    }
}
struct Mat:Exp {
    func askRemove(removingUid: String) -> Bool {
        return uid == removingUid
    }
    
    
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
    func askRemove(removingUid: String) -> Bool {
        return removingUid == uid
    }
    
    func replace(uid: String, to: Exp)-> Bool {  return false  }
    
    let uid: String = UUID().uuidString
    
    func latex() -> String {
        return letter
    }
    
    var letter:String
}
struct BG:Exp {
    mutating func askRemove(removingUid: String) -> Bool {
        if uid == removingUid {
            return true
        }
        return e.askRemove(removingUid: removingUid)
    }
    
    mutating func replace(uid: String, to: Exp)-> Bool {
        if e.uid == uid {
            e = to
            return true
        }
        return e.replace(uid: uid, to: to)
    }
    
    let uid: String = UUID().uuidString
    
    func latex() -> String {
        return "\\colorbox{\(color.hex)}{\(e.latex())}"
    }
    
    let color:UIColor = UIColor(hue: CGFloat(Float.random(in: 0.0..<1.0)), saturation: CGFloat(Float.random(in: 0.25..<0.4)), brightness: CGFloat(Float.random(in: 0.7..<0.9)), alpha: 1)
    var e:Exp
}
struct Buffer:Exp {
    mutating func askRemove(removingUid: String) -> Bool {
        if uid == removingUid {
            return true
        }
        return e.askRemove(removingUid: removingUid)
    }
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
