 /*
  execute.s
  Created by Peter Wallen
  Version 1.0
  Copyright c 2018 Peter Wallen
 
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
 
  Execute one or more arm machine instructions (thumb) and save
  general registers r0 - r7.
 
  on entry:
        r0 points to a 4 byte aligned area of storage which must be large enough to contain 10 32 bit words.
        r1 points to a 4 byte aligned area of storage which must be large enough to contain at least 20 bytes of storage to hold 9 2 byte thumb instructions (the last 2 bytes are used by the calling routine).
            N.B. Incraseing the length of this storage for example  to 256 bytes allows trailing storage to be used as a storage area for use by executed instructions.
 
 */
.global execute
.thumb

execute:
// ****  PREFIX CODE  ****
    push {r2,r3,r4,r5,r6,r7,lr} // save resgisters
    mov  r8,r0  // on entry register 0 points to a save area
                //          register 1 points to an instruction buffer
//    add  r1,#2   // bump register to skip command prefix (2 bytes)
    add  r1,#1  // set low bit on to indicate thumb routine
    mov r10,r1  // use register 10 to temporarily save branch addreess
    mov r11,sp  // save calling programs stack pointer in register 11
    ldr r3,[r0,#36] //load stack pointer from save area
    mov sp,r3
    ldr  r1,=return // load link register with suffix code
    add r1,#1
 // mov lr,r1
    mov r12,r1 // Use r12 for return address BX R12 0x4760
// setup general register from save area
    ldr r1,[r0] //first restore register 0
    mov r9,r1   //temporarily save in register 9
    add r0,#4   // advance save area pointer
    ldmia r0!,{r1,r2,r3,r4,r5,r6,r7} // restore registers 1 - 7
    mov r0,r9   // now restore register 0
    mov pc,r10  // branch to instructions in instruction buffer
.ascii "AAAAAAAA"
return:
// **** SUFFIX CODE
    mov r9,r0   // temporaily save contents of register 0
    mov r0,r8   // set register 0 to point to save area
    stmia r0!,{r0,r1,r2,r3,r4,r5,r6,r7}  // store register 0 - 7 in save area
                                         // N.B. register 0 points to save area
    mov r2,r8      // now use register 2 to point to save area
    mov r0,r9      // restore register 0 from tempoary backup
    str r0,[r2]    // store user contents of register 0
    mrs   r0,psr   // load the program status register
    str r0,[r2,#32]  // store in save area
    mov r3,sp        // store stack pointer in save area
    str r3,[r2,#36]
    mov sp,r11       // restore calling program stack pointer
    pop {r2,r3,r4,r5,r6,r7,pc}  // restore registers and set lr to pc
.end
