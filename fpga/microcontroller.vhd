-- Computer Microcontroller interface

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity microcontroller is
	port (
		address : in std_logic_vector(31 downto 0);
		write_en : in std_logic;
		clock : in std_logic;
		reset : in std_logic;
		data_in : in std_logic_vector(31 downto 0);
		data_out : out std_logic_vector(31 downto 0);
		buttons : in std_logic_vector(1 downto 0);
		switches : in std_logic_vector(9 downto 0);
		gpio : inout std_logic_vector(35 downto 0);
		arduino : inout std_logic_vector(15 downto 0);
		leds : buffer std_logic_vector(9 downto 0);
		hex0 : out std_logic_vector(7 downto 0);
		hex1 : out std_logic_vector(7 downto 0);
		hex2 : out std_logic_vector(7 downto 0);
		hex3 : out std_logic_vector(7 downto 0);
		hex4 : out std_logic_vector(7 downto 0);
		hex5 : out std_logic_vector(7 downto 0)
	);
end entity;

architecture impl of microcontroller is
	type seg7_array is array (0 to 5) of std_logic_vector(3 downto 0);

	component seg7 is
		port (
			digit : in std_logic_vector(3 downto 0);
			segments: out std_logic_vector(7 downto 0)
		);
	end component;
	
	component uart_controller is
		port (
			clock : in std_logic;
			reset : in std_logic;
			write_en : in std_logic;
			data : in std_logic_vector(7 downto 0);
			rx : in std_logic;
			pop : in std_logic;
			full : out std_logic;
			tx : out std_logic;
			received : out std_logic_vector(7 downto 0);
			available : out std_logic_vector(7 downto 0)
		);
	end component;
	
	-- Uart signals
	signal uart_available : std_logic_vector(7 downto 0);
	signal uart_received : std_logic_vector(7 downto 0);
	signal uart_tx : std_logic;
	signal uart_write : std_logic;
	signal uart_pop : std_logic;
	signal uart_full : std_logic;
	
	-- Registers
	signal seg7_states : seg7_array;
	signal arduino_states : std_logic_vector(15 downto 0);
	signal arduino_modes : std_logic_vector(15 downto 0);
	signal gpio_states : std_logic_vector(35 downto 0);
	signal gpio_modes : std_logic_vector(35 downto 0);
	signal uart_enable : std_logic;
begin
	seg7_0 : seg7 port map(seg7_states(0), hex0);
	seg7_1 : seg7 port map(seg7_states(1), hex1);
	seg7_2 : seg7 port map(seg7_states(2), hex2);
	seg7_3 : seg7 port map(seg7_states(3), hex3);
	seg7_4 : seg7 port map(seg7_states(4), hex4);
	seg7_5 : seg7 port map(seg7_states(5), hex5);
	
	uart : uart_controller
		port map (
			clock => clock,
			reset => reset,
			write_en => uart_write,
			data => data_in(7 downto 0),
			rx => arduino(0),
			pop => uart_pop,
			full => uart_full,
			tx => uart_tx,
			received => uart_received,
			available => uart_available
		);
	
	-- Port read logic
	process(all)
		variable index : integer;
	begin
		index := (to_integer(unsigned(address)) - 16#40000#) / 4;
		
		case index is
			when 0 to 9 => data_out <= x"0000000" & "000" & leds(index);
         when 10 to 15 => data_out <= x"0000000" & seg7_states(index - 10);
			when 16 to 51 => data_out <= x"0000000" & "000" & gpio(index - 16);
			when 52 to 87 => data_out <= x"0000000" & "000" & gpio_modes(index - 52);
			when 88 to 103 => data_out <= x"0000000" & "000" & arduino(index - 88);
			when 104 to 119 => data_out <= x"0000000" & "000" & arduino_modes(index - 104);
			when 120 to 129 => data_out <= x"0000000" & "000" & switches(index - 120);
			when 130 to 131 => data_out <= x"0000000" & "000" & buttons(index - 130);
			when 132 => data_out <= x"000000" & uart_received;
			when 133 => data_out <= x"000000" & uart_available;
			when 134 => data_out <= x"0000000" & "000" & uart_full;
			when 135 => data_out <= x"0000000" & "000" & uart_enable;
			when others => data_out <= x"00000000";
		end case;
	end process;
	
	-- Clocked write logic
	process(all)
		variable index : integer;
		variable bool : std_logic;
	begin
		if reset = '1' then
			for i in 0 to 5 loop
				seg7_states(i) <= x"0";
			end loop;
			arduino_states <= x"0000";
			arduino_modes <= x"0000";
			gpio_states <= x"000000000";
			gpio_modes <= x"000000000";
			leds <= "0000000000";
		elsif rising_edge(clock) and write_en = '1' then
			if data_in = x"00000000" then
				bool := '0';
			else
				bool := '1';
			end if;
		
			index := (to_integer(unsigned(address)) - 16#40000#) / 4;
		
			case index is
				when 0 to 9 => leds(index) <= bool;
				when 10 to 15 => seg7_states(index - 10) <= data_in(3 downto 0);
				when 16 to 51 => gpio_states(index - 16) <= bool;
				when 52 to 87 => gpio_modes(index - 52) <= bool;
				when 88 to 103 => arduino_states(index - 88) <= bool;
				when 104 to 119 => arduino_modes(index - 104) <= bool;
				when 135 => uart_enable <= bool;
				when others => null;
			end case;
		end if;
	end process;
	
	-- Non-clocked write logic
	process(all)
		variable index : integer;
	begin
		index := (to_integer(unsigned(address)) - 16#40000#) / 4;
		
		if index = 132 and write_en = '1' then
			uart_write <= '1';
		else
			uart_write <= '0';
		end if;
	
		if index = 133 and write_en = '1' then
			uart_pop <= '1';
		else
			uart_pop <= '0';
		end if;
	end process;
	
	-- Arduino/GPIO logic
	process(all)
	begin
		for i in 0 to 15 loop
			if arduino_modes(i) = '1' then
				if i = 1 and uart_enable = '1' then
					arduino(i) <= uart_tx;
				else
					arduino(i) <= arduino_states(i);
				end if;
			else
				arduino(i) <= 'Z';
			end if;
		end loop;
		
		for i in 0 to 35 loop
			if gpio_modes(i) = '1' then
				gpio(i) <= gpio_states(i);
			else
				gpio(i) <= 'Z';
			end if;
		end loop;
	end process;
end architecture;
