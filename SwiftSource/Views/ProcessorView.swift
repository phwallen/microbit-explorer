
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

import UIKit
@objc(ProcessorView)
class ProcessorView: UIView,ProcessorDelegate {
    
    let instructionBuffer = UILabel()
    var memoryViewArray = [UILabel]()
    var registerViewArray = [UILabel]()
    let psrV = UILabel()
    let psrC = UILabel()
    let psrZ = UILabel()
    let psrN = UILabel()
    let stackPointer = UILabel()
    
    let activityIndicatorView = UIActivityIndicatorView()
   
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    func setupView() {
        backgroundColor = UIColor(displayP3Red: 72/255, green: 137/255, blue: 133/255, alpha: 1.0)
        //backgroundColor = .clear
        let vStackView = UIStackView()
        vStackView.axis = .vertical
        vStackView.distribution = .fillProportionally
        vStackView.spacing = 5
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let hStackView = UIStackView()
        hStackView.axis = .horizontal
        hStackView.distribution = .fillProportionally
        hStackView.spacing = 5
        
        hStackView.addArrangedSubview(addLabel(text: "Processor", color: .blue,alignment:.left))
        vStackView.addArrangedSubview(hStackView)
        vStackView.addArrangedSubview(addLabel(text:"Instruction Buffer:",fontSize:10,alignment:.left))
        instructionBuffer.backgroundColor = .gray
        instructionBuffer.text = " "
        instructionBuffer.font = instructionBuffer.font.withSize(20)
        instructionBuffer.textColor = .white
        vStackView.addArrangedSubview(instructionBuffer)
        vStackView.addArrangedSubview(addLabel(text: "General Registers:",fontSize:10,alignment:.left))
        
        let psrStackView = UIStackView()
        psrStackView.axis = .horizontal
        psrStackView.distribution = .fillProportionally
        psrStackView.spacing = 0
        //psrStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for field in 1 ... 7 {
            switch field {
            case 1:
                psrStackView.addArrangedSubview(addLabel(text: "    Stack Pointer: ", fontSize: 10, alignment: .right))
            case 2:
                stackPointer.text = "00000000"
                stackPointer.textAlignment = .left
                stackPointer.backgroundColor = .lightGray
                //stackPointer.font = stackPointer.font.withSize(18)
                stackPointer.adjustsFontSizeToFitWidth = true
                stackPointer.textAlignment = .center
                psrStackView.addArrangedSubview(stackPointer)
            case 3:
                psrStackView.addArrangedSubview(addLabel(text: "Program Status Register: ",fontSize:10,alignment:.right))
            case 4:
                psrN.text = "N"
                psrN.textColor = .lightGray
                psrN.adjustsFontSizeToFitWidth = true
                psrStackView.addArrangedSubview(psrN)
            case 5:
                psrZ.text = "Z"
                psrZ.textColor = .lightGray
                psrZ.adjustsFontSizeToFitWidth = true
                psrStackView.addArrangedSubview(psrZ)
            case 6:
                psrC.text = "C"
                psrC.textColor = .lightGray
                psrC.adjustsFontSizeToFitWidth = true
                psrStackView.addArrangedSubview(psrC)
            case 7:
                psrV.text = "V"
                psrV.textColor = .lightGray
                psrV.adjustsFontSizeToFitWidth = true
                psrStackView.addArrangedSubview(psrV)
            default:
                print("Invalid PSR field")
            }
        }
        
        
        let rvStackView = UIStackView()
        rvStackView.axis = .vertical
        rvStackView.distribution = .fillEqually
        rvStackView.spacing = 5
        //rvStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for row in 0 ... 7 {
            let hStackView = UIStackView()
            hStackView.axis = .horizontal
            hStackView.distribution = .fillEqually
            hStackView.spacing = 0
            //hStackView.translatesAutoresizingMaskIntoConstraints = false
        
