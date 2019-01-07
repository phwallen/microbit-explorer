
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
 This class contains conditional compilation depending of whether it is running in an IOS
 or Swift Playgrounds environment.
 
 Under Swift Playgrounds it implements the the PlaygroundBluetoothConnectionView for managing the connection between the iPad and the micro:bit.
 Under IOS it implements a simple connection button for establishing connection.
 N.B. the micro:bit bluetooth name is hardcoded in 'ExplorerInterface.swift' when an instance of MicrobitPlayground is intialized.
*/
import UIKit
#if canImport(PlaygroundBluetooth)
import PlaygroundBluetooth
import CoreBluetooth
#endif

class ConnectionView {
    var microbit:MicrobitPlayground?
    let connectionView = UIButton(type:.system)
    var isConnected = false
    #if canImport(PlaygroundBluetooth)
    public init(view:UIView,microbit:MicrobitPlayground) {
        let connectionView = PlaygroundBluetoothConnectionView(centralManager:microbit.centralManager!)
        connectionView.delegate = self
        connectionView.dataSource = self
        view.addSubview(connectionView)
        let margins = view.layoutMarginsGuide
        connectionView.topAnchor.constraint(equalTo: margins.topAnchor, constant: 0.0).isActive = true
        connectionView.rightAnchor.constraint(equalTo: margins.rightAnchor,constant: 0.0).isActive = true
        connectionView.leftAnchor.constraint(equalTo: margins.rightAnchor,constant: -300.0).isActive = true
        connectionView.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
    }
    #else
    init(view:UIView,microbit:MicrobitPlayground) {
        self.microbit = microbit
        connectionView.setTitle("Connect", for: .normal)
        connectionView.backgroundColor = .white
        connectionView.isEnabled = true
        connectionView.translatesAutoresizingMaskIntoConstraints = false
        connectionView.addTarget(self,action: #selector(buttonAction),for: .primaryActionTriggered)
        setup(view:view)
        
    }
    #endif
    func setup(view:UIView) {
        view.addSubview(connectionView)
        let margins = view.layoutMarginsGuide
        /*
        connectionView.topAnchor.constraint(equalTo: margins.topAnchor, constant: 0.0).isActive = true
        connectionView.rightAnchor.constraint(equalTo: margins.rightAnchor,constant: 0.0).isActive = true
        connectionView.leftAnchor.constraint(equalTo: margins.rightAnchor,constant: -300.0).isActive = true
        connectionView.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        */
        Layout.manager(connectionView,margins:margins,left:-100,right:0,top:0,bottom:50,pinH:.right,pinV:.top)
        
        setupNotficationObservers()
    }
    func setupNotficationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(connected(notification:)), name: .isConnected, object: nil)
    }
    @objc func connected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let flag = userInfo["isConnected"] as? Bool  {
                isConnected = flag
                if isConnected {
                    connectionView.setTitle("Connected", for: .normal)
                    connectionView.isEnabled = false
                } else {
                    connectionView.setTitle("Connect", for: .normal)
                    connectionView.isEnabled = true
                }
            }
        }
    }
    @objc func buttonAction(sender:UIButton) {
        microbit?.startScanning()
    }
}
#if canImport(PlaygroundBluetooth)
extension ConnectionView:PlaygroundBluetoothConnectionViewDelegate {
    public func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, shouldDisplayDiscovered peripheral: CBPeripheral, withAdvertisementData advertisementData: [String : Any]?, rssi: Double) -> Bool {
        if let device  = advertisementData?[CBAdvertisementDataLocalNameKey] as? String {
            NSLog("Possible device detected: \(device)")
            if device.range(of:"micro:bit") != nil {
                return true
            } else {
                return false
            }
        }
        return false
    }
    public func connectionView(_ connectionView: PlaygroundBluetoothConnectionView,
                               shouldConnectTo peripheral: CBPeripheral,
                               withAdvertisementData advertisementData: [String: Any]?,
                               rssi: Double) -> Bool {
        NSLog("*** Should Connect To Peripheral ***")
        return true
    }
    public func connectionView(_ connectionView: PlaygroundBluetoothConnectionView,
                               willDisconnectFrom peripheral: CBPeripheral) {
        NSLog ("*** Will Disconnect From Peripheral ***")
    }
    public func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, titleFor state: PlaygroundBluetoothConnectionView.State) -> String {
        switch state {
        case .noConnection:
            return "Connect Micro:bit"
        case .connecting:
            return "Connecting to Micro:bit"
        case .searchingForPeripherals:
            return "Searching for Micro:bit"
        case .selectingPeripherals:
            return "Select your Micro:bit"
        case .connectedPeripheralFirmwareOutOfDate:
            return "Connect to a different Micro:bit"
        }
    }
    public func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, firmwareUpdateInstructionsFor peripheral: CBPeripheral) -> String {
        NSLog ("Firmware Update Instructions For Peripheral")
        return("N/A")
    }
    
}
extension ConnectionView:PlaygroundBluetoothConnectionViewDataSource {
    public func connectionView(_ connectionView: PlaygroundBluetoothConnectionView, itemForPeripheral peripheral: CBPeripheral, withAdvertisementData advertisementData: [String : Any]?) -> PlaygroundBluetoothConnectionView.Item {
        let name = peripheral.name ?? NSLocalizedString("Unknown", comment: "")
        let icon = UIImage(imageLiteralResourceName:"microbit-explorer.png")
        let issueIcon = icon
        return PlaygroundBluetoothConnectionView.Item(name: name, icon: icon, issueIcon: issueIcon, firmwareStatus: nil, batteryLevel: nil)
    }
}
#endif
