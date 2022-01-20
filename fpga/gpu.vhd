-- 8-bit GPU/PPU

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity gpu is
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
end entity;

architecture impl of gpu is
	type sprite_type is record
		first_tile : integer range 0 to 255;
		x : integer range 0 to 511;
		y : integer range 0 to 511;
		h_flip : boolean;
		v_flip: boolean;
	end record;
	
	type palette_array is array (0 to 15) of std_logic_vector(15 downto 0);
	
	function rgb_888_to_565(rgb : std_logic_vector(23 downto 0)) return std_logic_vector is
	begin
		return rgb(23 downto 19) & rgb(15 downto 10) & rgb(7 downto 3);
	end function;
	
	function reverse_nibbles(value : std_logic_vector(31 downto 0)) return std_logic_vector is
	begin
		return value(3 downto 0) & value(7 downto 4) & value(11 downto 8) & value(15 downto 12) 
			& value(19 downto 16) & value(23 downto 20) & value(27 downto 24) & value(31 downto 28);
	end function;
	
	function deserialize_sprite(serialized : unsigned(27 downto 0)) return sprite_type is
	begin
		return (
			first_tile => to_integer(serialized(27 downto 20)),
			x => to_integer(serialized(19 downto 11)),
			y => to_integer(serialized(10 downto 2)),
			h_flip => serialized(1) = '1',
			v_flip => serialized(0) = '1'
		);
	end function;

  	-- Graphics registers
	signal render : boolean;
	signal h_scroll : integer range 0 to 511;
	signal v_scroll : integer range 0 to 511;
	signal window_x : integer range 0 to 511;
	signal window_y : integer range 0 to 511;
	signal palette : palette_array;
	
	-- Sprite RAM signals
	signal sprite_read_addr : std_logic_vector(5 downto 0);
	signal sprite_write_addr : std_logic_vector(5 downto 0);
	signal sprite_write : std_logic;
	signal sprite_out : std_logic_vector(31 downto 0);
	signal sprite_data : sprite_type;
	
	-- Sprite cache RAM signals
	signal sprite_cache_a_addr : std_logic_vector(5 downto 0);
	signal sprite_cache_b_addr : std_logic_vector(5 downto 0);
	signal sprite_cache_a_write : std_logic;
	signal sprite_cache_b_write : std_logic;
	signal sprite_cache_a_in : std_logic_vector(31 downto 0);
	signal sprite_cache_b_in : std_logic_vector(31 downto 0);
	signal sprite_cache_a_out : std_logic_vector(31 downto 0);
	signal sprite_cache_b_out : std_logic_vector(31 downto 0);
	signal sprite_cache_data : integer range 0 to 15;
	
	-- Tile RAM signals
	signal tile_a_addr : std_logic_vector(10 downto 0);
	signal tile_a_write : std_logic;
	signal tile_a_out : std_logic_vector(31 downto 0);
	signal tile_b_addr : std_logic_vector(7 downto 0);
	signal tile_b_out : std_logic_vector(255 downto 0);
	
	-- Background RAM signals
	signal bg_read_addr : std_logic_vector(11 downto 0);
	signal bg_write_addr : std_logic_vector(11 downto 0);
	signal bg_write : std_logic;
	signal bg_out : std_logic_vector(7 downto 0);
	signal bg_data : integer range 0 to 255;
	
	-- Window RAM signals
	signal win_read_addr : std_logic_vector(9 downto 0);
	signal win_write_addr : std_logic_vector(9 downto 0);
	signal win_write : std_logic;
	signal win_out : std_logic_vector(7 downto 0);
	signal win_data : integer range 0 to 255;
	
	-- Other signals
	signal addr_index : integer;
	signal bg_palette_index : integer range 0 to 15;
	signal sprite_data_prev : sprite_type;
	signal bg_x_1 : unsigned(9 downto 0);
	signal bg_y_1 : unsigned(8 downto 0);
	signal bg_x_2 : unsigned(9 downto 0);
	signal bg_y_2 : unsigned(8 downto 0);
