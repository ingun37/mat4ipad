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
    func needRetire()->Int?
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
        return try kids.map({try $0.eval()}).reduce(Add.unit(), {try add($0, $1)})
    }
    
    static func unit()->Exp {
        return IntExp(0)
    }
    init(_ operands:[Exp]) {
        kids = operands
    }
}
struct Mul: AssociativeExp {
    static func unit()->Exp {
        return IntExp(1)
    }
    func eval() throws -> Exp {
        return try kids.map({try $0.eval()}).reduce(Mul.unit(), {try mul($0, $1)})
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
}
struct Mat:VectorSpace {
    func identity() -> Mat {
        return Mat([[IntExp(1), IntExp(0)],[IntExp(0), IntExp(1)]])
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
    init(_ arr2d:[ArraySlice<Exp>]) {
        rows = arr2d.count
        cols = arr2d[0].count
        kids = arr2d.flatMap({$0})
    }
    func row(_ i:Int)->ArraySlice<Exp> {
        return kids[i*cols..<i*cols+cols]
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
struct IntExp:VectorSpace {
    func identity() -> IntExp {
        return IntExp(1)
    }
    
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
        if let x = x as? IntExp {
            if x.i == 0 {
                if let b = b as? VectorSpace {
                    return b.identity()
                }
            } else {
                return try Array(repeating: b, count: x.i-1).reduce(b) {try mul($0, $1)}
            }
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
        if let x = exponent as? IntExp {
            if x.i == 1 {
                return 0
            }
        }
        return nil
    }
    func needRemove() -> Bool {
        return kids.isEmpty
    }
}
extension Int {
    var exp:Exp {
        return IntExp(self)
    }
}
extension Rational where T == Int {
    var exp:Exp {
        return RationalExp(numerator.exp, denominator.exp)
    }
}
struct RationalExp:VectorSpace {
    func identity() -> RationalExp {
        return RationalExp(IntExp(1), IntExp(1))
    }
    
    func eval() throws -> Exp {
        let nu = try numerator.eval()
        let de = try denominator.eval()

        if let de = de as? IntExp {
            if de.i == 1 {
                return nu
            }
            if let nu = nu as? IntExp {//if both is IntExp
                if nu.i == 0 {
                    return 0.exp
                }
                let r = Rational(nu.i, de.i)
                if r.denominator == 1 {
                    return r.numerator.exp
                } else {
                    return r.exp
                }
            }
        }
        return self
    }
    
    var uid: String  = UUID().uuidString
    var kids: [Exp] = []
    func needRetire() -> Int? { return nil }
    func needRemove() -> Bool { return false }
    
    var numerator:Exp {
        return kids[0]
    }
    var denominator:Exp {
        return kids[1]
    }
    
    func latex() -> String {
        return "\\frac{\(numerator.latex())}{\(denominator.latex())}"
    }
    init(_ numerator:Exp, _ denominator:Exp) {
        kids = [numerator, denominator]
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
