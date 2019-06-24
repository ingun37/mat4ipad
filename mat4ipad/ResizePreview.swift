//
//  ResizePreview.swift
//  mat4ipad
//
//  Created by ingun on 24/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit

class ResizePreview: UIView {
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
    static func newWith(resizingFrame:CGRect) -> ResizePreview {
        let view = loadViewFromNib()
        view.frame = resizingFrame
        return view
    }
}
