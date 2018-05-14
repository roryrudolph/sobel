library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity top_level is
    generic (
        IMAGE_WIDTH  : positive := 512;
        FRAME_WIDTH  : positive := 1280;
        FRAME_HEIGHT : positive := 1024;
        BAUD_RATE    : positive := 115200
    );
    port (
        clka         : in std_logic;
        rx_in        : in std_logic;
        LED          : out std_logic_vector (15 downto 0);
        btnC         : in std_logic;
        VGA_HS_O     : out std_logic;
        VGA_VS_O     : out std_logic;
        VGA_RED_O    : out std_logic_vector (3 downto 0);
        VGA_BLUE_O   : out std_logic_vector (3 downto 0);
        VGA_GREEN_O  : out std_logic_vector (3 downto 0);
        data_out     : out std_logic;
        data_valid   : out std_logic
    );
end top_level;

architecture behavior of top_level is

    constant BITWIDTH : integer := 8;

    -- Receives the incoming serial data
    component uart is
        generic ( baud_rate : integer := BAUD_RATE );
        port (
            clk      : in std_logic; -- input clock
            rst_n    : in std_logic; -- asynchronous active low reset
            rx_in    : in std_logic; -- receive data line (bit-by-bit)
            rx_data  : out std_logic_vector (7 downto 0); -- received data
            rx_valid : out std_logic -- received data is valid
        );
    end component;

    -- FIFO Memory Module that stores incoming serial data
    component pixel_generation is
        generic (
            BIT_DEPTH     : positive := BITWIDTH;
            ROWS          : positive := IMAGE_WIDTH;
            COLS          : positive := IMAGE_WIDTH;
            COUNT_SIZE    : positive := 4
        );
        port (
            clk             : in std_logic;
            pixel_in        : in std_logic_vector (7 downto 0);
            pixel_valid_in  : in std_logic;
            Z1_out          : out std_logic_vector (7 downto 0);
            Z2_out          : out std_logic_vector (7 downto 0);
            Z3_out          : out std_logic_vector (7 downto 0);
            Z4_out          : out std_logic_vector (7 downto 0);
            Z5_out          : out std_logic_vector (7 downto 0);
            Z6_out          : out std_logic_vector (7 downto 0);
            Z7_out          : out std_logic_vector (7 downto 0);
            Z8_out          : out std_logic_vector (7 downto 0);
            Z9_out          : out std_logic_vector (7 downto 0);
            valid_data_out  : out std_logic
        );
    end component;

    -- Executes the actual Sobel Operator
    component sobel_wrapper is
        generic (
            arr_elements : integer := IMAGE_WIDTH * IMAGE_WIDTH;
            data_width   : integer := 8;
            nrows        : integer := IMAGE_WIDTH;
            addr_width   : integer := 24
        );
        port (
            clk            : in std_logic;
            enb            : out std_logic;
            ena            : out std_logic;
            wea            : out std_logic;
            sobel_complete : out std_logic;
            addra          : out std_logic_vector (addr_width-1 downto 0);
            dia            : out std_logic;
            dob1           : in std_logic_vector (data_width-1 downto 0);
            dob2           : in std_logic_vector (data_width-1 downto 0);
            dob3           : in std_logic_vector (data_width-1 downto 0);
            dob4           : in std_logic_vector (data_width-1 downto 0);
            dob5           : in std_logic_vector (data_width-1 downto 0);
            dob6           : in std_logic_vector (data_width-1 downto 0);
            dob7           : in std_logic_vector (data_width-1 downto 0);
            dob8           : in std_logic_vector (data_width-1 downto 0);
            dob9           : in std_logic_vector (data_width-1 downto 0)
        );
    end component;

