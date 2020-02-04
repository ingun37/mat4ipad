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
import SignedNumberRecognizer
import ExpressiveAlgebra

class MatrixCell: UIView, ExpViewable, UIGestureRecognizerDelegate {
    var directSubExpViews: [ExpViewable] { return []}
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false

        
//        isMultipleTouchEnabled = true
    }
//    let overwriter = Overwriter()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard !drawing.isEmpty else {
            return
        }
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }
        UIGraphicsPushContext(context)
        context.addPath(drawing)
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokePath()
        UIGraphicsPopContext()
    }
    var drawing = CGMutablePath()
    var lastPhase:UITouch.Phase = .began
    var lastPoint = CGPoint.zero
    
    func follow(touch:UITouch) {
        let loc = touch.location(in: self)
        switch touch.phase {
        case .began:
            drawing.move(to: loc)
            timer?.invalidate()
        case .moved:
            drawing.addLine(to: loc)
        case .ended:
            if lastPhase == .began {
                drawing = CGMutablePath()
                del?.onTap(view: self)
            } else {
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {[unowned self] (tmr) in
                    let res = recognize(paths: seperate(path: self.drawing))
                    let most = mostLikely(sign: res.0, results: res.1)
                    if let i = Int(most) {
                        self.del?.changeto(view: self, to: NumExp(i))
                    } else {
                        self.drawing = CGMutablePath()
                        self.setNeedsDisplay()
                        self.latex.isHidden = true
                    }
                })
            }
        case .cancelled:
            drawing = CGMutablePath()
        default:
            drawing = CGMutablePath()
        }
        lastPhase = touch.phase
        lastPoint = loc
        latex.isHidden = !drawing.isEmpty
        
        setNeedsDisplay()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {return}
        follow(touch: touch)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {return}
        follow(touch: touch)
    }
    var timer:Timer? = nil
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else {return}
        follow(touch: touch)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesCancelled(touches, with: event)
        guard let touch = touches.first else {return}
        follow(touch: touch)
    }
    
    var exp:Exp = Unassigned("z")
    var del:ExpViewableDelegate?
    var parentMatrix:Exp = Mat.identityOf(2, 2)
    var parentExp: Exp? {return parentMatrix}
    func set(_ exp:Exp, del:ExpViewableDelegate?, parentMatrix:Exp) {
        self.parentMatrix = parentMatrix
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
        self.mat = m
        for ri in (0..<m.rows) {
            let rowView = MatrixRow.loadViewFromNib()
            for ci in (0..<m.cols) {
                let cell = MatrixCell.loadViewFromNib()
                cell.set(m.row(ri)[ci], del:del, parentMatrix: self.mat)
                rowView.stack.addArrangedSubview(cell)
            }
            stack.addArrangedSubview(rowView)
        }
    }
    static func loadViewFromNib() -> MatrixView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! MatrixView
    }
}

