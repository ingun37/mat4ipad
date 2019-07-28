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
    
    var drawings:[[CGPoint]] = []
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }
        
        for drawing in drawings {
            if drawing.count == 1 {
                print("dfghjk")
                context.addEllipse(in: CGRect(origin: drawing[0], size: CGSize(width: 2, height: 2)))
            } else {
                context.addLines(between: drawing)
            }
        }
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokePath()
        context.setFillColor(UIColor.red.cgColor)
        context.drawPath(using: .fillStroke)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("fuck!")
        drawings.append([touches.first!.location(in: self)])
        setNeedsDisplay()
        timer?.invalidate()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesMoved(touches, with: event)
        guard !drawings.isEmpty else {return}
        guard let loc = touches.first?.location(in: self) else {return}
        if let p = drawings.last?.last {
            if 1 > abs(p.x - loc.x) + abs(p.y - loc.y) {
                return
            }
        }
        print("move")
        drawings[drawings.count-1].append(loc)
        setNeedsDisplay()
    }
    var timer:Timer? = nil
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {[unowned self] (tmr) in
            self.flushDrawing()
        })
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        flushDrawing()
    }
    func flushDrawing() {
        drawings = []
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
