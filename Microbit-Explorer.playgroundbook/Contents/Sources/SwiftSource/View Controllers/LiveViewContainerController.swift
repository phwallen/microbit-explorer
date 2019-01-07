
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
 This class helps manage view layouts during orientation changes. It is based on code
 devloped by : Gary J.H. Atkinson of Stinky Kitten Ltd.
 and used here under the terms of it's MIT License and includes the following copyright notice: Copyright (c) 2018 micro:bit Educational Foundation
*/
import UIKit

@objc(LiveViewContainerController)
public class LiveViewContainerController: UIViewController {
    
    var liveViewController: LiveViewController?
   
    @IBOutlet weak var containerView: UIView!
    
    public static func controllerFromStoryboard(_ storyboardName: String) -> LiveViewContainerController {
        let bundle = Bundle(for: LiveViewContainerController.self)
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! LiveViewContainerController
        return controller
    }
    
    override public func viewDidLoad() {
    
    }
    
    override public func prepare(for seque: UIStoryboardSegue, sender: Any?) {
        if seque.identifier == "embededLiveViewControllerSeque" {
            liveViewController = seque.destination as? LiveViewController
            #if swift(>=4.2)
            self.addChild(liveViewController!)
            #else
            self.addChildViewController(liveViewController!)
            #endif
            self.liveViewController!.containerViewController = self
        }
    }
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setChildsConstraintsFromSize(self.view.frame.size)
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        self.setChildsConstraintsFromSize(size)
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func setChildsConstraintsFromSize(_ size: CGSize) {
        let ratio = size.width / size.height
        let horizontalSizeClass = UITraitCollection(horizontalSizeClass: ratio > 1 ? .regular : .compact)
        let verticalSizeClass = UITraitCollection(verticalSizeClass: ratio > 1 ? .compact : .regular)
        let newTraitsCollection = UITraitCollection(traitsFrom: [horizontalSizeClass, verticalSizeClass])
        
        #if swift(>=4.2)
        for childViewController in self.children {
            self.setOverrideTraitCollection(newTraitsCollection, forChild: childViewController)
        }
        #else
        for childViewController in self.childViewControllers {
        self.setOverrideTraitCollection(newTraitsCollection, forChildViewController: childViewController)
        }
        #endif
    }

}
/*
 The following section will only compile in a Swift Playgrounds environment.
*/
#if canImport(PlaygroundBluetooth)
import PlaygroundSupport
extension LiveViewContainerController: PlaygroundLiveViewMessageHandler {
    public func liveViewMessageConnectionOpened() {
        
    }
    public func liveViewMessageConnectionClosed() {
        
    }
    
    public func receive(_ message: PlaygroundValue) {
        if case let .string(message) = message {
            liveViewController?.explorerInterface.command(message)
        }
    }
    public func sendToContentView(instruction:String) {
        send(.string(instruction))
    }
}
#endif
