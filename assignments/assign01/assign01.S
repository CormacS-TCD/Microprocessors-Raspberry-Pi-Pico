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

@ Entry point to the ASM portion of the program
main_asm:
        ldr     r0, =msg
        bl      printf
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        movs    r0, #GPIO_LED_PIN     @ Initialize the LED and set the direction to output
        bl      asm_gpio_init
        movs    r0, #GPIO_LED_PIN
        movs    r1, #GPIO_DIR_OUT
        bl      asm_gpio_set_dir
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        movs    r0, #GPIO_BTN_DN      @ Initialize the DN button and set the direction to input
        bl      asm_gpio_init
        movs    r0, #GPIO_BTN_DN
        movs    r1, #GPIO_DIR_IN
        bl      asm_gpio_set_dir
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        movs    r0, #GPIO_BTN_EN      @ Initialize the EN button and set the direction to input
        bl      asm_gpio_init
        movs    r0, #GPIO_BTN_EN
        movs    r1, #GPIO_DIR_IN
        bl      asm_gpio_set_dir
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        movs    r0, #GPIO_BTN_UP      @ Initialize the UP button and set the direction to input
        bl      asm_gpio_init
        movs    r0, #GPIO_BTN_UP
        movs    r1, #GPIO_DIR_IN
        bl      asm_gpio_set_dir
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        movs    r0, #GPIO_BTN_DN      @ Set DN, EN and UP to have interupts on them
        bl      asm_gpio_set_irq
        movs    r0, #GPIO_BTN_EN
        bl      asm_gpio_set_irq
        movs    r0, #GPIO_BTN_UP
        bl      asm_gpio_set_irq
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ldr     r0, =time_length
        ldr     r1, =DFLT_ALARM_TIME
        str     r1, [r0]
        bl      install_alarm_isr
        bl      load_alarm
        bl      install_gpio_isr




main_loop:
        wfi
        b       main_loop



install_alarm_isr:
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)            @Get the offset of the vector table
        ldr     r1, [r2]                                        @Load that into r1
        movs    r2, #ALRM_ISR_OFFSET                            @Load the Timer0 offset
        add     r2, r1                                          @Add the offset
        ldr     r0, =toggle_led                                 @Get the address of the toggle_led isr
        str     r0, [r2]                                        @Store that at the Timer0 isr address. This is the place where the processor will look at when an timer0 interrupt is triggered
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @Load ICPR register. Here we can clear pending interrupts
        movs    r0, #0x1
        str     r0, [r2]                                        @Write a 1 in bit position 0 to clear the Timer0 interrupt
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @Load the ISER register. Here we can enable interrupts
        movs    r0, #0x1
        str     r0, [r2]                                        @Write a 1 in bit positon 0 to enable the Timer0 interrupt
        bx      lr

