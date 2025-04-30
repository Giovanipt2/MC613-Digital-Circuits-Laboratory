library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    port (
        -- System Clocks
        clk         : in  std_logic; -- 50 MHz main clock
        clk_enable  : in  std_logic; -- 9600 Hz enable signal (bit clock)

        -- Transmitter Interface
        data        : in  std_logic_vector(7 downto 0); -- Data to be sent
        send_data   : in  std_logic; -- Trigger signal to start transmission
        TX          : out std_logic; -- Serial transmit line

        -- Receiver Interface
        RX          : in  std_logic; -- Serial receive line
        received_bits : out std_logic_vector(7 downto 0) -- Received data (0s on parity error)
    );
end entity uart;

architecture behavioral of uart is

    -- == Transmitter Types and Signals ==
    type tx_state_type is (
        TX_IDLE,
        TX_START_BIT,
        TX_DATA_BITS,
        TX_PARITY_BIT_ST,
        TX_STOP_BIT
    );
    signal tx_state         : tx_state_type := TX_IDLE;
    signal tx_data_reg      : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_parity_bit    : std_logic := '0';
    signal tx_bit_count     : integer range 0 to 7 := 0; -- Counter for data bits
    signal tx_shift_reg     : std_logic_vector(9 downto 0) := (others => '0'); -- 1 start + 8 data + 1 parity
    signal tx_busy          : std_logic := '0'; -- Internal flag to avoid re-triggering during send

    -- == Receiver Types and Signals ==
    type rx_state_type is (
        RX_IDLE,
        RX_START_BIT,
        RX_DATA_BITS,
        RX_PARITY_BIT,
        RX_STOP_BIT
    );
    signal rx_state         : rx_state_type := RX_IDLE;
    signal rx_data_reg      : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_received_parity : std_logic := '0';
    signal rx_bit_count     : integer range 0 to 7 := 0; -- Counter for received data bits
    signal rx_shift_reg     : std_logic_vector(9 downto 0) := (others => '0'); -- Buffer for start + data + parity
    signal rx_parity_error  : std_logic := '0';
    signal rx_data_output   : std_logic_vector(7 downto 0) := (others => '0'); -- Internal buffer for output


    -- Function to calculate even parity
    function calculate_even_parity (data_in : std_logic_vector(7 downto 0)) return std_logic is
        variable parity : std_logic := '0';
    begin
        -- Count the number of 1s in the data
        for i in 0 to 7 loop
            if data_in(i) = '1' then
                parity := not parity; -- Toggle parity for each '1' found
            end if;
        end loop;
        return parity; -- This bit makes the total number of 1s (data + parity) even
    end function calculate_even_parity;

