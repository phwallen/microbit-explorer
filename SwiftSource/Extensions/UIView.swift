//
//  UIView.swift
//  Explorer
//
//  Created by Peter Wallen on 22/11/2018.
//  Copyright © 2018 Peter Wallen. All rights reserved.
//

import UIKit
extension UIView {
    
    func pushTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.subtype = CATransitionSubtype.fromLeft
        animation.duration = duration
        layer.add(animation,forKey: CATransitionType.push.rawValue)
    }
}
