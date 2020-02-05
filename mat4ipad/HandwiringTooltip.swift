//
//  HandwiringTooltip.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/05.
//  Copyright © 2020 ingun37. All rights reserved.
//

import UIKit

class HandwiringTooltip: UIView {
    static func loadViewFromNib() -> HandwiringTooltip {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! HandwiringTooltip
    }
}
