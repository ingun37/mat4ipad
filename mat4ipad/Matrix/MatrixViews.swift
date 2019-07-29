//
//  MatrixCell.swift
//  mat4ipad
//
//  Created by ingun on 04/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ByClassRecognizer

class MatrixCell: UIView, ExpViewable, UIGestureRecognizerDelegate {
    @IBOutlet weak var imgView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false

        
//        isMultipleTouchEnabled = true
    }
    let overwriter = Overwriter()
    
    func drawTo(context: CGContext, strokeColor:UIColor) {
        context.addPath(overwriter.drawing)
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        context.setLineWidth(2)
        context.setStrokeColor(strokeColor.cgColor)
        context.strokePath()
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }
        drawTo(context: context, strokeColor: UIColor.black)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {return}
        overwriter.follow(touch: touch, anchorView: self)
        setNeedsDisplay()
        timer?.invalidate()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {return}
        overwriter.follow(touch: touch, anchorView: self)
        setNeedsDisplay()
    }
    var timer:Timer? = nil
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else {return}
        if overwriter.lastPhase == .began {
            self.overwriter.reset()
            self.setNeedsDisplay()
            del?.onTap(view: self)
        } else {
            overwriter.follow(touch: touch, anchorView: self)
            self.setNeedsDisplay()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {[unowned self] (tmr) in
                if let res = recognize(path: self.overwriter.drawing) {
                    if let most = res.inferences.first {
                        if let i = Int(most.label) {
                            self.del?.changeto(uid: self.exp.uid, to: NumExp(i))
                        } else {
                            self.del?.changeto(uid: self.exp.uid, to: Unassigned(most.label))
                        }
                        return
                    }
                }
                self.overwriter.reset()
                self.setNeedsDisplay()
            })
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        overwriter.reset()
        setNeedsDisplay()
    }
    
    var exp:Exp = Unassigned("z")
    var del:ExpViewableDelegate?
    func set(_ exp:Exp, del:ExpViewableDelegate?) {
        self.exp = exp
        self.del = del
        latex.set(exp.latex())
    }
    @IBOutlet private weak var latex: LatexView!
    
    @IBAction func ontap(_ sender: Any) {
        del?.onTap(view: self)
    }
    static func loadViewFromNib() -> MatrixCell {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! MatrixCell
    }
}
class MatrixRow: UIView {
    @IBOutlet weak var stack: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
    }
    static func loadViewFromNib() -> MatrixRow {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! MatrixRow
    }
}
class MatrixView:UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
    }
    var mat:Mat!
    @IBOutlet weak var stack: UIStackView!
    func set(_ m:Mat, del:ExpViewableDelegate?) {
        for ri in (0..<m.rows) {
            let rowView = MatrixRow.loadViewFromNib()
            for ci in (0..<m.cols) {
                let cell = MatrixCell.loadViewFromNib()
                cell.set(m.row(ri)[ci], del:del)
                rowView.stack.addArrangedSubview(cell)
            }
            stack.addArrangedSubview(rowView)
        }
        self.mat = m
    }
    static func loadViewFromNib() -> MatrixView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! MatrixView
    }
}

