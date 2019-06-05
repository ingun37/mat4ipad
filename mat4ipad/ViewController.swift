//
//  ViewController.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

class ViewController: UIViewController, ExpViewableDelegate, ApplyTableDelegate {
    @IBOutlet weak var anchorView: UIView!
    
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
    @IBOutlet weak var mathScrollContentWidth: NSLayoutConstraint!
    @IBOutlet weak var mathScrollContentHeight: NSLayoutConstraint!
    
    var mathView:ExpView?
    var matrixDrags:[UIView] = []
    func refresh() {
        if let mv = mathView {
            mathScrollContentView.willRemoveSubview(mv)
            mv.removeFromSuperview()
        }
        
        mathView = ExpView.loadViewFromNib()
        guard let mathView = mathView else {return}
        mathView.setExp(exp: exp, del:self)
        mathScrollContentView.addSubview(mathView)
        mathView.onLayoutSubviews = { [unowned self] in
            let size = mathView.frame.size
            self.mathScrollContentWidth.constant = size.width
            self.mathScrollContentHeight.constant = size.height
        }
        
        
        do {
            try preview.set("{\(exp.latex())} = {\(exp.eval().latex())}")
        } catch {
            if let e = error as? evalErr {
                preview.set("{\(exp.latex())} = {\(e.describeInLatex())}")
            } else {
                preview.set("{\(exp.latex())} = \\text{invalid}")
            }
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        history = [Mul([Mat.identityOf(2, 2), Unassigned("A")])]
        refresh()
    }

    @IBAction func matrixResizeMode(_ sender: Any) {
        self.matrixDrags.forEach({v in
            self.view.willRemoveSubview(v)
            v.removeFromSuperview()
        })
        let matriViews = self.mathView?.allSubExpViews.compactMap({$0.matrixView}).filter({!$0.isHidden}) ?? []
        self.matrixDrags = matriViews.map({ v in
            CGRect(origin: v.convert(v.bounds.origin, to: self.view), size: v.bounds.size)
        }).map({UIView(frame: $0)})
        
        self.matrixDrags.forEach({ v in
            v.backgroundColor = UIColor.purple
            self.view.addSubview(v)
        })
    }
}