begin

    -- Default TX to IDLE state ('1')
    TX <= '1' when tx_state = TX_IDLE else tx_shift_reg(0); -- Output LSB of shift register during transmission

    -- Output the received data (handles parity error case)
    received_bits <= rx_data_output;

    -- == Transmitter Process ==
    tx_process : process(clk)
    begin
        if rising_edge(clk) then
            if clk_enable = '1' then
                case tx_state is
                    when TX_IDLE => -- Idle state
                        tx_busy <= '0'; -- Not busy anymore
                        if send_data = '1' and tx_busy = '0' then -- Start transmission on request if not busy
                            tx_data_reg   <= data;
                            tx_parity_bit <= calculate_even_parity(data);
                            -- Load shift register: stop(0), parity, data(7..0), start(0)
                            -- Note: We shift LSB out first. Stop bit is loaded last but shifted out first.
                            tx_shift_reg  <= calculate_even_parity(data) & data & '0';
                            tx_bit_count  <= 0; -- Reset bit counter
                            tx_state      <= TX_START_BIT;
                            tx_busy       <= '1'; -- Set busy flag
                        else
                            tx_state <= TX_IDLE;
                        end if;

                    when TX_START_BIT => -- Start bit ('0') is now in tx_shift_reg(0)
                        -- Start bit ('0') is already in tx_shift_reg(0)
                        -- Shift register one position to the right (prepare data bit 0)
                        tx_shift_reg <= '1' & tx_shift_reg(9 downto 1); -- Shift in '1' (idle) at MSB
                        tx_state     <= TX_DATA_BITS;

                    when TX_DATA_BITS =>
                        -- Current data bit is in tx_shift_reg(0)
                        tx_shift_reg <= '1' & tx_shift_reg(9 downto 1); -- Shift right
                        if tx_bit_count < 7 then
                            tx_bit_count <= tx_bit_count + 1;
                            tx_state     <= TX_DATA_BITS;
                        else
                            tx_bit_count <= 0; -- Reset counter for next time
                            tx_state     <= TX_PARITY_BIT_ST;
                        end if;

                    when TX_PARITY_BIT_ST =>
                        -- Parity bit is now in tx_shift_reg(0)
                        tx_shift_reg <= '1' & tx_shift_reg(9 downto 1); -- Shift right
                        tx_state     <= TX_STOP_BIT;

                    when TX_STOP_BIT =>
                        -- Stop bit ('0') is now in tx_shift_reg(0)
                        tx_shift_reg <= '1' & tx_shift_reg(9 downto 1); -- Shift right (back to idle state)
                        tx_state     <= TX_IDLE; -- Return to IDLE after stop bit
                        -- tx_busy remains '1' until IDLE is entered on next clk_enable cycle

                    when others => -- Should not happen
                         tx_state <= TX_IDLE;

                end case;
            end if; -- clk_enable check
        end if; -- rising_edge(clk) check
    end process tx_process;


    -- == Receiver Process ==
    rx_process : process(clk)
        variable calculated_parity : std_logic;
    begin
        if rising_edge(clk) then
             -- Latch RX input synchronously with main clock for better metastability handling (optional but good practice)
            -- We will sample based on clk_enable anyway
            -- signal rx_synced : std_logic;
            -- rx_synced <= RX;

            if clk_enable = '1' then -- Sample RX only at the bit rate
                case rx_state is
                    when RX_IDLE =>
                        rx_parity_error <= '0'; -- Clear error flag
                        if RX = '0' then -- Detect potential start bit (transition 1 -> 0)
                            rx_state <= RX_START_BIT;
                        else
                            rx_state <= RX_IDLE;
                        end if;

                    when RX_START_BIT =>
                        if RX = '0' then -- Confirm it's a start bit
                            rx_bit_count <= 0;
                            rx_state <= RX_DATA_BITS;
                        else -- Glitch or noise, go back to idle
                            rx_state <= RX_IDLE;
                        end if;

                    when RX_DATA_BITS =>
                        -- Shift received bit into LSB of data register
                        rx_data_reg <= RX & rx_data_reg(7 downto 1);
                        if rx_bit_count < 7 then
                            rx_bit_count <= rx_bit_count + 1;
                            rx_state <= RX_DATA_BITS;
                        else
                            rx_bit_count <= 0; -- Reset counter
                            rx_state <= RX_PARITY_BIT;
                        end if;

                    when RX_PARITY_BIT =>
                        rx_received_parity <= RX; -- Store received parity bit
                        rx_state <= RX_STOP_BIT;

                    when RX_STOP_BIT =>
                        if RX = '0' then -- Check for valid stop bit ('0' as per spec)
                            -- Check Parity
                            calculated_parity := calculate_even_parity(rx_data_reg);
                            if calculated_parity = rx_received_parity then
                                -- Parity OK
                                rx_data_output  <= rx_data_reg; -- Output received data
                                rx_parity_error <= '0';
                            else
                                -- Parity Error
                                rx_data_output  <= (others => '0'); -- Output all zeros
                                rx_parity_error <= '1';
                            end if;
                        else
                            -- Framing Error (Stop bit was not '0') - Also treat as error
                            rx_data_output  <= (others => '0'); -- Output all zeros
                            rx_parity_error <= '1'; -- Indicate error (though not specifically requested, good practice)
                        end if;
                        rx_state <= RX_IDLE; -- Ready for next frame

                    when others => -- Should not happen
                        rx_state <= RX_IDLE;

                end case;
            end if; -- clk_enable check
        end if; -- rising_edge(clk) check
    end process rx_process;

end architecture behavioral;