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
		timer_int : out std_logic;
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
	type adc_array is array (0 to 5) of std_logic_vector(11 downto 0);
	type pwm_duty_array is array (0 to 7) of std_logic_vector(7 downto 0);
	type timer_prescale_array is array (0 to 7) of std_logic_vector(15 downto 0);
	type timer_count_array is array (0 to 7) of std_logic_vector(31 downto 0);

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
	
	component adc is
		port (
			clock : in std_logic := '0';
			ch0 : out std_logic_vector(11 downto 0);
			ch1 : out std_logic_vector(11 downto 0);
			ch2 : out std_logic_vector(11 downto 0);
			ch3 : out std_logic_vector(11 downto 0);
			ch4 : out std_logic_vector(11 downto 0);
			ch5 : out std_logic_vector(11 downto 0);
			ch6 : out std_logic_vector(11 downto 0);
			ch7 : out std_logic_vector(11 downto 0);
			reset : in std_logic := '0'
		);
	end component;
	
	-- Uart signals
	signal uart_available : std_logic_vector(7 downto 0);
	signal uart_received : std_logic_vector(7 downto 0);
	signal uart_tx : std_logic;
	signal uart_write : std_logic;
	signal uart_pop : std_logic;
	signal uart_full : std_logic;
	
	signal adc_states : adc_array;
	signal pwm_count : unsigned(7 downto 0);
	signal pwm_states : std_logic_vector(7 downto 0);
	signal timer_ticks : timer_prescale_array;
	signal timer_if_write : std_logic;
	signal timer_rollover : std_logic_vector(7 downto 0);
	
	-- Registers
	signal seg7_states : seg7_array;
	signal arduino_states : std_logic_vector(15 downto 0);
	signal arduino_modes : std_logic_vector(15 downto 0);
	signal gpio_states : std_logic_vector(35 downto 0);
	signal gpio_modes : std_logic_vector(35 downto 0);
	signal uart_enable : std_logic;
	signal pwm_enable : std_logic_vector(7 downto 0);
	signal pwm_duty : pwm_duty_array;
	signal timer_ie : std_logic_vector(7 downto 0);
	signal timer_if : std_logic_vector(7 downto 0);
	signal timer_repeat : std_logic_vector(7 downto 0);
	signal timer_enable : std_logic_vector(7 downto 0);
	signal timer_counts : timer_count_array;
	signal timer_compares : timer_count_array;
	signal timer_prescales : timer_prescale_array;
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
	
	adc_driver : adc
		port map (
			clock => clock,
			reset => reset,
			ch0 => adc_states(0),
			ch1 => adc_states(1),
			ch2 => adc_states(2),
			ch3 => adc_states(3),
			ch4 => adc_states(4),
			ch5 => adc_states(5)
		);
	
	-- PWM state logic
	pwm_logic : for i in 0 to 7 generate
		pwm_states(i) <= '1' when pwm_duty(i) = x"FF" or unsigned(pwm_count) < unsigned(pwm_duty(i)) else '0';
	end generate;
	
	-- Timer interrupt flag logic
	process(all)
	begin
		if reset = '1' then
			timer_if <= x"00";
		elsif rising_edge(clock) then
			if timer_if_write = '1' then
				timer_if <= data_in(7 downto 0);
			else
				timer_if <= timer_if or timer_rollover;
			end if;
		end if;
	end process;
	
	timer_int <= '1' when (timer_if and timer_ie) /= 8x"0" else '0';
	
	-- Timer logic
	timer_logic : for i in 0 to 7 generate
		process(all)
			variable index : integer;
		begin
			index := (to_integer(unsigned(address)) - 16#40000#) / 4;
			
			if reset = '1' then
				timer_enable(i) <= '0';
				timer_counts(i) <= 32x"0";
				timer_ticks(i) <= 16x"0";
				timer_rollover(i) <= '0';
			elsif rising_edge(clock) then
				if write_en = '1' and index = 168 + i then
					timer_counts(i) <= data_in;
					timer_rollover(i) <= '0';
				elsif write_en = '1' and index = 184 + i then
					if data_in = 32x"0" then
						timer_enable(i) <= '0';
					else
						timer_enable(i) <= '1';
					end if;
					timer_rollover(i) <= '0';
				elsif timer_enable(i) = '1' then
					if timer_counts(i) = timer_compares(i) then
						timer_counts(i) <= 32x"0";
						timer_rollover(i) <= '1';
						if timer_repeat(i) = '0' then
							timer_enable(i) <= '0';
						end if;
					else
						if unsigned(timer_ticks(i)) >= unsigned(timer_prescales(i)) - 1 then
							timer_counts(i) <= std_logic_vector(unsigned(timer_counts(i)) + 1);
							timer_ticks(i) <= 16x"0";
						else
							timer_ticks(i) <= std_logic_vector(unsigned(timer_ticks(i)) + 1);
						end if;
						timer_rollover(i) <= '0';
					end if;
				end if;
			end if;
		end process;
	end generate;
	
	-- Port read logic
	process(all)
		variable index : integer;
	begin
		index := (to_integer(unsigned(address)) - 16#40000#) / 4;
		
		case index is
			when 0 to 9 => data_out <= 31x"0" & leds(index);
         when 10 to 15 => data_out <= 28x"0" & seg7_states(index - 10);
			when 16 to 51 => data_out <= 31x"0" & gpio(index - 16);
			when 52 to 87 => data_out <= 31x"0" & gpio_modes(index - 52);
			when 88 to 103 => data_out <= 31x"0" & arduino(index - 88);
			when 104 to 119 => data_out <= 31x"0" & arduino_modes(index - 104);
			when 120 to 129 => data_out <= 31x"0" & switches(index - 120);
			when 130 to 131 => data_out <= 31x"0" & not buttons(index - 130);
			when 132 => data_out <= 24x"0" & uart_received;
			when 133 => data_out <= 24x"0" & uart_available;
			when 134 => data_out <= 31x"0" & uart_full;
			when 135 => data_out <= 31x"0" & uart_enable;
			when 136 to 141 => data_out <= 20x"0" & adc_states(index - 136);
			when 142 to 149 => data_out <= 31x"0" & pwm_enable(index - 142);
			when 150 to 157 => data_out <= 24x"0" & pwm_duty(index - 150);
			when 158 => data_out <= 24x"0" & timer_ie;
			when 159 => data_out <= 24x"0" & timer_if;
			when 160 to 167 => data_out <= 31x"0" & timer_repeat(index - 160);
			when 168 to 175 => data_out <= timer_counts(index - 168);
			when 176 to 183 => data_out <= 16x"0" & timer_prescales(index - 176);
			when 184 to 191 => data_out <= 31x"0" & timer_enable(index - 184);
			when 192 to 199 => data_out <= timer_compares(index - 192);
			when others => data_out <= 32x"0";
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
			pwm_count <= x"00";
			timer_ie <= x"00";
			timer_repeat <= x"00";
			for i in 0 to 7 loop
				timer_prescales(i) <= 16x"1";
				timer_compares(i) <= 32x"0";
			end loop;
		elsif rising_edge(clock) then
			pwm_count <= pwm_count + 1;
			
			if write_en = '1' then
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
					when 142 to 149 => pwm_enable(index - 142) <= bool;
					when 150 to 157 => pwm_duty(index - 150) <= data_in(7 downto 0);
					when 158 => timer_ie <= data_in(7 downto 0);
					when 160 to 167 => timer_repeat(index - 160) <= bool;
					when 176 to 183 => timer_prescales(index - 176) <= data_in(15 downto 0);
					when 192 to 199 => timer_compares(index - 192) <= data_in;
					when others => null;
				end case;
			end if;
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
	
		if index = 159 and write_en = '1' then
			timer_if_write <= '1';
		else
			timer_if_write <= '0';
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
				if i < 8 and pwm_enable(i) = '1' then
					gpio(i) <= pwm_states(i);
				else
					gpio(i) <= gpio_states(i);
				end if;
			else
				gpio(i) <= 'Z';
			end if;
		end loop;
	end process;
end architecture;
