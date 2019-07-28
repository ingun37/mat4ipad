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

class MatrixCell: UIView, ExpViewable, UIGestureRecognizerDelegate {
    @IBOutlet weak var imgView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false

        
//        isMultipleTouchEnabled = true
    }
    
    var drawing:CGMutablePath = CGMutablePath()
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }
        
        context.addPath(drawing)
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokePath()
    }
    enum TouchState {
        case Began
        case Moved
        case End
    }
    var touchState:TouchState = .Began
    var lastPoint = CGPoint.zero
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let loc = touches.first?.location(in: self) else {return}
        drawing.move(to: loc)
        
        setNeedsDisplay()
        timer?.invalidate()
        lastPoint = loc
        touchState = .Began
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let loc = touches.first?.location(in: self) else {return}
        drawing.addLine(to: loc)
        setNeedsDisplay()
        touchState = .Moved
        lastPoint = loc
    }
    var timer:Timer? = nil
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {[unowned self] (tmr) in
            self.flushDrawing()
        })
        if touchState == .Began {
            drawing.addEllipse(in: CGRect(origin: lastPoint, size: CGSize(width: 2, height: 2)))
        }
        touchState = .End
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        flushDrawing()
    }
    func flushDrawing() {
        drawing = CGMutablePath()
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
