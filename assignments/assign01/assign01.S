#include "hardware/regs/addressmap.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.syntax unified
.cpu    cortex-m0plus
.thumb
.global main_asm
.align  4

.equ    DFLT_STATE_STRT, 1            @ Specify the value to start flashing
.equ    DFLT_STATE_STOP, 0            @ Specify the value to stop flashing
.equ    DFLT_ALARM_TIME, 1000000      @ Specify the default alarm timeout

.equ    GPIO_BTN_DN_MSK, 0x00040000   @ Bit-18 for falling-edge event on GP20
.equ    GPIO_BTN_EN_MSK, 0x00400000   @ Bit-22 for falling-edge event on GP21
.equ    GPIO_BTN_UP_MSK, 0x04000000   @ Bit-26 for falling-edge event on GP22

.equ    GPIO_BTN_DN,  20              @ Specify pin for the "down" button
.equ    GPIO_BTN_EN,  21              @ Specify pin for the "enter" button
.equ    GPIO_BTN_UP,  22              @ Specify pin for the "up" button
.equ    GPIO_LED_PIN, 25              @ Specify pin for the built-in LED
.equ    GPIO_DIR_IN,   0              @ Specify input direction for a GPIO pin
.equ    GPIO_DIR_OUT,  1              @ Specify output direction for a GPIO pin

.equ    LED_VAL_ON,    1              @ Specify value that turns the LED "on"
.equ    LED_VAL_OFF,   0              @ Specify value that turns the LED "off"

.equ    GPIO_ISR_OFFSET, 0x74         @ GPIO is int #13 (vector table entry 29)
.equ    ALRM_ISR_OFFSET, 0x40         @ ALARM0 is int #0 (vector table entry 16)

@ Entry point to the main_asm code
main_asm:
        movs    r0, #GPIO_LED_PIN     @ Store the LED pin value and initialise the LED
        bl      asm_gpio_init         
        movs    r0, #GPIO_LED_PIN     @ Store the LED pin again and the direction (output) and set the direction         
        movs    r1, #GPIO_DIR_OUT
        bl      asm_gpio_set_dir

        movs    r0, #GPIO_BTN_DN      @ Store the DN button pin value and initialise the button
        bl      asm_gpio_init
        movs    r0, #GPIO_BTN_DN      @ Store the DN button pin again and the direction (input) and set the direction
        movs    r1, #GPIO_DIR_IN
        bl      asm_gpio_set_dir

        movs    r0, #GPIO_BTN_EN      @ Store the EN button pin value and initialise the button
        bl      asm_gpio_init
        movs    r0, #GPIO_BTN_EN      @ Store the EN button pin again and the direction (input) and set the direction
        movs    r1, #GPIO_DIR_IN
        bl      asm_gpio_set_dir

        movs    r0, #GPIO_BTN_UP      @ Store the UP button pin value and initialise the button
        bl      asm_gpio_init
        movs    r0, #GPIO_BTN_UP      @ Store the UP button pin again and the direction (input) and set the direction
        movs    r1, #GPIO_DIR_IN
        bl      asm_gpio_set_dir


        movs    r0, #GPIO_BTN_DN      @ Set DN to be gpio interrupt enabled
        bl      asm_gpio_set_irq
        movs    r0, #GPIO_BTN_EN      @ Set EN to be gpio interrupt enabled
        bl      asm_gpio_set_irq
        movs    r0, #GPIO_BTN_UP      @ Set UP to be gpio interrupt enabled
        bl      asm_gpio_set_irq

        ldr     r0, =time             @ Initialise the time variable, controlling the flashing, with the default alarm time
        ldr     r1, =DFLT_ALARM_TIME
        str     r1, [r0]

        bl      install_alarm_isr     @ Branch to the install_alarm_isr subroutine
        bl      reset_alarm           @ Branch to the reset_alarm subroutine
        bl      install_gpio_isr      @ Branch to the install_gpio_isr subroutine




main_loop:
        wfi
        b       main_loop


