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
enum Emit {
    case removed(Lineage)
    case changed(Lineage)
}
class ExpView: UIView, ExpViewable {
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
        guard let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "apply") as? ApplyTableVC else { return }
        guard let root = UIApplication.shared.windows.first?.rootViewController as? ViewController else {return}
        
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.sourceView = padLatexView
        
        vc.set(exp: exp, parentExp: nil, varNames: Array(root.history.top.vars.keys), availableVarName: root.availableVarName())
        vc.promise.then { (r) in
            switch r {
            case let .changed(to):
                self.emit.onNext(.changed(Lineage(chain: self.lineage.chain, exp: to)))
//                self.del?.changeto(view: self, to: to)
            case .removed:
                self.emit.onNext(.removed(self.lineage))
//                root.remove(view: self)
            case .nothin:
                break
            }
        }
        root.present(vc, animated: true, completion: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    let emit = PublishSubject<Emit>()
//    private var dragStartPosition:CGPoint = CGPoint.zero
    override func awakeFromNib() {
        super.awakeFromNib()
        
        padLatexView.layer.shadowColor = UIColor.black.cgColor
        padLatexView.layer.shadowOpacity = 0.5
        padLatexView.layer.shadowOffset = CGSize(width: 1, height: 1)
        padLatexView.layer.shadowRadius = 1
        
        matrixView.changed.subscribe(onNext:{newMat in
            self.emit.onNext(.changed(Lineage(chain: self.lineage.chain, exp: newMat)))
//            self.del?.changeto(view: self, to: newMat)
        }).disposed(by: dbag)
        matrixView.cellTapped.subscribe(onNext:{cell in
            guard let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "apply") as? ApplyTableVC else { return }
            guard let root = UIApplication.shared.windows.first?.rootViewController as? ViewController else {return}
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = cell
            vc.set(exp: cell.exp, parentExp: nil, varNames: Array(root.history.top.vars.keys), availableVarName: root.availableVarName())
            vc.promise.then { (r) in
                switch r {
                case let .changed(to):
                    self.emit.onNext(.changed(Lineage(chain: cell.lineage.chain, exp: to)))
//                    self.del?.changeto(view: cell, to: to)
                case .removed:
                    self.emit.onNext(.removed(cell.lineage))
//                    root.remove(view: cell)
                case .nothin:
                    break
                }
            }
            root.present(vc, animated: true, completion: nil)
        }).disposed(by: dbag)
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
    let dbag = DisposeBag()
    var exp:Exp  {
        return lineage.exp
    }
    var lineage:Lineage = Lineage(chain: [], exp: Unassigned("X"))
    func setExp(lineage:Lineage) {
        self.lineage = lineage
        padLatexView.contentView.mathv?.latex = exp.latex()
        if let exp = exp as? Mat {
            matrixView.isHidden = false
            stack.isHidden = true
            matrixView.set(exp, lineage: lineage)
        } else if exp.subExps().isEmpty {
            matrixView.isHidden = true
            stack.isHidden = false
        } else {
            matrixView.isHidden = true
            stack.isHidden = false
            
            directCommutativeKids(exp: exp).forEach { (relLineage) in
                let v = ExpView.loadViewFromNib()
                v.setExp(lineage: Lineage(chain: lineage.chain + relLineage.chain, exp: relLineage.exp))
                v.emit.subscribe(self.emit).disposed(by: self.dbag)
                stack.addArrangedSubview(v)
            }
        }
    }

    @IBOutlet weak var matrixHeight: NSLayoutConstraint!
    @IBOutlet weak var matrixWidth: NSLayoutConstraint!
}

func directCommutativeKids(exp:Exp)-> [Lineage] {
    let kids = exp.kids()
    
    let commutativeKids = (0..<kids.count).flatMap { (idx) -> [Lineage] in
        let kid = kids[idx]
        let baseChain = [idx]
        if exp is Add && kid is Add || exp is Mul && kid is Mul {
            let granCommuteKids = directCommutativeKids(exp: kid)
            return granCommuteKids.map { (relLineage) -> (Lineage) in
                return Lineage(chain: baseChain + relLineage.chain, exp: relLineage.exp)
            }
        } else {
            return [Lineage(chain: baseChain, exp: kid)]
        }
    }
    return commutativeKids
}

class ExpInitView:UIView {
    var contentView:ExpView?
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    let emit = PublishSubject<Emit>()
    var prev:Disposable? = nil
    func set(exp:Exp)-> ExpView {
        
        if let v = contentView {
            willRemoveSubview(v)
        }
        prev?.dispose()
        
        contentView?.removeFromSuperview()
        
        let eview = ExpView.loadViewFromNib()
        
        eview.frame = bounds
        addSubview(eview)
        
        eview.layoutMarginsGuide.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        eview.layoutMarginsGuide.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        eview.layoutMarginsGuide.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        eview.layoutMarginsGuide.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        
        contentView = eview
        eview.setExp(lineage: Lineage(chain: [], exp: exp))
        
        prev = eview.emit.subscribe(emit)
        return eview
    }
    
}
