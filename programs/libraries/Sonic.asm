; VHDLSonic

; Special register ports
    def ie=$20000
    def if=$20001

    def random=$20002

; Graphics ports
    def render=$30000
    def h_scroll=$30004
    def v_scroll=$30008
    def window_x=$3000C
    def window_y=$30010
    def palette=$30014
    def tile_data=$30054
    def bg_data=$38054
    def win_data=$3C054
    def sprites=$3D314

; Microcontroller ports
    def leds=$40000
    def seven_segment=$40028
    def gpio=$40040
    def gpio_modes=$400D0
    def arduino=$40160
    def arduino_modes=$40416
    def switches=$401E0
    def buttons=$40208
    def serial=$40210
