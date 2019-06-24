//
//  ResizePreview.swift
//  mat4ipad
//
//  Created by ingun on 24/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
protocol ResizePreviewDelegate {
    func expandBy(mat: Mat, row: Int, col: Int)
}
class ResizePreview: UIView {
    var del:ResizePreviewDelegate?
    @IBOutlet weak var dragPan: UIPanGestureRecognizer!
    @IBOutlet weak var blue: UIView!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    static func loadViewFromNib() -> ResizePreview {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! ResizePreview
    }
    weak var matrixView:MatrixView?
    static func newWith(resizingMatrixView:MatrixView, resizingFrame:CGRect, del:ResizePreviewDelegate) -> ResizePreview {
        let view = loadViewFromNib()
        let right = view.frame.width - view.blue.frame.width
        let bottom = view.frame.height - view.blue.frame.height
        view.frame = resizingFrame.insetBy(dx: -right/2, dy: -bottom/2).offsetBy(dx: right/2, dy: bottom/2)
        view.matrixView = resizingMatrixView
        view.del = del
        return view
    }
    let disposeBag = DisposeBag()

    var startFrame:CGRect = CGRect.zero
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dragPan.rx.event.subscribe(onNext: {[unowned self] (rec) in
                        if rec.state == .began {
                            self.startFrame = self.frame
                        }
                        let tran = rec.translation(in: nil)
            self.frame = self.startFrame.insetBy(dx: -tran.x/2, dy: -tran.y/2).offsetBy(dx: tran.x/2, dy: tran.y/2)
            
                    }).disposed(by: self.disposeBag)
        
        dragPan.rx.event.map({[unowned self] rec-> (Int, Int, UIGestureRecognizer.State) in
            let matrixFrame = self.startFrame
            let cellHeight = Int(matrixFrame.height) / (self.matrixView?.mat.rows ?? 1)
            let cellWidth = Int(matrixFrame.width) / (self.matrixView?.mat.cols ?? 1)
//            print("a: \(matrixFrame)")
            let tran:CGPoint = rec.translation(in: nil)

            return (Int(matrixFrame.height + tran.y) / cellHeight, Int(matrixFrame.width + tran.x) / cellWidth, rec.state)
        }).distinctUntilChanged({ (l:(Int, Int, UIGestureRecognizer.State), r:(Int, Int, UIGestureRecognizer.State))-> Bool in
            return l.0 == r.0 && l.1 == r.1 && l.2 == r.2
        }).subscribe(onNext: { [unowned self] (newSz) in
            let (newRow, newCol, state) = newSz
            guard let matrixView = self.matrixView else {return}
            let oldrow = matrixView.mat.rows
            let oldcol = matrixView.mat.cols
            self.previewResizedMatrix(newRow: newRow, newCol: newCol)
            if state == .ended {
                self.del?.expandBy(mat: matrixView.mat, row: newRow - oldrow, col: newCol - oldcol)
            }
            if state == .began {
//                self.matrixView.layer.borderWidth = 0
            }
        }).disposed(by: disposeBag)
    }
    
    
    func previewResizedMatrix(newRow:Int, newCol:Int) {
        let preview = blue!
        preview.isHidden = false
        preview.subviews.forEach({v in
            preview.willRemoveSubview(v)
            v.removeFromSuperview()
        })

        guard let matrixView = matrixView else {return}
        let stackFrame = matrixView.frame

        let cellw = stackFrame.size.width / CGFloat(matrixView.mat.cols)
        let cellh = stackFrame.size.height / CGFloat(matrixView.mat.rows)
        (0..<newRow+1).forEach({ ri in
            let line = UIView(frame: CGRect(x: 0, y: CGFloat(ri)*cellh, width: CGFloat(newCol)*cellw, height: 1))
            line.backgroundColor = UIColor.white
            preview.addSubview(line)
        })
        (0..<newCol+1).forEach({ ci in
            let line = UIView(frame: CGRect(x: CGFloat(ci)*cellw, y: 0, width: 1, height: CGFloat(newRow)*cellh))
            line.backgroundColor = UIColor.white
            preview.addSubview(line)
        })
    }
}


func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
func + (left: CGSize, right: CGPoint) -> CGSize {
    return (left.point + right).size
}
extension CGSize {
    var point:CGPoint {
        return CGPoint(x:width, y:height)
    }
}

extension CGPoint {
    var size:CGSize {
        return CGSize(width: x, height: y)
    }
}
