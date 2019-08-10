//
//  ExpViewable.swift
//  mat4ipad
//
//  Created by ingun on 10/08/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit
import AlgebraEvaluator

protocol ExpViewable: UIView {
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
            return exp.coverAllCases(Add: { (_) -> Exp? in
                nil
            }, Mul: { (_) -> Exp? in
                nil
            }, Mat: { (_) -> Exp? in
                nil
            }, Unassigned: { (_) -> Exp? in
                nil
            }, NumExp: { (_) -> Exp? in
                nil
            }, Power: { (_) -> Exp? in
                nil
            }, RowEchelonForm: { (e) -> Exp? in
                return e.mat
            }, GaussJordanElimination: { (e) -> Exp? in
                return e.mat
            }, Transpose: { (e) -> Exp? in
                return e.mat
            }, Determinant: { (e) -> Exp? in
                return e.mat
            }, Fraction: { (_) -> Exp? in
                return nil
            }, Inverse: { (e) -> Exp? in
                return e.mat
            }, Rank: { (e) -> Exp? in
                return e.mat
            }, Nullity: { (e) -> Exp? in
                return e.mat
            })
        }
        return exp.coverAllCases(Add: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view:view)})
            if removed.count == 0 {
                return nil
            } else if removed.count == 1 {
                return removed[0]
            } else {
                return Add(removed[0], removed[1])
            }
        }, Mul: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view:view)})
            if removed.count == 0 {
                return nil
            } else if removed.count == 1 {
                return removed[0]
            } else {
                return Mul(removed[0], removed[1])
            }
        }, Mat: { (e) -> Exp? in
            let removed = self.directSubExpViews.map({$0.removed(view:view) ?? NumExp(0)})
            let arrIn2D = stride(from: 0, to: removed.count, by: e.cols).map({
                Array(removed[$0..<$0+e.cols])
            })
            return Mat(arrIn2D)
        }, Unassigned: { (e) -> Exp? in
            return e
        }, NumExp: { (e) -> Exp? in
            return e
        }, Power: { (e) -> Exp? in
            let removed = self.directSubExpViews.map({$0.removed(view: view)})
            if let base = removed[0] {
                if let exponent = removed[1] {
                    return Power(base, exponent)
                } else {
                    return base
                }
            } else {
                return nil
            }
        }, RowEchelonForm: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view: view)})
            if let m = removed.first {
                return RowEchelonForm(mat: m)
            } else {
                return nil
            }
        }, GaussJordanElimination: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view: view)})
            if let m = removed.first {
                return GaussJordanElimination(m)
            } else {
                return nil
            }
        }, Transpose: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view: view)})
            if let m = removed.first {
                return Transpose(m)
            } else {
                return nil
            }
        }, Determinant: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view: view)})
            if let m = removed.first {
                return Determinant(m)
            } else {
                return nil
            }
        }, Fraction: { (e) -> Exp? in
            let removed = self.directSubExpViews.map({$0.removed(view: view)})
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
        }, Inverse: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view: view)})
            if let m = removed.first {
                return Inverse(m)
            } else {
                return nil
            }
        }, Rank: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view: view)})
            if let m = removed.first {
                return Rank(m)
            } else {
                return nil
            }
        }, Nullity: { (e) -> Exp? in
            let removed = self.directSubExpViews.compactMap({$0.removed(view: view)})
            if let m = removed.first {
                return Nullity(m)
            } else {
                return nil
            }
        })
    }
    //TODO: Currently it presumes that directSubExpViews() and subExps() are in same order.
    func changed(view: ExpViewable, to: Exp) -> Exp {
        if self == view {
            return to
        }
        return exp.coverAllCases(Add: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view:view, to: to)})
            return Add(changed[0], changed[1])
        }, Mul: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view:view, to: to)})
            return Mul(changed[0], changed[1])
        }, Mat: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view:view, to: to)})
            let arrIn2D = stride(from: 0, to: changed.count, by: e.cols).map({
                Array(changed[$0..<$0+e.cols])
            })
            return Mat(arrIn2D)
        }, Unassigned: { (e) -> Exp in
            return e
        }, NumExp: { (e) -> Exp in
            return e
        }, Power: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return Power(changed[0], changed[1])
        }, RowEchelonForm: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return RowEchelonForm(mat: changed[0])
        }, GaussJordanElimination: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return GaussJordanElimination(changed[0])
        }, Transpose: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return Transpose(changed[0])
        }, Determinant: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return Determinant(changed[0])
        }, Fraction: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return Fraction(numerator: changed[0], denominator: changed[1])
        }, Inverse: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return Inverse(changed[0])
        }, Rank: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return Rank(changed[0])
        }, Nullity: { (e) -> Exp in
            let changed = self.directSubExpViews.map({$0.changed(view: view, to: to)})
            return Nullity(changed[0])
        })
    }
    
}

