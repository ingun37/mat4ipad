//
//  ExpViewable.swift
//  mat4ipad
//
//  Created by ingun on 10/08/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit
import ExpressiveAlgebra

struct ParentInfo {
    let exp:Exp
    let kidNumber:Int
}
protocol ExpViewable: UIView {
    var lineage:[ParentInfo] {get}
    var exp:Exp {get}
    var directSubExpViews:[ExpViewable] {get}
}
protocol ExpViewableDelegate {
    func onTap(view:ExpViewable)
    func changeto(view:ExpViewable, to: Exp)
}

extension Exp {
    func refRemove(lineage:[ParentInfo], from:Exp)-> Exp? {
        guard let head = lineage.first else {
            if isEq(from) {
                switch reflect() {
                case .Add(_), .Mul(_), .Mat(_), .Unassigned(_), .NumExp(_), .Power(_), .Fraction(_), .Unknown, .Subtract(_):
                    return nil
                case .RowEchelon(_), .ReducedRowEchelon(_), .Transpose(_), .Determinant(_), .Inverse(_), .Rank(_), .Norm(_), .Nullity(_):
                    return kids().first
                }
            } else {
                return self
            }
        }
        if isEq(head.exp) {
            let newKids = (0..<kids().count).map({ (idx) -> Exp? in
                if idx == head.kidNumber {
                    return kids()[idx].refRemove(lineage: []+lineage.dropFirst(), from: from)
                } else {
                    return kids()[idx]
                }
            })
            
            switch reflect() {
            case .Add(_), .Mul(_), .Subtract(_):
                let remainingKids = newKids.compactMap({$0})
                if remainingKids.isEmpty {
                    return nil
                } else if remainingKids.count == 1 {
                    return remainingKids[0]
                } else {
                    return cloneWith(kids: remainingKids)
                }
            case .Mat(_):
                return cloneWith(kids: newKids.map({$0 ?? NumExp(0)}))
            case .Unassigned(_), .NumExp(_):
                return self
            case .Power(_):
                if let base = newKids[0] {
                    if let exponent = newKids[1] {
                        return Power(base, exponent)
                    } else {
                        return base
                    }
                } else {
                    return nil
                }
            case .RowEchelon(_), .ReducedRowEchelon(_), .Transpose(_), .Determinant(_), .Inverse(_), .Rank(_), .Nullity(_), .Norm(_):
                if let m = newKids[0] {
                    return cloneWith(kids: [m])
                } else {
                    return nil
                }
            case .Fraction(_):
                if let numerator = newKids[0] {
                    if let denominator = newKids[1] {
                        return Fraction(numerator: numerator, denominator: denominator)
                    }
                    else {
                        return numerator
                    }
                } else if let denominator = newKids[1] {
                    return Fraction(numerator: NumExp(1), denominator: denominator)
                } else {
                    return nil
                }
            case .Unknown:
                return self
            }
        }
        return self
    }
    /// Return all it's direct sub exps.
    ///
    /// The order of exps in return array is preserved
    func subExps()->[Exp] {
        return kids()
    }
    func changed(eqTo:Exp, to:Exp)->Exp {
        if isEq(eqTo) {
            return to
        }
        return cloneWith(kids: kids().map({$0.changed(eqTo: eqTo, to: to)}))
    }
    func refChanged(lineage:[ParentInfo], from: Exp, to:Exp)-> Exp {
        guard let head = lineage.first else {
            if isEq(from) {
                return to
            } else {
                return self
            }
        }
        if isEq(head.exp) {
            return cloneWith(kids: (0..<kids().count).map({ (idx) -> Exp in
                if idx == head.kidNumber {
                    return kids()[idx].refChanged(lineage: []+lineage.dropFirst(), from: from, to: to)
                } else {
                    return kids()[idx]
                }
            }))
        }
        return self
    }
}

