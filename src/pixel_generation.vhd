library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity pixel_generation is
	generic (
		BIT_DEPTH  : positive := 8;
		ROWS       : positive := 512;
		COLS       : positive := 512;
		COUNT_SIZE : positive := 8
	);
	port (
		clk            : in std_logic;
		pixel_in       : in std_logic_vector(BIT_DEPTH-1 downto 0);
		pixel_valid_in : in std_logic;
		Z1_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		Z2_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		Z3_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		Z4_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		Z5_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		Z6_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		Z7_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		Z8_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		Z9_out         : out std_logic_vector(BIT_DEPTH-1 downto 0);
		valid_data_out : out std_logic
	);
end pixel_generation;

architecture pixel_generation_arch of pixel_generation is

	component Simple_FIFO is
		generic (
			DATA_WIDTH : positive := BIT_DEPTH;
			FIFO_DEPTH : positive := ROWS
		);

		port (
			CLK     : in std_logic;
			RST     : in std_logic;
			DataIn	: in std_logic_vector(7 downto 0);
			WriteEn : in std_logic;
			ReadEn	: in std_logic;
			DataOut : out std_logic_vector(7 downto 0);
			Full    : out std_logic;
			Empty   : out std_logic
		);
	end component;

	signal rst : std_logic;
	signal enable_counter : std_logic;
	signal black_data : std_logic;

	signal Z1 : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal Z2 : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal Z3 : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal Z4 : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal Z5 : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal Z6 : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal Z7 : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal Z8 : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal Z9 : std_logic_vector (BIT_DEPTH-1 downto 0);

	signal data_in_r1  : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal data_out_r1 : std_logic_vector (BIT_DEPTH-1 downto 0);

	signal rd_en_in_r1  : std_logic;
	signal wr_en_in_r1  : std_logic;
	signal empty_out_r1 : std_logic;
	signal full_out_r1  : std_logic;

	signal data_in_r2  : std_logic_vector (BIT_DEPTH-1 downto 0);
	signal data_out_r2 : std_logic_vector (BIT_DEPTH-1 downto 0);

	signal rd_en_in_r2  : std_logic;
	signal wr_en_in_r2  : std_logic;
	signal empty_out_r2 : std_logic;
	signal full_out_r2  : std_logic;

	signal countx_in  : unsigned (COUNT_SIZE-1 downto 0);
	signal county_in  : unsigned (COUNT_SIZE-1 downto 0);
	signal countx_out : unsigned (COUNT_SIZE-1 downto 0);
	signal county_out : unsigned (COUNT_SIZE-1 downto 0);
	
	type state_type is (
		RESET, 
		WAIT_1, 
		BLACK_ROW_0, 
		WAIT_2, 
		BLACK_CELL_0, 
		EXECUTE, 
		BLACK_CELL_511, 
		BLACK_ROW_511
	);

	signal this_state, next_state : state_type;

