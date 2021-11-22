; VHDLSonic

; CPU ports
    def ie=$20000
    def if=$20004
    def random=$20008

; Graphics ports
    def render=$30000
    def h_scroll=$30004
    def v_scroll=$30008
    def window_x=$3000C
    def window_y=$30010
    def palette=$30014
    def tile_data=$30054
    def bg_data=$32054
    def win_data=$36054
    def sprites=$37314

; Microcontroller ports
    def leds=$40000
    def led_0=$40000
    def led_1=$40004
    def led_2=$40008
    def led_3=$4000C
    def led_4=$40010
    def led_5=$40014
    def led_6=$40018
    def led_7=$4001C
    def led_8=$40020
    def led_9=$40024
    def seven_segment=$40028
    def seven_segment_0=$40028
    def seven_segment_1=$4002C
    def seven_segment_2=$40030
    def seven_segment_3=$40034
    def seven_segment_4=$40038
    def seven_segment_5=$4003C
    def gpio=$40040
    def gpio_modes=$400D0
    def arduino=$40160
    def arduino_modes=$401A0
    def switches=$401E0
    def switch_0=$401E0
    def switch_1=$401E4
    def switch_2=$401E8
    def switch_3=$401EC
    def switce_4=$401F0
    def switce_5=$401F4
    def switch_6=$401F8
    def switch_7=$401FC
    def switch_8=$40200
    def switch_9=$40204
    def buttons=$40208
    def button_0=$40208
    def button_1=$4020C
    def serial=$40210
    def serial_available=$40214
    def serial_full=$40218
    def uart_enable=$4021C
    def adc=$40220
    def adc_0=$40220
    def adc_1=$40224
    def adc_2=$40228
    def adc_3=$4022C
    def adc_4=$40230
    def adc_5=$40234
