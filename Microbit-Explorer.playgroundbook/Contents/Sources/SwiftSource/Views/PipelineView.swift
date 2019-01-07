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
@objc(PipelineView)
class PipelineView: UIView {

    let fetchInstruction = UILabel()
    let decodeInstruction = UILabel()
    let executeInstruction = UILabel()
    let fetchPC = UILabel()
    
    let cycleButton = UIButton()
    let autoSwitch = UISwitch()
    let speedSlider = UISlider()
    
    var speed = 1.0
    
    var timer:Timer?
    
    var pc = 0
    var program:[UInt16] = Array()
    
    var psr:UInt32 = 0
    var registers:[Int32] = Array(repeating: 0, count: 8)
    
    let invalid:UInt16 = 0xde00
    var pipeline:[UInt16] = Array(repeating: 0xde00, count:3)
    
    var isConnected = false
    var inProgress = false
    
    var delegate:PipelineViewDelegate?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
        self.setupNotficationObservers()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
        self.setupNotficationObservers()
    }
    func setupView() {
        backgroundColor = UIColor(displayP3Red: 237/255, green: 227/255, blue: 212/255, alpha: 1.0)
        
        let vStackView = UIStackView()
        vStackView.axis = .vertical
        vStackView.distribution = .fillEqually
        vStackView.spacing = 0
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Pipeline"
        titleLabel.textColor = .blue
        vStackView.addArrangedSubview(titleLabel)
        
        let pipelineVStackView = UIStackView()
        pipelineVStackView.axis = .vertical
        pipelineVStackView.distribution = .fill
        pipelineVStackView.distribution = .fill
        pipelineVStackView.spacing = 0
        
        let pcStackView = UIStackView()
        pcStackView.axis = .horizontal
        pcStackView.distribution = .fillEqually
        pcStackView.spacing = 10
        
        let pcLabel = UILabel()
        pcLabel.text = "Program Counter:"
        pcLabel.textAlignment = .right
        pcLabel.adjustsFontSizeToFitWidth = true
        pcStackView.addArrangedSubview(pcLabel)
        fetchPC.text = String(format:"%08X",pc)
        fetchPC.adjustsFontSizeToFitWidth = true
        pcStackView.addArrangedSubview(fetchPC)
        
        vStackView.addArrangedSubview(pcStackView)
        
        let separator1 = UILabel()
        separator1.text = ">>> Pipeline >>>"
        separator1.textAlignment = .center
        separator1.backgroundColor = .gray
        pipelineVStackView.addArrangedSubview(separator1)
        
        let pipelineLabelStackView = UIStackView()
        pipelineLabelStackView.axis = .horizontal
        pipelineLabelStackView.distribution = .fillEqually
        pipelineLabelStackView.spacing = 10
        
        let fetchLabel = UILabel()
        let decodeLabel = UILabel()
        let executeLabel = UILabel()
        fetchLabel.text = "Fetch"
        decodeLabel.text = "Decode"
        executeLabel.text = "Execute"
        fetchLabel.textAlignment = .right
        decodeLabel.textAlignment = .right
        executeLabel.textAlignment = .right
        pipelineLabelStackView.addArrangedSubview(fetchLabel)
        pipelineLabelStackView.addArrangedSubview(decodeLabel)
        pipelineLabelStackView.addArrangedSubview(executeLabel)
        
        pipelineVStackView.addArrangedSubview(pipelineLabelStackView)
    
        let pipelineStackView = UIStackView()
        pipelineStackView.axis = .horizontal
        pipelineStackView.distribution = .fillEqually
        pipelineStackView.spacing = 10
    
        fetchInstruction.text = " "
        fetchInstruction.adjustsFontSizeToFitWidth = true
        decodeInstruction.adjustsFontSizeToFitWidth = true
        executeInstruction.adjustsFontSizeToFitWidth = true
        fetchInstruction.textAlignment = .right
        decodeInstruction.textAlignment = .right
        executeInstruction.textAlignment = .right
        
        pipelineStackView.addArrangedSubview(fetchInstruction)
        pipelineStackView.addArrangedSubview(decodeInstruction)
        pipelineStackView.addArrangedSubview(executeInstruction)
        
        pipelineVStackView.addArrangedSubview(pipelineStackView)
        
        let separator2 = UILabel()
        separator2.text = " "
        separator2.backgroundColor = .gray
        separator2.font = separator2.font.withSize(4)
        pipelineVStackView.addArrangedSubview(separator2)
        
        let filler1 = UIView()
        //filler1.layer.borderWidth = 1.0
        //filler1.layer.borderColor = UIColor.black.cgColor
        pipelineVStackView.addArrangedSubview(filler1)
        
        vStackView.addArrangedSubview(pipelineVStackView)
        
        let controlVStackView = UIStackView()
        controlVStackView.axis = .vertical
        controlVStackView.distribution = .fillProportionally
        controlVStackView.spacing = 10
        controlVStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionStackView = UIStackView()
        descriptionStackView.axis = .horizontal
        descriptionStackView.distribution = .fillProportionally
        descriptionStackView.spacing = 0
        
        let cycleLabel = UILabel()
        cycleLabel.text = "Cycle"
        cycleLabel.textAlignment = .center
        cycleLabel.font = UIFont.boldSystemFont(ofSize: 10)
        descriptionStackView.addArrangedSubview(cycleLabel)
        
        let autoLabel = UILabel()
        autoLabel.text = "Auto"
        autoLabel.textAlignment = .left
        autoLabel.font = UIFont.boldSystemFont(ofSize: 10)
        descriptionStackView.addArrangedSubview(autoLabel)
        
        let speedLabel = UILabel()
        speedLabel.text = "Speed"
        speedLabel.textAlignment = .center
        speedLabel.font = UIFont.boldSystemFont(ofSize: 10)
        descriptionStackView.addArrangedSubview(speedLabel)
        
        
        controlVStackView.addArrangedSubview(descriptionStackView)
        
        let controlStackView = UIStackView()
        controlStackView.axis = .horizontal
        controlStackView.distribution = .fillEqually
        controlStackView.spacing = 0
        
        cycleButton.setTitle("🛑", for: .normal)
        cycleButton.setTitle("🚲", for: .highlighted)
        cycleButton.setTitle("⛔️", for: .disabled)
        cycleButton.titleLabel?.font = UIFont.systemFont(ofSize: 32)
        //cycleButton.isEnabled = false
        cycleButton.addTarget(self,action: #selector(cycleButtonAction),for: .primaryActionTriggered)
        controlStackView.addArrangedSubview(cycleButton)
        
        autoSwitch.isEnabled = true
        autoSwitch.tintColor = .green
        autoSwitch.addTarget(self,action: #selector(switchAction),for:.valueChanged)
        controlStackView.addArrangedSubview(autoSwitch)
        
        speedSlider.isContinuous = false
        speedSlider.minimumValue = 0.1
        speedSlider.maximumValue = 2.0
        speedSlider.value = 1.0
        speedSlider.tintColor = .green
        speedSlider.addTarget(self,action: #selector(sliderAction),for:.valueChanged)
        controlStackView.addArrangedSubview(speedSlider)
        
        controlVStackView.addArrangedSubview(controlStackView)
        
        vStackView.addArrangedSubview(controlVStackView)
        
        addSubview(vStackView)
        
        let margins = layoutMarginsGuide
        Layout.manager(vStackView,margins:margins,left:0,right:0,top:0,bottom:-20,pinH:.both,pinV:.both)
    }
    func setupNotficationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(connected(notification:)), name: .isConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progress(notification:)), name: .inProgress, object: nil)
    }
    func set(fetch:String,decode:String,execute:String,pc:Int) {
        fetchInstruction.pushTransition(1.0)
        fetchInstruction.text = fetch
        decodeInstruction.pushTransition(1.0)
        decodeInstruction.text = decode
        executeInstruction.pushTransition(1.0)
        executeInstruction.text = execute
        fetchPC.text = String(format: "%0d", pc)
    }
    func autoCycleOff() {
        autoSwitch.setOn(false, animated: true)
        if timer != nil {
            timer?.invalidate()
        }
        return
    }
    func enable(_ flag:Bool) {
        if flag {
            cycleButton.isEnabled = true
            autoSwitch.isEnabled = true
        } else {
            cycleButton.isEnabled = false
            autoSwitch.isEnabled = false
        }
    }
    func autoCycleOn() {
        timer = Timer(timeInterval: speed, repeats: true, block: {(timer)
            in
            self.cycle()
        })
        if let timer = timer {
            RunLoop.current.add(timer, forMode:.default)
        }
    }
    func cycle() {
        delegate?.pipelineView(self, didCycle: true)
    }
    @objc func connected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let flag = userInfo["isConnected"] as? Bool  {
                isConnected = flag
            }
        }
    }
    @objc func progress(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let flag = userInfo["inProgress"] as? Bool  {
                inProgress = flag
            }
        }
    }
    @objc func cycleButtonAction(sender:UIButton) {
        cycle()
    }
    @objc func sliderAction(sender:UISlider) {
        speed = Double(speedSlider.maximumValue - Float(sender.value))
        if autoSwitch.isOn {
            timer?.invalidate()
            autoCycleOn()
        }
    }
    @objc func switchAction(sender:UISwitch) {
        if sender.isOn {
            autoCycleOn()
        } else {
            timer?.invalidate()
        }
    }
}
protocol PipelineViewDelegate {
    func pipelineView(_ pipelineView:PipelineView,didCycle:Bool)
}
