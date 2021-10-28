library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_test is
end cpu_test;

architecture test of cpu_test is
	type ram_type is array(0 to 15) of std_logic_vector(31 downto 0);

	component cpu is
		port (
			clock : in std_logic;
			reset : in std_logic;
			int_in : in std_logic_vector(7 downto 0);
			data_in : in std_logic_vector(31 downto 0);
			data_out : out std_logic_vector(31 downto 0);
			address : out std_logic_vector(31 downto 0);
			data_mask : out std_logic_vector(3 downto 0);
			write_en : out std_logic;
			reset_int : out std_logic
		);
	end component;
	
	signal clock : std_logic;
	signal reset : std_logic;
	signal int_in : std_logic_vector(7 downto 0);
	signal data_in : std_logic_vector(31 downto 0);
	signal data_out : std_logic_vector(31 downto 0);
	signal address : std_logic_vector(31 downto 0);
	signal data_mask : std_logic_vector(3 downto 0);
	signal write_en : std_logic;
	signal reset_int : std_logic;
	
	signal rom : std_logic_vector(31 downto 0);
	signal ram : ram_type := (
		x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", 
		x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000"
	);
	signal mask : std_logic_vector(31 downto 0);
begin
	prcoessor : cpu
		port map (
			clock => clock,
			reset => reset,
			int_in => int_in,
			data_in => data_in,
			data_out => data_out,
			address => address,
			data_mask => data_mask,
			write_en => write_en,
			reset_int => reset_int
		);

--	rom <= -- Test branching
--		x"00000000" when address = x"00000000" else -- NOP
--		x"02000000" when address = x"00000004" else -- BNE 4
--		x"00000004" when address = x"00000008" else
--		x"4C000000" when address = x"0000000C" else -- HALT
--		x"01000000" when address = x"00000010" else -- BEQ 4
--		x"00000004" when address = x"00000014" else
--		x"4C000000" when address = x"00000018" else -- HALT
--		x"00000000" when address = x"0000001C" else -- NOP
--		x"4C000000";

--	rom <= -- Test immediate loading
--		x"12000000" when address = x"00000000" else -- LDR r0,$FF
--		x"000000FF" when address = x"00000004" else
--		x"4C000000";

--	rom <= -- Test LDR absolute
--		x"15000000" when address = x"00000000" else -- LDR r0,[$0000000C]
--		x"0000000C" when address = x"00000004" else
--		x"4C000000" when address = x"00000008" else -- Halt
--		x"ABCDEF01" when address = x"0000000C" else -- DD $ABCDEF01
--		x"4C000000";

--	rom <= -- Test LDW absolute
--		x"14000000" when address(31 downto 2) & "00" = x"00000000" else -- LDW r0,[$00000014]
--		x"00000014" when address(31 downto 2) & "00" = x"00000004" else
--		x"14000000" when address(31 downto 2) & "00" = x"00000008" else -- LDW r0,[$00000016]
--		x"00000016" when address(31 downto 2) & "00" = x"0000000C" else
--		x"4C000000" when address(31 downto 2) & "00" = x"00000010" else -- Halt
--		x"ABCDEF01" when address(31 downto 2) & "00" = x"00000014" else -- DD $ABCDEF01
--		x"4C000000";

--	rom <= -- Test LDB absolute
--		x"13000000" when address(31 downto 2) & "00" = x"00000000" else -- LDB r0,[$00000024]
--		x"00000024" when address(31 downto 2) & "00" = x"00000004" else
--		x"13100000" when address(31 downto 2) & "00" = x"00000008" else -- LDB r1,[$00000025]
--		x"00000025" when address(31 downto 2) & "00" = x"0000000C" else
--		x"13200000" when address(31 downto 2) & "00" = x"00000010" else -- LDB r2,[$00000026]
--		x"00000026" when address(31 downto 2) & "00" = x"00000014" else
--		x"13300000" when address(31 downto 2) & "00" = x"00000018" else -- LDB r3,[$00000027]
--		x"00000027" when address(31 downto 2) & "00" = x"0000001C" else
--		x"4C000000" when address(31 downto 2) & "00" = x"00000020" else -- Halt
--		x"ABCDEF01" when address(31 downto 2) & "00" = x"00000024" else -- DD $ABCDEF01
--		x"4C000000";

