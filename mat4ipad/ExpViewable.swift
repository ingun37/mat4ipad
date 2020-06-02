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
        let whenMBinary = { (_ cloner:(Matrix<Real>, Matrix<Real>)->Matrix<Real>)->Exp? in
            if case let .M(x) = remainingKids.first {
                if case let .M(y) = remainingKids.dropFirst().first {
                    return .M(cloner(x,y))
                }
                return .M(x)
            }
            return nil
        }
        let whenRBinary = { (_ cloner:(Real,Real)->Real)->Exp? in
            if case let .R(x) = remainingKids.first {
                if case let .R(y) = remainingKids.dropFirst().first {
                    return .R(cloner(x,y))
                }
                return .R(x)
            }
            return nil
        }
        let whenMUnary = { (_ cloner:(Matrix<Real>)->Matrix<Real>) -> Exp? in
            if case let .M(m) = newKids.first {
                return .M(cloner(m))
            } else {
                return nil
            }
        }
        let whenRUnary = { (_ cloner:(Real)->Real) -> Exp? in
            if case let .R(m) = newKids.first {
                return .R(cloner(m))
            } else {
                return nil
            }
        }
        switch self {
        case let .M(m):
            switch m.c {
            case let .e(e): return self
            case let .o(o):
                switch o {
                case .Echelon(_): return whenMUnary{Matrix(.o(.Echelon($0)))}
                case let .Ring(r):
                    switch r {
                    case let .Abelian(o):
                        switch o {
                        case let .Monoid(o):
                            switch o {
                            case .Add(_): return whenMBinary {Matrix(amonoidOp: .Add(.init(l: $0, r: $1)))}
                            }
                        case .Negate(_): return whenMUnary{Matrix(abelianOp: .Negate($0))}
                        case .Subtract(_, _): return whenMBinary {Matrix(abelianOp: .Subtract($0, $1))}
                        }
                    case let .MMonoid(o):
                        switch o {
                        case .Mul(_): return whenMBinary {Matrix(mmonoidOp: .Mul(.init(l: $0, r: $1)))}
                        }
                    }
                case .Scale(_, _):
                    if let m = newKids[1] {
                        return m
                    } else {
                        return nil
                    }
                case .ReducedEchelon(_): return whenMUnary{Matrix(.o(.ReducedEchelon($0)))}
                case .Inverse(_): return whenMUnary{Matrix(.o(.Inverse($0)))}
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
                            case .Add(_): return whenRBinary {Real(amonoidOp: .Add(.init(l: $0, r: $1)))}
                            }
                        case .Negate(_): return whenRUnary({Real(abelianOp: .Negate($0))})
                        case .Subtract(_, _): return whenRBinary {Real(abelianOp: .Subtract($0, $1))}
                        }
                    case .Conjugate(_): return whenRUnary({Real(fieldOp: .Conjugate($0))})
                    case .Determinant(_):
                        if case let .M(m) = newKids.first {
                            return .R(Real(fieldOp: .Determinant(m)))
                        } else {
                            return nil
                        }
                    case let .Mabelian(ma):
                        switch ma {
                        case .Inverse(_): whenRUnary({Real(mabelianOp: .Inverse($0))})
                        case let .Monoid(m):
                            switch m {
                            case .Mul(_): return whenRBinary {Real(mmonoidOp: .Mul(.init(l: $0, r: $1)))}
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
        return kids()
    }
    func changed(eqTo:Exp, to:Exp)->Exp {
        if isEq(eqTo) {
            return to
        }
        return cloneWith(kids: kids().map({$0.changed(eqTo: eqTo, to: to)}))
    }
    func refChanged(chain:[Int], to:Exp)-> Exp {
        guard let head = chain.first else {
            return to
        }
        return cloneWith(kids: (0..<kids().count).map({ (idx) -> Exp in
            if idx == head {
                return kids()[idx].refChanged(chain: []+chain.dropFirst(), to: to)
            } else {
                return kids()[idx]
            }
        }))
    
    }
}

enum ExpReflection {
    case Add(Exp, Exp)
    case Mul(Exp, Exp)
    case Mat(MatrixB)
    case Var(String)
    case Scalar(RealBasis)
    case Power(base:Exp, exponent:Exp)
    case RowEchelon(NonEmpty<[NonEmpty<[Exp]>]>)
    case ReducedRowEchelon(NonEmpty<[NonEmpty<[Exp]>]>)
    case Determinant(NonEmpty<[NonEmpty<[Exp]>]>)
    case Subtract(Exp, Exp)
    case Negate(Exp)
    case Unknown
}

extension Exp {
    func reflect()->ExpReflection {
        switch self {
        case let .M(m):
            switch m.c {
            case let .e(e):
                switch e {
                case let .Basis(b): return .Mat(b.)
                case let .Var(v): <#code#>
                }
            case let .o(o): <#code#>
            }
        case let .R(r): <#code#>
        }
    }
}

extension Exp {
    func kids()->[Exp] {
        switch reflect() {
        case .Add(let e): return [e.l, e.r]
        case .Mul(let e): return [e.l, e.r]
        case .Mat(let e): return e.elements.flatMap { $0 }
        case .MatrixVar(_), .ScalarVar(_): return []
        case .Scalar(let e): return []
        case .Power(let e): return [e.base, e.exponent]
        case .RowEchelon(let e): return [e.mat]
        case .ReducedRowEchelon(let e): return [e.mat]
        case .Transpose(let e): return [e.mat]
        case .Determinant(let e):  return [e.mat]
        case .Fraction(let e): return [e.numerator, e.denominator]
        case .Inverse(let e): return [e.mat]
        case .Rank(let e): return [e.mat]
        case .Nullity(let e): return [e.mat]
        case .Unknown: return []
        case .Subtract(let e): return [e.l, e.r]
        case .Negate(let e): return [e.e]
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
        case .MatrixVar(_), .ScalarVar(_): return self
        case .Scalar(_): return self
        case .Power(_): return Power(changed[0], changed[1])
        case .RowEchelon(_): return RowEchelon(mat: changed[0])
        case .ReducedRowEchelon(_): return ReducedRowEchelon(changed[0])
        case .Transpose(_): return Transpose(changed[0])
        case .Determinant(_): return Determinant(changed[0])
        case .Fraction(_): return Fraction(numerator: changed[0], denominator: changed[1])
        case .Inverse(_): return Inverse(changed[0])
        case .Rank(_): return Rank(changed[0])
        case .Nullity(_): return Nullity(changed[0])
        case .Unknown: return self
        case .Subtract(_): return Subtract(changed[0], changed[1])
        case .Negate(_): return Negate(changed[0])
        }
    }
}
