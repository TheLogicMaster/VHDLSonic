-- Set as project top level entity to test Debugger behavior

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debug_test is
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

architecture impl of debug_test is
	component debug is
		port (
			clock : in std_logic;
			reset : in std_logic;
			pc : in std_logic_vector(31 downto 0);
			debug_reset : out std_logic;
			paused : out std_logic
		);
	end component;
	
	component power_on_reset is
		port (
			clock : in std_logic;
			reset_in : in std_logic;
			reset_out : out std_logic
		);
	end component;
	
	signal reset_logic : std_logic;
	signal reset : std_logic;
	signal paused : std_logic;
	signal debug_reset : std_logic;
	signal pc : std_logic_vector(31 downto 0);
	signal state : integer range 0 to 1;
begin
	LEDR(0) <= paused;

	reset_logic <= (not KEY(0)) or debug_reset;
	
	por : power_on_reset
		port map (
			clock => MAX10_CLK1_50,
			reset_in => reset_logic,
			reset_out => reset
		);
		
	test : debug
		port map (
			clock => MAX10_CLK1_50,
			reset => reset,
			pc => pc,
			debug_reset => debug_reset,
			paused => paused
		);
	
	process(all)
	begin
		if rising_edge(MAX10_CLK1_50) then
			if paused = '1' then
				state <= 0;
			else
				if state = 0 then
					state <= 1;
				else
					if unsigned(pc) < 16#20000# then
						pc <= std_logic_vector(unsigned(pc) + 4);
					else
						pc <= 32x"0";
					end if;
					state <= 0;
				end if;
			end if;
		end if;
	end process;
end architecture;