--	rom <= -- Test STR absolute
--		x"12000000" when address = x"00000000" else -- LDR r0,$12345678
--		x"12345678" when address = x"00000004" else
--		x"1E000000" when address = x"00000008" else -- STR r0,[$00010000]
--		x"00010000" when address = x"0000000C" else
--		x"4C000000"; -- Halt

--	rom <= -- Test STW absolute
--		x"12000000" when address = x"00000000" else -- LDR r0,$12345678
--		x"12345678" when address = x"00000004" else
--		x"1D000000" when address = x"00000008" else -- STW r0,[$00010000]
--		x"00010000" when address = x"0000000C" else
--		x"1D000000" when address = x"00000010" else -- STW r0,[$00010002]
--		x"00010002" when address = x"00000014" else
--		x"4C000000"; -- Halt

--	rom <= -- Test STB absolute
--		x"12000000" when address = x"00000000" else -- LDR r0,$12345678
--		x"12345678" when address = x"00000004" else
--		x"1E000000" when address = x"00000008" else -- STR r0,[$00010000]
--		x"00010000" when address = x"0000000C" else
--		x"1C000000" when address = x"00000010" else -- STB r0,[$00010000]
--		x"00010004" when address = x"00000014" else
--		x"1C000000" when address = x"00000018" else -- STB r0,[$00010001]
--		x"00010009" when address = x"0000001C" else
--		x"1C000000" when address = x"00000020" else -- STB r0,[$00010002]
--		x"0001000E" when address = x"00000024" else
--		x"1C000000" when address = x"00000028" else -- STB r0,[$00010003]
--		x"00010013" when address = x"0000002C" else
--		x"4C000000"; -- Halt

--	rom <= -- Test JMP
--		x"12000000" when address = x"00000000" else -- LDR r0,$0000001C
--		x"0000001C" when address = x"00000004" else
--		x"46000000" when address = x"00000008" else -- JMP $00000014
--		x"00000014" when address = x"0000000C" else
--		x"4C000000" when address = x"00000010" else -- HALT
--		x"47000000" when address = x"00000014" else -- JMP r0
--		x"4C000000" when address = x"00000018" else -- HALT
--		x"00000000" when address = x"0000001C" else -- NOP
--		x"4C000000"; -- Halt

--	rom <= -- Stack test
--		x"12F00000" when address = x"00000000" else -- LDR sp,$00010000
--		x"00010000" when address = x"00000004" else
--		x"12000000" when address = x"00000008" else -- LDR r0,$12345678
--		x"12345678" when address = x"0000000C" else
--		x"12100000" when address = x"00000010" else -- LDR r1,$98765432
--		x"98765432" when address = x"00000014" else
--		x"44000000" when address = x"00000018" else -- PUSH r0
--		x"44100000" when address = x"0000001C" else -- PUSH r1
--		x"45000000" when address = x"00000020" else -- POP r0
--		x"45100000" when address = x"00000024" else -- POP r1
--		x"4C000000"; -- Halt

--	rom <= -- Subroutine test
--		x"12F00000" when address = x"00000000" else -- LDR sp,$00010000
--		x"00010000" when address = x"00000004" else
--		x"48000000" when address = x"00000008" else -- JSR $00000014
--		x"00000014" when address = x"0000000C" else
--		x"4C000000" when address = x"00000010" else -- HALT
--		x"12000000" when address = x"00000014" else -- LDR r0,$12345678
--		x"12345678" when address = x"00000018" else
--		x"49000000" when address = x"0000001C" else -- RET
--		x"4C000000"; -- Halt

--	rom <= -- Test LDR indexed
--		x"12000000" when address = x"00000000" else -- LDR r0,$0000001C
--		x"0000001C" when address = x"00000004" else
--		x"1810C000" when address = x"00000008" else -- LDR r1,r0++
--		x"1820C000" when address = x"0000000C" else -- LDR r2,r0++
--		x"18302000" when address = x"00000010" else -- LDR r3,--r0
--		x"18402000" when address = x"00000014" else -- LDR r4,--r0
--		x"4C000000" when address = x"00000018" else -- Halt
--		x"01234567" when address = x"0000001C" else -- DD $01234567
--		x"12345678" when address = x"00000020" else -- DD $12345678
--		x"4C000000";

