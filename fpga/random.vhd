-- Random number generator

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity random is
	port (
		clock	: in std_logic;
		reset : in std_logic;
		seed : in std_logic_vector(31 downto 0);
		seed_write : in std_logic;
		rand : out std_logic_vector(31 downto 0)
	);
end entity;

architecture impl of random is
	signal lsfr : std_logic_vector(31 downto 0);
begin
	rand <= lsfr;
	
	process(all)
	begin
		if reset = '1' then
			lsfr <= x"FFFFFFFF";
		elsif rising_edge(clock) then
			if seed_write = '1' then
				lsfr <= seed;
			else
				lsfr(31) <= lsfr(0);
				lsfr(30) <= lsfr(31) xor lsfr(0);
				
				for i in 29 downto 0 loop
					lsfr(i) <= lsfr(i + 1);
				end loop;
			end if;
		end if;
	end process;
end architecture;
