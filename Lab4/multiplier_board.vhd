library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplier_board is
    port(
        CLOCK_50    : in std_logic;
        SW          : in std_logic_vector(9 downto 0);  -- Operands
        KEY         : in std_logic_vector(3 downto 0);  -- Set signal
        -- Display outputs
        HEX0        : out std_logic_vector(6 downto 0); 
        HEX1        : out std_logic_vector(6 downto 0);
        HEX2        : out std_logic_vector(6 downto 0)
    );
end entity multiplier_board;    

architecture structural of multiplier_board is
    signal A, B     : std_logic_vector(4 downto 0);
    signal R        : std_logic_vector(9 downto 0);
    signal R_ext    : std_logic_vector(3 downto 0);
    signal set      : std_logic;
    
begin
    -- Switches map to operands
    A <= SW(9 downto 5);
    B <= SW(4 downto 0);
    
    -- Control signal to the operands
    set <= not KEY(0);
    
    -- Multiplier instantiation
    multiplier_inst: entity work.multiplier
        generic map (
            N => 5
        )
        port map (
            a => A,
            b => B,
            r => R,
            clk => CLOCK_50,
            set => set
        );
    R_ext(3 downto 2) <= (others => '0');
    R_ext(1 downto 0) <= R(9 downto 8);

    unsigned_HEX0: entity work.unsigned_to_7seg port map(bin => R(3 downto 0), segs => HEX0);
    unsigned_HEX1: entity work.unsigned_to_7seg port map(bin => R(7 downto 4), segs => HEX1);
    unsigned_HEX2: entity work.unsigned_to_7seg port map(bin => R_ext, segs => HEX2);

end architecture structural;