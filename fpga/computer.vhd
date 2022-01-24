-- Top level computer entity

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity computer is
	port (
		-- Clocks
		ADC_CLK_10, MAX10_CLK1_50, MAX10_CLK2_50 : in std_logic;

		-- SDRAM
		DRAM_DQ : inout std_logic_vector(15 downto 0);
		DRAM_ADDR : out std_logic_vector(12 downto 0);
		DRAM_BA : out std_logic_vector(1 downto 0);
		DRAM_CAS_N, DRAM_CKE, DRAM_CLK, DRAM_CS_N, DRAM_LDQM, DRAM_RAS_N, DRAM_UDQM, DRAM_WE_N : out std_logic;

		-- Switches
		SW : in std_logic_vector(9 downto 0);

		-- Push buttons
		KEY: in std_logic_vector(1 downto 0);

		-- Seven segment displays
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(7 downto 0);

		-- LEDs
		LEDR : out std_logic_vector(9 downto 0);

		-- VGA
		VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
		VGA_HS, VGA_VS : out std_logic;

		-- Accelerometer
		GSENSOR_INT : in std_logic_vector(2 downto 1);
		GSENSOR_SDI, GSENSOR_SDO : inout std_logic;
		GSENSOR_CS_N, GSENSOR_SCLK : out std_logic;

		-- Arduino
		ARDUINO_IO : inout std_logic_vector(15 downto 0);
		ARDUINO_RESET_N : inout std_logic;

		-- GPIO
		GPIO : inout std_logic_vector(35 downto 0)
	);
end entity;

