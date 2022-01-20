-- 8-bit GPU/PPU

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity apu is
	port (
		address : in std_logic_vector(31 downto 0);
		write_en : in std_logic;
		clock : in std_logic;
		reset : in std_logic;
		data_in : in std_logic_vector(31 downto 0);
		data_out : out std_logic_vector(31 downto 0);
		i2s_bck : buffer std_logic;
		i2s_din : out std_logic;
		i2s_lrck : buffer std_logic
	);
end entity;

architecture impl of apu is
	type square_channel is record
		period : unsigned(15 downto 0);
		volume : unsigned(2 downto 0);
		duration : unsigned(11 downto 0);
		finite : boolean;
		ticks : unsigned(15 downto 0);
		state : boolean;
	end record;
	
	function deserialize_square_channel(serialized : unsigned(31 downto 0)) return square_channel is
	begin
		return (
			period => serialized(15 downto 0),
			volume => serialized(18 downto 16),
			duration => serialized(30 downto 19),
			finite => serialized(31) = '1',
			ticks => 16x"0",
			state => false
		);
	end function;
	
	function serialize_square_channel(channel : square_channel) return std_logic_vector is
		variable temp : std_logic_vector(31 downto 0);
	begin
		if channel.finite then
			temp := '1' & 31x"0";
		else
			temp := '0' & 31x"0";
		end if;
		temp(30 downto 0) := std_logic_vector(channel.duration & channel.volume & channel.period);
		return temp;
	end function;
	
	type square_channel_array is array (0 to 2) of square_channel;
	
	signal square_channels : square_channel_array;
	
	signal clock_divider : integer range 0 to 8;
	signal apu_clock : std_logic;
	signal state : unsigned(4 downto 0);
	signal sequence_ticks : unsigned(15 downto 0);
	signal sampled : unsigned(15 downto 0);
	signal length_ticks : integer range 0 to 50000;
begin

	process(all)
		variable index : integer;
	begin
		index := (to_integer(unsigned(address)) - 16#50000#) / 4;
		
		case index is
			when 0 to 2 => data_out <= serialize_square_channel(square_channels(index));
			when others => data_out <= x"00000000";
		end case;
	end process;
	
	process(all)
		variable index : integer;
		variable data : unsigned(31 downto 0);
		variable temp : unsigned(15 downto 0);
	begin
		if reset = '1' then
			for i in 0 to 2 loop
				square_channels(i) <= deserialize_square_channel(32x"0");
			end loop;
		elsif rising_edge(clock) then
			if write_en = '1' then
				index := (to_integer(unsigned(address)) - 16#50000#) / 4;
				data := unsigned(data_in);
			
				case index is
					when 0 to 2 => square_channels(index) <= deserialize_square_channel(data);
					when others => null;
				end case;
			else
				for i in 0 to 2 loop
					if square_channels(i).duration > 0 and length_ticks = 0 then
						square_channels(i).duration <= square_channels(i).duration - 1;
					end if;
				
					if square_channels(i).period /= 0 and (not square_channels(i).finite or square_channels(i).duration > 0) then
						if sequence_ticks - square_channels(i).ticks >= square_channels(i).period then
							square_channels(i).state <= not square_channels(i).state;
							square_channels(i).ticks <= sequence_ticks;
						end if;
					else
						square_channels(i).state <= false;
					end if;
				end loop;
			end if;
		end if;
	end process;
	
	process(all)
		variable temp : integer range 0 to 50000;
	begin
		if reset = '1' then
			apu_clock <= '0';
			clock_divider <= 0;
			length_ticks <= 0;
		elsif rising_edge(clock) then
			temp := clock_divider + 1;
			if temp > 8 then
				temp := 0;
				apu_clock <= not apu_clock;
			end if;
			clock_divider <= temp;
			
			temp := length_ticks + 1;
			if temp = 50000 then
				temp := 0;
			end if;
			length_ticks <= temp;
		end if;
	end process;
	
	process(all)
		variable sample: unsigned(15 downto 0);
	begin
		sample := 16x"0";
		for i in 0 to 2 loop
			if square_channels(i).state then
				sample := sample + square_channels(i).volume;
			end if;
		end loop;
		sampled <= shift_left(sample, 9);
	end process;
	
	i2s_din <= sampled(15 - to_integer((state - 2) / 2));
	
	process(all)
	begin
		if reset = '1' then
			i2s_bck <= '0';
			i2s_lrck <= '0';
			sequence_ticks <= 16x"0";
			state <= 5x"0";
		elsif rising_edge(apu_clock) then
			i2s_bck <= not i2s_bck;
			state <= state + 1;
			if state = "11111" then
				i2s_lrck <= not i2s_lrck;
				sequence_ticks <= sequence_ticks + 1;
			end if;
		end if;
	end process;
end architecture;
