//
//  MathScrollView.swift
//  mat4ipad
//
//  Created by ingun on 03/08/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit

class MathScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is MatrixCell {
            return false
        } else {
            return super.touchesShouldCancel(in: view)
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