--	rom <= -- Test LDW indexed
--		x"12000000" when address(31 downto 2) & "00" = x"00000000" else -- LDR r0,$0000001C
--		x"0000001C" when address(31 downto 2) & "00" = x"00000004" else
--		x"1710C000" when address(31 downto 2) & "00" = x"00000008" else -- LDW r1,r0++
--		x"1720C000" when address(31 downto 2) & "00" = x"0000000C" else -- LDW r2,r0++
--		x"17302000" when address(31 downto 2) & "00" = x"00000010" else -- LDW r3,--r0
--		x"17402000" when address(31 downto 2) & "00" = x"00000014" else -- LDW r4,--r0
--		x"4C000000" when address(31 downto 2) & "00" = x"00000018" else -- Halt
--		x"01234567" when address(31 downto 2) & "00" = x"0000001C" else -- DD $01234567
--		x"4C000000";

--	rom <= -- Test LDB indexed
--		x"12000000" when address(31 downto 2) & "00" = x"00000000" else -- LDR r0,$0000001C
--		x"0000001C" when address(31 downto 2) & "00" = x"00000004" else
--		x"1610C000" when address(31 downto 2) & "00" = x"00000008" else -- LDB r1,r0++
--		x"1620C000" when address(31 downto 2) & "00" = x"0000000C" else -- LDB r2,r0++
--		x"16302000" when address(31 downto 2) & "00" = x"00000010" else -- LDB r3,--r0
--		x"16402000" when address(31 downto 2) & "00" = x"00000014" else -- LDB r4,--r0
--		x"4C000000" when address(31 downto 2) & "00" = x"00000018" else -- Halt
--		x"01234567" when address(31 downto 2) & "00" = x"0000001C" else -- DD $01234567
--		x"4C000000";

--	rom <= -- Test STR indexed
--		x"12000000" when address = x"00000000" else -- LDR r0,$00010000
--		x"00010000" when address = x"00000004" else
--		x"12100000" when address = x"00000008" else -- LDR r1,$12345678
--		x"12345678" when address = x"0000000C" else
--		x"2110C000" when address = x"00000010" else -- STR r1,r0++
--		x"2110C000" when address = x"00000014" else -- STR r1,r0++
--		x"12100000" when address = x"00000018" else -- LDR r1,$87654321
--		x"87654321" when address = x"0000001C" else
--		x"21102000" when address = x"00000020" else -- STR r1,--r0
--		x"21102000" when address = x"00000024" else -- STR r1,--r0
--		x"4C000000" when address = x"00000028" else -- Halt
--		x"4C000000";

--	rom <= -- Test STW indexed
--		x"12000000" when address = x"00000000" else -- LDR r0,$00010000
--		x"00010000" when address = x"00000004" else
--		x"12100000" when address = x"00000008" else -- LDR r1,$12345678
--		x"12345678" when address = x"0000000C" else
--		x"2010C000" when address = x"00000010" else -- STW r1,r0++
--		x"2010C000" when address = x"00000014" else -- STW r1,r0++
--		x"12100000" when address = x"00000018" else -- LDR r1,$87654321
--		x"87654321" when address = x"0000001C" else
--		x"20102000" when address = x"00000020" else -- STW r1,--r0
--		x"20102000" when address = x"00000024" else -- STW r1,--r0
--		x"4C000000" when address = x"00000028" else -- Halt
--		x"4C000000";

--	rom <= -- Test STB indexed
--		x"12000000" when address = x"00000000" else -- LDR r0,$00010000
--		x"00010000" when address = x"00000004" else
--		x"12100000" when address = x"00000008" else -- LDR r1,$12345678
--		x"12345678" when address = x"0000000C" else
--		x"1F10C000" when address = x"00000010" else -- STB r1,r0++
--		x"1F10C000" when address = x"00000014" else -- STB r1,r0++
--		x"12100000" when address = x"00000018" else -- LDR r1,$87654321
--		x"87654321" when address = x"0000001C" else
--		x"1F102000" when address = x"00000020" else -- STB r1,--r0
--		x"1F102000" when address = x"00000024" else -- STB r1,--r0
--		x"4C000000" when address = x"00000028" else -- Halt
--		x"4C000000";

--	rom <= -- Reset test
--		x"12000000" when address = x"00000000" else -- LDR r0,$12345678
--		x"12345678" when address = x"00000004" else
--		x"4A000000" when address = x"00000008" else -- INT 0
--		x"00000000" when address = x"0000000C" else
--		x"4C000000"; -- Halt

