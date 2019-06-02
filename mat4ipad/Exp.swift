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
func replaced(e:Exp, uid:String, to:Exp)-> Exp {
    var o = e
    o.kids = o.kids.map({replaced(e: $0, uid: uid, to: to)})
    o.kids = o.kids.map({$0.uid == uid ? to : $0})
    if let o = o as? AssociativeExp {
        return o.associated()
    }
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
    if let o = o as? AssociativeExp {
        return o.associated()
    }
    return o
}

protocol Exp{
    var uid: String {get}
    var kids:[Exp] {get set}
    func latex() -> String
    func needRetire()->Int?
    func needRemove()->Bool
    func eval() throws ->Exp
}
protocol AssociativeExp:Exp {
    func associated()->Exp
}
extension AssociativeExp {
    func associated()->Exp {
        var o = self
        o.kids = kids.flatMap({ $0 is Self ? $0.kids : [$0]})
        return o
    }
}

enum evalErr:Error {
    case operandIsNotMatrix(Exp)
    case matrixSizeNotMatch(Mat, Mat)
    case multiplyNotSupported(Exp, Exp)
}
extension evalErr {
    func describeInLatex() -> String {
        switch self {
        case let .operandIsNotMatrix(e):
            return "\\text{operand is not a matrix: }{\(e.latex())}"
        case let .matrixSizeNotMatch(a, b):
            return "\\text{matrix size not match} {\(a.latex())} * {\(b.latex())}"
        case let .multiplyNotSupported(a , b):
            return "\\text{multiply not supported} {\(a.latex())} * {\(b.latex())}"
        }
    }
}
func add(_ a:Exp, _ b:Exp) throws -> Exp {
    if let a = a as? IntExp, let b = b as? IntExp {
        return IntExp(a.i + b.i)
    }
    if let a = a as? IntExp {
        if a.i == 0 {
            return b
        }
    }
    if let b = b as? IntExp {
        if b.i == 0 {
            return a
        }
    }
    return Add([a, b])
}
func mul(_ e1:Exp, _ e2:Exp) throws ->Exp {//never call eval in here
    if let a = e1 as? Mat, let b = e2 as? Mat {
        guard a.cols == b.rows else {
            throw evalErr.matrixSizeNotMatch(a, b)
        }
        let new2d = try (0..<a.rows).map({i in
            try (0..<b.cols).map({j in
                try zip(a.row(i), b.col(j)).map({try mul($0, $1)}).reduce(Add.unit(), {Add([$0, $1])})
            })
        })
        return Mat(new2d)
    }
    
    if let a = e1 as? Unassigned, let b = e2 as? Unassigned {
        return Unassigned("\(a.letter)\(b.letter)")
    }

    if let a = e1 as? IntExp, let b = e2 as? IntExp {
        return IntExp(a.i * b.i)
    }
    if let a = e1 as? IntExp {
        if a.i == 1 {
            return e2
        }
    }
    if let b = e2 as? IntExp {
        if b.i == 1 {
            return e1
        }
    }

    return Mul([e1, e2])
}
extension Mat {
    func row(_ i:Int)->ArraySlice<Exp> {
        return kids[i*cols..<i*cols+cols]
    }
    func col(_ j:Int)->[Exp] {
        return (0..<rows).map({$0*cols + j}).map({kids[$0]})
    }
}
class Add:AssociativeExp {
    var uid: String = UUID().uuidString
    var kids: [Exp] = []
    func latex() -> String {
        return kids.map({"{\($0.latex())}"}).joined(separator: " + ")
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
    
    func eval() throws -> Exp {
        var r = try kids.map({try $0.eval()}).reduce(Add.unit(), {try add($0, $1)})
        r.kids = try r.kids.map({try $0.eval()})
        return r
    }
    
    static func unit()->Exp {
        return IntExp(0)
    }
    init(_ operands:[Exp]) {
        kids = operands
    }
}
class Mul: AssociativeExp {
    static func unit()->Exp {
        return IntExp(1)
    }
    func eval() throws -> Exp {
        var r = try kids.map({try $0.eval()}).reduce(Mul.unit(), {try mul($0, $1)})
        r.kids = try r.kids.map({try $0.eval()})
        return r
    }
    
    var uid: String = UUID().uuidString
    
    var kids: [Exp] = []
    
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
    func eval() throws -> Exp {
        return self
    }
    
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
    func eval() throws -> Exp {
        return self
    }
    
    var uid: String = UUID().uuidString
    var kids: [Exp] = []
    func needRetire() -> Int? { return nil }
    func needRemove() -> Bool { return false }
    
    func latex() -> String {
        return letter
    }
    
    var letter:String
    init(_ l:String) {
        letter = l
    }
}
class IntExp:Exp {
    func eval() throws -> Exp {
        return self
    }
    
    var uid: String  = UUID().uuidString
    var kids: [Exp] = []
    func needRetire() -> Int? { return nil }
    func needRemove() -> Bool { return false }

    
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
