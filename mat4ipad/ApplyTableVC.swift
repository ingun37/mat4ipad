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
import Promises
//
//protocol ApplyTableDelegate {
//    func changeto(uid:String, to:Exp)
//    func remove(uid:String)
//}
class ApplyTableVC: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    enum Result {
        case changed(String, Exp)
        case removed(String)
    }
    let promise = Promise<Result>.pending()
    @IBOutlet weak var fillBtn: UIButton!
    
    @IBOutlet weak var matrixPanel: UIStackView!
    
//    var del:ApplyTableDelegate?
    let disposeBag = DisposeBag()
    @IBOutlet weak var tv: UITableView!
    var exp:Exp?
    func set(exp:Exp) {
        self.exp = exp
    }
    struct Represent {
        let exp:Exp
        let showLatex:String
        init(_ e:Exp) {
            exp = e
            showLatex = e.latex()
        }
        init(_ e:Exp, show:String) {
            exp = e
            showLatex = show
        }
    }
    func optionsFor(exp:Exp)-> [Represent] {
        var options:[Represent] = []
        let evalType = exp.evalType()
        if evalType == .Mat || evalType == .Unknown {
            options.append(Represent(RowEchelonForm(mat: exp), show: "\\text{Row Echelon Form}"))
            options.append(Represent(GaussJordanElimination(mat: exp), show: "\\text{Gauss Jordan Elimination}"))
            options.append(Represent(Transpose(exp)))
            options.append(Represent(Determinant(exp)))
            
        }
        
        if evalType == .Num || evalType == .Unknown {
            options.append(Represent(Fraction(numerator: exp, denominator: Unassigned("D"))))
            options.append(Represent(Fraction(numerator: NumExp(1), denominator: exp)))
        }
        
        options.append(Represent(Inverse(exp)))
        options.append(Represent(Mat.identityOf(2, 2)))
        options.append(Represent(Mul([exp, Unassigned("Z")])))
        options.append(Represent(Add([exp, Unassigned("Z")])))
        options.append(Represent(Power(exp, Unassigned("n"))))
        
        return options
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let exp = exp else {
            return
        }
        let options = optionsFor(exp: exp)
        let oble = Observable.just(options)
        
        
        oble.bind(to: tv.rx.items(cellIdentifier: "cell", cellType: ApplyTableCell.self), curriedArgument: { (row, element, cell) in
            cell.latex.set(element.showLatex)
            cell.lbl.text = "" //unused
        }).disposed(by: disposeBag)
        
        tv.rx.modelSelected(Represent.self).subscribe(onNext:  { value in
            self.dismiss(animated: false, completion: {
                self.promise.fulfill(.changed(exp.uid, value.exp))
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
            self.promise.fulfill(.changed(mat.uid, Mat(exparr)))
        }
    }
    
    @IBAction func removeClick(_ sender: Any) {
        dismiss(animated: false) {
            if let uid = self.exp?.uid {
                self.promise.fulfill(.removed(uid))
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
        self.promise.fulfill(.changed(exp.uid, newExp))
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
    @IBOutlet weak var lbl:UILabel!
}

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