            for col in 0 ... 3 {
                let label = UILabel()
                label.textAlignment = .center
                label.text = "0"
                label.adjustsFontSizeToFitWidth = true
                
                if col == 0 {
                    label.text = String(row)
                    label.textAlignment = .center
                }
                if col == 1 {
                    label.text = "00000000"
                    label.textAlignment = .center
                    label.backgroundColor = .lightGray
                }
                if col == 2 {
                    label.adjustsFontSizeToFitWidth = true
                }
                
                if col == 3 {
                    label.textColor = .blue
                    label.text = " "
                }
                
                registerViewArray.append(label)
                hStackView.addArrangedSubview(label)
            }
            rvStackView.addArrangedSubview(hStackView)
        }
        vStackView.addArrangedSubview(rvStackView)
        vStackView.addArrangedSubview(psrStackView)

        
        //vStackView.addArrangedSubview(addLabel(text: "Memory"))

        
        let mvStackView = UIStackView()
        mvStackView.axis = .vertical
        mvStackView.distribution = .fillProportionally
        mvStackView.spacing = 0
        for row in 0 ... 1 {
            let hStackView = UIStackView()
            hStackView.axis = .horizontal
            hStackView.distribution = .equalSpacing
            hStackView.spacing = 0
            
            for col in 0 ... 3 {
                let cell = UILabel()
                cell.tag = col
                //cell.translatesAutoresizingMaskIntoConstraints = false
                
                if row == 0 {
                    cell.text = "Memory - M" + String(col)
                    cell.font = cell.font.withSize(8)
                } else {
                    cell.text = "00000000"
                    cell.backgroundColor = .lightGray
                    cell.font = stackPointer.font.withSize(14)
                    cell.adjustsFontSizeToFitWidth = true
                    memoryViewArray.append(cell)
                }
                hStackView.addArrangedSubview(cell)
            }
            
            mvStackView.addArrangedSubview(hStackView)
        }
        vStackView.addArrangedSubview(mvStackView)
        
        addSubview(vStackView)
        
        activityIndicatorView.style = .whiteLarge
        addSubview(activityIndicatorView)
    
        let margins = layoutMarginsGuide
        Layout.manager(vStackView,margins:margins,left:0,right:0,top:0,bottom:0,pinH:.both,pinV:.both)
        
        
        setupNotficationObservers()
        
    }
    
    func addLabel(text:String,color:UIColor = .black,fontSize:CGFloat = 0,alignment:NSTextAlignment = .center) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = color
        if fontSize == 0 {
            label.adjustsFontSizeToFitWidth = true
        } else {
            label.font = label.font.withSize(fontSize)
        }
        label.textAlignment = alignment
        return label
    }
    
    func setupNotficationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(progress(notification:)), name: .inProgress, object: nil)
    }
    
    @objc func progress(notification: NSNotification) {
        activityIndicatorView.frame.origin.x = bounds.width / 2
        activityIndicatorView.frame.origin.y = bounds.height / 2
        if let userInfo = notification.userInfo {
            if let flag = userInfo["inProgress"] as? Bool  {
                if flag {
                    activityIndicatorView.startAnimating()
                } else {
                    activityIndicatorView.stopAnimating()
                }
                /*
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                let date = Date()
                let dateString = formatter.string(from: date)
                print ("\(dateString) In progress = \(flag)")
                 */
            }
        }
    }
    
    func set(register:Int,value:Int32) {
        if register > 7 || register < 0 {return}
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        registerViewArray[register * 4 + 2].text = numberFormatter.string(from: NSNumber(value:value))
        registerViewArray[register * 4 + 1].text = String(format:"%08X",value)
        if value >= 32 {
            if let displayCharacter = UnicodeScalar(Int(value)) {
                let displayString = String(String(displayCharacter).filter{!"\u{0085}".contains($0)})
                registerViewArray[register * 4 + 3].text = displayString
            } else {
                registerViewArray[register * 4 + 3].text = " "
            }
        } else {
            registerViewArray[register * 4 + 3].text = " "
        }
    }
    
    func setPSR(value:UInt32) {
        var psr:[Bool] = Array(repeating:false,count:4)
        psr[0] = (value & 0x10000000 != 0)
        psr[1] = (value & 0x20000000 != 0)
        psr[2] = (value & 0x40000000 != 0)
        psr[3] = (value & 0x80000000 != 0)
        if psr[0] {psrV.textColor = .black} else {psrV.textColor = .lightGray}
        if psr[1] {psrC.textColor = .black} else {psrC.textColor = .lightGray}
        if psr[2] {psrZ.textColor = .black} else {psrZ.textColor = .lightGray}
        if psr[3] {psrN.textColor = .black} else {psrN.textColor = .lightGray}
    }
    func setStackPointer(value:Int32) {
        stackPointer.text = String(format:"%08X",value)
    }
    func update(memory:[Int32]) {
        for cell in 0 ... 3 {
            memoryViewArray[cell].text = String(format:"%08X",memory[cell].bigEndian)
        }
    }
    
    func set(instructionBuffer:String) {
        self.instructionBuffer.text = instructionBuffer
    }
    
    func processor(_ processor: Processor, didUpdateRegisters: [Int32], psr: UInt32, stackPointer: Int32, memory: [Int32]) {
        setPSR(value:psr)
        for register in 0 ... 7 {
            set(register: register, value:didUpdateRegisters[register])
        }
        setStackPointer(value: stackPointer)
        update(memory: memory)
    }
    
}
