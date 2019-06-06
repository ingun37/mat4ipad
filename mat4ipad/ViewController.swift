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

class ViewController: UIViewController, ExpViewableDelegate, ApplyTableDelegate {
    @IBOutlet weak var anchorView: UIView!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var preview: LatexView!
    func expandBy(mat: Mat, row: Int, col: Int) {
        let co = mat.cols
        var kids2d = (0..<mat.rows).map({ri in Array(mat.kids[ri*co..<ri*co+co])})
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
        changeto(uid: mat.uid, to: newMat)
    }
    var history:[Exp] = []
    var exp:Exp {
        if history.isEmpty {
            history.append(Unassigned("A"))
        }
        return history.last!
    }
    func remove(uid: String) {
        history.append(removed(e: exp, uid: uid))
        refresh()
    }
    
    
    func changeto(uid:String, to: Exp) {
        history.append(replaced(e: exp, uid: uid, to: to))
        refresh()
    }
    @IBAction func undo(_ sender: Any) {
        let _ = history.popLast()
        refresh()
    }
    
    func onTap(view: ExpViewable) {
        performSegue(withIdentifier: "op", sender: view)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "op" {
            guard let vc = segue.destination as? ApplyTableVC else { return }
            guard let expview = sender as? ExpViewable else {return}

            if let expview = expview as? ExpView {
                anchorView.frame.origin = expview.latexWrap.convert(CGPoint(x: expview.latexWrap.frame.size.width/2, y: expview.latexWrap.frame.size.height), to: anchorView.superview)
            } else if let matcell = expview as? MatrixCell {
                anchorView.frame.origin = matcell.convert(CGPoint(x: matcell.frame.size.width/2, y: matcell.frame.size.height/2), to: anchorView.superview)
            }
            
            print("\(anchorView.frame.origin.x), \(anchorView.frame.origin.y)")
            vc.set(exp: expview.exp, del:self)
        }
    }
    
    
    func occupiedLetters(e:Exp)->[String] {
        let kidsLetters = e.kids.map({self.occupiedLetters(e: $0)}).flatMap({$0})
        if let e = e as? Unassigned {
            return [e.letter] + kidsLetters
        }
        return kidsLetters
    }
    func availableLetters()->Set<String> {
        return Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ".map({"\($0)"})).subtracting(occupiedLetters(e: exp))
    }
    
    
    @IBOutlet weak var mathScrollContentView: UIView!
    