begin
	rendering <= '1' when render else '0';

	addr_index <= (to_integer(unsigned(address)) - 16#30000#) / 4;
	
	-- Sprite writing and reading logic
	sprite_write_addr <= std_logic_vector(to_unsigned(addr_index - 7365, 6));
	sprite_write <= '1' when addr_index >= 7365 and addr_index <= 7428 and write_en = '1' else '0';
	sprite_read_addr <= sprite_index;
	sprite_data <= deserialize_sprite(unsigned(sprite_out(27 downto 0)));
		
	-- Tile write/BG tile reading logic
	tile_a_addr <=
		std_logic_vector(to_unsigned(addr_index - 21, 11)) when blanking = '1' or render = false
		else std_logic_vector(resize(unsigned(bg_out) * 8 + (bg_y_2 mod 8), 11));
	tile_a_write <= '1' when addr_index >= 21 and addr_index <= 2068 and write_en = '1' else '0';
	
	-- Sprite tile reading logic
	-- Todo: Convert to process
	tile_b_addr <= 
		std_logic_vector(to_unsigned(sprite_data.first_tile, 8)) when ticks(1) = '0' and to_integer(unsigned(pixel_y)) + 16 - sprite_data.y < 8
		else std_logic_vector(to_unsigned(sprite_data.first_tile + 1, 8)) when ticks(1) = '1' and to_integer(unsigned(pixel_y)) + 16 - sprite_data.y < 8
		else std_logic_vector(to_unsigned(sprite_data.first_tile + 2, 8)) when ticks(1) = '0' and to_integer(unsigned(pixel_y)) + 16 - sprite_data.y >= 8
		else std_logic_vector(to_unsigned(sprite_data.first_tile + 3, 8));
	
	-- Background data writing and reading logic
	bg_write_addr <= std_logic_vector(to_unsigned(addr_index - 2069, 12));
	bg_write <= '1' when addr_index >= 2069 and addr_index <= 6164 and write_en = '1' else '0';
	bg_read_addr <= std_logic_vector(resize(bg_x_1 / 8 + bg_y_1 / 8 * (512 / 8), 12));
	bg_data <= to_integer(unsigned(bg_out));
	
	-- Window data writing and reading logic
	win_write_addr <= std_logic_vector(to_unsigned(addr_index - 6165, 10));
	win_write <= '1' when addr_index >= 6165 and addr_index <= 7364 and write_en = '1' else '0';
	win_data <= to_integer(unsigned(win_out));
	
	-- Graphics layer combining logic
	bg_palette_index <= to_integer(shift_right(unsigned(tile_a_out), to_integer(28 - ((unsigned(pixel_x) + h_scroll) mod 8) * 4)) and x"0000000F");
	pixel <=
		palette(sprite_cache_data) when sprite_cache_data > 0
		else palette(bg_palette_index);
	
	-- Background rendering pipeline logic
	process(all)
	begin
		bg_x_1 <= unsigned(bg_x) + h_scroll;
		bg_y_1 <= unsigned(bg_y) + v_scroll;
		if rising_edge(clock) then
			bg_x_2 <= bg_x_1;
			bg_y_2 <= bg_y_1;
		end if;
	end process;

	-- Sprite caching logic
	-- Todo: Sprite mirroring
	process(all)
		variable y : integer range 0 to 511;
		variable sprite_x : integer range 0 to 15;
		variable sprite_y : integer range 0 to 15;
		variable tile_offset : integer range 0 to 255;
		variable sprite : sprite_type;
		variable base_addr : integer range -2 to 41;
		variable tile_row : std_logic_vector(31 downto 0);
		variable new_color : std_logic_vector(3 downto 0);
		variable new_data : std_logic_vector(31 downto 0);
	begin
		sprite_cache_data <= to_integer(resize(shift_right(unsigned(sprite_cache_a_out), (to_integer(unsigned(pixel_x)) mod 8) * 4), 4));
	
		sprite := sprite_data_prev;
		if ticks(0) = '0' then
			sprite_x := 8;
		else
			sprite_x := 0;
		end if;
		
		y := to_integer(unsigned(pixel_y)) + 16;
		sprite_y := to_integer(unsigned(pixel_y)) + 16 - sprite.y;
		if sprite_cache_write = '1' and sprite.y > 0 and sprite.x > 0 and sprite.y + 16 > y and sprite.y <= y and sprite.x - 16 < 320 then
			-- Draw sprites into line buffer
			base_addr := sprite.x / 8 - 2;
			
			if ticks(1) = '1' then
				base_addr := base_addr + 1;
			end if;
			
			tile_offset := 32 * (sprite_y mod 8);
			tile_row := tile_b_out(tile_offset + 31 downto tile_offset);
			
			new_data := reverse_nibbles(std_logic_vector(shift_right(unsigned(tile_row), 4 * (sprite.x mod 8))));
			for i in 0 to 7 loop
				new_color := new_data(i * 4 + 3 downto i * 4);
				if new_color /= x"0" then
					sprite_cache_a_in(i * 4 + 3 downto i * 4) <= new_color;
				else
					sprite_cache_a_in(i * 4 + 3 downto i * 4) <= sprite_cache_a_out(i * 4 + 3 downto i * 4);
				end if;
			end loop;
			
			new_data := reverse_nibbles(std_logic_vector(shift_left(unsigned(tile_row), 32 - 4 * (sprite.x mod 8))));
			for i in 0 to 7 loop
				new_color := new_data(i * 4 + 3 downto i * 4);
				if new_color /= x"0" then
					sprite_cache_b_in(i * 4 + 3 downto i * 4) <= new_color;
				else
					sprite_cache_b_in(i * 4 + 3 downto i * 4) <= sprite_cache_b_out(i * 4 + 3 downto i * 4);
				end if;
			end loop;
			
			if ticks(0) = '0' then
				if base_addr >= 0 then
					sprite_cache_a_write <= '1';
				else
					sprite_cache_a_write <= '0';
				end if;
				sprite_cache_b_write <= '1';
			else
				sprite_cache_a_write <= '0';
				sprite_cache_b_write <= '0';
			end if;
			sprite_cache_a_addr <= std_logic_vector(to_unsigned(base_addr, 6));
			sprite_cache_b_addr <= std_logic_vector(to_unsigned(base_addr + 1,  6));
		elsif sprite_cache_clear then
			-- Clear sprite line buffer
			sprite_cache_a_write <= '1';
			sprite_cache_b_write <= '1';
			sprite_cache_a_addr <= sprite_cache_index;
			sprite_cache_b_addr <= std_logic_vector(unsigned(sprite_cache_index) + 20);
			sprite_cache_a_in <= 32x"0";
			sprite_cache_b_in <= 32x"0";
		else
			-- Use port A for rendering from buffer
			sprite_cache_a_write <= '0';
			sprite_cache_b_write <= '0';
			sprite_cache_a_addr <= std_logic_vector(resize(unsigned(pixel_x) / 8, 6));
			sprite_cache_b_addr <= 6x"0";
			sprite_cache_a_in <= 32x"0";
			sprite_cache_b_in <= 32x"0";
		end if;

		if rising_edge(clock) then
			sprite_data_prev <= sprite_data;
		end if;
	end process;
	
	sprite_ram : altsyncram
		generic map (
			address_aclr_b => "NONE",
			address_reg_b => "CLOCK0",
			clock_enable_input_a => "BYPASS",
			clock_enable_input_b => "BYPASS",
			clock_enable_output_b => "BYPASS",
			intended_device_family => "MAX 10",
			lpm_type => "altsyncram",
			numwords_a => 64,
			numwords_b => 64,
			operation_mode => "DUAL_PORT",
			outdata_aclr_b => "NONE",
			outdata_reg_b => "UNREGISTERED",
			power_up_uninitialized => "FALSE",
			read_during_write_mode_mixed_ports => "OLD_DATA",
			widthad_a => 6,
			widthad_b => 6,
			width_a => 32,
			width_b => 32,
			width_byteena_a => 1
		)
		port map (
			address_a => sprite_write_addr,
			address_b => sprite_read_addr,
			clock0 => clock,
			data_a => data_in,
			wren_a => sprite_write,
			q_b => sprite_out
		);
	
	sprite_cache : altsyncram
		generic map (
			address_reg_b => "CLOCK0",
			clock_enable_input_a => "BYPASS",
			clock_enable_input_b => "BYPASS",
			clock_enable_output_a => "BYPASS",
			clock_enable_output_b => "BYPASS",
			indata_reg_b => "CLOCK0",
			intended_device_family => "MAX 10",
			lpm_type => "altsyncram",
			numwords_a => 64,
			numwords_b => 64,
			operation_mode => "BIDIR_DUAL_PORT",
			outdata_aclr_a => "NONE",
			outdata_aclr_b => "NONE",
			outdata_reg_a => "UNREGISTERED",
			outdata_reg_b => "UNREGISTERED",
			power_up_uninitialized => "FALSE",
			read_during_write_mode_mixed_ports => "DONT_CARE",
			read_during_write_mode_port_a => "NEW_DATA_WITH_NBE_READ",
			read_during_write_mode_port_b => "NEW_DATA_WITH_NBE_READ",
			widthad_a => 6,
			widthad_b => 6,
			width_a => 32,
			width_b => 32,
			width_byteena_a => 1,
			width_byteena_b => 1,
			wrcontrol_wraddress_reg_b => "CLOCK0"
		)
		port map (
			address_a => sprite_cache_a_addr,
			address_b => sprite_cache_b_addr,
			clock0 => clock,
			data_a => sprite_cache_a_in,
			data_b => sprite_cache_b_in,
			wren_a => sprite_cache_a_write,
			wren_b => sprite_cache_b_write,
			q_a => sprite_cache_a_out,
			q_b => sprite_cache_b_out
		);
	
	tile_ram : altsyncram
		generic map (
			address_reg_b => "CLOCK0",
			clock_enable_input_a => "BYPASS",
			clock_enable_input_b => "BYPASS",
			clock_enable_output_a => "BYPASS",
			clock_enable_output_b => "BYPASS",
			indata_reg_b => "CLOCK0",
			intended_device_family => "MAX 10",
			lpm_type => "altsyncram",
			numwords_a => 2048,
			numwords_b => 256,
			operation_mode => "BIDIR_DUAL_PORT",
			outdata_aclr_a => "NONE",
			outdata_aclr_b => "NONE",
			outdata_reg_a => "CLOCK0",
			outdata_reg_b => "UNREGISTERED",
			power_up_uninitialized => "FALSE",
			read_during_write_mode_mixed_ports => "OLD_DATA",
			read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
			read_during_write_mode_port_b => "NEW_DATA_NO_NBE_READ",
			widthad_a => 11,
			widthad_b => 8,
			width_a => 32,
			width_b => 256,
			width_byteena_a => 1,
			width_byteena_b => 1,
			wrcontrol_wraddress_reg_b => "CLOCK0"
		)
		port map (
			address_a => tile_a_addr,
			address_b => tile_b_addr,
			clock0 => clock,
			data_a => data_in(31 downto 0),
			wren_a => tile_a_write,
			q_a => tile_a_out,
			q_b => tile_b_out
		);
		
	bg_ram : altsyncram
		generic map (
			address_aclr_b => "NONE",
			address_reg_b => "CLOCK0",
			clock_enable_input_a => "BYPASS",
			clock_enable_input_b => "BYPASS",
			clock_enable_output_b => "BYPASS",
			intended_device_family => "MAX 10",
			lpm_type => "altsyncram",
			numwords_a => 4096,
			numwords_b => 4096,
			operation_mode => "DUAL_PORT",
			outdata_aclr_b => "NONE",
			outdata_reg_b => "UNREGISTERED",
			power_up_uninitialized => "FALSE",
			read_during_write_mode_mixed_ports => "OLD_DATA",
			widthad_a => 12,
			widthad_b => 12,
			width_a => 8,
			width_b => 8,
			width_byteena_a => 1
		)
		port map (
			address_a => bg_write_addr,
			address_b => bg_read_addr,
			clock0 => clock,
			data_a => data_in(7 downto 0),
			wren_a => bg_write,
			q_b => bg_out
		);
		
	win_ram : altsyncram
		generic map (
			address_aclr_b => "NONE",
			address_reg_b => "CLOCK0",
			clock_enable_input_a => "BYPASS",
			clock_enable_input_b => "BYPASS",
			clock_enable_output_b => "BYPASS",
			intended_device_family => "MAX 10",
			lpm_type => "altsyncram",
			numwords_a => 1024,
			numwords_b => 1024,
			operation_mode => "DUAL_PORT",
			outdata_aclr_b => "NONE",
			outdata_reg_b => "UNREGISTERED",
			power_up_uninitialized => "FALSE",
			read_during_write_mode_mixed_ports => "OLD_DATA",
			widthad_a => 10,
			widthad_b => 10,
			width_a => 8,
			width_b => 8,
			width_byteena_a => 1
		)
		port map (
			address_a => win_write_addr,
			address_b => win_read_addr,
			clock0 => clock,
			data_a => data_in(7 downto 0),
			wren_a => win_write,
			q_b => win_out
		);
		
	-- Register read logic
	process(all)
		variable index : integer;
	begin
		index := (to_integer(unsigned(address)) - 16#30000#) / 4;
		
		case index is
			when 0 => 
				if render then
					data_out <= x"00000001";
				else
					data_out <= x"00000000";
				end if;
			when others => data_out <= x"00000000";
		end case;
	end process;
	
	-- Register write logic
	process(all)
		variable index : integer;
		variable data : unsigned(31 downto 0);
		variable tile : integer range 0 to 255;
	begin
		if reset = '1' then
			render <= false;
			h_scroll <= 0;
			v_scroll <= 0;
			window_x <= 0;
			window_y <= 0;
			palette <= (
				0 => rgb_888_to_565(x"000000"),
				1 => rgb_888_to_565(x"005500"),
				2 => rgb_888_to_565(x"00aa00"),
				3 => rgb_888_to_565(x"00ff00"),
				4 => rgb_888_to_565(x"0000ff"),
				5 => rgb_888_to_565(x"0055ff"),
				6 => rgb_888_to_565(x"00aaff"),
				7 => rgb_888_to_565(x"00ffff"),
				8 => rgb_888_to_565(x"ff0000"),
				9 => rgb_888_to_565(x"ff5500"),
				10 => rgb_888_to_565(x"ffaa00"),
				11 => rgb_888_to_565(x"ffff00"),
				12 => rgb_888_to_565(x"ff00ff"),
				13 => rgb_888_to_565(x"ff55ff"),
				14 => rgb_888_to_565(x"ffaaff"),
				15 => rgb_888_to_565(x"ffffff")
			);
		elsif rising_edge(clock) and write_en = '1' then
			index := (to_integer(unsigned(address)) - 16#30000#) / 4;
			data := unsigned(data_in);
		
			case index is
				when 0 => render <= data /= 0;
				when 1 => h_scroll <= to_integer(data);
				when 2 => v_scroll <= to_integer(data);
				when 3 => window_x <= to_integer(data);
				when 4 => window_y <= to_integer(data);
				when 5 to 20 => palette(index - 5) <= rgb_888_to_565(data_in(23 downto 0));
				when others => null;
			end case;
		end if;
	end process;
end architecture;
