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
	
	component power_on_reset is
		port (
			clock : in std_logic;
			reset_in : in std_logic;
			reset_out : out std_logic
		);
	end component;
	
	-- Data bus
	signal cpu_in : std_logic_vector(31 downto 0);
	signal data : std_logic_vector(31 downto 0);
	signal memory_data : std_logic_vector(31 downto 0);
	signal microcontroller_data : std_logic_vector(31 downto 0);
	signal address : std_logic_vector(31 downto 0); -- Address line
	signal data_mask : std_logic_vector(3 downto 0); -- Data line mask
	signal write_en : std_logic; -- Write enable line
	
	-- Interrupt bus
	signal interrupts : std_logic_vector(7 downto 0);
	
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
		else microcontroller_data when to_integer(unsigned(address)) >= 16#40000# and to_integer(unsigned(address)) < 16#50000#
		else x"00000000";
	
	interrupts <= x"00";
	
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
			buttons => KEY,
			switches => SW,
			gpio => GPIO,
			arduino => ARDUINO_IO,
			leds => LEDR,
			hex0 => HEX0,
			hex1 => HEX1,
			hex2 => HEX2,
			hex3 => HEX3,
			hex4 => HEX4,
			hex5 => HEX5
		);

	por : power_on_reset
		port map (
			clock => clock,
			reset_in => reset_trigger,
			reset_out => reset
		);
end architecture;