begin

	FIFO_1 : Simple_FIFO
		port map (
			CLK     => clk,
			RST     => rst,
			DataIn  => data_in_r1,
			WriteEn => wr_en_in_r1,
			ReadEn  => rd_en_in_r1,
			DataOut => data_out_r1,
			Full    => full_out_r1,
			Empty   => empty_out_r1
		);

	FIFO_2 : Simple_FIFO
		port map (
			CLK     => clk,
			RST     => rst,
			DataIn  => data_in_r2,
			WriteEn => wr_en_in_r2,
			ReadEn  => rd_en_in_r2,
			DataOut => data_out_r2,
			Full    => full_out_r2,
			Empty   => empty_out_r2
		);

	data_in_r1  <= pixel_in;
	rd_en_in_r1 <= pixel_valid_in;
	wr_en_in_r1 <= pixel_valid_in;

	data_in_r2  <= data_out_r1;
	rd_en_in_r2 <= pixel_valid_in;
	wr_en_in_r2 <= pixel_valid_in;

	Z1_out <= (others => '0') when black_data = '1' else Z1;
	Z2_out <= (others => '0') when black_data = '1' else Z2;
	Z3_out <= (others => '0') when black_data = '1' else Z3;
	Z4_out <= (others => '0') when black_data = '1' else Z4;
	Z5_out <= (others => '0') when black_data = '1' else Z5;
	Z6_out <= (others => '0') when black_data = '1' else Z6;
	Z7_out <= (others => '0') when black_data = '1' else Z7;
	Z8_out <= (others => '0') when black_data = '1' else Z8;
	Z9_out <= (others => '0') when black_data = '1' else Z9;


	count_out : process (clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				countx_out <= (others => '0');
				county_out <= (others => '0');
			else
				if (enable_counter = '1') then
					countx_out <= countx_out + 1;
					if (countx_out >= (ROWS-1)) then
						county_out <= county_out + 1;
					else
						county_out <= county_out;
					end if;
				else
					countx_out <= countx_out;
					county_out <= county_out;
				end if;
			end if;
		end if;
	end process;
	
	
	count_in : process (clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				countx_in <= (others => '0');
				county_in <= (others => '0');
			else
				if (pixel_valid_in = '1') then
					countx_in <= countx_in + 1;
					if (countx_in >= (ROWS-1)) then
						county_in <= county_in + 1;
					else
						county_in <= county_in;
					end if;
				else
					countx_in <= countx_in;
					county_in <= county_in;
				end if;
			end if;
		end if;
	end process;

	process (clk)
	begin
		if rising_edge(clk) then
			this_state <= next_state;
		end if;
	end process;

	-- Overall state machine
	state_machine : process (this_state, countx_in, county_in, countx_out, county_out, pixel_valid_in)
	begin
		next_state <= this_state;
		rst <= '0';
		enable_counter <= '0';
		black_data     <= '0';
		valid_data_out <= '0';
		
		case this_state is

			when RESET =>
				rst <= '1';
				next_state <= WAIT_1;

			when WAIT_1 =>
				if ((countx_in = "0000") and (county_in = "0001") and (pixel_valid_in = '1')) then
					next_state <= BLACK_ROW_0;
				else
					next_state <= WAIT_1;
				end if;

			when BLACK_ROW_0 =>
				enable_counter <= '1';
				black_data <= '1';
				valid_data_out <= '1';
				if (countx_out = ROWS - 1) then
					next_state <= WAIT_2;
				else
					next_state <= BLACK_ROW_0;
				end if;

			when WAIT_2 =>
				if (pixel_valid_in = '1') then
					next_state <= BLACK_CELL_0;
				else
					next_state <= WAIT_2;
				end if;

			when BLACK_CELL_0 =>
				if (pixel_valid_in = '1') then
					enable_counter <= '1';
					black_data <= '1';
					valid_data_out <= '1';
					next_state <= EXECUTE;
				else
					enable_counter <= '0';
					black_data <= '0';
					valid_data_out <= '0';
					next_state <= BLACK_CELL_0;
				end if;

			when EXECUTE =>
				if (pixel_valid_in = '1') then
					enable_counter <= '1';
					valid_data_out <= '1';
				end if;

				if countx_in = (ROWS - 1) then
					next_state <= BLACK_CELL_511;
				else
					next_state <= EXECUTE;
				end if;

			when BLACK_CELL_511 =>
				enable_counter <= '1';
				black_data <= '1';
				valid_data_out <= '1';
				if(county_in = (COLS-1)) then
					next_state <= BLACK_ROW_511;
				else
					next_state <= WAIT_2;
				end if;

			when BLACK_ROW_511 =>
				enable_counter <= '1';
				black_Data <= '1';
				valid_data_out <= '1';
				if(countx_out = (ROWS-1)) then
					next_state <= RESET;
				else
					next_state <= BLACK_ROW_511;
				end if;
		end case;
	end process;

	shift_reg_1 : process (clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				Z7 <= (others => '0');
				Z8 <= (others => '0');
				Z9 <= (others => '0');
			elsif (pixel_valid_in = '1') then
				Z7 <= Z8;
				Z8 <= Z9;
				Z9 <= pixel_in;
			else
				Z7 <= Z7;
				Z8 <= Z8;
				Z9 <= Z9;
			end if;
		end if;
	end process;

	shift_reg_2 : process (clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				Z4 <= (others => '0');
				Z5 <= (others => '0');
				Z6 <= (others => '0');
			elsif (pixel_valid_in = '1') then
				Z4 <= Z5;
				Z5 <= Z6;
				Z6 <= data_out_r1;
			else
				Z4 <= Z4;
				Z5 <= Z5;
				Z6 <= Z6;
			end if;
		end if;
	end process;

	shift_reg_3 : process (clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				Z1 <= (others => '0');
				Z2 <= (others => '0');
				Z3 <= (others => '0');
			elsif (pixel_valid_in = '1') then
				Z1 <= Z2;
				Z2 <= Z3;
				Z3 <= data_out_r2;
			else
				Z1 <= Z1;
				Z2 <= Z2;
				Z3 <= Z3;
			end if;
		end if;
	end process;

end pixel_generation_arch;
