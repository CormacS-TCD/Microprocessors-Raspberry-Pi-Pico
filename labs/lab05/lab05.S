#include "hardware/regs/addressmap.h"
#include "hardware/regs/m0plus.h"

.syntax unified                 @ Specify unified assembly syntax
.cpu    cortex-m0plus           @ Specify CPU type is Cortex M0+
.thumb                          @ Specify thumb assembly for RP2040
.global main_asm                @ Provide program starting address to the linker
.align 4                        @ Specify code alignment

.equ    SLEEP_TIME, 500         @ Specify the sleep time (in ms)
.equ    LED_GPIO_PIN, 25        @ Specify the pin that the LED is connected to
.equ    LED_GPIO_OUT, 1         @ Specify the direction of the GPIO pin
.equ    LED_VALUE_ON, 1         @ Specify the value that turns the LED "on"
.equ    LED_VALUE_OFF, 0        @ Specify the value that turns the LED "off"
.equ    SVC_ISR_OFFSET, 0x2C    @ The SVC is entry 11 in the vector table
.equ    SVC_MAX_INSTRS, 0x01    @ Maximum allowed SVC subroutines

@ Entry point to the ASM portion of the program
main_asm:
    bl      init_gpio_led       @ Initialise the GPIO LED pin
    bl      install_svc_isr     @ Install the SVC interrupt service routine
loop:
    svc     #0                  @ Call the SVC ISR with value 0 (turns on LED)
    nop                         @ Add a no-op instruction for alignment after SVC
    bl      do_sleep            @ Short pause before proceeding
    svc     #1                  @ Call the SVC ISR with value 1 (turns off LED)
    nop                         @ Add a no-op instruction for alignment after SVC
    bl      do_sleep            @ Add a short pause before proceeding
    b       loop                @ Always jump back to the start of the loop

@ Subroutine used to introduce a short delay in the application
do_sleep:
    push    {lr}
    ldr     r0, =SLEEP_TIME             @ Set the value of SLEEP_TIME we want to wait for
    bl      sleep_ms                    @ Sleep until SLEEP_TIME has elapsed
    pop     {pc}
@ Subroutine used to initialise the PI Pico built-in LED
init_gpio_led:
    push    {lr}
    movs    r0, #LED_GPIO_PIN           @ This value is the GPIO LED pin on the PI PICO board
    bl      asm_gpio_init               @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #LED_GPIO_PIN           @ This value is the GPIO LED pin on the PI PICO board
    movs    r1, #LED_GPIO_OUT           @ We want this GPIO pin to be setup as an output pin
    bl      asm_gpio_set_dir            @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    pop     {pc}

@ Subroutine used to install the SVC interrupt service handler
install_svc_isr:
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)    @ Load the sum of the base address for the pi's VTOR and the offset for the vector table into r2
    ldr     r1, [r2]                                @ Load the address for the previous sum into r1
    movs    r2, #SVC_ISR_OFFSET                     @ Move the SVC vector table offset into r2
    add     r2, r1                                  @ Add add the svc offset to the original address in r1 and store in r2
    ldr     r0, =svc_isr                            @ Load the svc_isr subroutine address into r0
    str     r0, [r2]                                @ Store the subroutine address in r0 in the address of r2
    bx      lr                                      @ Branch back to where this subroutine was entered

@ SVC interrupt service handler routine
.thumb_func                     @ Required for all interrupt service routines
svc_isr:
    push    {lr}                @ Push the link register to the top of the stack
    ldr     r0, [sp, #0x1C]     @ Load the address of the stack pointer, offset by 28, into r0
    subs    r0, #0x2            @ Decrement r0 by 2 and set the flags
    ldr     r0, [r0]            @ Load the address of the value in r0 into r0
    ldr     r1, =#0xFF          @ Load 255 into r1
    ands    r0, r1              @ AND 255 with the address in r0 and set the flags
    cmp     r0, #SVC_MAX_INSTRS @ Compare register r0 with the constant for the maximum allowed SVC subroutines
    bgt     svc_done            @ If r0 is greater than the max allowed SVC subroutines, branch to svc_done
    adr     r1, svc_jmptbl      @ Store the address of svc_jmptbl in r1
    lsls    r0, #2              @ Multiply the value at r0 by 4
    ldr     r1, [r1, r0]        @ Increment the value of r1 by r0 not permanently, and load the address at r1 into r1
    mov     pc, r1              @ Move the value at r1 into the program counter
svc_done:
    pop     {pc}                @ Pop the link register from the stack to the program counter

@ First function of SVC subroutine - turn on the LED
svc_num0:
    movs    r1, #LED_VALUE_ON           @ Move the LED ON value into r1
    movs    r0, #LED_GPIO_PIN           @ Set the LED GPIO pin number to r0 for use by asm_gpio_put
    bl      asm_gpio_put                @ Update the the value of the LED GPIO pin (based on value in r1)
    b       svc_done                    @ Branch back to the main ISR when done

@ Second function of SVC subroutine - turn off the LED
svc_num1:
    movs    r1, #LED_VALUE_OFF          @ Move the LED OFF value into r1 
    movs    r0, #LED_GPIO_PIN           @ Set the LED GPIO pin number to r0 for use by asm_gpio_put
    bl      asm_gpio_put                @ Update the the value of the LED GPIO pin (based on value in r1)
    b       svc_done                    @ Branch back to the main ISR when done

@ SVC function entry jump table.
.align 2
svc_jmptbl:
    .word svc_num0              @ Entry zero goes to SVC function #0.
    .word svc_num1              @ Entry one goes to SVC function #1.
    .word 0                     @ Null termination of the jump table.

@ Set data alignment
.data
    .align 4
