library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity sobel_wrapper is
	generic (
		arr_elements  : integer := 6400; -- 80*80
		data_width    : integer := 8;
		nrows         : integer := 80;
		addr_width    : integer := 18
	);

	port (
		--clk : in std_logic;
		enb            : out std_logic := '0';
		ena            : out std_logic := '0';
		wea            : out std_logic := '0';
		clk            : in std_logic;
		sobel_complete : out std_logic := '0';
		addra          : out std_logic_vector(addr_width-1 downto 0) := std_logic_vector(to_unsigned(0,addr_width));
		dia            : out std_logic := '0';
		dob1           : in std_logic_vector(data_width-1 downto 0);
		dob2           : in std_logic_vector(data_width-1 downto 0);
		dob3           : in std_logic_vector(data_width-1 downto 0);
		dob4           : in std_logic_vector(data_width-1 downto 0);
		dob5           : in std_logic_vector(data_width-1 downto 0);
		dob6           : in std_logic_vector(data_width-1 downto 0);
		dob7           : in std_logic_vector(data_width-1 downto 0);
		dob8           : in std_logic_vector(data_width-1 downto 0);
		dob9           : in std_logic_vector(data_width-1 downto 0)
	);
end sobel_wrapper;

architecture sobel_wrapper_arch of sobel_wrapper is

	signal P_in1 : std_logic_vector(data_width-1 downto 0);
	signal P_in2 : std_logic_vector(data_width-1 downto 0);
	signal P_in3 : std_logic_vector(data_width-1 downto 0);
	signal P_in4 : std_logic_vector(data_width-1 downto 0);
	signal P_in5 : std_logic_vector(data_width-1 downto 0);
	signal P_in6 : std_logic_vector(data_width-1 downto 0);
	signal P_in7 : std_logic_vector(data_width-1 downto 0);
	signal P_in8 : std_logic_vector(data_width-1 downto 0);
	signal P_in9 : std_logic_vector(data_width-1 downto 0);
	-- signal addra1 : std_logic_vector(addr_width-1 downto 0) := std_logic_vector( to_unsigned(0,addr_width));
	-- signal addra2 : std_logic_vector(addr_width-1 downto 0) := std_logic_vector( to_unsigned(0,addr_width));
	-- signal addra3 : std_logic_vector(addr_width-1 downto 0) := std_logic_vector( to_unsigned(0,addr_width));
	-- signal addra4 : std_logic_vector(addr_width-1 downto 0) := std_logic_vector( to_unsigned(0,addr_width));
	-- signal addra5 : std_logic_vector(addr_width-1 downto 0) := std_logic_vector( to_unsigned(0,addr_width));
	-- signal addra6 : std_logic_vector(addr_width-1 downto 0) := std_logic_vector( to_unsigned(0,addr_width));
	signal G_out : std_logic := '0';
	-- signal comp1 : std_logic := '0';
	-- signal comp2 : std_logic := '0';
	-- signal comp3 : std_logic := '0';
	-- signal comp4 : std_logic := '0';
	-- signal comp5 : std_logic := '0';
	-- signal comp6 : std_logic := '0';
	-- signal stop1 : std_logic := '0';
	-- signal stop2 : std_logic := '0';
	-- signal stop3 : std_logic := '0';
	-- signal stop4 : std_logic := '0';
	-- signal stop5 : std_logic := '0';
	-- signal stop6 : std_logic := '0';
	signal sobel_stop : std_logic := '0';
	-- signal validity_mask1 : std_logic := '0';
	-- signal validity_mask2 : std_logic := '0';
	-- signal validity_mask3 : std_logic := '0';
	-- signal validity_mask4 : std_logic := '0';
	-- signal validity_mask5 : std_logic := '0';
	signal validity_mask : std_logic := '0';
	signal sumx, sumy : std_logic_vector(10 downto 0);
	signal Gx, Gy : std_logic_vector(10 downto 0);
	signal Gxy : std_logic_vector(10 downto 0);
	signal i   : integer := 0;
	signal j   : integer := 0;

begin

	EmittingProcess : process (clk)
	begin

		if clk'event and clk='1' then
		--if clk = '1' and sobel_stop = '0' then

			P_in1 <= dob1;
			P_in2 <= dob2;
			P_in3 <= dob3;
			P_in4 <= dob4;
			P_in5 <= dob5;
			P_in6 <= dob6;
			P_in7 <= dob7;
			P_in8 <= dob8;
			P_in9 <= dob9;

			-- sobel operation starts
			sumx <= ("000" & P_in3)+("00" & P_in6 & '0')+("000" & P_in9)-("000" & P_in1)-("00" & P_in4 & '0')-("000" & P_in7);
			sumy <= ("000" & P_in7)+("00" & P_in8 & '0')+("000" & P_in9)-("000" & P_in1)-("00" & P_in2 & '0')-("000" & P_in3);

			if sumx(10) = '1' then -- implementing |Gx|
				Gx <= not (sumx+1); -- 2's compliment
			else
				Gx <= sumx;
			end if;

			if sumy(10) = '1' then -- implementing |Gy|
				Gy <= not (sumy+1); -- 2's compliment
			else
				Gy <= sumy;
			end if;

			Gxy <= Gx + Gy;
			if Gxy > "00001111111" then -- Threshold = 127
				G_out <='1';
			else
				G_out <='0';
			end if;

			-- sobel operation ends
			addra <= std_logic_vector( to_unsigned((nrows*(i))+j,addr_width));
			dia <= G_out;
			if (i = 0) and (j = 0) then -- NorthWest
				--validity_mask1 <= '1';
				validity_mask <= '1';
			end if;

			if (i = (nrows-1)) and (j = (nrows-1)) then
				--comp1 <= '1'; -- Sobel Operation is complete
				sobel_complete <= '1'; -- Sobel Operation is complete
				i <= 0;
				j <= 0;
				--stop1 <= '1';
				sobel_stop <= '1';
			else
				--comp1 <= '0';
				sobel_complete <= '0';
				j <= (j mod nrows) + 1; -- increment j
				if ((j mod nrows) = (nrows-1)) then -- increment i
					j <= 0;
					i <= i + 1;
				end if;
			end if;

			-- else --clk = '0'
				-- i <= 0;
				-- j <= 0;
			--end if; -- if for clk = 1
			ena <= clk AND validity_mask;
			enb <= clk;
			wea <= clk AND validity_mask;
		end if; -- clk
	end process EmittingProcess;
end sobel_wrapper_arch;