architecture impl of computer is
	constant USE_LCD : boolean := true;
	constant USE_APU : boolean := true;

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
	
	component memory is
		port (
			address : in std_logic_vector(31 downto 0);
			data_mask : in std_logic_vector(3 downto 0);
			write_en : in std_logic;
			clock : in std_logic;
			data_in : in std_logic_vector(31 downto 0);
			data_out : out std_logic_vector(31 downto 0)
		);
	end component;	

	component microcontroller is
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
			leds : out std_logic_vector(9 downto 0);
			hex0 : out std_logic_vector(7 downto 0);
			hex1 : out std_logic_vector(7 downto 0);
			hex2 : out std_logic_vector(7 downto 0);
			hex3 : out std_logic_vector(7 downto 0);
			hex4 : out std_logic_vector(7 downto 0);
			hex5 : out std_logic_vector(7 downto 0)
		);
	end component;

	component gpu is
		port (
			address : in std_logic_vector(31 downto 0);
			write_en : in std_logic;
			clock : in std_logic;
			reset : in std_logic;
			data_in : in std_logic_vector(31 downto 0);
			data_out : out std_logic_vector(31 downto 0);
			pixel : out std_logic_vector(15 downto 0);
			pixel_x : in std_logic_vector(9 downto 0);
			pixel_y : in std_logic_vector(8 downto 0);
			sprite_index : in std_logic_vector(5 downto 0);
			sprite_cache_index : in std_logic_vector(5 downto 0);
			sprite_cache_write : in std_logic;
			sprite_cache_clear : in std_logic;
			bg_x : in std_logic_vector(9 downto 0);
			bg_y : in std_logic_vector(8 downto 0);
			rendering : out std_logic;
			blanking : in std_logic;
			ticks : in std_logic_vector(1 downto 0)
		);
	end component;							
	
	component vga_driver is
		port (
			clock : in std_logic;
			reset : in std_logic;
			pixel : in std_logic_vector(15 downto 0);
			pixel_x : out std_logic_vector(9 downto 0);
			pixel_y : out std_logic_vector(8 downto 0);
			sprite_index : out std_logic_vector(5 downto 0);
			sprite_cache_index : out std_logic_vector(5 downto 0);
			sprite_cache_write : out std_logic;
			sprite_cache_clear : out std_logic;
			bg_x : out std_logic_vector(9 downto 0);
			bg_y : out std_logic_vector(8 downto 0);
			rendering : in std_logic;
			blanking : out std_logic;
			ticks : out std_logic_vector(1 downto 0);
			vblank : out std_logic;
			hblank : out std_logic;
			vga_r : out std_logic_vector(3 downto 0);
			vga_g : out std_logic_vector(3 downto 0);
			vga_b : out std_logic_vector(3 downto 0);
			vga_hs : out std_logic;
			vga_vs : out std_logic
		);
	end component;
	
	component lcd_driver is
		port (
			clock : in std_logic;
			reset : in std_logic;
			pixel : in std_logic_vector(15 downto 0);
			pixel_x : out std_logic_vector(9 downto 0);
			pixel_y : out std_logic_vector(8 downto 0);
			sprite_index : out std_logic_vector(5 downto 0);
			sprite_cache_index : out std_logic_vector(5 downto 0);
			sprite_cache_write : out std_logic;
			sprite_cache_clear : out std_logic;
			bg_x : out std_logic_vector(9 downto 0);
			bg_y : out std_logic_vector(8 downto 0);
			rendering : in std_logic;
			blanking : out std_logic;
			ticks : out std_logic_vector(1 downto 0);
			vblank : out std_logic;
			hblank : out std_logic;
			lcd_data : out std_logic_vector(7 downto 0);
			lcd_write : out std_logic;
			lcd_command : out std_logic;
			lcd_enable : out std_logic
		);
	end component;						
	
	component apu is
		port (
			address : in std_logic_vector(31 downto 0);
			write_en : in std_logic;
			clock : in std_logic;
			reset : in std_logic;
			data_in : in std_logic_vector(31 downto 0);
			data_out : out std_logic_vector(31 downto 0);
			i2s_bck : buffer std_logic;
			i2s_din : out std_logic;
			i2s_lrck : buffer std_logic
		);
	end component;
	
	component power_on_reset is
		port (
			clock : in std_logic;
			reset_in : in std_logic;
			reset_out : out std_logic
		);
	end component;
	
	signal arduino : std_logic_vector(15 downto 0);
	signal lcd_data : std_logic_vector(7 downto 0);
	signal gpio_pins : std_logic_vector(35 downto 0);
	
	-- GPU signals
	signal gpu_pixel : std_logic_vector(15 downto 0);
	signal gpu_pixel_x : std_logic_vector(9 downto 0);
	signal gpu_pixel_y : std_logic_vector(8 downto 0);
	signal gpu_sprite_index : std_logic_vector(5 downto 0);
	signal gpu_sprite_cache_index : std_logic_vector(5 downto 0);
	signal gpu_sprite_cache_write : std_logic;
	signal gpu_sprite_cache_clear : std_logic;
	signal gpu_bg_x : std_logic_vector(9 downto 0);
	signal gpu_bg_y : std_logic_vector(8 downto 0);
	signal gpu_rendering : std_logic;
	signal gpu_blanking : std_logic;
	signal gpu_ticks : std_logic_vector(1 downto 0);
	
	-- Data bus
	signal cpu_in : std_logic_vector(31 downto 0);
	signal data : std_logic_vector(31 downto 0);
	signal memory_data : std_logic_vector(31 downto 0);
	signal microcontroller_data : std_logic_vector(31 downto 0);
	signal gpu_data : std_logic_vector(31 downto 0);
	signal apu_data : std_logic_vector(31 downto 0);
	signal address : std_logic_vector(31 downto 0); -- Address line
	signal data_mask : std_logic_vector(3 downto 0); -- Data line mask
	signal write_en : std_logic; -- Write enable line
	
	-- Interrupt bus
	signal interrupts : std_logic_vector(7 downto 0);
	signal int_vblank : std_logic;
	signal int_hblank : std_logic;
	signal int_timer : std_logic;
	
	-- Reset system
	signal reset_int : std_logic; -- Reset interrupt
	signal reset : std_logic; -- Reset line
	signal reset_trigger : std_logic; -- Trigger POR reset
	
	-- System clock
	signal clock : std_logic; -- Clock line
