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
@objc(KeypadView)
class KeypadView: UIView {
    var delegate:KeyPadViewDelegate?
    
    let keyboardSelectControl = UISegmentedControl(items:["Hex Keypad","Binary Keypad"])
    var keyButtonArray = [UIButton]()
    let instructionLabel = UILabel()
    let messageLabel = UILabel()
    
    let binaryKeyTitles = ["M0","M1","M2","M3","Clear","15","14","13","12"," ","11","10","9","8","","7","6","5","4","Execute","3","2","1","0",""]
    let hexKeyTitles = ["M0","M1","M2","M3","\u{232B}","0","1","2","3","All Clear","4","5","6","7","Space","8","9","A","B","Execute","C","D","E","F",""]
    
    var hexKeypadSelected = true
    var instruction:UInt16 = 0
    var charactersEntered = 0
    let MAX_CHARACTERS = 32
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    func setupView() {
        //backgroundColor = UIColor(displayP3Red: 237/255, green: 227/255, blue: 212/255, alpha: 1.0)
        backgroundColor = .clear
        let vStackView = UIStackView()
        vStackView.axis = .vertical
        vStackView.distribution = .fillEqually
        vStackView.spacing = 5
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        keyboardSelectControl.selectedSegmentIndex = 0
        keyboardSelectControl.translatesAutoresizingMaskIntoConstraints = false
        keyboardSelectControl.addTarget(self,action: #selector(segmentedControlAction),for: .primaryActionTriggered)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.backgroundColor = .gray
        messageLabel.backgroundColor = .black
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textColor = .white
        vStackView.addArrangedSubview(keyboardSelectControl)
        vStackView.addArrangedSubview(instructionLabel)
        vStackView.addArrangedSubview(messageLabel)
        let hStackView = UIStackView()
        hStackView.axis = .horizontal
        hStackView.distribution = .equalSpacing
        hStackView.spacing = 5
        hStackView.translatesAutoresizingMaskIntoConstraints = false
        for row in 0 ... 4 {
            let hStackView = UIStackView()
            hStackView.axis = .horizontal
            hStackView.distribution = .fillEqually
            hStackView.spacing = 5
            hStackView.translatesAutoresizingMaskIntoConstraints = false
            for col in 0 ... 4 {
                let keyButton = UIButton(type:.system)
                keyButton.translatesAutoresizingMaskIntoConstraints = false
                keyButton.tag = col * 4 + row
                
                if col == 4 {
                    keyButton.backgroundColor = .blue
                    keyButton.titleLabel?.font = UIFont(name: "Helvetica", size: 12)
                } else {
                    keyButton.backgroundColor = .gray
                }
                if row == 0 {
                    keyButton.backgroundColor = .blue
                    keyButton.titleLabel?.font = UIFont(name: "Helvetica", size: 12)
                }
                
                keyButton.setTitleColor(.white, for: .normal)
                keyButton.addTarget(self,action: #selector(keyButtonAction),for: .primaryActionTriggered)
                keyButtonArray.append(keyButton)
                hStackView.addArrangedSubview(keyButton)
            }
            vStackView.addArrangedSubview(hStackView)
        }
        vStackView.addArrangedSubview(hStackView)
        addSubview(vStackView)
        let margins = layoutMarginsGuide
        Layout.manager(vStackView,margins:margins,left:0,right:0,top:50,bottom:0,pinH:.both,pinV:.both)
        hexKeypad()
    }
    
    func hexKeypad() {
        for row in 0 ... 4 {
            for col in 0 ... 4 {
                keyButtonArray[col * 5 + row].setTitle(hexKeyTitles[col * 5 + row], for: .normal)
            }
        }
    }
    func binaryKeypad() {
        for row in 0 ... 4 {
            for col in 0 ... 4 {
                keyButtonArray[col * 5 + row].setTitle(binaryKeyTitles[col * 5 + row], for: .normal)
            }
        }
    }
    func binaryKey(_ sender:UIButton) {
        let key = Int((sender.titleLabel?.text!)!)
        if let key = key {
            let mask:UInt16 = 1 << key
            instruction = instruction ^ mask
            instructionLabel.text = String(format: "%04X", instruction)
            if instruction & mask == mask {
                sender.backgroundColor = .red
            } else {
                sender.backgroundColor = .gray
            }
        }
    }
    
    func hexKey(_ sender:UIButton) {
        guard let key = sender.titleLabel?.text else{return}
        let textCurrentlyInDisplay = instructionLabel.text
        if charactersEntered < MAX_CHARACTERS {
            if textCurrentlyInDisplay == nil {
                instructionLabel.text = key
            } else {
                instructionLabel.text = textCurrentlyInDisplay! + key
            }
            charactersEntered += 1
        } else {
            messageLabel.text = "Maximum number of characters entered"
        }
    }
    func clearBinary() {
        for row in 0 ... 3 {
            for col in 1 ... 4 {
                keyButtonArray[col * 5 + row].backgroundColor = .gray
            }
        }
    }
    func clearHex() {
        if ((instructionLabel.text?.count)! > 0) {
            let subString = instructionLabel.text?.dropLast()
            instructionLabel.text = String(subString!)
            messageLabel.text = ""
            if instructionLabel.text?.last != " " {
                charactersEntered -= 1
            }
        }
    }
    func memory(cell:Int) {
        messageLabel.text = ""
        guard let hexValue = instructionLabel.text?.components(separatedBy: .whitespaces).joined() else {return}
        if hexValue.count > 8 {
            messageLabel.text = "Number is too big"
        } else {
            delegate?.keyPadView(self, sendMemory: hexValue, cell: cell)
        }
    }
    @objc func segmentedControlAction(sender:UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0 :
            hexKeypadSelected = true
            hexKeypad()
            clearBinary()
        case 1 :
            hexKeypadSelected = false
            binaryKeypad()
            clearBinary()
            instruction = 0
            instructionLabel.text = String(format: "%04X", instruction)
        default :
            print("Invalid keypad selected")
        }
    }
    @objc func keyButtonAction(sender:UIButton) {
        switch sender.titleLabel?.text {
        case "Execute" :
            messageLabel.text = ""
            guard let trimmedInstruction = instructionLabel.text?.components(separatedBy: .whitespaces).joined() else {break}
            if ((trimmedInstruction.count) % 4) != 0 {
                messageLabel.text = "Incomplete instruction"
            } else {
                delegate?.keyPadView(self, sendInstructionBuffer: trimmedInstruction)
            }
        case "\u{232B}" :
            clearHex()
        case "Clear" :
            clearBinary()
            instruction = 0
            instructionLabel.text = String(format: "%04X", instruction)
        case "All Clear" :
            instructionLabel.text = ""
            charactersEntered = 0
        case "Space" :
            instructionLabel.text = instructionLabel.text! + " "
        case "M0" :
            memory(cell: 0)
        case "M1" :
            memory(cell: 1)
        case "M2" :
            memory(cell: 2)
        case "M3" :
            memory(cell: 3)
        default :
            if hexKeypadSelected {
                hexKey(sender)
            } else {
                binaryKey(sender)
            }
        }
    }
}
protocol KeyPadViewDelegate {
    func keyPadView(_ keyPadView:KeypadView,sendInstructionBuffer:String)
    func keyPadView(_ keyPadView:KeypadView,sendMemory:String,cell:Int)
}
