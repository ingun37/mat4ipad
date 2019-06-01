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
    func expandBy(mat:Mat, row:Int, col:Int)
}
import RxSwift
import RxCocoa

class ExpTreeView: UIView {
    var del:ExpTreeDelegate?
    @IBOutlet weak var outstack: UIStackView!
    @IBOutlet weak var stack: UIStackView!
    
    @IBOutlet weak var matWrap: UIView!
    @IBOutlet weak var matcollection: MatCollection!
    var contentView:UIView?
    let disposeBag = DisposeBag()

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
    @IBOutlet weak var matWrapAspectRatio: NSLayoutConstraint!
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
            
            if let exp = exp as? Mat {
                matWrap.isHidden = false
                stack.isHidden = true
                matcollection.set(exp: exp)
                
                let newCon = NSLayoutConstraint(item: matWrapAspectRatio.firstItem!, attribute: matWrapAspectRatio.firstAttribute, relatedBy: matWrapAspectRatio.relation, toItem: matWrapAspectRatio.secondItem, attribute: matWrapAspectRatio.secondAttribute, multiplier: CGFloat(exp.cols)/CGFloat(exp.rows), constant: matWrapAspectRatio.constant)
                
                matWrap.removeConstraint(matWrapAspectRatio)
                matWrap.addConstraint(newCon)
                let items = Observable.just(
                    exp.kids
                )
                
                items.bind(to: matcollection.rx.items(cellIdentifier: "cell", cellType: MatCell.self), curriedArgument: { (row, element, cell) in
                    if let e = element as? Unassigned {
                        cell.lbl.text = e.letter
                    }
                }).disposed(by: disposeBag)
                
            } else {
                matWrap.isHidden = true
                stack.isHidden = false
                exp.kids.forEach({e in
                    let v = ExpTreeView()
                    v.setExp(exp: e, del:del)
                    stack.addArrangedSubview(v)
                })
            }
        }
    }
    @IBAction func increaseCol(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 0, col: 1)
    }
    @IBAction func decreaseCol(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 0, col: -1)
    }
    @IBAction func increaseRow(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 1, col: 0)
    }
    @IBAction func decreaseRow(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: -1, col: 0)
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
class MatCollection:UICollectionView, UICollectionViewDelegateFlowLayout {
    override func awakeFromNib() {
        super.awakeFromNib()
        register(UINib(nibName: "MatCell", bundle: Bundle(for: MatCell.self)), forCellWithReuseIdentifier: "cell")
        print("awake called")
        self.delegate = self
    }
    var rows = 1;
    var cols = 1;
    func set(exp:Mat) {
        print("set called")
        rows = exp.rows
        cols = exp.cols
        
    }
    func collectionView(_ cv: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = frame.size.width/CGFloat(cols)
        let h = frame.size.height/CGFloat(rows)
        
        return CGSize(width: w, height: h)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
class MatCell:UICollectionViewCell {
    
    @IBOutlet weak var lbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}
