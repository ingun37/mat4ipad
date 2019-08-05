//
//  ExpOp.swift
//  mat4ipad
//
//  Created by ingun on 03/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation

func if2<T:Exp>(_ a:Exp, _ b:Exp, _ c:(T, T) throws ->Exp?) throws ->Exp? {
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
func if1V(_ a:Exp, _ b:Exp, _ c:(VectorSpace, Exp) throws ->Exp?) throws ->Exp? {
    if let a = a as? VectorSpace {
        return try c(a, b)
    } else if let b = b as? VectorSpace {
        return try c(b, a)
    }
    return nil
}
func if2V(_ a:Exp, _ b:Exp, _ c:(VectorSpace, VectorSpace) throws ->Exp?) throws ->Exp? {
    if let a = a as? VectorSpace, let b = b as? VectorSpace {
        return try c(a, b)
    }
    return nil
}
func add(_ a:Exp, _ b:Exp) throws -> Exp {
    return try if2V(a, b, { (a, b) -> Exp in
        return try a.added(b)
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
        if new2d.count == 1 {
            if new2d.first?.count == 1 {
                return new2d[0][0]
            }
        }
        return Mat(new2d)
    }) ?? if2(a, b, { (a:Unassigned, b:Unassigned) -> Exp in
        return Unassigned("\(a.letter)\(b.letter)")
    }) ?? if1(a, b, { (a:NumExp, b) -> Exp? in
        if let b = b as? VectorSpace {
            return try b.scalarMultiplied(a)
        }
        return nil
    }) ?? Mul([a, b])
}
