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
import ExpressiveAlgebra
import lexiFreeMonoid
import SwiftUI
import EasyTipView

struct History {
    struct State {
        let main:Exp
        let vars:[String:Exp]
    }
    private var _history:[State] = [
        State(main: Add(
                        Power(Mat([[NumExp(1), Unassigned("x")],
                                   [NumExp(0), NumExp(1)]]), NumExp(2)),
                    Mul(Mat([[NumExp(1), NumExp(0)],[Unassigned("z"), NumExp(1)]]), Unassigned("A"))),
              vars: ["A" : Mat([[NumExp(1), NumExp(2)],[NumExp(3), NumExp(1)]]),
                     "z" : NumExp(-1)])
    ]
    mutating func push(main:Exp, vars:[String:Exp]) {
        _history.append(State(main: main, vars: vars))
    }
    mutating func push(main:Exp) {
        _history.append(State(main: main, vars: top.vars))
    }
    mutating func push(_ state:State) {
        _history.append(state)
    }
    var top:State {
        return _history.last ?? State(main: Unassigned("A"), vars: [:])
    }
    @discardableResult
    mutating func pop()-> State? {
        return _history.popLast()
    }
}
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
    
    var history = History()
    
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
        e.directSubExpViews.compactMap({$0 as? ExpView}).forEach { (v) in
            self.setHierarchyBG(e: v, f:f - 0.1)
        }
    }
    
    func refresh() {
        let mainexpview = mainExpView.set(exp: exp)
        setHierarchyBG(e: mainexpview, f: 0.9)
        
        for v in varStack.arrangedSubviews {
            varStack.willRemoveSubview(v)
            varStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        
        for (varname, varExp) in history.top.vars.sorted(by: { (l, r) -> Bool in
            let lt = self.variableAddTimes[l.key] ?? Date(timeIntervalSince1970: 0)
            let rt = self.variableAddTimes[r.key] ?? Date(timeIntervalSince1970: 0)
            if lt == rt {
                return l.key < r.key
            } else {
                return lt < rt
            }
        }) {
            let varview = VarView.loadViewFromNib()
            let expview = varview.set(name: varname, exp: varExp, varDel: self)
            varview.emit.subscribe(onNext: { (e) in
                switch e {
                case .removed(let l):
                    let newExp = varExp.refRemove(chain: l.chain) ?? Unassigned(varname)
                    var vars = self.history.top.vars
                    vars[varname] = newExp
                    self.history.push(main: self.history.top.main, vars: vars)
                case .changed(let l):
                    let newExp = varExp.refChanged(chain: l.chain, to: l.exp)
                    var vars = self.history.top.vars
                    vars[varname] = newExp
                    self.history.push(main: self.history.top.main, vars: vars)
                }
                self.refresh()
                }).disposed(by: dbag)
            varStack.addArrangedSubview(varview)
            setHierarchyBG(e: expview, f: 0.9)
        }
        
        let mainExp = mainexpview.exp
        let varviews = varStack.arrangedSubviews.compactMap({$0 as? VarView})
        let final = varviews.reduce(mainExp) { (exp, vv) -> Exp in
            exp.changed(eqTo: Unassigned(vv.name), to: vv.exp)
        }
        
        
        
        do {
            try preview.set("= {\(final.v().latex())}")
        } catch {
            if let e = error as? evalErr {
                switch e {
                case .MatrixSizeNotMatchForMultiplication(let a, let b):
                    preview.set("\\text{Matrix size does not match for multiplication}" + a.latex() + " " + b.latex())
                case .InvertingNonSquareMatrix(let m):
                    preview.set("\\text{Can't invert a non-square matrix}"+m.latex())
                case .MatrixNotCompleteForRowEchelonForm(_):
                    preview.set("\\text{Can't invert a non-square matrix}")
                case .NotAMatrixForRowEchelonForm(let e):
                    preview.set("\\text{Can't turn not a matrix expression into row echelon form.}" + e.latex())
                case .InvertingSingularMatrix(let m):
                    preview.set("\\text{Can't invert a singular matrix." + m.latex())
                case .NotAMatrixForDeterminant(let e):
                    preview.set("\\text{Can't get a determinant of not a matrix.}" + e.latex())
                case .NotAMatrixForTranspose(let e):
                    preview.set("\\text{Can't transpose a not a matrix.}" + e.latex())

                @unknown default:
                    preview.set("\\text{UnknownError}")
                }
            } else {
                preview.set("= \\text{invalid}")
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
                let newMain = self.history.top.main.refRemove(chain: l.chain) ?? Unassigned("A")
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
//        history.push(main: Mul([Mat.identityOf(2, 2), Unassigned("A")]))
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
            !self.history.top.vars.keys.contains(name) && !allSubVars.contains(name)
        })!
    }
    var variableAddTimes:[String: Date] = [:]
    @IBAction func addVariableClick(_ sender: Any) {
        
        let varname = availableVarName()
        
        let last = history.top
        var newVars = last.vars
        newVars[varname] = Unassigned(varname)
        variableAddTimes[varname] = Date()
        history.push(main: last.main, vars: newVars)
        refresh()
    }
    @IBAction func clearClick(_ sender: Any) {
        history.push(main: Unassigned("A"), vars: [:])
        refresh()
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
            var lastVars = last.vars
            lastVars[to] = last.vars[from]
            lastVars.removeValue(forKey: from)
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
    return allSubExps(of: of).compactMap({($0 as? Unassigned)?.letter})
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
