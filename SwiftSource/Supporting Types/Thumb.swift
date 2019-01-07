
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
 This class disassembles Thumb machine instructions. It can determine if an instruction can be passed to the micro:bit for execution or it requires simulation (i.e. branch instructions)
 */
import Foundation
class Thumb {
    var rc = 0
    var pc = 0
    var lr = 0
    
    var text = " "
    var target:UInt32 = 0
    
    func fetch(program:[UInt16],pc:Int)->String {
        return String(format:"%04X",program[pc])
    }
    func fetch(program:[UInt16],pc:Int)->UInt16 {
        return program[pc]
    }
    func decode(program:[UInt16],pc:Int,psr:UInt32,registers:[Int32]) -> String {
        self.text = " "
        interpret(instruction:program[pc],update:false,psr:psr,registers:registers)
        return(self.text)
    }
    func decode(instruction:UInt16,pc:Int,psr:UInt32,registers:[Int32]) -> String {
        self.text = " "
        interpret(instruction:instruction,update:false,psr:psr,registers:registers)
        return(self.text)
    }
    func execute(program:[UInt16],pc:Int,psr:UInt32,registers:[Int32]) -> (rc:Int,pc:Int,text:String) {
        self.text = " "
        self.pc = pc
        self.rc = 0
        interpret(instruction: program[pc],update:true,psr:psr,registers:registers)
        return(self.rc,self.pc,self.text)
    }
    func execute(instruction:UInt16,pc:Int,psr:UInt32,registers:[Int32]) -> (rc:Int,pc:Int,text:String) {
        self.text = " "
        self.pc = pc
        self.rc = 0
        interpret(instruction:instruction,update:true,psr:psr,registers:registers)
        return(self.rc,self.pc,self.text)
    }
    func interpret(instruction:UInt16,update:Bool,psr:UInt32,registers:[Int32]) {
        var instructionFormat = 0
        let formats:[[UInt16]] = [
            [21,0xff00,0xb200],
            [20,0xff00,0xba00],
            [19,0xf000,0xf000],
            [18,0xf800,0xe000],
            [17,0xff00,0xdf00],
            [16,0xf000,0xd000],
            [15,0xf000,0xc000],
            [14,0xf600,0xb400],
            [13,0xff00,0xb000],
            [12,0xf000,0xa000],
            [11,0xf000,0x9000],
            [10,0xf000,0x8000],
            [09,0xe000,0x6000],
            [08,0xf200,0x5200],
            [07,0xf200,0x5000],
            [06,0xf800,0x4800],
            [05,0xfc00,0x4400],
            [04,0xfc00,0x4000],
            [03,0xe000,0x2000],
            [02,0xf800,0x1800],
            [01,0xe000,0x0000]
        ]
        for format in formats {
            if (instruction & format[1] ) == format[2] {
                instructionFormat = Int(format[0])
                break
            }
        }
        switch instructionFormat {
        case 1 :
            format1(instruction: instruction)
        case 2 :
            format2(instruction:instruction)
        case 3 :
            format3(instruction:instruction)
        case 4 :
            format4(instruction:instruction)
        case 5 :
            format5(instruction:instruction,update:update,registers:registers)
        case 6 :
            format6(instruction:instruction)
        case 7 :
            format7(instruction:instruction)
        case 8 :
            format8(instruction:instruction)
        case 9 :
            format9(instruction:instruction)
        case 10 :
            format10(instruction:instruction)
        case 11 :
            format11(instruction:instruction)
        case 12 :
            format12(instruction:instruction)
        case 13 :
            format13(instruction:instruction)
        case 14 :
            format14(instruction:instruction)
        case 15 :
            format15(instruction:instruction)
        case 16 :
            format16(instruction:instruction,update:update,psr:psr)
        case 17 :
            format17(instruction:instruction)
        case 18 :
            format18(instruction:instruction,update:update)
        case 19 :
            format19(instruction:instruction,update:update)
        case 20 :
            format20(instruction:instruction)
        case 21 :
            format21(instruction:instruction)
        default :
            self.text = "Invalid format"
        }
    }
    func format1(instruction:UInt16) {
        let opTable = [0:"LSL",1:"LSR",2:"ASR"]
        let op = Int((instruction & 0x1800) >> 11)
        let rs = (instruction & 0x0038) >> 3
        let rd = (instruction & 0x0007) >> 0
        let offset5 = (instruction & 0x07C0) >> 6
        self.text = "\(opTable[op] ?? "unkown") r\(rd),r\(rs),#\(offset5)"
    }
    func format2(instruction:UInt16) {
        let opTable = [0:"ADD",1:"SUB"]
        let op = Int(instruction & 0x0200) >> 9
        let rs = (instruction & 0x0038) >> 3
        let rd = (instruction & 0x0007) >> 0
        let offset3 = (instruction & 0x01C0) >> 6
        let immediate = (instruction & 0x0400) >> 10
        if immediate == 1 {
           self.text = "\(opTable[op] ?? "unkown") r\(rd),r\(rs),#\(offset3)"
        } else {
           self.text = "\(opTable[op] ?? "unkown") r\(rd),r\(rs),r\(offset3)"
        }
    }
    func format3(instruction:UInt16) {
        let opTable = [0:"MOV",1:"CMP",2:"ADD",3:"SUB"]
        let op = Int(instruction & 0x1800) >> 11
        let rd = (instruction & 0x0700) >> 8
        let offset8 = (instruction & 0x00FF) >> 0
        self.text = "\(opTable[op] ?? "unkown") r\(rd),#\(offset8)"
    }
    func format4(instruction:UInt16) {
        let opTable = [0:"AND",1:"EOR",2:"LSL",3:"LSR",4:"ASR",5:"ADC",6:"SBC",7:"ROR",8:"TST",9:"NEG",10:"CMP",11:"CMN",12:"ORR",13:"MUL",14:"BIC",15:"MVN"]
        let op = Int(instruction & 0x03C0) >> 6
        let rd = (instruction & 0x0007) >> 0
        let rs = (instruction & 0x0038) >> 3
        self.text = "\(opTable[op] ?? "unkown") r\(rd),r\(rs)"
    }
    func format5(instruction:UInt16,update:Bool,registers:[Int32]) {
        let opTable = [0:"ADD",1:"CMP",2:"MOV",3:"BX"]
        let op = Int(instruction & 0x0300) >> 8
        var rd = (instruction & 0x0007) >> 0
        var rs = (instruction & 0x0038) >> 3
        let h1 = (instruction & 0x0080) >> 7
        let h2 = (instruction & 0x0040) >> 6
        if h2 == 1 && h1 == 0 {
            rs += 8
        }
        if h2 == 0 && h1 == 1 {
            rd += 8
        }
        if h2 == 1 && h1 == 1 {
            rs += 8
            rd += 8
        }
        if op == 3 {
            self.text = "\(opTable[op] ?? "unknown") r\(rs)"
            if update {
                rc = 2
                if rs == 14 {
                    pc = lr
                } else if rs < 8 {
                    pc = Int(registers[Int(rs)])
                }
            }
        } else {
            self.text = "\(opTable[op] ?? "unknown") r\(rd),r\(rs)"
        }
    }
    func format6(instruction:UInt16) {
        let rd = (instruction & 0x0700) >> 8
        let word8 = (instruction & 0x00ff) >> 0
        self.text = "LDR r\(rd),[pc, #\(word8 * 4)]"
    }
    func format7(instruction:UInt16) {
        let opTable = [0:"STR",1:"STRB",2:"LDR",3:"LDRB"]
        let op = Int(instruction & 0x0C00) >> 10
        let rd = (instruction & 0x0007) >> 0
        let rb = (instruction & 0x0038) >> 3
        let ro = (instruction & 0x01C0) >> 6
        self.text = "\(opTable[op] ?? "unkown") r\(rd),[r\(rb),r\(ro)]"
    }
    func format8(instruction:UInt16) {
        let opTable = [0:"STRH",1:"LDSB",2:"LDRH",3:"LDSH"]
        let op = Int(instruction & 0x0C00) >> 10
        let rd = (instruction & 0x0007) >> 0
        let rb = (instruction & 0x0038) >> 3
        let ro = (instruction & 0x01C0) >> 6
        self.text = "\(opTable[op] ?? "unkown") r\(rd),[r\(rb),r\(ro)]"
    }
    func format9(instruction:UInt16) {
        let opTable = [0:"STR",1:"LDR",2:"STRB",3:"LDRB"]
        let op = Int(instruction & 0x1800) >> 11
        let rd = (instruction & 0x0007) >> 0
        let rb = (instruction & 0x0038) >> 3
        let offset5 = (instruction & 0x07C0) >> 6
        if op > 1 {
            self.text = "\(opTable[op] ?? "unkown") r\(rd),[r\(rb),#\(offset5)]"
        } else {
            self.text = "\(opTable[op] ?? "unkown") r\(rd),[r\(rb),#\(offset5 * 4)]"
        }
    }
    func format10(instruction:UInt16) {
        let opTable = [0:"STRH",1:"LDRH"]
        let op = Int(instruction & 0x0800) >> 11
        let rd = (instruction & 0x0007) >> 0
        let rb = (instruction & 0x0038) >> 3
        let offset5 = (instruction & 0x07C0) >> 6
        self.text = "\(opTable[op] ?? "unkown") r\(rd),[r\(rb),#\(offset5 * 2)]"
    }
    func format11(instruction:UInt16) {
        let opTable = [0:"STR",1:"LDR"]
        let op = Int(instruction & 0x0800) >> 11
        let rd = (instruction & 0x0700) >> 8
        let word8 = (instruction & 0x00ff) >> 0
        self.text = "\(opTable[op] ?? "unkown") r\(rd),[sp,#\(word8 * 4)]"
    }
    func format12(instruction:UInt16) {
        let rd = (instruction & 0x0700) >> 8
        let sp = Int(instruction & 0x0800) >> 11
        let word8 = (instruction & 0x00ff) >> 0
        if sp == 0 {
            self.text = "ADD r\(rd),[pc,#\(word8 * 4)]"
        } else {
            self.text = "ADD r\(rd),[sp,#\(word8 * 4)]"
        }
    }
    func format13(instruction:UInt16) {
        let sign = (instruction & 0x0080) >> 7
        let sWord7 = Int(instruction & 0x007F)
        if sign == 0 {
            self.text = "ADD SP, #\(sWord7 * 4)"
        } else {
            self.text = "ADD SP, #\(sWord7 * -4)"
        }
    }
    func format14(instruction:UInt16) {
        let opTable = [0:"PUSH",1:"POP"]
        let op = Int(instruction & 0x0800) >> 11
        let pc_lr = (instruction & 0x0100) >> 8
        var rlist = " "
        for r in 0 ... 7 {
            let mask = UInt16( 0x01 << r)
            if (instruction & mask) >> r == 1 {
                rlist = rlist + " r" + String(r)
            }
        }
        if op == 0 && pc_lr == 1 {
             rlist = rlist + " lr"
        } else if op == 1 && pc_lr == 1  {
            rlist = rlist + " pc"
        }
        self.text = "\(opTable[op] ?? "unkown") {" + rlist + "}"
    }
    func format15(instruction:UInt16) {
        let opTable = [0:"STMIA",1:"LDMIA"]
        let op = Int(instruction & 0x0800) >> 11
        let rb = (instruction & 0x0700) >> 8
        var rlist = " "
        for r in 0 ... 7 {
            let mask = UInt16( 0x01 << r)
            if (instruction & mask) >> r == 1 {
                rlist = rlist + " r" + String(r)
            }
        }
        self.text = "\(opTable[op] ?? "unkown") r\(rb)!,{" + rlist + "}"
    }
    func format16(instruction:UInt16,update:Bool,psr:UInt32) {
        let ccTable = [0:"BEQ",1:"BNE",2:"BCS",3:"BCC",4:"BMI",5:"BPL",6:"BVS",7:"BVC",8:"BHI",9:"BLS",10:"BGE",11:"BLT",12:"BGT",13:"BLE"]
        let cc = Int(instruction & 0x0f00) >> 8
        let offset = UInt8(instruction & 0x00ff)
        let signedOffset = Int8(bitPattern: offset)
        self.text = "\(ccTable[cc] ?? "unkown") \(signedOffset)"
        if update {
            rc = 1
            let psrV = (psr & 0x10000000 != 0)  // V
            let psrC = (psr & 0x20000000 != 0)  // C
            let psrZ = (psr & 0x40000000 != 0)  // Z
            let psrN = (psr & 0x80000000 != 0)  // N
            self.text = "No Branch"
            switch cc {
            case 0 :
                if psrZ {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 1 :
                if !psrZ {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 2 :
                if psrC {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 3 :
                if !psrC {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 4 :
                if psrN {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 5 :
                if !psrN {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 6 :
                if psrV {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 7 :
                if !psrV {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 8 :
                if (psrC && !psrZ) {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 9 :
                if (!psrC || psrZ) {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 10 :
                if (psrN && psrV) || (!psrN && !psrV) {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 11 :
                if (psrN && !psrV) || (!psrN && psrV) {
                    pc = (pc + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 12 :
                if (!psrZ && ((psrN && psrV) || (!psrN && !psrV))) {
                    pc = (pc  + 1) + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
            case 13 :
                if (psrZ || (psrN && !psrV) || (!psrN && psrV)) {
                    pc = (pc + 1)  + Int(signedOffset)
                    self.text = "Branch (\(signedOffset))"
                    rc = 2
                }
                break
                default :
                self.text = "Invalid Conditional branch"
            }
        }
    }
    func format17(instruction:UInt16) {
        let value8 = Int(instruction & 0x00FF) >> 0
        self.text = "SVC \(value8)"
    }
    func format18(instruction:UInt16,update:Bool) {
        var offset11 = (instruction & 0x07FF) >> 0
        let sign = Int((instruction & 0x0400) >> 10)
        if sign == 1 {
            offset11 = offset11 | 0xF800
        }
        let signedOffset = Int16(bitPattern: offset11)
        self.text = "B \(signedOffset * 2)"
        if update {
            rc = 2
            pc = (pc + 1) + Int(signedOffset)
            self.text = "Branch (\(signedOffset))"
        }
    }
    func format19(instruction:UInt16,update:Bool) {
        if update {
            rc = 1
        }
        let type = (instruction & 0x0800) >> 11
        let offset11 = UInt32(instruction & 0x07FF)
        if type == 1 {
            target = target | offset11
            let sign = offset11 >> 10
            if sign == 1 {
                target = target | 0x0000f800
            }
        } else {
            target = 0
            target = offset11 << 12
        }
        let sign = target >> 22
        if sign == 1 {
            target = target | 0xFF800000
        }
        //print(String(format:"%08X",target))
        let signedOffset = Int32(bitPattern: target)
        self.text = "BL (\(type)) \(signedOffset)"
        if update && type == 1 {
            rc = 2
            lr = pc
            pc = (pc + 0) + Int(signedOffset)
            self.text = "Branch (\(signedOffset))"
        }
    }
    func format20(instruction:UInt16) {
        let opTable = [0:"REV",1:"REV16",3:"REVSH"]
        let op = Int((instruction & 0x00C0) >> 6)
        let rs = (instruction & 0x0038) >> 3
        let rd = (instruction & 0x0007) >> 0
        self.text = "\(opTable[op] ?? "unkown") r\(rd),r\(rs)"
    }
    func format21(instruction:UInt16) {
        let opTable = [0:"SXTH",1:"SXTB",2:"UXTH",3:"UXTB"]
        let op = Int((instruction & 0x00C0) >> 6)
        let rs = (instruction & 0x0038) >> 3
        let rd = (instruction & 0x0007) >> 0
        self.text = "\(opTable[op] ?? "unkown") r\(rd),r\(rs)"
    }
}
