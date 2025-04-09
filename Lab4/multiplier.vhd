library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplier is
    generic (N : integer := 4);
    port (
        a, b : in std_logic_vector(N-1 downto 0);  -- multiplicand e multiplier
        r    : out std_logic_vector(2*N-1 downto 0);-- product
        clk, set : in std_logic                    -- clock and reset signal
    );
end multiplier;

architecture Behavioral of multiplier is
    signal multiplicand : unsigned(2*N-1 downto 0);
    signal multiplier : unsigned(N-1 downto 0);
    signal product       : unsigned(2*N-1 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if set = '1' then
                -- Initialize the signals
                multiplicand <= resize(unsigned(a), 2*N);
                multiplier <= unsigned(b);
                product       <= (others => '0');
            else
                -- if multiplier LSB is 1, add multiplicand to product
                if multiplier(0) = '1' then
                    product <= product + multiplicand;
                end if;
                -- Left shift multiplicand and right shift multiplier
                multiplicand <= shift_left(multiplicand, 1);
                multiplier <= '0' & multiplier(N-1 downto 1);
            end if;
        end if;
    end process;

    r <= std_logic_vector(product);
end Behavioral;
