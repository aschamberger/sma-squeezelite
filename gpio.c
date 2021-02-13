#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <strings.h>
#include <wiringPi.h>

/*
 * gcc -o gpio gpio.c -Wall -Wextra -I/usr/local/include -Winline -pipe -lwiringPi -lwiringPiDev
 */

int main(int argc, char **argv)
{
  
  wiringPiSetupPhys ();
 
  if (argc > 1) 
  {
	  // INPUT 0, OUTPUT 1,
	  if (strcasecmp (argv [1], "set_mode") == 0) 
	  {
		int pin = atoi(argv[2]);
		int mode = atoi(argv [3]);
		pinMode (pin, mode);
	  }
	  // INPUT 0, OUTPUT 1,
	  else if (strcasecmp(argv[1], "get_mode") == 0) 
	  {
		int pin = atoi(argv [2]);
		int val = getAlt(pin);
		printf("%s\n", val == 0 ? "0" : "1");
	  }
	  // LOW 0, HIGH 1
	  else if (strcasecmp(argv[1], "read") == 0) 
	  {
		int pin = atoi(argv[2]);
		int val = digitalRead(pin);
		printf("%s\n", val == 0 ? "0" : "1");
	  }
	  // LOW 0, HIGH 1
	  else if (strcasecmp(argv[1], "write") == 0) 
	  {
		int pin = atoi(argv[2]);
		int state = atoi(argv[3]);
		digitalWrite(pin, state);
	  }
	  else
      {
        printf("Unknown command!\n");
        exit(1);
	  }
  }  
  else
  {
    printf("Unknown command!\n");
    exit(1);  
  }
  
  return 0;
  
}