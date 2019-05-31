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
    func remove(uid: String) {
        exp.remove(uid: uid)
        refresh()
    }
    
    
    func changeto(uid:String, to: Exp) {
        print("replacing \(uid) to \(to.uid)")
        exp.replace(uid: uid, to: to)
        refresh()
    }
    
    var tappedExp:Exp?
    func onTap(exp: Exp) {
        tappedExp = exp
        performSegue(withIdentifier: "op", sender: exp)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "op" {
            guard let vc = segue.destination as? ApplyTableVC else { return }
            guard let exp = tappedExp else {return}
            vc.set(exp: exp, del:self)
        }
    }
    var exp:Exp = Unassigned("_");
    
    @IBOutlet weak var mathContainer: UIView!
    
    var mathView:ExpTreeView?
    
    func refresh() {
        if let mv = mathView {
            mathContainer.willRemoveSubview(mv)
            mv.removeFromSuperview()
        }
        
        mathView = ExpTreeView()
        guard let mathView = mathView else {return}
        mathView.frame = mathContainer.frame
        mathContainer.addSubview(mathView)
        mathView.setExp(exp: exp, del:self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exp = Buffer(Mul([Mat([
            [Unassigned("a"), Unassigned("b")],
            [Unassigned("b"), Unassigned("d")],
            ]), Unassigned("A")]))
        refresh()
    }

    @IBAction func mul(_ sender: Any) {
        
    }
}

