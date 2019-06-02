//
//  LatexView.swift
//  mat4ipad
//
//  Created by ingun on 02/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

class LatexView: UIView {
    
    @IBOutlet weak var initialHeightCon: NSLayoutConstraint!
    var mathView:MTMathUILabel!
    func set(_ latex:String) {
        mathView.latex = latex
        mathView.sizeToFit()
        initialHeightCon.constant = mathView.frame.size.height
        
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        mathView = MTMathUILabel()
        addSubview(mathView)
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
