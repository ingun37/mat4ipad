//
//  PaddedLatexView.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/02.
//  Copyright © 2020 ingun37. All rights reserved.
//

import UIKit
import iosMath

class PaddedLatexView: UIView {
    
    @IBOutlet weak var container: UIView!
    var mathv: MTMathUILabel?
    static func loadViewFromNib() -> PaddedLatexView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! PaddedLatexView
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        mathv = MTMathUILabel()
        
        if let mathv = mathv {
            container.addSubview(mathv)
            mathv.frame = container.bounds
            container.translatesAutoresizingMaskIntoConstraints = false
            mathv.translatesAutoresizingMaskIntoConstraints = false
//
            mathv.layoutMarginsGuide.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
            mathv.layoutMarginsGuide.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor).isActive = true
            mathv.layoutMarginsGuide.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
            mathv.layoutMarginsGuide.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor).isActive = true

        }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
