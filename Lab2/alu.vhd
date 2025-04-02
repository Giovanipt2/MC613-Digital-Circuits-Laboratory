library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
port (
    A: in std_logic_vector(31 downto 0);        -- First operand
    B: in std_logic_vector(31 downto 0);        -- Second operand
    ALUCtl: in std_logic_vector(1 downto 0);    -- Control signals
    R: out std_logic_vector(31 downto 0);       -- Result
    Zero: out std_logic;                        -- Zero flag
    Overflow: out std_logic;                    -- Overflow flag
    Cout: out std_logic                         -- Carry-out flag
);
end entity alu;

architecture logic of alu is
    signal A_33, B_33, Result: signed(32 downto 0);
    signal Carry: std_logic;                -- Carry-out signal
    signal Result_32: signed(31 downto 0);  -- Resultado de 32 bits
begin
    -- Extends A and B to 33 bits (with an extra sign bit)
    A_33 <= '0' & signed(A);
    B_33 <= '0' & signed(B);

    -- Alu operation
    with ALUCtl select
        Result <= A_33 and B_33 when "00",      -- AND
                  A_33 + B_33 when "01",        -- Soma
                  A_33 or B_33 when "10",       -- OR
                  A_33 - B_33 when "11",        -- Subtração via complemento de 2
                  (others => '0') when others;
        
    -- Assign the result to the output with the 32 least significant bits
    R <= std_logic_vector(Result(31 downto 0));

    -- Defines zero flag
    Result_32 <= Result(31 downto 0);
    Zero <= '1' when Result_32 = 0 else '0';

    -- Overflow flag: 1 if arithmetic operation results in overflow, 0 otherwise
    Overflow <= '1' when ((ALUCtl = "01" and A(3) = B(3) and Result_32(3) /= A(3)) or
                            (ALUCtl = "11" and A(3) /= B(3) and Result_32(3) /= A(3))) else '0';

    -- Carry-out flag: 1 if result most significant bit is 1, 0 otherwise
    Carry <= Result(32);
    Cout <= Carry;

end architecture logic;
