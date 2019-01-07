
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
 This class represents the micro:bit processor, encapsulating registers and memory (only 4 words)
 */
import Foundation
protocol ProcessorDelegate {
    func processor(_ processor:Processor,didUpdateRegisters :[Int32],psr:UInt32,stackPointer:Int32,memory:[Int32])
}
public enum APICommand:Int {
    case execute
    case keypad
    case program
    case memorySigned
    case memoryUnsigned
    case sync
    case clear
    case message
}
class Processor:PipelineViewDelegate {
    
    //var microbit:MicrobitX
   
    var viewController:LiveViewController
    
    var explorerInterface:ExplorerInterface
    
    var isConnected = false {
        didSet {
            let notificationInfo = ["isConnected":isConnected] as [String : Any]
            NotificationCenter.default.post(name: .isConnected, object: nil,userInfo:notificationInfo)
        }
    }
    
    var inProgress = false {
        didSet {
            let notificationInfo = ["inProgress":inProgress] as [String : Any]
            NotificationCenter.default.post(name:.inProgress,object:nil,userInfo:notificationInfo)
        }
    }
    
    var delegate:ProcessorDelegate?
    
    var psr:UInt32 = 0
    var stackPointer:Int32 = 0
    var registers:[Int32] = Array(repeating: 0, count: 8)
    var memory:[Int32] = Array(repeating: 0,count: 4)
    
    var program:[UInt16] = Array()
    var pc = 0
    let thumb = Thumb()
    
    let INVALID:UInt16 = 0xde00
    var pipeline:[UInt16] = Array(repeating: 0xde00, count:3)
    
    
    init(viewController:LiveViewController,microbit:MicrobitPlayground) {
        self.viewController = viewController
        self.explorerInterface = viewController.explorerInterface
        //self.microbit = microbit
        //microbit.delegate = self
        self.viewController.keypadView.delegate = self
        self.viewController.pipelineView.delegate = self
    }

    
    func serviceAvailable(service:ServiceName) {
        //print ("Sercice Available = \(service)")
        if service == .UART {
            isConnected = true
        
            let timer = Timer(timeInterval: 0.01, repeats: false, block: {(timer)
                in
                self.sync()
            })
            RunLoop.current.add(timer, forMode: .default)
            
        }
    }
    
    func api(command:String) {
        let arguments = command.components(separatedBy: "\\")
        guard let command = APICommand(rawValue: Int(arguments[0])!) else {return}
        switch (command) {
        case .keypad :
            if arguments[1] == "ON" {
                viewController.keypadView.isHidden = false
                viewController.pipelineView.isHidden = true
            } else {
                viewController.keypadView.isHidden = true
                viewController.pipelineView.isHidden = true
            }
        case .execute :
            viewController.keypadView.isHidden = false
            viewController.pipelineView.isHidden = true
            execute(instructionBuffer: arguments[1])
        case .program :
            viewController.keypadView.isHidden = true
            viewController.pipelineView.isHidden = false
            clear()
            pipeline[0] = INVALID
            pipeline[1] = INVALID
            pipeline[2] = 0
            pc = 0
            viewController.pipelineView.set(fetch: " ", decode:" ", execute: " ", pc: pc)
            viewController.pipelineView.autoCycleOff()
            program(instructionBuffer: arguments[1])
        case .memorySigned :
            guard let location = Int(arguments[1]) else {break}
            guard let number = Int32(arguments[2]) else {break}
            writeMemory(location: location, signed: number)
        case .memoryUnsigned :
            guard let location = Int(arguments[1]) else {break}
            guard let value = UInt32(arguments[2]) else {break}
            writeMemory(location: location, unsigned: value)
        case .clear :
            clear()
        case .sync :
            sync()
        case .message :
            viewController.alert(alertTitle: "Assembler Error", alertMessage: arguments[1])
        }
    }
    
