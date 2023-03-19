#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "pico/stdlib.h"
#include "pico/float.h"     // Required for using single-precision variables.
#include "pico/double.h"    // Required for using double-precision variables.
#include "pico/multicore.h" // Required for using multiple cores on the RP2040.
#include "hardware/timer.h"


//Declare the functions piPrintF and piPrintD
int piPrintF(int limit);
int piPrintD(int limit);

//Declare a double constant PI which acts as the comparison for the approx. error
const double PI = 3.14159265359;

//Global variable for capturing time on the second core
float Time2;


/**
 * @brief This function acts as the main entry-point for core #1.
 *        A function pointer is passed in via the FIFO with one
 *        incoming int32_t used as a parameter. The function will
 *        provide an int32_t return value by pushing it back on 
 *        the FIFO, which also indicates that the result is ready.
 */

void core1_entry() {
    while (1) {
      //Pull the function and the variable onto the second core
      int32_t (*func)() = (int32_t(*)()) multicore_fifo_pop_blocking();
      int32_t p = multicore_fifo_pop_blocking();
      //Store the output of the function in result, and push it back to the first core
      int32_t result = (*func)(p);
      multicore_fifo_push_blocking(result);

      //Capture the absolute time in ms that the function ends on
      Time2 = to_ms_since_boot (get_absolute_time());
    }
}

// Main code entry point for core0.
int main() {

    const int ITER_MAX   = 100000;


    stdio_init_all();

    //Launch the second core
    multicore_launch_core1(core1_entry);

    //Capture absolute time in ms that the function starts on 
    float time1 = to_ms_since_boot (get_absolute_time());
    //Call piPrintF, passing in the 100000 as a parameter for calculation
    piPrintF(ITER_MAX);
    //Capture absolute time in ms that the function ends on 
    float time2 = to_ms_since_boot (get_absolute_time());

    //Capture absolute time in ms that the function starts on 
    float time3 = to_ms_since_boot (get_absolute_time());
    //Call piPrintD, passing in the 100000 as a parameter for calculation
    piPrintD(ITER_MAX);
    //Capture absolute time in ms that the function ends on 
    float time4 = to_ms_since_boot (get_absolute_time());

    //Print the two function run times and the total application run time
    printf("\n@Function F ran for %f seconds.\n", (time2-time1)/1000);
    printf("@Function D ran for %f seconds.\n", (time4-time3)/1000);
    printf("@Application ran for %f seconds.\n\n", (time4-time1)/1000);



    // Code for parallel run goes here…
    //Capture absolute time in ms that the function starts on 
    float Time1 = to_ms_since_boot (get_absolute_time());

    //Push the function and its variable to the second core
    multicore_fifo_push_blocking((uintptr_t) &piPrintF);
    multicore_fifo_push_blocking(ITER_MAX);
    //Capture absolute time in ms that the function starts on 
    float Time3 = to_ms_since_boot (get_absolute_time());
    piPrintD(ITER_MAX);
    //Capture absolute time in ms that the function ends on 
    float Time4 = to_ms_since_boot (get_absolute_time());

    //Print the two function run times and the total application run time
    printf("\n@Function F ran for %f seconds.\n", (Time2-Time1)/1000);
    printf("@Function D ran for %f seconds.\n", (Time4-Time3)/1000);
    printf("@Application ran for %f seconds.\n\n", (Time4-Time1)/1000);


    return 0;
}

//Declare the function piPrintF with argument limit
int piPrintF(int limit) {

  //Calculate the value of pi using limit and single-precision (float) through the Wallis product
  float pi = (4 / 3.0f);
  for (float i = 2; i <= limit; i++) {
    pi = pi * (2.0f * i) * (2.0f * i);
    pi = pi / (((2.0f * i) - 1) * ((2.0f * i) + 1.0f));
  }

  //Print the calculated pi value to the console
  printf("Single-precision value: %f\n", 2*pi);

  //Print the calculated approx. error percentage to the console
  printf("Approximation error percentage: %f\n", (100*((PI-(2*pi))/PI)));

  return 0;
}

//Declare the function piPrintD with argument limit
int piPrintD(int limit) {

  //Calculate the value of pi using limit and double-precision (double) through the Wallis product
  double pi = (4 / 3.0f);
  for (double i = 2; i <= limit; i++) {
    pi = pi * (2.0f * i) * (2.0f * i);
    pi = pi / (((2.0f * i) - 1) * ((2.0f * i) + 1.0f));
  }

  //Print the claculated pi value to the console
  printf("Double-precision value: %lf\n", 2*pi);

  //Print the calculated approx. error percentage to the console
  printf("Approximation error precentage: %lf\n", (100*((PI-(2*pi))/PI)));

  return 0;
}