extension Exp {
    func coverAllCases<T>(
        Add:(Add)->T,
        Mul:(Mul)->T,
        Mat:(Mat)->T,
        Unassigned:(Unassigned)->T,
        NumExp:(NumExp)->T,
        Power:(Power)->T,
        RowEchelonForm:(RowEchelonForm)->T,
        GaussJordanElimination:(GaussJordanElimination)->T,
        Transpose:(Transpose)->T,
        Determinant:(Determinant)->T,
        Fraction:(Fraction)->T,
        Inverse:(Inverse)->T,
        Rank:(Rank)->T,
        Nullity:(Nullity)->T
        )->T {
        
        if let e = self as? Add {
            return Add(e)
        } else if let e = self as? Mul {
            return Mul(e)
        } else if let e = self as? Mat {
            return Mat(e)
        } else if let e = self as? Unassigned {
            return Unassigned(e)
        } else if let e = self as? NumExp {
            return NumExp(e)
        } else if let e = self as? Power {
            return Power(e)
        } else if let e = self as? RowEchelonForm {
            return RowEchelonForm(e)
        } else if let e = self as? GaussJordanElimination {
            return GaussJordanElimination(e)
        } else if let e = self as? Transpose {
            return Transpose(e)
        } else if let e = self as? Determinant {
            return Determinant(e)
        } else if let e = self as? Fraction {
            return Fraction(e)
        } else if let e = self as? Inverse {
            return Inverse(e)
        } else if let e = self as? Rank {
            return Rank(e)
        } else if let e = self as? Nullity {
            return Nullity(e)
        }
        //TODO:
        fatalError()
    }
    
    /// Return all it's direct sub exps.
    ///
    /// The order of exps in return array is preserved
    func subExps()->[Exp] {
        return coverAllCases(Add: {[$0.l, $0.r]}, Mul: {[$0.l,$0.r]}, Mat: {$0.elements.flatMap({$0})}, Unassigned: {_ in []}, NumExp: {_ in []}, Power: {[$0.base, $0.exponent]}, RowEchelonForm: {[$0.mat]}, GaussJordanElimination: {[$0.mat]}, Transpose: {[$0.mat]}, Determinant: {[$0.mat]}, Fraction: {[$0.numerator, $0.denominator]}, Inverse: {[$0.mat]}, Rank: {[$0.mat]}, Nullity: {[$0.mat]})
    }
    func changed(eqTo:Exp, to:Exp)->Exp {
        if isEq(eqTo) {
            return to
        }
        return coverAllCases(Add: { (e) -> Exp in
            Add(e.l.changed(eqTo:eqTo, to:to), e.r.changed(eqTo:eqTo, to:to))
        }, Mul: { (e) -> Exp in
            Mul(e.l.changed(eqTo:eqTo, to:to), e.r.changed(eqTo:eqTo, to:to))
        }, Mat: { (e) -> Exp in
            Mat(e.elements.map({
                $0.map({
                    $0.changed(eqTo: eqTo, to: to)
                })
            }))
        }, Unassigned: { (e) -> Exp in
            e
        }, NumExp: { (e) -> Exp in
            e
        }, Power: { (e) -> Exp in
            Power(e.base.changed(eqTo: eqTo, to: to), e.exponent.changed(eqTo: eqTo, to: to))
        }, RowEchelonForm: { (e) -> Exp in
            RowEchelonForm(mat:e.mat.changed(eqTo: eqTo, to: to))
        }, GaussJordanElimination: { (e) -> Exp in
            GaussJordanElimination(e.mat.changed(eqTo: eqTo, to:to))
        }, Transpose: { (e) -> Exp in
            Transpose(e.mat.changed(eqTo: eqTo, to:to))
        }, Determinant: { (e) -> Exp in
            Determinant(e.mat.changed(eqTo: eqTo, to:to))
        }, Fraction: { (e) -> Exp in
            Fraction(numerator: e.numerator.changed(eqTo: eqTo, to: to), denominator: e.denominator.changed(eqTo: eqTo, to: to))
        }, Inverse: { (e) -> Exp in
            Inverse(e.mat.changed(eqTo: eqTo, to:to))
        }, Rank: { (e) -> Exp in
            Rank(e.mat.changed(eqTo: eqTo, to:to))
        }, Nullity: { (e) -> Exp in
            Nullity(e.mat.changed(eqTo: eqTo, to:to))
        })
    }
}
