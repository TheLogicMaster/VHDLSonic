-- Debug interface

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity debug is
	port (
		clock : in std_logic;
		reset : in std_logic;
		pc : in std_logic_vector(31 downto 0);
		debug_reset : out std_logic;
		paused : buffer std_logic
	);
end entity;

architecture impl of debug is
	type breakpoint_array is array (0 to 4) of std_logic_vector(31 downto 0);

	function hex_char_to_int(hex : std_logic_vector(7 downto 0)) return unsigned is
	begin
		if unsigned(hex) <= character'pos('9') then
			return unsigned(hex) - character'pos('0');
		else
			return unsigned(hex) - character'pos('a') + 10;
		end if;
	end function;	

	-- https://github.com/schoeberl/fpga-stuff/blob/13b6cc13011be78ed38d2751e9ef693bf33100c5/jtag_com/jtag_com.vhd#L19
	component alt_jtag_atlantic is
		generic (
			INSTANCE_ID : integer;
			LOG2_RXFIFO_DEPTH : integer;
			LOG2_TXFIFO_DEPTH : integer;
			SLD_AUTO_INSTANCE_INDEX : string
		);
		port (
			clk : in std_logic;
			rst_n : in std_logic;
			-- the signal names are a little bit strange
			r_dat : in std_logic_vector(7 downto 0); -- data from FPGA
			r_val : in std_logic; -- data valid
			r_ena : out std_logic; -- can write (next) cycle, or FIFO not full?
			t_dat : out std_logic_vector(7 downto 0); -- data to FPGA
			t_dav : in std_logic; -- ready to receive more data
			t_ena : out std_logic; -- tx data valid
			t_pause : out std_logic -- ???
		);
	end component alt_jtag_atlantic;	

	signal reset_n : std_logic;
	signal received_char : std_logic_vector(7 downto 0);
	signal received_valid : std_logic;
	signal state : integer range 0 to 14;
	signal breakpoint_index : integer range 0 to 4;
	signal breakpoint_address : std_logic_vector(31 downto 0);
	signal breakpoints : breakpoint_array;
	signal last_broken_address : std_logic_vector(31 downto 0); -- The last triggered breakpoint's address
	signal waiting : boolean; -- Waiting for PC to change
	signal stepping : boolean; -- Stepping to the next instruction
begin
	reset_n <= not reset;
	
	jtag_inst : component alt_jtag_atlantic
		generic map (
			INSTANCE_ID => 0,
			LOG2_RXFIFO_DEPTH => 3,
			LOG2_TXFIFO_DEPTH => 3,
			SLD_AUTO_INSTANCE_INDEX => "YES"
		)
		port map (
			clk => clock,
			rst_n => reset_n,
			r_dat => x"00",
			r_val => '0',
			t_dat => received_char,
			t_dav => '1',
			t_ena => received_valid
		);
	
	process(all)
		variable new_address : std_logic_vector(31 downto 0);
		variable new_waiting : boolean;
		variable broken : boolean;
	begin
		if reset = '1' then
			paused <= '0';
			state <= 0;
			debug_reset <= '0';
			breakpoint_index <= 0;
			breakpoint_address <= 32x"0";
			last_broken_address <= 32x"0";
			waiting <= false;
			stepping <= false;
		elsif rising_edge(clock) then
			if received_valid = '1' then
				case state is
					when 0 to 4 => -- Check for magic value
						if received_char = x"69" then
							state <= state + 1;
						else
							state <= 0;
						end if;
					when 5 => -- Determine command
						if to_integer(unsigned(received_char)) = character'pos('R') then -- Reset
							debug_reset <= '1';
							state <= 0;
						elsif to_integer(unsigned(received_char)) = character'pos('C') then -- Continue
							waiting <= true;
							last_broken_address <= pc;
							paused <= '0';
							state <= 0;
						elsif to_integer(unsigned(received_char)) = character'pos('B') then -- Breakpoint
							state <= state + 1;
						elsif to_integer(unsigned(received_char)) = character'pos('S') then -- Step
							stepping <= true;
							waiting <= true;
							last_broken_address <= pc;
							paused <= '0';
							state <= 0;
						elsif to_integer(unsigned(received_char)) = character'pos('P') then -- Pause
							paused <= '1';
							state <= 0;
						else
							state <= 0;
						end if;
					when 6 => -- Get breakpoint index
						breakpoint_index <= to_integer(hex_char_to_int(received_char));
						breakpoint_address <= 32x"0";
						state <= state + 1;
					when 7 to 14 => -- Get breakpoint address
						new_address := breakpoint_address or std_logic_vector(shift_left(resize(hex_char_to_int(received_char), 32), 4 * (state - 7)));
						breakpoint_address <= new_address;
						if state < 14 then
							state <= state + 1;
						else
							breakpoints(breakpoint_index) <= new_address;
							state <= 0;
						end if;
					when others => state <= 0;
				end case;
			else
				new_waiting := waiting;
				if last_broken_address /= pc then
					new_waiting := false;
				end if;
				waiting <= new_waiting;
				
				if not new_waiting then
					broken := stepping;
					for i in 0 to 4 loop
						if breakpoints(i) = pc and breakpoints(i) /= 32x"0" then
							broken := true;
						end if;
					end loop;
					if broken then
						paused <= '1';
						stepping <= false;
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture;
