
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
 API for micro:bit explorer playground book.
 
 This module contains conditional compilation allowing testing in a non Swift Playgrounds
 environment. Code enclosed by '#if canImport(PlaygroundBluetooth)' will only be compiled
 in the Swift Playgrounds App.
*/

import Foundation

var group:DispatchGroup?

/**
 Execute one or more (maximum 8) machine instructions.
 
 **example:**
    - execute("21ff 0409 3901 d1fd")
 - parameters:
    - _ A string containing machine instructions. Each instruction must be exactly 4 hexadecimal
     characters. Each instruction can be separated by one or more spaces.
 */
public func execute(_ machineInstructions:String) {
    group = DispatchGroup()
    group!.enter()
    let command = String(APICommand.execute.rawValue) + "\\" + machineInstructions
    sendToLiveView(command:command)
    wait()
}
/**
 Write a signed 32 bit integer to a given loaction in memory.
 
 **example:**
    - writeMemory(location:3,number:-1)
 - parameters:
    - location: a number in the range 0 - 3 specifiying the location of the integer to be wriiten.
    - number: a 32 bit signed integer to be written to memory.
 
 */
public func writeMemory(location:Int,number:Int32) {
    group = DispatchGroup()
    group!.enter()
    let command = String(APICommand.memorySigned.rawValue) + "\\" + String(location) + "\\" + String(number)
    sendToLiveView(command:command)
    wait()
}
/**
 Write a 32 bit value to a given loaction in memory.
 
 **examples:**
 - writeMemory(location:0,value:0xffff)
 - writeMemory(location:1,value:0b111
 - parameters:
    - location: a number in the range 0 - 3 specifiying the location of the integer to be wriiten.
    - value: a 32 bit value to be written to memory.
 
 */
public func writeMemory(location:Int,value:UInt32) {
    group = DispatchGroup()
    group!.enter()
    let command = String(APICommand.memoryUnsigned.rawValue) + "\\" + String(location) + "\\" + String(value)
    sendToLiveView(command:command)
    wait()
}
/**
 Load a program of machine instructions. The function is primarily designed to demonstrate the "pipeline" cycle of the micro:bit processor.
 
 Although similar to **execute**, the program function differs in the following ways:
 - There is no restiction on the number of instructions it can process.
 - Instructions are passed to the micro:bit individually.
 - Branch instructions are not executed on the micro:bit, but simulated in the playground.
 - The function will not block succeeding functions from execution, therefore no functions should be placed after the program function.
 
 **example:**
 - program("21ff 0409 3901 d1fd")
 
 - parameters:
    - _ A string containing machine instructions. Each instruction must be exactly 4 hexadecimal
 characters. Each instruction can be separated by one or more spaces.
 */
public func program(_ machineInstructions:String) {
    group = nil
    let command = String(APICommand.program.rawValue) + "\\" + machineInstructions
    sendToLiveView(command:command)
    finish()
}
/**
 Assemble **Thumb** instruction source.
 
 The function wraps a *lightweight* assembler. Source errors are reported in an "Error Report" which will be displayed in an alert box on the Live View. If any errors are found, the function returns the String "Error", which will be appropriately handled by the **execute** and **program** functions.
 
 **example:**
 ```
 let source = """
 mov r1,#255    ;define counter
 lsl r1,r1,#1   ;multiple by 2
 loop:
 sub r1,#1      ;decrement the counter
 bne loop
 """
 let machine_code = assemble(source)
 execute(machine_code)
 ```
 - parameters:
    - _ A string containing Thumb instruction source. Each source statement must be separated
    by a newline character.
 - returns:
    A string containing machine instructions separated by a newline character. The string will contain "Error" if the assembly fails.
*/
public func assemble(_ source:String)-> String {
    let assembler = Assembler()
    do {
        let machineCode = try assembler.assemble(source)
        return machineCode
    } catch Assembler.error.invalidInput(let errorReport) {
        send(message:errorReport)
    } catch(let error) {
        print("Unexpected error from the Assembler - \(error)")
    }
    return "Error"
}
/**
 Synchronizes the the values in registers and memory with the playground dipsplay.
 */
public func synchronize() {
    group = DispatchGroup()
    group!.enter()
    let command = String(APICommand.sync.rawValue) + "\\"
    sendToLiveView(command:command)
    wait()
}
/**
 Clears the contents of registers on the micro:bit
 */
public func clear() {
    group = DispatchGroup()
    group!.enter()
    let command = String(APICommand.clear.rawValue) + "\\"
    sendToLiveView(command:command)
    wait()
}
/**
 Used by the start function to ensure the keypad is displayed prior to running user code
 */
func setKeypad(_ flag:Bool) {
    var command = String(APICommand.keypad.rawValue) + "\\"
    if flag {
        command += "ON"
    } else {
        command += "OFF"
    }
    sendToLiveView(command: command)
}
func send(message:String) {
    let command = String(APICommand.message.rawValue) + "\\" + message
    sendToLiveView(command: command)
    
}
/**
 Only used for testing in a non Swift playgrounds environment
 */
func waitOnConnect() {
    group = DispatchGroup()
    group!.enter()
    wait()
    sleep(1)
}
/*
 Swift Playgrounds section
*/
#if canImport(PlaygroundBluetooth)
import PlaygroundSupport
let proxy = page.liveView as? PlaygroundRemoteLiveViewProxy
let page = PlaygroundPage.current
let listener = Listener()

func sendToLiveView(command:String) {
    DispatchQueue.main.async {
        proxy!.send(.string(command))
    }
}
public func start() {
    page.needsIndefiniteExecution = true
    setKeypad(true)
}
public func finish() {
    page.finishExecution()
}
func wait() {
    proxy?.delegate = listener
    group!.wait()
}

class Listener: PlaygroundRemoteLiveViewProxyDelegate {
    func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy,
                             received message: PlaygroundValue) {
        if case let .string(message) = message {
            if let group = group {
                group.leave()
            }
            group = nil
        }
    }
    func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) { }
}
/*
  Non Swift Playgrounds section
*/
#else
var containerController:LiveViewContainerController?
let listener = Listener()
class Listener:ExplorerInterfaceDelegate {
    func ExplorerInterface(_ explorerInterface: ExplorerInterface, message: String) {
        if let group = group {
            group.leave()
        }
        group = nil
    }
}
public func start(container:LiveViewContainerController) {
    containerController = container
    setKeypad(true)
}
func sendToLiveView(command:String) {
    DispatchQueue.main.async {
        containerController?.liveViewController?.explorerInterface.command(command)
    }
}
public func wait() {
    containerController?.liveViewController?.explorerInterface.delegate = listener
    group!.wait()
}
func finish() {
    print("Finish Exection")
}
#endif
