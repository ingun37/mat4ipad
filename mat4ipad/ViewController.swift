//
//  ViewController.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath
import RxSwift
import RxCocoa
import Promises
import lexiFreeMonoid
import SwiftUI
import EasyTipView
import SwiftGraph
import ComplexMatrixAlgebra

extension Int {
    var e:Exp {
        return .R(.init(.e(.Basis(.N(self)))))
    }
}
extension String {
    var rvar:Exp {
        return .R(.init(.e(.Var(self))))
    }
    var mvar:Exp {
        return .M(.init(.e(.Var(self))))
    }
}
func sampllevarZ()->Exp {
    return (-1).e
}
func sampllevarA()->Exp {
    let m = Exp.M(.init(.e(.Basis(.zero))))
    return m
//    let x = "x".e
//    let p = Power(x, (-2).e)
//    let f = Negate(Fraction(numerator: 1.e, denominator: "z".e))
//    return Mat([[f, 2.e],[3.e, p]])
}
func sampleMain()->Exp {
    return "A".mvar
//    let x = "x".e
//    let z = "z".e
//    let A = "A".e
//    return Add(Power(Mat([[1.e, x  ],
//                          [0.e, 1.e]]), 2.e),
//               Mul(Mat([[1.e, 0.e],[z, 1.e]]), A))
}
func sampleRealMain()->Exp {
    return "x".rvar
//    let x = "x".e
//    let z = "z".e
//    let A = "A".e
//    return Add(Power(Mat([[1.e, x  ],
//                          [0.e, 1.e]]), 2.e),
//               Mul(Mat([[1.e, 0.e],[z, 1.e]]), A))
}
struct History {
    struct State {
        let main:Exp
        let vars:[(String,Exp)]
    }
    let initial:State
    let sample:State
    init(initial:State, sample:State) {
        self.initial = initial
        self.sample = sample
        self._history = [sample]
    }
    private var _history:[State]
    mutating func push(main:Exp, vars:[(String,Exp)]) {
        _history.append(State(main: main, vars: vars))
    }
    mutating func push(main:Exp) {
        _history.append(State(main: main, vars: top.vars))
    }
    mutating func push(_ state:State) {
        _history.append(state)
    }
    var top:State {
        return _history.last ?? initial
    }
    @discardableResult
    mutating func pop()-> State? {
        return _history.popLast()
    }
}
let matrixInitalHistory = History(initial: History.State(main: "A".mvar, vars: []), sample: History.State(main: sampleMain(), vars: [("A", sampllevarA()), ("z", sampllevarZ())]))
let realInitalHistory = History(initial: History.State(main: "x".rvar, vars: []), sample: History.State(main: sampleRealMain(), vars: []))
class ViewController: UIViewController {
    @IBOutlet weak var mathRollv: MathScrollView!
    @IBSegueAction func addHelpSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: HelpView())
    }
    
    @IBSegueAction func addAboutSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        let about = About()
        let controller = UIHostingController(coder: coder, rootView: about)
        return controller
    }
    
    @IBOutlet weak var preview: LatexView!
    
    var history = matrixInitalHistory
    
    private var exp:Exp {
        return history.top.main
    }
    
    @IBAction func undo(_ sender: Any) {
        history.pop()
        refresh()
    }
    
    @IBOutlet weak var mathStackView:UIStackView!
    @IBOutlet weak var mainExpView:ExpInitView!
    
    @IBOutlet weak var varStack: UIStackView!
    var varViews: [VarView] {
        return varStack.arrangedSubviews.compactMap({$0 as? VarView})
    }
    func setHierarchyBG(e:ExpView, f:CGFloat) {
        let color = UIColor(hue: 0, saturation: 0, brightness: max(f, 0.5), alpha: 1)
        e.setBGColor(color)
        if case let .M(m) = e.exp, case let .e(.Var(letter)) = m.c {
            if let y = history.top.vars.first(where: {$0.0 == letter}) {
                e.setBGColor(varColor(varname: y.0))
            }
        } else if case let .R(r) = e.exp, case let .e(.Var(letter)) = r.c {
            if let y = history.top.vars.first(where: {$0.0 == letter}) {
                e.setBGColor(varColor(varname: y.0))
            }
        }
        e.kidExpViews.forEach { (v) in
            self.setHierarchyBG(e: v, f:f - 0.1)
        }
        e.matrixCells.forEach { v in
            if case let .M(m) = v.exp, case let .e(.Var(letter)) = m.c {
                if let y = history.top.vars.first(where: {$0.0 == letter}) {
                    v.backgroundColor = varColor(varname: y.0)
                    v.latex.mathView.textColor = .white
                }
            } else if case let .R(r) = v.exp, case let .e(.Var(letter)) = r.c {
                if let y = history.top.vars.first(where: {$0.0 == letter}) {
                    v.backgroundColor = varColor(varname: y.0)
                    v.latex.mathView.textColor = .white
                }
            }
        }

    }
    func varColor(varname:String)-> UIColor {
        let varcnt = history.top.vars.count
        let idx = history.top.vars.firstIndex { (x,y) -> Bool in
            x == varname
        } ?? 0
        return UIColor(hue: CGFloat(idx)/CGFloat(varcnt), saturation: 0.8, brightness: 0.8, alpha: 1)
    }
    func refresh() {
        let mainexpview = mainExpView.set(exp: exp)
        setHierarchyBG(e: mainexpview, f: 0.9)
        
        for v in varStack.arrangedSubviews {
            varStack.willRemoveSubview(v)
            varStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        
        let varcnt = history.top.vars.count
        
        let sorted = history.top.vars
        
        for (varname, varExp) in sorted {
            let varview = VarView.loadViewFromNib()
            let expview = varview.set(name: varname, exp: varExp, varDel: self)
            
            varview.backgroundColor = varColor(varname: varname)
            varview.emit.subscribe(onNext: { (e) in
                switch e {
                case .removed(let l):
                    let fallback:Exp
                    switch varExp {
                    case .M(_): fallback = .M(.init(.e(.Var(varname))))
                    case .R(_): fallback = .R(.init(.e(.Var(varname))))
                    }
                    let newExp = varExp.refRemove(chain: l.chain) ?? fallback
                    let vars = self.history.top.vars.map({ varname == $0.0 ? ($0.0, newExp) : $0})
                    self.history.push(main: self.history.top.main, vars: vars)
                case .changed(let l):
                    let newExp = varExp.refChanged(chain: l.chain, to: l.exp)
                    let vars = self.history.top.vars.map({ varname == $0.0 ? ($0.0, newExp) : $0})
                    self.history.push(main: self.history.top.main, vars: vars)
                }
                self.refresh()
                }).disposed(by: dbag)
            varStack.addArrangedSubview(varview)
            setHierarchyBG(e: expview, f: 0.9)
        }
        
        let mainExp = mainexpview.exp
        let vars = history.top.vars
        
        var graph = UnweightedGraph(vertices: vars.map({$0.0}))
        
        vars.forEach { (name,exp) in
            dependentVariables(e: exp).forEach { (dep) in
                graph.addEdge(from: name, to: dep, directed: true)
            }
        }
        
        while true {
            guard let cycle = graph.detectCycles().first else {break}
            if graph.edgeExists(from: cycle[0], to: cycle[1]) {
                graph.removeAllEdges(from: cycle[0], to: cycle[1])
            } else {
                graph.removeAllEdges(from: cycle[1], to: cycle[0])
            }
        }
        
        let topo = graph.topologicalSort()!
        
        let final = topo.reduce(mainExp) { (exp, vname) -> Exp in
            if let vexp = vars.first(where: {$0.0 == vname}) {
                return exp.changed(eqTo: vexp.1.sameTypeVar(name: vname), to: vexp.1)
            } else {
                return exp
            }
        }
        
        do {
            try preview.set("= {\(final.eval().latex())}")
        } catch {
//            if let e = error as? evalErr {
//                switch e {
//                case .MatrixSizeNotMatchForMultiplication(let a, let b):
//                    preview.set("\\text{Matrix size does not match for multiplication}" + a.latex() + " " + b.latex())
//                case .InvertingNonSquareMatrix(let m):
//                    preview.set("\\text{Can't invert a non-square matrix}"+m.latex())
//                case .MatrixNotCompleteForRowEchelonForm(_):
//                    preview.set("\\text{Can't invert a non-square matrix}")
//                case .NotAMatrixForRowEchelonForm(let e):
//                    preview.set("\\text{Can't turn not a matrix expression into row echelon form.}" + e.latex())
//                case .InvertingSingularMatrix(let m):
//                    preview.set("\\text{Can't invert a singular matrix." + m.latex())
//                case .NotAMatrixForDeterminant(let e):
//                    preview.set("\\text{Can't get a determinant of not a matrix.}" + e.latex())
//                case .NotAMatrixForTranspose(let e):
//                    preview.set("\\text{Can't transpose a not a matrix.}" + e.latex())
//
//                @unknown default:
//                    preview.set("\\text{UnknownError}")
//                }
//            } else {
//                preview.set("= \\text{invalid}")
//            }
        }
        
        singleTipView?.dismiss()
        varTipView?.dismiss()
        handleTipView?.dismiss()
        
//        self.view.layoutIfNeeded()
        matrixResizerTimer.onNext(0)
    }
    
    var wentBack = false
    public func wentBackground() {
        removeMatrixResizers()
        wentBack = true
    }
    public func cameForeground() {
        if wentBack {
            refresh()
            wentBack = false
        }
    }
    let matrixResizerTimer = PublishSubject<Int>()
    let dbag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        mainExpView.emit.subscribe(onNext:{ e in
            switch e {
            case .removed(let l):
                let newMain = self.history.top.main.refRemove(chain: l.chain) ?? "A".mvar
                self.history.push(main: newMain)
                self.refresh()
            case .changed(let l):
                let changedMain = self.history.top.main.refChanged(chain: l.chain, to: l.exp)
                self.history.push(main: changedMain, vars: self.history.top.vars)
                self.refresh()
            }
        }).disposed(by: dbag)
        
        matrixResizerTimer.debounce(RxTimeInterval.milliseconds(100), scheduler: MainScheduler.instance).subscribe { (_) in
            self.makeResizers()
        }
//        history.push(main: Mul([Mat.identityOf(2, 2), "A".e]))
        preview.mathView.fontSize = preview.mathView.fontSize * 1.5
        refresh()
    }

    private var matrixResizePreviews:[ResizePreview] = []
    func removeMatrixResizers() {
        matrixResizePreviews.forEach { (preview) in
            self.view.willRemoveSubview(preview)
            preview.removeFromSuperview()
        }
        matrixResizePreviews.removeAll()
    }
    func makeResizers() {
        removeMatrixResizers()
        guard let mathView = mainExpView.contentView else {return}
        
        let mats = mathView.allSubExpViews.compactMap({$0.matrixView}).filter({!$0.isHidden})
        
        let mats2 = varViews.flatMap { (varv) in
            varv.expView?.allSubExpViews.compactMap({$0.matrixView}) ?? []
        }.filter { (expv) -> Bool in
            !expv.isHidden
        }
        let allMatViews = mats + mats2
        matrixResizePreviews = allMatViews.filter({ (mv:MatrixView) -> Bool in
            mathRollv.bounds.contains(mv.convert(CGPoint(x: mv.bounds.size.width, y: mv.bounds.size.height), to: mathRollv))
        }).map({
            ResizePreview.newWith(resizingMatrixView:$0, resizingFrame:$0.convert($0.bounds, to: self.view))
        })
        matrixResizePreviews.forEach({self.view.addSubview($0)})
        let a = UserDefaultsManager()
        
        if !tipShown && a.showTooltip {
            if let cell = (mats.last?.stack.arrangedSubviews.last as? MatrixRow)?.stack.arrangedSubviews.last as? MatrixCell {
                tipShown = true
                if let prev = singleTipView {
                    prev.show(forView: cell)
                } else {
                    var preferences = EasyTipView.Preferences()
                    preferences.drawing.font = UIFont(name: "Futura-Medium", size: 13)!
                    preferences.drawing.foregroundColor = .white
                    preferences.drawing.backgroundColor = UIColor(hue:0.46, saturation:0.99, brightness:0.6, alpha:1)
                    preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.left
                    
                    let tipview = EasyTipView(text: """
            Try handwriting an integer with Apple Pencil within a cell!
            e.g 3, -10
            """, preferences: preferences, delegate: self)
                    
                    tipview.show(forView: cell)
                    self.singleTipView = tipview
                }
            }
        }
        
        if !varTipShown && UserDefaultsManager().showTooltip {
            if let lastvarview = varStack.arrangedSubviews.compactMap({$0 as? VarView}).last {
                varTipShown = true
                if let prev = varTipView {
                    prev.show(forView: lastvarview.namelbl)
                } else {
                    var preferences = EasyTipView.Preferences()
                    preferences.drawing.font = UIFont(name: "Futura-Medium", size: 13)!
                    preferences.drawing.foregroundColor = .white
                    preferences.drawing.backgroundColor = UIColor(hue:0.46, saturation:0.99, brightness:0.6, alpha:1)
                    preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.left
                    
                    let tipview = EasyTipView(text: """
                Tap variable label to change name or remove!
                """, preferences: preferences, delegate: self)
                        
                    tipview.show(forView: lastvarview.namelbl)
                    self.varTipView = tipview
                }
            }
        }
        if !handleTipShown && UserDefaultsManager().showTooltip {
            let handles = matrixResizePreviews.compactMap({$0.handle})
            if let lasthandle = handles.last {
                handleTipShown = true
                
                if let prev = handleTipView {
                    prev.show(forView: lasthandle)
                } else {
                    var preferences = EasyTipView.Preferences()
                    preferences.drawing.font = UIFont(name: "Futura-Medium", size: 13)!
                    preferences.drawing.foregroundColor = .white
                    preferences.drawing.backgroundColor = UIColor(hue:0.46, saturation:0.99, brightness:0.6, alpha:1)
                    preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.left
                    
                    let tipview = EasyTipView(text: """
                Drag blue handle to change matrix's size!
                """, preferences: preferences, delegate: self)
                        
                    tipview.show(forView: lasthandle)
                    self.handleTipView = tipview
                }
            }
        }
    }
    var handleTipView:EasyTipView? = nil
    var singleTipView:EasyTipView? = nil
    var varTipView:EasyTipView? = nil
    public var tipShown = false
    public var varTipShown = false
    public var handleTipShown = false
    func availableVarName()->String {
        let allSubVars = allSubVarNames(of: history.top.main) + history.top.vars.flatMap({ (_, v) in
            allSubVarNames(of: v)
        })
        return lexiFreeMonoid(generator: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map({"\($0)"})).first(where: {name in
            !self.history.top.vars.map({$0.0}).contains(name) && !allSubVars.contains(name)
        })!
    }
    var variableAddTimes:[String: Date] = [:]
    @IBAction func addVariableClick(_ sender: Any) {
        let varname = availableVarName()
        newVar(name: varname, exp: varname.rvar)
    }
    @IBAction func newMatrixVariableClick(_ sender: Any) {
        let varname = availableVarName()
        newVar(name: varname, exp: varname.mvar)
    }
    func newVar(name:String, exp:Exp) {
        let last = history.top
        let newVars = last.vars + [(name, exp)]
        
        variableAddTimes[name] = Date()
        history.push(main: last.main, vars: newVars)
        refresh()
    }
    @IBAction func clearClick(_ sender: Any) {
        switch mode {
        case .Matrix: history = matrixInitalHistory
        case .Real: history = realInitalHistory
        }
        history.pop()
        refresh()
    }
    enum Mode {
        case Matrix
        case Real
    }
    var mode:Mode = .Matrix
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            if mode != .Matrix {
                mode = .Matrix
                clearClick(sender)
            }
        } else {
            if mode != .Real {
                mode = .Real
                clearClick(sender)
            }
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}



