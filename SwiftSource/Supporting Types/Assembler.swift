//
//  Assembler.swift
//  Assembler
//
//  Created by Peter Wallen on 25/10/2018.
//  Copyright © 2018 Peter Wallen. All rights reserved.
//
//
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
 Simple Assembler to generate machine code for the ARM Cortex-M0 processor
 from Thumb assembler source code.
 
 Inspired by [Article: Touch Develop in 208 Bits](http://www.touchdevelop.com/docs/touch-develop-in-208-bits)
 
 This code has been designed for use within a Swift Playgrounds ennvironment to demonstrate the Thumb machine instructions on a micro:bit computer. It is NOT a substitute for the GNU Arm Embedded Toolchain and source code may not be compatible between this assembler and the Arm assembler. In particular:
        - instructions manipulationg Hi registers are not fully supported.
        - only Thumb mnemonics are supported (Unified assembler language is not supported).
        - register ranges are not supported. For example, PUSH {r1 - r4} must be coded as PUSH {r1,r2,r3,r4}. (PUSH {r1 - r4} will be interpreted as PUSH {r1,r4}).
        - breakpoint instruction (BKPT) is not supported.
        - rev16 mnemonic is replaced by revh
    In general, parameter checking is not as stringent as the Arm assembler, therefore, it is possible that invalid source code may be interpreted incorrectly and not throw an error.
    Arm Assembler directives are not supported.
*/
import Foundation
public class Assembler {
    enum encodeRules {
        case r0,r1,r2,r3,r4,r5,i0,i1,i2,i3,i4,i5,i6,i7,la,lb,lc,list1,list2
        
        func meta() -> (pattern:UInt16,max:Int,multiplier:Int) {
            switch self {
            case .r0: return (0x0007,7,1)
            case .r1: return (0x0038,7,1)
            case .r2: return (0x0087,15,1)
            case .r3: return (0x0078,14,1)
            case .r4: return (0x01C0,7,1)
            case .r5: return (0x0700,7,1)
            case .i0: return (0x00ff,255,1)
            case .i1: return (0x00ff,1020,4)
            case .i2: return (0x007f,512,4)
            case .i3: return (0x01c0,7,1)
            case .i4: return (0x07c0,31,1)
            case .i5: return (0x07c0,124,4)
            case .i6: return (0x0000,0,1)
            case .i7: return (0x07c0,62,2)
            case .la: return (0x07ff,11,1)
            case .lb: return (0x00ff,8,1)
            case .lc: return (0x07ff,22,1)
            case .list1: return (0x00ff,255,1)
            case .list2: return (0x0100,1,1)
            }
        }
    }
    public enum error:Error {
        case invalidInput(errorReport:String)
    }
    var encoding:[[Any]] = Array()
    
    var symbolTable:[String] = Array()
    var instructions:[UInt16] = Array()
    var messages:[String] = Array()
    var errorCount = 0
    
    public init() {
       add( ["adc,r,r",0x4140,encodeRules.r0,encodeRules.r1])
        add(["add,r,r",0x4400,encodeRules.r2,encodeRules.r3])
        add(["add,r,pc,#",0xa000,encodeRules.r5,encodeRules.i1])
        add(["add,r,sp,#",0xa800,encodeRules.r5,encodeRules.i1])
        add(["add,sp,#",0xb000,encodeRules.i2])
        add(["add,r,r,#",0x1c00,encodeRules.r0,encodeRules.r1,encodeRules.i3])
        add(["add,r,r,r",0x1800,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["add,r,#",0x3000,encodeRules.r5,encodeRules.i0])
        add(["adr,r,#",0xa000,encodeRules.r5,encodeRules.i1])
        add(["and,r,r",0x4000,encodeRules.r0,encodeRules.r1])
        add(["asr,r,r",0x4100,encodeRules.r0,encodeRules.r1])
        add(["asr,r,r,#",0x1000,encodeRules.r0,encodeRules.r1,encodeRules.i4])
        add(["b,*",0xe000,encodeRules.la])
        add(["bic,r,r",0x4380,encodeRules.r0,encodeRules.r1])
        //add(["bkpt,#",0xbe00,encodeRules.i0])
        add(["bl,*",0xf000,encodeRules.lc])
        add(["beq,*",0xd000,encodeRules.lb])
        add(["bne,*",0xd100,encodeRules.lb])
        add(["bcs,*",0xd200,encodeRules.lb])
        add( ["bcc,*",0xd300,encodeRules.lb])
        add(["bmi,*",0xd400,encodeRules.lb])
        add(["bpl,*",0xd500,encodeRules.lb])
        add(["bvs,*",0xd600,encodeRules.lb])
        add(["bvc,*",0xd700,encodeRules.lb])
        add(["bhi,*",0xd800,encodeRules.lb])
        add(["bls,*",0xd900,encodeRules.lb])
        add(["bge,*",0xda00,encodeRules.lb])
        add(["blt,*",0xdb00,encodeRules.lb])
        add(["bgt,*",0xdc00,encodeRules.lb])
        add(["ble,*",0xdd00,encodeRules.lb])
        add(["bx,r",0x4700,encodeRules.r3])
        add(["bx,lr",0x4700,encodeRules.r3])
        add(["cmn,r,r",0x42c0,encodeRules.r0,encodeRules.r1])
        add(["cmp,r,r",0x4280,encodeRules.r0,encodeRules.r1])
        //add(["cmp,r,r",0x4500,encodeRules.r2,encodeRules.r3]) hi reg compare not in use
        add(["cmp,r,#",0x2800,encodeRules.r5,encodeRules.i0])
        add(["eor,r,r",0x4040,encodeRules.r0,encodeRules.r1])
        add(["ldmia,*",0xc800,encodeRules.list1,encodeRules.r5,encodeRules.i0])
        add(["ldr,r,[r,#]",0x6800,encodeRules.r0,encodeRules.r1,encodeRules.i5])
        add(["ldr,r,[r,r]",0x5800,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["ldr,r,[pc,#]",0x4800,encodeRules.r5,encodeRules.i1])
        add(["ldr,r,[sp,#]",0x9800,encodeRules.r5,encodeRules.i1])
        add(["ldrb,r,[r,#]",0x7800,encodeRules.r0,encodeRules.r1,encodeRules.i4])
        add(["ldrb,r,[r,r]",0x5c00,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["ldrh,r,[r,#]",0x8800,encodeRules.r0,encodeRules.r1,encodeRules.i7])
        add(["ldrh,r,[r,r]",0x5a00,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["ldrsb,r,[r,r]",0x5600,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["ldrsh,r,[r,r]",0x5e00,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["lsl,r,r",0x4080,encodeRules.r0,encodeRules.r1])
        add(["lsl,r,r,#",0x0000,encodeRules.r0,encodeRules.r1,encodeRules.i4])
        add(["lsr,r,r",0x40c0,encodeRules.r0,encodeRules.r1])
        add(["lsr,r,r,#",0x0800,encodeRules.r0,encodeRules.r1,encodeRules.i4])
        add(["mov,r,r",0x0000,encodeRules.r0,encodeRules.r1])
        //add(["mov,r,r",0x4600,encodeRules.r2,encodeRules.r3]) hi reg move not in use
        add(["mov,r,#",0x2000,encodeRules.r5,encodeRules.i0])
        add(["mul,r,r",0x4340,encodeRules.r0,encodeRules.r1])
        add(["mvn,r,r",0x43c0,encodeRules.r0,encodeRules.r1])
        add(["neg,r,r",0x4240,encodeRules.r0,encodeRules.r1])
        add(["orr,r,r",0x4300,encodeRules.r0,encodeRules.r1])
        add(["pop,*",0xbc00,encodeRules.list2,encodeRules.i0])
        add(["push,*",0xb400,encodeRules.list2,encodeRules.i0])
        add(["rev,r,r",0xba00,encodeRules.r0,encodeRules.r1])
        add(["revh,r,r",0xba40,encodeRules.r0,encodeRules.r1]) /* replaces rev16 */
        add(["revsh,r,r",0xbac0,encodeRules.r0,encodeRules.r1])
        add(["ror,r,r",0x41C0,encodeRules.r0,encodeRules.r1])
        add(["sbc,r,r",0x4180,encodeRules.r0,encodeRules.r1])
        add(["stmia,*",0xc000,encodeRules.list1,encodeRules.r5,encodeRules.i0])
        add(["str,r,[r,#]",0x6000,encodeRules.r0,encodeRules.r1,encodeRules.i5])
        add(["str,r,[r,r]",0x5000,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["str,r,[sp,#]",0x9000,encodeRules.r5,encodeRules.i1])
        add(["strb,r,[r,#]",0x7000,encodeRules.r0,encodeRules.r1,encodeRules.i4])
        add(["strb,r,[r,r]",0x5400,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["strh,r,[r,#]",0x8000,encodeRules.r0,encodeRules.r1,encodeRules.i7])
        add(["strh,r,[r,r]",0x5200,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["sub,sp,#",0xb080,encodeRules.i2])
        add(["sub,r,r,#",0x1e00,encodeRules.r0,encodeRules.r1,encodeRules.i3])
        add(["sub,r,r,r",0x1a00,encodeRules.r0,encodeRules.r1,encodeRules.r4])
        add(["sub,r,#",0x3800,encodeRules.r5,encodeRules.i0])
        add(["swi,#",0xdf00,encodeRules.i0])
        add(["sxtb,r,r",0xb240,encodeRules.r0,encodeRules.r1])
        add(["sxth,r,r",0xb200,encodeRules.r0,encodeRules.r1])
        add(["tst,r,r",0x4200,encodeRules.r0,encodeRules.r1])
        add(["uxtb,r,r",0xb2c0,encodeRules.r0,encodeRules.r1])
        add(["uxth,r,r",0xb280,encodeRules.r0,encodeRules.r1])
    }
    /**
     Assemble sourc code and generate Thumb 16 bit binary code.
     
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
     ```
     - parameters:
        - _ A string containing source code. Each source statement must be separated by a newline character.
     - returns:
        A string containing one or more 16 bit binary codes encoded using hexadecimal notation. Each code is separated by a newline character.
     - throws:
        - invalidInput(errorReport:String) A string forming an error report listing invalid instructions.
     */
    public func assemble(_ code:String) throws -> String {
        var output = ""
        var lines = code.components(separatedBy: .controlCharacters)
        lines = stripComments(source: lines)
        let symbolTableSize = buildSymbolTable(source: lines)
        let instructionArraySize = encodeInstructions(source: lines)
        if errorCount > 0 {
            output = "Error Report\n\n" + getMessages() + "\nLines processed = \(lines.count)\nSymbol Table Size = \(symbolTableSize)\nInstruction Array Size = \(instructionArraySize)\nErrors = \(errorCount)"
            throw error.invalidInput(errorReport: output)
            //throw NSError(domain:output, code: 1, userInfo: nil)
        } else {
            output = getMachineCode()
        }
        return output
    }
    
    func add(_ rule:[Any]) {
        encoding.append(rule)
    }
    
    func buildSymbolTable(source:[String])->Int {
        var savedLabel = ""
        var add = true
        for line in source {
            let label = line.components(separatedBy: CharacterSet(charactersIn: ":"))
            if label.count > 1 {
                let instruction = label[1].components(separatedBy: .whitespaces).joined()
                if instruction.count == 0 {
                    savedLabel = label[0]
                    add = false
                } else {
                    savedLabel = label[0]
                    add = true
                }
            } else {
                add = true
            }
            if add {
                symbolTable.append(savedLabel.components(separatedBy: .whitespaces).joined())
                savedLabel = ""
            }
        }
        return symbolTable.count
    }
    func stripComments(source:[String]) -> [String] {
        var lines:[String] = Array()
        for line in source {
            var nonComment = line
            let comments = line.components(separatedBy: CharacterSet(charactersIn: "@"))
            if comments.count > 0 {
                nonComment = comments[0]
            }
            if nonComment.count > 0 {
                lines.append(nonComment)
            }
        }
        return lines
    }
    func encodeInstructions(source:[String])->Int {
        var locationCounter = 0
        for line in source {
            var instruction = ""
            var parms:[UInt16] = Array()
            var symbols:[String] = Array()
            var branchLabel = ""
            var found = false
            let label = line.components(separatedBy: CharacterSet(charactersIn: ":"))
            if label.count > 1 {
                instruction = label[1]
            } else {
                instruction = label[0]
            }
            instruction = clean(instruction)
            
            if instruction != "" {
                //print("raw instruction = \(instruction)")
                symbols = instruction.components(separatedBy:CharacterSet(charactersIn: ","))
                let numericCharacterSet = CharacterSet(charactersIn: "0123456789")
                let instructionFormat = instruction.components(separatedBy: numericCharacterSet).joined()
                let numerics = instruction.components(separatedBy:numericCharacterSet.inverted)
                for n in numerics {
                    if n != "" {
                        parms.append(UInt16(n) ?? 0)
                    }
                }
               
                for instructionNumber in 0 ..< encoding.count {
                    var instructionEncoding = encoding[instructionNumber][0] as! String
                    var format = instructionFormat.lowercased()
                    let parts = instructionEncoding.components(separatedBy: CharacterSet(charactersIn: ","))
                    if parts.count > 1 {
                        if parts[1] == "*" {
                            let components = instructionFormat.components(separatedBy: CharacterSet(charactersIn: ","))
                            format = components[0]
                            instructionEncoding = parts[0]
                        }
                    }
                    //print ("instruction format = \(format) instructionEncoding = \(instructionEncoding)")
                    if format == instructionEncoding {
                        //print ("Instruction Number = \(instructionNumber)")
                        var mc = UInt16(encoding[instructionNumber][1] as! Int)
                        var parmIndex = 2
                        let rule = encoding[instructionNumber][parmIndex] as! encodeRules
                        switch(rule) {
                        case .lb,.la,.lc :
                            branchLabel = symbols[1]
                        case .list1 :
                            let baseReg = parms[0]
                            var regList:[UInt16] = Array()
                            for i in 1 ..< parms.count  {
                                regList.append(parms[i])
                            }
                            let operand = setList(list: regList)
                            parms = Array()
                            parms.append(baseReg)
                            parms.append(operand)
                            parmIndex = 3
                        case .list2:
                            var pclrFlag:UInt16 = 0
                            if symbols.joined().range(of: "pc") != nil {
                                pclrFlag = 1
                            }
                            if symbols.joined().range(of: "lr") != nil {
                                pclrFlag = 1
                            }
                            let operand = setList(list:parms)
                            parms = Array()
                            parms.append(pclrFlag)
                            parms.append(operand)
                            parmIndex = 2
                        default :
                            branchLabel = ""
                        }
                        if branchLabel == "" {
                            if parms.count == 0 {
                                parms.append(UInt16(rule.meta().max))
                            }
                            //print ("Parm count = \(parms.count)   \(encoding[instructionNumber].count)")
                            if encoding[instructionNumber].count < parms.count + 2 {
                                break
                            }
                            for parm in parms {
                                //print ("Parm index = \(parmIndex) \(parms) \(encoding[instructionNumber].count)")
                                let rule = encoding[instructionNumber][parmIndex] as! encodeRules
                                if parm > rule.meta().max {
                                    messages.append("\(line) - Invalid parameter")
                                    errorCount += 1
                                }
                                let pattern = rule.meta().pattern
                                let operand = parm / UInt16(rule.meta().multiplier)
                                mc = setBits(machineCode: mc, operand: operand, pattern: pattern)
                                //print (String(format: "machine code %04X", mc))
                                parmIndex += 1
                            }
                        } else {
                            let location = findSymbol(branchLabel)
                            if location != 9999 {
                                //print ("Current Location \(locationCounter) Branch to \(location)")
                                //let rule = encoding[instructionNumber][parmIndex] as! encodeRules
                                //let max = rule.meta().max
                                let pattern = rule.meta().pattern
                                switch(rule) {
                                case .lb :
                                    let branchOffset = Int8(location - locationCounter - 2)
                                    let offset = UInt8(bitPattern: branchOffset)
                                    mc = setBits(machineCode: mc, operand: UInt16(offset), pattern: pattern)
                                case .la :
                                    let branchOffset = Int16(location - locationCounter - 2)
                                    let offset = UInt16(bitPattern: branchOffset)
                                    mc = setBits(machineCode: mc, operand: offset, pattern: pattern)
                                case .lc:
                                    var branchOffset = Int32(location - locationCounter)
                                    if branchOffset <= 0 {
                                        branchOffset -= 2
                                    } else {
                                        branchOffset -= 1
                                    }
                                    let offset = UInt32(bitPattern:branchOffset)
                                    let highOffset = UInt16((offset & 0xffff0000) >> 16)
                                    let lowOffset = UInt16(offset & 0x0000ffff)
                                    //print (String(format:"%08X %04X %04X",offset,highOffset,lowOffset))
                                    mc = setBits(machineCode: mc, operand: highOffset, pattern: pattern)
                                    instructions.append(mc)
                                    locationCounter += 1
                                    mc = UInt16(encoding[instructionNumber][1] as! Int)
                                    mc = setBits(machineCode: mc, operand: lowOffset, pattern: pattern)
                                    //print (String(format: "lowOffset %04X machine code %04X",lowOffset, mc))
                                    mc = setBits(machineCode: mc, operand: 0x01, pattern: 0x0800)
                                    symbolTable.insert("", at: locationCounter)
                                default :
                                    break
                                }
                                //print (String(format: "machine code %04X", mc))
                            } else {
                                messages.append("\(line) - Symbol not found")
                                errorCount += 1
                            }
                        }
                        //print (String(format: "machine code %04X", mc))
                        instructions.append(mc)
                        locationCounter += 1
                        found = true
                        break
                    }
                }
                if !found {
                    messages.append("\(line) - Invalid, or, instruction not supported")
                    errorCount += 1
                }
            }
        }
        return instructions.count
    }
    func setBits(machineCode:UInt16,operand:UInt16,pattern:UInt16) -> UInt16 {
        var mc = machineCode
        var operandMask:UInt16 = 1
        for b:UInt16 in 0 ... 15 {
            let mask:UInt16 = (1 << b)
            if pattern & mask == mask {
                if operand & operandMask == operandMask {
                    mc = mc | (1 << b)
                }
                operandMask = operandMask << 1
            }
        }
        return mc
    }
    func findSymbol(_ label:String) -> Int {
        for index in 0 ..< symbolTable.count {
            if label == symbolTable[index] {
                return index
            }
        }
        return 9999
    }
    func getMachineCode() -> String {
        var machineCode = ""
        for instruction in instructions {
            machineCode = machineCode + String(format:"%04X",instruction) + "\n"
        }
        return machineCode
    }
    func getMessages() -> String {
        var messageLog = ""
        for entry in messages {
            messageLog = messageLog + entry + "\n"
        }
        return messageLog
    }
    func clean(_ instruction:String) -> String {
        var cleanInstruction = instruction.trimmingCharacters(in: .whitespaces)
        if let matchedIndex = cleanInstruction.index(of: " ") {
            cleanInstruction.replaceSubrange(matchedIndex...matchedIndex,with:",")
        }
        cleanInstruction = cleanInstruction.components(separatedBy: .whitespaces).joined()
        return cleanInstruction
    }
    func setList(list:[UInt16])->UInt16 {
        var operand:UInt16 = 0
        for parm in list {
            operand = operand + 0x01 << parm
        }
        return operand
    }
}
