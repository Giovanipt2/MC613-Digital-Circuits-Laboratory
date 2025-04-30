-- uart_tb.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all; -- For reporting

entity uart_tb is
end entity uart_tb;

architecture test of uart_tb is

    -- Component Declaration for the UART entity
    component uart is
        port (
            clk         : in  std_logic;
            clk_enable  : in  std_logic;
            data        : in  std_logic_vector(7 downto 0);
            send_data   : in  std_logic;
            TX          : out std_logic;
            RX          : in  std_logic;
            received_bits : out std_logic_vector(7 downto 0)
        );
    end component uart;

    -- Testbench Signals
    signal tb_clk         : std_logic := '0';
    signal tb_clk_enable  : std_logic := '0';
    signal tb_data        : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_send_data   : std_logic := '0';
    signal tb_tx          : std_logic; -- Connect to DUT TX output
    signal tb_rx          : std_logic := '1'; -- Connect to DUT RX input, idle high
    signal tb_received_bits : std_logic_vector(7 downto 0); -- Connect to DUT received_bits output

    -- Constants for timing
    constant CLK_FREQ       : real := 50.0e6; -- 50 MHz
    constant BAUD_RATE      : real := 9600.0; -- 9600 Hz
    constant CLK_PERIOD     : time := 1 sec / CLK_FREQ; -- 20 ns
    constant BIT_PERIOD     : time := 1 sec / BAUD_RATE; -- Approx 104.167 us

    -- Calculate how many main clock cycles per bit period enable pulse
    constant CLK_CYCLES_PER_BIT_ENABLE : integer := integer((CLK_FREQ / BAUD_RATE)); -- Approx 5208

    -- Shared variable for reporting
    shared variable inline : line;

    function slv_to_string(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            if slv(i) = '1' then
                result(slv'length - i) := '1';
            else
                result(slv'length - i) := '0';
            end if;
        end loop;
        return result;
    end function slv_to_string;

begin

    -- Instantiate the Device Under Test (DUT)
    dut_inst : uart
        port map (
            clk         => tb_clk,
            clk_enable  => tb_clk_enable,
            data        => tb_data,
            send_data   => tb_send_data,
            TX          => tb_tx,
            RX          => tb_rx,
            received_bits => tb_received_bits
        );

    -- Clock Generation Process (50 MHz)
    clk_process : process
    begin
        loop
            tb_clk <= '0';
            wait for CLK_PERIOD / 2;
            tb_clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process clk_process;

    -- Clock Enable Generation Process (9600 Hz pulse for one clk period)
    clk_enable_process : process(tb_clk)
        variable clk_enable_cnt : integer range 0 to CLK_CYCLES_PER_BIT_ENABLE - 1 := 0;
    begin
        if rising_edge(tb_clk) then
            if clk_enable_cnt = 0 then
                tb_clk_enable <= '1';
            else
                tb_clk_enable <= '0';
            end if;

            if clk_enable_cnt = CLK_CYCLES_PER_BIT_ENABLE - 1 then
                clk_enable_cnt := 0;
            else
                clk_enable_cnt := clk_enable_cnt + 1;
            end if;
        end if;
    end process clk_enable_process;

    -- Stimulus Process
    stimulus_process : process
        -- Procedure to wait for specific number of bit times
        procedure wait_bits (num_bits : real) is
        begin
            wait for BIT_PERIOD * num_bits;
        end procedure wait_bits;

        -- Procedure to send a byte
        procedure send_byte (byte_to_send : std_logic_vector(7 downto 0)) is
        begin
            -- Wait for idle state if necessary (check tx busy or just wait)
            wait until tb_tx = '1'; -- Wait until previous transmission (if any) is likely done
            wait for CLK_PERIOD * 10; -- Small buffer

            -- Load data
            tb_data <= byte_to_send;
            wait for CLK_PERIOD; -- Ensure data is stable before send pulse

            -- Pulse send_data for one clk_enable period
            wait until tb_clk_enable = '1';
            tb_send_data <= '1';
            wait until tb_clk_enable = '0'; -- Wait for enable to go low
            tb_send_data <= '0';

            -- Wait for the transmission to complete (1 start + 8 data + 1 parity + 1 stop = 11 bits)
            wait_bits(11.1); -- Wait slightly longer than 11 bits

             -- Deassert data bus (optional, good practice)
            tb_data <= (others => 'X');

        end procedure send_byte;

    begin
        write(inline, string'("---- Starting UART Testbench ----")); writeline(output, inline);
        write(inline, string'("Clock Period: ") & time'image(CLK_PERIOD)); writeline(output, inline);
        write(inline, string'("Bit Period: ") & time'image(BIT_PERIOD)); writeline(output, inline);
        write(inline, string'("Clk Cycles per Bit Enable: ") & integer'image(CLK_CYCLES_PER_BIT_ENABLE)); writeline(output, inline);

        -- Initialize signals
        tb_send_data <= '0';
        tb_data      <= (others => '0');
        tb_rx        <= '1'; -- RX Idle high

        wait for 100 ns; -- Wait for initial stabilization

        -- === Test Case 1: Loopback Simple Send/Receive ===
        write(inline, string'("---- Test Case 1: Loopback AA ----")); writeline(output, inline);
        tb_rx <= tb_tx; -- Connect TX to RX for loopback
        wait for CLK_PERIOD;

        send_byte(x"AA"); -- Send 10101010 (Parity should be 0)

        -- Check received data
        assert tb_received_bits = x"AA"
            report "Test Case 1 FAILED: Expected xAA, Received " & slv_to_string(tb_received_bits)
            severity error;
        if tb_received_bits = x"AA" then
             write(inline, string'("Test Case 1 PASSED")); writeline(output, inline);
        end if;
        wait_bits(2.0); -- Wait a bit before next test

        -- === Test Case 2: Loopback Different Data ===
        write(inline, string'("---- Test Case 2: Loopback 55 ----")); writeline(output, inline);
        tb_rx <= tb_tx; -- Ensure loopback
        wait for CLK_PERIOD;

        send_byte(x"55"); -- Send 01010101 (Parity should be 0)

        -- Check received data
        assert tb_received_bits = x"55"
            report "Test Case 2 FAILED: Expected x55, Received " & slv_to_string(tb_received_bits)
            severity error;
        if tb_received_bits = x"55" then
             write(inline, string'("Test Case 2 PASSED")); writeline(output, inline);
        end if;
        wait_bits(2.0);

        -- === Test Case 3: Loopback Odd Parity Data ===
        write(inline, string'("---- Test Case 3: Loopback 3C ----")); writeline(output, inline);
        tb_rx <= tb_tx; -- Ensure loopback
        wait for CLK_PERIOD;

        send_byte(x"3C"); -- Send 00111100 (4 ones -> Parity 0) Should be 0
        assert tb_received_bits = x"3C"
            report "Test Case 3a FAILED: Expected x3C, Received " & slv_to_string(tb_received_bits)
            severity error;
        if tb_received_bits = x"3C" then
             write(inline, string'("Test Case 3a (Data 3C) PASSED")); writeline(output, inline);
        end if;
        wait_bits(2.0);

        send_byte(x"77"); -- Send 01110111 (6 ones -> Parity 0) Should be 0
        assert tb_received_bits = x"77"
            report "Test Case 3b FAILED: Expected x77, Received " & slv_to_string(tb_received_bits)
            severity error;
        if tb_received_bits = x"77" then
             write(inline, string'("Test Case 3b (Data 77) PASSED")); writeline(output, inline);
        end if;
        wait_bits(2.0);

        -- === Test Case 4: Parity Error Simulation ===
        write(inline, string'("---- Test Case 4: Inject Parity Error ----")); writeline(output, inline);
        -- Data x"11" (00010001) has 2 ones. Even parity bit should be '0'. We will force RX high during parity bit time.
        tb_data <= x"11";
        wait for CLK_PERIOD;

        -- Start transmission
        wait until tb_clk_enable = '1';
        tb_send_data <= '1';
        wait until tb_clk_enable = '0';
        tb_send_data <= '0';

        -- Wait until the *start* of the parity bit transmission
        -- Start bit (1) + Data bits (8) = 9 bit times after start trigger
        wait_bits(9.0); -- Wait for 9 full bit times from start of start bit

        -- Force RX high during the parity bit time (approx 1 bit period)
        write(inline, string'("Injecting parity error (forcing RX high)")); writeline(output, inline);
        tb_rx <= '1';
        wait_bits(1.0);
        tb_rx <= tb_tx; -- Reconnect RX to follow TX for stop bit

        -- Wait for reception to complete (Stop bit + processing)
        wait_bits(2.0);

        -- Check received data - should be all zeros due to parity error
        assert tb_received_bits = x"00"
            report "Test Case 4 FAILED: Parity Error Expected x00, Received " & slv_to_string(tb_received_bits)
            severity error;
        if tb_received_bits = x"00" then
             write(inline, string'("Test Case 4 PASSED (Parity Error correctly detected)")); writeline(output, inline);
        end if;
        wait_bits(2.0);


        -- === Test Case 5: Stop Bit Error Simulation ===
        write(inline, string'("---- Test Case 5: Inject Stop Bit Error ----")); writeline(output, inline);
        -- Data x"F0" (11110000) has 4 ones. Even parity bit should be '0'. Stop bit should be '0'. We force RX high.
        tb_data <= x"F0";
        wait for CLK_PERIOD;

        -- Start transmission
        wait until tb_clk_enable = '1';
        tb_send_data <= '1';
        wait until tb_clk_enable = '0';
        tb_send_data <= '0';

        -- Wait until the *start* of the stop bit transmission
        -- Start bit (1) + Data bits (8) + Parity bit (1) = 10 bit times after start trigger
        wait_bits(10.0); -- Wait for 10 full bit times

        -- Force RX high during the stop bit time (it should be '0')
        write(inline, string'("Injecting stop bit error (forcing RX high)")); writeline(output, inline);
        tb_rx <= '1';
        wait_bits(1.0);
        tb_rx <= tb_tx; -- Reconnect RX (though transmission is over)

        -- Wait for reception processing time
        wait_bits(1.0); -- Need time for receiver state machine to process the bad stop bit

        -- Check received data - should be all zeros due to stop bit error
        assert tb_received_bits = x"00"
            report "Test Case 5 FAILED: Stop Bit Error Expected x00, Received " & slv_to_string(tb_received_bits)
            severity error;
         if tb_received_bits = x"00" then
             write(inline, string'("Test Case 5 PASSED (Stop Bit Error correctly detected)")); writeline(output, inline);
        end if;
        wait_bits(2.0);


        -- === End of Test ===
        write(inline, string'("---- Testbench Finished ----")); writeline(output, inline);
        wait; -- Halt simulation

    end process stimulus_process;

end architecture test;