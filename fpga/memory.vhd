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
	signal mem_address : std_logic_vector(14 downto 0);
	signal mem_data : std_logic_vector(31 downto 0);
	signal mem_write : std_logic;
begin
	mem_address <= address(16 downto 2);

	read_mask <= std_logic_vector(resize(signed(data_mask(3 downto 3)), 8) & resize(signed(data_mask(2 downto 2)), 8) 
		& resize(signed(data_mask(1 downto 1)), 8) & resize(signed(data_mask(0 downto 0)), 8));
	
	process(all)
	begin
		case to_integer(unsigned(address)) is
			when 16#00000# to 16#17FFF# => 
				data_out <= mem_data and read_mask;
				mem_write <= '0';
			when 16#18000# to 16#1FFFF# => 
				data_out <= mem_data and read_mask;
				mem_write <= write_en;
			when others =>
				data_out <= x"00000000";
				mem_write <= '0';
		end case;
	end process;
	
	mem : altsyncram
		generic map (
			byte_size => 8,
			address_aclr_a => "NONE",
			clock_enable_input_a => "BYPASS",
			clock_enable_output_a => "BYPASS",
			init_file => "rom.mif",
			intended_device_family => "MAX 10",
			lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=MEM",
			lpm_type => "altsyncram",
			numwords_a => 32768,
			operation_mode => "SINGLE_PORT",
			outdata_aclr_a => "NONE",
			outdata_reg_a => "UNREGISTERED",
			widthad_a => 15,
			width_a => 32,
			width_byteena_a => 4
		)
		port map (
			address_a => mem_address,
			clock0 => clock,
			data_a => data_in,
			wren_a => mem_write,
			q_a => mem_data,
			byteena_a => data_mask
		);
end architecture;
