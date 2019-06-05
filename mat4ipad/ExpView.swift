//
//  ExpTreeView.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath
protocol ExpViewable:UIView {
    var exp:Exp {get}
}
protocol ExpViewableDelegate {
    func onTap(view:ExpViewable)
}
import RxSwift
import RxCocoa

class ExpView: UIView, ExpViewable {
    
    var del:ExpViewableDelegate?
    @IBOutlet weak var stack: UIStackView!
    var allSubExpViews:[ExpView] {
        let directSubviews = stack.arrangedSubviews.compactMap({$0 as? ExpView})
        return directSubviews + directSubviews.map({$0.allSubExpViews}).flatMap({$0})
    }
    @IBOutlet weak var latexWrap: UIView!
    @IBOutlet weak var latexView: LatexView!
    
    @IBOutlet weak var matrixView: MatrixView!
    
    let disposeBag = DisposeBag()

    @IBAction func ontap(_ sender: Any) {
        print("sending \(exp.uid)")
        del?.onTap(view: self)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    var onLayoutSubviews:()->Void = {}
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 8;
        
        latexWrap.layer.cornerRadius = 8;
        latexWrap.layer.shadowColor = UIColor.black.cgColor
        latexWrap.layer.shadowOpacity = 0.5
        latexWrap.layer.shadowOffset = CGSize(width: 1, height: 1)
        latexWrap.layer.shadowRadius = 1
        
    }
    func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        
        
//        layer.masksToBounds = false
    }
    static func loadViewFromNib() -> ExpView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! ExpView
    }
    
    var exp:Exp = Unassigned("z")
    func setExp(exp:Exp, del:ExpViewableDelegate) {
        self.exp = exp
        self.del = del
        latexView.set(exp.latex())
        if let exp = exp as? Mat {
            matrixView.isHidden = false
            stack.isHidden = true
            matrixView.set(exp, del:del)
        } else if exp.kids.isEmpty {
            matrixView.isHidden = true
            stack.isHidden = false
        } else {
            matrixView.isHidden = true
            stack.isHidden = false
            
            exp.kids.forEach({e in
                let v = ExpView.loadViewFromNib()
                v.setExp(exp: e, del:del)
                stack.addArrangedSubview(v)
            })
        }
    }
    @IBAction func increaseCol(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
    }
    @IBAction func decreaseCol(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
    }
    @IBAction func increaseRow(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
    }
    @IBAction func decreaseRow(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
    }
    
}