--	rom <= -- Interrupt test
--		x"46000000" when address = x"00000000" else -- JMP $00000010
--		x"00000010" when address = x"00000004" else
--		x"46000000" when address = x"00000008" else -- JMP $0000002C
--		x"0000002C" when address = x"0000000C" else
--		x"12F00000" when address = x"00000010" else -- LDR sp,$00010000
--		x"00010000" when address = x"00000014" else
--		x"4A000000" when address = x"00000018" else -- INT 1
--		x"00000001" when address = x"0000001C" else
--		x"12000000" when address = x"00000020" else -- LDR r0,$BBBBBBBB
--		x"BBBBBBBB" when address = x"00000024" else
--		x"4C000000" when address = x"00000028" else -- HALT
--		x"12000000" when address = x"0000002C" else -- LDR r0,$AAAAAAAA
--		x"AAAAAAAA" when address = x"00000030" else
--		x"4B000000" when address = x"00000034" else -- RTI
--		x"4C000000"; -- Halt

--	rom <= -- Test LDR, LDW, LDB relative
--		x"12000000" when address(31 downto 2) & "00" = x"00000000" else -- LDR r0,$00000024
--		x"00000024" when address(31 downto 2) & "00" = x"00000004" else
--		x"1B100000" when address(31 downto 2) & "00" = x"00000008" else -- LDR r1,r0,0
--		x"00000000" when address(31 downto 2) & "00" = x"0000000C" else
--		x"1A200000" when address(31 downto 2) & "00" = x"00000010" else -- LDW r2,r0,2
--		x"00000002" when address(31 downto 2) & "00" = x"00000014" else
--		x"19300000" when address(31 downto 2) & "00" = x"00000018" else -- LDB r3,r0,3
--		x"00000003" when address(31 downto 2) & "00" = x"0000001C" else
--		x"4C000000" when address(31 downto 2) & "00" = x"00000020" else -- HALT
--		x"01234567" when address(31 downto 2) & "00" = x"00000024" else -- DD $01234567
--		x"4C000000"; -- HALT

	rom <= -- Test STR, STW, STB relative
		x"12000000" when address = x"00000000" else -- LDR r0,$12345678
		x"12345678" when address = x"00000004" else
		x"12100000" when address = x"00000008" else -- LDR r1,$00010000
		x"00010000" when address = x"0000000C" else
		x"24010000" when address = x"00000010" else -- STR r0,r1,0
		x"00000000" when address = x"00000014" else
		x"23010000" when address = x"00000018" else -- STW r0,r1,4
		x"00000004" when address = x"0000001C" else
		x"22010000" when address = x"00000020" else -- STB r0,r1,6
		x"00000006" when address = x"00000024" else
		x"4C000000"; -- Halt
	
	mask <= std_logic_vector(resize(signed(data_mask(3 downto 3)), 8) & resize(signed(data_mask(2 downto 2)), 8) 
		& resize(signed(data_mask(1 downto 1)), 8) & resize(signed(data_mask(0 downto 0)), 8));
	
	process(all)
	begin
		if reset = '1' then
			data_in <= x"00000000";
		elsif rising_edge(clock) then
			if to_integer(unsigned(address)) < 16#10000# then
				data_in <= rom and mask;
			elsif to_integer(unsigned(address)) < 16#20000# then
				if write_en = '1' then
					ram(to_integer(unsigned(address(5 downto 2)))) <= (data_out and mask) or (ram(to_integer(unsigned(address(5 downto 2)))) and not mask);
				end if;
				data_in <= ram(to_integer(unsigned(address(5 downto 2)))) and mask;
			else
				data_in <= x"00000000";
			end if;
		end if;
	end process;
	
	vectors: process
		constant period: time := 10 ns;
	begin	
		  -- Reset
		  int_in <= x"00";
		  clock <= '0';
		  reset <= '1';
		  wait for period;
		  clock <= '1';
		  wait for period;
		  clock <= '0';
		  wait for period;
		  clock <= '1';
		  wait for period;
		  clock <= '0';
		  wait for period;
		  reset <= '0';
		  clock <= '1';
		  wait for period;
		  clock <= '0';
				  
		  for i in 1 to 40 loop
				wait for period;
				clock <= '1';
				wait for period;
				clock <= '0';
		  end loop;
		  
		  wait;
    end process;
end test;
