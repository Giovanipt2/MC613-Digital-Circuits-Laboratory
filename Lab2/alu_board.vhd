library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_board is
    port (
        SW    : in std_logic_vector(9 downto 0);  -- Input switches
        LEDR  : out std_logic_vector(9 downto 0); -- LEDs for flags
        HEX5  : out std_logic_vector(6 downto 0); -- Negative sign of A
        HEX4  : out std_logic_vector(6 downto 0); -- Value of A
        HEX3  : out std_logic_vector(6 downto 0); -- Negative sign of B
        HEX2  : out std_logic_vector(6 downto 0); -- Value of B
        HEX1  : out std_logic_vector(6 downto 0); -- Negative sign of R
        HEX0  : out std_logic_vector(6 downto 0)  -- Result R
    );
end entity alu_board;

architecture structural of alu_board is
    signal A_ext, B_ext, R : std_logic_vector(31 downto 0);
    signal ALUCtl : std_logic_vector(1 downto 0);
    signal Zero, Overflow, Cout : std_logic;

begin
	LEDR(9 downto 3) <= (others => '0');
    -- Mapping switches to ALUCtl and operands A and B with sign extension
    ALUCtl <= SW(9 downto 8);
    A_ext(31 downto 4) <= (others => SW(7));
	 A_ext(3 downto 0) <= SW(7 downto 4); 
    B_ext(31 downto 4) <= (others => SW(3));
	 B_ext(3 downto 0) <= SW(3 downto 0); 

    -- ALU instantiation
    alu_inst: entity work.alu port map (
        A      => A_ext,
        B      => B_ext,
        ALUCtl => ALUCtl, 
        R      => R,
        Zero   => Zero,
        Overflow => Overflow,
        Cout   => Cout
    );
    
    -- Output flags to LEDs
    LEDR(0) <= Zero;
    LEDR(1) <= Overflow;
    LEDR(2) <= Cout;
    
    -- Display negative sign if necessary
    two_comp_A: entity work.two_comp_to_7seg port map (bin => A_ext(3 downto 0), segs => HEX4, segs_signal => HEX5, neg => A_ext(3));
    two_comp_B: entity work.two_comp_to_7seg port map (bin => B_ext(3 downto 0), segs => HEX2, segs_signal => HEX3, neg => B_ext(3));
    two_comp_R: entity work.two_comp_to_7seg port map (bin => R(3 downto 0), segs => HEX0, segs_signal => HEX1, neg => R(3));

end architecture structural;
