// Resistive touch LCD library

#ifndef TOUCH_H
#define TOUCH_H

#define TOUCH_X1 5
#define TOUCH_X2 6
#define TOUCH_Y1 7
#define TOUCH_Y2 8
#define TOUCH_X_ADC 0
#define TOUCH_Y_ADC 1

void getResistiveTouch(int *x, int *y) {
    GPIO_Modes[TOUCH_X1] = 1;
    GPIO_Modes[TOUCH_X2] = 1;
    GPIO_Modes[TOUCH_Y1] = 0;
    GPIO_Modes[TOUCH_Y2] = 0;
    GPIO[TOUCH_X1] = 1;
    GPIO[TOUCH_X2] = 0;

    // Todo: Adjust delay
    for (int i = 0; i < 100; i++);
    *x = ADC[0];

    GPIO_Modes[TOUCH_X1] = 0;
    GPIO_Modes[TOUCH_X2] = 0;
    GPIO_Modes[TOUCH_Y1] = 1;
    GPIO_Modes[TOUCH_Y2] = 1;
    GPIO[TOUCH_Y1] = 1;
    GPIO[TOUCH_Y2] = 0;

    for (int i = 0; i < 100; i++);
    *y = ADC[1];
}

#endif // TOUCH_H