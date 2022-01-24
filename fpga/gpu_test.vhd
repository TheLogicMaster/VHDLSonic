-- Set as project top level entity to test GPU behavior

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpu_test is
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

architecture impl of gpu_test is
	constant USE_LCD : boolean := true;

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
	
	component power_on_reset is
		port (
			clock : in std_logic;
			reset_in : in std_logic;
			reset_out : out std_logic
		);
	end component;					
	
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
	signal lcd_data : std_logic_vector(7 downto 0);
	
	-- Data bus
	signal gpu_data : std_logic_vector(31 downto 0);
	
	signal reset : std_logic;
	signal reset_trigger : std_logic;
	
	signal state : integer;
	signal address : std_logic_vector(31 downto 0);
	signal data : std_logic_vector(31 downto 0);
	signal write_en : std_logic;
begin
	reset_trigger <= not ARDUINO_RESET_N;

	ARDUINO_IO(9 downto 8) <= lcd_data(1 downto 0);
	ARDUINO_IO(7 downto 2) <= lcd_data(7 downto 2);
	
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
	--			vblank => ,
	--			hblank => ,
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
	--			vblank => ,
	--			hblank => ,
				vga_r => VGA_R,
				vga_g => VGA_G,
				vga_b => VGA_B,
				vga_hs => VGA_HS,
				vga_vs => VGA_VS
			);
	end generate;
	
	por : power_on_reset
		port map (
			clock => MAX10_CLK1_50,
			reset_in => reset_trigger,
			reset_out => reset
		);
		
	process(all)
	begin
		if reset = '1' then
			state <= 0;
		elsif rising_edge(MAX10_CLK1_50) then
			if state < 1000 then
				state <= state + 1;
			end if;
			case state is
				when 0 to 31 =>
					address <= std_logic_vector(to_unsigned(16#00030054# + (8 + state) * 4, 32));
					case state mod 8 is
						when 0 => data <= x"8888888" & std_logic_vector(to_unsigned(state / 8 + 1, 4));
						when 1 => data <= x"8000000" & std_logic_vector(to_unsigned(state / 8 + 1, 4));
						when 2 => data <= x"8000000" & std_logic_vector(to_unsigned(state / 8 + 1, 4));
						when 3 => data <= x"8000000" & std_logic_vector(to_unsigned(state / 8 + 1, 4));
						when 4 => data <= x"80000008";
						when 5 => data <= x"80000008";
						when 6 => data <= x"80000008";
						when 7 => data <= x"88888888";
						when others => data <= x"00000000";
					end case;
--					if (state mod 2) = 0 then
--						data <= x"01234567";
--					else
--						data <= x"89ABCDEF";
--					end if;
					write_en <= '1';
				when 32 => -- BG_data[0] = 1;
					address <= x"00032054";
					data <= x"00000001";
					write_en <= '1';
				when 33 => -- BG_data[1] = 2;
					address <= std_logic_vector(to_unsigned(16#00032054# + 1 * 4, 32));
					data <= x"00000002";
					write_en <= '1';
				when 34 => -- BG_data[2] = 3;
					address <= std_logic_vector(to_unsigned(16#00032054# + 2 * 4, 32));
					data <= x"00000003";
					write_en <= '1';
				when 35 => -- BG_data[3] = 4;
					address <= std_logic_vector(to_unsigned(16#00032054# + 3 * 4, 32));
					data <= x"00000004";
					write_en <= '1';
				when 36 => -- BG_data[130] = 1;
					address <= std_logic_vector(to_unsigned(16#00032054# + 130 * 4, 32));
					data <= x"00000001";
					write_en <= '1';
				when 37 => -- Sprites[0] = {1, 50, 34, false, false};
					address <= x"00037365";
					data <= x"0" & x"01" & 9x"032" & 9x"022" & "0" & "0";
					write_en <= '1';
				when 38 => -- Sprites[1] = {1, 66, 6, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 1 * 4, 32));
					data <= x"0" & x"01" & 9x"042" & 9x"006" & "0" & "0";
					write_en <= '1';
				when 39 => -- Sprites[2] = {1, 66, 252, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 2 * 4, 32));
					data <= x"0" & x"01" & 9x"042" & 9x"0FC" & "0" & "0";
					write_en <= '1';
				when 40 => -- Sprites[3] = {1, 6, 64, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 3 * 4, 32));
					data <= x"0" & x"01" & 9x"006" & 9x"040" & "0" & "0";
					write_en <= '1';
				when 41 => -- Sprites[4] = {1, 332, 128, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 4 * 4, 32));
					data <= x"0" & x"01" & 9x"14C" & 9x"080" & "0" & "0";
					write_en <= '1';
				when 42 => -- Sprites[5] = {1, 51, 43, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 4 * 5, 32));
					data <= x"0" & x"01" & 9x"033" & 9x"02B" & "0" & "0";
					write_en <= '1';
				when 43 => -- Sprites[6] = {1, 80, 80, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 4 * 6, 32));
					data <= x"0" & x"01" & 9x"050" & 9x"050" & "0" & "0";
					write_en <= '1';
				when 44 => -- Sprites[7] = {1, 84, 96, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 4 * 7, 32));
					data <= x"0" & x"01" & 9x"054" & 9x"060" & "0" & "0";
					write_en <= '1';
				when 45 => -- Sprites[8] = {1, 88, 112, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 4 * 8, 32));
					data <= x"0" & x"01" & 9x"058" & 9x"070" & "0" & "0";
					write_en <= '1';
				when 46 => -- Sprites[9] = {1, 92, 128, false, false};
					address <= std_logic_vector(to_unsigned(16#00037365# + 4 * 9, 32));
					data <= x"0" & x"01" & 9x"05C" & 9x"080" & "0" & "0";
					write_en <= '1';
--				when 47 => -- H_Scroll = 4
--					address <= x"00030004";
--					data <= x"00000004";
--					write_en <= '1';
--				when 48 => -- V_Scroll = 4
--					address <= x"00030008";
--					data <= x"00000004";
--					write_en <= '1';
				when 49 => -- BG_data[40] = 4;
					address <= std_logic_vector(to_unsigned(16#00032054# + 40 * 4, 32));
					data <= x"00000004";
					write_en <= '1';
				when 50 => -- Render = 1
					address <= x"00030000";
					data <= x"00000001";
					write_en <= '1';
				when others =>
					address <= x"00000000";
					data <= x"00000000";
					write_en <= '0';
			end case;
		end if;
	end process;
end architecture;
