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
    func drawTo(context: CGContext, strokeColor:UIColor) {
        context.addPath(drawing)
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
            guard let img = self.exportDrawing(toSize: 28.0) else {return}
            let model = ModelDataHandler(modelFileInfo: ByClass.modelInfo, labelsFileInfo: ByClass.labelsInfo)
            if let res = model?.runModel(onFrame: img) {
                print(res.inferences.map({$0.label}))
            }
            self.discardDrawing()
            print("fuck")
        })
        if touchState == .Began {
            drawing.addEllipse(in: CGRect(origin: lastPoint, size: CGSize(width: 2, height: 2)))
        }
        touchState = .End
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        discardDrawing()
    }
    func discardDrawing() {
        drawing = CGMutablePath()
        setNeedsDisplay()
    }
    func exportDrawing(toSize:CGFloat)->UIImage? {
        print(imgView.bounds)
        let bbox = drawing.boundingBoxOfPath
        let fitEdge = max(bbox.size.width, bbox.size.height)
        let pad = fitEdge * 0.15
        let edge = 2*pad + fitEdge
        let scale = toSize / edge
        print("scale: \(scale)")
        let to = CGPoint(x: toSize/2, y: toSize/2)
        let from = CGPoint(x: bbox.midX * scale, y: bbox.midY * scale)
        let vecX = to.x - from.x
        let vecY = to.y - from.y
        
        UIGraphicsBeginImageContext(CGSize(width: toSize, height: toSize))
//        UIGraphicsBeginImageContext(imgView.bounds.size)
        guard let context = UIGraphicsGetCurrentContext() else {return nil}
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: toSize, height: toSize))
        let t = CGAffineTransform(translationX: vecX, y: vecY).scaledBy(x: scale, y: scale)
//        let t = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: vecX, y: vecY)
        context.concatenate(t)
        drawTo(context: context, strokeColor: UIColor.white)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
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

