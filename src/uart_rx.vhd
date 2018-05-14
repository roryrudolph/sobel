library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is
    generic (baud_rate : integer := 115200);
    port (
        clk      : in std_logic; -- input clock
        rst_n    : in std_logic; -- asynchronous active low reset
        rx_in    : in std_logic; -- receive data line (bit-by-bit)
        rx_data  : out std_logic_vector (7 downto 0); -- received data
        rx_valid : out std_logic -- received data is valid
    );
end entity;

architecture uart_rx_arch of uart_rx is
    -- System clock frequency
    constant f_clk       : integer := 100000000;
    -- Oversample by this amount (e.g. 4 samples per bit)
    constant div_sample  : integer := 4;
    -- Count the number of samples taken
    constant div_counter : integer := f_clk / (baud_rate * div_sample);
    
    constant mid_sample  : integer := div_sample / 2;
    constant div_bit     : integer := 10;

    signal is_valid        : std_logic := '0';
    signal shift           : std_logic;
    signal this_state      : std_logic;
    signal next_state      : std_logic;
    signal cntr_bit        : unsigned (3 downto 0); -- counts up to 9 rx bits
    signal cntr_bit_clr    : std_logic; -- clear flag for bit counter
    signal cntr_bit_inc    : std_logic; -- increment flag for bit counter
    signal cntr_sample     : unsigned (1 downto 0);
    signal cntr_sample_clr : std_logic; -- clear flag for sample counter
    signal cntr_sample_inc : std_logic; -- increment flag for sample counter
    signal cntr            : unsigned (13 downto 0); -- counts the baud rate
    signal rx_shift_reg    : std_logic_vector (9 downto 0); -- holds rx bits

begin

    -- bit 9 is the start bit and bit 0 is the stop bit
    -- bits 8:1 are valid
    rx_data <= rx_shift_reg(8 downto 1);
    rx_valid <= is_valid;

    uart_rx_logic : process (clk, rst_n)
    begin
        if (rst_n = '0') then
            this_state  <= '0';
            cntr        <= (others => '0');
            cntr_bit    <= (others => '0');
            cntr_sample <= (others => '0');
            rx_shift_reg <= (others => '0');
        elsif (rising_edge(clk)) then

            cntr <= cntr + 1; -- start counting edges

            -- has the counter reached the baud rate? ...
            if (cntr >= div_counter - 1) then

                -- ... yes, so reset the counter
                cntr <= (others => '0');

                this_state <= next_state;

                -- shift in the rx data bit if shift flag is asserted
                if (shift = '1') then
                    rx_shift_reg <= rx_in & rx_shift_reg(9 downto 1);
                end if;

                -- if sample counter's clear flag set, clear
                if (cntr_sample_clr = '1') then
                    cntr_sample <= (others => '0');
                end if;

                -- if sample counter's increment flag set, increment
                if (cntr_sample_inc = '1') then
                    cntr_sample <= cntr_sample + 1;
                end if;

                -- if bit counter's clear flag set, clear
                if (cntr_bit_clr = '1') then
                    cntr_bit <= (others => '0');
                end if;

                -- if bit counter's increment flag set, increment
                if (cntr_bit_inc = '1') then
                    cntr_bit <= cntr_bit + 1;
                end if;

            end if;
        end if;
    end process;

    uart_rx_state_machine : process (clk)
    begin
        if (rising_edge(clk)) then
            shift <= '0';
            cntr_bit_inc <= '0';
            cntr_bit_clr <= '0';
            cntr_sample_inc <= '0';
            cntr_sample_clr <= '0';
            next_state <= '0';

            case this_state is
                -- idle state
                when '0' =>
                    is_valid <= '0';

                    -- if the rx line is set, don't do anything.
                    -- the rx line must be low, signaling a start bit
                    if (rx_in = '1') then
                        next_state <= '0';
                    else
                        next_state <= '1';
                        cntr_bit_clr <= '1';
                        cntr_sample_clr <= '1';
                    end if;

                -- receiving state
                when '1' =>
                    next_state <= '1'; -- default

                    -- are we at the midpoint of a bit right now?
                    if (cntr_sample = mid_sample-1) then
                        shift <= '1'; -- yes, so trigger a shift
                    end if;

                    -- is the sample counter 3?
                    if (cntr_sample = div_sample - 1) then
                        -- have we counted 9 bits yet?
                        if (cntr_bit = div_bit - 1) then
                            next_state <= '0'; -- rx is complete, back to idle
                            is_valid <= '1';
                            
                        end if;
                        cntr_bit_inc <= '1';
                        cntr_sample_clr <= '1';
                    else -- not finished counting, keep going
                        cntr_sample_inc <= '1';
                    end if;
                when others =>
                    next_state <= '0'; -- default idle state
            end case;

        end if;
    end process;
end architecture;
