-- 32-bit CPU

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
	port (
		clock : in std_logic;
		reset : in std_logic;
		int_in : in std_logic_vector(7 downto 0);
		data_in : in std_logic_vector(31 downto 0);
		data_out : buffer std_logic_vector(31 downto 0);
		address : buffer std_logic_vector(31 downto 0);
		data_mask : out std_logic_vector(3 downto 0);
		write_en : buffer std_logic;
		reset_int : out std_logic
	);
end entity;

architecture impl of cpu is
	type state_type is (
		s_decode_1,
		s_decode_2,
		s_interrupt_1,
		s_interrupt_2,
		s_interrupt_3,
		s_interrupt_4,
		s_interrupt_5,
		s_reset,
		s_branch_1,
		s_branch_2,
		s_load_imm_1,
		s_load_imm_2,
		s_load_abs_1,
		s_load_abs_2,
		s_load_abs_3,
		s_load_abs_4,
		s_load_ind_1,
		s_load_ind_2,
		s_load_ind_3,
		s_load_rel_1,
		s_load_rel_2,
		s_load_rel_3,
		s_load_rel_4,
		s_store_abs_1,
		s_store_abs_2,
		s_store_abs_3,
		s_store_abs_4,
		s_store_ind_1,
		s_store_ind_2,
		s_store_ind_3,
		s_store_rel_1,
		s_store_rel_2,
		s_store_rel_3,
		s_store_rel_4,
		s_alu_imm_1,
		s_alu_imm_2,
		s_alu_reg,
		s_push_1,
		s_push_2,
		s_pop_1,
		s_pop_2,
		s_jmp_imm_1,
		s_jmp_imm_2,
		s_jsr_1,
		s_jsr_2,
		s_jsr_3,
		s_jsr_4,
		s_ret_1,
		s_ret_2,
		s_ret_3,
		s_int_1,
		s_int_2,
		s_rti_1,
		s_rti_2,
		s_rti_3,
		s_rti_4,
		s_rti_5,
		s_halted
	);
	type reg_file_type is array(0 to 15) of unsigned(31 downto 0);
	
	component alu is
		port (
			operand_1 : in std_logic_vector(31 downto 0);
			operand_2 : in std_logic_vector(31 downto 0);
			mode : in std_logic_vector(3 downto 0);
			flags_in : in std_logic_vector(3 downto 0);
			result : out std_logic_vector(31 downto 0);
			flags_out : out std_logic_vector(3 downto 0)
		);
	end component;
	
	component random is
		port (
			clock	: in std_logic;
			reset : in std_logic;
			seed : in std_logic_vector(31 downto 0);
			seed_write : in std_logic;
			rand : out std_logic_vector(31 downto 0)
		);
	end component;
	
	-- Registers
	signal state : state_type;
	signal reg_file : reg_file_type;
	signal instr : unsigned(31 downto 0);
	signal pc : unsigned(31 downto 0);
	signal status : std_logic_vector(4 downto 0);
	signal cache : unsigned(31 downto 0);
	signal interrupt_enable : std_logic_vector(7 downto 0);
	signal interrupt_flags : std_logic_vector(7 downto 0);
	
	-- CPU signals
	signal data : std_logic_vector(31 downto 0);
	
	-- ALU signals
	signal alu_op_1 : std_logic_vector(31 downto 0);
	signal alu_op_2 : std_logic_vector(31 downto 0);
	signal alu_mode : std_logic_vector(3 downto 0);
	signal alu_result : std_logic_vector(31 downto 0);
	signal alu_flags : std_logic_vector(3 downto 0);
	
	-- Rand signals
	signal random_seed_write : std_logic;
	signal random_value : std_logic_vector(31 downto 0);
	
	-- Aliases
	alias opcode is instr(31 downto 24);
	alias source_reg is instr(23 downto 20);
	alias operand_reg is instr(19 downto 16);
	alias indexed_pre_post is instr(15);
	alias indexed_increment is instr(14);
	alias indexed_decrement is instr(13);
	alias sp is reg_file(15);
	alias flag_i is status(4);
	alias flag_z is status(3);
	alias flag_c is status(2);
	alias flag_n is status(1);
	alias flag_v is status(0);
	alias arithmetic_flags is status(3 downto 0);
