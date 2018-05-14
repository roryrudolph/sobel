library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tb is
    port ( 
        clk  : in std_logic;
        btnC : in std_logic;
        RsRx : in std_logic;
        led  : out std_logic_vector (15 downto 0)
    );
end entity;

architecture behavioral of uart_tb is

	constant baud_rate : integer := 115200;

    component uart
        generic (baud_rate : integer := baud_rate);
        port (
            clk      : in std_logic; -- input clock
            rst_n    : in std_logic; -- asynchronous active low reset
            rx_in    : in std_logic; -- receive data line (bit-by-bit)
            rx_data  : out std_logic_vector (7 downto 0); -- received data
            rx_valid : out std_logic -- high when received data is valid
        );
    end component;

    signal rst_n    : std_logic := '0';
    signal rx_valid : std_logic := '0';
    signal rx_data  : std_logic_vector (7 downto 0);

begin

    rst_n <= not btnC;
    
    led(15) <= not btnC; -- show that reset was pressed
    led(14) <= '1'; -- light up so you know the board is running
    led(13 downto 8) <= (others => '0'); -- don't use
    led(7 downto 0) <= rx_data when rx_valid = '1' and rst_n = '1';

    uart1 : uart
        generic map (baud_rate => baud_rate)
        port map (
            clk      => clk,
            rst_n    => rst_n,
            rx_in    => RsRx,
            rx_data  => rx_data,
            rx_valid => rx_valid
        );
        
end architecture;
