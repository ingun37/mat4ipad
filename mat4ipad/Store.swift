//
//  Store.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/22.
//  Copyright © 2020 ingun37. All rights reserved.
//

import Foundation
import ReSwift
import ComplexMatrixAlgebra
import NonEmpty
import lexiFreeMonoid

public struct TooltipState: StateType {
    var applyTipShown: Bool = false
}

public struct ApplyTipShownAction: Action {}

public func tooltipReducer(action: Action, state: TooltipState?)->TooltipState {
    var state = state ?? TooltipState()
    switch action {
    case _ as ApplyTipShownAction:
        state.applyTipShown = true
    default:
        break
    }
    return state
}

public let tooltipStore = Store<TooltipState>(
    reducer: tooltipReducer,
    state: nil
)
struct SnapShot {
    let main:Exp
    let vars:[String:Exp]
    
    func availableVarName(charSet:String)->String {
        let allSubVars = allSubVarNames(of: main) + vars.flatMap({ (_, v) in
            allSubVarNames(of: v)
        })
        return lexiFreeMonoid(generator: charSet.map({"\($0)"})).first(where: {name in
            !vars.map({$0.0}).contains(name) && !allSubVars.contains(name)
        })!
    }
}
enum Mode {
    case Matrix
    case Real
}
func availableRealVarName()->String {
    return appStore.state.ofCase.availableVarName(charSet: "abcdefghijklmnopqrstuvwxyz")
}
func availableMatrixVarName()->String {
    return appStore.state.ofCase.availableVarName(charSet: "abcdefghijklmnopqrstuvwxyz".uppercased())
}
struct AppState:StateType {
    let matrix:NonEmpty<[SnapShot]>
    let real:NonEmpty<[SnapShot]>
    let mode:Mode
    var ofCase:SnapShot {
        switch mode {
        case .Matrix: return matrix.last
        case .Real: return real.last
        }
    }
}
struct ActChangeMode: Action {
    let to:Mode
}
struct ActUndo: Action {}
struct ActVar: Action {
    let name:String
    let exp:Exp
}
struct ActRefRemove: Action {
    let chain:Lineage
}
struct ActRefChange: Action {
    let chain:Lineage
}
struct ActVarRefRemove: Action {
    let varName:String
    let chain:Lineage
}
struct ActVarRefChanged: Action {
    let varName:String
    let chain:Lineage
}
struct ActRefresh:Action {}
struct ActRemoveVar:Action {
    let which:String
}
struct ActChangeVarName:Action {
    let from:String
    let to:String
}
struct ActNewVar:Action {
    let kind:Mode
}
struct ActClear:Action {}


fileprivate let defaultAppState = AppState(
    matrix: .init(.init(main: "A".mvar, vars: [:]), [.init(main: sampleMain(), vars: ["A": sampllevarA(), "z": sampllevarZ()])]),
    real: .init(.init(main: "a".rvar, vars: [:]), [.init(main: sampleRealMain(), vars: ["x": .R(3.r)])]),
    mode: .Matrix)
let appStore = Store(reducer: appReducer, state: defaultAppState)

