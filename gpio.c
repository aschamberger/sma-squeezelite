#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <strings.h>
#include <lgpio.h>

#define LFLAGS 0

/*
 * gcc -O3 -Wall -pthread -o gpio gpio.c -I/usr/local/src/lg-master -L/usr/local/src/lg-master -llgpio
 */

int main(int argc, char **argv)
{
    int h;
    int pin, mode, state;

    static int board_map[41] =
    {
        -1,     // 0
        -1, -1, // 1, 2
         2, -1, // 3, 4
         3, -1, // ...
         4, 14,
        -1, 15,
        17, 18,
        27, -1,
        22, 23,
        -1, 24,
        10, -1,
         9, 25,
        11,  8,
        -1,  7,
         0,  1,
         5, -1,
         6, 12,
        13, -1,
        19, 16,
        26, 20,
        -1, 21,
    };

    h = lgGpiochipOpen(0);

    if (h < 0)
    {
        printf("Could not open GPIO!\n");
        exit(1);
    }

    if (argc > 1)
    {
        // INPUT 0, OUTPUT 1,
        if (strcasecmp (argv [1], "set_mode") == 0)
        {
            pin = atoi(argv[2]);
            mode = atoi(argv[3]);
            if (mode == 1)
            {
                state = lgGpioRead(h, board_map[pin]);
                lgGpioClaimOutput(h, LFLAGS, board_map[pin], state);
            }
            else if (mode == 0)
            {
                lgGpioClaimInput(h, LFLAGS, board_map[pin]);
            }
        }
        // INPUT 0, OUTPUT 1,
        else if (strcasecmp(argv[1], "get_mode") == 0)
        {
            pin = atoi(argv[2]);
            mode = lgGpioGetMode(h, board_map[pin]);
            printf("%s", mode & 0x2 ? "1" : "0");
        }
        // LOW 0, HIGH 1
        else if (strcasecmp(argv[1], "read") == 0)
        {
            pin = atoi(argv[2]);
            state = lgGpioRead(h, board_map[pin]);
            printf("%s", state == 0 ? "0" : "1");
        }
        // LOW 0, HIGH 1
        else if (strcasecmp(argv[1], "write") == 0)
        {
            pin = atoi(argv[2]);
            state = atoi(argv[3]);
            lgGpioWrite(h, board_map[pin], state);
        }
        else
        {
            printf("Unknown command!\n");
            lgGpiochipClose(h);
            exit(1);
        }
    }
    else
    {
        printf("Unknown command!\n");
        lgGpiochipClose(h);
        exit(1);
    }

    lgGpiochipClose(h);

    return 0;

}