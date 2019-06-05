//
//  ApplyTableVC.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath
import RxSwift
import RxCocoa
import NumberKit

protocol ApplyTableDelegate {
    func changeto(uid:String, to:Exp)
    func remove(uid:String)
    func expandBy(mat:Mat, row:Int, col:Int)

}
class ApplyTableVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var matrixPanel: UIStackView!
    
    var del:ApplyTableDelegate?
    let disposeBag = DisposeBag()
    @IBOutlet weak var tv: UITableView!
    var exp:Exp?
    func set(exp:Exp, del:ApplyTableDelegate?) {
        self.exp = exp
        self.del = del
        
    }
    func optionsFor(exp:Exp)-> [Exp] {
        var options:[Exp] = []
        if exp is Unassigned {
            options.append(Mat.identityOf(2, 2))
        }
        options.append(Mul([exp, Unassigned("Z")]).associated())
        options.append(Add([exp, Unassigned("Z")]).associated())
        options.append(Power(exp, Unassigned("n")))
        
        return options
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let exp = exp else {
            return
        }
        let options = optionsFor(exp: exp)
        let oble = Observable.just(options)
        let ct = UITableViewCell.self
        oble.bind(to: tv.rx.items(cellIdentifier: "cell", cellType: ct), curriedArgument: { (row, element, cell) in
            (cell as? ApplyTableCell)?.latex.set(element.latex())
        }).disposed(by: disposeBag)
        
        tv.rx.modelSelected(Exp.self).subscribe(onNext:  { value in
            self.dismiss(animated: true, completion: {
                print("sending to value \(value.uid): \(value.latex())")
                self.del?.changeto(uid:exp.uid, to: value)
            })
        }).disposed(by: disposeBag)
        matrixPanel.isHidden = !(exp is Mat)
    }
    
    @IBAction func removeClick(_ sender: Any) {
        dismiss(animated: true) {
            if let uid = self.exp?.uid {
                self.del?.remove(uid: uid)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        guard let exp = exp else {return true}
        guard let valueTxt = textField.text else {return true}
        if let value = Int(valueTxt) {
            self.dismiss(animated: true, completion: {
                self.del?.changeto(uid:exp.uid, to: value.exp)
            })
        } else if let value = Float(valueTxt) {
            self.dismiss(animated: true, completion: {
                self.del?.changeto(uid:exp.uid, to: NumExp(value))
            })
        } else if let r = Rational<Int>(from: valueTxt){
            self.dismiss(animated: true, completion: {
                self.del?.changeto(uid:exp.uid, to: NumExp(r))
            })
        } else if valueTxt.isAlphanumeric {
            self.dismiss(animated: true, completion: {
                self.del?.changeto(uid:exp.uid, to: Unassigned(valueTxt))
            })
        }
        
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func rowIncrease(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 1, col: 0)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func rowDecrease(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: -1, col: 0)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func columnIncrease(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 0, col: 1)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func columnDecrease(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 0, col: -1)
        dismiss(animated: true, completion: nil)
    }
    
}
class ApplyTableCell:UITableViewCell {
    @IBOutlet weak var latex:LatexView!
}

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
