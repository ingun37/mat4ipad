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
import ComplexMatrixAlgebra
import NonEmpty

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
    var lineage:Lineage = Lineage(chain: [], exp: "c".rvar)
    
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
                let matAsExp:Exp = .M(.init(element: .Basis(.Matrix(self.mat))))
                let changedMat = affectedCells.reduce(matAsExp, { (mat, cellv) -> Exp in
                    let res = recognize(paths: seperate(path: cellv.drawing))
                    let most = mostLikely(sign: res.0, results: res.1)
                    cellv.drawing = CGMutablePath()
                    if let i = Int(most) {
                        let kididx = cellv.lineage.chain.last!
                        var elements = mat.kids()
                        elements[kididx] = .R(.init(element: .Basis(.N(i))))
                        return mat.cloneWith(kids: elements)
                    } else {
                        return mat
                    }
                })
                if case let .M(cm) = changedMat, cm == Matrix<Real>(element: .Basis(.Matrix(self.mat))) {
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
    var mat:Mat<Real>!
    var cellViews:[MatrixCell] = []
    
    @IBOutlet weak var stack: UIStackView!
    var lineage:Lineage = Lineage(chain: [], exp: "M".mvar)
    let cellTapped = PublishSubject<MatrixCell>()
    func set(_ m:Mat<Real>, lineage:Lineage) {
        self.mat = m
        self.lineage = lineage
        for ri in (0..<m.rowLen) {
            let rowView = MatrixRow.loadViewFromNib()
            for ci in (0..<m.colLen) {
                let cell = MatrixCell.loadViewFromNib()
                let kididx = ri*m.colLen + ci
                cell.set(lineage: Lineage(chain: lineage.chain + [kididx], exp: .R(m.row(ri).all[ci])))
                rowView.stack.addArrangedSubview(cell)
                cell.rxDrawing.map({_ in kididx}).subscribe(cellsDrawingSignal).disposed(by: dBag)
                cell.tapped.subscribe(cellTapped).disposed(by: dBag)
                cellViews.append(cell)
            }
            stack.addArrangedSubview(rowView)
        }
    }
    func expandBy(row: Int, col: Int) {
        let co = mat.colLen
        var kids2d = mat.e
        let colIdx = NonEmpty(0, 1..<mat.colLen+col)
        kids2d = kids2d.fmap { (row) in
            colIdx.map { (ci) in row.all.safe(at: ci) ?? Real(element: .Basis(.Zero)) }.list
        }
        let rowIdx = NonEmpty(0, 1..<mat.rowLen+row)
        kids2d = rowIdx.map({ (ri)->List<Real> in
            return kids2d.all.safe(at: ri) ?? colIdx.map({_ in Real(element: .Basis(.Zero))}).list
        }).list
        
        let newMat = Mat<Real>.init(e: kids2d)
        changed.onNext(.M(.init(.e(.Basis(.Matrix(newMat))))))
    }
    static func loadViewFromNib() -> MatrixView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! MatrixView
    }
}

extension Collection where Index == Int {
    func safe(at:Int)-> Element? {
        if at < count {
            return self[at]
        } else {
            return nil
        }
    }
}
