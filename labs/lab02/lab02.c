//#define WOKWI //Uncomment when using Wokwi sim
//

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "pico/stdlib.h"
#include "pico/float.h"     // Required for using single-precision variables.
#include "pico/double.h"    // Required for using double-precision variables.

//Declare the functions piPrintF and piPrintD
void piPrintF(int limit);
void piPrintD(int limit);

//Declare a double constant PI which acts as the comparison for the approx. error
const double PI = 3.14159265359;

int main() {
  //Call piPrintF, passing in the 100000 as a parameter for calculation
  piPrintF(100000);

  //Call piPrintD, passing in the 100000 as a parameter for calculation
  piPrintD(100000);

  return 0;
}

//Declare the function piPrintF with argument limit
void piPrintF(int limit) {

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
}

//Declare the function piPrintD with argument limit
void piPrintD(int limit) {

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
}
