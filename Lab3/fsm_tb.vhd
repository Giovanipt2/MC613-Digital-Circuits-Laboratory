library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

entity fsm_tb is
end entity fsm_tb;

architecture testbench of fsm_tb is

    -- Signals for DUT (Device Under Test)
    signal clk, rst: std_logic := '0';
    signal r50, r100, r200: std_logic := '1';
    signal cafe, t50, t100, t200 : std_logic;
    signal state : std_logic_vector(3 downto 0);

    -- Clock period definition
    constant clk_period : time := 10 ns;

begin
    -- Instantiate the FSM
    uut: entity work.fsm
        port map (
            clk   => clk,
            rst   => rst,
            r50   => r50,
            r100  => r100,
            r200  => r200,
            cafe  => cafe,
            t50   => t50,
            t100  => t100,
            t200  => t200,
            state => state
        );

    -- Clock process
    clk_process : process
    begin
        while now < 500 ns loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset the FSM
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;

        -- Insert a 1-real coin (R$1.00)
        r100 <= '0';
        wait for clk_period;
        r100 <= '1';
        wait for clk_period;

        -- Insert a 50-cent coin (R$0.50)
        r50 <= '0';
        wait for clk_period;
        r50 <= '1';
        wait for clk_period;

        -- Insert another 1-real coin (total: R$2.50, should dispense coffee)
        r100 <= '0';
        wait for clk_period;
        r100 <= '1';
        wait for clk_period;

        -- Wait and reset
        wait for 20 ns;
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;

        -- Insert a 2-real bill (R$2.00)
        r200 <= '0';
        wait for clk_period;
        r200 <= '1';
        wait for clk_period;

        -- Insert a 50-cent coin (total: R$2.50, should dispense coffee)
        r50 <= '0';
        wait for clk_period;
        r50 <= '1';
        wait for clk_period;

        -- Wait and reset
        wait for 20 ns;
        rst <= '0';
        wait for clk_period;
        rst <= '1';

        -- Insert a 2-real bill (R$2.00) followed by a 1-real coin (R$1.00) (should dispense coffee + change)
        r200 <= '0';
        wait for clk_period;
        r200 <= '1';
        wait for clk_period;
        r100 <= '0';
        wait for clk_period;
        r100 <= '1';
        wait for clk_period;

        -- Wait and reset
        wait for 20 ns;
        rst <= '1';
        wait for clk_period;
        rst <= '0';

        -- Insert a 2-real bill (R$2.00) 
        r200 <= '0';
        wait for clk_period;
        r200 <= '1';
        wait for clk_period;

        -- Insert another 2-real bill (R$4.00, should dispense coffee + change)
        r200 <= '0';
        wait for clk_period;
        r200 <= '1';
        wait for clk_period;

        -- End simulation
        wait for 50 ns;
        wait;
    end process;

end architecture testbench;
