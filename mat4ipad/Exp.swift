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
    
    /// Clone itself with different UID. Kids must have all new UIDs.
    func clone()->Exp
    
    func changeKid(from:String, to:Exp)->Exp
    
    var kids:[Exp] {get}
    func latex() -> String

    /**
     Don't call eval of a newly created object inside of eval which is a possible !!!!
     */
    func eval() throws ->Exp
}
extension Exp {
    func changed(from:String, to:Exp)-> Exp {
        if uid == from {
            return to
        }
        return changeKid(from: from, to: to)
    }
    
}


enum evalErr:Error {
    case operandIsNotMatrix(Exp)
    case matrixSizeNotMatch(Mat, Mat)
    case multiplyNotSupported(Exp, Exp)
    case invalidExponent(Exp, Exp)
    case RowEcheloningWrongExp
    case InvalidMatrixToRowEchelon
    case ZeroRowEchelon
    case InvertingNonSquareMatrix
    case invertingDeterminantZero
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
        case .RowEcheloningWrongExp:
            return "asfd"
        case .InvalidMatrixToRowEchelon:
            return "asdfasfd"
        case .ZeroRowEchelon:
            return "asdfasdfasdf"
        case .InvertingNonSquareMatrix:
            return "inverting non square matrix"
        case .invertingDeterminantZero:
            return "inverting a matrix with determinant of zero"
        }
    }
}

struct Add:Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return Add(kids.map({$0.changed(from: from, to: to)}))
    }
    
    func clone() -> Exp {
        return Add(kids.map({$0.clone()}))
    }
    
    var uid: String = UUID().uuidString
    var kids: [Exp] = []
    func latex() -> String {
        return kids.map({"{\($0.latex())}"}).joined(separator: " + ")
    }
    
    func eval() throws -> Exp {
        let kds = try kids.map({try $0.eval()})
        return try kds.dropFirst().reduce(kds[0], {try add($0, $1)})
    }
    
    init(_ operands:[Exp]) {
        kids = operands
    }
}
struct Mul: Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return Mul(kids.map({$0.changed(from: from, to: to)}))
    }
    
    func clone() -> Exp {
        return Mul(kids.map({$0.clone()}))
    }
    
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
    
}
protocol VectorSpace: Exp {
    func identity()-> Self
    var isZero:Bool {get}
    var isIdentity:Bool {get}
}
struct Mat:VectorSpace {
    func changeKid(from: String, to: Exp) -> Exp {
        return Mat(rowArr.map({
            $0.map({$0.changed(from: from, to: to)})
        }))
    }
    
    func clone() -> Exp {
        return Mat(rowArr.map({
            $0.map({$0.clone()})
        }))
    }
    
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
    func rowDropped(first:Int)->Mat {
        let restRows = (first..<rows).map({row($0)})
        return Mat(restRows)
    }
    var rowArr:[[Exp]] {
        return (0..<rows).map({self.row($0)})
    }
    func rowMultiply(by:NumExp, at:Int)throws->Mat {
        var rs = rowArr
        guard let multipliedRow = try mul(rs[at].asMat, by) as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        rs[at] = multipliedRow.kids
        return Mat(rs)
    }
    func rowAddToOther(from:Int, to:Int, by:NumExp)throws ->Mat {
        var rs = rowArr
        guard let multipliedRow = try mul(rs[from].asMat, by) as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        guard let addedRow = try add(multipliedRow, rs[to].asMat) as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        rs[to] = addedRow.kids
        return Mat(rs)
    }
    func drop(row:Int)-> Mat {
        let rs = (0..<rows).filter({$0 != row}).map({self.row($0)})
        return Mat(rs)
    }
    func transpose()->Mat {
        let arr = (0..<cols).map({ col($0) })
        return Mat(arr)
    }
    func drop(col:Int)-> Mat {
        let cs = (0..<cols).filter({$0 != col}).map({self.col($0)})
        return Mat(cs).transpose()
    }
    func determinant()throws -> Exp {
        if cols == 1 && rows == 1 {
            return row(0)[0]
        }
        let entries = row(0)
        let cofactors = try (0..<cols).map({try self.cofactor(row: 0, col: $0)})
        let p = try zip(entries, cofactors).map({try mul($0.0, $0.1)})
        let first = p[0]
        let rest = p.dropFirst()
        let sum = try rest.reduce(first, {
            try add($0, $1)
        })
        return sum
    }
    func minor(row:Int, col:Int)throws -> Exp {
        let dropped = drop(row: row).drop(col: col)
        return try dropped.determinant()
    }
    func cofactor(row:Int, col:Int)throws -> Exp {
        let m = try minor(row: row, col: col)
        return (row + col).isOdd ? try mul(NumExp(-1), m) : m
    }
    func adjoint()throws -> Mat {
        let arr2d = try (0..<rows).map({ri in
            try (0..<cols).map({ci in
                try cofactor(row: ri, col: ci)
            })
        })
        return Mat(arr2d).transpose()
    }
}
extension Array where Element == Exp {
    var asMat:Mat {
        return Mat([self])
    }
}
struct Unassigned:Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return self
    }
    
    func clone() -> Exp {
        return Unassigned(letter)
    }
    
    func eval() throws -> Exp {
        return self
    }
    
    var uid: String = UUID().uuidString
    var kids: [Exp] = []
    
    func latex() -> String {
        return letter
    }
    
    var letter:String
    init(_ l:String) {
        letter = l
    }
}
struct NumExp:VectorSpace {
    func changeKid(from: String, to: Exp) -> Exp {
        return self
    }
    
