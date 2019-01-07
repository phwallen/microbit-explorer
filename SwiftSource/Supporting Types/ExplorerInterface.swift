
/*
 MIT License
 
 Created by Peter Wallen on 20/11/2018.
 Copyright © 2018 Peter Wallen.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

/*
 This class provides an interface between the main logic encapuslated by 'Processor.swift' and the bluetooth interface to the micro:bit, currently implemented by
 MicrobitPlayground.swift. This separation is designed to make it easier to implement
 alternative communication designs.
 
 The class contains conditional compilation making it suitable to run in both the IOS and
 Swift Playgrounds environment. This facilitates testing in an Xcode/IOS environment, however, a limited 'ConnectionView' is supported under IOS requiring the micro:bit bluetooth name to be hardcoded in the microbit variable.
*/

import Foundation
protocol ExplorerInterfaceDelegate {
    func ExplorerInterface(_ explorerInterface:ExplorerInterface,message:String)
}
class ExplorerInterface:MicrobitPlaygroundDelegate {
    let microbit = MicrobitPlayground("BBC micro:bit [zuvev]")
    var processor:Processor?
    var group:DispatchGroup?
    var delegate:ExplorerInterfaceDelegate?
    init() {
         microbit.delegate = self
         setupNotficationObservers()
    }
    func uartSend(buffer:Data) {
         microbit.uartSend(buffer: buffer)
    }
    func uartReceived(message:Data) {
        processor?.uartReceived(message: message)
    }
    func disconnected() {
        processor?.disconnected()
    }
    func serviceAvailable(service:ServiceName) {
        processor?.serviceAvailable(service: service)
    }
    func setupNotficationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(connected(notification:)), name: .isConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progress(notification:)), name: .inProgress, object: nil)
    }
    @objc func connected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let flag = userInfo["isConnected"] as? Bool  {
                if flag {
                    connected()
                }
            }
        }
    }
    @objc func progress(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let flag = userInfo["inProgress"] as? Bool  {
                if !flag {
                    completed()
                }
            }
        }
    }
    public func command(_ message:String) {
        processor?.api(command: message)
    }
    #if canImport(PlaygroundBluetooth)
    // Swift Playgrounds conditional section
    func completed() {
    processor?.viewController.containerViewController.sendToContentView(instruction:"Completd")
    }
    func connected() {
        processor?.viewController.containerViewController.sendToContentView(instruction:"connected")
    }
    #else
    // IOS conditional section
    func completed() {
        delegate?.ExplorerInterface(self, message: "Completed")
    }
    func connected() {
        delegate?.ExplorerInterface(self, message: "Connected")
    }
    #endif
}
