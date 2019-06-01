//
//  Exp.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit

enum Err:Error {
    case stackisempty
    case unknownArith
}
//func stripBGs(_ e:Exp)->Exp {
//    if e is BG {
//        return stripBGs(e.kids[0])
//    } else {
//        return e
//    }
//}
//protocol Expvv{
//    let uid: String = UUID().uuidString
//    var kids:[Exp] = []
//    func latex() -> String {
//        return ""
//    }
//    func needRetire()->Int? {
//        return nil
//    }
//    func needRemove()->Bool {
//        return false
//    }
//    func associative() {
//        if self is Mul {
//            if let idx = kids.firstIndex(where: {stripBGs($0) is Mul}) {
//                let mulKid = stripBGs(kids.remove(at: idx))
//                kids.insert(contentsOf: mulKid.kids, at: idx)
//                associative()
//                return
//            }
//        }
//    }
//    func remove(uid:String) {
//        kids.forEach({$0.remove(uid: uid)})
//        kids.removeAll(where: {$0.uid == uid})
//        kids.removeAll(where: {$0.needRemove()})
//
//        for i in 0..<kids.count {
//            if let successor = kids[i].needRetire() {
//                kids[i] = kids[i].kids[successor]
//            }
//        }
//        associative()
//    }
//}
func replaced(e:Exp, uid:String, to:Exp)-> Exp {
    var o = e
    o.kids = o.kids.map({replaced(e: $0, uid: uid, to: to)})
    o.kids = o.kids.map({$0.uid == uid ? to : $0})
    o.associative()
    return o
}
func removed(e:Exp, uid:String)-> Exp {
    var o = e
    o.kids.removeAll(where: {$0.uid == uid})
    o.kids = o.kids.map({removed(e: $0, uid: uid)})
    o.kids.removeAll(where: {$0.needRemove()})
    o.kids = o.kids.map({ e in
        if let successor = e.needRetire() {
            return e.kids[successor]
        } else {
            return e
        }
    })
    o.associative()
    return o
}
protocol Exp{
    var uid: String {get}
    var kids:[Exp] {get set}
    func latex() -> String
    func needRetire()->Int?
    func needRemove()->Bool
    func associative()
}
//struct BG:Exp {
//    var uid: String = UUID().uuidString
//    var kids: [Exp] = []
//
//    func needRetire() -> Int? { return nil }
//    func needRemove() -> Bool { return kids.isEmpty }
//    func associative() {}
//
//    func latex() -> String {
//        return "\\colorbox{\(color.hex)}{\(kids[0].latex())}"
//    }
//    var e:Exp {
//        return kids[0]
//    }
//    let color:UIColor = UIColor(hue: CGFloat(Float.random(in: 0.0..<1.0)), saturation: CGFloat(Float.random(in: 0.25..<0.4)), brightness: CGFloat(Float.random(in: 0.7..<0.9)), alpha: 1)
//
//    init(_ e:Exp) {
//        kids = [e]
//    }
//}
class Mul: Exp {
    var uid: String = UUID().uuidString
    
    var kids: [Exp] = []
    
    func associative() {
        if let idx = kids.firstIndex(where: {$0 is Mul}) {
            let mulKid = kids.remove(at: idx)
            kids.insert(contentsOf: mulKid.kids, at: idx)
            associative()
        }
    }
    
    func latex() -> String {
        return kids.map({"{\($0.latex())}"}).joined(separator: " * ")
    }
    init(_ operands:[Exp]) {
        kids = operands
    }
    func needRetire() -> Int? {
        if kids.count == 1 {
            return 0
        } else {
            return nil
        }
    }
    func needRemove() -> Bool {
        return kids.isEmpty
    }
}
class Mat:Exp {
    var uid: String = UUID().uuidString
    var kids: [Exp] = []
    func needRetire() -> Int? { return nil }
    func needRemove() -> Bool { return kids.isEmpty }
    func associative() { }
    
    let rows, cols:Int
    func latex() -> String {
        let array2d = (0..<rows).map({r in kids[r*cols..<r*cols+cols]})
        
        let inner = array2d.map({ $0.map({"{\($0.latex())}"}).joined(separator: " & ") }).joined(separator: "\\\\\n")
        return "\\begin{pmatrix}\n" + inner + "\n\\end{pmatrix}"
    }
    init(r:Int, c:Int) {
        rows = r
        cols = c
        kids = Array(repeating: Unassigned("A"), count: rows*cols)
    }
    init(_ arr2d:[[Exp]]) {
        rows = arr2d.count
        cols = arr2d[0].count
        kids = arr2d.flatMap({$0})
    }
    init(_ arr2d:[ArraySlice<Exp>]) {
        rows = arr2d.count
        cols = arr2d[0].count
        kids = arr2d.flatMap({$0})
    }
}
class Unassigned:Exp {
    var uid: String = UUID().uuidString
    var kids: [Exp] = []
    func needRetire() -> Int? { return nil }
    func needRemove() -> Bool { return false }
    func associative() { }
    
    func latex() -> String {
        return letter
    }
    
    var letter:String
    init(_ l:String) {
        letter = l
    }
}
class IntExp:Exp {
    var uid: String  = UUID().uuidString
    var kids: [Exp] = []
    func needRetire() -> Int? { return nil }
    func needRemove() -> Bool { return false }
    func associative() {}
    
    var i:Int = 0
    func latex() -> String {
        return "\(i)"
    }
    init(_ i:Int) {
        self.i = i
    }
}
//class Buffer:Exp {
//    var uid: String = UUID().uuidString
//    var kids: [Exp] = []
//    func needRetire() -> Int? {return nil}
//    func associative() {    }
//    
//    func latex() -> String {
//        return kids[0].latex()
//    }
//    
//    init(_ e:Exp) {
//        kids = [e]
//    }
//    
//    var e:Exp {
//        return kids[0]
//    }
//    func needRemove() -> Bool {
//        return kids.isEmpty
//    }
//}
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
