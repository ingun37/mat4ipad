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
enum DrawErr:Error {
    case canceled
}
class MatrixCell: UIView, ExpViewable, UIGestureRecognizerDelegate {
    let rxDrawing = PublishSubject<Int>()
    
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
            rxDrawing.onNext(0)
        case .ended:
            if lastPhase == .began {
                drawing = CGMutablePath()
                self.ontap(self)
//                del?.onTap(view: self)
            } else {
                
                    
                
            }
        case .cancelled:
            rxDrawing.onError(DrawErr.canceled)
            drawing = CGMutablePath()
        default:
            rxDrawing.onError(DrawErr.canceled)
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
    
    var exp:Exp {
        return lineage.exp
    }
    var lineage:Lineage = Lineage(chain: [], exp: "c".e)
    
    func set(lineage:Lineage) {
        self.lineage = lineage
        latex.set(exp.latex())
    }
    @IBOutlet weak var latex: LatexView!
    let tapped = PublishSubject<MatrixCell>()
    @IBAction func ontap(_ sender: Any) {
//        del?.onTap(view: self)
        tapped.onNext(self)
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
        cellsDrawingSignal.debounce(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: {[weak self] (n) in
            print("drawn")
            if let self = self {
                let affectedCells = self.cellViews.filter { (cellv) -> Bool in
                    !cellv.drawing.isEmpty
                }
                let changedMat = affectedCells.reduce(self.mat as Exp, { (mat, cellv) -> Exp in
                    let res = recognize(paths: seperate(path: cellv.drawing))
                    let most = mostLikely(sign: res.0, results: res.1)
                    cellv.drawing = CGMutablePath()
                    if let i = Int(most) {
                        let kididx = cellv.lineage.chain.last!
                        var elements = mat.kids()
                        elements[kididx] = Scalar(i)
                        return mat.cloneWith(kids: elements)
                    } else {
                        return mat
                    }
                })
                if changedMat.isEq(self.mat) {
                    affectedCells.forEach { (cellv) in
                        cellv.drawing = CGMutablePath()
                        cellv.latex.isHidden = false
                        cellv.setNeedsDisplay()
                    }
                } else {
                    
                    (UIApplication.shared.windows.first?.rootViewController as? ViewController)?.singleTipView?.dismiss()
                    (UIApplication.shared.windows.first?.rootViewController as? ViewController)?.tipShown = true
                    self.changed.onNext(changedMat)
//                    self.del?.changeto(exp: self.mat, lineage: self.lineage, to: changedMat)
                }
            }
        }).disposed(by: dBag)
    }
    let changed = PublishSubject<Exp>()
    let cellsDrawingSignal = PublishSubject<Int>()
    let dBag = DisposeBag()
    var mat:Mat!
    var cellViews:[MatrixCell] = []
    
    @IBOutlet weak var stack: UIStackView!
    var lineage:Lineage = Lineage(chain: [], exp: "M".e)
    let cellTapped = PublishSubject<MatrixCell>()
    func set(_ m:Mat, lineage:Lineage) {
        self.mat = m
        self.lineage = lineage
        for ri in (0..<m.rows) {
            let rowView = MatrixRow.loadViewFromNib()
            for ci in (0..<m.cols) {
                let cell = MatrixCell.loadViewFromNib()
                let kididx = ri*m.cols + ci
                cell.set(lineage: Lineage(chain: lineage.chain + [kididx], exp: m.row(ri)[ci]))
                rowView.stack.addArrangedSubview(cell)
                cell.rxDrawing.map({_ in kididx}).subscribe(cellsDrawingSignal).disposed(by: dBag)
                cell.tapped.subscribe(cellTapped).disposed(by: dBag)
                cellViews.append(cell)
            }
            stack.addArrangedSubview(rowView)
        }
    }
    func expandBy(row: Int, col: Int) {
        let co = mat.cols
        var kids2d = mat.elements
        if col < 0 && 0 < co + col {
            kids2d = kids2d.map({row in row.dropLast(-col)})
        } else if 0 < col {
            kids2d = kids2d.map({$0 + (0..<col).map({_ in 0.exp})})
        }
        
        if row < 0 && 0 < mat.rows + row {
            kids2d = kids2d.dropLast(-row)
        } else if 0 < row {
            let colLen = kids2d[0].count
            kids2d = kids2d + (0..<row).map({_ in
                (0..<colLen).map({_ in 0.exp})
            })
        }
        
        let newMat = Mat(kids2d)
        changed.onNext(newMat)
    }
    static func loadViewFromNib() -> MatrixView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! MatrixView
    }
}

