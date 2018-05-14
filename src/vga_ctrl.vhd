----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/25/2014 02:10:40 PM
-- Design Name: 
-- Module Name: vga_ctrl - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.math_real.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_ctrl is
    Generic ( IMAGE_WIDTH  : positive := 512;
              FRAME_WIDTH  : positive := 1280;
              FRAME_HEIGHT : positive := 1024
            );
    Port ( 
           CLK_I : in STD_LOGIC;
           VGA_HS_O : out STD_LOGIC;
           VGA_VS_O : out STD_LOGIC;
           VGA_RED_O : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_BLUE_O : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_GREEN_O : out STD_LOGIC_VECTOR (3 downto 0); 
		   CLK_105_0 : out std_logic;
		   ADD_OUT_RAM : out std_logic_vector(23 downto 0); 
		   PIXEL_VAL_IN : in std_logic; 
		   PIXEL_READ_EN : out std_logic
           );
end vga_ctrl;

architecture Behavioral of vga_ctrl is



 

component clk_wiz_0
port
 (-- Clock in ports
  clk_in1           : in     std_logic;
  --Clock out ports
  clk_out1          : out    std_logic
 );
end component;


component vga_to_memory_translator is
    generic ( IMAGE_WIDTH : positive := IMAGE_WIDTH );
	Port (  pixel_clk : in STD_LOGIC;
			PIXEL_X : in STD_LOGIC_VECTOR(11 downto 0);
			PIXEL_Y : in STD_LOGIC_VECTOR(11 downto 0);
			ADD_OUT : out std_logic_vector(23 downto 0); 
			EN : in STD_LOGIC;
			valid_pix : out std_logic
	);
end component;




signal add_out_1D : std_logic_vector(23 downto 0); 

  --***1280x1024@60Hz***--
  --constant FRAME_WIDTH : natural := 1280;
  --constant FRAME_HEIGHT : natural := 1024;
  
  constant H_FP : natural := 48; --H front porch width (pixels)
  constant H_PW : natural := 112; --H sync pulse width (pixels)
  constant H_MAX : natural := 1688; --H total period (pixels)
  
  constant V_FP : natural := 1; --V front porch width (lines)
  constant V_PW : natural := 3; --V sync pulse width (lines)
  constant V_MAX : natural := 1066; --V total period (lines)
  
  constant H_POL : std_logic := '1';
  constant V_POL : std_logic := '1';
  
  -------------------------------------------------------------------------
  
  -- VGA Controller specific signals: Counters, Sync, R, G, B
  
  -------------------------------------------------------------------------
  -- Pixel clock, in this case 108 MHz
  signal pxl_clk : std_logic;
  -- The active signal is used to signal the active region of the screen (when not blank)
  signal active  : std_logic;
  
  -- Horizontal and Vertical counters
  signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
  signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
  
  
  -- Horizontal and Vertical Sync
  signal h_sync_reg : std_logic := not(H_POL);
  signal v_sync_reg : std_logic := not(V_POL);
  -- Pipe Horizontal and Vertical Sync
  signal h_sync_reg_dly : std_logic := not(H_POL);
  signal v_sync_reg_dly : std_logic :=  not(V_POL);
  
  -- VGA R, G and B signals coming from the main multiplexers
  signal vga_red_cmb   : std_logic_vector(3 downto 0);
  signal vga_green_cmb : std_logic_vector(3 downto 0);
  signal vga_blue_cmb  : std_logic_vector(3 downto 0);
  --The main VGA R, G and B signals, validated by active
  signal vga_red    : std_logic_vector(3 downto 0);
  signal vga_green  : std_logic_vector(3 downto 0);
  signal vga_blue   : std_logic_vector(3 downto 0);
  -- Register VGA R, G and B signals
  signal vga_red_reg   : std_logic_vector(3 downto 0) := (others =>'0');
  signal vga_green_reg : std_logic_vector(3 downto 0) := (others =>'0');
  signal vga_blue_reg  : std_logic_vector(3 downto 0) := (others =>'0');
  
  signal pixel_val : std_logic := '0'; 
  
  
  signal H_minus_V_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
	
	signal EN_MEM_READ : std_logic := '1'; 
  
  signal valid_pix : std_logic := '0'; 
  
  signal final_pix : std_logic := '0'; 
  
  signal pixel_read_en_s : std_logic := '1'; 
  
