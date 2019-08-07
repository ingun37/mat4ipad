//
//  VarView.swift
//  mat4ipad
//
//  Created by ingun on 02/08/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import Promises
import AlgebraEvaluator

protocol VarDelegate {
    func varNameChanged(from:String, to:String)->Promise<Bool>
}
class VarView: UIView, ExpViewable, UITextFieldDelegate {
    var del:VarDelegate?
    var exp: Exp {
        return expView?.exp ?? Unassigned(tf.text ?? "Var")
    }
    
    @IBOutlet weak var stack:UIStackView!
    @IBOutlet weak var tf:UITextField!
    
    var name = ""
    var expView:ExpView? = nil
    static func loadViewFromNib() -> VarView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! VarView
    }
    
    @discardableResult
    func set(name:String, exp:Exp, expDel:ExpViewableDelegate, varDel:VarDelegate)-> ExpView {
        self.del = varDel
        tf.text = name
        let eview = ExpView.loadViewFromNib()
        if let prev = expView {
            stack.removeArrangedSubview(prev)
            prev.removeFromSuperview()
        }
        expView = eview
        stack.addArrangedSubview(eview)
        eview.setExp(exp: exp, del: expDel)
        self.name = name
        return eview
    }
    @IBAction func editEnd(_ sender: UITextField) {
        if let to = sender.text {
            del?.varNameChanged(from:name, to: to).then({[unowned self] (allowed) in
                if allowed {
                    self.name = to
                } else {
                    sender.text = self.name
                }
            })
        } else {
            sender.text = name
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

class VarInitView:UIView {
    var varview:VarView
    
    required init?(coder aDecoder: NSCoder) {
        varview = VarView.loadViewFromNib()
        super.init(coder: aDecoder)
        varview.frame = bounds
        addSubview(varview)
    }
}
