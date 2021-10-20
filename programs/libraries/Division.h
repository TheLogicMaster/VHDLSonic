 // Division function

#include "Sonic.h"

int divide(int numerator, int denominator) {
    int quotient = 0;
    int remainder = 0;
    int sign = 1;
    int is_min = 0;

    if (denominator == 0)
        error();

    if (denominator == 1)
        return numerator;

    if (numerator == 0x80000000) {
        if (denominator == -1)
            error();
        is_min = 1;
        numerator++;
    }

    if (numerator > 0 != denominator > 0)
        sign = -1;

    if (numerator < 0)
        numerator *= -1;

    if (denominator < 0)
        denominator *= -1;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (numerator >> i) & 1;
        if (remainder >= denominator) {
            remainder -= denominator;
            quotient |= 1 << i;
        }
    }

    if (is_min && remainder == denominator - 1) {
        remainder = 0;
        quotient++;
    }

    return quotient * sign;
}
