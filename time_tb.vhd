library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity time_tb is
end entity time_tb;

architecture sim of time_tb is
    -- Signals for the UUT
    signal clk            : std_logic := '0';
    signal clk_enable     : std_logic := '0';            -- Enables the counter
    signal set_mode_pulse : std_logic := '0';
    signal set_value      : std_logic_vector(5 downto 0) := (others => '0');
    signal control        : std_logic := '0';            -- Allows mode change
    signal hours          : std_logic_vector(6 downto 0);
    signal minutes        : std_logic_vector(6 downto 0);
    signal seconds        : std_logic_vector(6 downto 0);
    signal mode           : std_logic_vector(1 downto 0);

    -- Constants for the tests (6-bit values)
    constant VAL_HOURS_15    : std_logic_vector(5 downto 0) := "001111"; -- 15
    constant VAL_MINUTES_45  : std_logic_vector(5 downto 0) := "101101"; -- 45
    constant VAL_SECONDS_30  : std_logic_vector(5 downto 0) := "011110"; -- 30
    constant VAL_MAX_HOURS   : std_logic_vector(5 downto 0) := "010111"; -- 23
    constant VAL_MAX_MINSEC  : std_logic_vector(5 downto 0) := "111011"; -- 59

begin
    -----------------------------------------------------------------------------
    -- UUT instantiation (including clk_enable and control)
    -----------------------------------------------------------------------------
    uut: entity work.time port map(
        clk            => clk,
        clk_enable     => clk_enable,
        set_mode_pulse => set_mode_pulse,
        set_value      => set_value,
        control        => control,
        hours          => hours,
        minutes        => minutes,
        seconds        => seconds,
        mode           => mode
    );

    -----------------------------------------------------------------------------
    -- Clock generation: 10 ns period (each cycle equals 1 "second" in the design)
    -----------------------------------------------------------------------------
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process clk_process;

    -----------------------------------------------------------------------------
    -- Stimulus process
    -----------------------------------------------------------------------------
    stim_proc: process
    begin
        -- Activate counting and mode change
        clk_enable <= '1';
        control    <= '1';
        wait for 20 ns;

        -----------------------------------------------------------------------------
        -- Normal mode: allow counting to observe rollover
        -----------------------------------------------------------------------------
        report "Normal Mode: Counting test";
        wait for 100 ns;  -- 10 clock cycles

        -----------------------------------------------------------------------------
        -- Test: change to Set Hours
        -----------------------------------------------------------------------------
        report "Test: Setting Hours to 15";
        set_value <= VAL_HOURS_15;
        wait for 10 ns;
        set_mode_pulse <= '1';
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        -----------------------------------------------------------------------------
        -- Test: change to Set Minutes
        -----------------------------------------------------------------------------
        report "Test: Setting Minutes to 45";
        set_value <= VAL_MINUTES_45;
        wait for 10 ns;
        set_mode_pulse <= '1';
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        -----------------------------------------------------------------------------
        -- Test: change to Set Seconds
        -----------------------------------------------------------------------------
        report "Test: Setting Seconds to 30";
        set_value <= VAL_SECONDS_30;
        wait for 10 ns;
        set_mode_pulse <= '1';
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        -----------------------------------------------------------------------------
        -- Edge test for maximum values
        -----------------------------------------------------------------------------
        report "Edge Test: Setting Hours to Maximum (23)";
        set_value <= VAL_MAX_HOURS;
        wait for 10 ns;
        set_mode_pulse <= '1';
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        report "Edge Test: Setting Minutes to Maximum (59)";
        set_value <= VAL_MAX_MINSEC;
        wait for 10 ns;
        set_mode_pulse <= '1';
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        report "Edge Test: Setting Seconds to Maximum (59)";
        set_value <= VAL_MAX_MINSEC;
        wait for 10 ns;
        set_mode_pulse <= '1';
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        -----------------------------------------------------------------------------
        -- Complete mode cycle: Normal → Set H → Set M → Set S → Normal
        -----------------------------------------------------------------------------
        report "Test: Complete mode cycle";
        for i in 1 to 4 loop
            set_mode_pulse <= '1'; wait for 10 ns;
            set_mode_pulse <= '0'; wait for 10 ns;
        end loop;
        wait for 50 ns;

        report "Testbench simulation ended";
        wait;
    end process stim_proc;

end architecture sim;