    func clone() -> Exp {
        return NumExp(num)
    }
    
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
                let mul = w * Rational(v)
                if let iv = mul.intValue {
                    return NumExp(iv)
                } else {
                    return NumExp(mul)
                }
            }
        case let .Rational(v):
            switch right.num {
            case .Float(_):
                return right * left
            case .Int(_):
                return right * left
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
    
    var inverse:NumExp {
        switch num {
        case let .Int(i):
            return NumExp(1, i)
        case let .Float(f):
            return NumExp(1/f)
        case let .Rational(r):
            return NumExp(r.denominator, r.numerator)
        }
    }
    
    var minus:NumExp {
        switch num {
        case let .Int(i):
            return NumExp(-i)
        case let .Float(f):
            return NumExp(-f)
        case let .Rational(r):
            return NumExp(-r.numerator, r.denominator)
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
    init(_ num:NumType) {
        switch num {
        case let .Int(i):
            self.init(i)
        case let .Float(f):
            self.init(f)
        case let .Rational(r):
            self.init(r)
        }
    }
    func identity() -> NumExp {
        return NumExp(1)
    }
    static func identity() -> NumExp {
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
}
struct Power: Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return Power(base.changed(from: from, to: to), exponent.changed(from: from, to: to))
    }
    
    func clone() -> Exp {
        return Power(base.clone(), exponent.clone())
    }
    
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

struct RowEchelonForm:Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return RowEchelonForm(mat: mat.changed(from: from, to: to) as! Mat)
    }
    
    func clone() -> Exp {
        return RowEchelonForm(mat: mat.clone() as! Mat)
    }
    
    var uid: String = UUID().uuidString

    var kids: [Exp]
    
    func latex() -> String {
        return "\\text{REF}(\(kids[0].latex()))"
    }
    
    private func leftMostEntry(m:Mat) throws ->(Int, Int) {
        for ci in 0..<m.cols {
            for ri in 0..<m.rows {
                guard let n = m.row(ri)[ci] as? NumExp else {
                    throw evalErr.InvalidMatrixToRowEchelon
                }
                if !n.isZero {
                    return (ri, ci)
                }
            }
        }
        return (m.rows-1, m.cols-1)
    }
    private func interchangeRow(m:Mat, r1:Int, r2:Int)->Mat {
        var rows = (0..<m.rows).map({m.row($0)})
        rows.swapAt(r1, r2)
        return Mat(rows)
    }

    
    
    func eval() throws -> Exp {
        guard let mat = try kids[0].eval() as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        let (row, col) = try leftMostEntry(m: mat)
        let interchanged = interchangeRow(m: mat, r1: 0, r2: row)
        guard let entry = mat.row(row)[col] as? NumExp else {
            throw evalErr.InvalidMatrixToRowEchelon
        }
        guard !entry.isZero else {
            return mat
        }
        var entryNormalized = try interchanged.rowMultiply(by: entry.inverse, at: 0)
        for ri in 1..<entryNormalized.rows {
            guard let e = entryNormalized.row(ri)[col] as? NumExp else {
                throw evalErr.RowEcheloningWrongExp
            }
            entryNormalized = try entryNormalized.rowAddToOther(from: 0, to: ri, by: e.minus)
        }
        if entryNormalized.rows == 1 {
            return entryNormalized
        }
        let top = entryNormalized.row(0)
        let rest = Mat((1..<entryNormalized.rows).map({entryNormalized.row($0)}))
        guard let echelon2 = try RowEchelonForm(mat: rest).eval() as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        return Mat([top] + echelon2.rowArr)
        
    }
    
    init(mat:Mat) {
        kids = [mat]
    }
    var mat:Mat {
        return kids[0] as! Mat
    }
}

