-- Computer RAM/ROM interface

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity memory is
	port (
		address : in std_logic_vector(31 downto 0);
		data_mask : in std_logic_vector(3 downto 0);
		write_en : in std_logic;
		clock : in std_logic;
		data_in : in std_logic_vector(31 downto 0);
		data_out : out std_logic_vector(31 downto 0)
	);
end entity;

architecture impl of memory is
	signal read_mask : std_logic_vector(31 downto 0);
	signal rom_address : std_logic_vector(13 downto 0);
	signal rom_data : std_logic_vector(31 downto 0);
	signal ram_address : std_logic_vector(13 downto 0);
	signal ram_data : std_logic_vector(31 downto 0);
	signal ram_write : std_logic;
begin
	rom_address <= address(15 downto 2);
	ram_address <= std_logic_vector(unsigned(address(15 downto 2)) - to_unsigned(16#10000#, 32)(15 downto 2));

	read_mask <= std_logic_vector(resize(signed(data_mask(3 downto 3)), 8) & resize(signed(data_mask(2 downto 2)), 8) 
		& resize(signed(data_mask(1 downto 1)), 8) & resize(signed(data_mask(0 downto 0)), 8));
	
	process(all)
	begin
		case to_integer(unsigned(address)) is
			when 16#00000# to 16#0FFFF# => 
				data_out <= rom_data and read_mask;
				ram_write <= '0';
			when 16#10000# to 16#1FFFF# => 
				data_out <= ram_data and read_mask;
				ram_write <= write_en;
			when others =>
				data_out <= x"00000000";
				ram_write <= '0';
		end case;
	end process;
	
	rom : altsyncram
		generic map (
			byte_size => 8,
			address_aclr_a => "NONE",
			clock_enable_input_a => "BYPASS",
			clock_enable_output_a => "BYPASS",
			init_file => "rom.mif",
			intended_device_family => "MAX 10",
			lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=ROM",
			lpm_type => "altsyncram",
			numwords_a => 16384,
			operation_mode => "ROM",
			outdata_aclr_a => "NONE",
			outdata_reg_a => "UNREGISTERED",
			widthad_a => 14,
			width_a => 32,
			width_byteena_a => 4
		)
		port map (
			address_a => rom_address,
			clock0 => clock,
			q_a => rom_data,
			byteena_a => data_mask
		);

	ram : altsyncram
		generic map (
			byte_size => 8,
			clock_enable_input_a => "BYPASS",
			clock_enable_output_a => "BYPASS",
			intended_device_family => "MAX 10",
			lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=RAM",
			lpm_type => "altsyncram",
			numwords_a => 16384,
			operation_mode => "SINGLE_PORT",
			outdata_aclr_a => "NONE",
			outdata_reg_a => "UNREGISTERED",
			power_up_uninitialized => "FALSE",
--			read_during_write_mode_port_a => "NEW_DATA_WITH_NBE_READ",
			read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
			widthad_a => 14,
			width_a => 32,
			width_byteena_a => 4
		)
		port map (
			address_a => ram_address,
			clock0 => clock,
			data_a => data_in,
			wren_a => ram_write,
			q_a => ram_data,
			byteena_a => data_mask
		);
end architecture;