begin
	reset_trigger <= (not ARDUINO_RESET_N) or reset_int or (not KEY(0));
	clock <= MAX10_CLK1_50;
	
	cpu_in <= 
		memory_data when to_integer(unsigned(address)) < 16#20000#
		else gpu_data when to_integer(unsigned(address)) >= 16#30000# and to_integer(unsigned(address)) < 16#40000#
		else microcontroller_data when to_integer(unsigned(address)) >= 16#40000# and to_integer(unsigned(address)) < 16#50000#
		else apu_data when to_integer(unsigned(address)) >= 16#50000# and to_integer(unsigned(address)) < 16#60000#
		else x"00000000";
	
	interrupts <= 3x"0" & int_timer & int_hblank & int_vblank & 2x"0";
	
	lcd_pins : if not USE_LCD generate
		ARDUINO_IO(15 downto 0) <= arduino(15 downto 0);
	else generate
		ARDUINO_IO(9 downto 8) <= lcd_data(1 downto 0);
		ARDUINO_IO(7 downto 2) <= lcd_data(7 downto 2);
		ARDUINO_IO(13 downto 10) <= arduino(13 downto 10);
	end generate;
	
	apu_pins : if not USE_APU generate
		GPIO(35 downto 33) <= gpio_pins(35 downto 33);
	end generate;
	GPIO(32 downto 0) <= gpio_pins(32 downto 0);
	
	prcoessor : cpu
		port map (
			clock => clock,
			reset => reset,
			int_in => interrupts,
			data_in => cpu_in,
			data_out => data,
			address => address,
			data_mask => data_mask,
			write_en => write_en,
			reset_int => reset_int
		);
		
	mem : memory
		port map (
			address => address,
			data_mask => data_mask,
			write_en => write_en,
			clock => clock,
			data_in => data,
			data_out => memory_data
		);
	
	micro : microcontroller
		port map (
			address => address,
			write_en => write_en,
			clock => clock,
			reset => reset,
			data_in => data,
			data_out => microcontroller_data,
			timer_int => int_timer,
			buttons => KEY,
			switches => SW,
			gpio => gpio_pins,
			arduino => arduino,
			leds => LEDR,
			hex0 => HEX0,
			hex1 => HEX1,
			hex2 => HEX2,
			hex3 => HEX3,
			hex4 => HEX4,
			hex5 => HEX5
		);
	
	ppu : gpu
		port map (
			address => address,
			write_en => write_en,
			clock => MAX10_CLK1_50,
			reset => reset,
			data_in => data,
			data_out => gpu_data,
			pixel => gpu_pixel,
			pixel_x => gpu_pixel_x,
			pixel_y => gpu_pixel_y,
			sprite_index => gpu_sprite_index,
			sprite_cache_index => gpu_sprite_cache_index,
			sprite_cache_write => gpu_sprite_cache_write,
			sprite_cache_clear => gpu_sprite_cache_clear,
			bg_x => gpu_bg_x,
			bg_y => gpu_bg_y,
			rendering => gpu_rendering,
			blanking => gpu_blanking,
			ticks => gpu_ticks
		);

	audio_driver : if USE_APU generate
		audio : apu
			port map (
				address => address,
				write_en => write_en,
				clock => MAX10_CLK1_50,
				reset => reset,
				data_in => data,
				data_out => apu_data,
				i2s_bck => GPIO(33),
				i2s_din => GPIO(34),
				i2s_lrck => GPIO(35)
			);
	end generate;
		
	display_driver : if USE_LCD generate
		lcd : lcd_driver
			port map (
				clock => MAX10_CLK1_50,
				reset => reset,
				pixel => gpu_pixel,
				pixel_x => gpu_pixel_x,
				pixel_y => gpu_pixel_y,
				sprite_index => gpu_sprite_index,
				sprite_cache_index => gpu_sprite_cache_index,
				sprite_cache_write => gpu_sprite_cache_write,
				sprite_cache_clear => gpu_sprite_cache_clear,
				bg_x => gpu_bg_x,
				bg_y => gpu_bg_y,
				rendering => gpu_rendering,
				blanking => gpu_blanking,
				ticks => gpu_ticks,
				vblank => int_vblank,
				hblank => int_hblank,
				lcd_data => lcd_data,
				lcd_write => ARDUINO_IO(1),
				lcd_command => ARDUINO_IO(14),
				lcd_enable => ARDUINO_IO(15)
			);
	else generate
		vga : vga_driver
			port map (
				clock => MAX10_CLK1_50,
				reset => reset,
				pixel => gpu_pixel,
				pixel_x => gpu_pixel_x,
				pixel_y => gpu_pixel_y,
				sprite_index => gpu_sprite_index,
				sprite_cache_index => gpu_sprite_cache_index,
				sprite_cache_write => gpu_sprite_cache_write,
				sprite_cache_clear => gpu_sprite_cache_clear,
				bg_x => gpu_bg_x,
				bg_y => gpu_bg_y,
				rendering => gpu_rendering,
				blanking => gpu_blanking,
				ticks => gpu_ticks,
				vblank => int_vblank,
				hblank => int_hblank,
				vga_r => VGA_R,
				vga_g => VGA_G,
				vga_b => VGA_B,
				vga_hs => VGA_HS,
				vga_vs => VGA_VS
			);
	end generate;

	por : power_on_reset
		port map (
			clock => clock,
			reset_in => reset_trigger,
			reset_out => reset
		);
end architecture;
