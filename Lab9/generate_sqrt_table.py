# generate_sqrt_table.py
import math

with open('sqrt_table.vhd', 'w') as vhdl:
    vhdl.write("""-- sqrt_table.vhd: Lookup table para inteiros 0..65025
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sqrt_table is
    Port (
        addr     : in  STD_LOGIC_VECTOR(17 downto 0);
        sqrt_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
end sqrt_table;

architecture Behavioral of sqrt_table is
begin
    process(addr)
    begin
        case to_integer(unsigned(addr)) is
""")
    for n in range(65026):
        root = int(math.isqrt(n))
        vhdl.write(f"            when {n} => sqrt_out <= STD_LOGIC_VECTOR(to_unsigned({root}, 8));\n")
    vhdl.write("""            when others => sqrt_out <= (others => '0');
        end case;
    end process;
end Behavioral;
""")
print("Arquivo sqrt_table.vhd gerado com sucesso.")
