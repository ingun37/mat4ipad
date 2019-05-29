//
//  ViewController.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

class ViewController: UIViewController {
    var _exp:Exp = Unassigned(letter: "_");
    
    @IBOutlet weak var mathContainer: UIView!
    var mathView:ExpTreeView!
    var exp:Exp {
        get {
            return _exp
        }
        set {
            _exp = newValue
            mathView.setExp(exp: _exp)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mathView = ExpTreeView()
        mathView.frame = mathContainer.frame
        mathContainer.addSubview(mathView)
        
        exp = Mul(a: Mat(elements: []), b: Unassigned(letter: "A"));
    }


    @IBAction func mul(_ sender: Any) {
        
    }
}