    func toData16(_ value: UInt16) -> Data {
        var value = value
        return withUnsafeBytes(of: &value) { Data($0) }
    }
    func toData32(_ value: UInt32) -> Data {
        var value = value
        return withUnsafeBytes(of: &value) { Data($0) }
    }
    func toData32signed(_ value: Int32) -> Data {
        var value = value
        return withUnsafeBytes(of: &value) { Data($0) }
    }
    func createProgramFrom(codeString:String) -> (rc:Int,programBuffer:[UInt16],trimmedInstructionBuffer:String ) {
        var rc = 0
        var programBuffer:[UInt16] = Array()
        var trimmedInstructionBuffer = ""
        if codeString == "Error" {
            return(1,programBuffer,trimmedInstructionBuffer)
        }
        let instructions = codeString.components(separatedBy: "/")
        for instruction in instructions {
            if instruction.prefix(1) != "*" {
                let stripedControlCharacters = instruction.components(separatedBy: .controlCharacters).joined()
                let stripedWhiteSpace = stripedControlCharacters.components(separatedBy:.whitespaces).joined()
                trimmedInstructionBuffer += stripedWhiteSpace
            }
        }
        if ((trimmedInstructionBuffer.count) % 4) != 0 {
            viewController.alert(alertTitle: "Incomplete Instruction", alertMessage: "Each instruction must be exactly 4 hexadecimal characters long.")
            rc = 1
        } else {
            let characters = Array(trimmedInstructionBuffer)
            
            for i in stride(from: 0, to: characters.count, by: 4) {
                var charHex:[Character] = Array()
                charHex.append(characters[i])
                charHex.append(characters[i+1])
                charHex.append(characters[i+2])
                charHex.append(characters[i+3])
                let hex = String(charHex)
                if let instruction = UInt16(hex,radix:16) {
                    programBuffer.append(instruction)
                } else {
                    viewController.alert(alertTitle:"Invalid Instruction", alertMessage: "Looks like there is a problem with instruction \(i / 4 + 1). Each instruction must be 4 hexadecimal characters.")
                    rc = 1
                }
            }
        }
        return (rc,programBuffer,trimmedInstructionBuffer)
    }
    func execute(instructionBuffer:String) {
        let MAX_INSTRUCTIONS = 8
        var instructionData:Data = Data()
        let code = createProgramFrom(codeString: instructionBuffer)
        if code.rc == 0 {
            if code.programBuffer.count > MAX_INSTRUCTIONS {
                viewController.alert(alertTitle: "Too many instructions to process", alertMessage: "A maximum of \(MAX_INSTRUCTIONS) can be processed with the execute command")
                return
            }
            for instruction in code.programBuffer {
                instructionData.append(contentsOf:toData16(instruction))
            }
            viewController.processorView.set(instructionBuffer:code.trimmedInstructionBuffer.uppercased())
            transmitInstruction(buffer: instructionData)
        }
        
    }
    func program(instructionBuffer:String) {
        let code = createProgramFrom(codeString: instructionBuffer)
        if code.rc == 0 {
            program = code.programBuffer
            viewController.pipelineView.enable(true)
            viewController.alert(alertTitle: "Program ready to run", alertMessage: "Press the 'Cycle' button to fetch the instruction located at the Program Counter")
        }  else {
            viewController.pipelineView.enable(false)
        }
    }
    
    func writeMemory(location:Int,unsigned:UInt32) {
        let wordData = toData32(unsigned)
        transmitStorage(location: location, word: wordData)
    }
    func writeMemory(location:Int,signed:Int32) {
        let wordData = toData32signed(signed)
        transmitStorage(location: location, word: wordData)
    }
    func writeMemory(location:Int,hexString:String) {
        if location > 3 || location < 0 {
            viewController.alert(alertTitle: "Invalid memory location", alertMessage: "The memory location must be in the range 0 - 3")
            return
        }
        var wordData:Data = Data()
        let trimmedInstruction = hexString.components(separatedBy: .whitespaces).joined()
        if trimmedInstruction.count > 0  && trimmedInstruction.count <= 8 {
            if let number = UInt32(trimmedInstruction,radix:16) {
                wordData.append(contentsOf:toData32(number))
            } else {
                viewController.alert(alertTitle: "Invalid value (not hex)", alertMessage: "The value you want to write to memory must only contain valid hex chracters")
                return
            }
        } else {
            print("Value too large (max 32 bits)")
            viewController.alert(alertTitle: "Value is too large", alertMessage: "The value you want to write to memory must be a maximum of 32 bits")
            return
        }
        transmitStorage(location: location, word: wordData)
    }
    
    func transmitStorage(location:Int,word:Data) {
        viewController.processorView.set(instructionBuffer: " ")
        if location > 3 || location < 0 {
            viewController.alert(alertTitle: "Invalid memory location", alertMessage: "The memory location must be in the range 0 - 3")
            return
        }
        let command = [UInt8(0x04 + location)]
        var storageData = Data()
        storageData.append(contentsOf: word)
        if storageData.count < 19 {
            for _ in 0 ..< 19 - storageData.count {
                storageData.append(0x00)
            }
            storageData.append(contentsOf:command)
            uartSend(message: storageData)
        }
    }
    
    func transmitInstruction(buffer:Data) {
        let command = [UInt8(0x00)]
        var instructionData = Data()
        instructionData.append(contentsOf: buffer)
        instructionData.append(contentsOf: [0x60,0x47])
        if instructionData.count < 19 {
            for _ in 0 ..< 19 - instructionData.count {
                instructionData.append(0x00)
            }
            instructionData.append(contentsOf:command)
        }
        uartSend(message: instructionData)
    }
    
    func reset() {
        var message:[UInt8] = Array(repeating: 0, count: 20)
        message[19] = 0x02
        let messageData = Data(message)
        uartSend(message: messageData)
    }
    
    func clear() {
        var message:[UInt8] = Array(repeating: 0, count: 20)
        viewController.processorView.set(instructionBuffer: " ")
        message[19] = 0x03
        let messageData = Data(message)
        uartSend(message: messageData)
    }
    func sync() {
        var message:[UInt8] = Array(repeating: 0, count: 20)
        message[19] = 0x08
        let messageData = Data(message)
        uartSend(message: messageData)
    }
    