extension ViewController: VarDelegate {
    func changeVarName(original: String) -> Promise<String> {
        let pro = Promise<String>.pending()
        let alert = UIAlertController(title: "Enter name", message: title, preferredStyle: .alert)
        alert.addTextField { (tfield) in }
        alert.addAction(UIAlertAction(title: "Change", style: .default, handler: {_ in
            pro.fulfill(alert.textFields?.first?.text ?? "")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            pro.reject(Err.nameIsNull)
        }))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: {[weak self] (_) in
            if let self = self {
                self.history.push(main: self.history.top.main, vars: self.history.top.vars.filter({ (key, val) -> Bool in
                    return key != original
                }))
                self.refresh()
            }
        }))
        present(alert, animated: true, completion: nil)
        return pro
    }
    
    func alert(title:String, del:@escaping ()->Void) {
        let alert = UIAlertController(title: "Invalid Variable Name", message: title, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in del()}))
        present(alert, animated: true, completion: nil)
    }
    enum InvalidNameReasons:String {
        case empty = "Name can't be empty."
        case startsWithNumber = "Name can't start with numbers"
        case unknown
    }
    func isVarNameValid(name:String)->(Bool, InvalidNameReasons) {
        guard let first = name.first else {
            return (false, .empty)
        }
        guard !first.isNumber else {
            return (false, .startsWithNumber)
        }
        return (true, .unknown)
    }
    func varNameChanged(from:String, to: String) -> Promise<Bool> {
        let (allowed, reason) = isVarNameValid(name: to)
        if allowed {
            let last = history.top
            let lastVars = last.vars.map { (name, e) in
                name == from ? (to, e) : (name, e)
            }
            history.push(main: last.main, vars: lastVars)
            refresh()
            return Promise(true)
        } else {
            let pend = Promise<Bool>.pending()
            alert(title: reason.rawValue) {
                pend.fulfill(false)
            }
            return pend
        }
    }
}

func allSubExps(of:Exp)->[Exp] {
    return [of] + of.subExps().flatMap({allSubExps(of:$0)})
}
func allSubVarNames(of:Exp)->[String] {
    return allSubExps(of: of).compactMap({ e in
        switch e {
        case let .M(m):
            if case let .Var(v) = m.element { return v }
        case let .R(r):
            if case let .Var(v) = r.element { return v }
        }
        return nil
    })
}

extension ViewController: EasyTipViewDelegate {
    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.makeResizers()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.makeResizers()
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.removeMatrixResizers()
    }
}

func dependentVariables(e:Exp)-> [String] {
    if case let .M(m) = e, case let .Var(v) = m.element { return [v] }
    if case let .R(r) = e, case let .Var(v) = r.element { return [v] }
    return e.kids().flatMap({dependentVariables(e: $0)})
}