begin
	arithmetic : alu
		port map (
			operand_1 => alu_op_1,
			operand_2 => alu_op_2,
			mode => alu_mode,
			flags_in => arithmetic_flags,
			result => alu_result,
			flags_out => alu_flags
		);
		
	rand : random
		port map (
			clock => clock,
			reset => reset,
			seed => data_out,
			seed_write => random_seed_write,
			rand => random_value
		);

	alu_op_1 <= std_logic_vector(reg_file(to_integer(source_reg)));
	alu_op_2 <= 
		std_logic_vector(to_unsigned(1, 32)) when opcode >= 16#3E# and opcode <= 16#3F#
		else data when state = s_alu_imm_2
		else std_logic_vector(reg_file(to_integer(operand_reg)));
	alu_mode <=
		std_logic_vector(to_unsigned((to_integer(opcode) - 16#26#) / 2, 4)) when opcode >= 16#26# and opcode <= 16#3B#
		else std_logic_vector(to_unsigned(3, 4)) when opcode = 16#3C# or opcode = 16#3D# or opcode = 16#3F#
		else std_logic_vector(to_unsigned(1, 4)) when opcode = 16#3E#
		else x"0";
		
	data <=
		x"000000" & interrupt_enable when address = x"00020000"
		else x"000000" & interrupt_flags when address = x"00020004"
		else random_value when address = x"00020008"
		else data_in;
	
	data_out <= -- Todo: Could be re-organized like data_mask to not repeat as much
		std_logic_vector(shift_left(reg_file(to_integer(source_reg)), (3 - to_integer(unsigned(address(1 downto 0)))) * 8)) 
			when (opcode = to_unsigned(16#1C#, 8) or opcode = to_unsigned(16#1F#, 8) or opcode = to_unsigned(16#22#, 8)) 
				and (state = s_store_abs_4 or state = s_store_ind_3 or state = s_store_rel_4)
		else std_logic_vector(shift_left(reg_file(to_integer(source_reg)), (2 - to_integer(unsigned(address(1 downto 1) & '0'))) * 8)) 
			when (opcode = to_unsigned(16#1D#, 8) or opcode = to_unsigned(16#20#, 8) or opcode = to_unsigned(16#23#, 8)) 
				and (state = s_store_abs_4 or state = s_store_ind_3 or state = s_store_rel_4)
		else std_logic_vector(reg_file(to_integer(source_reg))) 
			when ((opcode = to_unsigned(16#1E#, 8) or opcode = to_unsigned(16#21#, 8) or opcode = to_unsigned(16#24#, 8)) 
				and (state = s_store_abs_4 or state = s_store_ind_3 or state = s_store_rel_4)) or state = s_push_2
		else 
			std_logic_vector(pc) when state = s_jsr_4 or state = s_interrupt_4
		else
			x"000000" & "000" & status when state = s_interrupt_2
		else x"00000000";

	data_mask <=
		"1111" when not (state = s_load_abs_3 or state = s_load_abs_4 or state = s_store_abs_3 or state = s_store_abs_4 or state = s_load_ind_2 
			or state = s_load_ind_3 or state = s_store_ind_2 or state = s_store_ind_3 or state = s_load_rel_3 or state = s_load_rel_4
			or state = s_store_rel_3 or state = s_store_rel_4)
		else std_logic_vector(shift_right(to_unsigned(2#1000#, 4), to_integer(unsigned(address(1 downto 0)))))
			when opcode = to_unsigned(16#13#, 8) or opcode = to_unsigned(16#16#, 8) or opcode = to_unsigned(16#19#, 8) 
				or opcode = to_unsigned(16#1C#, 8) or opcode = to_unsigned(16#1F#, 8) or opcode = to_unsigned(16#22#, 8)
		else std_logic_vector(shift_right(to_unsigned(2#1100#, 4), to_integer(unsigned(address(1 downto 1) & '0'))))
			when opcode = to_unsigned(16#14#, 8) or opcode = to_unsigned(16#17#, 8) or opcode = to_unsigned(16#1A#, 8) 
				or opcode = to_unsigned(16#1D#, 8) or opcode = to_unsigned(16#20#, 8) or opcode = to_unsigned(16#23#, 8)
		else "1111";
	
	write_en <=
		'1' when state = s_store_abs_4 or state = s_push_2 or state = s_jsr_4 or state = s_store_ind_3 or state = s_interrupt_2 or state = s_interrupt_4 
			or state = s_store_rel_4 
		else '0';
	
	address <=
		std_logic_vector(cache) when state = s_load_abs_3 or state = s_load_abs_4 or state = s_store_abs_3 or state = s_store_abs_4
		else std_logic_vector(sp) when state = s_push_1 or state = s_push_2 or state = s_pop_1 or state = s_pop_2 or state = s_jsr_3 or state = s_jsr_4 
			or state = s_ret_2 or state = s_ret_3 or state = s_interrupt_1 or state = s_interrupt_2 or state = s_interrupt_3 or state = s_interrupt_4
			or state = s_rti_2 or state = s_rti_3 or state = s_rti_4 or state = s_rti_5 
		else std_logic_vector(reg_file(to_integer(operand_reg))) 
			when state = s_load_ind_2 or state = s_load_ind_3 or state = s_store_ind_2 or state = s_store_ind_3
		else std_logic_vector(reg_file(to_integer(operand_reg)) + cache) 
			when state = s_load_rel_3 or state = s_load_rel_4 or state = s_store_rel_3 or state = s_store_rel_4
		else std_logic_vector(pc);
	
	random_seed_write <= '1' when write_en = '1' and address = x"00020008" else '0';
	
	reset_int <= '1' when state = s_reset else '0';
	
	process(all)
		variable done : boolean;
		variable interrupts : std_logic_vector(7 downto 0);
		variable interrupt : integer range 0 to interrupts'length - 1;
		
		procedure index_inc_dec (
			pre_post : in std_ulogic
		) is
			begin
				if indexed_pre_post = pre_post then
					if indexed_increment = '1' then
						case to_integer(opcode) is
							when 16#16# | 16#1F# => -- LDB/STB
								reg_file(to_integer(operand_reg)) <= reg_file(to_integer(operand_reg)) + to_unsigned(1, 32);
							when 16#17# | 16#20# => -- LDW/STW
								reg_file(to_integer(operand_reg)) <= reg_file(to_integer(operand_reg)) + to_unsigned(2, 32);
							when 16#18# | 16#21# => -- LDR/STR
								reg_file(to_integer(operand_reg)) <= reg_file(to_integer(operand_reg)) + to_unsigned(4, 32);
							when others => null; -- Illegal state
						end case;
					elsif indexed_decrement = '1' then
						case to_integer(opcode) is
							when 16#16# | 16#1F# => -- LDB/STB
								reg_file(to_integer(operand_reg)) <= reg_file(to_integer(operand_reg)) - to_unsigned(1, 32);
							when 16#17# | 16#20# => -- LDW/STW
								reg_file(to_integer(operand_reg)) <= reg_file(to_integer(operand_reg)) - to_unsigned(2, 32);
							when 16#18# | 16#21# => -- LDR/STR
								reg_file(to_integer(operand_reg)) <= reg_file(to_integer(operand_reg)) - to_unsigned(4, 32);
							when others => null; -- Illegal state
						end case;
					end if;
				end if;
			end procedure;
	begin
		if reset = '1' then
			state <= s_decode_1;
			for i in 0 to 15 loop
				reg_file(i) <= x"00000000";
			end loop;
			instr <= x"00000000";
			pc <= x"00000000";
			status <= "00000";
			cache <= x"00000000";
			interrupt_enable <= x"00";
			interrupt_flags <= x"00";
		else
			if rising_edge(clock) then
				interrupts := interrupt_flags or int_in;
				
				if write_en = '1' and address = x"00020000" then
					interrupt_enable <= data_out(7 downto 0);
				end if;
				
				if write_en = '1' and address = x"00020004" then
					interrupts := data_out(7 downto 0);
				end if;
				
				case state is
					-- Decode instuction 1
					when s_decode_1 => 
						if interrupts(0) = '1' then
							state <= s_reset;
						elsif ((interrupts and interrupt_enable) > x"00" and status(4) = '1') or interrupts(1) = '1' then
							interrupt := 0;
							for i in 1 to interrupts'length - 1 loop
								if interrupts(i) = '1' and (interrupt_enable(i) = '1' or i = 1) then
									interrupt := i;
								end if;
							end loop;
							interrupts(interrupt) := '0';
							cache <= resize(to_unsigned(interrupt, 32) * 8, 32);
							state <= s_interrupt_1;
						else
							state <= s_decode_2;
						end if;
					
					-- Decode instuction 2
					when s_decode_2 =>
						instr <= unsigned(data);
						pc <= pc + 4;
						case to_integer(unsigned(data(31 downto 24))) is
							when 16#00# => state <= s_decode_1; -- NOP
							when 16#01# to 16#0F# => state <= s_branch_1; -- Branch instructions
							when 16#12# => state <= s_load_imm_1; -- Load immediate
							when 16#13# to 16#15# => state <= s_load_abs_1; -- Absolute load instructions
							when 16#16# to 16#18# => state <= s_load_ind_1; -- Indexed load instructions
							when 16#19# to 16#1B# => state <= s_load_rel_1; -- Relative load instructions
							when 16#1C# to 16#1E# => state <= s_store_abs_1; -- Absolute store instructions
							when 16#1F# to 16#21# => state <= s_store_ind_1; -- Indexed store instructions
							when 16#22# to 16#24# => state <= s_store_rel_1; -- Relative store instructions
							when 16#25# => -- TFR
								reg_file(to_integer(unsigned(data(23 downto 20)))) <= reg_file(to_integer(unsigned(data(19 downto 16))));
								state <= s_decode_1;
							when 16#26# to 16#3F# => -- ALU instructions
								if data(24) = '1' or data(31 downto 24) = x"3E" or data(31 downto 24) = x"3F" then
									state <= s_alu_reg;
								else
									state <= s_alu_imm_1;
								end if;
							when 16#40# => -- SEI
								flag_i <= '1';
								state <= s_decode_1;
							when 16#41# => -- CLI
								flag_i <= '0';
								state <= s_decode_1;
							when 16#42# => -- SEC
								flag_c <= '1';
								state <= s_decode_1;
							when 16#43# => -- CLC
								flag_c <= '0';
								state <= s_decode_1;
							when 16#44# => state <= s_push_1; -- PUSH
							when 16#45# =>
								sp <= sp - 4;
								state <= s_pop_1; -- POP
							when 16#46# => state <= s_jmp_imm_1; -- JMP imm
							when 16#47# => -- JMP reg
								pc <= reg_file(to_integer(unsigned(data(23 downto 20))));
								state <= s_decode_1;
							when 16#48# => state <= s_jsr_1; -- JSR
							when 16#49# => state <= s_ret_1; -- RET
							when 16#4A# => state <= s_int_1; -- INT
							when 16#4B# => state <= s_rti_1; -- RTI
							when 16#4C# => state <= s_halted; -- HALT
							when others => state <= s_decode_1; -- Illegal instructions, treat as NOP for now
						end case;
					
					-- Branch instructions 1
					-- Todo: This could be replaced with one giant if statement if desired
					when s_branch_1 =>
						done := true;
						case opcode is
							when x"01" => -- BEQ
								if flag_z = '1' then
									done := false;
								end if;
							when x"02" => -- BNE
								if flag_z = '0' then
									done := false;
								end if;
							when x"03" => -- BHS
								if flag_c = '1' then
									done := false;
								end if;
							when x"04" => -- BLO
								if flag_c = '0' then
									done := false;
								end if;
							when x"05" => -- BMI
								if flag_n = '1' then
									done := false;
								end if;
							when x"06" => -- BPL
								if flag_n = '0' then
									done := false;
								end if;
							when x"07" => -- BVS
								if flag_v = '1' then
									done := false;
								end if;
							when x"08" => -- BVC
								if flag_v = '0' then
									done := false;
								end if;
							when x"09" => -- BHI
								if flag_c = '1' and flag_z = '0' then
									done := false;
								end if;
							when x"0A" => -- BLS
								if flag_c = '0' or flag_z = '1' then
									done := false;
								end if;
							when x"0B" => -- BGE
								if flag_n = flag_v then
									done := false;
								end if;
							when x"0C" => -- BLT
								if flag_n /= flag_v then
									done := false;
								end if;
							when x"0D" => -- BGT
								if flag_z = '0' and flag_n = flag_v then
									done := false;
								end if;
							when x"0E" => -- BLE
								if flag_z = '1' or flag_n /= flag_v then
									done := false;
								end if;
							when x"0F" => -- BRA
								done := false;
							when others => null; -- Illegal state
						end case;
						if done then
							pc <= pc + 4;
							state <= s_decode_1;
						else
							state <= s_branch_2;
						end if;
					
					-- Interrupt 1
					when s_interrupt_1 => state <= s_interrupt_2;
					
					-- Interrupt 2
					when s_interrupt_2 => 
						sp <= sp + 4;
						state <= s_interrupt_3;
					
					-- Interrupt 3
					when s_interrupt_3 => state <= s_interrupt_4;
					
					-- Interrupt 4
					when s_interrupt_4 => 
						sp <= sp + 4;
						state <= s_interrupt_5;
					
					-- Interrupt 5
					when s_interrupt_5 => 
						pc <= cache;
						state <= s_decode_1;
					
					-- Reset
					when s_reset => state <= s_reset;
					
					-- Branch instructions 2
					when s_branch_2 =>
						pc <= pc + unsigned(resize(signed(data), 32)) + to_unsigned(4, 32);
						state <= s_decode_1;
					
					-- Load immediate 1
					when s_load_imm_1 => state <= s_load_imm_2;
					
					-- Load immediate 2
					when s_load_imm_2 =>
						reg_file(to_integer(source_reg)) <= unsigned(data);
						if data = x"00000000" then
							flag_z <= '1';
						else
							flag_z <= '0';
						end if;
						pc <= pc + 4;
						state <= s_decode_1;
					
					-- Load absolute 1
					when s_load_abs_1 => state <= s_load_abs_2;
					
					-- Load absolute 2
					when s_load_abs_2 =>
						cache <= unsigned(data);
						pc <= pc + 4;
						state <= s_load_abs_3;
					
					-- Load absolute 3
					when s_load_abs_3 => state <= s_load_abs_4;
					
					-- Load indexed 1
					when s_load_ind_1 => 
						index_inc_dec('0');
						state <= s_load_ind_2;
					
					-- Load indexed 2
					when s_load_ind_2 => state <= s_load_ind_3;
					
					-- Load relative 1
					when s_load_rel_1 => state <= s_load_rel_2;
					
					-- Load relative 2
					when s_load_rel_2 =>
						cache <= unsigned(data);
						pc <= pc + 4;
						state <= s_load_rel_3;
					
					-- Load relative 3
					when s_load_rel_3 => state <= s_load_rel_4;
					
					-- Load value
					when s_load_abs_4 | s_load_ind_3 | s_load_rel_4 =>
						case to_integer(opcode) is
							when 16#13# | 16#16# | 16#19# =>
								reg_file(to_integer(source_reg)) <= shift_right(unsigned(data), (3 - to_integer(unsigned(address(1 downto 0)))) * 8);
							when 16#14# | 16#17# | 16#1A# =>
								reg_file(to_integer(source_reg)) <= shift_right(unsigned(data), to_integer(unsigned((not address(1 downto 1)) & '0')) * 8);
							when 16#15# | 16#18# | 16#1B# =>
								reg_file(to_integer(source_reg)) <= unsigned(data);
							when others => null; -- Illegal state
						end case;
						
						if data = x"00000000" then
							flag_z <= '1';
						else
							flag_z <= '0';
						end if;
						
						if state = s_load_ind_3 then
							index_inc_dec('1');
						end if;
						
						state <= s_decode_1;
					
					-- Store absolute 1
					when s_store_abs_1 => state <= s_store_abs_2;
					
					-- Store absolute 2
					when s_store_abs_2 =>
						cache <= unsigned(data);
						pc <= pc + 4;
						state <= s_store_abs_3;
					
					-- Store absolute 3
					when s_store_abs_3 => state <= s_store_abs_4;
					
					-- Store absolute 4
					when s_store_abs_4 => state <= s_decode_1;
					
					-- Store indexed 1
					when s_store_ind_1 => 
						index_inc_dec('0');
						state <= s_store_ind_2;
					
					-- Store indexed 2
					when s_store_ind_2 =>
						state <= s_store_ind_3;
					
					-- Store indexed 3
					when s_store_ind_3 => 
						index_inc_dec('1');
						state <= s_decode_1;
					
					-- Store relative 1
					when s_store_rel_1 => state <= s_store_rel_2;
					
					-- Store relative 2
					when s_store_rel_2 =>
						cache <= unsigned(data);
						pc <= pc + 4;
						state <= s_store_rel_3;
					
					-- Store relative 3
					when s_store_rel_3 => state <= s_store_rel_4;
					
					-- Store relative 4
					when s_store_rel_4 => state <= s_decode_1;
					
					-- ALU register
					when s_alu_reg =>
						if opcode /= x"3D" then
							reg_file(to_integer(source_reg)) <= unsigned(alu_result);
						end if;
						arithmetic_flags <= alu_flags;
						state <= s_decode_1;
					
					-- ALU immediate 1
					when s_alu_imm_1 => state <= s_alu_imm_2;
					
					-- ALU immediate 2
					when s_alu_imm_2 =>
						if opcode /= x"3C" then
							reg_file(to_integer(source_reg)) <= unsigned(alu_result);
						end if;
						arithmetic_flags <= alu_flags;
						pc <= pc + 4;
						state <= s_decode_1;
					
					-- PUSH 1
					when s_push_1 => state <= s_push_2;
					
					-- PUSH 2
					when s_push_2 => 
						sp <= sp + 4;
						state <= s_decode_1;
					
					-- POP 1
					when s_pop_1 => state <= s_pop_2;
					
					-- POP 2
					when s_pop_2 =>
						reg_file(to_integer(source_reg)) <= unsigned(data);
						state <= s_decode_1;
					
					-- JMP immediate 1
					when s_jmp_imm_1 => state <= s_jmp_imm_2;
					
					-- JMP immediate 1
					when s_jmp_imm_2 => 
						pc <= unsigned(data);
						state <= s_decode_1;
					
					-- JSR 1
					when s_jsr_1 => state <= s_jsr_2;
					
					-- JSR 2
					when s_jsr_2 =>
						cache <= unsigned(data);
						pc <= pc + 4;
						state <= s_jsr_3;
					
					-- JSR 3
					when s_jsr_3 => state <= s_jsr_4;
					
					-- JSR 4
					when s_jsr_4 =>
						sp <= sp + 4;
						pc <= cache;
						state <= s_decode_1;
					
					-- RET 1
					when s_ret_1 => 
						sp <= sp - 4;
						state <= s_ret_2;
					
					-- RET 2
					when s_ret_2 => state <= s_ret_3;
					
					-- RET 3
					when s_ret_3 =>
						pc <= unsigned(data);
						state <= s_decode_1;
					
					-- INT 1
					when s_int_1 => state <= s_int_2;
					
					-- INT 2
					when s_int_2 =>
						interrupts := interrupts or std_logic_vector(shift_left(to_unsigned(1, 8), to_integer(unsigned(data))));
						pc <= pc + 4;
						state <= s_decode_1;
					
					-- RTI 1
					when s_rti_1 => 
						sp <= sp - 4;
						state <= s_rti_2;
					
					-- RTI 2
					when s_rti_2 => state <= s_rti_3;
					
					-- RTI 3
					when s_rti_3 => 
						pc <= unsigned(data);
						sp <= sp - 4;
						state <= s_rti_4;
					
					-- RTI 4
					when s_rti_4 => state <= s_rti_5;
					
					-- RTI 5
					when s_rti_5 => 
						status <= data(4 downto 0);
						state <= s_decode_1;
					
					-- Halted
					when s_halted => state <= s_halted;
				end case;
				
				interrupt_flags <= interrupts;
			end if;
		end if;
	end process;
end architecture;
