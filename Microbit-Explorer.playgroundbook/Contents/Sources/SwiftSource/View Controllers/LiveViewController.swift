
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
@objc(LiveViewController)
class LiveViewController: UIViewController {
    
    public weak var containerViewController: LiveViewContainerController!
    
    @IBOutlet weak var processorView: ProcessorView!
    @IBOutlet weak var keypadView: KeypadView!
    @IBOutlet weak var pipelineView: PipelineView!
    
    var connectionView:ConnectionView?
    var explorerInterface = ExplorerInterface()
    var processor:Processor?
    
    override public func viewDidLoad() {
        
        processorView.isHidden = false
        keypadView.isHidden = false
        pipelineView.isHidden = true
        
        connectionView = ConnectionView(view: view,microbit:explorerInterface.microbit)
        processor = Processor(viewController: self, microbit: explorerInterface.microbit)
        processor?.delegate = processorView
        explorerInterface.processor = processor
    }
    func alert(alertTitle:String,alertMessage:String) {
        let alert = UIAlertController(title:alertTitle,
                                      message:alertMessage,
                                      preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"OK",style:.default,handler:nil))
        self.present(alert,animated:true)
    }
    
}
