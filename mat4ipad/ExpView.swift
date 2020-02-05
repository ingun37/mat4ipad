//
//  ExpTreeView.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath
import RxSwift
import RxCocoa
import ExpressiveAlgebra

class ExpView: UIView, ExpViewable {
    var del:ExpViewableDelegate?
    @IBOutlet weak var stack: UIStackView!
    var directSubExpViews:[ExpViewable] {
        if exp is Mat {
            return matrixView.stack.arrangedSubviews.map({$0 as! MatrixRow}).flatMap({
                $0.stack.arrangedSubviews.map({($0 as! MatrixCell)})
            })
        }
        return stack.arrangedSubviews.compactMap({$0 as? ExpView})
    }
    var allSubExpViews:[ExpView] {
        return [self] + directSubExpViews.compactMap({($0 as? ExpView)?.allSubExpViews}).flatMap({$0})
    }
    @IBOutlet weak var padLatexView: PaddedLatexViewStory!
    
    @IBOutlet weak var matrixView: MatrixView!
    
    let disposeBag = DisposeBag()

    @IBAction func ontap(_ sender: Any) {
        print("ExpView tapped:\(self)")
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
    
//    private var dragStartPosition:CGPoint = CGPoint.zero
    override func awakeFromNib() {
        super.awakeFromNib()
        
        padLatexView.layer.shadowColor = UIColor.black.cgColor
        padLatexView.layer.shadowOpacity = 0.5
        padLatexView.layer.shadowOffset = CGSize(width: 1, height: 1)
        padLatexView.layer.shadowRadius = 1
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
    var lineage:[ParentInfo] = []
    func setExp(exp:Exp, del:ExpViewableDelegate, lineage:[ParentInfo]) {
        self.lineage = lineage
        self.exp = exp
        self.del = del
        padLatexView.contentView.mathv?.latex = exp.latex()
        if let exp = exp as? Mat {
            matrixView.isHidden = false
            stack.isHidden = true
            matrixView.set(exp, lineage: lineage, del:del)
        } else if exp.subExps().isEmpty {
            matrixView.isHidden = true
            stack.isHidden = false
        } else {
            matrixView.isHidden = true
            stack.isHidden = false
            
            let kids = exp.kids()
            for idx in 0..<kids.count {
                let v = ExpView.loadViewFromNib()
                v.setExp(exp: kids[idx], del:del, lineage: lineage+[ParentInfo(exp: exp, kidNumber: idx)])
                stack.addArrangedSubview(v)
            }
        }
    }
    

    @IBOutlet weak var matrixHeight: NSLayoutConstraint!
    @IBOutlet weak var matrixWidth: NSLayoutConstraint!
    
    
    
}

class ExpInitView:UIView {
    var contentView:ExpView?
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func set(exp:Exp, del:ExpViewableDelegate)-> ExpView {
        if let v = contentView {
            willRemoveSubview(v)
        }
        contentView?.removeFromSuperview()
        
        let eview = ExpView.loadViewFromNib()
        
        eview.frame = bounds
        addSubview(eview)
        
        eview.layoutMarginsGuide.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        eview.layoutMarginsGuide.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        eview.layoutMarginsGuide.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        eview.layoutMarginsGuide.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        
        contentView = eview
        
        eview.setExp(exp: exp, del: del, lineage: [])
        return eview
    }
    
}
