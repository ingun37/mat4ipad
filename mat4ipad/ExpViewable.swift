//
//  ExpViewable.swift
//  mat4ipad
//
//  Created by ingun on 10/08/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit
import NonEmpty
import ComplexMatrixAlgebra

struct Lineage {
    let chain:[Int]
    let exp:Exp
}
protocol ExpViewable: UIView {
    var lineage:Lineage {get}
    var exp:Exp {get}
}


extension Exp {
    func refRemove(chain:[Int])-> Exp? {
        guard let head = chain.first else {
            if let firstKid = kids().first {
                return firstKid
            } else {
                return nil
            }
        }
    
        let newKids = (0..<kids().count).map({ (idx) -> Exp? in
            if idx == head {
                return kids()[idx].refRemove(chain: []+chain.dropFirst())
            } else {
                return kids()[idx]
            }
        })
        let remainingKids = newKids.compactMap({$0})
        let whenBinary:()->Exp? = {
            if let x = remainingKids.first {
                if let y = remainingKids.dropFirst().first {
                    return self.cloneWith(kids: [x,y])
                }
                return x
            }
            return nil
        }
        let whenUnary:()->Exp? = {
            if let x = remainingKids.first {
                return self.cloneWith(kids: [x])
            } else { return nil }
        }
        switch self {
        case let .M(m):
            switch m.c {
            case let .e(e): return self
            case let .o(o):
                switch o {
                case .ReducedEchelon(_): return whenUnary()
                case .Inverse(_): return whenUnary()
                case .Echelon(_): return whenUnary()
                case let .Ring(r):
                    switch r {
                    case let .Abelian(o):
                        switch o {
                        case let .Monoid(o):
                            switch o {
                            case .Add(_): return whenBinary()
                            }
                        case .Negate(_): return whenUnary()
                        case .Subtract(_, _):  return whenBinary()
                        }
                    case let .MMonoid(o):
                        switch o {
                        case .Mul(_):  return whenBinary()
                        }
                    }
                case .Scale(_, _):
                    if let m = newKids[1] {
                        return m
                    } else {
                        return nil
                    }
                }
            }
        case let .R(r):
            switch r.c {
            case .e(_): return self
            case let .o(o):
                switch o {
                case let .f(f):
                    switch f {
                    case let .Abelian(a):
                        switch a {
                        case let .Monoid(m):
                            switch m {
                            case .Add(_): return whenBinary()
                            }
                        case .Negate(_): return whenUnary()
                        case .Subtract(_, _): return whenBinary()
                        }
                    case .Conjugate(_): return whenUnary()
                    case .Determinant(_):
                        if case let .M(m) = newKids.first {
                            return .R(Real(fieldOp: .Determinant(m)))
                        } else {
                            return nil
                        }
                    case let .Mabelian(ma):
                        switch ma {
                        case .Inverse(_): return whenUnary()
                        case let .Monoid(m):
                            switch m {
                            case .Mul(_): return whenBinary()
                            }
                        case .Quotient(_, _):
                            if case let .R(denom) = newKids[1] {
                                if case let .R(numer) = newKids[0] {
                                    return .R(Real(mabelianOp: .Quotient(numer, denom)))
                                }
                                return .R(Real(mabelianOp: .Inverse(denom)))
                            } else if case let .R(numer) = newKids[0] {
                                return .R(numer)
                            } else {
                                return nil
                            }
                        }
                    case .Power(_, _):
                        if case let .R(base) = newKids[0] {
                            if case let .R(exp) = newKids[1] {
                                return .R(Real(fieldOp: .Power(base: base, exponent: exp)))
                            }
                            return .R(base)
                        } else {
                            return nil
                        }
                    }
                }
            }
        }
    }
    /// Return all it's direct sub exps.
    ///
    /// The order of exps in return array is preserved
    func subExps()->[Exp] {
        switch self {
        case let .M(m):
            switch m.c {
            case let .e(m):
                switch m {
                case let .Basis(mb):
                    switch mb {
                    case let .Matrix(m):
                        return m.rows.all.flatMap({$0.all}).map({.R($0)})
                    case .id(_): return []
                    case .zero: return []
                    }
                case .Var(_): return []
                }
            case let .o(o):
                switch o {
                case let .Echelon(m): return [.M(m)]
                case let .Inverse(m): return [.M(m)]
                case let .ReducedEchelon(m): return [.M(m)]
                case let .Ring(r):
                    switch r {
                    case let .Abelian(ab):
                        switch ab {
                        case let .Monoid(m):
                            switch m {
                            case let .Add(a): return [.M(a.l), .M(a.r)]
                            }
                        case let .Negate(m): return [.M(m)]
                        case let .Subtract(x,y): return [.M(x), .M(y)]
                        }
                    case let .MMonoid(ma):
                        switch ma {
                        case let .Mul(m): return [.M(m.l), .M(m.r)]
                        }
                    }
                case let .Scale(k, m): return [.R(k), .M(m)]
                }
            }
        case let .R(r):
            switch r.c {
            case let .e(e): return []
            case let .o(o):
                switch o {
                case let .f(f):
                    switch f {
                    case let .Abelian(ab):
                        switch ab {
                        case let .Monoid(m):
                            switch m {
                            case let .Add(b): return [.R(b.l), .R(b.r)]
                            }
                        case let .Negate(r): return [.R(r)]
                        case let .Subtract(x, y): return [.R(x), .R(y)]
                        }
                    case let .Conjugate(r): return [.R(r)]
                    case let .Determinant(m): return [.M(m)]
                    case let .Mabelian(ma):
                        switch ma {
                        case let .Inverse(r): return [.R(r)]
                        case let .Monoid(mon):
                            switch mon {
                            case let .Mul(b): return [.R(b.l), .R(b.r)]
                            }
                        case let .Quotient(x, y): return [.R(x), .R(y)]
                        }
                    case .Power(let base, let exponent): return [.R(base), .R(exponent)]
                    }
                }
            }
        }
    }
    func changed(eqTo:Exp, to:Exp)->Exp {
        if self == eqTo {
            return to
        }
        
        return cloneWith(kids: kids().map({$0.changed(eqTo: eqTo, to: to)}))
    }
    func refChanged(chain:[Int], to:Exp)-> Exp {
        guard let head = chain.first else {
            return to
        }
        let kids = self.kids()
        return cloneWith(kids: (0..<kids.count).map({ (idx) -> Exp in
            if idx == head {
                return kids[idx].refChanged(chain: []+chain.dropFirst(), to: to)
            } else {
                return kids[idx]
            }
        }))
    
    }
}

