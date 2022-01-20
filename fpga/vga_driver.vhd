-- VGA Driver

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity vga_driver is
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
		vga_vs : buffer std_logic
	);
end entity;

architecture impl of vga_driver is
	signal h_cnt : unsigned(10 downto 0);
	signal v_cnt : unsigned(9 downto 0);
	signal vga_clk : std_logic;
begin
	-- Clock divider
	process(all)
	begin
		if reset = '1' then
			vga_clk <= '0';
		elsif rising_edge(clock) then
			vga_clk <= not vga_clk;
		end if;
	end process;
	
	pixel_x <= std_logic_vector(resize((h_cnt - (96 + 48)) / 2, 10));
	pixel_y <= std_logic_vector(resize((v_cnt - 11) / 2, 9));
	sprite_index <= std_logic_vector(resize((h_cnt - 21) / 2, 6));
	sprite_cache_index <= std_logic_vector(resize(h_cnt, 6));
	sprite_cache_write <= '1' when h_cnt >= 22 and h_cnt < 22 + 64 * 2 else '0';
	sprite_cache_clear <= '1' when h_cnt >= 0 and h_cnt < 20 else '0';
	bg_x <= std_logic_vector(resize((h_cnt - (96 + 48)) / 2, 10));
	bg_y <= std_logic_vector(resize((v_cnt - 11) / 2, 9));
	blanking <= '1' when v_cnt >= 10 + 480 else '0';
	ticks <= h_cnt(0) & vga_clk;
	
	vblank <= '1' when h_cnt = 0 and v_cnt = 10 + 480 else '0';
	hblank <= '1' when h_cnt = 96 + 48 + 640 - 1 and v_cnt >= 10 - 1 and v_cnt < 10 + 480 else '0';
	
	vga_hs <= '1' when h_cnt < 96 else '0';
	vga_vs <= '1' when v_cnt < 2 else '0';
	
	process(all)
	begin
		if reset = '1' then
			h_cnt <= to_unsigned(0, 11);
			v_cnt <= to_unsigned(0, 10);
			vga_r <= x"0";
			vga_g <= x"0";
			vga_b <= x"0";
		elsif rising_edge(vga_clk) then
			if h_cnt < 784 and h_cnt >= 96 and v_cnt < 514 and v_cnt >= 11 and rendering = '1' then
				vga_r <= pixel(15 downto 12);
				vga_g <= pixel(10 downto 7);
				vga_b <= pixel(4 downto 1);
			else
				vga_r <= x"0";
				vga_g <= x"0";
				vga_b <= x"0";
			end if;
			
			if h_cnt = 640 + 16 + 96 + 48 - 1 then
				h_cnt <= to_unsigned(0, 11);
				if v_cnt = 480 + 10 + 2 + 33 - 1 then
					v_cnt <= to_unsigned(0, 10);
				else
					v_cnt <= v_cnt + 1;
				end if;
			else
				h_cnt <= h_cnt + 1;
			end if;
		end if;
	end process;
end architecture;
