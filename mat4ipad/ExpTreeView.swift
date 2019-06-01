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
import RxSwift
import RxCocoa

class ExpTreeView: UIView {
    var del:ExpTreeDelegate?
    @IBOutlet weak var outstack: UIStackView!
    @IBOutlet weak var stack: UIStackView!
    
    @IBOutlet weak var matcollection: MatCollection!
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
            
            if let exp = exp as? Mat {
                matcollection.isHidden = false
                stack.isHidden = true
            } else {
                matcollection.isHidden = true
                stack.isHidden = false
                exp.kids.forEach({e in
                    let v = ExpTreeView()
                    v.setExp(exp: e, del:del)
                    stack.addArrangedSubview(v)
                })
            }
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
class MatCollection:UICollectionView, UICollectionViewDelegateFlowLayout {
    let disposeBag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        register(UINib(nibName: "MatCell", bundle: Bundle(for: MatCell.self)), forCellWithReuseIdentifier: "cell")
        
        let items = Observable.just(
            (0..<4).map { "\($0)" }
        )
        
        items.bind(to: self.rx.items(cellIdentifier: "cell", cellType: MatCell.self)) { (row, element, cell) in
            
            }
            .disposed(by: disposeBag)
        self.delegate = self

    }
    func collectionView(_ cv: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: frame.size.width/2, height: frame.size.height/2)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
class MatCell:UICollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}
