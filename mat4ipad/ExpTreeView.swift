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
    
    @IBOutlet weak var outstack: UIStackView!
    @IBOutlet weak var stack: UIStackView!
    
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
        mathlbl.latex = exp.latex()
        mathlbl.sizeToFit()
        outstack.insertArrangedSubview(mathlbl, at: 0)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 8;
        layer.borderColor = UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1).cgColor;
        layer.borderWidth = 3.0;
    }
}
