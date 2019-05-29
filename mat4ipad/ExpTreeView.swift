//
//  ExpTreeView.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

@IBDesignable
class ExpTreeView: UIView {
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var latexContainer: UIView!
    
    var contentView:UIView?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    func commonInit() {
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        contentView = view
    }
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing:type(of: self)), bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    func setExp(exp:Exp) {
        let mathlbl = MTMathUILabel()
        mathlbl.frame = latexContainer.frame
        mathlbl.latex = exp.latex()
        mathlbl.sizeToFit()
        latexContainer.addSubview(mathlbl)
        if let exp = exp as? BinaryOp {
            let v1 = ExpTreeView()
            v1.setExp(exp: exp.a)
            let v2 = ExpTreeView()
            v2.setExp(exp: exp.b)
            stack.addArrangedSubview(v1)
            stack.addArrangedSubview(v2)
        } else {
            
        }
    }
}
