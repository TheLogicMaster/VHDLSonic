-- 32-bit ALU

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; --possible not needed; VHDL 2008 includes numeric_std by default; gives error when commented out

entity aluv2 is
	port (
		operand_1 : in unsigned(31 downto 0);
		operand_2 : in unsigned(31 downto 0);
		mode : in std_logic_vector(3 downto 0);
		flags_in : in std_logic_vector(3 downto 0); --ZCNV - current
		result : out unsigned(31 downto 0);
		flags_out : out std_logic_vector(3 downto 0) --ZCNV (3:0)
	);
end entity;

architecture impl of aluv2 is
--internal signal used to store the result and in concurrent statements
--1 bit wider to store carry out
signal res : unsigned(32 downto 0) := 33x"0_0000_0000";

begin

	
	flags_out(3) <= '1' when result = x"0000_0000" else '0'; 				  --Z
	
	flags_out(1) <= res(31);											 				  --N

	with to_integer(unsigned(mode)) select											  --C
		
		flags_out(2) <= res(32) when 1 to 4 | 8 to 10,		
							 flags_in(2) when others;


	flags_out(0) <= '0' when ((res(31)=operand_1(31)) and (operand_1(31)=operand_2(31))) else '1'; --V
	

	result <= res(31 downto 0);

	process(all)
	begin
	
	-- Calculate result
		case to_integer(unsigned(mode)) is
			when 0 => res <= resize(operand_1 * operand_2, 33); 										 							-- MUL
			
			when 1 => res <= ('0' & operand_1) + ('0' & operand_2); 														 				-- ADD
			
			when 2 => res <= ('0' & operand_1) + ('0' & operand_2) + unsigned(flags_in(2 downto 2));  		 					-- ADC
			
			when 3 => res <= ('0' & operand_1) - ('0' & operand_2); 														 				-- SUB
			
			when 4 => res <= ('0' & operand_1) - ('0' & operand_2) - unsigned(flags_in(2 downto 2));  		 					-- SBC
			
			when 5 => res(31 downto 0) <= operand_1 and operand_2; 													 					-- AND
			
			when 6 => res(31 downto 0) <= operand_1 or operand_2; 																	   -- OR
			
			when 7 => res(31 downto 0) <= operand_1 xor operand_2;										   						   -- XOR
			
			when 8 => res(31 downto 0) <= shift_left(operand_1, to_integer(operand_2)); 							   	-- LSL
						 if (to_integer(operand_2) > 32) then
							res(32) <= '0';
						 else
							res(32) <= operand_1(31 - to_integer(operand_2) - 1);
						 end if;
			
			when 9 => res(31 downto 0) <= shift_right(operand_1, to_integer(operand_2)); 						 			-- LSR
						 if (to_integer(operand_2) > 32) then
							res(32) <= '0';
						 else
						  res(32) <= operand_1(to_integer(operand_2) - 1);
						 end if;
			
			when 10 => res(31 downto 0) <= unsigned(shift_right(signed(operand_1), to_integer(operand_2))); 		-- ASR
						 if (to_integer(operand_2) > 32) then
						 	res(32) <= operand_1(31);
						 else
						  	res(32) <= operand_1(to_integer(operand_2) - 1);
						 end if;
			
			when others => res <= 'X' & x"XXXXXXXX"; 																	 				-- Illegal mode
		end case;

	end process;
end architecture;