struct GaussJordanElimination:Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return GaussJordanElimination(mat: mat.changed(from: from, to: to) as! Mat)
    }
    
    func clone() -> Exp {
        return GaussJordanElimination(mat: mat.clone() as! Mat)
    }
    
    var uid: String = UUID().uuidString

    var kids: [Exp]
    
    func latex() -> String {
        return "\\text{GJE}(\(kids[0].latex()))"
    }
    
    func eval() throws -> Exp {
        guard let m = kids[0] as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        guard var ech = try RowEchelonForm(mat: m).eval() as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        for i in 1..<ech.rows {
            if let leftmostIdx = ech.row(i).firstIndex(where: {($0 as! NumExp).isZero == false}) {
                for j in 0..<i {
                    let a = ech.row(j)[leftmostIdx] as! NumExp
                    ech = try ech.rowAddToOther(from: i, to: j, by: a.minus)
                }
            } else {
                break
            }
        }
        return ech
    }
    
    init(mat:Mat) {
        kids = [mat]
    }
    var mat:Mat {
        return kids[0] as! Mat
    }
}

struct Transpose:Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return Transpose(mat.changed(from: from, to: to) as! Mat)
    }
    
    func clone() -> Exp {
        return Transpose(mat.clone() as! Mat)
    }
    
    var uid: String = UUID().uuidString

    var kids: [Exp]
    
    func latex() -> String {
        return "{\(kids[0].latex())}^\\top"
    }
    
    
    func eval() throws -> Exp {
        guard let m = kids[0] as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        let arr = (0..<m.cols).map({ m.col($0) })
        return Mat(arr)
    }
    init(_ m:Mat) {
        kids = [m]
    }
    var mat:Mat {
        return kids[0] as! Mat
    }
}

struct Determinant:Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return Determinant(mat.changed(from: from, to: to) as! Mat)
    }
    
    func clone() -> Exp {
        return Determinant(mat.clone() as! Mat)
    }
    
    var uid: String = UUID().uuidString

    var kids: [Exp]
    
    func latex() -> String {
        return "det{\(kids[0].latex())}"
    }
    
    
    func eval() throws -> Exp {
        guard let m = try kids[0].eval() as? Mat else {
            throw evalErr.RowEcheloningWrongExp
        }
        guard m.cols == m.rows else {
            throw evalErr.InvertingNonSquareMatrix
        }
        return try m.determinant().eval()
        
    }
    init(_ m:Mat) {
        kids = [m]
    }
    var mat:Mat {
        return kids[0] as! Mat
    }
}

struct Fraction:Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return Fraction(numerator: numerator.changed(from: from, to: to), denominator: denominator.changed(from: from, to: to))
    }
    
    func clone() -> Exp {
        return Fraction(numerator: numerator.clone(), denominator: denominator.clone())
    }
    
    var uid: String = UUID().uuidString
    
    var kids: [Exp] = [Unassigned("N"), Unassigned("D")]
    var numerator:Exp {
        get { return kids[0] }
        set { kids[0] = newValue }
    }
    var denominator:Exp {
        get { return kids[1] }
        set { kids[1] = newValue }
    }
    func latex() -> String {
        return "\\frac{\(numerator.latex())}{\(denominator.latex())}"
    }
    
    func eval() throws -> Exp {
        let n = try numerator.eval()
        let d = try denominator.eval()
        if let n = n as? NumExp, let d = d as? NumExp {
            return try mul(n, d.inverse)
        }
        return Fraction(numerator: n, denominator: d)
    }
    
    init(numerator:Exp, denominator:Exp) {
        self.numerator = numerator
        self.denominator = denominator
    }
}

struct Inverse:Exp {
    func changeKid(from: String, to: Exp) -> Exp {
        return Inverse(mat.changed(from: from, to: to) as! Mat)
    }
    
    func clone() -> Exp {
        return Inverse(mat.clone() as! Mat)
    }
    
    var uid: String = UUID().uuidString
    
    var kids: [Exp]
    
    func latex() -> String {
        return "{\(kids[0].latex())}^{-1}"
    }
    
    func eval() throws -> Exp {
        let m = mat
        guard m.rows == m.cols else {
            throw evalErr.InvertingNonSquareMatrix
        }
        let det = try m.determinant()
        if (det as? NumExp)?.isZero ?? false {
            throw evalErr.invertingDeterminantZero
        }
        let invdet = (det as? NumExp)?.inverse ?? Fraction(numerator: NumExp.identity(), denominator: det) as Exp
        return try mul(invdet, m.adjoint())
    }
    init(_ m:Mat) {
        kids = [m]
    }
    var mat:Mat {
        return kids[0] as! Mat
    }
}
