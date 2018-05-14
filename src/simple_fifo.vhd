library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
 
entity simple_fifo is
	generic (
		constant DATA_WIDTH : positive := 8;
		constant FIFO_DEPTH : positive := 256
	);
	port (
		clk      : in  std_logic;
		reset    : in  std_logic;
		write_en : in  std_logic;
		data_in  : in  std_logic_vector (DATA_WIDTH-1 downto 0);
		read_en  : in  std_logic;
		data_out : out std_logic_vector (DATA_WIDTH-1 downto 0);
		empty    : out std_logic;
		full     : out std_logic
	);
end simple_fifo;

architecture simple_fifo_arch of simple_fifo is
begin

	-- memory Pointer Process
	fifo_process : process (clk)
		type fifo_memory is array (0 to FIFO_DEPTH-1) of std_logic_vector (DATA_WIDTH-1 downto 0);
		variable memory : fifo_memory;
		variable head : natural range 0 to FIFO_DEPTH-1;
		variable tail : natural range 0 to FIFO_DEPTH-1;
		variable looped : boolean;
	begin
		if (rising_edge(clk)) then
			if (reset = '1') then
				head   := 0;
				tail   := 0;
				looped := false;
				full   <= '0';
				empty  <= '1';
			else
				if (read_en = '1') then
					if ((looped = true) or (head /= tail)) then
						-- Update data output
						data_out <= memory(tail);

						-- Update tail pointer as needed
						if (tail = FIFO_DEPTH - 1) then
							tail := 0;
							looped := false;
						else
							tail := tail + 1;
						end if;

					end if;
				end if;

				if (write_en = '1') then
					if ((looped = false) or (head /= tail)) then
						-- Write Data to memory
						memory(head) := data_in;

						-- Increment head pointer as needed
						if (head = FIFO_DEPTH - 1) then
							head := 0;

							looped := true;
						else
							head := head + 1;
						end if;
					end if;
				end if;

				-- Update empty and full flags
				if (head = tail) then
					if (looped) then
						full <= '1';
					else
						empty <= '1';
					end if;
				else
					empty <= '0';
					full <= '0';
				end if;
			end if;
		end if;
	end process;

end simple_fifo_arch;
