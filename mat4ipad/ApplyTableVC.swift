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
protocol ApplyTableDelegate {
    func changeto(uid:String, to:Exp)
    func remove(uid:String)
}
class ApplyTableVC: UIViewController {
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
        if let exp = exp as? Mul {
            options = [Mul(exp.kids + [BG(Unassigned("Z"))] )]
        } else {
        }
        
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
            let mathlbl = MTMathUILabel()
            mathlbl.latex = element.latex()
            mathlbl.frame = cell.contentView.frame;
            cell.contentView.addSubview(mathlbl)
        }).disposed(by: disposeBag)
        
        tv.rx.modelSelected(Exp.self).subscribe(onNext:  { value in
            self.dismiss(animated: true, completion: {
                print("sending to value \(value.uid): \(value.latex())")
                self.del?.changeto(uid:exp.uid, to: value)
            })
        }).disposed(by: disposeBag)
    }
    
    @IBAction func removeClick(_ sender: Any) {
        dismiss(animated: true) {
            if let uid = self.exp?.uid {
                self.del?.remove(uid: uid)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
