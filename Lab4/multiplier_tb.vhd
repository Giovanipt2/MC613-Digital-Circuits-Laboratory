library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplier_tb is
end multiplier_tb;

architecture sim of multiplier_tb is
    constant N : integer := 4;

    signal a, b : std_logic_vector(N-1 downto 0);
    signal r    : std_logic_vector(2*N-1 downto 0);
    signal clk, set : std_logic := '0';

    component multiplier
        generic (N : integer := 4);
        port (
            a, b : in std_logic_vector(N-1 downto 0) := (others => '0');
            r    : out std_logic_vector(2*N-1 downto 0);
            clk  : in std_logic;
            set  : in std_logic
        );
    end component;

begin
    UUT: multiplier
        generic map (N => N)
        port map (
            a => a,
            b => b,
            r => r,
            clk => clk,
            set => set
        );

    -- Clock process
    clk_process: process
    begin
        while now < 500 ns loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Stimulus
    stimulus: process
        procedure test_mult(x, y: integer) is
        begin
            a <= std_logic_vector(to_unsigned(x, N));
            b <= std_logic_vector(to_unsigned(y, N));
            set <= '1';
            wait for 10 ns;  -- 1 clock cycle
            set <= '0';

            for i in 1 to N loop
                wait for 10 ns;  -- add 1 clock cycle
            end loop;
            
        end procedure;

    begin
        wait for 20 ns;

        test_mult(0, 0);    -- 0 * 0 = 0
        test_mult(0, 7);    -- 0 * 7 = 0
        test_mult(3, 0);    -- 0 * 3 = 0
        test_mult(1, 1);    -- 1 * 1 = 1
        test_mult(2, 3);    -- 2 * 3 = 6
        test_mult(5, 5);    -- 5 * 5 = 25
        test_mult(7, 2);    -- 7 * 2 = 14
        test_mult(15, 15);  -- 15 * 15 = 225

        wait;
    end process;
end sim;
