' Test Basic program

' Set variables to some values
b = 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 ' 14 arithmetic operations per line maximum
a = 2
a = a + 1

' Hello World
print "Hello World!\n"

' Print a
print "a = "
print a
print "\n"

' Test basic arithmetic
if 2 * 3 / 2 == 3 && 2 * (3 / 2) == 2 then print "Parentheses working!\n"
if 2 + 3 * 4 == 14 then print "Operator precedence working!\n"

' Call @routine
gosub @routine

' Jump to @test
goto @test
end
@test

' Test operators
if 1 == 1 then print "1 == 1\n"
if 1 != 0 then print "1 != 0\n"
if 0 > -1 then print "0 > -1\n"
if 0 >= -1 then print "0 >= -1\n"
if -1 < 0 then print "-1 < 0\n"
if -1 <= 0 then print "-1 <= 0\n"
if 1 << 2 == 4 then print "1 << 2 == 4\n"
if 4 >> 2 == 1 then print "4 >> 2 == 1\n"
if 3 + 1 == 4 then print "3 + 1 == 4\n"
if 3 - 1 == 2 then print "3 - 1 == 2\n"
if 2 * 2 == 4 then print "2 * 2 = 4\n"
if 4 / 2 == 2 then print "4 / 2 == 2\n"
if 5 mod 3 == 2 then print "5 mod 3 == 2\n"
if (2 && 1) == 1 then print "(2 && 1) == 1\n"
if (2 || 1) == 1 then print "(2 || 1) == 1\n"
if (1 and 2) == 0 then print "(1 and 2) == 0\n"
if (1 or 2) == 3 then print "(1 or 2) == 3\n"
if (1 xor 3) == 2 then print "(1 xor 3) == 2\n"
if not 0 == -1 then print "not 0 == -1\n"
if !2 == 0 then print "!2 == 0\n"

' Test IF-ELSE branches
for i = 0 to 3
    print "i = "
    print i
    print ": "
    if i == 0 then
        print "IF"
    elseif i ==1 then
        print "ELSEIF 1"
    elseif i == 2 then
        print "ELSEIF 2"
    else
        print "ELSE"
    endif
    print "\n"
next

' Test WHILE loops
print "While: "
a = 0
while a < 3
    b = 0
    while b < 4
        print a * 3 + b
        inc b
        if b == 3 then exitwhile
    wend
    inc a
wend
print "\n"

' Test FOR loops
print "For: "
for i = 2 to 0 step -1
    for j = 0 to 3
        if j == 3 then exitfor
        print i * 3 + 2 - j
    next
next
print "\n"

' Test DO-WHILE and DO-UNTIL loops
a = 0
print "Loop: "
do
    b = 0
    do
        print a * 3 + b
        inc b
        if b == 3 then exitdo
    loop while b < 4
    inc a
loop until a == 3
print "\n"

' Set and read back an LED
setled 1, 1
getled a, 1
if a == 0 then print "LED off\n" else print "LED on\n"

' Read and print switch 0
getswitch switch, 0
print "Switch 0: "
if switch then print "on\n" else print "off\n"

' Read ADC 0
getadc adc, 0
print "ADC 0: "
print adc
print "\n"

' Set and read back seven segment display
setsevenseg 0, 15
getsevenseg seg, 0
print "HEX0: "
print seg
print "\n"

' Wait for button 0 to be pressed
print "Press Button 0...\n"
while !pressed
    getbtn pressed, 0
wend
print "Pressed!\n"

' End program
end

' Routine
@routine
print "Routine!\n"
return
