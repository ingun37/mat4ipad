//
//  OverWriter.swift
//  mat4ipad
//
//  Created by ingun on 29/07/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit

class Overwriter {
    var drawing = CGMutablePath()
    var lastPhase:UITouch.Phase = .began
    var lastPoint = CGPoint.zero
    func follow(touch:UITouch, anchorView:UIView)->CGPath {
        let loc = touch.location(in: anchorView)
        switch touch.phase {
        case .began:
            drawing.move(to: loc)
        case .moved:
            drawing.addLine(to: loc)
        case .ended:
            if lastPhase == .began {
                drawing.addEllipse(in: CGRect(origin: lastPoint, size: CGSize(width: 2, height: 2)))
            }
        default:
            drawing = CGMutablePath()
        }
        lastPhase = touch.phase
        lastPoint = loc
        return drawing
    }
    func reset() {
        drawing = CGMutablePath()
    }
}
