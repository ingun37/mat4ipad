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
import Promises
import ExpressiveAlgebra
import NumberKit
import Regex

//
//protocol ApplyTableDelegate {
//    func changeto(uid:String, to:Exp)
//    func remove(uid:String)
//}
class ApplyTableVC: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    enum Result {
        case changed(Exp)
        case removed
        case nothin
    }
    let promise = Promise<Result>.pending()
    @IBOutlet weak var fillBtn: UIButton!
    
    @IBOutlet weak var matrixPanel: UIStackView!
    
    @IBOutlet weak var varPanel: UIStackView!
    //    var del:ApplyTableDelegate?
    let disposeBag = DisposeBag()
    
    var exp:Exp!
    var parentExp:Exp?
    var varNames:[String] = []
    var availableVarName = "Z"
    func set(exp:Exp, parentExp:Exp?, varNames:[String], availableVarName:String) {
        self.exp = exp
        self.varNames = varNames
        self.availableVarName = availableVarName
        self.parentExp = parentExp
    }
    
    @IBOutlet weak var stackView: UIStackView!
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
        if !(parentExp is Mat) {
            options.append(Represent(Mat.identityOf(2, 2)))
        }
        if !(parentExp is Mat) && !(exp is Mat) {
            options.append(Represent(Fraction(numerator: exp, denominator: Unassigned(availableVarName))))
        }
        if !(exp is Mat) {
            options.append(Represent(Fraction(numerator: NumExp(1), denominator: exp)))
        }
        options.append(Represent(Inverse(exp)))
        if !(parentExp is Mat) {
            options.append(Represent(Mul(exp, Unassigned(availableVarName))))
            options.append(Represent(Mul(Unassigned(availableVarName), exp)))
            options.append(Represent(Add(exp, Unassigned(availableVarName))))
            options.append(Represent(Add(Unassigned(availableVarName), exp)))
            options.append(Represent(Subtract(exp, Unassigned(availableVarName))))
            options.append(Represent(Subtract(Unassigned(availableVarName), exp)))
            options.append(Represent(Power(exp, Unassigned(availableVarName))))
        }
        if !(exp is NumExp) && !(exp is Fraction) && !(exp is Power) {
            options.append(Represent(Transpose(exp)))
            options.append(Represent(Determinant(exp), show: "\\text{Determinant}(\(exp.latex()))"))
            options.append(Represent(RowEchelon(mat: exp), show: "\\text{Row Echelon Form}(\(exp.latex()))"))
            options.append(Represent(ReducedRowEchelon(exp), show: "\\text{Reduced Row Echelon Form}(\(exp.latex()))"))
        }
        
        
        return options
    }
    
    @IBOutlet weak var varcvlayout: UICollectionViewFlowLayout!
    override func viewDidLoad() {
        super.viewDidLoad()
        varPanel.isHidden = varNames.isEmpty
        varcvlayout.estimatedItemSize = CGSize(width: 20, height: 20)
        varcvlayout.itemSize = UICollectionViewFlowLayout.automaticSize
        
        let options = optionsFor(exp: exp)
        let expViews = options.map { (rep) -> UIView in
            let latexv = PaddedLatexView.loadViewFromNib()
            if rep.showLatex.isEmpty {
                latexv.mathv?.latex = rep.exp.latex()
            } else {
                latexv.mathv?.latex = rep.showLatex
            }
            let tap = UITapGestureRecognizer()
            latexv.addGestureRecognizer(tap)
            tap.rx.event.bind { (rec) in
                self.dismiss(animated: false, completion: {
                    self.promise.fulfill(.changed(rep.exp))
                })
            }.disposed(by: disposeBag)
            return latexv
        }
        expViews.forEach { (v) in
            stackView.addArrangedSubview(v)
        }
//        let oble = Observable.just(options)
        
        
//        oble.bind(to: tv.rx.items(cellIdentifier: "cell", cellType: ApplyTableCell.self), curriedArgument: { (row, element, cell) in
//            cell.latex.set(element.showLatex)
//            cell.lbl.text = "" //unused
//        }).disposed(by: disposeBag)
//
//        tv.rx.modelSelected(Represent.self).subscribe(onNext: { value in
//            self.dismiss(animated: false, completion: {
//                self.promise.fulfill(.changed(value.exp))
//            })
//        }).disposed(by: disposeBag)
        popoverPresentationController?.delegate = self
//        matrixPanel.isHidden = !(exp is Mat)
        
        let fillingValueOb = numberTextField.rx.text.startWith("0").map({ $0 ?? "0"}).map({$0 == "" ? "0" : $0})
        
        fillingValueOb.subscribe(onNext: { [unowned self] (str) in
            self.fillBtn.setTitle("Fill matrix with \(str)", for: .normal)
        }).disposed(by: disposeBag)
        
//        Observable.just(["a", "bb", "cccc"]).bind(to: varcv.rx.items(cellIdentifier: "cell", cellType: VarCell.self), curriedArgument: { (row, element, cell) in
//            cell.lbl.text = element
//        }).disposed(by: disposeBag)
    }
    @IBAction func fillMatrixClick(_ sender: Any) {
        
        guard let mat = exp as? Mat else {return}
        guard let txt = numberTextField.text else {return}
        guard let _ = txt2exp(txt: txt) else {return}
        let exparr = (0..<mat.rows).map({_ in (0..<mat.cols).map({_ in txt2exp(txt: txt)! })})
        dismiss(animated: false) {
            self.promise.fulfill(.changed(Mat(exparr)))
        }
    }
    
    @IBAction func removeClick(_ sender: Any) {
        dismiss(animated: false) {
            self.promise.fulfill(.removed)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.varcvlayout.invalidateLayout()
        }
    }
    func txt2exp(txt:String)->Exp? {
        if let value = Int(txt) {
            return value.exp
        } else if let value = Float(txt) {
            return NumExp(value)
        } else if let r = Rational<Int>(from: txt){
            return NumExp(r)
        } else if txt.isAlphabets {
            return Unassigned(txt)
        } else {
            if let match = "^(-?)(\\d+)([a-zA-Z]+)$".r?.findFirst(in: txt) {
                if let numpart = match.group(at: 2) {
                    if let varpart = match.group(at: 3) {
                        let sign = match.group(at: 1) ?? ""
                        if let num = Int(sign + numpart) {
                            return Mul(NumExp(num), Unassigned(varpart))
                        }
                    }
                }
            }
            
            return nil
        }
    }
    
    ///Dismiss and fulfill the user input if possible.
    func applyNumber() {
        if let input = numberTextField.text {
            if let newExp = txt2exp(txt: input) {
                dismiss(animated: false) { [unowned self] in
                    self.promise.fulfill(.changed(newExp))
                }
            } else if input.isEmpty {
                
            } else {
                let alert = UIAlertController(title: "Invalid expression", message: """
Following formats are accepted
123, -123, 1/2, 3.14 ...
x, A, 6y ...
""", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        applyNumber()
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
        applyNumber()
        return true
    }
    @IBOutlet weak var varcv: UICollectionView!
    
    @IBAction func cancel(_ sender:UIButton) {
        dismiss(animated: false) {
            self.promise.fulfill(.nothin)
        }
    }
}
class ApplyTableCell:UITableViewCell {
    @IBOutlet weak var latex:LatexView!
    @IBOutlet weak var lbl:UILabel!
}

extension String {
    var isAlphabets: Bool {
        return !isEmpty && range(of: "[^a-zA-Z]", options: .regularExpression) == nil
    }
}
class VarCell:UICollectionViewCell {
    @IBOutlet weak var lbl:UILabel!
}
extension ApplyTableVC:UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return varNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        (cell as? VarCell)?.lbl.text = varNames[indexPath.row]
        print("--_-" + varNames[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dismiss(animated: false) { [unowned self] in
            self.promise.fulfill(.changed(Unassigned(self.varNames[indexPath.row])))
        }
    }
}
