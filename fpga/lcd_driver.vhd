-- LCD Driver

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity lcd_driver is
	port (
		clock : in std_logic;
		reset : in std_logic;
		paused : in std_logic;
		pixel : in std_logic_vector(15 downto 0);
		pixel_x : out std_logic_vector(9 downto 0);
		pixel_y : buffer std_logic_vector(8 downto 0);
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
end entity;

architecture impl of lcd_driver is
	signal lcd_state : integer range 0 to 63;
	signal lcd_count : unsigned(24 downto 0);
begin
	pixel_x <= std_logic_vector(resize((lcd_count - 20 - 64 * 4 - 2) / 4, 10));
--	sprite_index <= std_logic_vector(resize((h_cnt - 21) / 2, 6));
--	sprite_cache_index <= std_logic_vector(resize(h_cnt, 6));
--	sprite_cache_write <= '1' when h_cnt >= 22 and h_cnt < 22 + 64 * 2 else '0';
--	sprite_cache_clear <= '1' when h_cnt >= 0 and h_cnt < 20 else '0';
--	bg_x <= pixel_x;--std_logic_vector(resize((h_cnt - (96 + 48)) / 2, 10));
	sprite_index <= std_logic_vector(resize((lcd_count - 20 - 4) / 4, 6));
	sprite_cache_index <= std_logic_vector(resize(lcd_count, 6));
	bg_x <= std_logic_vector(resize((lcd_count - 20 - 64 * 4 - 2 + 3) / 4, 10));
	sprite_cache_write <= '1' when lcd_count >= 20 and lcd_count < 20 + 64 * 4 else '0';
	sprite_cache_clear <= '1' when lcd_count < 20 else '0';
	bg_y <= pixel_y;--std_logic_vector(resize((v_cnt - 11) / 2, 9));
	blanking <= '1' when lcd_state = 22 else '0';
	ticks <= std_logic_vector(lcd_count(1 downto 0));
	
	vblank <= '1' when lcd_state = 22 and lcd_count = 0 and paused = '0' else '0';
	hblank <= '1' when lcd_state = 20 and lcd_count = 0 and paused = '0' else '0';
	
	process(all)
	begin
		case lcd_state is
			when 0 => -- Write zeros
				lcd_data <= x"00";
				lcd_command <= '0';
				lcd_enable <= '0';
				if (lcd_count mod 2) = 1 then
					lcd_write <= '0';
				else
					lcd_write <= '1';
				end if;
			when 2 | 4 to 6 | 8 to 10 | 12 to 13 | 15 => -- 8-bit registers
				lcd_enable <= '0';
				if (lcd_count mod 2) = 1 then
					lcd_write <= '0';
				else
					lcd_write <= '1';
				end if;
				if lcd_count < 2 then
					-- Register ID
					case lcd_state is
						when 2 => lcd_data <= x"01";
						when 4 => lcd_data <= x"28";
						when 5 => lcd_data <= x"C0";
						when 6 => lcd_data <= x"C1";
						when 8 => lcd_data <= x"C7";
						when 9 => lcd_data <= x"36";
						when 10 => lcd_data <= x"3A";
						when 12 => lcd_data <= x"B7";
						when 13 => lcd_data <= x"11";
						when 15 => lcd_data <= x"29";
						when others => lcd_data <= x"00";
					end case;
					lcd_command <= '0';
				else
					-- Register value
					case lcd_state is
						when 2 => lcd_data <= x"00";
						when 4 => lcd_data <= x"00";
						when 5 => lcd_data <= x"23";
						when 6 => lcd_data <= x"10";
						when 8 => lcd_data <= x"C0";
						when 9 => lcd_data <= x"28";
						when 10 => lcd_data <= x"55";
						when 12 => lcd_data <= x"07";
						when 13 => lcd_data <= x"00";
						when 15 => lcd_data <= x"00";
						when others => lcd_data <= x"00";
					end case;
					lcd_command <= '1';
				end if;
			when 7 | 11 => -- 16-bit registers
				lcd_enable <= '0';
				if (lcd_count mod 2) = 1 then
					lcd_write <= '0';
				else
					lcd_write <= '1';
				end if;
				if lcd_count <= 1 then
					-- Register ID
					case lcd_state is
						when 7 => lcd_data <= x"C5";
						when 11 => lcd_data <= x"B1";
						when others => lcd_data <= x"00";
					end case;
					lcd_command <= '0';
				elsif lcd_count <= 3 then
					-- First 8-bits
					case lcd_state is
						when 7 => lcd_data <= x"2B";
						when 11 => lcd_data <= x"00";
						when others => lcd_data <= x"00";
					end case;
					lcd_command <= '1';
				else
					-- Second 8-bits
					case lcd_state is
						when 7 => lcd_data <= x"2B";
						when 11 => lcd_data <= x"1B";
						when others => lcd_data <= x"00";
					end case;
					lcd_command <= '1';
				end if;
			when 17 => -- Set address window
				lcd_enable <= '0';
				if (lcd_count mod 2) = 1 then
					lcd_write <= '0';
				else
					lcd_write <= '1';
				end if;
				if ((lcd_count / 2) mod 5) = 0 then
					lcd_command <= '0';
				else
					lcd_command <= '1';
				end if;
				case to_integer(lcd_count / 2) is
					when 0 => lcd_data <= x"2A";
					when 1 => lcd_data <= x"00";
					when 2 => lcd_data <= x"00";
					when 3 => lcd_data <= x"01";
					when 4 => lcd_data <= x"3F";
					when 5 => lcd_data <= x"2B";
					when 6 => lcd_data <= x"00";
					when 7 => lcd_data <= x"00";
					when 8 => lcd_data <= x"00";
					when 9 => lcd_data <= x"EF";
					when others => lcd_data <= x"00";
				end case;
			when 18 => -- Start buffer write
				lcd_enable <= '0';
				if (lcd_count mod 2) = 1 then
					lcd_write <= '0';
				else
					lcd_write <= '1';
				end if;
				lcd_command <= '0';
				lcd_data <= x"2C";
			when 19 => -- Render line
				lcd_enable <= '0';
				if lcd_count > 20 + 64 * 4 - 1 and lcd_count(0) = '0' then
					lcd_write <= '0';
				else
					lcd_write <= '1';
				end if;
				lcd_command <= '1';
				if lcd_count(1) = '0' then
					lcd_data <= std_logic_vector(pixel(15 downto 8));
				else
					lcd_data <= std_logic_vector(pixel(7 downto 0));
				end if;
			when others =>
				lcd_data <= x"00";
				lcd_command <= '0';
				lcd_enable <= '1';
				lcd_write <= '1';
		end case;
	end process;
	
	-- LCD driver
	process(all)
		variable counts : integer range 0 to 25000000;
	begin
		if reset = '1' then
			lcd_state <= 0;
			lcd_count <= 25x"0";
			pixel_y <= 9x"0";
		elsif rising_edge(clock) then
			case lcd_state is
				when 0 =>
					if lcd_count >= 6 then
						lcd_state <= lcd_state + 1;
						lcd_count <= 25x"0";
					else
						lcd_count <= lcd_count + 1;
					end if;
				when 1 | 3 | 14 | 16 | 20 | 22 => -- Delays
					case lcd_state is
						when 1 => counts := 200 * 50000; -- 200 millis
						when 3 => counts := 50 * 50000; -- 50 millis
						when 14 => counts := 150 * 50000; -- 150 millis
						when 16 => counts := 500 * 50000; -- 500 millis
--						when 1 => counts := 3;--200 * 50000; -- 200 millis
--						when 3 => counts := 4;--50 * 50000; -- 50 millis
--						when 14 => counts := 5;--150 * 50000; -- 150 millis
--						when 16 => counts := 6;--500 * 50000; -- 500 millis
						when 20 => counts := 320; -- Horizontal blank
						when 22 => counts := 1600 * 810; -- Vertical blank
						when others => counts := 0;
					end case;
					if lcd_count >= counts then
						lcd_state <= lcd_state + 1;
						lcd_count <= 25x"0";
					else
						lcd_count <= lcd_count + 1;
					end if;
				when 2 | 4 to 6 | 8 to 10 | 12 to 13 | 15 => -- 8-bit registers
					if lcd_count >= 3 then
						lcd_state <= lcd_state + 1;
						lcd_count <= 25x"0";
					else
						lcd_count <= lcd_count + 1;
					end if;
				when 7 | 11 => -- 16-bit registers
					if lcd_count >= 5 then
						lcd_state <= lcd_state + 1;
						lcd_count <= 25x"0";
					else
						lcd_count <= lcd_count + 1;
					end if;
				when 17 => -- Set address window
					if lcd_count >= 19 then
						lcd_state <= lcd_state + 1;
						lcd_count <= 25x"0";
					else
						lcd_count <= lcd_count + 1;
					end if;
				when 18 => -- Start buffer write
					if lcd_count >= 1 then
						lcd_state <= lcd_state + 1;
						lcd_count <= 25x"0";
					else
						lcd_count <= lcd_count + 1;
					end if;
				when 19 => -- Render line
					if lcd_count >= 320 * 2 * 2 + 20 + 64 * 4 - 1 then
						lcd_state <= lcd_state + 1;
						lcd_count <= 25x"0";
					else
						lcd_count <= lcd_count + 1;
					end if;
				when 21 =>
					if unsigned(pixel_y) + 1 >= 240 then
						lcd_state <= lcd_state + 1;
						pixel_y <= 9x"0";
					else
						lcd_state <= 19;
						pixel_y <= std_logic_vector(unsigned(pixel_y) + 1);
					end if;
				when 23 => 
					lcd_state <= 18;
				when others => null;
			end case;
		end if;
	end process;
end architecture;
