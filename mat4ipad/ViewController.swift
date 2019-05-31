//
//  ViewController.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

class ViewController: UIViewController, ExpTreeDelegate {
    var tappedExp:Exp?
    func onTap(exp: Exp) {
        tappedExp = exp
        performSegue(withIdentifier: "op", sender: exp)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "op" {
            guard let vc = segue.destination as? ApplyTableVC else { return }
            guard let exp = tappedExp else {return}
            vc.set(exp: exp)
        }
    }
    var _exp:Exp = Unassigned(letter: "_");
    
    @IBOutlet weak var mathContainer: UIView!
    
    var mathView:ExpTreeView?
    
    var exp:Exp {
        get {
            return _exp
        }
        set {
            _exp = newValue
            refresh()
        }
    }
    
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
        
        exp = Mul(a:  BG(color: UIColor.purple, e:Mat(elements: [
            [Unassigned(letter: "a"), Unassigned(letter: "b")],
            [Unassigned(letter: "b"), Unassigned(letter: "d")],
            ])), b: BG(color: UIColor.green, e: Unassigned(letter: "A")));
    }

    @IBAction func mul(_ sender: Any) {
        
    }
}

