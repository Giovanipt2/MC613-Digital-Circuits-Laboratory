library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.ENV.STOP;

entity stopwatch_tb is
end stopwatch_tb;

architecture Behavioral of stopwatch_tb is
    -- Input signals
    signal clk         : std_logic := '0';
    signal clk_enable  : std_logic := '0';
    signal control     : std_logic := '0';
    signal pause_start : std_logic := '0';
    signal reset       : std_logic := '0';

    -- Output signals
    signal minutes     : std_logic_vector(6 downto 0);
    signal seconds     : std_logic_vector(6 downto 0);
    signal cent_secs   : std_logic_vector(6 downto 0);

    -- Clock period constant
    constant clk_period : time := 100 ns;

begin
    -- Instantiate the stopwatch component
    uut: entity work.stopwatch
        port map (
            clk         => clk,
            clk_enable  => clk_enable,
            pause_start => pause_start,
            reset       => reset,
            control     => control,
            minutes     => minutes,
            seconds     => seconds,
            cent_secs   => cent_secs
        );

    -- Clock generation process (10ms period for 0.01s resolution)
    clock_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    -- Stimulus process
    stimulus : process
    begin
        -- Initialize system
        control     <= '1';  -- Enable stopwatch mode
        clk_enable  <= '1';  -- Enable clock for stopwatch
        reset       <= '1';  -- Apply reset
        wait for 20 ms;
        reset       <= '0';  -- Release reset
        wait for 10 ms;

        -- Start the stopwatch: generate rising edge on pause_start
        pause_start <= '1';
        wait for clk_period;
        pause_start <= '0';
        wait for 400 ms;  -- Let it run for a while

        -- Pause the stopwatch: rising edge
        pause_start <= '1';
        wait for clk_period;
        pause_start <= '0';
        wait for 500 ms;

        -- Resume the stopwatch
        pause_start <= '1';
        wait for clk_period;
        pause_start <= '0';
        wait for 1000 ms;

        -- Test asynchronous reset
        reset <= '1';
        wait for 10 ms;
        reset <= '0';
        wait for 100 ms;

        -- Let it run again
        wait for 400 ms;

        -- Pause the stopwatch again
        pause_start <= '1';
        wait for clk_period;
        pause_start <= '0';

        -- End simulation
        stop;
    end process;

end Behavioral;