    var mathView:ExpView?
    var matrixDrags:[MatrixDragHandleView] = []
    func setBG(e:ExpView, f:CGFloat) {
        let color = UIColor(hue: 0, saturation: 0, brightness: max(f, 0.5), alpha: 1)
        e.backgroundColor = color
        e.directSubExpViews.forEach { (v) in
            self.setBG(e: v, f:f - 0.1)
        }
    }
    func refresh() {
        if let mv = mathView {
            mathScrollContentView.willRemoveSubview(mv)
            mv.removeFromSuperview()
        }
        
        mathView = ExpView.loadViewFromNib()
        guard let mathView = mathView else {return}
        mathView.setExp(exp: exp, del:self)
        mathScrollContentView.addSubview(mathView)
        mathView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: mathScrollContentView.layoutMarginsGuide.leadingAnchor).isActive = true
        mathView.layoutMarginsGuide.topAnchor.constraint(equalTo: mathScrollContentView.layoutMarginsGuide.topAnchor).isActive = true
        mathView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: mathScrollContentView.layoutMarginsGuide.trailingAnchor).isActive = true
        mathView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: mathScrollContentView.layoutMarginsGuide.bottomAnchor).isActive = true
        
        setBG(e: mathView, f: 0.9)
        do {
            try preview.set("= {\(exp.eval().latex())}")
        } catch {
            if let e = error as? evalErr {
                preview.set("= {\(e.describeInLatex())}")
            } else {
                preview.set("= \\text{invalid}")
            }
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        undoButton.layer.shadowColor = UIColor.black.cgColor
        undoButton.layer.shadowOpacity = 0.5
        undoButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        undoButton.layer.shadowRadius = 1
        
        history = [Mul([Mat.identityOf(2, 2), Unassigned("A")])]
        preview.mathView.fontSize = preview.mathView.fontSize * 1.5
        refresh()
    }

    @IBOutlet weak var matrixResizePreview: UIView!
    @IBAction func matrixResizeMode(_ sender: Any) {
        self.matrixDrags.forEach({v in
            self.view.willRemoveSubview(v)
            v.removeFromSuperview()
            v.removeGestureRecognizer(panGesture)
        })
        let matriViews = self.mathView?.allSubExpViews.compactMap({$0.matrixView}).filter({!$0.isHidden}) ?? []
        for matrixView in matriViews {
            let placeholder = matrixView.dragHandlePlaceHolder!
            placeholder.backgroundColor = UIColor.green
            let rect = CGRect(origin: placeholder.convert(CGPoint.zero, to: self.view), size: placeholder.bounds.size)
            let handle = MatrixDragHandleView(frame: rect)
            handle.set(matView: matrixView)
            handle.addGestureRecognizer(self.panGesture)
            self.view.addSubview(handle)
            panGesture.rx.event.subscribe(onNext: { (rec) in
                self.matrixResizePreview.isHidden = false
                
                let tran = rec.translation(in: nil)
                handle.frame.origin = handle.matView.dragHandlePlaceHolder.convert(tran, to: self.view)
                
                let matrixOrigin = handle.matView.stack.convert(CGPoint.zero, to: self.view)
                let originalMatrixFrame = handle.matView.stack.frame
                let newSize = CGSize(width: originalMatrixFrame.size.width + tran.x, height: originalMatrixFrame.size.height + tran.y)
                self.matrixResizePreview.frame = CGRect(origin: matrixOrigin, size: newSize)
            }).disposed(by: handle.disposeBag)
            
            panGesture.rx.event.map({rec-> (Int, Int) in
                let sz = matrixView.stack.bounds.size
                let cellHeight = Int(sz.height) / matrixView.mat.rows
                let cellWidth = Int(sz.width) / matrixView.mat.cols
                let tran:CGPoint = rec.translation(in: nil)
                let deltaRow = Int(tran.y) / cellHeight
                let deltaCol = Int(tran.x) / cellWidth
                return (deltaRow, deltaCol)
            }).distinctUntilChanged({$0.0 == $1.0 && $0.1 == $1.1}).subscribe(onNext: { [unowned self] (deltaBy) in
                self.previewResizedMatrix(matView: matrixView, rowBy: deltaBy.0, colBy: deltaBy.1)
                print(deltaBy)
            }).disposed(by: handle.disposeBag)
        }
        
    }
    let disposeBag = DisposeBag()
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    func previewResizedMatrix(matView:MatrixView, rowBy:Int, colBy:Int) {
        let preview = matrixResizePreview!
        preview.isHidden = false
        preview.subviews.forEach({v in
            preview.willRemoveSubview(v)
            v.removeFromSuperview()
        })
        let rows = matView.mat.rows + rowBy
        let cols = matView.mat.cols + colBy
        let stackFrame = matView.stack.frame
        let cellw = stackFrame.size.width / CGFloat(matView.mat.rows)
        let cellh = stackFrame.size.height / CGFloat(matView.mat.cols)
        (0..<rows+1).forEach({ ri in
            let line = UIView(frame: CGRect(x: 0, y: CGFloat(ri)*cellh, width: CGFloat(cols)*cellw, height: 1))
            line.backgroundColor = UIColor.white
            preview.addSubview(line)
        })
        (0..<cols+1).forEach({ ci in
            let line = UIView(frame: CGRect(x: CGFloat(ci)*cellw, y: 0, width: 1, height: CGFloat(rows)*cellh))
            line.backgroundColor = UIColor.white
            preview.addSubview(line)
        })
//        matView.stack.convert(CGPoint.zero, to: <#T##UICoordinateSpace#>)
    }
}

class MatrixDragHandleView:UIView {
    let disposeBag = DisposeBag()
    var matView:MatrixView!
    func set(matView:MatrixView) {
        self.matView = matView
        backgroundColor = UIColor.red
    }
}
