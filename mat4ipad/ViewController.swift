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
class ViewController: UIViewController, ResizePreviewDelegate {
    @IBOutlet weak var mathRollv: MathScrollView!
    @IBSegueAction func addHelpSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: HelpView())
    }
    
    @IBSegueAction func addAboutSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        let about = About()
        let controller = UIHostingController(coder: coder, rootView: about)
        return controller
    }
    @IBOutlet weak var anchorView: UIView!
    func findOwnerOf(matrix:MatrixView)->ExpView? {
        let views = varStack.arrangedSubviews.compactMap({($0 as? VarView)?.expView}).flatMap({$0.allSubExpViews}) + (mainExpView.contentView?.allSubExpViews ?? [])
        return views.first(where: { (v) -> Bool in
            v.matrixView == matrix
        })
    }
    @IBOutlet weak var preview: LatexView!
    func expandBy(matrix: MatrixView, row: Int, col: Int) {
        guard let view = findOwnerOf(matrix: matrix) else {return}
        guard let mat = view.exp as? Mat else {return}
        print("expanding \(view)")
        let co = mat.cols
        var kids2d = mat.elements
        if col < 0 && 0 < co + col {
            kids2d = kids2d.map({row in row.dropLast(-col)})
        } else if 0 < col {
            kids2d = kids2d.map({$0 + (0..<col).map({_ in 0.exp})})
        }
        
        if row < 0 && 0 < mat.rows + row {
            kids2d = kids2d.dropLast(-row)
        } else if 0 < row {
            let colLen = kids2d[0].count
            kids2d = kids2d + (0..<row).map({_ in
                (0..<colLen).map({_ in 0.exp})
            })
        }
        
        let newMat = Mat(kids2d)
        changeto(view: view, to: newMat)
    }
    
    var history = History()
    
    private var exp:Exp {
        return history.top.main
    }
    func remove(view: ExpViewable) {
        //(varview.name, varview.expView!.removed(view: view) ?? Unassigned(varview.name))
        let newMain = mainExpView.contentView?.exp.refRemove(lineage: view.lineage, from: view.exp) ?? Unassigned("A")
        let newVars = varStack.arrangedSubviews.compactMap({ $0 as? VarView }).map({(varview)-> (String, Exp) in
            let nm = varview.name
            let newExp = varview.exp.refRemove(lineage: view.lineage, from: view.exp) ?? Unassigned(nm)
            return (nm, newExp)
        })
        
        history.push(main: newMain, vars: Dictionary(uniqueKeysWithValues: newVars))
        refresh()
    }
    
    @IBAction func undo(_ sender: Any) {
        history.pop()
        refresh()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "op" {
            guard let vc = segue.destination as? ApplyTableVC else { return }
            guard let expview = sender as? ExpViewable else {return}

            print("ExpView is preparing for segue: \(expview)")
            if let expview = expview as? ExpView {
                anchorView.frame.origin = expview.padLatexView.convert(CGPoint(x: expview.padLatexView.frame.size.width/2, y: expview.padLatexView.frame.size.height), to: anchorView.superview)
            } else if let matcell = expview as? MatrixCell {
                anchorView.frame.origin = matcell.convert(CGPoint(x: matcell.frame.size.width/2, y: matcell.frame.size.height/2), to: anchorView.superview)
            }
            let aa = Array(history.top.vars.keys)

            vc.set(exp: expview.exp, parentExp: expview.lineage.last?.exp, varNames: aa, availableVarName: availableVarName())
            vc.promise.then { (r) in
                switch r {
                case let .changed(to):
                    self.changeto(view: expview, to: to)
                case .removed:
                    self.remove(view: expview)
                case .nothin:
                    break
                }
            }
        }
    }
    
    
    
    @IBOutlet weak var mathStackView:UIStackView!
    @IBOutlet weak var mainExpView:ExpInitView!
    
    @IBOutlet weak var varStack: UIStackView!
    var varViews: [VarView] {
        return varStack.arrangedSubviews.compactMap({$0 as? VarView})
    }
    func setHierarchyBG(e:ExpView, f:CGFloat) {
        let color = UIColor(hue: 0, saturation: 0, brightness: max(f, 0.5), alpha: 1)
        e.backgroundColor = color
        e.directSubExpViews.compactMap({$0 as? ExpView}).forEach { (v) in
            self.setHierarchyBG(e: v, f:f - 0.1)
        }
    }
    
    func refresh() {
        let mainexpview = mainExpView.set(exp: exp, del: self)
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
            let expview = varview.set(name: varname, exp: varExp, expDel: self, varDel: self)
            varStack.addArrangedSubview(varview)
            setHierarchyBG(e: expview, f: 0.9)
        }
        
        let mainExp = mainexpview.exp
        let final = varStack.arrangedSubviews.compactMap({$0 as? VarView}).reduce(mainExp) { (exp, vv) -> Exp in
            exp.changed(eqTo: Unassigned(vv.name), to: vv.exp)
        }
        do {
            try preview.set("= {\(final.eval().latex())}")
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
        
        self.view.layoutIfNeeded()
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
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            ResizePreview.newWith(resizingMatrixView:$0, resizingFrame:$0.convert($0.bounds, to: self.view), del:self)
        })
        matrixResizePreviews.forEach({self.view.addSubview($0)})
        let a = UserDefaultsManager()
        
        if !tipShown && a.showTooltip {
            if let cell = (mats.last?.stack.arrangedSubviews.last as? MatrixRow)?.stack.arrangedSubviews.last as? MatrixCell {
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
            e.g 37, -16
            """, preferences: preferences, delegate: self)
                    
                    tipview.show(forView: cell)
                    self.singleTipView = tipview
                }
            }
        }
    }
    var singleTipView:EasyTipView? = nil
    var tipShown = false
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

extension ViewController: ExpViewableDelegate {
    func changeto(exp: Exp, lineage: [ParentInfo], to: Exp) {
        //($0.name, $0.expView!.changed(view: view, to: to))
        let changedVarPairs = varStack.arrangedSubviews.map({$0 as! VarView}).map({varv-> (String, Exp) in
            let nm = varv.name
            let newExp = varv.exp.refChanged(lineage: lineage, from: exp, to: to)
            return (nm, newExp)
        })
        
        if let mainExpView = mainExpView.contentView {
            let changedMain = mainExpView.exp.refChanged(lineage: lineage, from: exp, to: to)
            history.push(main: changedMain, vars:
                Dictionary(uniqueKeysWithValues: changedVarPairs))
            refresh()
        }
    }
    
    func changeto(view:ExpViewable, to: Exp) {
        changeto(exp: view.exp, lineage: view.lineage, to: to)
    }
    func onTap(view: ExpViewable) {
        performSegue(withIdentifier: "op", sender: view)
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
        self.tipShown = true
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