enum ExpReflection {
    case Add(Add)
    case Mul(Mul)
    case Mat(Mat)
    case Unassigned(Unassigned)
    case NumExp(NumExp)
    case Power(Power)
    case RowEchelon(RowEchelon)
    case ReducedRowEchelon(ReducedRowEchelon)
    case Transpose(Transpose)
    case Determinant(Determinant)
    case Fraction(Fraction)
    case Inverse(Inverse)
    case Rank(Rank)
    case Nullity(Nullity)
    case Norm(Norm)
    case Subtract(Subtract)
    case Unknown
}

extension Exp {
    func reflect()->ExpReflection {
        if let e = self as? Add {
            return .Add(e)
        } else if let e = self as? Mul {
            return .Mul(e)
        } else if let e = self as? Mat {
            return .Mat(e)
        } else if let e = self as? Unassigned {
            return .Unassigned(e)
        } else if let e = self as? NumExp {
            return .NumExp(e)
        } else if let e = self as? Power {
            return .Power(e)
        } else if let e = self as? RowEchelon {
            return .RowEchelon(e)
        } else if let e = self as? ReducedRowEchelon {
            return .ReducedRowEchelon(e)
        } else if let e = self as? Transpose {
            return .Transpose(e)
        } else if let e = self as? Determinant {
            return .Determinant(e)
        } else if let e = self as? Fraction {
            return .Fraction(e)
        } else if let e = self as? Inverse {
            return .Inverse(e)
        } else if let e = self as? Rank {
            return .Rank(e)
        } else if let e = self as? Nullity {
            return .Nullity(e)
        } else if let e = self as? Norm {
            return .Norm(e)
        } else if let e = self as? Subtract {
            return .Subtract(e)
        } else {
            return .Unknown
        }
    }
}

extension Exp {
    func kids()->[Exp] {
        switch reflect() {
        case .Add(let e): return [e.l, e.r]
        case .Mul(let e): return [e.l, e.r]
        case .Mat(let e): return e.elements.flatMap { $0 }
        case .Unassigned(let e): return []
        case .NumExp(let e): return []
        case .Power(let e): return [e.base, e.exponent]
        case .RowEchelon(let e): return [e.mat]
        case .ReducedRowEchelon(let e): return [e.mat]
        case .Transpose(let e): return [e.mat]
        case .Determinant(let e):  return [e.mat]
        case .Fraction(let e): return [e.numerator, e.denominator]
        case .Inverse(let e): return [e.mat]
        case .Rank(let e): return [e.mat]
        case .Nullity(let e): return [e.mat]
        case .Norm(let e): return [e.mat]
        case .Unknown: return []
        case .Subtract(let e): return [e.l, e.r]
        }
    }
    func cloneWith(kids:[Exp])->Exp {
        let changed = kids
        switch reflect() {
        case .Add(_): return Add(changed[0], changed[1])
        case .Mul(_): return Mul(changed[0], changed[1])
        case .Mat(let e):
            let arrIn2D = stride(from: 0, to: changed.count, by: e.cols).map({
                Array(changed[$0..<$0+e.cols])
            })
            return Mat(arrIn2D)
        case .Unassigned(_): return self
        case .NumExp(_): return self
        case .Power(_): return Power(changed[0], changed[1])
        case .RowEchelon(_): return RowEchelon(mat: changed[0])
        case .ReducedRowEchelon(_): return ReducedRowEchelon(changed[0])
        case .Transpose(_): return Transpose(changed[0])
        case .Determinant(_): return Determinant(changed[0])
        case .Fraction(_): return Fraction(numerator: changed[0], denominator: changed[1])
        case .Inverse(_): return Inverse(changed[0])
        case .Rank(_): return Rank(changed[0])
        case .Nullity(_): return Nullity(changed[0])
        case .Norm(_): return Norm(changed[0])
        case .Unknown: return self
        case .Subtract(_): return Subtract(changed[0], changed[1])
        }
    }
}
