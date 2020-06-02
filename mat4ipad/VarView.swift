//
//  VarView.swift
//  mat4ipad
//
//  Created by ingun on 02/08/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import Promises
import RxSwift
import RxCocoa

protocol VarDelegate {
    func varNameChanged(from:String, to:String)->Promise<Bool>
    func changeVarName(original:String)->Promise<String>
}
enum Err:Error {
    case nameIsNull
}
class VarView: UIView, UITextFieldDelegate {
    @IBOutlet weak var namelbl: UILabel!
    var del:VarDelegate?
    
    @IBOutlet weak var stack:UIStackView!
    
    @IBAction func nameTap(_ sender: Any) {
        let original = name
        del?.changeVarName(original: original).then({ (to)-> Promise<Bool> in
            guard !to.isEmpty else {throw Err.nameIsNull}
            guard let del = self.del else {throw Err.nameIsNull}
            return del.varNameChanged(from: original, to: to).then { (allowed) in
                guard allowed else {throw Err.nameIsNull}
                self.namelbl.text = to +  " ="
                self.name = to
            }
        }).catch({ (err) in
            
        })
    }
    var name = ""
    var expView:ExpView? = nil
    static func loadViewFromNib() -> VarView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! VarView
    }
    var prev:Disposable?
    let emit = PublishSubject<Emit>()
    
    @discardableResult
    func set(name:String, exp:Exp, varDel:VarDelegate)-> ExpView {
        prev?.dispose()
        self.del = varDel
        namelbl.text = name + " ="
        let eview = ExpView.loadViewFromNib()
        if let prev = expView {
            stack.removeArrangedSubview(prev)
            prev.removeFromSuperview()
        }
        expView = eview
        stack.addArrangedSubview(eview)
        eview.setExp(lineage: Lineage(chain: [], exp: exp))
        prev = eview.emit.subscribe(emit)
        self.name = name
        return eview
    }
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