--    component Sobel_Operation is
--        generic (
--            bit_depth     : positive;
--            output_depth  : positive;
--            rows          : positive;
--            cols          : positive;
--            Threshold_Value : positive
--        );
--        port (
--            clk            : in std_logic;
--            valid_data_in  : in std_logic_vector (7 downto 0);
--            Z1_in          : in std_logic_vector (7 downto 0);
--            Z2_in          : in std_logic_vector (7 downto 0);
--            Z3_in          : in std_logic_vector (7 downto 0);
--            Z4_in          : in std_logic_vector (7 downto 0);
--            Z5_in          : in std_logic_vector (7 downto 0);
--            Z6_in          : in std_logic_vector (7 downto 0);
--            Z7_in          : in std_logic_vector (7 downto 0);
--            Z8_in          : in std_logic_vector (7 downto 0);
--            Z9_in          : in std_logic_vector (7 downto 0);
--            pixel_data_out : out std_logic_vector (7 downto 0);
--            pixel_data_valid_out : out std_logic 
--        );
--    end component;
    
    -- Storage RAM for the Sobel output
    -- Stores only a single black or white value
    component simple_dual_two_clocks is
        generic (
            arr_elements  : integer := IMAGE_WIDTH * IMAGE_WIDTH;
            data_width    : integer := BITWIDTH;
            addr_width    : integer := 24
        );
        port (
            clka  : in std_logic;
            clkb  : in std_logic;
            ena   : in std_logic;
            enb   : in std_logic;
            wea   : in std_logic;
            addra : in std_logic_vector (addr_width-1 downto 0);
            addrb : in std_logic_vector (addr_width-1 downto 0);
            dia   : in std_logic;
            dob   : out std_logic
        );
    end component;

    -- Handles the VGA output of the system
    component vga_ctrl is
        generic (
            IMAGE_WIDTH  : positive := IMAGE_WIDTH;
            FRAME_WIDTH  : positive := FRAME_WIDTH;
            FRAME_HEIGHT : positive := FRAME_HEIGHT
        );
        port (
            CLK_I         : in std_logic;
            VGA_HS_O      : out std_logic;
            VGA_VS_O      : out std_logic;
            VGA_RED_O     : out std_logic_vector (3 downto 0);
            VGA_BLUE_O    : out std_logic_vector (3 downto 0);
            VGA_GREEN_O   : out std_logic_vector (3 downto 0);
            CLK_105_0     : out std_logic;
            ADD_OUT_RAM   : out std_logic_vector (23 downto 0);
            PIXEL_VAL_IN  : in std_logic;
            PIXEL_READ_EN : out std_logic
        );
    end component;

    -- Internal Signals
    signal rst   : std_logic;
    signal rst_n : std_logic;

    -- Serial signals
    signal rx_data  : std_logic_vector (7 downto 0);
    signal rx_valid : std_logic;

    -- Pixel_Generation signals
    signal Z1_out, Z2_out, Z3_out, Z4_out, Z5_out, Z6_out, Z7_out, Z8_out, Z9_out : std_logic_vector (7 downto 0);
    signal valid_data_out : std_logic;

    -- Sobel Wrapper signals
    signal ena   : std_logic;
    signal wea   : std_logic;
    signal dia   : std_logic;
    signal addra : std_logic_vector (23 downto 0);
    signal pixel_data_valid_out : std_logic;
    signal pixel_data_out : std_logic_vector(BITWIDTH-1 downto 0);

    -- TODO: Finalize the input signals
    -- Memory output signals
    signal clkb  : std_logic;
    signal addrb : std_logic_vector (23 downto 0);
    signal enb   : std_logic;
    signal dob   : std_logic;

    signal i_address : integer := 0; 
    
    -- Signals to handle the ready data signal
    signal PS, NS : std_logic;
    signal valid_serial_data : std_logic;
    
    signal test_data_out : std_logic;
    signal addrb_int : unsigned(23 downto 0);
    signal valid_test_data_out : std_logic;
    signal valid_data_count : unsigned(23 downto 0);
begin

    rst <= btnC;
    rst_n <= not btnC;

    LED(7 downto 0) <= rx_data;
    LED(12 downto 8) <= (others => 'Z');
    LED(13) <= rx_valid;
    LED(14) <= rst_n;
    LED(15) <= '1';

    serial_in : uart
        generic map (baud_rate => BAUD_RATE)--115200)
        port map (
            clk      => clka,
            rst_n    => rst_n,
            rx_in    => rx_in,
            rx_data  => rx_data,
            rx_valid => rx_valid
        );

    
    process (clka, rst_n)
    begin
        if rst_n = '0' then
            PS <= '0';
        elsif rising_edge(clka) then
            PS <= NS;
        end if;
    end process;
    
    
    process (PS, rx_valid)
    begin
        valid_serial_data <= '0';
        case PS is
            when '0' =>
                if rx_valid = '1' then
                    valid_serial_data <= '1';
                    NS <= '1';
                else
                    NS <= '0';
                end if;
            when '1' =>
                if rx_valid = '0' then
                    valid_serial_data <= '0';
                    NS <= '0';
                    i_address <= i_address + 1;
                else
                    NS <= '1';
                end if;
            when others =>
                NS <= '0';
        end case;
   end process;
    
    pixel_data : pixel_generation
