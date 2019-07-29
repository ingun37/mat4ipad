//
//  Source.swift
//  SingleRecognizer
//
//  Created by ingun on 29/07/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit

public func CGPath2SquareImage(path:CGPath, toSize:CGFloat)-> UIImage? {
    let bbox = path.boundingBoxOfPath
    let fitEdge = max(bbox.size.width, bbox.size.height)
    let pad = fitEdge * 0.15
    let edge = 2*pad + fitEdge
    let scale = toSize / edge
    
    let to = CGPoint(x: toSize/2, y: toSize/2)
    let from = CGPoint(x: bbox.midX * scale, y: bbox.midY * scale)
    let vecX = to.x - from.x
    let vecY = to.y - from.y
    
    UIGraphicsBeginImageContext(CGSize(width: toSize, height: toSize))
    guard let context = UIGraphicsGetCurrentContext() else {return nil}
    
    context.setFillColor(UIColor.black.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: toSize, height: toSize))
    let t = CGAffineTransform(translationX: vecX, y: vecY).scaledBy(x: scale, y: scale)
    context.concatenate(t)
    
    context.addPath(path)
    context.setLineCap(.round)
    context.setBlendMode(.normal)
    context.setLineWidth(2)
    context.setStrokeColor(UIColor.white.cgColor)
    context.strokePath()
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img
}
