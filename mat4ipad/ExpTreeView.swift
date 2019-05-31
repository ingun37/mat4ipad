//
//  ExpTreeView.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

protocol ExpTreeDelegate {
    func onTap(exp:Exp)
}
class ExpTreeView: UIView {
    var del:ExpTreeDelegate?
    @IBOutlet weak var outstack: UIStackView!
    @IBOutlet weak var stack: UIStackView!
    
    var contentView:UIView?

    @IBAction func ontap(_ sender: Any) {
        guard let exp = exp else {return}
        print("sending \(exp.uid)")
        del?.onTap(exp: exp)
    }
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
        
        layer.cornerRadius = 8;
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 1
//        layer.masksToBounds = false
    }
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing:type(of: self)), bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    private var exp:Exp?
    func setExp(exp:Exp, del:ExpTreeDelegate) {
        if let exp = exp as? Buffer {
            setExp(exp: exp.e, del: del)
        } else {
            contentView?.backgroundColor = exp.bgcolor
            self.exp = exp
            self.del = del
            let mathlbl = MTMathUILabel()
            mathlbl.latex = exp.latex()
            mathlbl.sizeToFit()
            outstack.insertArrangedSubview(mathlbl, at: 0)
            exp.kids.forEach({e in
                let v = ExpTreeView()
                v.setExp(exp: e, del:del)
                stack.addArrangedSubview(v)
            })
        }
    }
    
}

extension Range where Bound == Double {
    private func interp(_ n:Int, _ d:Int) -> Double {
        let a:Double = (upperBound*Double(n)/Double(d))
        let b:Double = (lowerBound*Double(d-n)/Double(d))
        return a + b
    }
    func block(_ numerator:Int, _ denominator:Int) -> Range<Double> {
        return interp(numerator, denominator)..<interp(numerator+1, denominator)
    }
}
