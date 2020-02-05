//
//  PaddedLatexView.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/02.
//  Copyright © 2020 ingun37. All rights reserved.
//

import UIKit
import iosMath
class PaddedLatexViewStory: UIView {
    var contentView:PaddedLatexView
    required init?(coder: NSCoder) {
        contentView = PaddedLatexView.loadViewFromNib()
        super.init(coder: coder)
        contentView.frame = bounds
        addSubview(contentView)
        translatesAutoresizingMaskIntoConstraints = false

        contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.layoutMarginsGuide.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    }
}
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
            let leading = mathv.layoutMarginsGuide.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor)
            leading.isActive = true
            leading.priority = .required
            let top = mathv.layoutMarginsGuide.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor)
            top.isActive = true
            top.priority = .required
            let trailing = mathv.layoutMarginsGuide.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor)
            trailing.isActive = true
            trailing.priority = .required
            let bottom = mathv.layoutMarginsGuide.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor)
            bottom.isActive = true
            bottom.priority = .required

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
