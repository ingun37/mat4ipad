//
//  ExpOp.swift
//  mat4ipad
//
//  Created by ingun on 03/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
func replaced(e:Exp, uid:String, to:Exp)-> Exp {
    if e.uid == uid {
        return to
    }
    
    var o = e
    o.kids = o.kids.map({replaced(e: $0, uid: uid, to: to)})
    return o
}
func removed(e:Exp, uid:String)-> Exp? {
    if e.uid == uid {
        return nil
    }
    if e is Add {
        let newkids = e.kids.compactMap({removed(e: $0, uid: uid)})
        if newkids.count == 1 {
            return newkids[0]
        } else if newkids.isEmpty {
            return nil
        } else {
            return Add(newkids)
        }
    } else if e is Mul {
        let newkids = e.kids.compactMap({removed(e: $0, uid: uid)})
        if newkids.count == 1 {
            return newkids[0]
        } else if newkids.isEmpty {
            return nil
        } else {
            return Mul(newkids)
        }
    } else if let e = e as? Mat {
        let newkids = e.kids.map({removed(e: $0, uid: uid)})
        let newkids2 = newkids.map({ $0 ?? NumExp(0)})
        let newkids2D = (0..<e.rows).map({ri in
            (0..<e.cols).map({ci in
                newkids2[ri*e.cols + ci]
            })
        })
        return Mat(newkids2D)
    } else if e is Unassigned {
        return e
    } else if e is NumExp {
        return e
    } else if let e = e as? Power {
        if let newbase = removed(e: e.base, uid: uid) {
            if let newExponent = removed(e: e.exponent, uid: uid) {
                return Power(newbase, newExponent)
            } else {
                return newbase
            }
        } else {
            return nil
        }
        
    } else if let e = e as? RowEchelonForm {
        if let newMat = removed(e: e.mat, uid: uid) {
            guard let newMat = newMat as? Mat else {
                fatalError()
            }
            return RowEchelonForm(mat: newMat)
        } else {
            return nil
        }
    } else if let e = e as? GaussJordanElimination {
        if let newMat = removed(e: e.mat, uid: uid) {
            guard let newMat = newMat as? Mat else {
                fatalError()
            }
            return GaussJordanElimination(mat: newMat)
        } else {
            return nil
        }
    } else if let e = e as? Transpose {
        if let newMat = removed(e: e.mat, uid: uid) {
            guard let newMat = newMat as? Mat else {
                fatalError()
            }
            return Transpose(newMat)
        } else {
            return nil
        }
    } else if let e = e as? Determinant {
        if let newMat = removed(e: e.mat, uid: uid) {
            guard let newMat = newMat as? Mat else {
                fatalError()
            }
            return Determinant(newMat)
        } else {
            return nil
        }
    } else {
        fatalError()
    }
}
func if2<T:Exp>(_ a:Exp, _ b:Exp, _ c:(T, T) throws ->Exp) throws ->Exp? {
    if let a = a as? T, let b = b as? T {
        return try c(a, b)
    }
    return nil
}
func if1<T:Exp>(_ a:Exp, _ b:Exp, _ c:(T, Exp) throws ->Exp?) throws ->Exp? {
    if let a = a as? T {
        return try c(a, b)
    } else if let b = b as? T {
        return try c(b, a)
    }
    return nil
}
func add(_ a:Exp, _ b:Exp) throws -> Exp {
    return try if2(a, b, { (a:Mat, b:Mat) -> Exp in
        guard a.cols == b.cols && a.rows == b.rows else {
            throw evalErr.matrixSizeNotMatch(a, b)
        }
        let new2d = try (0..<a.rows).map({i in
            try zip(a.row(i), b.row(i)).map({ try add($0, $1) })
        })
        return Mat(new2d)
    }) ?? if2(a, b, { (a:NumExp, b:NumExp) -> Exp in
        return a+b
    }) ?? if1(a, b, { (a:NumExp, b) -> Exp? in
        return a.isZero ? b : nil
    }) ?? Add([a, b])
}
func mul(_ a:Exp, _ b:Exp) throws ->Exp {//never call eval in here
    return try if2(a, b, { (a:Mat, b:Mat) -> Exp in
        guard a.cols == b.rows else {
            throw evalErr.matrixSizeNotMatch(a, b)
        }
        let new2d = try (0..<a.rows).map({i in
            try (0..<b.cols).map({j-> Exp in
                let products = try zip(a.row(i), b.col(j)).map({try mul($0, $1)})
                return try products.dropFirst().reduce(products[0], {try add($0, $1)})
            })
        })
        return Mat(new2d)
    }) ?? if2(a, b, { (a:Unassigned, b:Unassigned) -> Exp in
        return Unassigned("\(a.letter)\(b.letter)")
    }) ?? if2(a, b, { (a:NumExp, b:NumExp) -> Exp in
        return a * b
    }) ?? if1(a, b, { (a:NumExp, b) -> Exp? in
        if a.isIdentity {
            return b
        }
        if let b = b as? Mat {
            let rows = try (0..<b.rows).map({try b.row($0).map({try mul($0, a)})})
            return Mat(rows)
        }
        return nil
    }) ?? Mul([a, b])
}
