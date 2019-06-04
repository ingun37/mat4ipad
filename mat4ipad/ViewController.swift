//
//  ViewController.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

class ViewController: UIViewController, ExpTreeDelegate, ApplyTableDelegate {
    @IBOutlet weak var anchorView: UIView!
    func changeMatrixElement(mat: Mat, row: Int, col: Int, txt: String) {
        let sub = mat.kids[row*mat.cols + col]
        if let i = Int(txt) {
            self.changeto(uid: sub.uid, to: i.exp)
        } else {
            self.changeto(uid: sub.uid, to: Unassigned(txt))
        }
    }
    
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
    
    func remove(uid: String) {
        exp = removed(e: exp, uid: uid)
        refresh()
    }
    
    
    func changeto(uid:String, to: Exp) {
        exp = replaced(e: exp, uid: uid, to: to)
        refresh()
    }
    
    func onTap(view: ExpTreeView) {
        
        performSegue(withIdentifier: "op", sender: view)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "op" {
            guard let vc = segue.destination as? ApplyTableVC else { return }
            guard let expview = sender as? ExpTreeView else {return}
            guard let exp = expview.exp else {return}
            let anchorPoint = expview.latexWrap.convert(CGPoint(x: expview.latexWrap.frame.size.width/2, y: expview.latexWrap.frame.size.height), to: anchorView.superview)
            
            anchorView.frame.origin = anchorPoint
            print("\(anchorView.frame.origin.x), \(anchorView.frame.origin.y)")
            vc.set(exp: exp, del:self)
        }
    }
    var exp:Exp = Unassigned("_");
    
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
    
    @IBOutlet weak var mathContainer: UIView!
    
    var mathView:ExpTreeView?
    
    func refresh() {
        if let mv = mathView {
            mathContainer.willRemoveSubview(mv)
            mv.removeFromSuperview()
        }
        
        mathView = ExpTreeView.loadViewFromNib()
        guard let mathView = mathView else {return}
        mathView.frame = mathContainer.frame
        mathContainer.addSubview(mathView)
        mathView.setExp(exp: exp, del:self)
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
        
        exp = Mul([Mat.identityOf(2, 2), Unassigned("A")])
        refresh()
    }

    @IBAction func mul(_ sender: Any) {
        
    }
}

