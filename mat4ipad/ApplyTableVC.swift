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
class ApplyTableVC: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var fillBtn: UIButton!
    
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
        if let exp = exp as? Mat {
            options.append(RowEchelonForm(mat: exp))
            options.append(GaussJordanElimination(mat: exp))
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
            self.dismiss(animated: false, completion: {
                print("sending to value \(value.uid): \(value.latex())")
                self.del?.changeto(uid:exp.uid, to: value)
            })
        }).disposed(by: disposeBag)
        popoverPresentationController?.delegate = self
//        matrixPanel.isHidden = !(exp is Mat)
        
        let fillingValueOb = numberTextField.rx.text.startWith("0").map({ $0 ?? "0"}).map({$0 == "" ? "0" : $0})
        
        fillingValueOb.subscribe(onNext: { [unowned self] (str) in
            self.fillBtn.setTitle("Fill matrix with \(str)", for: .normal)
        }).disposed(by: disposeBag)
    }
    @IBAction func fillMatrixClick(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        guard let txt = numberTextField.text else {return}
        guard let _ = txt2exp(txt: txt) else {return}
        let exparr = (0..<mat.rows).map({_ in (0..<mat.cols).map({_ in txt2exp(txt: txt)! })})
        dismiss(animated: false) {
            self.del?.changeto(uid:mat.uid, to: Mat(exparr))
        }
    }
    
    @IBAction func removeClick(_ sender: Any) {
        dismiss(animated: false) {
            if let uid = self.exp?.uid {
                self.del?.remove(uid: uid)
            }
        }
    }

    func txt2exp(txt:String)->Exp? {
        if let value = Int(txt) {
            return value.exp
        } else if let value = Float(txt) {
            return NumExp(value)
        } else if let r = Rational<Int>(from: txt){
            return NumExp(r)
        } else if txt.isAlphanumeric {
            return Unassigned(txt)
        }
        return nil
    }
    func applyExpression(txt:String) {
        guard let exp = exp else {return}
        guard let newExp = txt2exp(txt: txt) else {return}
        self.del?.changeto(uid:exp.uid, to: newExp)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        guard let valueTxt = textField.text else {return true}
        applyExpression(txt: valueTxt)
        
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
    @IBOutlet weak var numberTextField: UITextField!
    
    @IBAction func numberClick(_ sender: UIButton) {
        numberTextField.text = (numberTextField.text ?? "") + (sender.title(for: UIControl.State.normal) ?? "")
        numberTextField.sendActions(for: .valueChanged)
    }

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        guard let txt = numberTextField.text else {return true}
        applyExpression(txt: txt)
        
        return true
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
