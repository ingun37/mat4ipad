//
//  MatrixCell.swift
//  mat4ipad
//
//  Created by ingun on 04/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit

class MatrixCell: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderColor = UIColor.darkGray.cgColor;
        layer.borderWidth = 2
    }
    @IBOutlet weak var latex: LatexView!
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
    @IBOutlet weak var stack: UIStackView!
    func set(_ m:Mat) {
        for ri in (0..<m.rows) {
            let rowView = MatrixRow.loadViewFromNib()
            for ci in (0..<m.cols) {
                let cell = MatrixCell.loadViewFromNib()
                let row = m.row(ri)
                cell.latex.set(row[ci].latex())
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
