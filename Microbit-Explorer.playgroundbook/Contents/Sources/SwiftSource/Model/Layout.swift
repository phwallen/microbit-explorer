//
//  Layout.swift
//  MicrobitExplorer
//
//  Created by Peter Wallen on 11/11/2018.
//  Copyright © 2018 Peter Wallen. All rights reserved.
//

import UIKit
class Layout {
    enum pinType{
        case left
        case right
        case top
        case bottom
        case both
    }
    class func manager(_ uiObject:UIView,margins:UILayoutGuide,left:CGFloat,right:CGFloat,top:CGFloat,bottom:CGFloat,pinH:pinType,pinV:pinType) {
        switch (pinH) {
        case .left :
            uiObject.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: left).isActive = true
            uiObject.trailingAnchor.constraint(equalTo: margins.leadingAnchor,constant: right).isActive = true
        case .right :
            uiObject.leadingAnchor.constraint(equalTo: margins.trailingAnchor, constant: left).isActive = true
            uiObject.trailingAnchor.constraint(equalTo: margins.trailingAnchor,constant: right).isActive = true
        case .both :
            uiObject.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: left).isActive = true
            uiObject.trailingAnchor.constraint(equalTo: margins.trailingAnchor,constant: right).isActive = true
        default :
            break
        }
        switch (pinV) {
        case .top :
            uiObject.topAnchor.constraint(equalTo: margins.topAnchor, constant: top).isActive = true
            uiObject.bottomAnchor.constraint(equalTo: margins.topAnchor,constant: bottom).isActive = true
        case .bottom :
            uiObject.topAnchor.constraint(equalTo: margins.bottomAnchor, constant: top).isActive = true
            uiObject.bottomAnchor.constraint(equalTo: margins.bottomAnchor,constant: bottom).isActive = true
        case .both :
            uiObject.topAnchor.constraint(equalTo: margins.topAnchor, constant: top).isActive = true
            uiObject.bottomAnchor.constraint(equalTo: margins.bottomAnchor,constant: bottom).isActive = true
        default :
            break
        }
    }
}
