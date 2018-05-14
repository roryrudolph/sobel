


library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_to_memory_translator is
    Generic ( IMAGE_WIDTH : positive := 512 );
	Port (  pixel_clk : in STD_LOGIC;
			PIXEL_X : in STD_LOGIC_VECTOR(11 downto 0);
			PIXEL_Y : in STD_LOGIC_VECTOR(11 downto 0);
			ADD_OUT : out std_logic_vector(23 downto 0); 
			EN : in STD_LOGIC;
			valid_pix : out std_logic
	);
end vga_to_memory_translator;


architecture Behavioral of vga_to_memory_translator is

signal pixel_x_s : unsigned(11 downto 0) := (others =>'0');
signal pixel_y_s: unsigned(11 downto 0) := (others =>'0');

signal pixel_x_trunc_s : unsigned(11 downto 0) := (others =>'0');
signal pixel_y_trunc_s: unsigned(11 downto 0) := (others =>'0');


signal val_out1 : std_logic; 

signal add_out_s: std_logic_vector(23 downto 0) := (others =>'0');

  signal valid_pix_x : std_logic; 
	signal valid_pix_y : std_logic; 


begin

ADD_OUT <= add_out_s; 
pixel_x_trunc_s <= unsigned(PIXEL_X); 
pixel_y_trunc_s <= unsigned(PIXEL_Y); 

valid_pix <= valid_pix_x and valid_pix_y;
 
 process(pixel_clk)
     begin
		if (EN = '1') then
		  if(rising_edge(pixel_clk)) then
			if (unsigned(pixel_x_trunc_s) > IMAGE_WIDTH-1) then	
				--pixel_x_s <= X"1FF"; 
				pixel_x_s <= to_unsigned(IMAGE_WIDTH-1, pixel_x_s'length); 
				valid_pix_x <= '0';
			else
				pixel_x_s <= pixel_x_trunc_s; 
				valid_pix_x <= '1'; 
			end if;
         end if;
		end if; 
         
     end process; 
	 
 process(pixel_clk)
     begin
		if (EN = '1') then
		  if(rising_edge(pixel_clk)) then
			if (unsigned(pixel_y_trunc_s) > IMAGE_WIDTH-1) then	
				--pixel_y_s <= X"1FF";
				pixel_y_s <= to_unsigned(IMAGE_WIDTH-1, pixel_x_s'length); 
				valid_pix_y <= '0';
			else
				pixel_y_s <= pixel_y_trunc_s; 
				valid_pix_y <= '1';
			end if;
         end if;
		end if; 
         
     end process; 

process(pixel_clk)
     begin
		if (EN = '1') then
		  if(rising_edge(pixel_clk)) then
			--add_out_s <= std_logic_vector(unsigned(pixel_y_s) * 512 + unsigned(pixel_x_s));
			add_out_s <= std_logic_vector((unsigned(pixel_y_s) * IMAGE_WIDTH) + unsigned(pixel_x_s));           
         end if;
		end if; 
         
     end process;

--pixel_x <= PIXEL_X; 
--pixel_y <= PIXEL_Y; 

end Behavioral;
