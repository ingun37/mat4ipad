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

struct History {
    struct State {
        let main:Exp
        let vars:[String:Exp]
    }
    private var _history:[State] = []
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
        let newMain = mainExpView.contentView?.removed(view: view) ?? Unassigned("A")
        let newVars = varStack.arrangedSubviews.compactMap({ $0 as? VarView }).map({varview in
            (varview.name, varview.expView!.removed(view: view) ?? Unassigned(varview.name))
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
                anchorView.frame.origin = expview.latexWrap.convert(CGPoint(x: expview.latexWrap.frame.size.width/2, y: expview.latexWrap.frame.size.height), to: anchorView.superview)
            } else if let matcell = expview as? MatrixCell {
                anchorView.frame.origin = matcell.convert(CGPoint(x: matcell.frame.size.width/2, y: matcell.frame.size.height/2), to: anchorView.superview)
            }
            let aa = Array(history.top.vars.keys)

            vc.set(exp: expview.exp, varNames: aa)
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
        
        for (varname, varExp) in history.top.vars {
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
                case .operandIsNotMatrix(_):
                    preview.set("= \\text{operandIsNotMatrix}")
                case .matrixSizeNotMatch(_, _):
                    preview.set("= \\text{matrixSizeNotMatch}")
                case .multiplyNotSupported(_, _):
                    preview.set("= \\text{multiplyNotSupported}")
                case .invalidExponent(_, _):
                    preview.set("= \\text{invalidExponent}")
                case .RowEcheloningWrongExp:
                    preview.set("= \\text{RowEcheloningWrongExp}")
                case .InvalidMatrixToRowEchelon:
                    preview.set("= \\text{InvalidMatrixToRowEchelon}")
                case .ZeroRowEchelon:
                    preview.set("= \\text{ZeroRowEchelon}")
                case .InvertingNonSquareMatrix:
                    preview.set("= \\text{InvertingNonSquareMatrix}")
                case .invertingDeterminantZero:
                    preview.set("= \\text{invertingDeterminantZero}")
                case .NotInSameSpace:
                    preview.set("= \\text{NotInSameSpace}")
                }
            } else {
                preview.set("= \\text{invalid}")
            }
        }
        
        self.view.layoutIfNeeded()
        makeResizers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        history.push(main: Mul([Mat.identityOf(2, 2), Unassigned("A")]))
        preview.mathView.fontSize = preview.mathView.fontSize * 1.5
        refresh()
    }

    private var matrixResizePreviews:[ResizePreview] = []
    func makeResizers() {
        matrixResizePreviews.forEach { (preview) in
            self.view.willRemoveSubview(preview)
            preview.removeFromSuperview()
        }
        matrixResizePreviews.removeAll()
        guard let mathView = mainExpView.contentView else {return}
        let mats = mathView.allSubExpViews.compactMap({$0.matrixView}).filter({!$0.isHidden})
        matrixResizePreviews = mats.map({
            ResizePreview.newWith(resizingMatrixView:$0, resizingFrame:$0.convert($0.bounds, to: self.view), del:self)
        })
        matrixResizePreviews.forEach({self.view.addSubview($0)})
    }
    
    
    @IBOutlet weak var newVarBtn: UIButton!
    
    @IBAction func addVariableClick(_ sender: Any) {
        var varname = (0...).lazy.map({"V\($0)"}).first(where: {name in
            !self.history.top.vars.keys.contains(name)
        })!
        
        let last = history.top
        var newVars = last.vars
        newVars[varname] = Unassigned(varname)
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
    func changeto(view:ExpViewable, to: Exp) {
        let changedVarPairs = varStack.arrangedSubviews.map({$0 as! VarView}).map({
            ($0.name, $0.expView!.changed(view: view, to: to))
        })
        
        if let mainExpView = mainExpView.contentView {
            print("ExpView is changing: \(mainExpView)")
            let changedMain = mainExpView.changed(view: view, to: to)
            history.push(main: changedMain, vars:
                Dictionary(uniqueKeysWithValues: changedVarPairs))
            refresh()
        }
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
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in
            pro.fulfill(alert.textFields?.first?.text ?? "")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            pro.reject(Err.nameIsNull)
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

class ShadowButton:UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 1
    }
}