    func uartSend(message:Data) {
        //print("\(message.map { String(format: "%02x", $0 ) }.joined())")
        if inProgress {
            viewController.processorView.set(instructionBuffer: "BUSY!")
            return
        }
        if isConnected {
            inProgress = true
            explorerInterface.uartSend(buffer: message)
        } else {
            viewController.alert(alertTitle: "Micro:bit not connected", alertMessage: "Try and connect your Micro:bit")
        }
    }
    
    func disconnected() {
        viewController.alert(alertTitle: "Micro:bit has disconnected", alertMessage: "Try and reconnect your Micro:bit")
        viewController.pipelineView.autoCycleOff()
        isConnected = false
        inProgress = false
    }
    
    func uartReceived(message:Data) {
        //print("\(message.map { String(format: "%02x", $0 ) }.joined())")
        let type:UInt8 = message.getInteger(start: 0, length: 1)
        switch type {
        case 1 :
            registers[0] = message.getInteger(start:4,length:4)
            registers[1] = message.getInteger(start:8,length:4)
            registers[2] = message.getInteger(start:12,length:4)
            registers[3] = message.getInteger(start:16,length:4)
        case 2 :
            registers[4] = message.getInteger(start:4,length:4)
            registers[5] = message.getInteger(start:8,length:4)
            registers[6] = message.getInteger(start:12,length:4)
            registers[7] = message.getInteger(start:16,length:4)
        case 3 :
            psr = message.getInteger(start:4,length:4)
            stackPointer = message.getInteger(start:8,length:4)
        case 4:
            memory[0] = message.getInteger(start:4,length:4)
            memory[1] = message.getInteger(start:8,length:4)
            memory[2] = message.getInteger(start:12,length:4)
            memory[3] = message.getInteger(start:16,length:4)
            //printRegisters()
            delegate?.processor(self, didUpdateRegisters: registers, psr: psr, stackPointer: stackPointer, memory: memory)
            inProgress = false
        default :
            print("Invalid type")
        }
    }
    func pipelineView(_ pipelineView: PipelineView, didCycle: Bool) {
        var fetchText = ""
        var decodeText = ""
        var executeText = ""
        if inProgress || !isConnected {return}
        if pc < 0 || pc > program.count + 2{
            fetchText = "Invalid fetch"
            viewController.pipelineView.set(fetch: fetchText, decode:decodeText, execute: executeText, pc: pc)
            return
        }
        if pipeline[2] != INVALID {
            pipeline[2] = thumb.fetch(program: program, pc: pc)
            fetchText = thumb.fetch(program:program,pc:pc)
        } else {
            fetchText = ""
        }
        if pipeline[1] != INVALID {
            decodeText = thumb.decode(instruction: pipeline[1], pc: pc-1, psr: psr, registers: registers)
        } else {
            decodeText = ""
        }
        if pipeline[0] != INVALID {
            let executeResult = thumb.execute(instruction: pipeline[0], pc: pc-2, psr: psr, registers: registers)
            executeText = executeResult.text
            if executeResult.rc == 2 {
                pipeline[2] = INVALID
                pipeline[1] = INVALID
                pipeline[0] = INVALID
                pc = executeResult.pc
                executeText = "Branch to instruction \(pc+1)"
                decodeText = ""
                fetchText = ""
            }
            if executeResult.rc == 0 {
                let instructionString = String(format:"%04X",pipeline[0])
                execute(instructionBuffer:instructionString)
            }
        } else {
            executeText = ""
        }
        pipeline[0] = pipeline[1]
        pipeline[1] = pipeline[2]
        pc += 1
        if pc >= program.count {
            pipeline[2] = INVALID
        } else {
            pipeline[2] = 0
        }
        if (fetchText == "" && decodeText == "" && executeText == "") {
            fetchText = "End of program"
            viewController.pipelineView.autoCycleOff()
        }
        viewController.pipelineView.set(fetch: fetchText, decode:decodeText, execute: executeText, pc: pc)
    }
    func printRegisters() {
        var regNo = 0
        for register in registers {
            print(String(format: "reg%d %08x",regNo, register))
            regNo += 1
        }
        print(String(format: "PSR  %08x",psr))
        print(String(format: "Stack Pointer %08x", stackPointer))
        var cell = 0
        for m in memory {
            print(String(format: "memory cell%d %08x",cell, m))
            cell += 1
        }
    }
}
extension Processor:KeyPadViewDelegate {
    func keyPadView(_ keyPadView: KeypadView, sendInstructionBuffer: String) {
        execute(instructionBuffer: sendInstructionBuffer)
    }
    
    func keyPadView(_ keyPadView: KeypadView, sendMemory: String, cell: Int) {
        writeMemory(location: cell, hexString: sendMemory)
    }
}
