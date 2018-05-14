--Engineer     : Michael Capone
--Date         : 11/11/2017
--Name of file : simple_dual_two_clocks.vhd
--Description  : Simple Dual-Port Block RAM with Two Clocks; Correct Modelization with a Shared Variable;
--             : Design based on https://www.xilinx.com/support/documentation/sw_manuals/xilinx2016_4/ug901-vivado-synthesis.pdf

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
entity simple_dual_two_clocks is
	generic (arr_elements	: integer := 1024;
			data_width		: integer := 16;
			addr_width		: integer := 24
	);
	port(
	   clka  : in std_logic;
	   clkb  : in std_logic;
	   ena   : in std_logic;
	   enb   : in std_logic;
	   wea   : in std_logic;
	   addra : in std_logic_vector(addr_width-1 downto 0);
	   addrb : in std_logic_vector(addr_width-1 downto 0);
	   dia   : in std_logic;
	   dob   : out std_logic
	);
end simple_dual_two_clocks;

architecture syn of simple_dual_two_clocks is
	type ram_type is array (arr_elements-1 downto 0) of std_logic;
	shared variable RAM : ram_type;
begin
	process(clka)
	begin
		if clka'event and clka = '1' then
			if ena = '1' then
				if wea = '1' then
					RAM(conv_integer(addra)) := dia;
				end if;
			end if;
		end if;
	end process;
 
	process(clkb)
	begin
		if clkb'event and clkb = '1' then
			if enb = '1' then
				dob <= RAM(conv_integer(addrb));
			end if;
		end if;
	end process;
end syn;