@ Subroutine to establish the ALARM0 interrupt
install_alarm_isr:
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)            @ Get the offset of the vector table and store it in r2
        ldr     r1, [r2]                                        @ Load the offset into r1
        movs    r2, #ALRM_ISR_OFFSET                            @ Load the Timer0 offset into r2
        add     r2, r1                                          @ Add the offsets together, store in r2
        ldr     r0, =toggle_led                                 @ Get the address of the toggle_led subroutine and store it in r0
        str     r0, [r2]                                        @ Store the address of toggle_led at the Timer0 isr address, where the ALARM0 interrupt will look for a subroutine when it is called

        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Load ICPR register
        movs    r0, #0x1
        str     r0, [r2]                                        @ Set the 0 bit position to 1 to disable the Timer0 interrupt

        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @ Load the ISER register
        movs    r0, #0x1
        str     r0, [r2]                                        @ Set the 0 bit position to 1 to enable the Timer0 interrupt

        bx      lr

@ Subroutine to reset the ALARM0 interrupt after it is called
reset_alarm:
        ldr     r1, =time                                       @ Load in the current time value for flashing the LED
        ldr     r0, [r1]                                        
        ldr     r2, =(TIMER_BASE)                               @ Load in the base address for the timer
        movs    r1, #0x1
        str     r1, [r2, #TIMER_INTE_OFFSET]                    
        ldr     r1, [r2, #TIMER_TIMELR_OFFSET]                  @ Load in the current timer value
        add     r1, r0                                          @ Increment the timer value by the time variable
        str     r1, [r2, #TIMER_ALARM0_OFFSET]                  @ Store this future timer value in the offset address

        bx      lr

@ Subroutine to establish the GPIO interrupt
install_gpio_isr:
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)            @ Get the offset of the vector table and store it in r2
        ldr     r1, [r2]                                        @ Load the offset into r1
        movs    r2, #GPIO_ISR_OFFSET                            @ Load the GPIO offset into r2
        add     r2, r1                                          @ Add the offsets together, store in r2
        ldr     r0, =gpio_isr                                   @ Get the address of the gpio_isr subroutine and store it in r0
        str     r0, [r2]                                        @ Store the address of gpio_isr at the GPIO isr address, where the GPIO interrupt will look for a subroutine when it is called

        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Write to bit 13 in ICPR to clear any gpio interrupts
        ldr     r0, =0x2001                                     @ 0x2001 = 2^13+1
        str     r0, [r2]                                        @ Store 0x2001 in the 13 bit position to disable the interrupt

        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @ Write to bit 13 in ISER to enable gpio interrupt
        ldr     r0, =0x2001                                     @ 0x2001 = 2^13+1
        str     r0, [r2]                                        @ Store 0x2001 in the 13 bit position to enable the interrupt

        bx      lr

@ Subroutine to toggle the LED on or off through the ALARM0 interrupt
.thumb_func
toggle_led:
        push    {lr}                                            @ Push the link register to the stack

        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Write to bit 13 in ICPR to clear any gpio interrupts
        ldr     r0, =0x2001                                     @ 0x2001 = 2^13+1
        str     r0, [r2]                                        @ Store 0x2001 in the 13 bit position to disable the interrupt
        
        ldr     r2, =(TIMER_BASE)
        movs    r1, #0x1
        str     r1, [r2, #TIMER_INTR_OFFSET]

        ldr     r0, =lstate                                     @ Get the lstate variable into r0, which stores the LED state (flashing or not-flashing)
        ldr     r1, [r0]                                        @ Load the variable into r1
        cmp     r1, #0x0                                        @ Compare the lstate value with 0, which checks if the LED is not-flashing
        beq     end_alarm_isr                                   @ If they are equal, the LED is not-flashing and branch to subroutine end_alarm_isr, continue else

        movs    r0, #GPIO_LED_PIN                               @ Set the LED GPIO pin number to r0 for use by asm_gpio_get
        bl      asm_gpio_get                                    @ Get current the value of the LED GPIO pin (returns to r0)
        cmp     r0, #LED_VAL_OFF                                @ Check if the LED GPIO pin value is "off"
        beq     led_set_on                                      @ If it is "off" then jump code to to turn it on
led_set_off:
        movs    r1, #LED_VAL_OFF                                @ The LED is currently "on" so we want to turn it "off"
        b       led_set_state                                   @ Jump to portion of code where we set the state of the LED
led_set_on:
        movs    r1, #LED_VAL_ON                                 @ The LED is currently "off" so we want to turn it "on"
led_set_state:
        movs    r0, #GPIO_LED_PIN                               @ Set the LED GPIO pin number to r0 for use by asm_gpio_put
        bl      asm_gpio_put                                    @ Update the value of the LED GPIO pin (based on value in r1)
        
end_alarm_isr:
        bl      reset_alarm                                     @ Branch to the reset_alarm subroutine to reset the ALARM0 interrupt
        pop     {pc}                                            @ Pop the link register from the stack to the program counter

@ Subroutine to check the button that triggered the GPIO interrupt, and branch to take appropriate action
.thumb_func
gpio_isr:
        push    {lr}                                            @ Push the link register to the stack

        @ Check the status mask for which button triggered the interrupt and branch accordingly
        ldr     r2, =(IO_BANK0_BASE+IO_BANK0_PROC0_INTS2_OFFSET)
        ldr     r1, [r2]                                        @Get the Status register
        ldr     r0, =GPIO_BTN_DN_MSK
        ands    r1,r0,r1
        cmp     r0, r1
        beq     button_20                                       @If it matches the DN mask, then button 20 was pressed

        ldr     r1, [r2]                                        @Get the Status register
        ldr     r0, =GPIO_BTN_EN_MSK
        ands    r1,r0,r1
        cmp     r0, r1                        
        beq     button_21                                       @If it matches the EN mask, then button 21 was pressed

        ldr     r1, [r2]                                        @Get the Status register
        ldr     r0, =GPIO_BTN_UP_MSK
        ands    r1,r0,r1
        cmp     r0,r1
        beq     button_22                                       @If it matches the UP mask, then button 22 was pressed

@ Subroutine for when button 20 is pressed
button_20:
        @ Check the lstate variable, if it is not-flashing, branch to the button20_22 subroutine
        ldr     r0, =lstate
        ldr     r1, [r0]
        cmp     r1, #0x0
        beq     button20_22

        @ Else, load up the time variable and half it, halving the flashing rate
        ldr     r0, =time
        ldr     r1, [r0]
        movs    r2, #0x1
        lsrs    r1, r1, r2
        str     r1, [r0]

        b       end_isr

@ Subroutine for when button 21 is pressed
button_21:
        @ Check the lstate variable, if it is flashing, branch to the subroutine toggle_off_lstate
        ldr     r0, =lstate
        ldr     r1, [r0]
        cmp     r1, #0x1
        beq     toggle_off_lstate

        @ Else, flip the lstate variable and set it to flashing
        movs    r1, #0x1
        str     r1, [r0]

        b       end_isr
toggle_off_lstate:
        @ Flip the lstate variable and set it to not-flashing
        movs    r1, #0x0
        str     r1, [r0]

        @ Turn off the LED
        movs    r0, #GPIO_LED_PIN       
        bl      asm_gpio_put

        b       end_isr

@ Subroutine for when button 22 is pressed
button_22:
        @ Check the lstate variable, if it is not-flashing, branch to the button20_22 subroutine
        ldr     r0, =lstate
        ldr     r1, [r0]
        cmp     r1, #0x0
        beq     button20_22

        @ Else, load up the time variable and double it, doubling the flashing rate
        ldr     r0, =time
        ldr     r1, [r0]
        movs    r2, #0x1
        lsls    r1, r1, r2
        str     r1, [r0]

        b       end_isr
@ Subroutine for when button 22 or button 20 is pressed
button20_22:
        @ Check the lstate variable, if it is flashing, skip over it
        ldr     r0, =lstate
        ldr     r1, [r0]
        cmp     r1, #0x1
        beq     end_isr

        @ Else, load up the time variable and reset it to the default time variable
        ldr     r0, =time
        ldr     r1, =DFLT_ALARM_TIME
        str     r1, [r0]        

        b       end_isr

@ Subroutine to finish the GPIO interrupt call
end_isr:
        ldr     r2, =(IO_BANK0_BASE+0x0f8)                      @ Load the INTR2 register
        ldr     r0, =0x04440000                                 @ 0x04440000 = 2^26+2^22+2^18
        str     r0, [r2]                                        @ Clear the GPIO interrupt
        pop     {pc}                                            @ Pop the link register from the stack to the program counter

@ .align 4
@ msg:    .asciz "btn20\n"
@ msg2:   .asciz "btn21\n"
@ msg3:   .asciz "btn22\n"

.data
lstate: .word   DFLT_STATE_STRT
ltimer: .word   DFLT_ALARM_TIME
time:   .word   0
