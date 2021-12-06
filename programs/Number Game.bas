' Number guessing game

@loop

random num
num = (num and 127) mod 100

@guess_loop
print "Enter a guess between 1 and 99: "

input guess

if guess < 1 || guess > 99 then
    print "\n"
    goto @guess_loop
endif

print guess
print "\n"

if guess == num then
    print "Correct!\n"
    goto @loop
elseif guess < num then
    print "Too low!\n"
else
    print "Too high!\n"
endif

goto @guess_loop
