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
import NonEmpty
import ReSwift

fileprivate extension Int {
    var r:Real {
        return .init(.e(.Basis(.N(self))))
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

class ViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = AppState
    
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
    
    
    @IBAction func undo(_ sender: Any) {
        appStore.dispatch(ActUndo())
    }
    
    @IBOutlet weak var mathStackView:UIStackView!
    @IBOutlet weak var mainExpView:ExpInitView!
    
    @IBOutlet weak var varStack: UIStackView!
    var varViews: [VarView] {
        return varStack.arrangedSubviews.compactMap({$0 as? VarView})
    }
    func setHierarchyBG(vars:[(String, Exp)], e:ExpView, f:CGFloat) {
        let color = UIColor(hue: 0, saturation: 0, brightness: max(f, 0.5), alpha: 1)
        e.setBGColor(color)
        if case let .M(m) = e.exp, case let .e(.Var(letter)) = m.c {
            if let y = vars.first(where: {$0.0 == letter}) {
                e.setBGColor(varColor(vars: vars, varname: y.0))
            }
        } else if case let .R(r) = e.exp, case let .e(.Var(letter)) = r.c {
            if let y = vars.first(where: {$0.0 == letter}) {
                e.setBGColor(varColor(vars: vars, varname: y.0))
            }
        }
        e.kidExpViews.forEach { (v) in
            self.setHierarchyBG(vars:vars, e: v, f:f - 0.1)
        }
        e.matrixCells.forEach { v in
            if case let .M(m) = v.exp, case let .e(.Var(letter)) = m.c {
                if let y = vars.first(where: {$0.0 == letter}) {
                    v.backgroundColor = varColor(vars:vars, varname: y.0)
                    v.latex.mathView.textColor = .white
                }
            } else if case let .R(r) = v.exp, case let .e(.Var(letter)) = r.c {
                if let y = vars.first(where: {$0.0 == letter}) {
                    v.backgroundColor = varColor(vars:vars, varname: y.0)
                    v.latex.mathView.textColor = .white
                }
            }
        }

    }
    func varColor(vars:[(String, Exp)], varname:String)-> UIColor {
        let varcnt = vars.count
        let idx = vars.firstIndex { (x,y) -> Bool in
            x == varname
        } ?? 0
        return UIColor(hue: CGFloat(idx)/CGFloat(varcnt), saturation: 0.8, brightness: 0.8, alpha: 1)
    }
    func newState(state: AppState) {
        let snap:SnapShot
        switch state.mode {
        case .Matrix: snap = state.matrix.last
        case .Real: snap = state.real.last
        }
        let exp = snap.main
        let vars = snap.vars
        
        let mainexpview = mainExpView.set(exp: exp)
        let varsPairs = Array(vars)
        setHierarchyBG(vars: varsPairs, e: mainexpview, f: 0.9)
        
        for v in varStack.arrangedSubviews {
            varStack.willRemoveSubview(v)
            varStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        
        let varcnt = vars.count
        
        let sorted = vars
        
        for (varname, varExp) in sorted {
            let varview = VarView.loadViewFromNib()
            let expview = varview.set(name: varname, exp: varExp, varDel: self)
            
            varview.backgroundColor = varColor(vars: varsPairs, varname: varname)
            varview.emit.subscribe(onNext: { (e) in
                switch e {
                case .removed(let l):
                    appStore.dispatch(ActVarRefRemove(varName: varname, chain: l))
                case .changed(let l):
                    appStore.dispatch(ActVarRefChanged(varName: varname, chain: l))
                }
                }).disposed(by: dbag)
            varStack.addArrangedSubview(varview)
            setHierarchyBG(vars:varsPairs , e: expview, f: 0.9)
        }
        
        let mainExp = mainexpview.exp
        
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
            try preview.set("= {\(final.eval().prettify().latex())}")
        } catch {
            switch error {
            case AlgebraError.DivisionByZero:
                preview.set("= {\\text{Division by zero}}")
            default:
                preview.set("= {\\text{unknown error}}")

            }

        }
        
        singleTipView?.dismiss()
        varTipView?.dismiss()
        handleTipView?.dismiss()
        
//        self.view.layoutIfNeeded()
        matrixResizerTimer.onNext(0)
    }
    
    var wentBack = false
    public func wentBackground() {
        appStore.unsubscribe(self)
        removeMatrixResizers()
        wentBack = true
    }
    public func cameForeground() {
        if wentBack {
            appStore.subscribe(self)
            appStore.dispatch(ActRefresh())
            wentBack = false
        }
    }
    let matrixResizerTimer = PublishSubject<Int>()
    let dbag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        appStore.subscribe(self)

        mainExpView.emit.subscribe(onNext:{ e in
            switch e {
            case .removed(let l):
                appStore.dispatch(ActRefRemove(chain: l))
            case .changed(let l):
                appStore.dispatch(ActRefChange(chain: l))
            }
        }).disposed(by: dbag)
        
        matrixResizerTimer.debounce(RxTimeInterval.milliseconds(100), scheduler: MainScheduler.instance).subscribe { (_) in
            self.makeResizers()
        }
//        history.push(main: Mul([Mat.identityOf(2, 2), "A".e]))
        preview.mathView.fontSize = preview.mathView.fontSize * 1.5
        appStore.dispatch(ActRefresh())
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

    var variableAddTimes:[String: Date] = [:]
    @IBAction func addVariableClick(_ sender: Any) {
        appStore.dispatch(ActNewVar(kind: .Real))
    }
    @IBAction func newMatrixVariableClick(_ sender: Any) {
        appStore.dispatch(ActNewVar(kind: .Matrix))
    }
    @IBAction func clearClick(_ sender: Any) {
        appStore.dispatch(ActClear())
    }
    enum Mode {
        case Matrix
        case Real
    }
    var mode:Mode = .Matrix
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            appStore.dispatch(ActChangeMode(to: .Matrix))
        } else {
            appStore.dispatch(ActChangeMode(to: .Real))
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
            appStore.dispatch(ActRemoveVar(which: original))
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
            appStore.dispatch(ActChangeVarName(from: from, to: to))
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