load_alarm:
        ldr     r1, =time_length
        ldr     r0, [r1]          
        ldr     r2, =(TIMER_BASE)
        movs    r1, #0x1
        str     r1, [r2, #TIMER_INTE_OFFSET]
        ldr     r1, [r2, #TIMER_TIMELR_OFFSET]
        add     r1, r0
        str     r1, [r2, #TIMER_ALARM0_OFFSET]
        bx      lr

install_gpio_isr:
        ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)
        ldr     r1, [r2]
        movs    r2, #GPIO_ISR_OFFSET
        add     r2, r1
        ldr     r0, =gpio_isr
        str     r0, [r2]
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @Write to bit 13 in ICPR to clear a pending interupt
        ldr     r0, =0x2001                                     @0x2001 = 2^13+1
        str     r0, [r2]
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @Write to bit 13 in ISER to enable gpio interrupt
        ldr     r0, =0x2001                                     @0x2001 = 2^13+1
        str     r0, [r2]
        bx      lr



.thumb_func
toggle_led:
        push    {lr}                                            @ Store the link register to the stack as we will call nested subroutines

        ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @Write to bit 13 in ICPR to clear a pending interupt
        ldr     r0, =0x2001                                     @0x2001 = 2^13+1
        str     r0, [r2]
        
        ldr     r2, =(TIMER_BASE)
        movs    r1, #0x1
        str     r1, [r2, #TIMER_INTR_OFFSET]

        ldr     r0, =lstate
        ldr     r1, [r0]
        cmp     r1, #0x0
        beq     end_alarm_isr

        movs    r0, #GPIO_LED_PIN           @ Set the LED GPIO pin number to r0 for use by asm_gpio_get
        bl      asm_gpio_get                @ Get current the value of the LED GPIO pin (returns to r0)
        cmp     r0, #LED_VAL_OFF          @ Check if the LED GPIO pin value is "off"
        beq     led_set_on                  @ If it is "off" then then jump code to to turn it on
led_set_off:
        movs    r1, #LED_VAL_OFF          @ The LED is currently "on" so we want to turn it "off"
        b       led_set_state               @ Jump to portion of code where we set the state of the LED
led_set_on:
        movs    r1, #LED_VAL_ON           @ The LED is currently "off" so we want to turn it "on"
led_set_state:
        movs    r0, #GPIO_LED_PIN           @ Set the LED GPIO pin number to r0 for use by asm_gpio_put
        bl      asm_gpio_put                @ Update the the value of the LED GPIO pin (based on value in r1)
        
end_alarm_isr:
        bl      load_alarm
        pop     {pc}                        @ Pop the link register from the stack to the program counter

.thumb_func
gpio_isr:
        push    {lr}   

        @Check status mask and do something
        ldr     r2, =(IO_BANK0_BASE+IO_BANK0_PROC0_INTS2_OFFSET)
        ldr     r1, [r2]                                    @Get the Status register
        ldr     r0, =GPIO_BTN_DN_MSK
        ands    r1,r0,r1
        cmp     r0, r1
        beq     button_20                                   @If it is equal to the DN mask, then button 20 was pressed
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ldr     r1, [r2]                                    @Get the Status registe
        ldr     r0, =GPIO_BTN_EN_MSK
        ands    r1,r0,r1
        cmp     r0, r1                        
        beq     button_21                                   @If it is equal to the EN mask, then button 21 was pressed
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ldr     r1, [r2]                                    @Get the Status registe
        ldr     r0, =GPIO_BTN_UP_MSK
        ands    r1,r0,r1
        cmp     r0,r1
        beq     button_22                                   @If it is equal to the UP mask, then button 22 was pressed
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


button_20:
        ldr     r0, =lstate
        ldr     r1, [r0]
        cmp     r1, #0x0
        beq     button20_22

        ldr     r0, =msg
        bl      printf
        ldr     r0, =time_length
        ldr     r1, [r0]
        movs    r2, #0x1
        lsrs    r1, r1, r2
        str     r1, [r0]
        b       end_isr

button_21:
        ldr     r0, =lstate
        ldr     r1, [r0]

        cmp     r1, #0x1
        beq     toggle_off_lstate
        movs    r1, #0x1
        str     r1, [r0]
        b       end_isr

toggle_off_lstate:
        movs    r1, #0x0
        str     r1, [r0]

        @movs    r1, #LED_VAL_OFF
        movs    r0, #GPIO_LED_PIN       
        bl      asm_gpio_put

        b       end_isr

button_22:
        ldr     r0, =lstate
        ldr     r1, [r0]
        cmp     r1, #0x0
        beq     button20_22

        ldr     r0, =msg3
        bl      printf
        ldr     r0, =time_length
        ldr     r1, [r0]
        movs    r2, #0x1
        lsls    r1, r1, r2
        str     r1, [r0]
        b       end_isr

button20_22:
        ldr     r0, =lstate
        ldr     r1, [r0]
        cmp     r1, #0x1
        beq     end_isr

        ldr     r0, =time_length
        ldr     r1, =DFLT_ALARM_TIME
        str     r1, [r0]        

        b       end_isr
end_isr:
        ldr     r2, =(IO_BANK0_BASE+0x0f8)                      @Load the INTR2 register
        ldr     r0, =0x04440000                                 @0x04440000 = 2^26+2^22+2^18 to clear the interrupt
        str     r0, [r2]
        pop     {pc}

.align 4
msg:    .asciz "btn20\n"
msg2:   .asciz "btn21\n"
msg3:   .asciz "btn22\n"

.data
lstate: .word   DFLT_STATE_STRT
ltimer: .word   DFLT_ALARM_TIME
time_length: .word 0
