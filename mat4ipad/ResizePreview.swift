//
//  ResizePreview.swift
//  mat4ipad
//
//  Created by ingun on 24/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit

class ResizePreview: UIView {
    
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
    static func newWith(resizingFrame:CGRect) -> ResizePreview {
        let view = loadViewFromNib()
        
        view.frame = resizingFrame.insetBy(dx: -5, dy: -5).offsetBy(dx: 5, dy: 5)
        
        return view
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
