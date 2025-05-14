library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tb is
end entity uart_tb;

architecture behavior of uart_tb is

    -- DUT signals
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal data_in     : std_logic_vector(7 downto 0) := (others => '0');
    signal send_data   : std_logic := '0';
    signal tx_line     : std_logic;
    signal rx_line     : std_logic;
    signal received    : std_logic_vector(7 downto 0);

    -- Test parameters
    constant CLK_PERIOD    : time := 20 ns;        -- 50 MHz clock
    constant BIT_PERIOD    : time := 100000 ns;    -- 50 µs per bit (≈10 kHz)
    constant FRAME_PERIOD  : time := BIT_PERIOD * 11; -- 11 bits/frame

    -- Test vectors
    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
    constant TEST_BYTES    : byte_array := (
        x"55", x"AA", x"FF", x"3C"
    );

begin

    -----------------------------------------------------------------------------
    -- Instantiate UART
    -----------------------------------------------------------------------------
    uut: entity work.uart
        port map (
            clk           => clk,
            reset         => reset,
            data          => data_in,
            send_data     => send_data,
            TX            => tx_line,
            RX            => rx_line,
            received_bits => received
        );

    -----------------------------------------------------------------------------
    -- Clock generation (50 MHz)
    -----------------------------------------------------------------------------
    clk_proc: process
    begin
        while true loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
    end process;

    -----------------------------------------------------------------------------
    -- Reset pulse
    -----------------------------------------------------------------------------
    reset_proc: process
    begin
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;
        wait;
    end process;

    -----------------------------------------------------------------------------
    -- Loopback test: send bytes and check reception
    -----------------------------------------------------------------------------
    -- Loopback: wire TX to RX
    rx_line   <= tx_line;
    loopback_proc: process
    begin
        -- Wait for reset release
        wait until reset = '0';


        for i in TEST_BYTES'range loop
            wait for 5*BIT_PERIOD;  -- Wait for idle line
            -- Apply data and trigger transmission
            data_in   <= TEST_BYTES(i);
            wait until rising_edge(clk);
            send_data <= '1';
            -- wait for 2499 cloks
            wait for BIT_PERIOD - CLK_PERIOD;
            send_data <= '0';


            -- Wait full frame time for receipt
            wait for FRAME_PERIOD + BIT_PERIOD;  -- extra bit for safety

            -- Check received byte
            assert received = TEST_BYTES(i)
                report "Loopback test failed for byte " & integer'image(i)
                       severity error;

            -- Small pause before next
            wait for 5*BIT_PERIOD;
        end loop;

        report "Loopback tests passed." severity note;

        wait for 2 ms;  -- Wait before parity‐error test
        wait;
    end process;

end architecture behavior;
