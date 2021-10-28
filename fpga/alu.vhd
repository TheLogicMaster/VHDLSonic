-- 32-bit ALU

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
	port (
		operand_1 : in std_logic_vector(31 downto 0);
		operand_2 : in std_logic_vector(31 downto 0);
		mode : in std_logic_vector(3 downto 0);
		flags_in : in std_logic_vector(3 downto 0);
		result : out std_logic_vector(31 downto 0);
		flags_out : out std_logic_vector(3 downto 0)
	);
end entity;

architecture impl of alu is
begin
	process(all)
		variable res : unsigned(31 downto 0);
	begin	
		-- Calculate result
		case to_integer(unsigned(mode)) is
			when 0 => res := resize(unsigned(operand_1) * unsigned(operand_2), 32); -- MUL
			when 1 => res := unsigned(operand_1) + unsigned(operand_2); -- ADD
			when 2 => res := unsigned(operand_1) + unsigned(operand_2) + unsigned(flags_in(2 downto 2)); -- ADC
			when 3 => res := unsigned(operand_1) - unsigned(operand_2); -- SUB
			when 4 => res := unsigned(operand_1) - unsigned(operand_2) - unsigned(flags_in(2 downto 2)); -- SBC
			when 5 => res := unsigned(operand_1) and unsigned(operand_2); -- AND
			when 6 => res := unsigned(operand_1) or unsigned(operand_2); -- OR
			when 7 => res := unsigned(operand_1) xor unsigned(operand_2); -- XOR
			when 8 => res := shift_left(unsigned(operand_1), to_integer(unsigned(operand_2))); -- LSL
			when 9 => res := shift_right(unsigned(operand_1), to_integer(unsigned(operand_2))); -- LSR
			when 10 => res := unsigned(shift_right(signed(operand_1), to_integer(unsigned(operand_2)))); -- ASR
			when others => res := x"XXXXXXXX"; -- Illegal mode
		end case;
		
		-- Set Zero flag
		if res = x"00000000" then
			flags_out(3) <= '1';
		else
			flags_out(3) <= '0';
		end if;
		
		-- Set Carry flag
		case to_integer(unsigned(mode)) is
			when 0 | 5 to 7 => flags_out(2) <= flags_in(2); -- MUL, AND, OR, XOR
			when 1 => -- ADD
				if ('0' & unsigned(operand_1)) + unsigned(operand_2) > x"FFFFFFFF" then
					flags_out(2) <= '1';
				else
					flags_out(2) <= '0';
				end if;
			when 2 => -- ADC
				if ('0' & unsigned(operand_1)) + unsigned(operand_2) + unsigned(flags_in(2 downto 2)) > x"FFFFFFFF" then
					flags_out(2) <= '1';
				else
					flags_out(2) <= '0';
				end if;
			when 3 => -- SUB
				if unsigned(operand_2) <= unsigned(operand_1) then
					flags_out(2) <= '1';
				else
					flags_out(2) <= '0';
				end if;
			when 4 => -- SBC
				if unsigned(operand_2) + unsigned(flags_in(2 downto 2)) <= unsigned(operand_1) then
					flags_out(2) <= '1';
				else
					flags_out(2) <= '0';
				end if;
			when 8 => -- LSL
				if operand_2 > x"00000000" and shift_left(unsigned(operand_1), to_integer(unsigned(operand_2)) - 1)(31) = '1' then
					flags_out(2) <= '1';
				else
					flags_out(2) <= '0';
				end if;
			when 9 => -- LSR
				if operand_2 > x"00000000" and shift_right(unsigned(operand_1), to_integer(unsigned(operand_2)) - 1)(0) = '1' then
					flags_out(2) <= '1';
				else
					flags_out(2) <= '0';
				end if;
			when 10 => -- ASR
				if operand_2 > x"00000000" and shift_right(signed(operand_1), to_integer(unsigned(operand_2)) - 1)(0) = '1' then
					flags_out(2) <= '1';
				else
					flags_out(2) <= '0';
				end if;
			when others => flags_out(2) <= 'X'; -- Illegal mode
		end case;
		
		-- Set Negative flag
		case to_integer(unsigned(mode)) is
			when 0 | 5 to 10 => flags_out(1) <= flags_in(1); -- MUL, AND, OR, XOR, LSL, LSR, ASR
			when 1 to 4 => flags_out(1) <= res(31); -- ADD, ADC, SUB, SBC
			when others => flags_out(1) <= 'X'; -- Illegal mode
		end case;
		
		-- Set oVerflow flag
		case to_integer(unsigned(mode)) is
			when 0 | 5 to 10 => flags_out(0) <= flags_in(0); -- MUL, AND, OR, XOR, LSL, LSR, ASR
			when 1 => -- ADD
				if (operand_1 and x"80000000") = (operand_2 and x"80000000") 
						and (operand_1 and x"80000000") /= (std_logic_vector(res) and x"80000000") then
					flags_out(0) <= '1';
				else
					flags_out(0) <= '0';
				end if;
			when 2 => -- ADC
				if (operand_1 and x"80000000") = (std_logic_vector(unsigned(operand_2) + unsigned(flags_in(2 downto 2))) and x"80000000")
						and (operand_1 and x"80000000") /= (std_logic_vector(res) and x"80000000") then
					flags_out(0) <= '1';
				else
					flags_out(0) <= '0';
				end if;
			when 3 => -- SUB
				if ((operand_1 xor std_logic_vector(res)) and ((not operand_2) xor std_logic_vector(res)) and x"80000000") > x"00000000" then
					flags_out(0) <= '1';
				else
					flags_out(0) <= '0';
				end if;
			when 4 => -- SBC
				if ((operand_1 xor std_logic_vector(res))
						and ((not std_logic_vector(unsigned(operand_2) + unsigned(flags_in(2 downto 2)))) xor std_logic_vector(res)) and x"80000000") > x"00000000" then
					flags_out(0) <= '1';
				else
					flags_out(0) <= '0';
				end if;
			when others => flags_out(0) <= 'X'; -- Illegal mode
		end case;
		
		result <= std_logic_vector(res);
	end process;
end architecture;