begin
  
            
  clk_wiz_0_inst : clk_wiz_0
  port map
   (
    clk_in1 => CLK_I,
    clk_out1 => pxl_clk);
  
    
  --pxl_clk <= CLK_I; 
       
       ---------------------------------------------------------------
       
       -- Generate Horizontal, Vertical counters and the Sync signals
       
       ---------------------------------------------------------------
         -- Horizontal counter
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (h_cntr_reg = (H_MAX - 1)) then
               h_cntr_reg <= (others =>'0');
             else
               h_cntr_reg <= h_cntr_reg + 1;
             end if;
           end if;
         end process;
         -- Vertical counter
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if ((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) then
               v_cntr_reg <= (others =>'0');
             elsif (h_cntr_reg = (H_MAX - 1)) then
               v_cntr_reg <= v_cntr_reg + 1;
             end if;
           end if;
         end process;
         -- Horizontal sync
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1)) then
               h_sync_reg <= H_POL;
             else
               h_sync_reg <= not(H_POL);
             end if;
           end if;
         end process;
         -- Vertical sync
         process (pxl_clk)
         begin
           if (rising_edge(pxl_clk)) then
             if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1)) then
               v_sync_reg <= V_POL;
             else
               v_sync_reg <= not(V_POL);
             end if;
           end if;
         end process;
         
       --------------------
       
       -- The active 
       
       --------------------  
         -- active signal
         active <= '1' when h_cntr_reg < FRAME_WIDTH and v_cntr_reg < FRAME_HEIGHT
                   else '0';
       
       
       --------------------

     ---------------------------------------
     
     -- Generate moving colorbar background
     
     ---------------------------------------
    
	 
	 process(pxl_clk)
     begin
         if(rising_edge(pxl_clk)) then
			if (final_pix = '0') then
			
				vga_red <= "0000";
				vga_green <= "0000";
				vga_blue <= "0000"; 
			
			else
			
				vga_red <= "0110";
				vga_green <= "0110";
				vga_blue <= "0110"; 
			end if;
			
             
         end if;
     end process;
	 
	 H_minus_V_cntr_reg <= std_logic_vector(((h_cntr_reg) - (v_cntr_reg))); 
	         
	 		  
	final_pix <= pixel_val and valid_pix; 
	pixel_val <= PIXEL_VAL_IN; 
	
	 
	
		Inst_vga_to_memory_translator: vga_to_memory_translator
        PORT MAP 
        (
            pixel_clk	=> pxl_clk,
			PIXEL_X		=> h_cntr_reg,
			PIXEL_Y 	=> v_cntr_reg,
			ADD_OUT		=> add_out_1D,
			EN			=> EN_MEM_READ,
			valid_pix	=> valid_pix
        );
		
	
    ------------------------------------------------------------
    -- Turn Off VGA RBG Signals if outside of the active screen
    -- Make a 4-bit AND logic with the R, G and B signals
    ------------------------------------------------------------
    vga_red_cmb <= (active & active & active & active) and vga_red;
    vga_green_cmb <= (active & active & active & active) and vga_green;
    vga_blue_cmb <= (active & active & active & active) and vga_blue;
    
    
    -- Register Outputs
     process (pxl_clk)
     begin
       if (rising_edge(pxl_clk)) then
    
         v_sync_reg_dly <= v_sync_reg;
         h_sync_reg_dly <= h_sync_reg;
         vga_red_reg    <= vga_red_cmb;
         vga_green_reg  <= vga_green_cmb;
         vga_blue_reg   <= vga_blue_cmb;      
       end if;
     end process;
    
     -- Assign outputs
     VGA_HS_O     	<= h_sync_reg_dly;
     VGA_VS_O     	<= v_sync_reg_dly;
     VGA_RED_O    	<= vga_red_reg;
     VGA_GREEN_O  	<= vga_green_reg;
     VGA_BLUE_O   	<= vga_blue_reg;
	 
	 CLK_105_0 		<= pxl_clk;
	 ADD_OUT_RAM	<= 	add_out_1D; 
	 
	 PIXEL_READ_EN	<= pixel_read_en_s;
	 
end Behavioral;
