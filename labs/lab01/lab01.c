/**
 * @brief LAB #01 - TEMPLATE
 *        Main entry point for the code.
 * 
 */

#include "pico/stdlib.h"

/**
 * @brief EXAMPLE - BLINK_C
 *        Simple example to initialise the built-in LED on
 *        the Raspberry Pi Pico and then flash it forever. 
 * 
 * @return int  Application return code (zero for success).
 */

void BLINK(uint Pin, uint Delay) {
  //While loop that doesn't end
  while (true) {

    // Toggle the LED on
    gpio_put(Pin, 1);
    //Sleep for delay period
    sleep_ms(Delay);

    // Toggle the LED off
    gpio_put(Pin, 0);
    //Sleep for delay period
    sleep_ms(Delay);

  }
}

int main() {

    // Specify the PIN number and sleep delay
    const uint LED_PIN   =  25;
    const uint LED_DELAY = 500;

    // Setup the LED pin as an output.
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);

    BLINK(LED_PIN, LED_DELAY);

    // Should never get here due to infinite while-loop.
    return 0;

}