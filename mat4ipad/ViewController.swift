//
//  ViewController.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

protocol item {
    
}
enum Err:Error {
    case stackisempty
    case unknownArith
}

protocol Exp: item {
    func latex() -> String;
}
protocol BinaryOp:Exp {
    var a: Exp { get }
    var b: Exp { get }
}
struct Mul:BinaryOp {
    var a: Exp
    
    var b: Exp
    
    func latex() -> String {
        return "{\(a.latex())} * {\(b.latex())}"
    }
}
struct Mat:Exp {
    func latex() -> String {
        return """
                \\begin{pmatrix}
                a & b \\\\
                c & d
                \\end{pmatrix}
        """
    }
    
    var elements:[[Exp]];
}
struct Unassigned:Exp {
    func latex() -> String {
        return letter
    }
    
    var letter:String
    
}
class ViewController: UIViewController {
    var exp:Exp = Mul(a: Mat(elements: []), b: Unassigned(letter: "A"));
    
    @IBOutlet weak var mathcontainer: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let mathlbl = MTMathUILabel()
        mathlbl.frame = mathcontainer.frame
        mathcontainer.addSubview(mathlbl)
        mathlbl.latex = exp.latex()
        // Do any additional setup after loading the view.
    }


    @IBAction func mul(_ sender: Any) {
        
    }
}

