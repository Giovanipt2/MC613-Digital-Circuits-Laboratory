library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_board is
    port (
        SW    : in std_logic_vector(9 downto 0);  -- Switches de entrada
        LEDR  : out std_logic_vector(2 downto 0); -- LEDs para as flags
        HEX5  : out std_logic_vector(6 downto 0); -- Sinal negativo de A
        HEX4  : out std_logic_vector(6 downto 0); -- Valor de A
        HEX3  : out std_logic_vector(6 downto 0); -- Sinal negativo de B
        HEX2  : out std_logic_vector(6 downto 0); -- Valor de B
        HEX1  : out std_logic_vector(6 downto 0); -- Sinal negativo de R
        HEX0  : out std_logic_vector(6 downto 0)  -- Resultado R
    );
end entity alu_board;

architecture structural of alu_board is
    signal A_ext, B_ext, R : std_logic_vector(31 downto 0);
    signal ALUCtl : std_logic_vector(1 downto 0);
    signal Zero, Overflow, Cout : std_logic;

begin
    -- Mapeamento dos switches para ALUCtl e operandos A e B com extensao de sinal
    ALUCtl <= SW(9 downto 8);
    A_ext <= (others => SW(7)) & SW(7 downto 4); 
    B_ext <= (others => SW(3)) & SW(3 downto 0); 

    -- Instanciacao da ALU
    alu_inst: entity work.alu port map (
        A      => A_ext,
        B      => B_ext,
        ALUCtl => ALUCtl,
        R      => R,
        Zero   => Zero,
        Overflow => Overflow,
        Cout   => Cout
    );
    
    -- Saidas das flags nos LEDs
    LEDR(0) <= Zero;
    LEDR(1) <= Overflow;
    LEDR(2) <= Cout;
    
    -- Mostrar sinal negativo se necessario
    two_comp_A: entity work.two_comp_to_7seg port map (bin => A_ext(3 downto 0), segs => HEX4, neg => A(3));
    two_comp_B: entity work.two_comp_to_7seg port map (bin => B_ext(3 downto 0), segs => HEX2, neg => B(3));
    two_comp_R: entity work.two_comp_to_7seg port map (bin => R(3 downto 0), segs => HEX0, neg => R(3));

    HEX5 <= "1111110" when two_comp_A.neg = '1' else "1111111";
    HEX3 <= "1111110" when two_comp_B.neg = '1' else "1111111"; 
    HEX1 <= "1111110" when two_comp_R.neg = '1' else "1111111"; 
    
end architecture structural;
