library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
port (
    A: in std_logic_vector(31 downto 0); -- First operand
    B: in std_logic_vector(31 downto 0); -- Second operand
    ALUCtl: in std_logic_vector(1 downto 0); -- Control signals
    R: out std_logic_vector(31 downto 0); -- Result of the operation
    Zero: out std_logic; -- 1 if the result is zero, 0 otherwise
    Overflow: out std_logic; -- 1 if arithmetic operation results in overflow, 0 otherwise
    Cout: out std_logic -- 1 if arithmetic operation results in carry-out, 0 otherwise
    );
end entity alu;

architecture logic of alu is
    signal A_33: signed(32 downto 0); -- First operand with sign bit
    signal B_33: signed(32 downto 0); -- Second operand with sign bit
    signal Result: signed(32 downto 0); -- Intermediate result
    signal Carry: std_logic; 				-- Carry-out signal
    signal Result_32: signed(31 downto 0); -- Result with 32 bits
begin
    -- Extend A and B to 33 bits with one more 0 to the left
    A_33 <= '0' & signed(A);
    B_33 <= '0' & signed(B);

    -- create a process that runs when A, B, or ALUCtl changes
    with ALUCtl select
			Result <= A_33 and B_33 when "00",
                        A_33 + B_33 when "01",
                        A_33 or B_33 when "10",
                        A_33 - B_33 when "11",
                        (others => '0') when others;
        
    -- Assign the result to the output R (32 least significant bits)
    R <= std_logic_vector(Result(31 downto 0));

    -- Zero flag: 1 if the result is zero, 0 otherwise
    Result_32 <= Result(31 downto 0);
    Zero <= '1' when Result_32 = 0 else '0';

    -- Overflow flag: 1 if arithmetic operation results in overflow, 0 otherwise
    Overflow <= '1' when ((ALUCtl = "01" and A(3) = B(3) and Result_32(3) /= A(3)) or
                            (ALUCtl = "11" and A(3) /= B(3) and Result_32(3) /= A(3))) else '0';

    -- Carry-out flag: 1 if result most significant bit is 1, 0 otherwise
    Carry <= Result(32);
    Cout <= Carry;

end architecture logic;