-- Set as project top level entity to test GPU behavior

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apu_test is
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

architecture impl of apu_test is
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
	
	component power_on_reset is
		port (
			clock : in std_logic;
			reset_in : in std_logic;
			reset_out : out std_logic
		);
	end component;					
	
	-- Data bus
	signal apu_data : std_logic_vector(31 downto 0);
	
	signal reset : std_logic;
	signal reset_trigger : std_logic;
	
	signal state : integer;
	signal address : std_logic_vector(31 downto 0);
	signal data : std_logic_vector(31 downto 0);
	signal write_en : std_logic;
begin
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
				when 0 =>
					address <= x"00050000";
					data <= '1' & x"FFF" & "111" & x"0100";
					write_en <= '1';
				when 1 =>
					address <= x"00050004";
					data <= x"00070040";
					write_en <= '0';
				when others =>
					address <= x"00000000";
					data <= x"00000000";
					write_en <= '0';
			end case;
		end if;
	end process;
end architecture;
