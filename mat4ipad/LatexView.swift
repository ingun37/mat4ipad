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
    var currentHeightCon:NSLayoutConstraint!
    var mathView:MTMathUILabel!
    func set(_ latex:String) {
        mathView.latex = latex
        mathView.sizeToFit()
        let newLatexHeightCon = NSLayoutConstraint(item: currentHeightCon.firstItem!, attribute: currentHeightCon.firstAttribute, relatedBy: currentHeightCon.relation, toItem: currentHeightCon.secondItem, attribute: currentHeightCon.secondAttribute, multiplier: currentHeightCon.multiplier, constant: mathView.frame.size.height)
        removeConstraint(currentHeightCon)
        addConstraint(newLatexHeightCon)
        currentHeightCon = newLatexHeightCon
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        mathView = MTMathUILabel()
        addSubview(mathView)
        currentHeightCon = initialHeightCon
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
