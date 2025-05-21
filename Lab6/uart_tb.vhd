library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tb is
end entity uart_tb;

architecture behavior of uart_tb is

    -- DUT signals
    signal clk         : std_logic := '0';
    signal clk_inverted : std_logic := '0';
    signal reset_1       : std_logic := '1';
    signal reset_2       : std_logic := '1';
    signal data_in_1     : std_logic_vector(7 downto 0) := (others => '0');
    signal data_in_2     : std_logic_vector(7 downto 0) := (others => '0');
    signal send_data_1   : std_logic := '0';
    signal send_data_2   : std_logic := '0';
    signal tx_line     : std_logic;
    signal rx_line     : std_logic;
    signal received_1    : std_logic_vector(7 downto 0);
    signal received_2    : std_logic_vector(7 downto 0);

    -- Test parameters
    constant CLK_PERIOD    : time := 20 ns;        -- 50 MHz clock
    constant BIT_PERIOD    : time := 100000 ns;    -- 50 µs per bit (≈10 kHz)
    constant FRAME_PERIOD  : time := BIT_PERIOD * 11; -- 11 bits/frame

    -- Test vectors
    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
    constant TEST_BYTES_UUT1 : byte_array := (
        x"55", x"AA", x"FF", x"3C"
    );
    constant TEST_BYTES_UUT2 : byte_array := (
        x"33", x"CC", x"88", x"1E"
    );


begin
    -----------------------------------------------------------------------------
    -- Instantiate the 2 UARTs
    -----------------------------------------------------------------------------
    uut: entity work.uart
        port map (
            clk           => clk,
            reset         => reset_1,
            data          => data_in_1,
            send_data     => send_data_1,
            TX            => tx_line,
            RX            => rx_line,
            received_bits => received_1
        );

    uut2: entity work.uart
        port map (
            clk           => clk_inverted,
            reset         => reset_2,
            data          => data_in_2,
            send_data     => send_data_2,
            TX            => rx_line,
            RX            => tx_line,
            received_bits => received_2
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

    clk_inverted <= not clk;

    -----------------------------------------------------------------------------
    -- Reset pulse
    -----------------------------------------------------------------------------
    reset_proc: process
    begin
        reset_1 <= '1';
        reset_2 <= '1';
        wait for 100 ns;
        reset_1 <= '0';
        reset_2 <= '0';
        wait for 100 ns;
        wait;
    end process;

    -----------------------------------------------------------------------------
    -- Test uut1 sending to uut2
    -----------------------------------------------------------------------------
    uut1_send_proc: process
    begin
        -- Wait for reset release
        wait until reset_1 = '0';

        for i in TEST_BYTES_UUT1'range loop
            wait for 3*BIT_PERIOD;  -- Wait for idle line
            -- Apply data and trigger transmission
            data_in_1   <= TEST_BYTES_UUT1(i);
            wait until rising_edge(clk);
            send_data_1 <= '1';
            wait for BIT_PERIOD - CLK_PERIOD;
            send_data_1 <= '0';

            -- Wait full frame time for receipt
            wait for FRAME_PERIOD + BIT_PERIOD;  -- Extra bit for safety

            -- Check received byte on uut2
            assert received_2 = TEST_BYTES_UUT1(i)
                report "UUT1 to UUT2 test failed for byte " & integer'image(i)
                severity error;

            -- Small pause before next
            wait for 3*BIT_PERIOD;
        end loop;

        report "UUT1 to UUT2 tests passed." severity note;
        wait;
    end process;

    -----------------------------------------------------------------------------
    -- Test uut2 sending to uut1
    -----------------------------------------------------------------------------
    uut2_send_proc: process
    begin
        -- Wait for reset release and some offset to avoid collision with uut1
        wait until reset_2 = '0';
        wait for FRAME_PERIOD * 4 + 10*BIT_PERIOD;  -- Offset after uut1's tests

        for i in TEST_BYTES_UUT2'range loop
            wait for 3*BIT_PERIOD;  -- Wait for idle line
            -- Apply data and trigger transmission
            data_in_2   <= TEST_BYTES_UUT2(i);
            wait until rising_edge(clk_inverted);
            send_data_2 <= '1';
            wait for BIT_PERIOD - CLK_PERIOD;
            send_data_2 <= '0';

            -- Wait full frame time for receipt
            wait for FRAME_PERIOD + BIT_PERIOD;  -- Extra bit for safety

            -- Check received byte on uut1
            assert received_1 = TEST_BYTES_UUT2(i)
                report "UUT2 to UUT1 test failed for byte " & integer'image(i)
                severity error;

            -- Small pause before next
            wait for 3*BIT_PERIOD;
        end loop;

        report "UUT2 to UUT1 tests passed." severity note;
        wait for 2 ms;
        wait;
    end process;
end architecture behavior;