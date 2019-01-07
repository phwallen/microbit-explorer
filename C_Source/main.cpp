  /*
 main.cpp
 
 Created by Peter Wallen on 05/07/2018
 Version 1.0
 
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
 
 This program runs on the Micro:bit. It is used in conjunction with the Micro:bit Explorer Swift
 Playground running on an iPad.
 
 The program communicates with the iPad over Bluetooth LE.
 
 The program receives one or more Thumb instructions and executes them on the Micro:bit and sets the leds based on the contents of the general registers and the program status register. The program then returns information, over bluetooth, regarding contents of registers and memory.
*/

#include "MicroBit.h"
#include "MicroBitUARTService.h"

#define STACK_SIZE 256
#define MEMORY_SIZE 256

extern void execute(int *storage,unsigned char *instructions) __asm__("execute");

MicroBit uBit;
MicroBitUARTService *uart;

int connected = 0;
int counter = 0;

// Input buffer
// The first 20 bytes - input from Swift Playground (byte 20 is the command byte)
// The remainder used as a scratch pad
unsigned char instructions[MEMORY_SIZE] __attribute__((aligned(4))) = {};
// Memory buffer where general register contents are stored following the execution of one or more machine
// instructions.
// 0 - 7   General Registers 0 - 7
// 8 PSR
// 9 Stack Pointer
// 10 - 11 reserved
int storage[12] __attribute__((aligned(4))) = {} ;
// stack
int stack[STACK_SIZE] __attribute__((aligned(4))) = {};
// Buffers used for returning data
int send_buffer[5] = {};
unsigned char memory_buffer[20] = {};


void display(int command) {
    MicroBitImage image(5,5);
    if (command == 1) {
        image.setPixelValue(0,4,255);
        uBit.display.print(image);
        return;
    }
    if (storage[7] > 31) {
        char ascii = storage[7] & 0x000000FF;
        uBit.display.print(ascii);
        return;
    }
   
    int mask[6] = {0x00,0x01,0x02,0x04,0x08,0x10};
    for (int x = 0; x <= 3; x++ ) {
        int reg = storage[x];
        for (int i = 1; i <= 5; i++) {
            if (reg & mask[i] ) {
                image.setPixelValue(5 - i,x,255);
            } else {
                image.setPixelValue(5 - i,x,0);
            }
        }
    }
    int psr = storage[8];
    unsigned int psrMask[5] = {0x00000000,0x10000000,0x20000000,0x40000000,0x80000000};
    for (int z = 1; z <= 4; z++) {
        if (psr & psrMask[z] ) {
            image.setPixelValue(5 - z,4,255);
        } else {
            image.setPixelValue(5 - z,4,0);
        }
    }
    uBit.display.print(image);
}

void send() {
    for (int record = 1;record <= 3;record++) {
        send_buffer[0] = record;
        for (int i = 0;i < 4; i++) {
            send_buffer[i + 1] = storage[(record - 1) * 4  + i];
        }
        uart->send(reinterpret_cast<const uint8_t*>(send_buffer),sizeof(send_buffer));
    }
    memory_buffer[0] = 4;
    for (int i = 0;i < 16;i++) {
        memory_buffer[i+4] = instructions[i+20];
    }
    uart->send(memory_buffer,sizeof(memory_buffer));
}

void sync() {
    send();
    display(0);
}

void run() {
    execute(storage,instructions);
    send();
    display(0);
}
void clear() {
    for (int i = 0; i < 10; i++) {
        storage[i] = 0;
    }
    for (unsigned int i = 0; i < sizeof(instructions); i++) {
        instructions[i] = 0;
    }
    storage[9] = int(&stack[STACK_SIZE - 1]);
    send();
    display(0);
}
void store(int command) {
    int location = (command - 4) * 4;
    for (int i = 0; i < 4; i++) {
        instructions[location + 20 + i] = instructions[i];
    }
    send();
}

void resetInstructionBuffer() {
    unsigned char instruction_reset[18] = {0x60,0x47,0x60,0x47,0x60,0x47,0x60,0x47,0x60,0x47,0x60,0x47,0x60,0x47,0x60,0x47,0x60,0x47};
    for (int i = 0; i < 18; i++) {
        instructions[i] = instruction_reset[i];
    }
}

void onConnected(MicroBitEvent)
{

    //uBit.display.print("C");
    //display(1);
    connected = 1;
    
    while(connected == 1) {

        uart->read(instructions,20);
        int command = instructions[19];
        switch(command) {
            case 0 :
                run();
                break;
            case 1 :
                connected = 0;
                break;
            case 2 :
                uBit.reset();
                break;
            case 3 :
                clear();
                break;
            case 4 ... 7 :
                store(command);
                break;
            case 8 :
                sync();
                break;
            default :
                uBit.display.print("Z");
        }
    }
}

void onDisconnected(MicroBitEvent)
{
    uBit.display.print("D");
    //display(1);
    connected = 0;
}

void onButton(MicroBitEvent e)
{
    if (e.source == MICROBIT_ID_BUTTON_A) {
        resetInstructionBuffer();
    }
    if (e.source == MICROBIT_ID_BUTTON_B) {
        MicroBitImage image(5,5);
        image.setPixelValue(0,4,255);
        uBit.display.print(image);
    }
}

int main()
{
    // Initialise the micro:bit runtime.
    uBit.init();

    uBit.messageBus.listen(MICROBIT_ID_BLE, MICROBIT_BLE_EVT_CONNECTED, onConnected);
    uBit.messageBus.listen(MICROBIT_ID_BLE, MICROBIT_BLE_EVT_DISCONNECTED, onDisconnected);
    
    uBit.messageBus.listen(MICROBIT_ID_BUTTON_A, MICROBIT_EVT_ANY, onButton,MESSAGE_BUS_LISTENER_IMMEDIATE);
    
    uBit.messageBus.listen(MICROBIT_ID_BUTTON_B, MICROBIT_EVT_ANY, onButton,MESSAGE_BUS_LISTENER_IMMEDIATE);
   
    uart = new MicroBitUARTService(*uBit.ble, 32, 32);
    uBit.display.print("R");
    
    storage[9] = int(&stack[STACK_SIZE - 1]);
    
    // If main exits, there may still be other fibers running or registered event handlers etc.
    // Simply release this fiber, which will mean we enter the scheduler. Worse case, we then
    // sit in the idle task forever, in a power efficient sleep.
    release_fiber();
}