--        generic map (
--            bit_depth  => 8,
--            rows       => 512,
--            cols       => 512,
--            setup_time => 1
--        )
        port map (
            clk            => clka,
            pixel_in       => rx_data,
            pixel_valid_in => valid_serial_data,
            Z1_out         => Z1_out,
            Z2_out         => Z2_out,
            Z3_out         => Z3_out,
            Z4_out         => Z4_out,
            Z5_out         => Z5_out,
            Z6_out         => Z6_out,
            Z7_out         => Z7_out,
            Z8_out         => Z8_out,
            Z9_out         => Z9_out,
            valid_data_out => valid_data_out
        );

    -- Executes the actual Sobel Operator
    sobel : sobel_wrapper
        generic map (
            arr_elements => IMAGE_WIDTH,
            data_width => BITWIDTH,
            nrows => IMAGE_WIDTH,
            addr_width => 24 
        )
        port map (
            clk   => valid_data_out,
            addra => addra,
            dia   => dia,
            ena   => ena,
            wea   => wea,
            --start_sobel => -- Do we need/want this signal or should we always be computing the sobel operator when the data is valid?
            sobel_complete => open, -- Do we need/want this signals or should the VGA port always be drawing out the image?
            dob1  => Z1_out,
            dob2  => Z2_out,
            dob3  => Z3_out,
            dob4  => Z4_out,
            dob5  => Z5_out,
            dob6  => Z6_out,
            dob7  => Z7_out,
            dob8  => Z8_out,
            dob9  => Z9_out
        );
--    sobel : Sobel_Operation
--        generic map (
--            bit_depth => 8,
--            output_depth => 8,
--            rows => 512,
--            cols => 512,
--            Threshold_Value => 127
--        )
--        port map (
--            clk            => clka,
--            valid_data_in  => valid_data_out,
--            Z1_in         => Z1_out,
--            Z2_in         => Z2_out,
--            Z3_in         => Z3_out,
--            Z4_in         => Z4_out,
--            Z5_in         => Z5_out,
--            Z6_in         => Z6_out,
--            Z7_in         => Z7_out,
--            Z8_in         => Z8_out,
--            Z9_in         => Z9_out,
--            pixel_data_out => pixel_data_out,
--            pixel_data_valid_out => pixel_data_valid_out,
--        );
    
     -- Stores the Sobel Output data that will be displayed on the VGA port
    sobel_data : simple_dual_two_clocks
--        generic map (
--            arr_elements => IMAGE_WIDTH * IMAGE_WIDTH;
--            data_width => BITWIDTH;
--            addr_width => 24
--        );
        port map (
            clka  => clka,
            clkb  => clkb,
            ena   => ena,
            enb   => enb,
            wea   => wea,
            addra => addra,
            addrb => addrb,
            dia   => dia,
            dob   => dob
        );
        
    process (clkb)
    begin
        if rst_n = '0' then
            addrb_int <= (others => '0');
            addrb <= (others => '0');
            data_valid <= '0';
            enb <= '0';
        elsif rising_edge(clkb) then
            data_out <= dob;
            if addrb_int >= 255 then
                data_valid <= '0';
                addrb_int <= addrb_int;
                addrb <= (others => '0');
                enb <= '0';
            elsif (addra >= 253 and addrb < 256) then
                data_valid <= '1';
                addrb_int <= addrb_int + 1;
                addrb <= std_logic_vector(addrb_int);
                enb <= '1';
            else
                data_valid <= '0';
                addrb_int <= addrb_int;
                addrb <= (others => '0');
                enb <= '0';
            end if;
        end if;
    end process;
    
    -- Outputs the data via VGA out
    vga_out : vga_ctrl
        port map (
            CLK_I         => clka,
            VGA_HS_O      => VGA_HS_O,
            VGA_VS_O      => VGA_VS_O,
            VGA_RED_O     => VGA_RED_O,
            VGA_BLUE_O    => VGA_BLUE_O,
            VGA_GREEN_O   => VGA_GREEN_O,
            CLK_105_0     => clkb,
            --ADD_OUT_RAM   => addrb,
            ADD_OUT_RAM   => open,
            --PIXEL_VAL_IN  => dob,
            PIXEL_VAL_IN  => '0',
            --PIXEL_READ_EN => enb
            PIXEL_READ_EN => open
        );

end behavior;

