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

protocol ExpViewable: UIView {
    var parentExp:Exp? {get}
    var exp:Exp {get}
    func changed(view:ExpViewable, to:Exp)->Exp
    func removed(view: ExpViewable) -> Exp?
    var directSubExpViews:[ExpViewable] {get}
}
protocol ExpViewableDelegate {
    func onTap(view:ExpViewable)
    func changeto(view:ExpViewable, to: Exp)
}

extension ExpViewable {
    func removed(view: ExpViewable) -> Exp? {
        if self == view {
            //Return it's successor if exists.
            switch exp.reflect() {
            case .Add(_): return nil
            case .Mul(_): return nil
            case .Mat(_): return nil
            case .Unassigned(_): return nil
            case .NumExp(_): return nil
            case .Power(_): return nil
            case .RowEchelonForm(let e): return e.mat
            case .GaussJordanElimination(let e): return e.mat
            case .Transpose(let e): return e.mat
            case .Determinant(let e): return e.mat
            case .Fraction(_): return nil
            case .Inverse(let e): return e.mat
            case .Rank(let e): return e.mat
            case .Nullity(let e): return e.mat
            case .Norm(let e): return e.mat
            case .Unknown: return nil
            }
        }
        let removed = self.directSubExpViews.map({$0.removed(view:view)})
        switch exp.reflect() {
        case .Add(_):
            if let l = removed[0] {
                if let r = removed[1] {
                    return Add(l, r)
                } else {
                    return l
                }
            } else {
                return nil
            }
        case .Mul(_):
            if let l = removed[0] {
                if let r = removed[1] {
                    return Mul(l, r)
                } else {
                    return l
                }
            } else {
                return nil
            }
        case .Mat(let e):
            let arrIn2D = stride(from: 0, to: removed.count, by: e.cols).map({
                Array(removed[$0..<$0+e.cols].map({$0 ?? NumExp(0)}))
            })
            return Mat(arrIn2D)
        case .Unassigned(_):
            return exp
        case .NumExp(_):
            return exp
        case .Power(_):
            if let base = removed[0] {
                if let exponent = removed[1] {
                    return Power(base, exponent)
                } else {
                    return base
                }
            } else {
                return nil
            }
        case .RowEchelonForm(_):
            if let m = removed[0] {
                return RowEchelonForm(mat: m)
            } else {
                return nil
            }
        case .GaussJordanElimination(_):
            if let m = removed[0] {
                return GaussJordanElimination(m)
            } else {
                return nil
            }
        case .Transpose(_):
            if let m = removed[0] {
                return Transpose(m)
            } else {
                return nil
            }
        case .Determinant(_):
            if let m = removed[0] {
                return Determinant(m)
            } else {
                return nil
            }
        case .Fraction(_):
            if let numerator = removed[0] {
                if let denominator = removed[1] {
                    return Fraction(numerator: numerator, denominator: denominator)
                }
                else {
                    return numerator
                }
            } else if let denominator = removed[1] {
                return Fraction(numerator: NumExp(1), denominator: denominator)
            } else {
                return nil
            }
        case .Inverse(_):
            if let m = removed[0] {
                return Inverse(m)
            } else {
                return nil
            }
        case .Rank(_):
            if let m = removed[0] {
                return Rank(m)
            } else {
                return nil
            }
        case .Nullity(_):
            if let m = removed[0] {
                return Nullity(m)
            } else {
                return nil
            }
        case .Norm(_):
            if let m = removed[0] {
                return Norm(m)
            } else {
                return nil
            }
        case .Unknown:
            return exp
        }
    }
    //TODO: Currently it presumes that directSubExpViews() and subExps() are in same order.
    func changed(view: ExpViewable, to: Exp) -> Exp {
        if self == view {
            return to
        }
        let changed = self.directSubExpViews.map({$0.changed(view:view, to: to)})
        switch exp.reflect() {
        case .Add(_):
            return Add(changed[0], changed[1])
        case .Mul(_):
            return Mul(changed[0], changed[1])
        case .Mat(let e):
            let arrIn2D = stride(from: 0, to: changed.count, by: e.cols).map({
                Array(changed[$0..<$0+e.cols])
            })
            return Mat(arrIn2D)
        case .Unassigned(_):
            return exp
        case .NumExp(_):
            return exp
        case .Power(_):
            return Power(changed[0], changed[1])
        case .RowEchelonForm(_):
            return RowEchelonForm(mat: changed[0])
        case .GaussJordanElimination(_):
            return GaussJordanElimination(changed[0])
        case .Transpose(_):
            return Transpose(changed[0])
        case .Determinant(_):
            return Determinant(changed[0])
        case .Fraction(_):
            return Fraction(numerator: changed[0], denominator: changed[1])
        case .Inverse(_):
            return Inverse(changed[0])
        case .Rank(_):
            return Rank(changed[0])
        case .Nullity(_):
            return Nullity(changed[0])
        case .Norm(_):
            return Norm(changed[0])
        case .Unknown:
            return exp
        }
    }
    
}

extension Exp {

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
}

enum ExpReflection {
    case Add(Add)
    case Mul(Mul)
    case Mat(Mat)
    case Unassigned(Unassigned)
    case NumExp(NumExp)
    case Power(Power)
    case RowEchelonForm(RowEchelonForm)
    case GaussJordanElimination(GaussJordanElimination)
    case Transpose(Transpose)
    case Determinant(Determinant)
    case Fraction(Fraction)
    case Inverse(Inverse)
    case Rank(Rank)
    case Nullity(Nullity)
    case Norm(Norm)
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
        } else if let e = self as? RowEchelonForm {
            return .RowEchelonForm(e)
        } else if let e = self as? GaussJordanElimination {
            return .GaussJordanElimination(e)
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
        case .RowEchelonForm(let e): return [e.mat]
        case .GaussJordanElimination(let e): return [e.mat]
        case .Transpose(let e): return [e.mat]
        case .Determinant(let e):  return [e.mat]
        case .Fraction(let e): return [e.numerator, e.denominator]
        case .Inverse(let e): return [e.mat]
        case .Rank(let e): return [e.mat]
        case .Nullity(let e): return [e.mat]
        case .Norm(let e): return [e.mat]
        case .Unknown: return []
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
        case .RowEchelonForm(_): return RowEchelonForm(mat: changed[0])
        case .GaussJordanElimination(_): return GaussJordanElimination(changed[0])
        case .Transpose(_): return Transpose(changed[0])
        case .Determinant(_): return Determinant(changed[0])
        case .Fraction(_): return Fraction(numerator: changed[0], denominator: changed[1])
        case .Inverse(_): return Inverse(changed[0])
        case .Rank(_): return Rank(changed[0])
        case .Nullity(_): return Nullity(changed[0])
        case .Norm(_): return Norm(changed[0])
        case .Unknown: return self
        }
    }
}