func appReducer(action:Action, state:AppState?)->AppState {
    let current = state ?? defaultAppState
    
    switch action {
    case let a as ActChangeMode :
        return AppState(matrix: current.matrix, real: current.real, mode: a.to)
    case _ as ActUndo:
        switch current.mode {
        case .Matrix:
            return .init(matrix: .init(current.matrix.head, current.matrix.tail.dropLast()), real: current.real, mode: current.mode)
        case .Real:
            return .init(matrix: current.matrix, real: .init(current.real.head, current.real.tail.dropLast()), mode: current.mode)
        }
    case let a as ActVar:
        switch current.mode {
        case .Matrix:
            let newVars = current.matrix.last.vars.merging([a.name:a.exp], uniquingKeysWith: {$1})
            let newSnap = SnapShot(main: current.matrix.last.main, vars: newVars)
            return .init(matrix: current.matrix + [newSnap], real: current.real, mode: current.mode)
        case .Real:
            let newVars = current.real.last.vars.merging([a.name:a.exp], uniquingKeysWith: {$1})
            let newSnap = SnapShot(main: current.real.last.main, vars: newVars)
            return .init(matrix: current.matrix, real: current.real + [newSnap], mode: current.mode)
        }
    case let x as ActRefRemove:
        switch current.mode {
        case .Matrix:
            let last = current.matrix.last
            let newMain = last.main.refRemove(chain: x.chain.chain) ?? "A".mvar
            return .init(matrix: current.matrix + [.init(main: newMain, vars: last.vars)], real: current.real, mode: current.mode)
        case .Real:
            let last = current.real.last
            let newMain = last.main.refRemove(chain: x.chain.chain) ?? "a".rvar
            return .init(matrix: current.matrix, real: current.real + [.init(main: newMain, vars: last.vars)], mode: current.mode)
        }
    case let x as ActRefChange:
        switch current.mode {
        case .Matrix:
            let last = current.matrix.last
            let newMain = last.main.refChanged(chain: x.chain.chain, to: x.chain.exp)
            return .init(matrix: current.matrix + [.init(main: newMain, vars: last.vars)], real: current.real, mode: current.mode)
        case .Real:
            let last = current.real.last
            let newMain = last.main.refChanged(chain: x.chain.chain, to: x.chain.exp)
            return .init(matrix: current.matrix, real: current.real + [.init(main: newMain, vars: last.vars)], mode: current.mode)
        }
    case let x as ActRemoveVar:
        switch current.mode {
        case .Matrix:
            let last = current.matrix.last
            let newVars = last.vars.filter { $0.key != x.which }
            return .init(matrix: current.matrix + [.init(main: last.main, vars: newVars)], real: current.real, mode: current.mode)
        case .Real:
            let last = current.real.last
            let newVars = last.vars.filter { $0.key != x.which }
            return .init(matrix: current.matrix, real: current.real + [.init(main: last.main, vars: newVars)], mode: current.mode)
        }
    case let x as ActChangeVarName:
        switch current.mode {
        case .Matrix:
            var vars = current.matrix.last.vars
            if let removed = vars.removeValue(forKey: x.from) {
                vars[x.to] = removed
                let last = current.matrix.last
                return .init(matrix: current.matrix + [.init(main: last.main, vars: vars)], real: current.real, mode: current.mode)
            } else {
                return current
            }
        case .Real:
            var vars = current.real.last.vars
            if let removed = vars.removeValue(forKey: x.from) {
                vars[x.to] = removed
                let last = current.real.last
                return .init(matrix: current.matrix, real: current.real + [.init(main: last.main, vars: vars)], mode: current.mode)
            } else {
                return current
            }
        }
    case _ as ActClear:
        switch current.mode {
        case .Matrix:
            return .init(matrix: current.matrix + [current.matrix.head], real: current.real, mode: current.mode)
        case .Real:
            return .init(matrix: current.matrix, real: current.real + [current.real.head], mode: current.mode)
        }
    case let x as ActNewVar:
        switch current.mode {
        case .Matrix:
            let last = current.matrix.last
            var vars = last.vars
            switch x.kind {
            case .Matrix:
                let availableName = last.availableVarName(charSet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                vars[availableName] = availableName.mvar
            case .Real:
                let availableName = last.availableVarName(charSet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".lowercased())
                vars[availableName] = availableName.rvar
            }
            return .init(
                matrix: current.matrix + [.init(main: last.main, vars: vars)],
                real: current.real, mode: current.mode)
        case .Real:
            let last = current.real.last
            var vars = last.vars
            switch x.kind {
            case .Matrix:
                let availableName = last.availableVarName(charSet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                vars[availableName] = availableName.mvar
            case .Real:
                let availableName = last.availableVarName(charSet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".lowercased())
                vars[availableName] = availableName.rvar
            }
            return .init(
                matrix: current.matrix,
                real: current.real + [.init(main: last.main, vars: vars)],
                mode: current.mode)
        }
    case let x as ActVarRefRemove:
        switch current.mode {
        case .Matrix:
            let last = current.matrix.last
            var vars = last.vars
            if let vexp = vars[x.varName] {
                if let removed = vexp.refRemove(chain: x.chain.chain) {
                    vars[x.varName] = removed
                } else {
                    let fallback:Exp
                    switch vexp {
                    case .M(_): fallback = x.varName.mvar
                    case .R(_): fallback = x.varName.rvar
                    }
                    vars[x.varName] = fallback
                }
                return .init(
                    matrix: current.matrix + [.init(main: last.main, vars: vars)],
                    real: current.real,
                    mode: current.mode)
            } else {
                return current
            }
        case .Real:
            let last = current.real.last
            var vars = last.vars
            if let vexp = vars[x.varName] {
                if let removed = vexp.refRemove(chain: x.chain.chain) {
                    vars[x.varName] = removed
                } else {
                    let fallback:Exp
                    switch vexp {
                    case .M(_): fallback = x.varName.mvar
                    case .R(_): fallback = x.varName.rvar
                    }
                    vars[x.varName] = fallback
                }
                return .init(
                    matrix: current.matrix, real:
                    current.real + [.init(main: last.main, vars: vars)],
                    mode: current.mode)
            } else {
                return current
            }
        }
    case let x as ActVarRefChanged:
        switch current.mode {
        case .Matrix:
            let last = current.matrix.last
            var vars = last.vars
            if let vexp = vars[x.varName] {
                let changed = vexp.refChanged(chain: x.chain.chain, to: x.chain.exp)
                vars[x.varName] = changed
                return .init(
                    matrix: current.matrix + [.init(main: last.main, vars: vars)],
                    real: current.real,
                    mode: current.mode)
            } else {
                return current
            }
        case .Real:
            let last = current.real.last
            var vars = last.vars
            if let vexp = vars[x.varName] {
                let removed = vexp.refChanged(chain: x.chain.chain, to: x.chain.exp)
                vars[x.varName] = removed
                return .init(
                    matrix: current.matrix, real:
                    current.real + [.init(main: last.main, vars: vars)],
                    mode: current.mode)
            } else {
                return current
            }
        }
    default:
        return current
    }
}


fileprivate extension String {
    var r:Real { return .init(.e(.Var(self))) }
    var m:Matrix<Real> { return .init(.e(.Var(self))) }
    var rvar:Exp {
        return .R(.init(.e(.Var(self))))
    }
    var mvar:Exp {
        return .M(.init(.e(.Var(self))))
    }
}

fileprivate extension Int {
    var r:Real {
        return .init(.e(.Basis(.N(self))))
    }
}

func sampllevarZ()->Exp {
    return .R((-1).r)
}
func sampllevarA()->Exp {
    let x = "x".r
    let p = Real(fieldOp: .Power(base: x, exponent: (-2).r))
    let f = -(1.r / "z".r)
    let row1 = NonEmpty(f, [2.r]).list
    let row2 = NonEmpty(3.r, [p]).list
    let rows = NonEmpty(row1, [row2]).list
    return .M(.init(element: .Basis(.Matrix(.init(e: rows)))))
}
func sampleMain()->Exp {
    let x = "x".r
    let z = "z".r
    let A = "A".m
    
    let row1 = NonEmpty<[Real]>(1.r, [x]).list
    let row2 = NonEmpty<[Real]>(0.r, [1.r]).list
    let rows = NonEmpty(row1, [row2]).list
    let Mx = Matrix<Real>(element: .Basis(.Matrix(.init(e: rows))))
    let rowy1 = NonEmpty(1.r, [0.r]).list
    let rowy2 = NonEmpty(z, [1.r]).list
    let My = Matrix<Real>(element: .Basis(.Matrix(.init(e: NonEmpty(rowy1, [rowy2]).list)) ))
    let aaa = (Mx * Mx) + (My * A)
    return .M(aaa)
}
func sampleRealMain()->Exp {
    let x = "x".r
    let y = "y".r
    let a = "a".r
    let b = "b".r
    let row1 = NonEmpty(x, [a]).list
    let row2 = NonEmpty(b, [y]).list
    let rows = NonEmpty(row1, [row2]).list
    let m = Mat<Real>(e: rows)
    return .R(Real(fieldOp: .Determinant(.init(element: .Basis(.Matrix(m))))))
}

