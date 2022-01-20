library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_test is
end audio_test;

architecture test of audio_test is

	component apu is
		port (
			address : in std_logic_vector(31 downto 0);
			write_en : in std_logic;
			clock : in std_logic;
			reset : in std_logic;
			data_in : in std_logic_vector(31 downto 0);
			data_out : out std_logic_vector(31 downto 0);
			i2s_bck : out std_logic;
			i2s_din : out std_logic;
			i2s_lrck : out std_logic
		);
	end component;		
	
	signal clock : std_logic;
	signal reset : std_logic;
	signal data_in : std_logic_vector(31 downto 0);
	signal data_out : std_logic_vector(31 downto 0);
	signal address : std_logic_vector(31 downto 0);
	signal write_en : std_logic;
	signal i2s_bck : std_logic;
	signal i2s_din : std_logic;
	signal i2s_lrck : std_logic;
begin
	audio : apu
		port map (
			address => address,
			write_en => write_en,
			clock => clock,
			reset => reset,
			data_in => data_in,
			data_out => data_out,
			i2s_bck => i2s_bck,
			i2s_din => i2s_din,
			i2s_lrck => i2s_lrck
		);

	vectors: process
		constant period: time := 10 ns;
	begin
		  write_en <= '0';
		  address <= 32x"0";
		  data_in <= 32x"0";
	
		  -- Reset
		  clock <= '0';
		  reset <= '1';
		  wait for period;
		  clock <= '1';
		  wait for period;
		  clock <= '0';
		  wait for period;
		  clock <= '1';
		  wait for period;
		  clock <= '0';
		  wait for period;
		  reset <= '0';
		  clock <= '1';
		  wait for period;
		  clock <= '0';
		  wait for period;
		  
		  write_en <= '1';
		  address <= 32x"50000";
		  data_in <= '1' & x"FFF" & "111" & x"0100";
		  
		  clock <= '1';
		  wait for period;
		  clock <= '0';
		  
		  write_en <= '0';
--		  address <= 32x"0";
		  data_in <= 32x"0";
		  
		  for i in 1 to 51000 loop
				wait for period;
				clock <= '1';
				wait for period;
				clock <= '0';
		  end loop;
		  
		  wait;
    end process;
end test;
