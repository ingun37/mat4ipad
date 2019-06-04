//
//  Exp.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit
import NumberKit

protocol Exp{
    var uid: String {get}
    var kids:[Exp] {get set}
    func latex() -> String
    /**
     Aware that kids could be missing in this function
     */
    func needRetire()->Int?
    /**
     Aware that kids could be missing in this function
     */
    func needRemove()->Bool
    /**
     Don't call eval of a newly created object inside of eval which is a possible !!!!
     */
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
    case invalidExponent(Exp, Exp)
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
        case let .invalidExponent(b, x):
            return "\\text{invalid exponent} {{\(b.latex())}^{\(x.latex())}}"
        }
    }
}

struct Add:AssociativeExp {
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
        let kds = try kids.map({try $0.eval()})
        return try kds.dropFirst().reduce(kds[0], {try add($0, $1)})
    }
    
    init(_ operands:[Exp]) {
        kids = operands
    }
}
struct Mul: AssociativeExp {
    func eval() throws -> Exp {
        let kds = try kids.map({try $0.eval()})
        return try kds.dropFirst().reduce(kds[0], {try mul($0, $1)})
    }
    
    var uid: String = UUID().uuidString
    
    var kids: [Exp] = []
    
    func latex() -> String {
        return kids.map({ e in
            if e is Add {
                return "({\(e.latex())})"
            } else {
                return "{\(e.latex())}"
            }
        }).joined(separator: " * ")
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
protocol VectorSpace: Exp {
    func identity()-> Self
    var isZero:Bool {get}
    var isIdentity:Bool {get}
}
struct Mat:VectorSpace {
    var isZero: Bool {
        return kids.allSatisfy({ ($0 as? NumExp)?.isZero ?? false})
    }
    
    var isIdentity: Bool {
        return (0..<rows*cols).allSatisfy { (i) -> Bool in
            if i%(cols+1) == 0 {
                return (kids[i] as? NumExp)?.isIdentity ?? false
            } else {
                return (kids[i] as? NumExp)?.isZero ?? false
            }
        }
    }
    static func identityOf(_ r:Int, _ c:Int)-> Mat {
        let arr2d = (0..<r).map({ri in
            return (0..<c).map({ci in
                return ci == ri ? NumExp(1) : NumExp(0)
            })
        })
        return Mat(arr2d)
    }
    func identity() -> Mat {
        return Mat.identityOf(rows, cols)
    }
    
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
    func row(_ i:Int)->[Exp] {
        return Array(kids[i*cols..<i*cols+cols])
    }
    func col(_ j:Int)->[Exp] {
        return (0..<rows).map({$0*cols + j}).map({kids[$0]})
    }
}
struct Unassigned:Exp {
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
struct NumExp:VectorSpace {
    static func * (left: NumExp, right: NumExp) -> NumExp {
        switch left.num {
        case let .Float(v):
            switch right.num {
            case let .Float(w):
                return NumExp(v * w)
            case let .Int(w):
                return NumExp(v * Float(w))
            case let .Rational(w):
                return NumExp(v * w.floatValue)
            }
        case let .Int(v):
            switch right.num {
            case let .Float(w):
                return NumExp(Float(v) * w)
            case let .Int(w):
                return NumExp(v * w)
            case let .Rational(w):
                return NumExp(w * Rational(v))
            }
        case let .Rational(v):
            switch right.num {
            case let .Float(w):
                return NumExp(v.floatValue * w)
            case let .Int(w):
                return NumExp(v * Rational(w))
            case let .Rational(w):
                return NumExp(v * w)
            }
        }
    }
    static func + (left: NumExp, right: NumExp) -> NumExp {
        switch left.num {
        case let .Float(v):
            switch right.num {
            case let .Float(w):
                return NumExp(v + w)
            case let .Int(w):
                return NumExp(v + Float(w))
            case let .Rational(w):
                return NumExp(v + w.floatValue)
            }
        case let .Int(v):
            switch right.num {
            case let .Float(w):
                return NumExp(Float(v) + w)
            case let .Int(w):
                return NumExp(v + w)
            case let .Rational(w):
                return NumExp(w + Rational(v))
            }
        case let .Rational(v):
            switch right.num {
            case let .Float(w):
                return NumExp(v.floatValue + w)
            case let .Int(w):
                return NumExp(v + Rational(w))
            case let .Rational(w):
                return NumExp(v + w)
            }
        }
    }
    var isZero: Bool {
        switch num {
        case let .Float(f):
            return f == 0
        case let .Int(i):
            return i == 0
        case let .Rational(r):
            return r.numerator == 0
        }
    }
    
    var isIdentity: Bool {
        switch num {
        case let .Float(f):
            return f == 1
        case let .Int(i):
            return i == 1
        case let .Rational(r):
            return r.numerator == r.denominator
        }
    }
    
    var intValue:Int? {
        switch num {
        case let .Float(f):
            return f == floor(f) ? Int(f) : nil
        case let .Int(i):
            return i
        case let .Rational(r):
            return r.numerator % r.denominator == 0 ? r.numerator/r.denominator : nil
        }
    }
    enum NumType {
        case Int(Int)
        case Float(Float)
        case Rational(Rational<Int>)
    }
    let num:NumType
    init(_ i:Int) {
        num = .Int(i)
    }
    init(_ f:Float) {
        num = .Float(f)
    }
    init(_ numerator:Int, _ denominator:Int) {
        num = .Rational(Rational(numerator, denominator))
    }
    init(_ r:Rational<Int>) {
        num = .Rational(r)
    }
    func identity() -> NumExp {
        return NumExp(1)
    }
    
    func eval() throws -> Exp {
        return self
    }
    
    func latex() -> String {
        switch num {
        case let .Rational(r):
            return "\\frac{\(r.numerator)}{\(r.denominator)}"
        case let .Int(i):
            return "\(i)"
        case let .Float(f):
            return "\(f)"
        }
    }
    
    var uid: String  = UUID().uuidString
    var kids: [Exp] = []
    func needRetire() -> Int? { return nil }
    func needRemove() -> Bool { return false }
}
struct Power: Exp {
    var base:Exp {
        return kids[0]
    }
    var exponent:Exp {
        return kids[1]
    }
    init(_ base:Exp, _ exponent:Exp) {
        kids = [base, exponent]
    }
    func eval() throws -> Exp {//dont' evaluate a newly created thing.
        let b = try base.eval()
        let x = try exponent.eval()
        if let x = x as? NumExp {
            if x.isZero {
                if let b = b as? VectorSpace {
                    return b.identity()
                }
            } else if x.isIdentity {
                return b
            } else if let n = x.intValue {
                return try Array(repeating: b, count: n-1).reduce(b, {try mul($0, $1)})
            } else {
                throw evalErr.invalidExponent(b, x)
            }
        } else {
            throw evalErr.invalidExponent(b, x)
        }
        return Power(b, x)
    }
    
    var uid: String = UUID().uuidString
    
    var kids: [Exp] = []
    
    func latex() -> String {
        let kid = kids[0]
        let base:String
        if kid is Mul || kid is Add {
            base = "(\(kid.latex()))"
        } else {
            base = kid.latex()
        }
        return "{\(base)}^{\(exponent.latex())}"
    }
    
    func needRetire() -> Int? {
        if kids.count == 1 {
            return 0
        }
        return ((exponent as? NumExp)?.isIdentity ?? false) ? 0 : nil
    }
    func needRemove() -> Bool {
        return kids.isEmpty
    }
}
extension Int {
    var exp:Exp {
        return NumExp(self)
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