extension NonEmptyArray {
    var list:List<Element> {
        return List(first, dropFirst())
    }
}
extension Exp {
    func eval()->Exp {
        switch self {
        case let .M(m): return .M(m.eval())
        case let .R(r): return .R(r.eval())
        }
    }
    func prettify()->Exp {
        switch self {
        case let .M(m): return .M(m.prettyfy())
        case let .R(r): return .R(r.prettyfy())
        }
    }
    func latex()->String {
        switch self {
        case let .M(m):
            return (m).latex()
        case let .R(r):
            return (r).latex()
        }
    }
    func sameTypeVar(name:String)->Exp {
        switch self {
        case let .M(m): return .M(.init(.e(.Var(name))))
        case let .R(r): return .R(.init(.e(.Var(name))))
        }
    }
    func kids()->[Exp] {
        return subExps()
    }
    func cloneWith(kids:[Exp])->Exp {
        let m1:Matrix<Real>?
        if case let .M(m) = kids.first {
            m1 = m
        } else { m1 = nil }
        let m2:Matrix<Real>?
        if case let .M(m) = kids.dropFirst().first {
            m2 = m
        } else { m2 = nil }
        let r1:Real?
        if case let .R(r) = kids.first {
            r1 = r
        } else { r1 = nil }
        let r2:Real?
        if case let .R(r) = kids.dropFirst().first {
            r2 = r
        } else { r2 = nil }
        switch self {
        case let .M(m):
            switch m.c {
            case let .e(e):
                switch e {
                case let .Basis(mb):
                    switch mb {
                    case let .Matrix(m):
                        let realKids = kids.map { (k) -> Real in
                            if case let .R(r) = k {
                                return r
                            } else {return Real(.e(.Basis(.N(0))))}
                        }
                        let newElements:List<List<Real>> = NonEmpty(0, 1..<m.rowLen).map { (rowIdx)-> List<Real> in
                            let cRng = NonEmpty(0, 1..<m.colLen)
                            let realRow = cRng.map({colIdx in
                                realKids[rowIdx * m.colLen + colIdx]
                            })
                            return realRow.list
                        }.list
                        return .M(Matrix<Real>(.e(.Basis(.Matrix(.init(e: newElements))))))
                    case .id(_): return self
                    case .zero: return self
                    }
                case .Var(_): return self
                }
            case let .o(o):
                switch o {
                case let .Echelon(m): return .M(.init(.o(.Echelon(m1 ?? m))))
                case let .Inverse(m): return .M(.init(.o(.Echelon(m1 ?? m))))
                case let .ReducedEchelon(m): return .M(.init(.o(.Echelon(m1 ?? m))))
                case let .Ring(r):
                    switch r {
                    case let .Abelian(abe):
                        switch abe {
                        case let .Monoid(mon):
                            switch mon {
                            case let .Add(b): return .M(.init(amonoidOp: .Add(.init(l: m1 ?? b.l, r: m2 ?? b.r))))
                            }
                        case let .Negate(m): return .M(.init(.o(.Echelon(m1 ?? m))))
                        case let .Subtract(l, r): return .M(.init(abelianOp: .Subtract(m1 ?? l, m2 ?? r)))
                        }
                    case let .MMonoid(mon):
                        switch mon {
                        case let .Mul(b): return .M(.init(mmonoidOp: .Mul(.init(l: m1 ?? b.l, r: m2 ?? b.r))))
                        }
                    }
                case let .Scale(k, m):
                    return .M(.init(.o(.Scale(r1 ?? k, m2 ?? m))))
                }
            }
        case let .R(r):
            switch r.c {
            case .e(_): return self
            case let .o(o):
                switch o {
                case let .f(f):
                    switch f {
                    case let .Abelian(abe):
                        switch abe {
                        case let .Monoid(mon):
                            switch mon {
                            case let .Add(b): return .R(.init(amonoidOp: .Add(.init(l: r1 ?? b.l, r: r2 ?? b.r))))
                            }
                        case let .Negate(r): return .R(.init(abelianOp: .Negate(r1 ?? r)))
                        case let .Subtract(x, y): return .R(.init(abelianOp: .Subtract(r1 ?? x, r2 ?? y)))
                        }
                    case let .Conjugate(r): return .R(.init(fieldOp: .Conjugate(r1 ?? r)))
                    case let .Determinant(m): return .R(.init(fieldOp: .Determinant(m1 ?? m)))
                    case let .Mabelian(ma):
                        switch ma {
                        case let .Inverse(r): return .R(.init(mabelianOp: .Inverse(r1 ?? r)))
                        case let .Monoid(mon):
                            switch mon {
                            case let .Mul(b): return .R(.init(mmonoidOp: .Mul(.init(l: r1 ?? b.l, r: r2 ?? b.r))))
                            }
                        case let .Quotient(x, y): return .R(.init(mabelianOp: .Quotient(r1 ?? x, r2 ?? y)))
                        }
                    case .Power(let base, let exponent): return .R(.init(fieldOp: .Power(base: r1 ?? base, exponent: r2 ?? exponent)))
                    }
                }
            }
        }
    }
}
