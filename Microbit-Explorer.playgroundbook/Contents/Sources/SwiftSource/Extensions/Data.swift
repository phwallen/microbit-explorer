//
//  Data.swift
//  MicrobitExplorer
//
//  Created by Peter Wallen on 12/11/2018.
//  Copyright © 2018 Peter Wallen. All rights reserved.
//

import Foundation
extension Data {
    func getInteger<T>(start:Int,length:Int) -> T {
        return self.subdata(in:start..<start+length).withUnsafeBytes {$0.pointee }
    }
    func getString(start:Int,length:Int) ->String? {
        return String(data:self.subdata(in:start..<start+length),encoding:.utf8)
    }
}
